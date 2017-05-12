use strict;
use warnings;
use Test::More tests => 5;
use Log::Handler;

my $CHECKED;

sub check_struct {
    $CHECKED = 1;
    my $message = shift;
    my $value   = '';

    if (ref($message) eq 'HASH') {
        ok(1, "checking hashref");
        $value = $message->{xname};
        ok($value eq 'xvalue', "checking scalar ret value");
        $value = $message->{yname};
        ok($value eq 'yvalue', "checking code ret value");
    } else {
        ok(0, "checking hashref");
    }
}

my $log = Log::Handler->new();

$log->set_pattern('%X', 'xname', 'xvalue');
$log->set_pattern('%Y', 'yname', sub { 'xxxxxx' });

$log->add(
    forward => {
        forward_to      => \&check_struct,
        maxlevel        => 'debug',
        minlevel        => 'debug',
        message_layout  => '%m',
        message_pattern => [ qw/%X %Y/ ],
    }
);

ok(1, 'new');

$log->set_pattern('%Y', 'yname', sub { 'yvalue' });
$log->debug('foo');

ok($CHECKED, "call check_struct()");
