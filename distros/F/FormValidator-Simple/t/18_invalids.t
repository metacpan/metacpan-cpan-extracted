use strict;
use Test::More tests => 16;
use CGI;

BEGIN{ use_ok("FormValidator::Simple") }

my $q = CGI->new;

$q->param( hoge  => 'test' );
$q->param( hoge2 => 'test' );
$q->param( hoge3 => ''     );

my $r = FormValidator::Simple->check( $q => [
    hoge  => [ [qw/LENGTH 10/], [qw/INT/], [qw/NOT_ASCII/] ],
    hoge2 => [ [qw/LENGTH 10/] ],
    hoge3 => [ 'NOT_BLANK' ],
] );

my $invalids = $r->invalid('hoge');
is(scalar(@$invalids), 3);
is($invalids->[0], 'LENGTH');
is($invalids->[1], 'INT');
is($invalids->[2], 'NOT_ASCII');

my @errors = $r->error;
is($errors[0], 'hoge');
is($errors[1], 'hoge2');
is($errors[2], 'hoge3');

my @inv = $r->invalid;
is($inv[0], 'hoge');
is($inv[1], 'hoge2');
my @mis = $r->missing;
is($mis[0], 'hoge3');


my $hoge_errors = $r->error('hoge');
is($hoge_errors->[0], 'LENGTH');
is($hoge_errors->[1], 'INT');
is($hoge_errors->[2], 'NOT_ASCII');

my $hoge_errors2 = $r->error('hoge3');
is($hoge_errors2->[0], 'NOT_BLANK');

ok($r->error( hoge3 => 'NOT_BLANK'));
