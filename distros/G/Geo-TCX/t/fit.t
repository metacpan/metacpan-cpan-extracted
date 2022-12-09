# t/fit.t - Test parsing of Garmin FIT files
use strict;
use warnings;
use Test::More;
use Geo::TCX;

eval "use Geo::FIT";
if ($@) {
    plan skip_all => "Geo::FIT not available"
} else {
    eval "Geo::TCX::_check_fit2tcx_pl_version()";
    if ($@) {
        my $msg;
        $msg = $1 if $@ =~ m/(.*)\n/;
        plan skip_all => $msg;
    }
    plan tests => 2;
}

unlink 't/10004793344_ACTIVITY.tcx';

my $o  = Geo::TCX->new('t/10004793344_ACTIVITY.fit');
isa_ok ($o,  'Geo::TCX');

$o->save();
is(-f $o->set_filename(), 1, "    save(): converted .fit file saved as a .tcx file");
unlink 't/10004793344_ACTIVITY.tcx';

print "so debugger doesn't exit\n";

