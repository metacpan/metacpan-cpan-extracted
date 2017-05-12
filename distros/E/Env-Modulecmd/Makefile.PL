# $Id: Makefile.PL,v 5.1 2014/08/18 16:56:08 ronisaac Exp $

# Copyright (c) 2001-2014, Morgan Stanley.
# Distributed under the terms of the GNU General Public License.
# Please see the copyright notice in Modulecmd.pm for more information.

use ExtUtils::MakeMaker;

WriteMakefile
  ('NAME'          => 'Env::Modulecmd',
   'VERSION_FROM'  => 'Modulecmd.pm',
   'PREREQ_PM'     => {},
   ($] >= 5.005 ?
    (ABSTRACT_FROM => 'Modulecmd.pm',
     AUTHOR        => 'Ron Isaacson <ron.isaacson@morganstanley.com>',
     PM_FILTER     => '$(PERL) -p filter'
    ) : ()),
  );
