package MARC::SubjectMap::XML;

## helper functions for xml creation
## internal use only

use strict;
use warnings;

use base qw( Exporter );
our @EXPORT_OK = qw( element emptyElement esc startTag endTag comment );

sub element {
    my ($tag,$content,@attrs) = @_;
    return startTag($tag,@attrs).esc($content).endTag($tag);
}

sub emptyElement {
    my ($tag,@attrs) = @_;
    my $xml = startTag( $tag,@attrs); 
    $xml =~ s{>$}{ />};
    return $xml;
}

sub startTag {
    my ($tag,@attrs) = @_;
    my $xml = "<$tag";
    while ( @attrs ) {
        my $key = shift(@attrs);
        my $val = esc( shift(@attrs) );
        $xml .= qq( $key="$val");
    }
    $xml .= ">";
    return $xml;
}

sub endTag {
    my $tag = shift;
    return ( "</$tag>" );
}

sub esc {
    my $str = shift;
    return "" if ! defined($str);
    $str =~ s/</&lt;/g;
    $str =~ s/>/&gt;/g;
    ## be careful not to encode ampersands that are valid entities
    $str =~ s/&(?!(amp|apos|lt|gt);)/&amp;/g;
    return $str;
}

sub comment {
    my $str = shift;
    return qq(<!-- $str -->);
}

1;


