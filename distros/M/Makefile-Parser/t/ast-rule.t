use strict;
use warnings;
use Test::More tests => 21;
use Makefile::AST::Rule;
use Makefile::AST::Rule::Implicit;

{

my $rule = Makefile::AST::Rule::Base->new(
  {
    normal_prereqs => [qw(a b c)],
    order_prereqs  => [qw(d e f)],
    commands       => [qw(c1 c2 c3)],
    colon          => ':',
  }
);
ok $rule, 'rule obj ok';
isa_ok $rule, 'Makefile::AST::Rule::Base', 'rule class okay';
is join(' ', @{ $rule->normal_prereqs }), 'a b c';
is join(' ', @{ $rule->order_prereqs }), 'd e f';
is join(' ', @{ $rule->commands }), 'c1 c2 c3';
is $rule->colon, ':';

}

{

my $rule = Makefile::AST::Rule->new(
  {
    normal_prereqs => [qw(a b c)],
    order_prereqs  => [qw(d e f)],
    commands       => [qw(c1 c2 c3)],
    colon          => ':',
    target         => 'blah',
    stem           => 'foo',
    other_targets  => [qw(baz boz)],
  }
);
ok $rule, 'rule obj ok';
isa_ok $rule, 'Makefile::AST::Rule::Base', 'rule class okay';
is join(' ', @{ $rule->normal_prereqs }), 'a b c';
is join(' ', @{ $rule->order_prereqs }), 'd e f';
is join(' ', @{ $rule->commands }), 'c1 c2 c3';
is $rule->colon, ':';
is $rule->target, 'blah', 'target is readable';
$rule->target('hey');
is $rule->target, 'hey', 'target is writable';

}

{

my $rule = Makefile::AST::Rule::Implicit->new(
  {
    normal_prereqs => [qw(a b c)],
    order_prereqs  => [qw(d e f)],
    commands       => [qw(c1 c2 c3)],
    colon          => '::',
    targets        => [qw( %.lib %.dll )],
  }
);
ok $rule, 'rule obj ok';
isa_ok $rule, 'Makefile::AST::Rule::Base', 'rule class okay';
is join(' ', @{ $rule->normal_prereqs }), 'a b c';
is join(' ', @{ $rule->order_prereqs }), 'd e f';
is join(' ', @{ $rule->commands }), 'c1 c2 c3';
is $rule->colon, '::';
is join(' ', @{ $rule->targets }), '%.lib %.dll', 'targets are readable';

}

