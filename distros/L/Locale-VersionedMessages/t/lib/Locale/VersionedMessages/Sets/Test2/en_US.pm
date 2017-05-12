package Locale::VersionedMessages::Sets::Test2::en_US;
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

our(%Messages);

%Messages = (
   'Subst_0a' => {
      'vers'  => 2,
      'text'  => 'Error message (not defined in French) [aaa]
',
   },
   'Subst_0b' => {
      'vers'  => 2,
      'text'  => 'Error message (contains aaa, not bbb) [aaa]
',
   },
   'Subst_0c' => {
      'vers'  => 2,
      'text'  => 'Error message (no substitutions)
',
   },
   'Subst_0d' => {
      'vers'  => 2,
      'text'  => 'Error message (should contain aaa)
',
   },
   'Subst_0e' => {
      'vers'  => 2,
      'text'  => 'Error message (format) [aaa:%]
',
   },
   'Subst_0f' => {
      'vers'  => 2,
      'text'  => 'Error message (format) [aaa:%z]
',
   },
   'Subst_0g' => {
      'vers'  => 2,
      'text'  => 'Error message (default string) [n:quant [_n==1] [one unit]]
',
   },
   'Subst_0h' => {
      'vers'  => 2,
      'text'  => 'Error message (invalid quant characters) [n:quant [_n==1 && a] [one unit] [lots]]
',
   },
   'Subst_0i' => {
      'vers'  => 2,
      'text'  => 'Error message (malformed quant test) [n:quant [_n>2 && (_n<=5))] [3-5 units] [lots]]
',
   },
   'Subst_1a' => {
      'vers'  => 2,
      'text'  => 'Substitution message 1a with value [aaa] in English.
',
   },
   'Subst_1b' => {
      'vers'  => 2,
      'text'  => 'Substitution message 1b with value [aaa] (dupl: [aaa]) in English.
',
   },
   'Subst_2a' => {
      'vers'  => 2,
      'text'  => 'Substitution message 2a with formatted value [n:%05d] in English.
',
   },
   'Subst_3a' => {
      'vers'  => 2,
      'text'  => 'Substitution message 3a with [n:quant [_n==1] [one value] [_n values]] in English.
',
   },
   'Subst_3b' => {
      'vers'  => 2,
      'text'  => q(Substitution message 3b with [n:quant _n==1 'one value' " _n values"] in English.
),
   },
);

1;
