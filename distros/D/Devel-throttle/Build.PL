#! /usr/local/bin/perl # -*- perl -*-

# This file is part of Devel-throttle.
# Copyright (C) 2009 Guido Flohr <guido@imperia.net>, 
# all rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;

use Module::Build;

my $build = Module::Build->new (
	module_name => 'Devel::throttle',
	licence => 'artistic',
	dist_abstract => 'Slow down execution of Perl scripts',
);

$build->create_build_script;
