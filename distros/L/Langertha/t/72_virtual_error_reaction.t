#!/usr/bin/env perl
# ABSTRACT: the error(...) reaction of Langertha::Engine::Virtual fails the request with its HTTP status, in process

use strict;
use warnings;

use Test2::Bundle::More;

use Langertha::Engine::Virtual;
use Langertha::Virtual::Rules qw( answer error );

my $engine = Langertha::Engine::Virtual->new(
  rules => [
    'Limit'  => error( 429, 'Rate limit reached' ),
    'Sub'    => sub { error( 503, 'Overloaded' ) },
    'Hello'  => answer('Hi'),
  ],
  langfuse_enabled => 0,
);

is_deeply( error( 429, 'x' ), { error => { status => 429, message => 'x' } }, 'error() is plain data' );

ok( !eval { $engine->simple_chat('Limit'); 1 }, 'simple_chat fails' );
like( $@, qr/429 Too Many Requests.*Rate limit reached/s, '... with the status, its reason and the message' );
ok( !eval { $engine->simple_chat('Sub'); 1 }, 'a sub may return an error reaction' );
like( $@, qr/503 Service Unavailable.*Overloaded/s, '... with its status' );
like( $engine->simple_chat_f('Limit')->failure, qr/429.*Rate limit reached/s, 'the _f calls fail the same way' );
is( "".$engine->simple_chat('Hello'), 'Hi', 'the engine keeps answering afterwards' );
is( scalar @{ $engine->requests }, 4, 'failed requests are recorded too' );

my $reply = $engine->virtual_reply( POST => '/v1/chat/completions',
  '{"model":"m","messages":[{"role":"user","content":"Limit"}]}' );
is_deeply( [ @{$reply}{qw( code message content )} ], [ 429, 'Too Many Requests', 'Rate limit reached' ],
  'virtual_reply hands the failure over as data' );

for my $bad ( [ 200, 'x' ], [ 'abc', 'x' ], [ 429, undef ], [ 429, [] ] ) {
  ok( !eval { error(@$bad); 1 }, 'error('.join( ', ', map { $_ // 'undef' } @$bad ).') croaks' );
}
ok( !eval { Langertha::Engine::Virtual->new( rules => [ 'x' => { error => { status => 429, message => 'm' }, answer => 'a' } ] ); 1 },
  'an error together with an answer croaks when the engine is built' );
like( $@, qr/error together with an answer/, '... and says so' );

done_testing;
