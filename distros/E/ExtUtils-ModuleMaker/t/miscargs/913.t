# t/miscargs/913.t
# tests of miscellaneous arguments passed to constructor
use strict;
use warnings;
use Test::More tests => 30;
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
        (30 - 10) if $@;
    use warnings;
    use_ok( 'File::Temp', qw| tempdir |);

    my ($tdir, $mod, $testmod, $filetext);

    ##### Set 13:  Test of INCLUDE_MANIFEST_SKIP option #####

    {
        $tdir = tempdir( CLEANUP => 1);
        ok(chdir $tdir, 'changed to temp directory for testing');

        $testmod = 'Phi';
        
        ok( $mod = ExtUtils::ModuleMaker->new( 
                NAME           => "Alpha::$testmod",
                COMPACT        => 1,
                INCLUDE_MANIFEST_SKIP => 1,
            ),
            "call ExtUtils::ModuleMaker->new for Alpha-$testmod"
        );
        
        ok( $mod->complete_build(), 'call complete_build()' );

        ok( -d qq{Alpha-$testmod}, "compact top-level directory exists" );
        ok( chdir "Alpha-$testmod", "cd Alpha-$testmod" );
        ok( -d, "directory $_ exists" ) for ( qw/lib scripts t/);
        ok( -f, "file $_ exists" )
            for ( qw|
                Changes     LICENSE Makefile.PL 
                MANIFEST    README  Todo        MANIFEST.SKIP
            | );
        ok( -f, "file $_ exists" )
            for ( "lib/Alpha/${testmod}.pm", "t/001_load.t" );
        
        ok($filetext = read_file_string('Makefile.PL'),
            'Able to read Makefile.PL');
    }

    ok(chdir $statusref->{cwd},
        "changed back to original directory");
} # end SKIP block

END {
    _restore_pretesting_status($statusref);
}

