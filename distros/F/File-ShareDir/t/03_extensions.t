use strict;
use warnings;

use Test::More;

# ABSTRACT: Test for overriding paths

use File::ShareDir qw( dist_dir dist_file module_dir module_file );
use Cwd qw( getcwd );

my $FAKE_DIST   = 'Fake-Sample-Dist';
my $FAKE_MODULE = 'Fake::Sample::Module';

{

    package Fake::Sample::Module;
    $INC{'Fake/Sample/Module.pm'} = 1;
}

$File::ShareDir::DIST_SHARE{$FAKE_DIST}     = getcwd;
$File::ShareDir::MODULE_SHARE{$FAKE_MODULE} = getcwd;

is(dist_dir($FAKE_DIST), getcwd, "Fake distribution resolves to forced value");
ok(-f dist_file($FAKE_DIST, 't/03_extensions.t'), "Fake distribution resolves to forced value with a file");

is(module_dir($FAKE_MODULE), getcwd, "Fake module resolves to forced value");
ok(-f module_file($FAKE_MODULE, 't/03_extensions.t'), "Fake module resolves to forced value with a file");

done_testing;

