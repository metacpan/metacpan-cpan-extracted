#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::DZil;

my $tzil = Builder->from_config( { dist_root => 'corpus/DZ' } );

$tzil->build;

my $got = $tzil->slurp_file('build/t/basic.t');

my $expected = <<'HERE';
#!/usr/bin/perl
use 5.008;
use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More tests => 1;
use File::Find;

fail("meh");
HERE

is( $got, $expected, "Test::DiagINC line inserted" );

my $tr = $tzil->prereqs->requirements_for(qw/test requires/);

is( $tr->requirements_for_module("Test::DiagINC"),
    "0.002", "Test::DiagINC added to Test/Requires" );

done_testing;
