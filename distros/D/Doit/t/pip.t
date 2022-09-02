#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2020 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  https://github.com/eserte/Doit
#

use Test::More;
use Doit;

my $d = Doit->init;
$d->add_component('pip');

plan skip_all => "No pip available" if !$d->can_pip;
plan 'no_plan';

{
    my @components = @{ $d->{components} };
    is($components[0]->{relpath}, 'Doit/Pip.pm', 'Pip component is correctly registered');
}

{
    my @missing_packages = $d->pip_missing_packages('this-does-not-exist');
    is_deeply(\@missing_packages, ['this-does-not-exist'], 'non-existing package detected');
}

{
    # Unfortunately older pip versions do not support --format option
    # Use info_open3 to cease stderr (may happen if there's an upgrade notice for pip3)
    chomp(my @packages = split /\n/, $d->info_open3({quiet=>1}, 'pip3', 'list'));
    if (@packages && $packages[0] =~ /^Package/) {
	shift @packages;
	if (@packages && $packages[0] =~ /^-+/) {
	    shift @packages;
	}
    }
    if (@packages) {
	my $package = $packages[0];
	if ($package =~ m{^(\S+)}) {
	    $package = $1;
	} else {
	    BAIL_OUT "Cannot parse '$package'";
	}
	my @missing_packages = $d->pip_missing_packages($package);
	is_deeply(\@missing_packages, [], "package '$package' considered already installed");
    }
}

__END__
