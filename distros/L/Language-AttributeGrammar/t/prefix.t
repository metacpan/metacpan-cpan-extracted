use Test::More tests => 5;

BEGIN { use_ok('Language::AttributeGrammar') }

my $grammar = new Language::AttributeGrammar { prefix => 'Root::' }, <<'EOG';

Foo:         $/.foo = { 1 }
Bar::Baz:    $/.foo = { 2 }
::Quux:      $/.foo = { 3 }
::Quux::Baz: $/.foo = { 4 }

EOG

is($grammar->apply((bless { } => 'Root::Foo'), 'foo'), 1, "normal prefix");
is($grammar->apply((bless { } => 'Root::Bar::Baz'), 'foo'), 2, "two-level prefix");
is($grammar->apply((bless { } => 'Quux'), 'foo'), 3, "prefix override");
is($grammar->apply((bless { } => 'Quux::Baz'), 'foo'), 4, "two-level prefix override");

# vim: ft=perl :
