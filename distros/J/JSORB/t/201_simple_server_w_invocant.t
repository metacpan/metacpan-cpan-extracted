#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;
use Test::Exception;
use Test::WWW::Mechanize;

BEGIN {
    use_ok('JSORB');
    use_ok('JSORB::Dispatcher::Path');
    use_ok('JSORB::Server::Simple');
}

{
    package App::Foo;
    use Moose;
    
    has 'bar' => (
        is      => 'ro',
        isa     => 'Str',   
        default => sub { "BAR" },
    );
    
    has 'baz' => (
        is      => 'ro',
        isa     => 'Str',   
        default => sub { "BAZ" },
    );    
}

my $ns = JSORB::Namespace->new(
    name     => 'App',
    elements => [
        JSORB::Interface->new(
            name       => 'Foo',            
            procedures => [
                JSORB::Method->new(
                    name  => 'bar',
                    spec  => [ 'Unit' => 'Str' ],
                ),
                JSORB::Method->new(
                    name  => 'baz',
                    spec  => [ 'Unit' => 'Str' ],
                ),                                                              
            ]
        )            
    ]
);
isa_ok($ns, 'JSORB::Namespace');

my $d = JSORB::Dispatcher::Path->new_with_traits(
    traits    => [ 'JSORB::Dispatcher::Traits::WithInvocant' ],
    namespace => $ns,
);
isa_ok($d, 'JSORB::Dispatcher::Path');

my $s = JSORB::Server::Simple->new_with_traits(
    traits     => [ 'JSORB::Server::Traits::WithInvocant' ],
    dispatcher => $d,
    invocant   => App::Foo->new(bar => 'Bar', baz => 'Baz')
);
isa_ok($s, 'JSORB::Server::Simple');

my $pid = fork;

unless ($pid) {
    $s->run;
    exit();
}
else {
    my $mech = Test::WWW::Mechanize->new;  
    $mech->get_ok('http://localhost:9999/?method=/app/foo/bar');    
    $mech->content_contains('"result":"Bar"', '... got the content we expected');
    
    $mech->get_ok('http://localhost:9999/?method=/app/foo/baz');    
    $mech->content_contains('"result":"Baz"', '... got the content we expected');
    
    ok($mech->get('http://localhost:9999/?method=/app/foo/bar&params=[2,0]'), '... the content with an error');  
    is($mech->status, 500, '... got the HTTP error we expected');  
    #diag $mech->content;
    $mech->content_contains('"error":', '... got the content we expected');    
    $mech->content_contains('"Bad number of arguments', '... got the content we expected');    
}

END {
    kill TERM => $pid; 
}








