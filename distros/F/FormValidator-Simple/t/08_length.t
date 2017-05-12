use strict;
use Test::More tests => 7;
use CGI;

BEGIN{ use_ok("FormValidator::Simple") }

my $q = CGI->new;
$q->param( text => 'text' );

my $r = FormValidator::Simple->check( $q => [
    text => [qw/NOT_BLANK/,[qw/LENGTH 4/]],
] );

ok(!$r->invalid('text'));

my $r2 = FormValidator::Simple->check( $q => [
    text => [qw/NOT_BLANK/,[qw/LENGTH 2 5/]],
] );

ok(!$r2->invalid('text'));

my $r3 = FormValidator::Simple->check( $q => [
    text => [qw/NOT_BLANK/,[qw/LENGTH 5 7/]],
] );

ok($r3->invalid('text'));

my $r4 = FormValidator::Simple->check( $q => [
    text => [qw/NOT_BLANK/, [qw/NOT_LENGTH 4/]],
] );

ok($r4->invalid('text'));

my $r5 = FormValidator::Simple->check( $q => [
    text => [qw/NOT_BLANK/,[qw/NOT_LENGTH 2 5/]],
] );

ok($r5->invalid('text'));

my $r6 = FormValidator::Simple->check( $q => [
    text => [qw/NOT_BLANK/,[qw/NOT_LENGTH 5 7/]],
] );

ok(!$r6->invalid('text'));


