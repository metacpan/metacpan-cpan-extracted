use blib;
use Test::More tests => 104;
use strict;
use warnings;
use vars qw( *RT1 );

use_ok( "Geo::TigerLine::Record::1" );

my ($sample) = grep( -r $_, "sample.rt1", "t/sample.rt1" );
die "Sample data missing" unless $sample;

open RT1, $sample
    or die "Can't read $sample: $!";

my @records = Geo::TigerLine::Record::1->parse_file( \*RT1 );

is( scalar(@records), 6, "Correct number of records loaded" );
isa_ok( $records[0], "Geo::TigerLine::Record::1", "First record" );
is( $records[0]->rt, 1, "First record has correct TIGER/Line type" );
is( $records[0]->{rt}, 1, "Smells like a hash, tastes like a hash" );
for (@records) {
    is($_->statel, "06", "Correct state on left");
    is($_->stater, "06", "Correct state on right");
    is($_->countyl, "075", "Correct county on left");
    is($_->countyr, "075", "Correct county on right");
    is($_->cfcc, "A41", "Correct CFCC type");
    is($_->placel, "67000", "Correct place on left");
    is($_->placer, "67000", "Correct place on right");
}

seek(RT1, 0, 0);
my $count = 0;
Geo::TigerLine::Record::1->parse_file(\*RT1, sub {
    my $record = shift;
    isa_ok( $record, "Geo::TigerLine::Record::1", "Callback object" );
    is( $record->fedirp, "", "Direction prefix" );
    is( $record->fename, "Elsie", "Feature name" );
    is( $record->fetype, "St", "Feature type" );
    is( $record->fedirs, "", "Feature suffix" );
    is( ($record->$_ > 0) && ($record->$_ < 400), 1, "$_ in range" )
	for (qw( fraddr toaddr fraddl toaddl ));
    $count++;
});

is($count, 6, "Callback called correct number of times");

my $obj = Geo::TigerLine::Record::1->new;
isa_ok( $obj, "Geo::TigerLine::Record::1", "synthetic record" );
$obj->rt(1);
is( $obj->rt, 1, "get/set works" );
