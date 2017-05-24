use strict;
use warnings;
use Test::More tests => 14; 

# test escaping of < > and & for XML

use_ok( 'MARC::File::XML' );

is( MARC::File::XML::escape( 'foo&bar&baz' ), 'foo&amp;bar&amp;baz', '&' );
is( MARC::File::XML::escape( 'foo>bar>baz' ), 'foo&gt;bar&gt;baz', '>' );
is( MARC::File::XML::escape( 'foo<bar<baz' ), 'foo&lt;bar&lt;baz', '<' );

use_ok( 'MARC::Record' );
use_ok( 'MARC::Field' );
use_ok( 'MARC::Batch' );

my $r1 = MARC::Record->new();
isa_ok( $r1, 'MARC::Record' );

$r1->leader( '&xyz<123>' );
$r1->append_fields(
    MARC::Field->new( '005', '&abc<def>' ),
    MARC::Field->new( '245', 0, 1, a => 'Foo&Bar<Baz>' )
);

my $xml1 = $r1->as_xml();
like( $xml1, qr/&amp;xyz&lt;123&gt;/, 'escaped leader' );
like( $xml1, qr/&amp;abc&lt;def&gt;/, 'escape control field' );
like( $xml1, qr/Foo&amp;Bar&lt;Baz&gt;/, 'escaped field' );

# check escaping of subfield labels
my $b = MARC::Batch->new( 'USMARC', 't/escape.mrc' );
my $r2 = $b->next();
is($r2->subfield('650', '<'), 'France', 'read subfield $< parsed from ISO2709 blob');
my $xml2 = $r2->as_xml();
my $r3;
SKIP: {
    eval { $r3 = MARC::Record->new_from_xml($xml2); };
    if ($@) {
        fail('failed to parse MARCXML generated from record containing a subfield $<');
	skip 'no point in checking further', 1;
    } else {
        is($r3->subfield('650', '<'), 'France', 'read subfield $< parsed from MARCXML');
	is_deeply($r2, $r3, 'record with subfield $< the same parsed from ISO2709 or MARCXML');
    }
}

