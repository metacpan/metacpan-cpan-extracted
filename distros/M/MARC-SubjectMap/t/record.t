use Test::More qw(no_plan);
use strict;
use warnings;

use MARC::Batch;
use MARC::SubjectMap;


my $batch = MARC::Batch->new( 'USMARC', 't/record.dat' );
my $record = $batch->next();
ok( !foundField($record), 'translated field not present before' );

my $map = MARC::SubjectMap->newFromConfig( 't/config.xml' );
my $new = $map->translateRecord( $record );
ok( foundField($new), 'translated field present afterwards' );

sub foundField {
    my $r = shift;
    foreach my $f ( $r->field('650') ) {
        my @subfields = $f->subfields();
        return 1 
            if $subfields[0][0] eq 'a' 
            and $subfields[0][1] eq 'Python (Computer program language)'
            and $subfields[1][0] eq '2'
            and $subfields[1][1] eq 'bogus'; 
    }
    return 0;
}

