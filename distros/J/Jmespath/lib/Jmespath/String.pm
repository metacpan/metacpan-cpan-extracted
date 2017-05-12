package Jmespath::String;
use strict;
use warnings;
use Data::Dumper;
use overload (
              "0+"     => sub { "\"${$_[0]}\""; },
              '""'     => sub { ${$_[0]}},
              "."      => sub { ${$_[0]}},
              "eq"     => sub { ${$_[0]} },
              fallback => sub { ${$_[0]} },
);

sub TO_JSON { return '' . shift; }

1;
