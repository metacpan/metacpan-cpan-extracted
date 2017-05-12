package MKDoc::XML::Decode::XMLBase;
use warnings;
use strict;

our %XML_Decode = (
    'amp'  => '&',
    'lt'   => '<',
    'gt'   => '>',
    'quot' => '"',
    'apos' => "'",
   );

sub process
{
    my $class = shift;
    my $stuff = shift;
    return $XML_Decode{$stuff};
}

sub module_name { 'xml' }

1;
