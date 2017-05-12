#!perl -T

use Test::More tests => 20;

# --------------------------------------------------------------------------------------
# This first bit tests the macro insertion code.  Macro insertions are nodes that are
# added to the tree "invisibly", that is, they're there but don't appear in the code's
# self-dump.  This is because they're presumed to have been added at runtime based on
# specifications already present in the defined code, and will be added on the next
# runtime based on those same specifications.
# --------------------------------------------------------------------------------------
use Decl qw(-nofilter Decl::Semantics);
use Data::Dumper;

$tree = Decl->new();

$code = <<'EOF';

pod head1 "HEADING"
  This is a POD element.

value basevar "0" {
   if (defined $value) {
      $^variable = -$value;
      $this->{$key} = $value;
   }
   $this->{$key}
}

thing nolabel { single-line body }

something (with=parameters, borders, numeric=0, boing=boing) [with_options, something here] "and a label"
   with children
      and grandchildren
      multiple ones
   and yet "more kids"
   a "plethora of'em"
 
EOF

$tree->load($code);

$with = $tree->first('with');
isa_ok ($with, 'Decl::Node');
$with->macroinsert (<<EOF);
 ! macro_expansion
 ! macro_expansion2
 !   with a child
 ! macro_expansion3
EOF

# Check that it all got added.
$me = $tree->first('macro_expansion');
isa_ok ($me, 'Decl::Node');
$me2 = $tree->first('macro_expansion2');
isa_ok ($me2, 'Decl::Node');
$child = $me2->find('with');
isa_ok ($child, 'Decl::Node');
$me3 = $tree->first('macro_expansion2');
isa_ok ($me3, 'Decl::Node');

$dump = $tree->describe;      # Normal description does not include macro expansions.

ok ($dump !~ /with a child/);
ok ($dump !~ /macro_expansion3/);

$dump = $tree->describe(1);   # Pass in the flag to test description *with* macro expansions.
#diag $dump;

ok ($dump =~ /with a child/);
ok ($dump =~ /macro_expansion3/);

$offset1 = index($dump, 'multiple ones');
$offset2 = index($dump, 'macro_expansion');

ok ($offset1 < $offset2);

# -----------------------------------------------------------------------------------------------------------------------
# Now the same test, but adding the macro stuff after a given node, instead of at the end of a child list (the default)
# -----------------------------------------------------------------------------------------------------------------------

$tree = Decl->new();

$code = <<'EOF';

something (with=parameters, borders, numeric=0, boing=boing) [with_options, something here] "and a label"
   with children
      and grandchildren
      multiple ones
   and yet "more kids"
   a "plethora of'em"
 
EOF

$tree->load($code);

$with = $tree->first('with');
isa_ok ($with, 'Decl::Node');
$and = $tree->first('and');
isa_ok ($with, 'Decl::Node');

$with->macroinsert (<<'EOF', $and);
 ! macro_expansion
 !   with a child
EOF

# Check that it got added.
$me = $tree->first('macro_expansion');
isa_ok ($me, 'Decl::Node');
$child = $me2->find('with');
isa_ok ($child, 'Decl::Node');

$dump = $tree->describe(1);
$offset1 = index($dump, 'multiple ones');
$offset2 = index($dump, 'macro_expansion');

ok ($offset1 > $offset2);


# --------------------------------------------------------------------------
# Here code macro with explicit output call
# --------------------------------------------------------------------------
$tree = Decl->new(<<'EOF');

<= {
   ^output ("inserted.\n");
   ^output ("  This is an inserted text tag.");
}

dummy.
  This is some dummy text.
  
EOF

#$tree->start();
#diag $tree->describe(1);
$content = $tree->content;

ok ($content =~ /inserted text/);
ok ($content =~ /dummy text/);

$offset1 = index($content, 'inserted text');
$offset2 = index($content, 'dummy text');

ok ($offset1 < $offset2);


# --------------------------------------------------------------------------
# Named code macro with explicit output call
# --------------------------------------------------------------------------
$tree = Decl->new(<<'EOF');

define my_coolness {
   ^output ("inserted.\n");
   ^output ("  This is an inserted text tag.\n");
}

dummy.
  This is marker text 1.
  
my_coolness

dummy.
  This is marker text 2.

my_coolness again
  
EOF

#diag $tree->describe(1);
$content = $tree->content;
is ($content, <<'EOF');
This is marker text 1.
This is an inserted text tag.
This is marker text 2.
This is an inserted text tag.
EOF


# --------------------------------------------------------------------------------
# << notation for output.
# --------------------------------------------------------------------------------

$tree = Decl->new(<<'EOF');

define my_ultra_coolness {
   << inserted.
        This is an inserted text tag.
   my $thing = 'value'; # This is just here to test the indentation parsing.
}

dummy.
  This is marker text 1.
  
my_ultra_coolness

dummy.
  This is marker text 2.

my_ultra_coolness again
  
EOF

#diag $tree->describe(1);
$content = $tree->content;
is ($content, <<'EOF');
This is marker text 1.
This is an inserted text tag.
This is marker text 2.
This is an inserted text tag.
EOF
