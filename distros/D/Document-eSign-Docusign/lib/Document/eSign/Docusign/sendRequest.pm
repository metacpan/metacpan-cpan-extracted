package Document::eSign::Docusign::sendRequest;
use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use HTTP::Headers;
use URI;
use Carp;
use Data::Dumper;

=head1 NAME

Document::eSign::Docusign::sendRequest - Handles communication with DocuSign

=head1 VERSION

Version 0.02

=head1 functions

=head2 new($method, $contenttype, $credentials, $uri, $params, $query_params)

Handles communication with the Docusign API. Behavior adapts according to what is requested by a particular call.

=cut

sub new {
    carp( "Got send request: " . Dumper(@_) ) if $_[1]->debug;
    my $class        = shift;
    my $main         = shift;
    my $method       = shift;
    my $contenttype  = shift;
    my $credentials  = shift;
    my $uri          = shift;
    my $params       = shift;
    my $query_params = shift;

    my $self = bless {}, $class;

    my $ua = LWP::UserAgent->new(
        default_headers => HTTP::Headers->new(
            'X-DocuSign-Authentication' => $credentials,
            Accept                      => 'application/json',
        ),
    );

    $ua->add_handler( "request_send", sub { shift->dump; return } )
      if $main->debug;

    $ua->add_handler( "response_done", sub { shift->dump; return } )
      if $main->debug;

    $ua->env_proxy();

    $ua->default_header( 'Content-Type' => $contenttype )
      if defined $contenttype;

    my ( $response, $jsonparams, $multipart );
    my $json = JSON->new->allow_nonref;

    if (   defined $params
        && defined $contenttype
        && $contenttype =~ /json|multipart/i )
    {
        $jsonparams = $json->encode($params);
    }

    if ( defined $contenttype && $contenttype =~ /multipart/i )
    {    #This shit is ugly, I am ashamed XXX
        $multipart = <<"EOF";


--snipsnip
Content-Type: application/json
Content-Disposition: form-data

$jsonparams
EOF
        if ( defined $params->{documents} ) {
            for my $doc ( @{ $params->{documents} } ) {
                open( my $fh, "<", $doc->{name} )
                  or
                  croak( "Unable to open file: " . $doc->{name} . " :: " . $! );
                $doc->{name} =~ s/^.*(\\|\/)//;
                local $/ = '';
                my $pdf = <$fh>;
                $multipart .= <<"EOF";
--snipsnip
Content-Type: application/pdf
Content-Disposition: file; filename="$doc->{name}"; documentid="$doc->{documentId}"

$pdf
EOF
                close $fh;
            }
            $multipart .= <<"EOF";
--snipsnip--

EOF
        }

    }

    if ( $method eq 'GET' ) {

        if ( defined $query_params ) {
            my $uri_with_params = URI->new($uri);
            $uri_with_params->query_form($query_params);
            $response = $ua->get($uri_with_params);
        }
        else {
            $response = $ua->get($uri);
        }

    }
    elsif ( $method eq 'POST' ) {

        $response =
          $ua->post( $uri, Content => $multipart || $jsonparams || $params );

    }
    elsif ( $method eq 'PUT' ) {

        $response =
          $ua->put( $uri, Content => $multipart || $jsonparams || $params );

    }
    elsif ( $method eq 'DELETE' ) {
        $response = $ua->delete($uri);
    }
    else {
        return { error =>
              "An undefined method was used, only use GET, POST, PUT, or DELETE"
        };
    }

    if ( $method =~ /GET|POST/ && $response->is_success ) {
        return $json->decode( $response->decoded_content );
    }
    elsif ( $response->is_success )
    {    #Calls that simply do something and are not expected to return data.
        return { Status => $response->status_line };
    }

    return { error => $response->status_line };

}

1;
