use strict;
use Test::More tests => 5;
use CGI;

BEGIN{ use_ok("FormValidator::Simple") }

my $q = CGI->new;
$q->param( hoge => 1  );
$q->param( foo  => '' );
$q->param( bar  => '' );

my $r = FormValidator::Simple->check( $q => [
    { any => [qw/hoge foo bar/] } => [qw/ANY/],
] );

ok(!$r->invalid('any'));

my $r2 = FormValidator::Simple->check( $q => [
    { any => [qw/hoge foo bar/] } => [qw/NOT_ANY/],
] );

ok($r2->invalid('any'));

$q->param( hoge => '' );

my $r3 = FormValidator::Simple->check( $q => [
    { any => [qw/hoge foo bar/] } => [qw/ANY/]
] );

ok($r3->invalid('any'));

my $r4 = FormValidator::Simple->check( $q => [
    { any => [qw/hoge foo bar/] } => [qw/NOT_ANY/]
] );

ok(!$r4->invalid('any'));
