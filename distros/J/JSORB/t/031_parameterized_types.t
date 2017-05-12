#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 20;
use Test::Exception;
use Test::Moose;

BEGIN {
    use_ok('JSORB');
}

sub sum {
    my ($x, @rest) = @{$_[0]};
    return $x unless @rest;
    return $x + sum(\@rest);
}

my $ns = JSORB::Namespace->new(
    name     => 'Math',
    elements => [
        JSORB::Interface->new(
            name       => 'Simple',            
            procedures => [
                JSORB::Procedure->new(
                    name  => 'sum',
                    body  => \&sum,
                    spec  => [ 'ArrayRef[Int]' => 'Int' ],
                )
            ]
        )            
    ]
);
isa_ok($ns, 'JSORB::Namespace');
isa_ok($ns, 'JSORB::Core::Element');

is($ns->name, 'Math', '... got there right name');
is_deeply($ns->fully_qualified_name, ['Math'], '... got the right fully qualified Perl name');

my $i = $ns->get_element_by_name('Simple');
isa_ok($i, 'JSORB::Interface');
isa_ok($i, 'JSORB::Namespace');
isa_ok($i, 'JSORB::Core::Element');

is($i->name, 'Simple', '... got the right name');
is_deeply($i->fully_qualified_name, ['Math', 'Simple'], '... got the right fully qualified Perl name');

my $proc = $i->get_procedure_by_name('sum');
isa_ok($proc, 'JSORB::Procedure');
isa_ok($proc, 'JSORB::Core::Element');

is($proc->name, 'sum', '... got the right name');
is_deeply($proc->fully_qualified_name, [qw[Math Simple sum]], '... got the right fully qualified Perl name');
is($proc->body, \&sum, '... got the body we expected');
is_deeply($proc->spec, [ qw/ ArrayRef[Int] Int / ], '... got the spec we expected');

is_deeply($proc->parameter_spec, [ 'ArrayRef[Int]' ], '... got the parameter spec we expected');
is($proc->return_value_spec, 'Int', '... got the return value spec we expected');

my $result;
lives_ok {
    $result = $proc->call([ 1 .. 5 ])
} '... call succedded';
is($result, 15, '... got the result we expected');



