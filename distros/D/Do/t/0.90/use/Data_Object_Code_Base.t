use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Code::Base

=abstract

Data-Object Abstract Code Class

=synopsis

  package My::Code;

  use parent 'Data::Object::Code::Base';

  my $code = My::Code->new(sub { shift + 1 });

=description

Data::Object::Code::Base provides routines for operating on Perl 5 code
references.

=cut

use_ok "Data::Object::Code::Base";

ok 1 and done_testing;
