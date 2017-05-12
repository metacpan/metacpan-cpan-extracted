##!perl -Tw

use Test::More tests => 20;

use strict;
use MARC::Record;
use MARC::Batch;
use MARC::File::USMARC;
use Encode;
use File::Spec;

## we are going to create a MARC record with a utf8 character in
## it (a Hebrew Aleph), write it to disk, and then attempt to
## read it back from disk as a MARC::Record.

my $aleph = chr(0x05d0);
ok( Encode::is_utf8($aleph), 'is_utf8()' );
my $filename = File::Spec->catfile( 't', 'utf8.marc' );

CREATE_FILE: {
    my $r = MARC::Record->new();
    isa_ok( $r, 'MARC::Record' );

    is( $r->encoding(), 'MARC-8', 'default encoding' );
    $r->encoding( 'UTF-8' );
    is( $r->encoding(), 'UTF-8', 'set encoding' );

    my $f = MARC::Field->new( 245, 0, 0, a => $aleph, c => 'Mr. Foo' );
    isa_ok( $f, 'MARC::Field' );

    my $nadds = $r->append_fields( $f );
    is( $nadds, 1, "Added one field" );

    ## write record to disk, telling perl (as we should) that we
    ## will be writing utf8 unicode
    open( my $OUT, '>', $filename );
    binmode( $OUT, ':utf8' ); # so we don't get a warning
    print $OUT $r->as_usmarc();
    close( $OUT );
}

## open the file back up, get the record, and see if our Aleph
## is there

REREAD_FILE: {
    my $f = MARC::File::USMARC->in( $filename );
    isa_ok( $f, 'MARC::File::USMARC' );

    my $r = $f->next();
    isa_ok( $r, 'MARC::Record' );

    # check encoding
    is( $r->encoding(), 'UTF-8', 'encoding is utf-8' );

    # check for warnings
    is( scalar( $r->warnings() ), 0, 'Reading it generated no warnings' ); 

    my $a = $r->field( 245 )->subfield( 'a' );
    ok( Encode::is_utf8( $a ), 'got actual utf8' );
    is( $a, $aleph, 'got aleph' );

    unlink( $filename );
}

WRITE_ANSEL: {
    my $r = MARC::Record->new();
    isa_ok( $r, 'MARC::Record' );
    is( $r->encoding(), 'MARC-8', 'default encoding' );

    my $f = MARC::Field->new( 245, 0, 0, a => "foo".chr(0xE2)."e" );
    isa_ok( $f, 'MARC::Field' );

    my $nadds = $r->append_fields( $f );
    is( $nadds, 1, "Added one field" );

    open( my $OUT, '>', $filename );
    print $OUT $r->as_usmarc();
    close( $OUT );    
}

READ_ANSEL: {
    my $f = MARC::File::USMARC->in( $filename );
    isa_ok( $f, 'MARC::File::USMARC' );

    my $r = $f->next();
    isa_ok( $r, 'MARC::Record' );
    is( scalar( $r->warnings() ), 0, 'Reading it generated no warnings' ); 

    is( $r->field('245')->subfield('a'), "foo".chr(0xE2)."e", 'non-utf8' );
    unlink( $filename );
}

