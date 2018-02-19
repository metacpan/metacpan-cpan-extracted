#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Parser;

my $Input = [
  'iprev=fail policy.iprev=123.123.123.123 (NOT FOUND)',
  'x-ptr=fail x-ptr-helo=bad.name.google.com x-ptr-lookup=',
];

my $InputARHeader = join( ";\n", 'test.example.com', @$Input );

my $Parser = Mail::AuthenticationResults::Parser->new( $InputARHeader );
my $Parsed = $Parser->parsed();

my $LR = "test.example.com;\n    iprev=fail policy.iprev=123.123.123.123 (NOT FOUND);\n    x-ptr=fail x-ptr-helo=bad.name.google.com x-ptr-lookup=\"\"";
my $CRLF = "test.example.com;\r\n    iprev=fail policy.iprev=123.123.123.123 (NOT FOUND);\r\n    x-ptr=fail x-ptr-helo=bad.name.google.com x-ptr-lookup=\"\"";

$Parsed->set_indent_style( 'entry' );

is( $Parsed->as_string(), $LR, 'Default is LR' );
$Parsed->set_eol( "\r\n" );
is( $Parsed->as_string(), $CRLF, 'Set CRLR' );
$Parsed->set_eol( "\n" );
is( $Parsed->as_string(), $LR, 'Set LR' );

dies_ok( sub{ $Parsed->set_eol( "**" ); }, 'Invalid eol dies' );

done_testing();

