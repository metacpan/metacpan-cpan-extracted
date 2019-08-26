use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Base::Any

=abstract

Data-Object Abstract Any Class

=synopsis

  package My::Any;

  use parent 'Data::Object::Base::Any';

  my $any = My::Any->new(\*main);

=description

Data::Object::Base::Any is an abstract base class for operating on any Perl 5 data type.

=cut

use_ok "Data::Object::Base::Any";

ok 1 and done_testing;
