#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Parser;
use Mail::AuthenticationResults::Header::Group;

my $Group = Mail::AuthenticationResults::Header::Group->new();

$Group->add_child( Mail::AuthenticationResults::Parser->new()->parse( 'test.example.com;one=two three=four (comment) five=six' ) );
$Group->add_child( Mail::AuthenticationResults::Parser->new()->parse( 'test2.example.com;one=two three=four (comment) five=six' ) );
$Group->add_child( Mail::AuthenticationResults::Parser->new()->parse( 'test.example.org;one=one three=three (comments) five=five' ) );
$Group->add_child( Mail::AuthenticationResults::Parser->new()->parse( 'test.example.org;newone=one newthree=three (comments) newfive=five' ) );

my $Found = $Group->search({ 'isa' => 'header', 'authserv_id' => 'test.example.com' });
$Found->children()->[0]->set_indent_style( 'none' );
is( $Found->as_string(), 'test.example.com; one=two three=four (comment) five=six', 'Found AuthServ ID' );

my $NotFound = $Group->search({ 'authserv_id' => 'test.example.net' });
is( scalar @{$NotFound->children() }, 0, 'Did not find missing AuthServ Id' );

my $FoundRegex = $Group->search({ 'authserv_id' => qr/\.example\.com$/ });
is( scalar @{$FoundRegex->children() }, 2, 'Found 2 results for Regex match' );

my $Found2 = $Group->search({ 'authserv_id' => 'test.example.org' });
is( scalar @{$Found2->children() }, 2, 'Found 2 results for Multiple match' );

my $Value = $Group->search({ 'value' => 'six' });
my $NotRelevant = $Value->search({ 'authserv_id' => 'test.example.com' });
is( scalar @{$NotRelevant->children() }, 0, 'Search on an entry found nothing' );

done_testing();

