use strict;
use Test::More tests => 5;
use CGI;

use lib 't/lib';

BEGIN { require_ok("FormValidator::Simple") } 

FormValidator::Simple->import(qw/Sample +MyNamespace::MyPlugin/);

my $q = CGI->new;
$q->param( sample1 => 'hogehoge' );
$q->param( sample2 => 'sample'   );

$q->param( myplugin1 => 'hogehoge' );
$q->param( myplugin2 => 'myplugin' );

my $r = FormValidator::Simple->check( $q => [
    sample1   => [qw/SAMPLE/],
    sample2   => [qw/SAMPLE/],
    myplugin1 => [qw/MYPLUGIN/],
    myplugin2 => [qw/MYPLUGIN/],
] );

ok($r->invalid('sample1'));
ok(!$r->invalid('sample2'));

ok($r->invalid('myplugin1'));
ok(!$r->invalid('myplugin2'));
