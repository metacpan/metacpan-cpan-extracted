use strict;
use warnings;

package My::Schema::Field;

use base qw(KinoSearch::Schema::FieldSpec);

sub analyzed { 0 }
sub stored   { 1 }
sub indexed  { 1 }

package My::Schema;

use base qw(KinoSearch::Schema);
use KinoSearch::Analysis::LCNormalizer;

our %fields = (
  id    => 'My::Schema::Field',
  type  => 'My::Schema::Field',
  name  => 'My::Schema::Field',
  color => 'My::Schema::Field',
);

sub analyzer { KinoSearch::Analysis::LCNormalizer->new }

1;
