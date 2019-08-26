use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

regexp

=usage

  # given qr(\w+)

  my $object = Data::Object->regexp(qr(\w+));

=description

The C<regexp> constructor function returns a L<Data::Object::Regexp> object for given
argument.

=signature

regexp(Regexp $arg) : RegexpObject

=type

method

=cut

# TESTING

use_ok 'Data::Object';

my $object = Data::Object->regexp(qr(\w+));

isa_ok $object, 'Data::Object::Regexp';

ok 1 and done_testing;
