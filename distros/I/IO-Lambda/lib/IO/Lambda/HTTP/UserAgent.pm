package IO::Lambda::HTTP::UserAgent;
use strict;
use warnings;
use IO::Lambda;
use IO::Lambda::HTTP::Client;
use HTTP::Cookies;
use LWP::ConnCache;

sub new
{
	my ( $class, %opt ) = @_;
	return bless {
		cookie_jar => HTTP::Cookies->  new,
		conn_cache => LWP::ConnCache-> new,
		signature  => "perl/IO-Lambda-HTTP v$IO::Lambda::VERSION",
		protocol   => 'HTTP/1.1',
		timeout    => 60,
		%opt,
	}, $class;
}

sub cookie_jar { $#_ ? $_[0]->{cookie_jar} = $_[1] : $_[0]->{cookie_jar} }
sub conn_cache { $#_ ? $_[0]->{conn_cache} = $_[1] : $_[0]->{conn_cache} }
sub signature  { $#_ ? $_[0]->{signature } = $_[1] : $_[0]->{signature } }
sub protocol   { $#_ ? $_[0]->{protocol  } = $_[1] : $_[0]->{protocol  } }
sub timeout    { $#_ ? $_[0]->{timeout   } = $_[1] : $_[0]->{timeout   } }

sub request
{
	my ( $self, $req, %xopt ) = @_;

	my $keep_alive = 0;
	my %headers;
	$headers{'User-Agent'} = $self->signature;
	if ( $self->protocol eq 'HTTP/1.1') {
		unless ( $req-> protocol) {
			$req-> protocol('HTTP/1.1');
		}
		$headers{Host}         = $req-> uri-> host;
		$headers{Connection}   = 'Keep-Alive';
		$headers{'Keep-Alive'} = 300;
		$keep_alive = 1;
	}

	my $h = $req-> headers;
	while ( my ($k, $v) = each %headers) {
		$h-> header($k, $v) unless defined $h-> header($k);
	}

	my $class = $xopt{class} // 'IO::Lambda::HTTP::Client';
	return $class->new($req,
		%xopt,
		cookie_jar => $self->cookie_jar,
		conn_cache => $self->conn_cache,
		keep_alive => $keep_alive,
		timeout    => $self->timeout,
	);
}

1;

=pod

=head1 NAME

IO::Lambda::HTTP::UserAgent - common properties for http requests

=head1 DESCRIPTION

The module is a simple convenience wrapper for C<IO::Lambda::HTTP::Client> for shared properties
such as cookies, connection cache, etc.

=head1 SYNOPSIS

   use IO::Lambda::HTTP::UserAgent;
   use HTTP::Request;
   my $ua = IO::Lambda::HTTP::UserAgent->new;
   $ua->request( HTTP::Request->new( .. ) )->wait;


=head1 API

=over

=item new %OPTIONS

Creates a user agent instance

=item conn_cache $CACHE

Shared instance of a C<LWP::ConnCache> object

=item cookie_jar $JAR

Shared instance of a C<HTTP::Cookies> object

=item protocol $HTTP

Default is C<HTTP/1.1>

=item request HTTP::Request, %OPTIONS

Creates a lambda that would end when the request is finished.
The lambda returns either a C<HTTP::Response> object or an error string

Options:

=over

=item class $STRING = IO::Lambda::HTTP::Client

Sets class of a HTTP client.

=back

=item signature $STRING

The default C<User-Agent> header

=item timeout $INTEGER

Timeout for requests, default 60 seconds.

=back

=cut
