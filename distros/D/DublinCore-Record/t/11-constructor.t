use strict;
use warnings;
use Test::More tests => 64; 

## use the Element constructor to create an element 
## for each type of element, and make sure that they're 
## available in the record afterwards 

use_ok( 'DublinCore::Record' );
use_ok( 'DublinCore::Element' );

my $record = DublinCore::Record->new();

foreach my $element ( @DublinCore::Record::VALID_ELEMENTS ) {
    my $e = DublinCore::Element->new( {
        name        => $element, 
        qualifier   => "$element-qualifier",
        content     => "$element-content",
        language    => "$element-language",
        scheme      => "$element-scheme"
    } );
    $record->add($e);
}

foreach my $element ( @DublinCore::Record::VALID_ELEMENTS ) {
    my $e = $record->$element();
    foreach my $attrib ( qw( qualifier content language scheme ) ) {
        is( $e->$attrib(), "$element-$attrib", "$element : $attrib" ); 
    }
}

# make sure we get the same results with elements()

my @expected_elements = map +{
    name      => $_,
    qualifier => "$_-qualifier",
    content   => "$_-content",
    language  => "$_-language",
    scheme    => "$_-scheme"
}, sort @DublinCore::Record::VALID_ELEMENTS;

my @got_elements = map +{
    name      => $_->name,
    qualifier => $_->qualifier,
    content   => $_->content,
    language  => $_->language,
    scheme    => $_->scheme
}, sort { $a->name cmp $b->name } $record->elements;

is_deeply( \@got_elements, \@expected_elements, 'elements()' );

# test removing

my $removed = $expected_elements[ 0 ];
@expected_elements = @expected_elements[ 1..$#expected_elements ];
my $name    = $removed->{ name };
my $remove  = $record->$name;

$record->remove( $remove );

@got_elements = map +{
    name      => $_->name,
    qualifier => $_->qualifier,
    content   => $_->content,
    language  => $_->language,
    scheme    => $_->scheme
}, sort { $a->name cmp $b->name } $record->elements;

is_deeply( \@got_elements, \@expected_elements, 'remove()' );
