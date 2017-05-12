# t/license/looselips.t
use strict;
local $^W = 1;
use Test::More tests => 33;
use_ok( 'ExtUtils::ModuleMaker::PBP' );
use_ok( 'ExtUtils::ModuleMaker::Licenses::Local' );
use_ok( 'ExtUtils::ModuleMaker::Auxiliary', qw(
        _save_pretesting_status
        _restore_pretesting_status
        read_file_string
        licensetest
    )
);

my $statusref = _save_pretesting_status();

SKIP: {
    eval { require 5.006_001 };
    skip "tests require File::Temp, core with 5.6", 
        (33 - 11) if $@;
    use warnings;
    use_ok( 'File::Temp', qw| tempdir |);

    my ($tdir, $mod, $testmod, $filetext, $license);

    {
        $tdir = tempdir( CLEANUP => 1);
        ok(chdir $tdir, 'changed to temp directory for testing');

        $testmod = 'Beta';

        ok($mod = ExtUtils::ModuleMaker::PBP->new( 
                NAME           => "Alpha::$testmod",
                LICENSE        => 'looselips',
                COPYRIGHT_YEAR => 1899,
                AUTHOR         => "J E Keenan", 
                ORGANIZATION   => "The World Wide Webby",
        ), "object created for Alpha::$testmod");

        ok($mod->complete_build(), "build files for Alpha::$testmod");

        ok( -d qq{Alpha-$testmod}, "compact top-level directory exists" );
        ok( chdir "Alpha-$testmod", "cd Alpha-$testmod" );
        ok(  -d, "directory $_ exists" ) for ( qw/lib t/);
        ok(! -d, "directory $_ does not exist" ) for ( qw/scripts/);
        ok( -f, "file $_ exists" )
            for ( qw/ Changes LICENSE Makefile.PL MANIFEST README /);
        ok(! -f 'Todo', "Todo correctly not created as it is not default" );

        ok( -f, "file $_ exists" )
            for ( "lib/Alpha/${testmod}.pm", "t/00.load.t" );
        
        ok($filetext = read_file_string('LICENSE'),
            'Able to read LICENSE');
        
        like($filetext,
            qr/Copyright \(c\) 1899 The World Wide Webby\. All rights reserved\./, 
            "correct copyright year and organization"
        );
        ok($license = $mod->get_license(), "license retrieved"); 
        like($license,
            qr/^={69}\s+={69}.*?={69}\s+={69}.*?={69}\s+={69}/s,
            "formatting for license and copyright found as expected"
        );
    }

    ok(chdir $statusref->{cwd},
        "changed back to original directory");
} # end SKIP block

END {
    _restore_pretesting_status($statusref);
}

