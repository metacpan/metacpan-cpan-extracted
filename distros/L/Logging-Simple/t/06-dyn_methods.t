#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Logging::Simple;
use Test::More;

my @nums = qw(_0 _1 _2 _3 _4 _5 _6 _7);

{ # test num methods
    my $log = Logging::Simple->new(print => 0, name => 'Logging::Simple');

    my @msgs;

    for (@nums){
        /^_(\d)$/;
        my $lvl = $log->levels($1);

        my $msg = $log->$_($_);
        if ($msg) {
            like ( $msg, qr/\[$lvl\]\[.*?\] $_/, "$_ has proper msg" );
        }
        push @msgs, $msg if $msg;
    }

    is (@msgs, 5, "with default level, nums has proper msg count");
}
{ # dyn methods reset level from ENV
    my $log = Logging::Simple->new(print => 0, name => 'Logging::Simple');

    my $subs = $log->_sub_names;

    for my $sub (@$subs){
        $sub =~ /_(\d)/;
        my $lvl = $1;
        $ENV{LS_LEVEL} = $lvl;
        my $msg = $log->$sub('env test');
        is ($log->level, $lvl, "$lvl has reset level to $lvl with LS_LEVEL env");
        like ($msg, qr/env test/, "...and msg is ok");
    }
}
done_testing();
__END__
{ # output with disabled display() in new()
    my $log = Logging::Simple->new(print => 0, display => 0);

    my $subs = $log->_sub_names;

    for (@$subs){
        my $lvl = $log->_level_value($_);
        my $msg = $log->$_('env test');
        $log->level($lvl);
        is ($msg, "env test\n", "with new(display => 0), $_ message is ok");
    }
}
{ # output with enabled display() in new()
    my $log = Logging::Simple->new(print => 0, display => 1, name => 'Logging::Simple');

    my $subs = $log->_sub_names;

    for (@$subs){
        my $lvl = $log->_level_value($_);
        my $msg = $log->$_('env test');
        $log->level($lvl);

        like (
            $msg,
            qr/(?:\[.*?\]){4} env test/,
            "with new(display => 1), $_ message is ok"
        );
    }
}
{ # output with display(0)
    my $log = Logging::Simple->new(print => 0, name => 'Logging::Simple');

    $log->display(0);
    my $subs = $log->_sub_names;

    for (@$subs){
        my $lvl = $log->_level_value($_);
        my $msg = $log->$_('env test');
        $log->level($lvl);
        is ($msg, "env test\n", "with display(0), $_ message is ok");
    }
}
{ # output with display(1)
    my $log = Logging::Simple->new(print => 0, name => 'Logging::Simple');

    $log->display(1);
    my $subs = $log->_sub_names;

    for (@$subs){
        my $lvl = $log->_level_value($_);
        my $msg = $log->$_('env test');
        $log->level($lvl);

        like (
            $msg,
            qr/(?:\[.*?\]){5} env test/,
            "with display(1), $_ message is ok"
        );
    }
}
done_testing();

