#!perl -T

use Test::More tests => 4;
use Data::Dumper;
sub arrayref_split { [split /\n/, $_[0]] }
sub is_text { is_deeply (arrayref_split ($_[0]), arrayref_split($_[1])); }


# --------------------------------------------------------------------------------------
# Decl::Data objects know how to iterate lists.
# --------------------------------------------------------------------------------------
use Decl qw(-nofilter Decl::Semantics);

$tree = Decl->new();

$code = <<'EOF';

data my_data (this, that)
   1    "this is the value of this"
   2    "that is the value of that"
   3    third
   
value count "0"
value first_test ""
value second_test ""

do {
   ^foreach this, that in my_data {{
      $^first_test .= "$this - $that\n";
      $^count ++;
   }}
   
   ^foreach my_data {{   # I'm sorry, I just find this incredibly cool.
      $^second_test .= "$that - $this\n";
      $^count ++;
   }}
}

EOF

$tree->load($code);

#diag Dumper($tree->sketch_c());

$data = $tree->find ('data');

$i1 = $data->iterate;

$count = 0;
while (<$i1>) {
   #diag "$_ - $$_[0] $$_[1]\n";
   $count++;
}
is ($count, 3);

# Now let's run that 'do'.
$tree->start;

is ($tree->value('count'), 6);

is_text ($tree->value('first_test'), <<'EOF');
1 - this is the value of this
2 - that is the value of that
3 - third
EOF

is_text ($tree->value('second_test'), <<'EOF');
this is the value of this - 1
that is the value of that - 2
third - 3
EOF

