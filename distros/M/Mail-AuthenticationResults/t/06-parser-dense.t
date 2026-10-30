#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;

use lib 'lib';
use Mail::AuthenticationResults::Parser;

# A single header containing a large number of assertions should not
# retain a copy of the remaining header in every token, doing so uses
# memory quadratic in the number of assertions.

my $count = 2000;
my @parts;
for my $i ( 0 .. $count - 1 ) {
    if ( $i % 3 ) {
        push @parts, 'dkim' . ( $i % 3 ) . "=pass (2048-bit key) header.d=d$i.test header.s=s$i";
    }
    else {
        push @parts, "spf=pass smtp.mailfrom=u$i.test";
    }
}
my $header = 'Authentication-Results: ' . join( ";\r\n ", 'mx.local.test', @parts );

my $parser = Mail::AuthenticationResults::Parser->new();
my $parsed = $parser->parse( $header );

is( scalar @{ $parsed->children() }, $count, 'All assertions parsed' );
is( $parsed->value()->value(), 'mx.local.test', 'AuthServ-ID parsed' );

my $last = $parsed->children()->[-1];
is( $last->key(), 'dkim1', 'Last entry key correct' );
is( $last->value(), 'pass', 'Last entry value correct' );
is( $last->search({ 'key' => 'header.s' })->children()->[0]->value(), 's' . ( $count - 1 ), 'Last entry sub entry correct' );

my $tokeniser = Mail::AuthenticationResults::Parser->new();
$tokeniser->tokenise( $header );
my $tokens = $tokeniser->{ 'tokenised' };
cmp_ok( scalar @$tokens, '>', $count * 8, 'Tokens generated' );

my $retained = 0;
foreach my $token ( @$tokens ) {
    $retained += length $token->{ 'header' } if defined $token->{ 'header' };
}
is( $retained, 0, 'Tokens do not retain the remaining header' );
is( $tokens->[0]->remainder(), undef, 'Parser created tokens return undef for remainder' );

done_testing();
