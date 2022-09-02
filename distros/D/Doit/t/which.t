#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

plan 'no_plan';

use Doit;

my $doit = Doit->init;

my $tempdir = tempdir('doit_XXXXXXXX', TMPDIR => 1, CLEANUP => 1);

my $testcmdbase = "doit-which-test-command-$$";
my $testcmdpath = File::Spec->catfile($tempdir, $testcmdbase . ($^O eq 'MSWin32' ? '.bat' : ''));
$doit->create_file_if_nonexisting($testcmdpath);
$doit->chmod(0755, $testcmdpath);

{
    eval { $doit->which };
    like $@, qr{Expecting exactly one argument: command};

    eval { $doit->which(1,2) };
    like $@, qr{Expecting exactly one argument: command};
}

{
    ok !$doit->which($testcmdbase);
    is $doit->which($testcmdbase), undef;
}

{
    require Config;
    %Config::Config = %Config::Config if 0; # cease -w
    my $sep = $Config::Config{'path_sep'} || ':';
    local $ENV{PATH} = join $sep, $ENV{PATH}, $tempdir;
    ok $doit->which($testcmdbase);
    is $doit->which($testcmdbase), $testcmdpath;
}
