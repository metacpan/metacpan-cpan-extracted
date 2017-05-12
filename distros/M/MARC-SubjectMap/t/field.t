use strict;
use warnings;
use Test::More qw( no_plan );
use Test::Exception;

use_ok( 'MARC::SubjectMap::Field' );

TEST_ACCESSORS: {

    my $f = MARC::SubjectMap::Field->new();
    isa_ok( $f, 'MARC::SubjectMap::Field' );

    $f->tag( '650' );
    is( $f->tag(), '650', 'tag() get/set' );

    $f->indicator1(1);
    is( $f->indicator1(), '1', 'indicator1()' );

    $f->indicator2('0');
    is( $f->indicator2(), '0', 'indicator2()' );

    $f->addCopy( 'a' );
    $f->addCopy( 'b' );
    is_deeply( [ $f->copy() ], ['a','b'], 'copy() getter' );

    $f->addTranslate( 'c' );
    $f->addTranslate( 'd' );
    is_deeply( [ $f->translate() ], ['c','d'], 'translate() getter' );

    throws_ok
        { $f->addTranslate('a') }
        qr/can't both translate and copy subfield a/,
        'expected exception when adding translate when already copy';
    throws_ok
        { $f->addCopy( 'c' ) }
        qr/can't both copy and translate subfield c/,
        'expected exception when adding copy when already translate';

    ## check XML
    is( $f->toXML(), join('',<DATA>), 'asXML()' );

}

__DATA__
<field tag="650" indicator1="1" indicator2="0">
<copy>a</copy>
<copy>b</copy>
<translate>c</translate>
<translate>d</translate>
<sourceSubfield>a</sourceSubfield>
</field>
