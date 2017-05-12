#
# Makefile.PL
#
# $Revision: 1.1.1.1 $
#
# Copyright (C) 2001 Gregor N. Purdy. All rights reserved.
#
# This program is free software. It may be modified and/or
# distributed under the same terms as Perl itself.
#

use ExtUtils::MakeMaker;

# TODO: Figure out how to make this work.
#use Inline::MakeMaker 'GDA';

WriteMakefile(
  'NAME'         => 'GDA',
  'AUTHOR'       => 'Gregor N. Purdy',
  'ABSTRACT'     => 'Perl bindings for GNU Data Access (GDA) library from GNOME-DB project',
  'PREREQ_PM'    => { 'Inline' => 0 },
  'VERSION_FROM' => 'lib/GDA.pm',
  'EXE_FILES'    => [ qw(script/gda-ls-log script/gda-ls-providers) ]
);

