package HTTP::OAI::UserAgent;

use strict;
use warnings;

use vars qw(@ISA $ACCEPT);

our $VERSION = '4.08';

# Do not use eval()
our $USE_EVAL = 1;
# Ignore bad utf8 characters
our $IGNORE_BAD_CHARS = 1;
# Silence bad utf8 warnings
our $SILENT_BAD_CHARS = 0;

use constant MAX_UTF8_BYTES => 4;

require LWP::UserAgent;
@ISA = qw(LWP::UserAgent);

unless( $@ ) {
	$ACCEPT = "gzip";
}

sub delay { shift->_elem( "delay", @_ ) }
sub last_request_completed { shift->_elem( "last_request_completed", @_ ) }

sub redirect_ok { 1 }

sub _oai {
	my( $self, @args ) = @_;
	my $cb = ref($args[0]) eq "CODE" ? shift @args : undef;
	my %args = @args;
	$cb = delete $args{onRecord} || $cb || $self->{onRecord};

	my $handlers = delete $args{handlers} || {};

	if( !$args{force} && (my @errors = HTTP::OAI::Repository::validate_request(%args)) ) {
		return new HTTP::OAI::Response(
			code=>503,
			message=>'Invalid Request (use \'force\' to force a non-conformant request): ' . $errors[0]->toString,
			errors=>\@errors
		);
	}

	# Get rid of any empty arguments
	for( keys %args ) {
		delete $args{$_} if !defined($args{$_}) || !length($args{$_});
	}

	my $request = HTTP::Request->new( GET => $self->_buildurl(%args) );

	delete $args{force};

	my $response = HTTP::OAI::Response->new(
			%args,
			handlers => $handlers,
			onRecord => $cb,
		);
	$response->request( $request );
	my $parser = XML::LibXML->new(
			Handler => HTTP::OAI::SAX::Trace->new(
				Handler => HTTP::OAI::SAX::Text->new(
					Handler => $response
			)	)	);
	$parser->{content_length} = 0;
	$parser->{content_buffer} = Encode::encode('UTF-8','');

HTTP::OAI::Debug::trace( $args{verb} . " " . ref($parser) . "->parse_chunk()" );
	my $r;
	{
		local $SIG{__DIE__};
		$r = $self->SUPER::request($request,sub {
				$self->lwp_callback( $parser, @_ )
			});
		if( $r->is_success && !defined $r->headers->header( 'Client-Aborted' ) )
		{
			eval { $self->lwp_endparse( $parser ) };
			if( $@ )
			{
				$r->headers->header( 'Client-Aborted', 'die' );
				$r->headers->header( 'X-Died', $@ );
			}
		}
	}
	if( defined($r->headers->header( 'Client-Aborted' )) && $r->headers->header( 'Client-Aborted' ) eq 'die' )
	{
		my $err = $r->headers->header( 'X-Died' );
		if( $err eq "done" )
		{
			$r->code(200);
			$r->message("OK");
		}
		else
		{
			$r->code(500);
			$r->message( 'An error occurred while parsing: ' . $err );
		}
	}

	my $cnt_len = $parser->{content_length};
	undef $parser;

	# OAI retry-after
	if( defined($r) && $r->code == 503 && defined(my $timeout = $r->headers->header('Retry-After')) ) {
		if( $self->{recursion}++ > 10 ) {
			$r->code(500);
			$r->message("Server did not give a response after 10 retries");
			return $r;
		}
		if( !$timeout or $timeout =~ /\D/ or $timeout < 0 or $timeout > 86400 ) {
			$r->code(500);
			$r->message("Server specified an unsupported duration to wait (\"".($timeout||'null')."\"");
			return $r;
		}
HTTP::OAI::Debug::trace( "Waiting $timeout seconds" );
		sleep($timeout+10); # We wait an extra 10 secs for safety
		return $self->_oai(@args);
	# Got an empty response
	} elsif( defined($r) && $r->is_success && $cnt_len == 0 ) {
		if( $self->{recursion}++ > 10 ) {
			$r->code(500);
			$r->message("No content in server response");
			return $r;
		}
HTTP::OAI::Debug::trace( "Retrying on empty response" );
		sleep(5);
		return $self->_oai(@args);
	# An HTTP error occurred
	} elsif( $r->is_error ) {
		return $r;
	# An error occurred during parsing
	} elsif( $@ ) {
		$r->code(my $code = $@ =~ /read timeout/ ? 504 : 600);
		$r->message($@);
		return $r;
	}

	# access the original response via previous
	$response->previous($r);

	return $response;
}

sub request
{
	my( $self, @args ) = @_;

	my $delay = $self->delay;
	if( defined $delay )
	{
		if( ref($delay) eq "CODE" )
		{
			$delay = &$delay( $self->last_request_completed );
		}
		select(undef,undef,undef,$delay) if $delay > 0;
	}

	my $r = $self->SUPER::request( @args );

	$self->last_request_completed( time );

	return $r;
}

sub lwp_badchar
{
	my $codepoint = sprintf('U+%04x', ord($_[2]));
	unless( $SILENT_BAD_CHARS )
	{
		warn "Bad Unicode character $codepoint at byte offset ".$_[1]->{content_length}." from ".$_[1]->{request}->uri."\n";
	}
	return $codepoint;
}

sub lwp_endparse
{
	my( $self, $parser ) = @_;

	my $utf8 = $parser->{content_buffer};
	# Replace bad chars with '?'
	if( $IGNORE_BAD_CHARS and length($utf8) ) {
		$utf8 = Encode::decode('UTF-8', $utf8, sub { $self->lwp_badchar($parser, @_) });
	}
	if( length($utf8) > 0 )
	{
		_ccchars($utf8); # Fix control chars
		$parser->{content_length} += length($utf8);
		$parser->parse_chunk($utf8);
	}
	delete($parser->{content_buffer});
	$parser->parse_chunk('', 1);
}

sub lwp_callback
{
	my( $self, $parser ) = @_;

	use bytes; # fixing utf-8 will need byte semantics

	$parser->{content_buffer} .= $_[2];

	do
	{
		# FB_QUIET won't split multi-byte chars on input
		my $utf8 = Encode::decode('UTF-8', $parser->{content_buffer}, Encode::FB_QUIET);

		if( length($utf8) > 0 )
		{
			use utf8;
			_ccchars($utf8); # Fix control chars
			$parser->{content_length} += length($utf8);
			$parser->parse_chunk($utf8);
		}

		if( length($parser->{content_buffer}) > MAX_UTF8_BYTES )
		{
			$parser->{content_buffer} =~ s/^([\x80-\xff]{1,4})//s;
			my $badbytes = $1;
			if( length($badbytes) == 0 )
			{
				Carp::confess "Internal error - bad bytes but not in 0x80-0xff range???";
			}
			if( $IGNORE_BAD_CHARS )
			{
				$badbytes = join('', map {
					$self->lwp_badchar($parser, $_)
				} split //, $badbytes);
			}
			$parser->parse_chunk( $badbytes );
		}
	} while( length($parser->{content_buffer}) > MAX_UTF8_BYTES );
}

sub _ccchars {
	$_[0] =~ s/([\x00-\x08\x0b-\x0c\x0e-\x1f])/sprintf("\\%04d",ord($1))/seg;
}

sub _buildurl {
	my( $self, %args ) = @_;

	Carp::confess "Requires verb parameter" unless $args{'verb'};

	my $uri = URI->new( $self->baseURL );
	return $uri->as_string if $uri->scheme eq "file";

	if( defined($args{resumptionToken}) && !$args{force} ) {
		$uri->query_form(verb=>$args{'verb'},resumptionToken=>$args{'resumptionToken'});
	} else {
		delete $args{force};
		# http://www.cshc.ubc.ca/oai/ breaks if verb isn't first, doh
		$uri->query_form(verb=>delete($args{'verb'}),%args);
	}

	return $uri->as_string;
}

sub decompress {
	my ($response) = @_;
	my $type = $response->headers->header("Content-Encoding");
	return $response->{_content_filename} unless defined($type);
	if( $type eq 'gzip' ) {
		my $filename = File::Temp->new( UNLINK => 1 );
		my $gz = Compress::Zlib::gzopen($response->{_content_filename}, "r") or die $!;
		my ($buffer,$c);
		my $fh = IO::File->new($filename,"w");
		binmode($fh,":utf8");
		while( ($c = $gz->gzread($buffer)) > 0 ) {
			print $fh $buffer;
		}
		$fh->close();
		$gz->gzclose();
		die "Error decompressing gziped response: " . $gz->gzerror() if -1 == $c;
		return $response->{_content_filename} = $filename;
	} else {
		die "Unsupported compression returned: $type\n";
	}
}

1;

__END__

=head1 NAME

HTTP::OAI::UserAgent - Extension of the LWP::UserAgent for OAI HTTP requests

=head1 DESCRIPTION

This module provides a simplified mechanism for making requests to an OAI repository, using the existing LWP::UserAgent module.

=head1 SYNOPSIS

	require HTTP::OAI::UserAgent;

	my $ua = new HTTP::OAI::UserAgent;

	my $response = $ua->request(
		baseURL=>'http://arXiv.org/oai1',
		verb=>'ListRecords',
		from=>'2001-08-01',
		until=>'2001-08-31'
	);

	print $response->content;

=head1 METHODS

=over 4

=item $ua = new HTTP::OAI::UserAgent(proxy=>'www-cache',...)

This constructor method returns a new instance of a HTTP::OAI::UserAgent module. All arguments are passed to the L<LWP::UserAgent|LWP::UserAgent> constructor.

=item $r = $ua->request($req)

Requests the HTTP response defined by $req, which is a L<HTTP::Request|HTTP::Request> object.

=item $r = $ua->request(baseURL=>$baseref, verb=>$verb, %opts)

Makes an HTTP request to the given OAI server (baseURL) with OAI arguments. Returns an L<HTTP::Response> object.

OAI-PMH related options:

	from => $from
	until => $until
	resumptionToken => $token
	metadataPrefix => $mdp
	set => $set

=item $time_d = $ua->delay( $time_d )

Return and optionally set a time (in seconds) to wait between requests. $time_d may be a CODEREF.

=back
