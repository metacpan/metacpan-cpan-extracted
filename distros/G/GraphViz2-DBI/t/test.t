use strict;
use warnings;
use Test::More;

use GraphViz2;
use GraphViz2::DBI;
use DBI;

my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:", '', '');
$dbh->do($_) for <<'EOF', <<'EOF', <<'EOF';
CREATE TABLE "user" (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username VARCHAR(255) UNIQUE NOT NULL,
  email VARCHAR(255) NOT NULL,
  password VARCHAR(255) NOT NULL,
  access TEXT NOT NULL CHECK( access IN ( 'user', 'moderator', 'admin' ) ) DEFAULT 'user',
  age INTEGER DEFAULT NULL,
  plugin VARCHAR(50) NOT NULL DEFAULT 'password',
  avatar VARCHAR(255) NOT NULL DEFAULT '',
  created DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
)
EOF
CREATE TABLE blog (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username VARCHAR(255) REFERENCES "user" ( username ),
  title VARCHAR(255) NOT NULL,
  slug VARCHAR(255),
  markdown VARCHAR(255) NOT NULL,
  html VARCHAR(255),
  is_published BOOLEAN NOT NULL DEFAULT FALSE,
  published_date DATETIME DEFAULT CURRENT_TIMESTAMP
)
EOF
CREATE TABLE zap (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title VARCHAR(255) NOT NULL
)
EOF

my $g_dbi = GraphViz2::DBI->new(dbh => $dbh);
$g_dbi->create(exclude => ['zap']);
my $g = $g_dbi->graph;
is_deeply_dump($g->node_hash, {
  blog => {
    attributes => {
      label => '<port0> blog|{<port1> 1:\\ html|<port2> 2:\\ id|<port3> 3:\\ is_published|<port4> 4:\\ markdown|<port5> 5:\\ published_date|<port6> 6:\\ slug|<port7> 7:\\ title|<port8> 8:\\ username}',
      shape => 'Mrecord',
    },
  },
  user => {
    attributes => {
      label => '<port0> user|{<port1> 1:\\ access|<port2> 2:\\ age|<port3> 3:\\ avatar|<port4> 4:\\ created|<port5> 5:\\ email|<port6> 6:\\ id|<port7> 7:\\ password|<port8> 8:\\ plugin|<port9> 9:\\ username}',
      shape => 'Mrecord',
    },
  },
}, 'nodes');
is_deeply_dump($g->edge_hash, {
  blog => {
    user => [ { attributes => {}, from_port => ':"port8"', to_port => ':"port9"' } ]
  }
}, 'edges');

sub is_deeply_dump {
  my ($got, $expected, $label) = @_;
  is_deeply $got, $expected, $label or diag explain $got;
}

done_testing;
