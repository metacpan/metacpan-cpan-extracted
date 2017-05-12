# t/10_standard_text.t
# tests of importation of standard text from
# lib/ExtUtils/Modulemaker/Defaults.pm
use strict;
use warnings;
use Test::More tests =>   43;
use_ok( 'ExtUtils::ModuleMaker' );
use_ok( 'ExtUtils::ModuleMaker::Auxiliary', qw(
        _save_pretesting_status
        _restore_pretesting_status
        read_file_string
        read_file_array
    )
);

my $statusref = _save_pretesting_status();

SKIP: {
    eval { require 5.006_001 };
    skip "tests require File::Temp, core with 5.6", 
        (43 - 10) if $@;
    use warnings;
    use_ok( 'File::Temp', qw| tempdir |);

    my ($tdir, $mod, $testmod, $filetext, @makefilelines, @pmfilelines,
        @readmelines);

    ########################################################################

    {   
        $tdir = tempdir( CLEANUP => 1);
        ok(chdir $tdir, 'changed to temp directory for testing');

        $testmod = 'Beta';
        
        ok( $mod = ExtUtils::ModuleMaker->new( 
                NAME           => "Alpha::$testmod",
                COMPACT        => 1,
            ),
            "call ExtUtils::ModuleMaker->new for Alpha-$testmod"
        );
        
        ok( $mod->complete_build(), 'call complete_build()' );

        ok( -d qq{Alpha-$testmod}, "compact top-level directory exists" );
        ok( chdir "Alpha-$testmod", "cd Alpha-$testmod" );
        ok( -d, "directory $_ exists" ) for ( qw/lib scripts t/);
        ok( -f, "file $_ exists" )
            for ( qw/Changes LICENSE Makefile.PL MANIFEST README Todo/);
        ok( -f, "file $_ exists" )
            for ( "lib/Alpha/${testmod}.pm", "t/001_load.t" );
        
        ok($filetext = read_file_string('Makefile.PL'),
            'Able to read Makefile.PL');
        ok(@pmfilelines = read_file_array("lib/Alpha/${testmod}.pm"),
            'Able to read module into array');

        # test of main pod wrapper
        is( (grep {/^#{20} main pod documentation (begin|end)/} @pmfilelines), 2, 
            "standard text for POD wrapper found");

        # test of block new method
        is( (grep {/^sub new/} @pmfilelines), 1, 
            "new method found");

        # test of block module header description
        is( (grep {/^sub new/} @pmfilelines), 1, 
            "new method found");

        # test of stub documentation
        is( (grep {/^Stub documentation for this module was created/} @pmfilelines), 
            1, 
            "stub documentation found");

        # test of subroutine header
        is( (grep {/^#{20} subroutine header (begin|end)/} @pmfilelines), 2, 
            "subroutine header found");

        # test of final block
        is( (grep { /^(1;|# The preceding line will help the module return a true value)$/ } @pmfilelines), 2, 
            "final module block found");

        # test of Makefile text
        ok(@makefilelines = read_file_array('Makefile.PL'),
            'Able to read Makefile.PL into array');
        is( (grep {/^# See lib\/ExtUtils\/MakeMaker.pm for details of how to influence/} @makefilelines), 1, 
            "Makefile.PL has standard text");

        # test of README text
        ok(@readmelines = read_file_array('README'),
            'Able to read README into array');
        is( (grep {/^pod2text $mod->{NAME}/} @readmelines),
            1,
            "README has correct pod2text line");
        is( (grep {/^If this is still here/} @readmelines),
            1,
            "README has correct top part");
        is( (grep {/^(perl Makefile\.PL|make( (test|install))?)/} @readmelines), 
            4, 
            "README has appropriate build instructions for MakeMaker");
        is( (grep {/^If you are on a windows box/} @readmelines),
            1,
            "README has correct bottom part");
    }
 

    ok(chdir $statusref->{cwd},
        "changed back to original directory");
} # end SKIP block

END {
    _restore_pretesting_status($statusref);
}

