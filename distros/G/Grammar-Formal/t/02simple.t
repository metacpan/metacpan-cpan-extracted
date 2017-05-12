
use Test::More tests => 3;

use Grammar::Formal;
my $g = Grammar::Formal->new;

my $s1 = Grammar::Formal::CaseSensitiveString->new(value => "a");
my $s2 = Grammar::Formal::CaseSensitiveString->new(value => "b");
my $choice = Grammar::Formal::Choice->new(p1 => $s1, p2 => $s2);

is($s1->parent, $choice);

eval {
  my $choice2 = Grammar::Formal::Choice->new(p1 => $s1, p2 => $s2);
};

ok($@, 'cannot re-parent nodes');

$g->set_rule("a-or-b" => $choice);

is($g->rules->{'a-or-b'}, $choice);
