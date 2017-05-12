use strict;
use warnings;
use Test::More tests => 15;
use Log::Handler;

my $CHECKED = 0;
my %PATTERN = (
    '%L' => 'level',
    '%T' => 'time',
    '%D' => 'date',
    '%P' => 'pid',
    '%H' => 'hostname',
    '%C' => 'caller',
    '%p' => 'package',
    '%f' => 'filename',
    '%l' => 'line',
    '%s' => 'subroutine',
    '%S' => 'progname',
    '%r' => 'runtime',
    '%t' => 'mtime',
    '%m' => 'message',
);

my %PATTERN_REC = map { $_ => 0 } values %PATTERN;

sub check_struct {
    my $m = shift;
    foreach my $name (keys %$m) {
        if (exists $PATTERN_REC{$name}) {
            $PATTERN_REC{$name}++;
        }
    }
}

my $log = Log::Handler->new();

$log->add(
    forward => {
        forward_to      => \&check_struct,
        maxlevel        => 'debug',
        minlevel        => 'debug',
        message_layout  => '',
        message_pattern => [ keys %PATTERN ],
    }
);

ok(1, 'new');

$log->debug('foo');

while ( my ($n, $v) = each %PATTERN_REC ) {
    ok($v, "test pattern $n");
}
