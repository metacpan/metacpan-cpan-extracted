use strict;
use warnings;
use Test::More tests => 14;
use Log::Handler;

my %config = (
    file => {
        default => {
            timeformat     => '%b %d %H:%M:%S',
            mode           => 'excl',
            message_layout => '%T %H[%P] [%L] %S: %m',
            debug_mode     => 2,
            fileopen       => 0,
        },
        file1 => {
            filename => 'foo',
            maxlevel => 'info',
            newline  => 0,
            priority => 1,
        }
    },
    screen => [
        {
            alias    => 'screen1',
            dump     => 1,
            priority => 2,
            maxlevel => 'info',
        },
        {
            alias    => 'screen2',
            dump     => 0,
            newline  => 0,
            priority => 3,
            maxlevel => 'info',
        }
    ]
);

my $log = Log::Handler->new();
$log->config(config => \%config);

my %opts;
$opts{handler}{file1}   = shift @{$log->{levels}->{INFO}};
$opts{handler}{screen1} = shift @{$log->{levels}->{INFO}};
$opts{handler}{screen2} = shift @{$log->{levels}->{INFO}};
$opts{output}{file1}    = $log->output('file1');
$opts{output}{screen1}  = $log->output('screen1');
$opts{output}{screen2}  = $log->output('screen2');

my %cmp = (
    output => {
        file1 => {
            filename => 'foo',
            fileopen => 0,
        },
        screen1 => {
            dump => 1,
        },
        screen2 => {
            dump => 0,
        }
    },
    handler => {
        file1 => {
            newline         => 0,
            timeformat      => '%b %d %H:%M:%S',
            message_layout  => '%T %H[%P] [%L] %S: %m',
            debug_mode      => 2,
            maxlevel        => 6,
        },
        screen1 => {
            priority => 2,
            maxlevel => 6,
        },
        screen2 => {
            newline  => 0,
            priority => 3,
            maxlevel => 6,
        }
    }
);

foreach my $x (qw/handler output/) {
    foreach my $y (qw/file1 screen1 screen2/) {
        foreach my $k (keys %{$cmp{$x}{$y}}) {
            my $cmp_val = $cmp{$x}{$y}{$k};
            my $opt_val = defined $opts{$x}{$y}{$k} ? $opts{$x}{$y}{$k} : 'n/a';
            ok($cmp_val eq $opt_val, "checking config $x:$y:$k ($cmp_val:$opt_val)");
        }
    }
}
