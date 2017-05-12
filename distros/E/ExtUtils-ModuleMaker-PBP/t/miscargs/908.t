# t/miscargs/908.t
# tests of miscellaneous arguments passed to constructor
use strict;
local $^W = 1;
use Test::More tests => 37;
use_ok( 'ExtUtils::ModuleMaker::PBP' );
use_ok( 'ExtUtils::ModuleMaker::Auxiliary', qw(
        _save_pretesting_status
        _restore_pretesting_status
    )
);

my $statusref = _save_pretesting_status();

SKIP: {
    eval { require 5.006_001 };
    skip "tests require File::Temp, core with 5.6", 
        (37 - 10) if $@;
    use warnings;
    use_ok( 'File::Temp', qw| tempdir |);

    my ($tdir, $mod, $testmod);

    ######### Set #8:  Test of EXTRA_MODULES Option ##########

    {
        $tdir = tempdir( CLEANUP => 1);
        ok(chdir $tdir, 'changed to temp directory for testing');

        $testmod = 'Sigma';
        
        ok( $mod = ExtUtils::ModuleMaker::PBP->new( 
                NAME           => "Alpha::$testmod",
                COMPACT        => 1,
                EXTRA_MODULES  => [
                    { NAME => "Alpha::${testmod}::Gamma" },
                    { NAME => "Alpha::${testmod}::Delta" },
                    { NAME => "Alpha::${testmod}::Gamma::Epsilon" },
                ],
            ),
            "call ExtUtils::ModuleMaker::PBP->new for Alpha-$testmod"
        );
        
        ok( $mod->complete_build(), 'call complete_build()' );

        ok( -d qq{Alpha-$testmod}, "compact top-level directory exists" );
        ok( chdir "Alpha-$testmod", "cd Alpha-$testmod" );

        ok(  -d, "directory $_ exists" ) for ( qw/lib lib\/Alpha t/);
        ok(! -d, "directory $_ does not exist" ) for ( qw/scripts/);
        ok(  -f, "file $_ exists" )
            for ( qw/Changes LICENSE Makefile.PL MANIFEST README/);
        ok(! -f 'Todo', "Todo file correctly not created");

        ok( -d, "directory $_ exists" ) for (
                "lib/Alpha",
                "lib/Alpha/${testmod}",
                "lib/Alpha/${testmod}/Gamma",
            );
        ok( -f, "file $_ exists" )
            for (
                "lib/Alpha/${testmod}.pm",
                "lib/Alpha/${testmod}/Gamma.pm",
                "lib/Alpha/${testmod}/Delta.pm",
                "lib/Alpha/${testmod}/Gamma/Epsilon.pm",
                't/00.load.t',
                't/pod-coverage.t',
                't/pod.t',
            );
        
    }

    ok(chdir $statusref->{cwd}, "changed back to original directory");

} # end SKIP block

END {
    _restore_pretesting_status($statusref);
}

