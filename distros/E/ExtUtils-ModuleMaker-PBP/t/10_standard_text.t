# t/10_standard_text.t
# tests of importation of standard text from
# lib/ExtUtils/Modulemaker/Defaults.pm
use strict;
local $^W = 1;
use Test::More tests => 35;
use_ok( 'ExtUtils::ModuleMaker::PBP' );
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
        (35 - 10) if $@;
    use warnings;
    use_ok( 'File::Temp', qw| tempdir |);

    my ($tdir, $mod, $testmod, $filetext, @makefilelines, @pmfilelines,
        @readmelines);

    ########################################################################

    {   
        $tdir = tempdir( CLEANUP => 1);
        ok(chdir $tdir, 'changed to temp directory for testing');

        $testmod = 'Beta';
        
        ok( $mod = ExtUtils::ModuleMaker::PBP->new( 
                NAME           => "Alpha::$testmod",
            ),
            "call ExtUtils::ModuleMaker::PBP->new for Alpha-$testmod"
        );
        
        ok( $mod->complete_build(), 'call complete_build()' );

        ok( -d qq{Alpha-$testmod}, "compact top-level directory exists" );
        ok( chdir "Alpha-$testmod", "cd Alpha-$testmod" );

        ok(  -d, "directory $_ exists" ) for ( qw/lib t/);
        ok(! -d, "directory $_ does not exist" ) for ( qw/scripts/);
        ok( -f, "file $_ exists" )
            for ( qw/Changes LICENSE Makefile.PL MANIFEST README/);
        ok(! -f 'Todo', "Todo correctly not created");

        ok( -f, "file $_ exists" )
            for ( "lib/Alpha/${testmod}.pm", "t/00.load.t" );
        
        ok($filetext = read_file_string('Makefile.PL'),
            'Able to read Makefile.PL');
        ok(@pmfilelines = read_file_array("lib/Alpha/${testmod}.pm"),
            'Able to read module into array');

        # test of README text
        ok(@readmelines = read_file_array('README'),
            'Able to read README into array');
        is( (grep {/The README is used to introduce/} @readmelines),
            1,
            "README has correct introductory explanation");
        is( (grep {/^INSTALLATION/} @readmelines),
            1,
            "README has INSTALLATION section");
        is( (grep {/^\s+(perl Makefile\.PL|make( (test|install))?)/} 
            @readmelines), 
            4, 
            "README has appropriate build instructions for MakeMaker");
        is( (grep {/^\s+(perl Build\.PL|\.\/Build( (test|install))?)/} 
            @readmelines), 
            4, 
            "README has appropriate build instructions for Module::Build");

        ok(chdir $statusref->{cwd}, "changed back to original directory");

   } 

} # end SKIP block

END {
    _restore_pretesting_status($statusref);
}

