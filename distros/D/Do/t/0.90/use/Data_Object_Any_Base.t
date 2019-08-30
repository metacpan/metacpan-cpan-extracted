use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Any::Base

=abstract

Data-Object Abstract Any Class

=synopsis

  package My::Any;

  use parent 'Data::Object::Any::Base';

  my $any = My::Any->new(\*main);

=description

Data::Object::Any::Base is an abstract base class for operating on any Perl 5
data type. This package inherits all behavior from L<Data::Object::Base>.

=cut

use_ok "Data::Object::Any::Base";

ok 1 and done_testing;
