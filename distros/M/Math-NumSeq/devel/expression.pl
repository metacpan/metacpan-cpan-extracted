#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;

use Smart::Comments;

use lib 'devel/lib';

{
  my $expression = '$k = $i; $k*$phi';

  require Safe;
  my $safe = Safe->new;
  ### hypot: $safe->reval('hypot(3,4)')
  ### subr: $safe->reval('sub { 123 }')
  # print "_[0] = ".(defined \$_[0] ? \$_[0] : 'undef')."\n";

  } else {
    print $subr->(10);
  }
  exit 0;
}
{
  require Math::Sequence;
  my $seq = Math::Sequence->new ('3*x', 2, 'x');
  { my $expr = $seq->next;
    my $value = $expr->value;
    ### $expr
    ### $value
  }
  { my $expr = $seq->at_index(2);
    my $value = $expr->value;
    ### $expr
    ### $value
  }
  exit 0;
}

{
  my $str = '$x = 1; $x + 2 - $y + $z';
  my $ret = eval "use strict; sub { $str }";
  my $err = $@;
  ### $ret
  ### $err
  if (defined $err) {
    my %vars;
    foreach my $line (split /\n/, $err) {
      if ($line =~ /^Global symbol "\$(.*?)" requires explicit package name/) {
        $vars{$1} = 1;
      }
    }
    ### vars: keys %vars
  }

  exit 0;
}

{
  require Math::Expression::Evaluator;
  my $me = Math::Expression::Evaluator->new;
  $me->parse ('phi=(1+sqrt(5))/2; z=3; z*x^2 + x + 2');
  # $me->optimize;
  ### variables: $me->variables
  ### val: $me->val({x => 4})

  my $comp = $me->compiled;
  ### $comp
  ### comp: &$comp({x=>4})
  ### ast: $me->_ast_to_perl($me->{ast})

  exit 0;
}

{
  use Math::Symbolic;
  my $tree = Math::Symbolic->parse_from_string('2*x^2 +x');
  ### $tree
  ### string: $tree->to_string
  ### string: $tree->to_string('prefix')
  ### string: $tree->to_code

  $tree = $tree->simplify;
  ### simplified
  ### string: $tree->to_string
  ### string: $tree->to_string('prefix')
  ### string: $tree->to_code

  ### signature: [$tree->signature]

  my ($code) = Math::Symbolic::Compiler->compile_to_code($tree, ['x']);
  ### $code

  my ($subr) = $tree->to_sub (x => 0);
  # ### $subr

  foreach my $i (0 .. 10) {
    say $i, ' ', $subr->($i);
  }
  exit 0;
}
