#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use FindBin;
use lib $FindBin::RealBin;

use Doit;
use Doit::Extcmd qw(is_in_path);
use Test::More;

use TestUtil qw(get_sudo);

return 1 if caller;

plan skip_all => "This test script requires Linux"
    if $^O ne 'linux';
plan skip_all => "This test script requires yum"
    if !is_in_path('yum');
plan skip_all => "This test script requires rpm"
    if !is_in_path('rpm');
plan 'no_plan';

my $doit = Doit->init;
$doit->add_component('rpm');

my @missing_packages = $doit->rpm_missing_packages('perl', 'yum', 'this-package-does-not-exist');
pass 'rpm_missing_packages call was successful';
ok((grep { $_ eq 'this-package-does-not-exist' } @missing_packages), 'expected missing package');

SKIP: {
    my $number_of_tests = 1;

    my %info;
    my $sudo = TestUtil::get_sudo($doit, info => \%info);
    if (!$sudo) {
	skip $info{error}, $number_of_tests;
    }

    eval {
	$sudo->rpm_install_packages('this-package-does-not-exist');
    };
    like $@, qr{Command exited with exit code \d}, 'expected error message when trying to install non-existent package';
}

__END__
