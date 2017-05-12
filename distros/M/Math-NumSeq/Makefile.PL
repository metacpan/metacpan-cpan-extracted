#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use ExtUtils::MakeMaker;

my %expression_modules = ('Math::Symbolic' => 0,
                          'Math::Expression::Evaluator' => 0,
                          # incompatible changes in 0.24
                          'Language::Expr' => 0.24,
                          'Language::Expr::Compiler::perl' => 0.24,
                         );

WriteMakefile
  (NAME          => 'Math::NumSeq',
   ABSTRACT      => 'Number sequences.',
   VERSION_FROM  => 'lib/Math/NumSeq.pm',
   PREREQ_PM     => {
                     'constant' => 1.02, # for leading underscore
                     'constant::defer' => 1,
                     'File::HomeDir' => 0,
                     'File::Spec' => 0,
                     'File::Temp' => 0,
                     'List::Util' => 0,
                     'Math::Libm' => 0,
                     'Math::Prime::XS' => '0.23', # version 0.23 for fix 1928099
                     'Module::Pluggable' => 0,

                     # version 0.40 for factors() on Math::BigInt
                     'Math::Factor::XS' => '0.40',

                     'Module::Util' => 0,
                     'Module::Load' => 0,
                    },
   TEST_REQUIRES => {
                     'Test' => 0,
                    },
   AUTHOR        => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE       => 'gpl_3',
   SIGN          => 1,
   MIN_PERL_VERSION => '5.004',

   META_MERGE =>
   { 'meta-spec' => { version => 2 },
     no_index    => { directory=>['devel','xt'] },
     resources =>
     { homepage => 'http://user42.tuxfamily.org/math-numseq/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },

     recommends =>
     { 'Math::Prime::XS' => '0.26', # v.26 for faster is_prime()
       # version 4.7 to avoid warnings about removal from the core perl dist
       # which was a ridiculous way to communicate to authors
       'Module::Pluggable' => '4.7',
     },
     prereqs =>
     { runtime =>
       { suggests =>
         { %expression_modules,
         }
       },
       test =>
       { suggests =>
         # have "make test" do as much as possible
         { 'Data::Float'  => 0,
           %expression_modules,
         }
       },
     },
     optional_features =>
     { maximum_interoperation =>
       { description => 'Have maximum inter-operation with other modules (optional other stuff).',
         prereqs =>
         { runtime =>
           { requires =>
             { %expression_modules,
             },
           },
         },
       },
     },
   },
  );

#------------------------------------------------------------------------------
# updating BuiltinTable.pm

package MY;
sub postamble {
  my ($makemaker) = @_;
  return <<'HERE';

oeis lib/Math/NumSeq/OEIS/Catalogue/Plugin/BuiltinTable.pm: tools/make-oeis-catalogue.pl lib/Math/NumSeq/*.pm
	$(PERL) tools/make-oeis-catalogue.pl || (rm -f $@; false)
HERE
}
