#!perl -w

use strict;
package Regcomp;
use vars qw(@ISA %types);
require ExtUtils::Constant::Base;
@ISA = 'ExtUtils::Constant::Base';

sub assignment_clause_for_type {
  my ($self, $type, $value) = @_;
  $value = uc $value;
  return "namedclass = complement ? ANYOF_N$value : ANYOF_$value;";
}

sub return_statement_for_notfound {
    "";
}

sub name_param {
  'posixcc';
}

sub namelen_param {
  'skip';
}

sub memEQ {
  "memEQ";
}

package main;

my @names = (qw(alpha ascii blank cntrl digit graph lower print punct upper
		xdigit), {name=>"alnum", value=>"ALNUMC"},
	     {name=>"space", value => "PSXSPC"},
	     {name=>"word", value=>"ALNUM",
	      pre=>'/* this is not POSIX, this is the Perl \w */'});

print Regcomp->C_constant ({breakout=>~0,indent=>20}, @names);

