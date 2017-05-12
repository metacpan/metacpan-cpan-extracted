# t/miscargs/909.t
# tests of miscellaneous arguments passed to constructor
use strict;
local $^W = 1;
use Test::More tests => 31;
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
        (31 - 10) if $@;
    use warnings;
    use_ok( 'File::Temp', qw| tempdir |);

    my ($tdir, $mod, $testmod, $filetext);

    # Set 9:  Test VERSION for value other than 0.01; make sure it is quoted
    # in .pm file.

    {
        $tdir = tempdir( CLEANUP => 1);
        ok(chdir $tdir, 'changed to temp directory for testing');

        $testmod = 'Beta';
        
        ok( $mod = ExtUtils::ModuleMaker::PBP->new( 
                NAME           => "Alpha::$testmod",
                VERSION        => q{0.3},
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

        ok( -f, "file $_ exists" )
            for ( "lib/Alpha/${testmod}.pm", "t/00.load.t" );
        
        ok($filetext = read_file_string("lib/Alpha/$testmod.pm"),
            "Able to read lib/Alpha/$testmod.pm");
        like($filetext, qr/\$VERSION.+?'0\.3'/,
            "VERSION number is correct and properly quoted");
        
    }

    ok(chdir $statusref->{cwd}, "changed back to original directory");

} # end SKIP block

END {
    _restore_pretesting_status($statusref);
}

