# t/miscargs/910.t
# tests of miscellaneous arguments passed to constructor
use strict;
local $^W = 1;
use Test::More tests => 40;
use_ok( 'ExtUtils::ModuleMaker::PBP' );
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
        (40 - 10) if $@;
    use warnings;
    use_ok( 'File::Temp', qw| tempdir |);

    my ($tdir, $mod, $testmod, $filetext);

    ######### Set # 10:  Test of EXTRA_MODULES Option ##########
    ########## with all tests in a single file #################

    {
        $tdir = tempdir( CLEANUP => 1);
        ok(chdir $tdir, 'changed to temp directory for testing');

        $testmod = 'Sigma';
        
        ok( $mod = ExtUtils::ModuleMaker::PBP->new( 
                NAME           => "Alpha::$testmod",
                EXTRA_MODULES  => [
                    { NAME => "Alpha::${testmod}::Gamma" },
                    { NAME => "Alpha::${testmod}::Delta" },
                    { NAME => "Alpha::${testmod}::Gamma::Epsilon" },
                ],
                EXTRA_MODULES_SINGLE_TEST_FILE => 1,
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
            );
        
        my $filetext = read_file_string("t/00.load.t");
        my $number_line = q{use Test::More tests => 4;};
        ok( (index($filetext, $number_line)) > -1, 
            "test file lists predicted number in plan");
        my @use = qw(
                Alpha::Sigma
                Alpha::Sigma::Gamma
                Alpha::Sigma::Delta
                Alpha::Sigma::Gamma::Epsilon
        );
        foreach my $f (@use) {
            my $newstr = "    use_ok( '$f' );";
            ok( (index($filetext, $newstr)) > -1, 
                "test file contains use_ok for $f");
        }

    }

    ok(chdir $statusref->{cwd}, "changed back to original directory");

} # end SKIP block

END {
    _restore_pretesting_status($statusref);
}

