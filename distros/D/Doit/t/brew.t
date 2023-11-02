#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2017 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

use File::Basename qw(basename);
use File::Glob qw(bsd_glob);
use Test::More;

use Doit;

plan skip_all => "Not on Mac OS X" if $^O ne 'darwin';

my $d = Doit->init;
$d->add_component('brew');

plan skip_all => "No homebrew available" if !$d->can_brew;
plan 'no_plan';

if (0) {
    # activate if homebrew needs an update before
    $d->system(qw(brew update));
}

{
    my @components = @{ $d->{components} };
    is($components[0]->{relpath}, 'Doit/Brew.pm');
}

{
    my @missing_packages = $d->brew_missing_packages('this-does-not-exist');
    is_deeply(\@missing_packages, ['this-does-not-exist']);
}

{
    my($package) = bsd_glob("/usr/local/Cellar/*");
    if ($package) {
	$package = basename $package;
	my @missing_packages = $d->brew_missing_packages($package);
	is_deeply(\@missing_packages, []);
    }
}

if ($ENV{GITHUB_ACTIONS}) {
    my $test_package = 'hello';
    $d->brew_install_packages($test_package);
    my @missing_packages = $d->brew_missing_packages($test_package);
    is_deeply(\@missing_packages, []);
    ok !$d->brew_install_packages($test_package), 'no packages to be installed';
}

__END__
