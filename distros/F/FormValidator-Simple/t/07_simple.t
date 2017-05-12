use strict;
use Test::More tests => 24;
use CGI;

BEGIN { use_ok("FormValidator::Simple"); }

my $q = CGI->new;
$q->param(text1 => 'HOGEHOGE'           );
$q->param(text2 => 'HOGEHOGEHOGE'       );
$q->param(int   => 7                    );
$q->param(blank => ""                   );
$q->param(email => 'lyo.kato@gmail.com' );

my $results = FormValidator::Simple->check( $q, [
    text1 => [qw/NOT_BLANK/],
    text2 => [qw/NOT_BLANK/],
    int   => [qw/INT/],
    blank => [qw/NOT_BLANK/],
    email => [qw/EMAIL_LOOSE/],
] );

isa_ok( $results, "FormValidator::Simple::Results" );
ok($results->missing('blank'));
ok(!$results->valid('blank'));
ok(!$results->invalid('blank'));
ok($results->has_missing);
ok(!$results->has_invalid);
is($results->valid('text1'), 'HOGEHOGE'          );
is($results->valid('int'),   7                   );
is($results->valid('email'), 'lyo.kato@gmail.com');
ok(!$results->invalid('text1'));
ok(!$results->invalid('int'));
ok(!$results->invalid('email'));
ok(!$results->missing('text1'));
ok(!$results->missing('int'));
ok(!$results->missing('email'));

my @missings = $results->missing;
my @invalids = $results->invalid;
my $valids   = $results->valid;

is(scalar(@missings), 1);
is(scalar(@invalids), 0);
is(scalar(keys %$valids),   4);

my $valid = FormValidator::Simple->new;

$valid->check( $q => [
    text1 => [qw/NOT_BLANK ASCII/],
] );

$valid->check( $q => [
    text2 => [qw/NOT_BLANK NOT_ASCII/],
] );

my $results2 = $valid->results;

ok(!$results2->invalid('text1'));
ok($results2->invalid('text2'));

$valid->set_invalid( hoge => 'HOGE' );

my $results3 = $valid->results;

ok($results3->invalid('hoge'));
ok($results3->invalid( hoge => 'HOGE' ));

# make sure check doesn't eat the profile
my $profile = [
  text => [qw/NOT_BLANK INT/],
  int  => [qw/NOT_BLANK INT/],
];

my $r3 = FormValidator::Simple->check( $q => $profile );
is_deeply( $profile, [
  text => [qw/NOT_BLANK INT/],
  int  => [qw/NOT_BLANK INT/],
] );

