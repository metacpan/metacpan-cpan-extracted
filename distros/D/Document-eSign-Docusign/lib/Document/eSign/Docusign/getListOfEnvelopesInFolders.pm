package Document::eSign::Docusign::getListOfEnvelopesInFolders;
use strict;
use warnings;
use Carp;
use Data::Dumper;

=head1 NAME

Document::eSign::Docusign::getListOfEnvelopesInFolders - This returns a list of envelopes 
that match the criteria specified in the query. Use to search for completed envelopes etc.

=head1 VERSION

Version 0.04

=cut

=head1 functions

=head2 getListOfEnvelopesInFolders($parent, $vars)

    my $response = $ds->getListOfEnvelopesInFolders(
        {
            accountId           => $ds->accountid, # Required
            search_folder       => 'completed', # Required
        },
        {
            start_position      => {integer}, 
            count               => {integer}
            from_date           => {date/time}, 
            to_date             => {date/time}, 
            order_by            => {string}, 
            order               => {string},
            include_recipients  => {true/false}, all
        }
    );
    
    print "Got envelopes: " . Dumper $response . "\n";
   
Full options:

https://www.docusign.com/p/RESTAPIGuide/RESTAPIGuide.htm#REST%20API%20References/Get%20List%20of%20Envelopes%20in%20Folders.htm%3FTocPath%3DREST%2520API%2520References%7C_____111
 
=cut

sub new {
    carp( "Got get List Of Envelopes In Folders request: " . Dumper(@_) ) if $_[1]->debug;
    my $class = shift;
    my $main  = shift;
    my $vars  = shift;
    my $query_params = shift;

    my $self = bless {}, $class;

    my $uri =  q{/search_folders/} . $vars->{search_folder};

    my $creds = $main->buildCredentials();

    my $response =
      $main->sendRequest( 'GET', undef, $creds, $main->baseUrl . $uri, $vars, $query_params );

    return $response;
}

1;
