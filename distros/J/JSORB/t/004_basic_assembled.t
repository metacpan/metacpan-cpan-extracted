#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 40;
use Test::Exception;
use Test::Moose;

BEGIN {
    use_ok('JSORB');
}

{
    package Math::Simple;
    sub add { $_[0] + $_[1] }
    sub sub { $_[0] - $_[1] }
}

my $ns = JSORB::Namespace->new(name => 'Math');
isa_ok($ns, 'JSORB::Namespace');
isa_ok($ns, 'JSORB::Core::Element');

my $interface = JSORB::Interface->new(name => 'Simple');
isa_ok($interface, 'JSORB::Interface');
isa_ok($interface, 'JSORB::Namespace');
isa_ok($interface, 'JSORB::Core::Element');
        
my $add = JSORB::Procedure->new(
    name  => 'add',
    spec  => [ 'Int' => 'Int' => 'Int' ],
);
isa_ok($add, 'JSORB::Procedure');
isa_ok($add, 'JSORB::Core::Element');

# now start digging ...

is($ns->name, 'Math', '... got there right name');
is_deeply($ns->fully_qualified_name, ['Math'], '... got the right fully qualified Perl name');

ok(!$ns->get_element_by_name('Simple'), '... no Simple element yet');

lives_ok {
    $ns->add_element($interface);
} '... added the Simple element correctly';

my $i = $ns->get_element_by_name('Simple');
isa_ok($i, 'JSORB::Interface');
isa_ok($i, 'JSORB::Namespace');
isa_ok($i, 'JSORB::Core::Element');

is($i->name, 'Simple', '... got the right name');
is_deeply($i->fully_qualified_name, ['Math', 'Simple'], '... got the right fully qualified Perl name');

ok(!$i->get_procedure_by_name('add'), '... no add procedure yet');

lives_ok {
    $i->add_procedure($add);
} '... added the add procedure correctly';

{
    my $proc = $i->get_procedure_by_name('add');
    isa_ok($proc, 'JSORB::Procedure');
    isa_ok($proc, 'JSORB::Core::Element');

    is($proc->name, 'add', '... got the right name');
    is_deeply($proc->fully_qualified_name, [qw[Math Simple add]], '... got the right fully qualified Perl name');
    is($proc->body, \&Math::Simple::add, '... got the body we expected');
    is_deeply($proc->spec, [ qw[ Int Int Int ] ], '... got the spec we expected');

    is_deeply($proc->parameter_spec, [ qw[ Int Int ] ], '... got the parameter spec we expected');
    is($proc->return_value_spec, 'Int', '... got the return value spec we expected');
    
    my $result;
    lives_ok {
        $result = $proc->call(2, 2)
    } '... call succedded';
    is($result, 4, '... got the result we expected');
}

lives_ok {
    $i->add_procedure(
        JSORB::Procedure->new(
            name  => 'sub',
            spec  => [ 'Int' => 'Int' => 'Int' ],
        )
    );
} '... added the procedure successfully';

{
    my $proc = $i->get_procedure_by_name('sub');
    isa_ok($proc, 'JSORB::Procedure');
    isa_ok($proc, 'JSORB::Core::Element');

    is($proc->name, 'sub', '... got the right name');
    is_deeply($proc->fully_qualified_name, [qw[Math Simple sub]], '... got the right fully qualified Perl name');
    is($proc->body, \&Math::Simple::sub, '... got the body we expected');
    is_deeply($proc->spec, [ qw[ Int Int Int ] ], '... got the spec we expected');

    is_deeply($proc->parameter_spec, [ qw[ Int Int ] ], '... got the parameter spec we expected');
    is($proc->return_value_spec, 'Int', '... got the return value spec we expected');
    
    my $result;
    lives_ok {
        $result = $proc->call(2, 2)
    } '... call succedded';
    is($result, 0, '... got the result we expected');
}

