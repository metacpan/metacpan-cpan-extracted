use strict;
use warnings;

use Test::More tests => 27;
use Makefile::AST;

my $ast = Makefile::AST->new;
ok $ast, 'ast obj ok';
isa_ok $ast, 'Makefile::AST', 'ast class ok';

my $var = Makefile::AST::Variable->new({
    name => 'foo',
    flavor => 'simple',
    origin => 'makefile',
    value => 'bar',
});
$ast->add_var($var);
my $var2 = $ast->get_var('foo');
is $var2, $var, 'get_var ok';

$ast->add_auto_var('@' => 'blah');
$var = $ast->get_var('@');
is $var->name, '@';
is $var->flavor, 'simple';
is $var->origin, 'automatic';
is $var->value->[0], 'blah';
my $rules = $ast->implicit_rules();
is_deeply $rules, [];

my $rule = Makefile::AST::Rule::Implicit->new({
        targets => ['%.pm','%.c'],
        normal_prereqs => ['%.cpp', '%.h', 'foo.h'],
        order_prereqs => ['foo', '%.bar'],
        commands => ['echo', 'hello', 'world'],
        colon => ':',
    });
$ast->add_implicit_rule($rule);
ok $ast->target_ought_to_exist('foo');
ok ! $ast->target_ought_to_exist('bar');
ok $ast->target_ought_to_exist('foo.h');
ok !$ast->target_ought_to_exist('bar.pm');
ok !$ast->target_ought_to_exist('%.pm');
ok !$ast->target_ought_to_exist('%.c');
ok !$ast->target_ought_to_exist('%.cpp');
ok !$ast->target_ought_to_exist('%.h');

$rules = $ast->implicit_rules();
is_deeply $rules, [$rule];

my $applied = $ast->apply_explicit_rules('foo.pm');
is $applied, undef;

$applied = $ast->apply_implicit_rules('foo.pm');
is $applied, undef;

$ast->{targets}->{'foo.cpp'} = 1;
# $ast->{targets}->{'foo.bar'} = 1;
$applied = $ast->apply_implicit_rules('foo.pm');
is $applied, undef;

$ast->{targets}->{'foo.cpp'} = 1;
# $ast->{targets}->{'foo.bar'} = 1;
$applied = $ast->apply_implicit_rules('foo.pm');
is $applied, undef;

$ast->{targets}->{'foo.cpp'} = 1;
$ast->{targets}->{'foo.bar'} = 1;
$applied = $ast->apply_implicit_rules('foo.pm');
ok $applied;
is $applied->target, 'foo.pm';
is join(' ', @{ $applied->other_targets }), 'foo.c';
is join(' ', @{ $applied->normal_prereqs }), 'foo.cpp foo.h foo.h';
is join(' ', @{ $applied->order_prereqs }), 'foo foo.bar';

$rule = Makefile::AST::Rule->new({
        target => 'blah.exe',
        normal_prereqs => ['blah.cpp', 'blah.h'],
        order_prereqs => [],
        commands => ['echo'],
        colon => ':',
    });
$ast->add_explicit_rule($rule);
my ($rule2) = $ast->apply_explicit_rules('blah.exe');
is $rule2, $rule;

