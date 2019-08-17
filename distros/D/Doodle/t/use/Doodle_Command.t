use 5.014;

use strict;
use warnings;

use Test::More;

=name

Doodle::Command

=abstract

Doodle Command Class

=synopsis

  use Doodle::Command;

  my $self = Doodle::Command->new(%args);

=description

Description of a DDL statement to build.

=cut

use_ok "Doodle::Command";

ok 1 and done_testing;
