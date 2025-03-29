use strict;
use warnings;
use Test::More tests => 4;
use FindBin;
use lib "$FindBin::Bin/../lib";
use JQ::Lite;
use JSON::PP;

my $json = <<'EOF';
{
  "users": [
    { "name": "Alice", "age": 30 },
    { "name": "Bob", "age": 25 },
    { "name": "Charlie", "age": 35 }
  ]
}
EOF

my $jq = JQ::Lite->new;

# Test: users[].name
my @names = $jq->run_query($json, '.users[] | .name');

is_deeply(\@names, ["Alice", "Bob", "Charlie"], 'Extract names from users array');

# Test: users[].age
my @ages = $jq->run_query($json, '.users[] | .age');

is_deeply(\@ages, [30, 25, 35], 'Extract ages from users array');

# Test: nested traversal .users[].name
my @alt = $jq->run_query($json, '.users[].name');

is_deeply(\@alt, ["Alice", "Bob", "Charlie"], 'Alternative syntax for extracting names');

# Test: top-level object access
my @all = $jq->run_query($json, '.users');

ok(ref($all[0]) eq 'ARRAY', 'Top-level array returned');
