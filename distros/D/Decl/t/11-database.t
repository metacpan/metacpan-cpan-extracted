#!perl -T

use Test::More tests => 3;
use Data::Dumper;

use Decl qw(-nofilter Decl::Semantics);

# -----------------------------------------------------------------------
# Test some simple queries against the test text database in 11-database.
# -----------------------------------------------------------------------

$tree = Decl->new(<<'EOF');

database (csv) "t/11-database"

do {
   ^select * from a {{
      return $row;
   }}
}
EOF

is_deeply($tree->start, {id=>1, name=>'testing'});

$tree = Decl->new(<<'EOF');

database (csv) "t/11-database"

do {
   ^select id, name from a {{
      return "$id - $name";
   }}
}
EOF

is_deeply($tree->start, '1 - testing');

$tree = Decl->new(<<'EOF');

database "CSV:f_dir=t/11-database"

do {
   ^select id, name from a {{
      return "$id - $name";
   }}
}
EOF

is_deeply($tree->start, '1 - testing');



