use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Regexp::Base

=abstract

Data-Object Abstract Regexp Class

=synopsis

  package My::Regexp;

  use parent 'Data::Object::Regexp::Base';

  my $re = My::Regexp->new(qr(\w+));

=description

Data::Object::Regexp::Base provides routines for operating on Perl 5 regular
expressions. This package inherits all behavior from L<Data::Object::Base>.

=cut

use_ok "Data::Object::Regexp::Base";

ok 1 and done_testing;
