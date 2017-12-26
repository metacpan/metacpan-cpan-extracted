#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Parser;

my $Parsed = Mail::AuthenticationResults::Parser->new()->parse( ' test.example.com ; foo=bar;dkim=fail ;one=; two ;three;dmarc=pass' );
my $Result = $Parsed->as_string();
is( $Result, "test.example.com;\nfoo=bar;\ndkim=fail;\none=;\ntwo=;\nthree=;\ndmarc=pass", 'Result ok' );

my $Parsed2 = Mail::AuthenticationResults::Parser->new()->parse( 'test.example.com;one=two three=four (comment) five=six' );

is ( ref $Parsed2, 'Mail::AuthenticationResults::Header', 'Isa Header' );
is ( scalar @{ $Parsed2->children() }, 1, 'Header with 1 child' );

my $Parsed2Child = $Parsed2->children()->[0];
is ( ref $Parsed2Child, 'Mail::AuthenticationResults::Header::Entry', 'Isa Entry' );
is ( scalar @{ $Parsed2Child->children() }, 2, 'Entry with 2 grandchildren' );

my $Parsed2Grand1 = $Parsed2Child->children()->[0];
is ( ref $Parsed2Grand1, 'Mail::AuthenticationResults::Header::SubEntry', 'First Isa SubEntry' );
is ( scalar @{ $Parsed2Grand1->children() }, 1, 'SubEntry with 2 grandchildren' );

my $Parsed2Grand1Child = $Parsed2Grand1->children()->[0];
is ( ref $Parsed2Grand1Child, 'Mail::AuthenticationResults::Header::Comment', 'Isa Comment' );
dies_ok( sub{ $Parsed2Grand1Child->children() }, 'Comment children throws' );

my $Parsed2Grand2 = $Parsed2Child->children()->[1];
is ( ref $Parsed2Grand2, 'Mail::AuthenticationResults::Header::SubEntry', 'First Isa SubEntry' );
is ( scalar @{ $Parsed2Grand2->children() }, 0, 'SubEntry with 0 grandchildren' );

done_testing();

