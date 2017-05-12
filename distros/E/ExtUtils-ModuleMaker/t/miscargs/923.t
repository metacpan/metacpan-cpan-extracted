# t/miscargs/923.t
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
        (32 - 10) if $@;
    use warnings;
    use_ok( 'File::Temp', qw| tempdir |);

    my ($tdir, $mod, $testmod, $filetext);

    # Test insertion of warnings in .pm files.

    {   
        $tdir = tempdir( CLEANUP => 1);
        ok(chdir $tdir, 'changed to temp directory for testing');

        $testmod = 'Lambda';
        
        ok( $mod = ExtUtils::ModuleMaker->new( 
                NAME           => "Alpha::$testmod",
                COMPACT        => 1,
                AUTHOR         => 'Phineas T. Bluster',
                CPANID         => 'PTBLUSTER',
                ORGANIZATION   => 'Peanut Gallery',
                EMAIL          => 'phineas@anonymous.com',
                INCLUDE_ID_LINE => 1,
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
            );

        my @pm_pred = (
                "lib/Alpha/${testmod}.pm",
        );
        my @t_pred = (
                't/001_load.t',
        );
        ok( -f, "file $_ exists" ) for ( @pm_pred, @t_pred);
        my $line = read_file_string("lib/Alpha/${testmod}.pm");
        ok($line =~ m|
                #$Id#\n
                use\sstrict;\n
            |xs,
            q<.pm file contains 'Id' string>);
    }

    ok(chdir $statusref->{cwd},
        "changed back to original directory");
} # end SKIP block

END {
    _restore_pretesting_status($statusref);
}

