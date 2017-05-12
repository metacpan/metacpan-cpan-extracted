################################################################################
#
# $Project: /Devel-Tokenizer-C $
# $Author: mhx $
# $Date: 2008/04/19 18:05:15 +0200 $
# $Revision: 7 $
# $Source: /Makefile.PL $
#
################################################################################
# 
# Copyright (c) 2002-2008 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
# 
################################################################################

require 5.005_03;
use strict;

use ExtUtils::MakeMaker;

my %prereq = (
  'Test::More' => '0.45',
);

WriteMakefile(
  NAME         => 'Devel::Tokenizer::C',
  VERSION_FROM => 'lib/Devel/Tokenizer/C.pm',
  PREREQ_PM    => \%prereq,
  realclean    => { FILES => 'dtcrun dtcrun.c dtcrun.exe dtcdata' },
  CONFIGURE    => \&configure,
);

sub configure
{
  my @moreopts;

  if (eval $ExtUtils::MakeMaker::VERSION >= 6) {
    push @moreopts, AUTHOR => 'Marcus Holland-Moritz <mhx@cpan.org>',
                    ABSTRACT_FROM => 'lib/Devel/Tokenizer/C.pm';
  }

  if (eval $ExtUtils::MakeMaker::VERSION >= 6.30_01) {
    print "Setting license tag...\n";
    push @moreopts, LICENSE => 'perl';
  }

  return { @moreopts };
}

