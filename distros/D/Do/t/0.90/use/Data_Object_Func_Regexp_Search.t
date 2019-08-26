use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Regexp::Search

=abstract

Data-Object Regexp Function (Search) Class

=synopsis

  use Data::Object::Func::Regexp::Search;

  my $func = Data::Object::Func::Regexp::Search->new(@args);

  $func->execute;

=description

Data::Object::Func::Regexp::Search is a function object for Data::Object::Regexp.

=cut

# TESTING

use_ok 'Data::Object::Func::Regexp::Search';

ok 1 and done_testing;
