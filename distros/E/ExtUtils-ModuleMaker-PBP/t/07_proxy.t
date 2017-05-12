# t/07_proxy.t
use strict;
local $^W = 1;
use Test::More 
tests => 56;
use_ok( 'ExtUtils::ModuleMaker::PBP' );
use_ok( 'ExtUtils::ModuleMaker::Auxiliary', qw(
        _save_pretesting_status
        _restore_pretesting_status
        read_file_string
        six_file_tests
    )
);

my $statusref = _save_pretesting_status();

SKIP: {
    eval { require 5.006_001 and require Module::Build };
    skip "tests require File::Temp, core with 5.6, and require Module::Build", 
        (56 - 10) if $@;
    use warnings;
    use_ok( 'File::Temp', qw| tempdir |);

    my $tdir = tempdir( CLEANUP => 1);
    ok(chdir $tdir, 'changed to temp directory for testing');

    ########################################################################

    my ($mod, $filetext);
    my $testmod = 'Delta';

    ########## Variant:  'Module::Build and proxy Makefile.PL' ##########

    ok( $mod = ExtUtils::ModuleMaker::PBP->new(
            NAME           => "Alpha::$testmod",
            ABSTRACT       => 'Test of the capacities of EU::MM',
            CHANGES_IN_POD => 1,
            BUILD_SYSTEM   => 'Module::Build and proxy Makefile.PL',
            AUTHOR         => 'Phineas T. Bluster',
            CPANID         => 'PTBLUSTER',
            ORGANIZATION   => 'Peanut Gallery',
            WEBSITE        => 'http://www.anonymous.com/~phineas',
            EMAIL          => 'phineas@anonymous.com',
        ),
        "call ExtUtils::ModuleMaker::PBP->new for Alpha-$testmod"
    );

    ok( $mod->complete_build(), 'call complete_build()' );

    ok( chdir "Alpha-$testmod", "cd Alpha-$testmod" );

    ok(  -d, "directory $_ exists" ) for ( qw/lib t/);
    ok(! -d, "directory $_ does not exist" ) for ( qw/scripts/);

    ok(  -f $_, "file $_ exists") for (qw/LICENSE Build.PL MANIFEST README/);
    ok(! -f $_, "$_ file correctly not created") for (qw/Todo Changes/);

    ok($filetext = read_file_string('Makefile.PL'),
        'Able to read Makefile.PL');
    ok($filetext =~ m|Module::Build::Compat|,
        'Makefile.PL will call Module::Build or install it');

    ok($filetext = read_file_string('Build.PL'),
        'Able to read Build.PL');

    six_file_tests(9, $testmod); # first arg is # entries in MANIFEST

    ########## Variant:  'Module::Build and Proxy' ##########

    ok( $mod = ExtUtils::ModuleMaker::PBP->new(
            NAME           => "Alpha::$testmod",
            ABSTRACT       => 'Test of the capacities of EU::MM',
            CHANGES_IN_POD => 1,
            BUILD_SYSTEM   => 'Module::Build and Proxy',
            AUTHOR         => 'Phineas T. Bluster',
            CPANID         => 'PTBLUSTER',
            ORGANIZATION   => 'Peanut Gallery',
            WEBSITE        => 'http://www.anonymous.com/~phineas',
            EMAIL          => 'phineas@anonymous.com',
        ),
        "call ExtUtils::ModuleMaker::PBP->new for Alpha-$testmod"
    );

    ok( $mod->complete_build(), 'call complete_build()' );

    ok( chdir "Alpha-$testmod", "cd Alpha-$testmod" );

    ok(  -d, "directory $_ exists" ) for ( qw/lib t/);
    ok(! -d, "directory $_ does not exist" ) for ( qw/scripts/);

    ok(  -f $_, "file $_ exists")
        for (qw/LICENSE Build.PL Makefile.PL MANIFEST README/);
    ok(! -f $_, "$_ file correctly not created") for (qw/Todo Changes/);

    ok($filetext = read_file_string('Makefile.PL'),
        'Able to read Makefile.PL');
    ok($filetext =~ m|Module::Build::Compat|,
        'Makefile.PL will call Module::Build or install it');

    ok($filetext = read_file_string('Build.PL'),
        'Able to read Build.PL');

    six_file_tests(9, $testmod); # first arg is # entries in MANIFEST
 
    ok(chdir $statusref->{cwd}, "changed back to original directory");

} # end SKIP block

END {
    _restore_pretesting_status($statusref);
}

