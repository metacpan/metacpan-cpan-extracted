use strict;
use Test::More tests => 4;

BEGIN{ use_ok("FormValidator::Simple") }

use CGI;

my $q = CGI->new;
$q->param( foo => 'foo' );
$q->param( bar => 'bar' );
$q->param( buz => 0 );

my $r = FormValidator::Simple->check( $q => [ 
    foo => [ [qw/IN_ARRAY foo bar buz/] ],
    bar => [ [qw/IN_ARRAY foo buz/] ],
    buz => [ [qw/IN_ARRAY 0 1/] ],
] );

ok(!$r->invalid('foo'));
ok($r->invalid('bar'));
ok(!$r->invalid('buz'));
