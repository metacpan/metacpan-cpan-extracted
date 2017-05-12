use strict;
use Test::More tests => 5;
use CGI;

BEGIN{ use_ok("FormValidator::Simple") }

my $q = CGI->new;
$q->param( param1 => 'text' );
$q->param( param2 => ' '    );

my $r = FormValidator::Simple->check( $q => [
    param1 => [qw/NOT_BLANK SP/],
    param2 => [qw/NOT_BLANK SP/],
] );

ok($r->invalid('param1'));
ok(!$r->invalid('param2'));

my $r2 = FormValidator::Simple->check( $q => [
    param1 => [qw/NOT_BLANK NOT_SP/],
    param2 => [qw/NOT_BLANK NOT_SP/],
] );

ok(!$r2->invalid('param1'));
ok($r2->invalid('param2'));
