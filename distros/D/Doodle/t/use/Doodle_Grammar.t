use 5.014;

use strict;
use warnings;

use Test::More;

=name

Doodle::Grammar

=abstract

Doodle Grammar Base Class

=synopsis

  use Doodle::Grammar;

  my $self = Doodle::Grammar->new(%args);

=description

Doodle::Grammar determines how Command classes should be interpreted to produce the correct DDL
statements.

=cut

use_ok "Doodle::Grammar";

ok 1 and done_testing;
