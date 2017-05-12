#!perl -T

use Test::More tests => 10;
use Decl qw(-nofilter Decl::Semantics);
use Data::Dumper;

# In Decl, there are two kinds of variable: regular Perl variables, and "special" variables.  Special variables are Decl's own variable system,
# and can be referenced from Perl code with the $^ sigil.  They're also the variables accessed by normal templates.  Variables originate either
# by being declared (either with the 'value' tag or with some other object that presents itself as a variable, like Wx input fields), or simply
# by being referenced in code with the $^ sigil.  In the latter case, the value is simply stored locally in a hashref in the node, but in the former,
# things can get complicated: a declared variable is looked for in a macro definition instead of its instance, and can inherit from parents, etc.
#
# So there are a lot of variations to test here.

# First: a Decl variable defaults to storage in the tag in which it appears, unless it's declared elsewhere.

$tree = Decl->new(<<'EOF');

do {
   $^variable = 'value';
}
EOF
$tree->start();
diag $tree->get_value('variable');
is ($tree->get_value('variable'), undef);

$do = $tree->find('do');
is ($do->get_value('variable'), 'value');

# But if we declare it outside, that's where we'll find it.  Note that in this case, both the root
# *and* the 'do' tag think the value is set to 'value'.

$tree = Decl->new(<<'EOF');

value variable "not value"

do {
   $^variable = 'value';
}
EOF
$tree->start();
is ($tree->get_value('variable'), 'value');

$do = $tree->find('do');
is ($do->get_value('variable'), 'value');


# --------------------------------------------------------------------------------------
# Semantic::Value takes advantage of the active-variable feature of declarative
# contexts to make variables that have active content.  Cool, huh?
# --------------------------------------------------------------------------------------

$tree = Decl->new();

$tree->load (<<'EOF');

value variable "0"

value basevar "0" {
   if (defined $value) {
      $^variable = 0 - $value; # Did it this way because Perl 5.6 treats this as a string and yields "-0"
      $this->{$key} = $value;
   }
   $this->{$key}
}
 
EOF

# All right, that should be easy!

$tree->start();

is ($tree->get_value('basevar'), 0);    # Basevar is initialized.
is ($tree->get_value('variable'), 0);   # So far, so good.

$tree->setvalue('variable', 1);
is ($tree->get_value('variable'), 1);
is ($tree->get_value('basevar'), 0);    # Variable has no effect on basevar.

$tree->setvalue('basevar', 2);
is ($tree->get_value('basevar'), 2);
is ($tree->get_value('variable'), -2);  # Basevar has magic code that affects variable.
