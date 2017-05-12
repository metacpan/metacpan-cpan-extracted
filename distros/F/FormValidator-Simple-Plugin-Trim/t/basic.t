use strict;
use warnings;

use CGI;
use Test::More tests => 5;

BEGIN { use_ok( 'FormValidator::Simple', 'Trim' ) };

my $q = CGI->new;
$q->param('int_param', ' 123 ');
$q->param('collapse', "  \n a \r\n b\nc  \t");
$q->param('left', ' abc ');

my $results = FormValidator::Simple->check( $q, [

  int_param => ['TRIM', 'NOT_BLANK', 'INT' ],
  collapse  => ['TRIM_COLLAPSE'],
  left      => ['TRIM_LEAD'],
] );

use Data::Dumper;
$Data::Dumper::Indent = 1;
ok($results->success, 'processed okay') or diag Dumper($results);
is($results->valid('int_param'), 123, 'trim');
is($results->valid('left'), "abc ", 'trim leading');
is($results->valid('collapse'), "a b c", 'trim collapse');
