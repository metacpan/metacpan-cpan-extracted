use strict;
use warnings;
use Test::More tests => 1;
use Log::Handler;

my $ALIAS_CHECK = 0;

sub alias_check {
    if ($_[0] =~ /foo/) {
        $ALIAS_CHECK++
    }
}

my $log = Log::Handler->new();

$log->add(
    forward => {
        forward_to => \&alias_check,
        alias => 'test',
    }
);

$log->output('test')->log('foo');
ok($ALIAS_CHECK, "checking alias");
