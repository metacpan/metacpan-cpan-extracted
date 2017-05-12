use Test::More;
use strict;
my $tests;
BEGIN { $tests = 0 }
use lib "lib";
use File::Path qw(mkpath rmtree);
use YAML::Syck ();

my $root_from = "t/ta";
my $root_to = "t/tb";
rmtree [$root_from, $root_to];

{
    # empty directory
    BEGIN { $tests += 5 }
    mkpath $root_from;
    my $ret = system $^X, "-Ilib", "bin/rrr-init", $root_from;
    my $prf = "$root_from/RECENT-1h.yaml";
    ok(-e $prf, "recent file exists");
    ok(-l "$root_from/RECENT.recent", "recent symlink exists");
    my $y = YAML::Syck::LoadFile $prf;
    ok(! defined $y->{meta}{minmax}{min}, "minmax/min is undef");
    my $recent = $y->{recent};
    is(ref $recent, "ARRAY", "recent is an array");
    ok(0 == scalar @$recent, "array is empty");
}

BEGIN {
    plan tests => $tests
}

rmtree [$root_from, $root_to];

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# End:
