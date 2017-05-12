use strict;
use Test::More tests => 5;
use CGI;

BEGIN { use_ok("FormValidator::Simple") }

my $q = CGI->new;
$q->param( email1 => 'lyo.kato@gmail.com' );
$q->param( email2 => 'lyo.kato@gmail.com' );

my $r = FormValidator::Simple->check( $q => [
    email1 => [qw/NOT_BLANK EMAIL_LOOSE/],
    email2 => [qw/NOT_BLANK EMAIL_LOOSE/],
    { email_dup => [qw/email1 email2/] } => [qw/DUPLICATION/],
] );

ok(!$r->invalid('email_dup'));

my $r2 = FormValidator::Simple->check( $q => [
    { email_dup => [qw/email1 email2/] } => [qw/NOT_DUPLICATION/],
] );

ok($r2->invalid('email_dup'));

$q->param( email2 => 'lyokato@gmail.com' );

my $r3 = FormValidator::Simple->check( $q => [
    { email_dup => [qw/email1 email2/] } => [qw/DUPLICATION/],
] );

ok($r3->invalid('email_dup'));

my $r4 = FormValidator::Simple->check( $q => [
    { email_dup => [qw/email1 email2/] } => [qw/NOT_DUPLICATION/],
] );

ok(!$r4->invalid('email_dup'));
