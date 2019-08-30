use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Regexp::Func::Ne

=abstract

Data-Object Regexp Function (Ne) Class

=synopsis

  use Data::Object::Regexp::Func::Ne;

  my $func = Data::Object::Regexp::Func::Ne->new(@args);

  $func->execute;

=description

Data::Object::Regexp::Func::Ne is a function object for Data::Object::Regexp.
This package inherits all behavior from L<Data::Object::Regexp::Func>.

=cut

# TESTING

use_ok 'Data::Object::Regexp::Func::Ne';

ok 1 and done_testing;
