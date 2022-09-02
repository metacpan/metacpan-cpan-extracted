#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use FindBin;
use lib $FindBin::RealBin;

use Test::More;

use Doit;

my $d = Doit->init;

plan skip_all => 'Only for linux' if $^O ne 'linux';
for my $exe (qw(dpkg apt-get)) {
    if (!$d->which($exe)) {
	plan skip_all => "$exe not in PATH (maybe not a Debian system?)";
    }
}

plan 'no_plan';

$d->add_component('deb');

{
    my @components = @{ $d->{components} };
    is $components[0]->{relpath}, 'Doit/Deb.pm', 'Doit::Deb is loaded';
}

{
    my @missing_packages = $d->deb_missing_packages('this-does-not-exist');
    is_deeply \@missing_packages, ['this-does-not-exist'], 'expected list of missing packages';
}

my $test_package = 'dpkg'; # most likely to be installed on an debian/ubuntu system

SKIP: {
    skip "no /usr/bin/$test_package available, so there's no $test_package package", 1
	if !-x "/usr/bin/$test_package";

    my @missing_packages = $d->deb_missing_packages($test_package);
    is_deeply \@missing_packages, [], "exepcted list of missing packages ($test_package already installed)";
}

SKIP: {
    skip 'deb manipulations only on CI systems', 1
	if !$ENV{GITHUB_ACTIONS};

    {
	my @installed_packages = $d->deb_install_packages($test_package);
	is_deeply \@installed_packages, [], "$test_package was already installed";
    }
}

__END__
