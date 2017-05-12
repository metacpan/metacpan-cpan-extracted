#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 39;
use Test::Exception;
use Test::Moose;

BEGIN {
    use_ok('JSORB');
}

{
    package Math::Simple;
    sub add { $_[0] + $_[1] }
    sub sub { $_[0] - $_[1] }
    package Math::More;
    sub mul { $_[0] * $_[1] }
    sub div { $_[0] % $_[1] }        
    package Math::More::Long;
    sub multiply { $_[0] * $_[1] }
    sub divide   { $_[0] % $_[1] }    
}

my $ns1 = JSORB::Namespace->new(
    name     => 'Math',
    elements => [
        JSORB::Interface->new(
            name       => 'Simple',
            procedures => [
                JSORB::Procedure->new(
                    name  => 'add',
                    spec  => [ 'Int' => 'Int' => 'Int' ],
                ),
            ]
        ),
        JSORB::Interface->new(
            name       => 'More',
            procedures => [
                JSORB::Procedure->new(
                    name  => 'mul',
                    spec  => [ 'Int' => 'Int' => 'Int' ],
                ),
            ],
            elements => [
                JSORB::Interface->new(
                    name       => 'Long',
                    procedures => [
                        JSORB::Procedure->new(
                            name  => 'multiply',
                            spec  => [ 'Int' => 'Int' => 'Int' ],
                        ),
                    ]
                )            
            ]
        ),        
    ]
);
isa_ok($ns1, 'JSORB::Namespace');

my $ns2 = JSORB::Namespace->new(
    name     => 'Math',
    elements => [
        JSORB::Interface->new(
            name       => 'More',
            procedures => [
                JSORB::Procedure->new(
                    name  => 'div',
                    spec  => [ 'Int' => 'Int' => 'Int' ],
                ),
            ],
            elements => [
                JSORB::Interface->new(
                    name       => 'Long',
                    procedures => [
                        JSORB::Procedure->new(
                            name  => 'divide',
                            spec  => [ 'Int' => 'Int' => 'Int' ],
                        ),                
                    ]
                )            
            ]            
        ),    
        JSORB::Interface->new(
            name       => 'Simple',
            procedures => [
                JSORB::Procedure->new(
                    name  => 'sub',
                    spec  => [ 'Int' => 'Int' => 'Int' ],
                )
            ]
        )
    ]
);    
isa_ok($ns2, 'JSORB::Namespace');


{
    my $ns3 = $ns1->merge_with($ns2);    
    isa_ok($ns3, 'JSORB::Namespace');

    is($ns3->name, 'Math', '... got there right name');
    is_deeply($ns3->fully_qualified_name, ['Math'], '... got the right fully qualified Perl name');

    {
        my $i = $ns3->get_element_by_name('Simple');
        isa_ok($i, 'JSORB::Interface');

        is($i->name, 'Simple', '... got the right name');
        is_deeply($i->fully_qualified_name, ['Math', 'Simple'], '... got the right fully qualified Perl name');
    
        {
            my $proc = $i->get_procedure_by_name('add');
            isa_ok($proc, 'JSORB::Procedure');

            is($proc->name, 'add', '... got the right name');
            is_deeply($proc->fully_qualified_name, [qw[Math Simple add]], '... got the right fully qualified Perl name');
            is($proc->body, \&Math::Simple::add, '... got the body we expected');
        }

        {
            my $proc = $i->get_procedure_by_name('sub');
            isa_ok($proc, 'JSORB::Procedure');

            is($proc->name, 'sub', '... got the right name');
            is_deeply($proc->fully_qualified_name, [qw[Math Simple sub]], '... got the right fully qualified Perl name');
            is($proc->body, \&Math::Simple::sub, '... got the body we expected');
        }
    }
    
    {
        my $i = $ns3->get_element_by_name('More');
        isa_ok($i, 'JSORB::Interface');

        is($i->name, 'More', '... got the right name');
        is_deeply($i->fully_qualified_name, ['Math', 'More'], '... got the right fully qualified Perl name');
    
        {
            my $proc = $i->get_procedure_by_name('mul');
            isa_ok($proc, 'JSORB::Procedure');

            is($proc->name, 'mul', '... got the right name');
            is_deeply($proc->fully_qualified_name, [qw[Math More mul]], '... got the right fully qualified Perl name');
            is($proc->body, \&Math::More::mul, '... got the body we expected');
        }

        {
            my $proc = $i->get_procedure_by_name('div');
            isa_ok($proc, 'JSORB::Procedure');

            is($proc->name, 'div', '... got the right name');
            is_deeply($proc->fully_qualified_name, [qw[Math More div]], '... got the right fully qualified Perl name');
            is($proc->body, \&Math::More::div, '... got the body we expected');
        }
        
        {
            my $i = $i->get_element_by_name('Long');
            isa_ok($i, 'JSORB::Interface');

            is($i->name, 'Long', '... got the right name');
            is_deeply($i->fully_qualified_name, ['Math', 'More', 'Long'], '... got the right fully qualified Perl name');

            {
                my $proc = $i->get_procedure_by_name('multiply');
                isa_ok($proc, 'JSORB::Procedure');

                is($proc->name, 'multiply', '... got the right name');
                is_deeply($proc->fully_qualified_name, [qw[Math More Long multiply]], '... got the right fully qualified Perl name');
                is($proc->body, \&Math::More::Long::multiply, '... got the body we expected');
            }

            {
                my $proc = $i->get_procedure_by_name('divide');
                isa_ok($proc, 'JSORB::Procedure');

                is($proc->name, 'divide', '... got the right name');
                is_deeply($proc->fully_qualified_name, [qw[Math More Long divide]], '... got the right fully qualified Perl name');
                is($proc->body, \&Math::More::Long::divide, '... got the body we expected');
            }
        }        
    }    
}
