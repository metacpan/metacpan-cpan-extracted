# $Id: test.pl,v 5.2 2014/08/18 16:56:19 ronisaac Exp $

# Copyright (c) 2001-2014, Morgan Stanley.
# Distributed under the terms of the GNU General Public License.
# Please see the copyright notice in Modulecmd.pm for more information.

use Test;
use Env::Modulecmd;

BEGIN {
  # prepare test plan

  our $TESTS = 4;
  plan tests => $TESTS;
}

# initialize environment

eval { Env::Modulecmd::use ('.'); };

if ($@ =~ /^Unable to execute/) {
  print <<MSG;

  ***** SKIPPING TESTS *****

  Env::Modulecmd was not able to invoke 'modulecmd'. This means
  one of two things:

  1. You do not have the 'modules' package installed. See
     http://www.modules.org for more information about this
     package. If you don't have it, Env::Modulecmd is probably
     not of any use to you.

  2. You do have the 'modules' package installed, but
     Env::Modulecmd was not able to find 'modulecmd'. There
     are three ways to correct this problem:

       a. Put 'modulecmd' in your PATH
       b. Set the environment variable PERL_MODULECMD to the full
          path to 'modulecmd'
       c. Rebuild the Env::Modulecmd package with a default
          PERL_MODULECMD; see the README for more information

  ***** SKIPPING TESTS *****

MSG

  skip ("Skip because modulecmd was not found", "") for (1..$TESTS);
  exit;
}

die $@ if $@;
ok (1);

# test loading

Env::Modulecmd::load ('testmod');
ok ($ENV{'TESTMOD_LOADED'}, 'yes');

# test unloading

Env::Modulecmd::unload ('testmod');
ok ($ENV{'TESTMOD_LOADED'}, undef);

# test failure

eval { Env::Modulecmd::load ('no_such_module') };
ok ($@, qr/Error loading module/);
