# $Id: /mirror/gungho/lib/Gungho/Plugin/Statistics/Format/XML.pm 4238 2007-10-29T15:08:17.605700Z lestrrat  $

package Gungho::Plugin::Statistics::Format::XML;
use strict;
use warnings;
use base qw(Gungho::Base);
use XML::LibXML;

sub format
{
    my ($self, $storage, $output) = @_;

    $output ||= \*STDOUT;

    my $doc = XML::LibXML::Document->new("1.0", "UTF-8");
    my $root = $doc->createElement('GunghoStatstics');
    $doc->setDocumentElement( $root );

    my $parent = $root;
    foreach my $name qw(active_requests finished_requests) {
        my $tag = $name;
        $tag =~ s/(?:\b|_)(.)/uc $1/ge;
        my $el = $doc->createElement($tag);
        my $value = $storage->get($name);
        if (defined $value) {
            $el->appendText($value);
        }
        $parent->appendChild($el);
    }

    print $output $doc->toString();
}

1;

__END__

=head1 NAME

Gungho::Plugin::Statistics::Format::XML - Format Statistics As XML

=head1 METHODS

=head2 format

=cut

