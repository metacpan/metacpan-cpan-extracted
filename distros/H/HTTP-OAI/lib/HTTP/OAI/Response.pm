package HTTP::OAI::Response;

require POSIX;

@ISA = qw( HTTP::Response HTTP::OAI::MemberMixin HTTP::OAI::SAX::Base );

use strict;

our $VERSION = '4.09';

# Backwards compatibility, pass any unknown methods to content
our $AUTOLOAD;

sub DESTROY {}
sub AUTOLOAD
{
	my $self = shift;
	$AUTOLOAD =~ s/^.*:://;

	# don't call a $self method here, because that might call AUTOLOAD again!
	my $content = $self->{content}->[-1];
	return defined $content ? $content->$AUTOLOAD( @_ ) : undef;
}

sub new
{
	my( $class, %self ) = @_;

	my $handlers = delete $self{handlers};
	my $cb = delete $self{onRecord};

	$self{responseDate} ||= POSIX::strftime("%Y-%m-%dT%H:%M:%S",gmtime).'Z';
	$self{requestURL} ||= CGI::self_url() if defined &CGI::self_url;

	my $self = $class->SUPER::new(
		delete($self{code}) || 200,
		delete($self{message}) || "OK",
		HTTP::Headers->new( %self )
	);

	$self->{Depth} = 0;
	$self->{handlers} = $handlers || {};
	$self->{onRecord} = $cb;
	$self->{doc} = XML::LibXML::Document->new( '1.0', 'UTF-8' );
	$self->{content} = [];

	return $self;
}

# Back compatibility
sub errors { shift->error(@_) }
sub toDOM { shift->dom }

# data that belong to this class
sub content { shift->_multi('content',@_) }
sub doc { shift->_elem('doc',@_) }
sub handlers { shift->_elem('handlers',@_) }

# data that belong to this class's headers
sub version { shift->headers->header('version',@_) }
sub verb { shift->headers->header('verb',@_) }
sub error { shift->headers->header('error',@_) }
sub xslt { shift->headers->header('xslt',@_) }
sub responseDate { shift->headers->header('responseDate',@_) }
sub requestURL { shift->headers->header('requestURL',@_) }

sub callback
{
	my( $self, $item, $list ) = @_;

	if( defined $self->{onRecord} )
	{
		$self->{onRecord}->( $item, $self );
	}
	else
	{
		Carp::confess( "Requires list parameter" ) if !defined $list;
		$list->item( $item );
	}
}

# error on 600 as well
sub is_error { my $code = shift->code; $code != 0 && $code != 200 }
sub is_success { !shift->is_error }

sub parse_string
{
	my( $self, $string ) = @_;

	eval { $self->SUPER::parse_string( $string ) };
	if( $@ )
	{
		$self->code( 600 );
		$self->message( $@ );
	}
}

sub parse_file
{
	my( $self, $fh ) = @_;

	eval { $self->SUPER::parse_file( $fh ) };
	if( $@ )
	{
		$self->code( 600 );
		$self->message( $@ );
	}
}

sub generate
{
	my( $self, $driver ) = @_;

	if( $self->xslt ) {
	  $driver->processing_instruction({
	    'Target' => 'xml-stylesheet',
	    'Data' => 'type=\'text/xsl\' href=\''. $self->xslt . '\''
	  });
	}

	if( !defined $self->version || $self->version eq "2.0" )
	{
		$driver->start_element( 'OAI-PMH',
			'xsi:schemaLocation' => 'http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd',
		);
		$driver->data_element( 'responseDate', $self->responseDate );
		my $url = URI->new( $self->requestURL );
		if( $self->error )
		{
			$url->query( undef );
			$driver->data_element( 'request', $url );

			for($self->error)
			{
				$_->generate( $driver );
			}
		}
		elsif( $self->content )
		{
			my %attr = $url->query_form;
			$url->query( undef );
			$driver->data_element( 'request', $url, %attr );

			my $content = ($self->content)[-1];
			$driver->start_element( $content->verb );
			$content->generate_body( $driver );
			$driver->end_element( $content->verb );
		}
		$driver->end_element( 'OAI-PMH' );
	}
	elsif( $self->version eq "2.0s" )
	{
		$driver->start_prefix_mapping({
			Prefix => 'static',
			NamespaceURI => 'http://www.openarchives.org/OAI/2.0/static-repository',
		});
		$driver->start_element( 'static:Repository',
			'xsi:schemaLocation' => 'http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd http://www.openarchives.org/OAI/2.0/static-repository http://www.openarchives.org/OAI/2.0/static-repository.xsd',
		);
		for($self->content)
		{
			$driver->start_element( 'static:' . $_->verb );
			$_->generate_body( $driver );
			$driver->end_element( 'static:' . $_->verb );
		}
		$driver->end_element( 'static:Repository' );
	}
}

sub start_element
{
	my( $self, $hash ) = @_;

	$hash->{Depth} = ++$self->{Depth};

	if( $self->{Depth} == 1 )
	{
		$self->version( $HTTP::OAI::VERSIONS{lc($hash->{NamespaceURI})} );
		if( !defined $self->version )
		{
			die "Unrecognised namespace for OAI response: {$hash->{NamespaceURI}}$hash->{Name}";
		}
		# static repositories don't contain ListIdentifiers or GetRecord, so
		# instead we'll perform a complete ListRecords then extract the
		# relevant data
		if( $self->version eq "2.0s" )
		{
			if( $self->verb eq "ListIdentifiers" || $self->verb eq "GetRecord" )
			{
				$self->{_verb} = $self->verb;
				$self->verb( "ListRecords" );
			}
			elsif( $self->verb eq 'ListSets' )
			{
				$self->content( HTTP::OAI::ListSets->new );
				$self->error(HTTP::OAI::Error->new( code => 'noSetHierarchy' ));
				die "done\n";
			}
		}
	}
	elsif( $self->{Depth} == 2 )
	{
		my $elem = $hash->{LocalName};
		if( $elem eq "error" )
		{
			$self->set_handler( my $error = HTTP::OAI::Error->new );
			$self->error( $error );
		}
		elsif
		  (
			$elem =~ /^GetRecord|Identify|ListIdentifiers|ListMetadataFormats|ListRecords|ListSets$/ &&
			(!defined $self->verb || $elem eq $self->verb)
		  )
		{
			if( $self->version eq "2.0s" && $self->verb eq "ListRecords" )
			{
				my $metadataPrefix = $hash->{Attributes}{'{}metadataPrefix'}{Value};
				if( $metadataPrefix eq $self->headers->header( 'metadataPrefix' ) )
				{
					$self->set_handler( my $content = "HTTP::OAI::$elem"->new );
					$self->content( [ $content ] );
				}
			}
			else
			{
				$self->set_handler( my $content = "HTTP::OAI::$elem"->new );
				$self->content( [ $content ] );
			}
		}
	}

	$self->SUPER::start_element( $hash, $self );
}

sub end_element
{
	my( $self, $hash ) = @_;

	$hash->{Depth} = $self->{Depth};

	$self->SUPER::end_element( $hash, $self );

	if( $self->{Depth} == 2 )
	{
		my $elem = $hash->{LocalName};
		if( $elem eq "responseDate" || $elem eq "requestURL" )
		{
			$self->headers->header( $elem, $hash->{Text} );
		}
		elsif( $elem eq "request" )
		{
			$self->headers->header("request",$hash->{Text});
			my $uri = new URI($hash->{Text});
			$uri->query_form(map { ($_->{LocalName},$_->{Value}) } values %{$hash->{Attributes}});
			$self->headers->header("requestURL",$uri);
		}
		elsif( $elem eq "error" )
		{
			my $error = $self->get_handler;
			if( $error->code !~ /^noRecordsMatch|noSetHierarchy$/ )
			{
				$self->code( 500 );
				$self->message( $error->code . ": " . $error->message );
			}
		}
		# extract ListIdentifiers and GetRecord from a static ListRecords
		elsif( defined($self->get_handler) && $self->version eq "2.0s" )
		{
			# fake ListIdentifiers/GetRecord
			if( defined(my $verb = $self->{_verb}) )
			{
				if( $verb eq "ListIdentifiers" )
				{
					my $content = HTTP::OAI::ListIdentifiers->new;
					$content->item( map { $_->header } ($self->content)[-1]->item );
					$self->content( [ $content ] );
				}
				elsif( $verb eq "GetRecord" )
				{
					my $content = HTTP::OAI::GetRecord->new;
					$content->item( [grep { $_->identifier eq $self->headers->header('identifier') } ($self->content)[-1]->item] );
					$self->content( [ $content ] );
					if( !defined( ($content->item)[0] ) )
					{
						$self->content( [] );
						$self->error(my $error = HTTP::OAI::Error->new( code => 'idDoesNotExist' ));
						$self->code( 500 );
						$self->message( $error->code . ": " . $error->message );
					}
				}
			}
			die "done\n";
		}
		$self->set_handler( undef );
	}
	if( $self->{Depth} == 1 )
	{
		if( $self->version eq "2.0s" && !$self->error && !$self->content )
		{
			$self->error(my $error = HTTP::OAI::Error->new( code => 'cannotDisseminateFormat' ));
			$self->code( 500 );
			$self->message( $error->code . ": " . $error->message );
		}
		# allow callers to do $r->next to check whether anything came back
		if( !$self->content && defined(my $verb = $self->verb) )
		{
			$self->content( "HTTP::OAI::$verb"->new );
		}
	}

	$self->{Depth}--;
}

1;
