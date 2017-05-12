use strict;
use Test::More tests => 13;
use CGI;

BEGIN{ use_ok("FormValidator::Simple") }

my $q = CGI->new;
$q->param( year  => 2005 );
$q->param( month =>   11 );
$q->param( day   =>   25 );
$q->param( hour  =>   12 );
$q->param( min   =>   40 );
$q->param( sec   =>    5 );

my $r = FormValidator::Simple->check( $q => [
    { date => [qw/year month day/] } => [qw/DATE/],
] );

ok(!$r->invalid('date'));

my $r2 = FormValidator::Simple->check( $q => [
    { date => [qw/year month day/] } => [qw/NOT_DATE/],
] );

ok($r2->invalid('date'));

$q->param( month =>  2 );
$q->param( day   => 30 );

my $r3 = FormValidator::Simple->check( $q => [
    { date => [qw/year month day/] } => [qw/DATE/],
] );

ok($r3->invalid('date'));

my $r4 = FormValidator::Simple->check( $q => [
    { date => [qw/year month day/] } => [qw/NOT_DATE/],
] );

ok(!$r4->invalid('date'));

my $r5 = FormValidator::Simple->check( $q => [
    { time => [qw/hour min sec/] } => [qw/TIME/],
] );

ok(!$r5->invalid('time'));

my $r6 = FormValidator::Simple->check( $q => [
    { time => [qw/hour min sec/] } => [qw/NOT_TIME/],
] );

ok($r6->invalid('time'));

$q->param( hour => 25 );

my $r7 = FormValidator::Simple->check( $q => [
    { time => [qw/hour min sec/] } => [qw/TIME/],
] );

ok($r7->invalid('time'));

my $r8 = FormValidator::Simple->check( $q => [
    { time => [qw/hour min sec/] } => [qw/NOT_TIME/]
] );

ok(!$r8->invalid('time'));

my $q2 = CGI->new;
$q2->param( year  => 2005 );
$q2->param( month =>   12 );
$q2->param( day   =>   29 );
$q2->param( hour  =>    5 );
$q2->param( min   =>   22 );
$q2->param( sec   =>   30 );

my $r9 = FormValidator::Simple->check( $q2 => [
    { datetime => [qw/year month day hour min sec/] } => [qw/DATETIME/]
] );

ok(!$r9->invalid('datetime'));

my $r10 = FormValidator::Simple->check( $q2 => [
    { datetime => [qw/year month day hour min sec/] } => [qw/NOT_DATETIME/]
] );

ok($r10->invalid('datetime'));

$q2->param( month => 2  );
$q2->param( day   => 30 );

my $r11 = FormValidator::Simple->check( $q2 => [
    { datetime => [qw/year month day hour min sec/] } => [qw/DATETIME/]
] );

ok($r11->invalid('datetime'));

my $r12 = FormValidator::Simple->check( $q2 => [
    { datetime => [qw/year month day hour min sec/] } => [qw/NOT_DATETIME/],
] );

ok(!$r12->invalid('datetime'));
