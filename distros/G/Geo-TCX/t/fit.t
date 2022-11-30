# t/fit.t - Test parsing of Garmin FIT files
use strict;
use warnings;
use Test::More;
use Geo::TCX;

eval "use Geo::FIT";
if ($@) {
    plan skip_all => "requires Geo::FIT"
} else {
    plan tests => 2;
}

unlink 't/10004793344_ACTIVITY.tcx';

my $o  = Geo::TCX->new('t/10004793344_ACTIVITY.fit');
isa_ok ($o,  'Geo::TCX');

$o->save();
is(-f $o->set_filename(), 1, "    save(): converted .fit file saved as a .tcx file");
unlink 't/10004793344_ACTIVITY.tcx';

print "so debugger doesn't exit\n";

