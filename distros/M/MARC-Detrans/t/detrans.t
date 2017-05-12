use strict;
use warnings;
use Test::More qw( no_plan );
use Test::Exception;

use_ok( 'MARC::Detrans' );
use_ok( 'MARC::Batch' );

my $detrans = MARC::Detrans->new( config => 't/testconfig.xml' );
isa_ok( $detrans, 'MARC::Detrans' );

throws_ok { MARC::Detrans->new() } qr/must supply config parameter/, 
    'no config in constructor call';

throws_ok { MARC::Detrans->new( config => 'foo' ) } 
    qr/config file doesn't exist/,
    'non-existent xml config file'; 

my $batch = MARC::Batch->new( 'USMARC', 't/marc.dat' );
while ( my $record = $batch->next() ) {
    $record = $detrans->convert( $record );
    if ( !$record ) { print $detrans->error(); next; }
    isa_ok( $record, 'MARC::Record' );
    ok( $record->field( '880' ), 'found 880 fields' );
    ok( $record->field( '066' ), 'found 066 field' );

    ## examine each 880 field
    foreach my $field ( $record->field( '880' ) ) {

        ## unpack the subfield 6 
        my $sub6 = $field->subfield(6);
        my ( $tag, $count, $script, $orientation ) = 
            $sub6 =~ m{^(\d+)-(\d+)/(..)/(.)?};

        ## verify the script code and orientation
        is( $script, '(N', 'script code' );
        is( $orientation, 'r', 'script orientation' );

        ## look for the linked field
        my $linkedField = getLinkedField( $record, $count );
        if ( ! $linkedField ) {
            fail( "missing linked field" );
        } else {
            ok( $linkedField->tag() eq $tag, "found liked 880 field" );
        }

    }
}

sub getLinkedField {
    my ($r,$count) = @_;
    foreach my $f ( $r->fields() ) {
        next if $f->is_control_field();
        my $sub6 = $f->subfield('6');
        if ( $sub6 and $sub6 eq sprintf( "880-%02d", $count ) ) {
            return $f;
        }
    }
}
