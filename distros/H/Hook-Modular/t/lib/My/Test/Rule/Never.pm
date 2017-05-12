package My::Test::Rule::Never;
use warnings;
use strict;
use parent 'Hook::Modular::Rule';
sub dispatch { 0 }
1;
