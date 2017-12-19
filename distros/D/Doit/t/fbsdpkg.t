#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use FindBin;
use lib $FindBin::RealBin;

use Doit;
use Test::More;

use TestUtil qw(get_sudo);

return 1 if caller;

plan skip_all => "This test script requires FreeBSD"
    if $^O ne 'freebsd';
plan 'no_plan';

my $doit = Doit->init;
$doit->add_component('fbsdpkg');

my @missing_packages = $doit->fbsdpkg_missing_packages('perl', 'pkg', 'this-package-does-not-exist');
pass 'fbsdpkg_missing_packages call was successful';
ok((grep { $_ eq 'this-package-does-not-exist' } @missing_packages), 'expected missing package');

SKIP: {
    my $number_of_tests = 1;

    my %info;
    my $sudo = TestUtil::get_sudo($doit, info => \%info);
    if (!$sudo) {
	skip $info{error}, $number_of_tests;
    }

    eval {
	$sudo->fbsdpkg_install_packages('this-package-does-not-exist');
    };
    like $@, qr{Command exited with exit code \d};
}

__END__
