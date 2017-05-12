package DocRaptor;

# This is used by the user agent, and should match up with the version in Build.PL.
my $PRETTY_VERSION = '0.2.1';

use Moose;
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use LWP::Protocol::https;

has 'api_key' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'is_reporting_user_agent' => (
    traits  => ['Bool'],
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

my $VERSION           = '0.002000';
my $DOC_RAPTOR_URL    = 'https://docraptor.com/docs';
my $USER_AGENT_STRING = 'doc_raptor-perl/'.$PRETTY_VERSION.' perl/'.sprintf( "%vd\n", $^V );

sub create
{
    my $self    = shift;
    my $options = shift; # a DocRaptor::DocOptions object
    my %request_options = $self->_coerce_options_to_request_format( $options );
    $request_options{'user_credentials'} = $self->api_key;
    my $request = POST( $DOC_RAPTOR_URL, [%request_options] );
    return $self->_user_agent->request($request);
}

sub _user_agent
{
    my $self = shift;
    my $agent_string = $self->is_reporting_user_agent ? $USER_AGENT_STRING : '';
    LWP::UserAgent->new( agent => $agent_string, ssl_opts => { verify_hostname => 0 } );
}

sub _coerce_options_to_request_format
{
    my $self            = shift;
    my $options         = shift;
    my %request_options = (
        'doc[document_type]' => $options->document_type,
        'doc[name]'          => $options->document_name,
        'doc[test]'          => $options->is_test ? 'true' : 'false',
    );
    if( $options->document_content )
    {
        $request_options{'doc[document_content]'} = $options->document_content;
    }
    elsif( $options->document_url )
    {
        $request_options{'doc[document_url]'} = $options->document_url;
    }
    else
    {
        die( "Must supply a document_url or document_content" );
    }

    return %request_options;
}

1;
