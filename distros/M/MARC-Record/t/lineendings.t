#!perl -Tw

use strict;

use Test::More;
use vars qw( @endings );
use File::Spec;

BEGIN {
    @endings = qw( 0a 0d 0d0a );
    plan( tests => @endings*13 + 2 );
    use_ok( 'MARC::Record' );
    use_ok( 'MARC::File::MicroLIF' );
}


foreach my $ending ( @endings ) {
    my $filename = File::Spec->catfile( 't', "lineendings-$ending.lif" );
    my $file = MARC::File::MicroLIF->in( $filename );
    isa_ok( $file, 'MARC::File::MicroLIF' );
    is( scalar $file->warnings(), 0, 'no file warnings for $filename' );

    my $record = $file->next();
    isa_ok( $record, 'MARC::Record', 'successfully decoded' );
    is( scalar $record->warnings(), 0, 'no record warnings' );

    is( scalar $record->fields(), 7, 'checking the number of fields in the record' );
    is( $record->leader(),                  '00180nam  22     2  4500', "checking $filename LDR" );
    is( $record->field('008')->as_string(), '891207s19xx    xxu           00010 eng d', "checking $filename 008" );
    is( $record->field('040')->as_string(), 'IMchF', "checking $filename 040" );
    is( $record->field('245')->as_string(), 'All about whales.', "checking $filename 245" );
    is( $record->field('260')->as_string(), 'Holiday, 1987.', "checking $filename 260" );
    is( $record->field('300')->as_string(), '[ ] p.', "checking $filename 300" );
    is( $record->field('900')->as_string(), 'ALL', "checking $filename 900" );
    is( $record->field('952')->as_string(), '20571 R ALL', "checking $filename 952" );

    $file->close();
}
