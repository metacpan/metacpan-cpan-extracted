#!/usr/bin/perl
use lib 'lib';
use Test::More;
BEGIN{ use_ok( 'Config::Tiny' ); }

my $parser = Config::Tiny->new();
isa_ok( $parser, Config::Tiny );
my $cfg = $parser->read('t/regexfile');
is( $parser->errstr, '', "read error message");

done_testing();
