use strict;
use warnings;

use Data::Dumper;
use Logging::Simple;
use Test::More;

my $mod = 'Logging::Simple';

{ # entire list
    my $log = Logging::Simple->new;

    my %h = $log->display;
    is (keys %h, 5, "display() with no params returns the correct hash");

    for (qw(name pid label time proc)){
        if ($_ eq 'proc' || $_ eq 'pid'){
            is ($h{$_}, 0, "$_ defaults to disabled");
        }
        else {
            is ($h{$_}, 1, "$_ defaults to enabled");
        }
    }
}
{ # all
    my $log = Logging::Simple->new;
    is ($log->display(1), 1, "display() returns true with '1' param");
}
{ # get single
    my $log = Logging::Simple->new;

    my %ret = $log->display(pid => 0, label => 0, time => 0, proc => 0);

    for (qw(pid label time proc)){
        is ($log->display($_), 0, "disabling $_ tag works");
        is ($ret{$_}, 0, "and full return works for $_");
        $log->display($_ => 1);
        is ($log->display($_), 1, "so does re-enabling $_");
    }
}
{ # invalid display tag
    my $log = Logging::Simple->new;

    my $warn;
    local $SIG{__WARN__} = sub { $warn = shift; };

    my $ret = $log->display(blah => 1);
    like ($warn, qr/blah is an invalid tag/, "invalid tags get squashed");
}
{ # display => none in new() param
    my $log = $mod->new(display => 0);

    my %display = $log->display;

    for (keys %display){
        is ($display{$_}, 0, "display setting $_ is disabled due to '0' param");
    }
}
{ # display() with 0 and all
    my $log = $mod->new;

    $log->display(0);
    my %display = $log->display;

    for (keys %display){
        is ($display{$_}, 0, "display setting $_ is disabled due to '0'");
    }

    $log->display(1);
    %display = $log->display;

    for (keys %display){
        is ($display{$_}, 1, "display setting $_ is enabled due to '1'");
    }
}
{ # custom_display()
    my $log = $mod->new(print => 0);

    $log->display(0);

    $log->custom_display("--");

    my $msg = $log->_0("testing");
    is ($msg, "-- testing\n", "custom_display() does the right thing by itself");

    $log->display(1);

    $msg = $log->_0("testing");

    like ($msg, qr/--\[/, "cust display with all others ok");

    $log->custom_display(0);

    $msg = $log->_0("testing");

    like ($msg, qr/\[/, "disabling custom display works");
}
done_testing();
