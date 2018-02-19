#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Parser;

my $Parsed = Mail::AuthenticationResults::Parser->new()->parse( ' test.example.com ; foo=bar;dkim=fail ;one=; two ;three;dmarc=pass' );
my $Result = $Parsed->as_string();
is( $Result, "test.example.com;\n    foo=bar;\n    dkim=fail;\n    one=\"\";\n    two=\"\";\n    three=\"\";\n    dmarc=pass", 'Result ok' );

my $Parsed2 = Mail::AuthenticationResults::Parser->new()->parse( 'Authentication-Results: test.example.com;one=two three=four (comment) five=six' );

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

my $ParsedAuthServID = Mail::AuthenticationResults::Parser->new()->parse( 'test.example.com 1 (this has a version); none' );
my $AuthServIDValue = $ParsedAuthServID->value();
is ( ref $AuthServIDValue, 'Mail::AuthenticationResults::Header::AuthServID', 'AuthServID Object Returned' );
is ( scalar @{ $AuthServIDValue->children() }, 2, 'AuthServID Object has 2 children' );
is ( ref $AuthServIDValue->children()->[1], 'Mail::AuthenticationResults::Header::Version', 'Version Object Returned' );
is ( $AuthServIDValue->children()->[1]->value(), '1', 'Version has correct value' );
is ( ref $AuthServIDValue->children()->[0], 'Mail::AuthenticationResults::Header::Comment', 'Comment Object Returned' );
is ( $AuthServIDValue->children()->[0]->value(), 'this has a version', 'Comment has correct value' );
is ( $AuthServIDValue->as_string(), 'test.example.com (this has a version) 1', 'AuthServID as string is correct' );
is ( $ParsedAuthServID->as_string(), "test.example.com (this has a version) 1; none", 'Header as string is correct' );

my $ParsedCommentFirst = Mail::AuthenticationResults::Parser->new()->parse( '(comment first) test.example.com;none' );
is ( $ParsedCommentFirst->as_string(), "test.example.com (comment first); none", 'Header as string is correct' );

my $ParsedPostAssign;
lives_ok( sub{ $ParsedPostAssign = Mail::AuthenticationResults::Parser->new()->parse( 'example.com; dkim=pass address=thisisa=test@example.com') }, 'Post Assign parse lives' );
is( $ParsedPostAssign->children()->[0]->children->[0]->value(), 'thisisa=test@example.com', 'Post assign value correct' );
is( $ParsedPostAssign->children()->[0]->children->[0]->as_string(), 'address="thisisa=test@example.com"', 'Post assign stringify correct' );

dies_ok( sub{ Mail::AuthenticationResults::Parser->new()->parse( ';none' ) }, 'Missing AuthServ-ID dies' );

done_testing();

