use strict;
use warnings;
use Test::More tests => 1;
use HTTP::Proxy;
use HTTP::Proxy::GreaseMonkey;
use File::Spec;
use URI;

package Fake::Message;

sub new { bless { uri => new URI($_[1]) }, $_[0] }
sub request { shift }
sub uri     { shift->{uri} }

package main;

my $gm = HTTP::Proxy::GreaseMonkey->new();

for my $name ( qw( u1.js u2.js ) ) {
    $gm->add_script( File::Spec->catfile( 't', 'scripts', $name ) );
}

my $msg = Fake::Message->new( 'http://hexten.net/index.html' );
$gm->begin( $msg );

my $body = '<html><head></head><body></body></html>';
$gm->filter( \$body, $msg, 'http', undef );

like $body, qr/Whoop.+Fnurk/s, 'whoop';
