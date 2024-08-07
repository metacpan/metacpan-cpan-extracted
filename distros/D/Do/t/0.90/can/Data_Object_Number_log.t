use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

log

=usage

  # given 12345

  $number->log; # 9.42100640177928

=description

The log method returns the natural logarithm (base e) of the number. This method
returns a L<Data::Object::Float> object.

=signature

log() : FloatObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Number';

my $data = Data::Object::Number->new(12345);

like $data->log(), qr/9.42100/;

ok 1 and done_testing;
