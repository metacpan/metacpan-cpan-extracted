#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 34;
use Test::Exception;

use JSON::RPC::Common::Procedure::Call;

BEGIN {
    use_ok('JSORB');
    use_ok('JSORB::Dispatcher::Path');
}

sub add { $_[0] + $_[1] }
sub sub { $_[0] - $_[1] }
sub mul { $_[0] * $_[1] }
sub div { $_[0] / $_[1] }

my $ns = JSORB::Namespace->new(
    name     => 'Math',
    elements => [
        JSORB::Interface->new(
            name       => 'Simple',            
            procedures => [
                JSORB::Procedure->new(
                    name  => 'add',
                    body  => \&add,
                    spec  => [ 'Int' => 'Int' => 'Int' ],
                ),
                JSORB::Procedure->new(
                    name  => 'sub',
                    body  => \&sub,
                    spec  => [ 'Int' => 'Int' => 'Int' ],
                ),
                JSORB::Procedure->new(
                    name  => 'mul',
                    body  => \&mul,
                    spec  => [ 'Int' => 'Int' => 'Int' ],
                ),
                JSORB::Procedure->new(
                    name  => 'div',
                    body  => \&div,
                    spec  => [ 'Int' => 'Int' => 'Int' ],
                ),                                               
            ]
        )            
    ]
);
isa_ok($ns, 'JSORB::Namespace');

my $d = JSORB::Dispatcher::Path->new(namespace => $ns);
isa_ok($d, 'JSORB::Dispatcher::Path');

is($d->namespace, $ns, '... got the same namespace');

is(
    $ns->get_element_by_name('Simple')->get_procedure_by_name($_),
    $d->router->match('/math/simple/' . $_)->target,
    '... got the right target (' . $_ . ')'
) foreach qw[ add sub mul div ];

my @calls = (
    JSON::RPC::Common::Procedure::Call->new(
	    method => "/math/simple/add",
	    params => [ 2, 2 ],
    ),
    JSON::RPC::Common::Procedure::Call->new(
	    method => "/math/simple/sub",
	    params => [ 8, 4 ],
    ),        
    JSON::RPC::Common::Procedure::Call->new(
	    method => "/math/simple/mul",
	    params => [ 2, 2 ],
    ),    
    JSON::RPC::Common::Procedure::Call->new(
	    method => "/math/simple/div",
	    params => [ 16, 4 ],
    ),    
);

foreach my $call (@calls) {
    my $res = $d->handler($call);
    isa_ok($res, 'JSON::RPC::Common::Procedure::Return');

    ok($res->has_result, '... we have a result, not an error');
    ok(!$res->has_error, '... we have a result, not an error');

    is($res->result, 4, '... got the result we expected');
}

my @errors = (
    # method not found ...
    JSON::RPC::Common::Procedure::Call->new(
	    method => "/math/simple/add_me",
    ),
    # type failure ...
    JSON::RPC::Common::Procedure::Call->new(
	    method => "/math/simple/add",
	    params => [ 'FOO', 10 ]
    ),    
    # division by zero error ...
    JSON::RPC::Common::Procedure::Call->new(
	    method => "/math/simple/div",
	    params => [ 4, 0 ],
    ),    
);

foreach my $error (@errors) {
    my $res = $d->handler($error);
    isa_ok($res, 'JSON::RPC::Common::Procedure::Return');

    ok(!$res->has_result, '... we have an error, not an result');
    ok($res->has_error, '... we have an error, not an result');
    
    #diag $res->error->message;
}

























