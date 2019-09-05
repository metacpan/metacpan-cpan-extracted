use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Regexp::Func::Lt

=abstract

Data-Object Regexp Function (Lt) Class

=synopsis

  use Data::Object::Regexp::Func::Lt;

  my $func = Data::Object::Regexp::Func::Lt->new(@args);

  $func->execute;

=inherits

Data::Object::Regexp::Func

=description

Data::Object::Regexp::Func::Lt is a function object for Data::Object::Regexp.

=cut

# TESTING

use_ok 'Data::Object::Regexp::Func::Lt';

ok 1 and done_testing;
