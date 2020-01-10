#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Parser;

#plan tests => noplan1;

chdir 't';

my $Input = [
  'dmarc=fail (p=none,d=none) header.from=.net',
  'dmarc=fail (p=none,d=none) header.from=..net',
];

my $Output = [
  'dmarc=fail (p=none,d=none) header.from=.net',
  'dmarc=fail (p=none,d=none) header.from=..net',
];

my $InputARHeader = join( ";\n", 'test.example.com', @$Input );

my $Parser;
dies_ok( sub{ $Parser = Mail::AuthenticationResults::Parser->new()->parse( '' ) }, 'Parser dies on empty' );
lives_ok( sub{ $Parser = Mail::AuthenticationResults::Parser->new( $InputARHeader ) }, 'Parser parses' );
is( ref $Parser, 'Mail::AuthenticationResults::Parser', 'Returns Parser Object' );

my $Header;
lives_ok( sub{ $Header = $Parser->parsed() }, 'Parser returns data' );
is( ref $Header, 'Mail::AuthenticationResults::Header', 'Returns Header Object' );
is( $Header->value()->value(), 'test.example.com', 'Authserve Id correct' );
is( $Header->as_string(), join( ";\n    ", 'test.example.com', @$Output ), 'As String data matches input data' );
is( $Header->search({'isa'=>'subentry','key'=>'header.from'})->children->[0]->value, '.net', 'Value 0 correct' );
is( $Header->search({'isa'=>'subentry','key'=>'header.from'})->children->[1]->value, '..net', 'Value 1 correct' );

done_testing();

