package Lingua::EN::Keywords::Yahoo;

use strict;
use LWP::UserAgent;
use XML::Twig;
use base qw(Exporter);

our $VERSION   = "0.5";
our @EXPORT_OK = qw(keywords);

our $ua;
our $uri = "http://api.search.yahoo.com/ContentAnalysisService/V1/termExtraction";

BEGIN {
    $ua = LWP::UserAgent->new();
};

=head1 NAME

Lingua::EN::Keywords::Yahoo - Automatically extracts keywords from text using the Yahoo! API

=head1 SYNOPSIS

  use Lingua::EN::Keywords::Yahoo qw(keywords);

  my @keywords = keywords($text);

or

  my @keywords = keywords($text, $query);

Where C<$query> is an optional term to help with the extraction process. 

=head1 DESCRIPTION

This uses the Yahoo! keywords API to extract keywords from 
text. 

To quote the Yahoo! page: "The Term Extraction Web Service provides a 
list of significant words or phrases extracted from a larger content."

=head1 EXPORT

Can export the C<keywords> subroutine.

=head1 AUTHOR

Original code by Simon Cozens, <simon@cpan.org>

Packaged by Simon Wistow, <simon@thegestalt.org>

=head1 COPYRIGHT

Released under the same terms as Perl itself.

=head1 SEE ALSO

The Term Extraction API:
http://developer.yahoo.net/search/content/V1/termExtraction.html

L<Yahoo::Search>

=cut



sub keywords {
    my $content = shift;

    my $q    =  {
        appid => "Perl::Lingua::EN::Keywords::Yahoo",
        context => $content
    };

    $q->{query} = shift if @_;

    my $resp = $ua->post($uri, $q);
    my @terms;
    if ($resp->is_success) { 
        my $xmlt = XML::Twig->new( index => [ "Result" ] );
        $xmlt->parse($resp->content);
        for my $result (@{ $xmlt->index("Result") || []}) {
            push @terms, $result->text;
        }
    }
    return @terms;
}

1;


