use 5.014;

use strict;
use warnings;

use Test::More;

=name

Doodle::Schema

=abstract

Doodle Schema Class

=synopsis

  use Doodle::Schema;

  my $self = Doodle::Schema->new(%args);

=description

Database representation.

=cut

use_ok "Doodle::Schema";

ok 1 and done_testing;
