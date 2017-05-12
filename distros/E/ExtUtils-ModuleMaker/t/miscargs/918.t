# t/miscargs/918.t
# tests of miscellaneous arguments passed to constructor
use strict;
use warnings;
use Test::More tests => 41;
use_ok( 'ExtUtils::ModuleMaker' );
use_ok( 'ExtUtils::ModuleMaker::Auxiliary', qw(
        _save_pretesting_status
        _restore_pretesting_status
        read_file_string
    )
);

my $statusref = _save_pretesting_status();

SKIP: {
    eval { require 5.006_001 };
    skip "tests require File::Temp, core with 5.6", 
        (41 - 10) if $@;
    use warnings;
    use_ok( 'File::Temp', qw| tempdir |);

    my $odir = $statusref->{cwd};
    my ($tdir, $mod, $testmod);

    ##### Set 18:  Test of INCLUDE_FILE_IN_PM option #####

    {
        $tdir = tempdir( CLEANUP => 1);
        ok(chdir $tdir, 'changed to temp directory for testing');

        $testmod = 'Kappa';
        
        ok( $mod = ExtUtils::ModuleMaker->new( 
                NAME           => "Alpha::$testmod",
                COMPACT        => 1,
                EXTRA_MODULES  => [
                    { NAME => "Alpha::${testmod}::Gamma" },
                    { NAME => "Alpha::${testmod}::Delta" },
                    { NAME => "Alpha::${testmod}::Gamma::Epsilon" },
                ],
                INCLUDE_FILE_IN_PM => "$odir/t/testlib/arbitrary.txt",
            ),
            "call ExtUtils::ModuleMaker->new for Alpha-$testmod"
        );
        
        ok( $mod->complete_build(), 'call complete_build()' );

        ok( -d qq{Alpha-$testmod}, "compact top-level directory exists" );
        ok( chdir "Alpha-$testmod", "cd Alpha-$testmod" );
        ok( -d, "directory $_ exists" ) for ( qw/lib scripts t/);

        ok( -f, "file $_ exists" )
            for ( qw|
                Changes     LICENSE      Makefile.PL 
                MANIFEST    README       Todo
            | );

        ok( -d, "directory $_ exists" ) for (
                "lib/Alpha",
                "lib/Alpha/${testmod}",
                "lib/Alpha/${testmod}/Gamma",
            );

        my @pm_pred = (
                "lib/Alpha/${testmod}.pm",
                "lib/Alpha/${testmod}/Gamma.pm",
                "lib/Alpha/${testmod}/Delta.pm",
                "lib/Alpha/${testmod}/Gamma/Epsilon.pm",
        );
        my @t_pred = (
                't/001_load.t',
                't/002_load.t',
                't/003_load.t',
                't/004_load.t',
        );
        ok( -f, "file $_ exists" ) for ( @pm_pred, @t_pred);
        for my $pm (@pm_pred) {
            my $line = read_file_string($pm);
            like($line, qr<=pod.+INCLUDE_FILE_IN_PM.+sub marine \{}>s,
                "$pm contains pod header, key-value pair, sub");
        }
    }

    ok(chdir $statusref->{cwd},
        "changed back to original directory");
} # end SKIP block

END {
    _restore_pretesting_status($statusref);
}

