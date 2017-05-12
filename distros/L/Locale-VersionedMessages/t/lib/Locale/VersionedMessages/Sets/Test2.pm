package Locale::VersionedMessages::Sets::Test2;
####################################################
#        *** WARNING WARNING WARNING ***
#
# This file was generated, and is intended to be
# maintained automatically using the lm_admin command.
# Any changes to this file may be lost the next
# time the command is run.
####################################################

use strict;
use warnings;

our($DefaultLocale,@AllLocale,%Messages);

$DefaultLocale = 'en_US';
@AllLocale     = (qw(en_US fr_FR));

%Messages = (
   'Subst_0a' => {
      'desc'  => q{Error message (not defined in French) [aaa]},
      'vals'  => ['aaa'],
   },
   'Subst_0b' => {
      'desc'  => q{Error message (contains aaa, not bbb) [aaa]},
      'vals'  => ['aaa'],
   },
   'Subst_0c' => {
      'desc'  => q{Error message (no substitutions)},
      'vals'  => [],
   },
   'Subst_0d' => {
      'desc'  => q{Error message (must contain aaa)},
      'vals'  => ['aaa'],
   },
   'Subst_0e' => {
      'desc'  => q{Error message (invalid sprintf format)},
      'vals'  => ['aaa'],
   },
   'Subst_0f' => {
      'desc'  => q{Error message (invalid sprintf format)},
      'vals'  => ['aaa'],
   },
   'Subst_0g' => {
      'desc'  => q{Error message (no default_string)},
      'vals'  => ['n'],
   },
   'Subst_0h' => {
      'desc'  => q{Error message (invalid quant characters)},
      'vals'  => ['n'],
   },
   'Subst_0i' => {
      'desc'  => q{Error message (malformed quant test)},
      'vals'  => ['n'],
   },
   'Subst_1a' => {
      'desc'  => q{Simple substitution message #1a [aaa]},
      'vals'  => ['aaa'],
   },
   'Subst_1b' => {
      'desc'  => q{Simple substitution message #1b with duplicates [aaa]},
      'vals'  => ['aaa'],
   },
   'Subst_2a' => {
      'desc'  => q{Formatted substitution message #2a [n]},
      'vals'  => ['n'],
   },
   'Subst_3a' => {
      'desc'  => q{Quantity substitution message #3a [n]},
      'vals'  => ['n'],
   },
   'Subst_3b' => {
      'desc'  => q{Quantity substitution message #3b [n]},
      'vals'  => ['n'],
   },
);

1;
