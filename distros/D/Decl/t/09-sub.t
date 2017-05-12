#!perl -T

use Test::More tests => 1;
use Data::Dumper;

# --------------------------------------------------------------------------------------
# Decl::Code objects that are defined as "sub" can be called from
# other code elsewhere.  Visibility is any direct child of any ancestor.
# --------------------------------------------------------------------------------------
use Decl qw(-nofilter Decl::Semantics);

$tree = Decl->new();

$code = <<'EOF';

value count "0"

sub increment {
   $^count ++;
}
   

do {
   increment();   
}

EOF

$tree->load($code);
$tree->start;

is ($tree->value('count'), 1);

