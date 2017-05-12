use strict;
use Test::More tests => 3;

BEGIN{ use_ok("FormValidator::Simple") }

use CGI;

my $q = CGI->new;
$q->param( foo => 'foo' );
$q->param( bar => 'bar' );
$q->param( buz => '' );

my $r = FormValidator::Simple->check( $q => [ 
  { all1 => [qw/foo bar/] } => ['ALL'],
  { all2 => [qw/bar buz/] } => ['ALL']
] );

ok(!$r->invalid('all1'));
ok($r->invalid('all2'));
