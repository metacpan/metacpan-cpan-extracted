use strict;
use warnings;

package My::Schema;

use base qw(KinoSearch::Schema);
use KinoSearch::Analysis::LCNormalizer;
use KinoSearch::Schema::FieldSpec;

our %fields = (
  id    => 'KinoSearch::Schema::FieldSpec',
  type  => 'KinoSearch::Schema::FieldSpec',
  name  => 'KinoSearch::Schema::FieldSpec',
  color => 'KinoSearch::Schema::FieldSpec',
);

sub analyzer { KinoSearch::Analysis::LCNormalizer->new }

1;
