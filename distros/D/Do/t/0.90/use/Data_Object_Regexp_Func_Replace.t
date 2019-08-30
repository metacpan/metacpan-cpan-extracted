use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Regexp::Func::Replace

=abstract

Data-Object Regexp Function (Replace) Class

=synopsis

  use Data::Object::Regexp::Func::Replace;

  my $func = Data::Object::Regexp::Func::Replace->new(@args);

  $func->execute;

=description

Data::Object::Regexp::Func::Replace is a function object for
Data::Object::Regexp. This package inherits all behavior from
L<Data::Object::Regexp::Func>.

=cut

# TESTING

use_ok 'Data::Object::Regexp::Func::Replace';

ok 1 and done_testing;
