use strict;
use Test::More tests => 5;
use CGI;

BEGIN{ use_ok("FormValidator::Simple") }

my $q = CGI->new;
$q->param( text => 'text' );
$q->param( int  => 12345  );

my $r = FormValidator::Simple->check( $q => [
    text => [qw/NOT_BLANK INT/],
    int  => [qw/NOT_BLANK INT/],
] );

ok($r->invalid('text'));
ok(!$r->invalid('int'));

my $r2 = FormValidator::Simple->check( $q => [
    text => [qw/NOT_BLANK NOT_INT/],
    int  => [qw/NOT_BLANK NOT_INT/],
] );

ok(!$r2->invalid('text'));
ok($r2->invalid('int'));
