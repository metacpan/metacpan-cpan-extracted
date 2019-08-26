use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Func::Regexp::Lt

=abstract

Data-Object Regexp Function (Lt) Class

=synopsis

  use Data::Object::Func::Regexp::Lt;

  my $func = Data::Object::Func::Regexp::Lt->new(@args);

  $func->execute;

=description

Data::Object::Func::Regexp::Lt is a function object for Data::Object::Regexp.

=cut

# TESTING

use_ok 'Data::Object::Func::Regexp::Lt';

ok 1 and done_testing;
