# t/miscargs/902.t
# tests of miscellaneous arguments passed to constructor
use strict;
local $^W = 1;
use Test::More tests => 33;
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
        (33 - 10) if $@;
    use warnings;
    use_ok( 'File::Temp', qw| tempdir |);
    use lib('t/testlib');
    use_ok( 'IO::Capture::Stdout' );

    my ($tdir, $mod, $testmod, $filetext);

    # Set 2:  Test VERBOSE => 1 to make sure that logging messages
    # note each directory and file created. Non-compact top directory.

    {
        $tdir = tempdir( CLEANUP => 1);
        ok(chdir $tdir, 'changed to temp directory for testing');

        $testmod = 'Gamma';
        
        ok( $mod = ExtUtils::ModuleMaker::PBP->new( 
                NAME           => "Alpha::$testmod",
                COMPACT        => 0,
                VERBOSE        => 1,
            ),
            "call ExtUtils::ModuleMaker::PBP->new for Alpha-$testmod"
        );
        
        my ($capture, %count);
        $capture = IO::Capture::Stdout->new();
        $capture->start();
        ok( $mod->complete_build(), 'call complete_build()' );
        $capture->stop();
        for my $l ($capture->read()) {
            $count{'mkdir'}++ if $l =~ /^mkdir/;
            $count{'writing'}++ if $l =~ /^writing file/;
        }
        is($count{'mkdir'}, 5, "correct no. of directories created announced verbosely");
        is($count{'writing'}, 9, "correct no. of files created announced verbosely");

        ok( -d qq{Alpha/$testmod}, "non-compact top-level directories exist" );
        ok( chdir "Alpha/$testmod", "cd Alpha/$testmod" );
        ok(  -d, "directory $_ exists" ) for ( qw/lib lib\/Alpha t/);
        ok(! -d, "directory $_ does not exist" ) for ( qw/scripts/);
        ok(  -f, "file $_ exists" )
            for ( qw/Changes LICENSE Makefile.PL MANIFEST README/);
        ok(! -f 'Todo', "Todo file correctly not created");
        ok( -f, "file $_ exists" )
            for ( "lib/Alpha/${testmod}.pm", "t/00.load.t" );
        
        ok($filetext = read_file_string('Makefile.PL'),
            'Able to read Makefile.PL');
        
    }

    ok(chdir $statusref->{cwd}, "changed back to original directory");

} # end SKIP block

END {
    _restore_pretesting_status($statusref);
}

