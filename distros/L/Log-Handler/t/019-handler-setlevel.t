use strict;
use warnings;
use Test::More tests => 2;
use Log::Handler;

my $MESSAGE;

sub test {
    $MESSAGE++;
}

ok(1, "use");

my $log = Log::Handler->new();

$log->add(
    forward => {
        alias      => "forward0",
        forward_to => \&test,
        minlevel   => "emerg",
        maxlevel   => "error",
    }
);

$log->add(
    forward => {
        alias      => "forward1",
        forward_to => \&test,
        minlevel   => "emerg",
        maxlevel   => "error",
    }
);

$log->add(
    forward => {
        alias      => "forward2",
        forward_to => \&test,
        minlevel   => "emerg",
        maxlevel   => "error",
    }
);

# should log nothing
$log->notice();

$log->set_level(
    forward1 => {
        minlevel   => "emerg",
        maxlevel   => "debug",
    }
);

# should only forward1 should log
$log->debug();

# disable logging for forward1 and
# enable it for forward0 and forward2
$log->set_level(
    forward0 => {
        minlevel   => "emerg",
        maxlevel   => "debug",
    }
);

$log->set_level(
    forward1 => {
        minlevel   => "emerg",
        maxlevel   => "error",
    }
);

$log->set_level(
    forward2 => {
        minlevel   => "emerg",
        maxlevel   => "debug",
    }
);

# should only log to forward0 and forward2
$log->debug();

ok($MESSAGE == 3, "check set_level($MESSAGE)");
