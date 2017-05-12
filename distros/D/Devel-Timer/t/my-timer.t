use strict;
use warnings;
use Test::More;
my $tests;
plan tests => $tests;


use lib 'eg';
use_ok('MyTimer');
BEGIN { $tests += 1; }


{
    close STDERR;
    my $stderr = '';
    open STDERR, '>', \$stderr or die;

    unlink 'timer.log';

    my $t = MyTimer->new;
    isa_ok($t, 'MyTimer');

    $t->mark("first db query");
    $t->mark("second db query");
    $t->mark("END");

    $t->report;
    $t->shutdown;
    is ($stderr, '');

    ok(-e 'timer.log');

    my $log = slurp('timer.log');
    like($log, qr/Total time/);
    like($log, qr/first db query/);
    like($log, qr/second db query/);
    like($log, qr/second db query -> END/);
    
    BEGIN { $tests += 7; }
}

sub slurp {
    my ($file) = @_;
    open my $fh, '<', $file or die;
    local $/ = undef;
    return <$fh>;
}

