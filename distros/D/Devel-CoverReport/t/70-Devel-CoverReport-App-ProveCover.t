#!/usr/bin/perl

use warnings; use strict;

use Carp;
use English qw( -no_match_vars );
use File::Path 1.07 qw( rmtree );
use FindBin qw( $Bin );
use Test::More;

use lib $Bin .q{/../lib/};

# This is just a smoke test, to make sure, that the 'prove_cover' implementation works.

plan tests =>
    + 1 # runs
    + 2 # actually generates something...
;

use Devel::CoverReport::App::ProveCover;

my $tmp_dir = sprintf q{/tmp/Devel-prove_cover-%d}, $PID;

diag("Cover tmp db: ". $tmp_dir);

open STDOUT, '>', '/dev/null' or confess "Can't open STDOUT";

my $exit_code = Devel::CoverReport::App::ProveCover::main(
    q{--cover_db}, $tmp_dir,
    $Bin .q{/Samples/Simple/t/},
);
        
open STDOUT, '>', q{-} or confess "Can't re-open STDOUT";

is($exit_code, 0, "prove_cover return code");

ok (-d $tmp_dir, q{cover_db is there});

# Devel::Cover itself has some issues, so those tests are not deterministic.
#ok (-d $tmp_dir .q{/runs}, "runs are there");
#ok (-d $tmp_dir .q{/structure}, "structure is there");

if (not -d $tmp_dir .q{/runs}) {
    diag(q{Directory 'runs' is not present, this may be an issue in Devel::Cover. Be warned!});
}
if (not -d $tmp_dir .q{/structure}) {
    diag(q{Directory 'structure' is not present, this may be an issue in Devel::Cover. Be warned!});
}

ok (-f $tmp_dir .q{/cover_report.html}, "report is there");

rmtree($tmp_dir);

