use 5.014;

use strict;
use warnings;

use Test::More;

=name

Doodle::Statement

=abstract

Doodle Statement Class

=synopsis

  use Doodle::Statement;

  my $self = Doodle::Statement->new(%args);

=description

Command and DDL statement representation.

=cut

use_ok "Doodle::Statement";

ok 1 and done_testing;
