use strict;
use warnings;

use Test::More tests => 24 * 3 + 1;

use Dist::Zilla::Util::RoleDB;

my $n_phases = 24;
my $i        = 0;

for my $phase ( Dist::Zilla::Util::RoleDB->new->phases ) {
  note "Phase Nr. $i ---";
  ok( length $phase->name, 'Phase has non-zero-length name' );
  note "name=" . $phase->name;
  ok( length $phase->description, 'Phase has non-zero-length description' );
  note "description=" . $phase->description;
  ok( length $phase->phase_method, 'Phase has non-zero-length method' );
  note "method=" . $phase->phase_method;
  note "End Phase";
  $i++;
}
is( $i, $n_phases, 'Number or phases matches expected' );
