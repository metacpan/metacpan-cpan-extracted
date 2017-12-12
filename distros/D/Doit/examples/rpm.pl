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

use strict;
use FindBin;
use lib ("$FindBin::RealBin/../lib");

use Doit;

return 1 if caller();

require Test::More;
Test::More->import();
plan('no_plan');

my $d = Doit->init;
$d->add_component('rpm');

{
    my @components = @{ $d->{components} };
    is($components[0]->{relpath}, 'Doit/Rpm.pm');
}

{
    my $r = $d->do_ssh_connect('prod5.bbbike.org', debug=>0);
    my @missing_packages = $r->rpm_missing_packages('perl');
    is_deeply(\@missing_packages, []);
}

{
    my $r = $d->do_ssh_connect('prod5.bbbike.org', debug=>0);
    my @missing_packages = $r->rpm_missing_packages('this-package-does-not-exist');
    is_deeply(\@missing_packages, ['this-package-does-not-exist']);
}

__END__
