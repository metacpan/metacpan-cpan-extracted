use strict;
use warnings;

use Test::More tests => 54 * 3 + 1;

use Dist::Zilla::Util::RoleDB;

my $n_role = 54;
my $i      = 0;

for my $role ( Dist::Zilla::Util::RoleDB->new->roles ) {
  note "Role Nr. $i ---";
  ok( length $role->name, 'Role has non-zero-length name' );
  note "name=" . $role->name;
  ok( length $role->full_name, 'Role has non-zero-lenght full-name' );
  note "full_name=" . $role->full_name;
  ok( length $role->description, 'Role has non-zero-length description' );
  note "description=" . $role->description;
  note "End Role";
  $i++;
}
is( $i, $n_role, 'Number of roles matches expected' );
