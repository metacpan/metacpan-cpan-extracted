#!perl -T

use Test::More tests => 2;
use IO::File;

# --------------------------------------------------------------------------------------
# Decl::Node objects can iterate over their contents.
# --------------------------------------------------------------------------------------
use Decl qw(-nofilter Decl::Semantics);

$tree = Decl->new();

$code = <<'EOF';

pod head1 "HEADING"
  This is a POD element.
  It has a lot of content, but more importantly,
  it has "wantsbody" status, so it will iterate over its indented text.

pod head1 "CODE TEST" { # This will iterate over a code return. 
   IO::File->new ('META.yml') or [];
}
EOF

$tree->load($code);

($pod1, $pod2) = $tree->search ('pod');

$i1 = $pod1->iterate;

$count = 0;
while (<$i1>) {
   $count++;
}
is ($count, 3);

$i2 = $pod2->iterate;

$count = 0;
while (<$i2>) {
   $count++;
}

ok ($count > 10);