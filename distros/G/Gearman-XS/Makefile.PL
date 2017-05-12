# Gearman Perl front end
# Copyright (C) 2013 Data Differential, http://datadifferential.com/
# Copyright (C) 2009-2010 Dennis Schoen
# All rights reserved.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.8.9 or,
# at your option, any later version of Perl 5 you may have available.

use strict;
use warnings;
use inc::Module::Install;
use Env qw(GEARMAN_LIB GEARMAN_INCLUDE);
use vars qw($INCLUDES $CCFLAGS);

my $LIBS = '';
$CCFLAGS = '-Wall -Wundef -Wno-shadow -Wmissing-prototypes -fdiagnostics-show-option -Wformat=2 -Wstrict-aliasing -Wextra -Wmissing-declarations -Wcast-align -Wswitch-default -Wswitch-enum -Wno-undef -Wno-unused-value -Wno-unused-variable -Wno-unused-parameter -Wno-format-invalid-specifier';

if (defined $GEARMAN_LIB) {
  print STDERR "Using GEARMAN_LIB = $GEARMAN_LIB\n";
  $LIBS .= " -L$GEARMAN_LIB ";
}

if (defined $GEARMAN_INCLUDE) {
  print STDERR "Using GEARMAN_INCLUDE = $GEARMAN_INCLUDE\n";
  $INCLUDES .= " -I$GEARMAN_INCLUDE";
}

$LIBS .= ' -lgearman';

name 'Gearman-XS';
license 'perl';
all_from 'lib/Gearman/XS.pm';
no_index directory => 'examples';

can_xs or die "This module requires a C compiler";

makemaker_args(
    INC     => $INCLUDES,
    LIBS    => $LIBS,
    CCFLAGS => $CCFLAGS,
    clean   => {
        FILES => q{
            MANIFEST
            inc
            META.yml
            Makefile.old
        },
    },
);

cc_files map { "$_\.c" } qw/XS Const Client Worker Job Task/;
tests 't/*.t';

test_requires 'Test::More';
test_requires 'Storable';
WriteAll;
