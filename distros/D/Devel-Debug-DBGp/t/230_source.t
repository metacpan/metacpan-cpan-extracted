#!/usr/bin/perl

use t::lib::Test;

my ($eval_start, $eval_end) = (12, 16);

run_debugger('t/scripts/source.pl');

send_command('run');

command_is(['source'], {
    success => 1,
    source  => _read_file('t/scripts/source.pl', 1, 10000),
});

command_is(['source', '-f', 'file://t/scripts/source.pl'], {
    success => 1,
    source  => _read_file('t/scripts/source.pl', 1, 10000),
});

command_is(['source', '-f', abs_path('t/scripts/source.pl')], {
    success => 1,
    source  => _read_file('t/scripts/source.pl', 1, 10000),
});

command_is(['source', '-f', abs_uri('t/scripts/source.pl')], {
    success => 1,
    source  => _read_file('t/scripts/source.pl', 1, 10000),
});

command_is(['source', '-f', 't/scripts/source.pl'], {
    success => 1,
    source  => _read_file('t/scripts/source.pl', 1, 10000),
});

command_is(['source', '-b', 10], {
    success => 1,
    source  => _read_file('t/scripts/source.pl', 10, 10000),
});

command_is(['source', '-b', 11, '-e', 15], {
    success => 1,
    source  => _read_file('t/scripts/source.pl', 11, 15),
});

send_command('run');

my $current_stack = send_command('stack_get');

command_is(['source'], {
    success => 1,
    source  => _read_file('t/scripts/source.pl', $eval_start, $eval_end) . "\n;",
});

command_is(['source', '-f', $current_stack->frames->[0]->filename], {
    success => 1,
    source  => _read_file('t/scripts/source.pl', $eval_start, $eval_end) . "\n;",
});

command_is(['source', '-f', $current_stack->frames->[0]->filename, '-b', 2, '-e', 3], {
    success => 1,
    source  => _read_file('t/scripts/source.pl', $eval_start + 1, $eval_start + 2),
});

done_testing();

sub _read_file {
    my ($file, $from, $to) = @_;
    open my $fh, '<', $file or die "Error opening '$file': $!";
    my @lines = readline $fh;

    return _mangle_pod(@lines[($from - 1)
                       ..
                       ($to >= @lines ? @lines - 1 : $to - 1)]);
}

sub _mangle_pod {
    return join '', @_ if $] >= 5.012;
    my ($started, $first_line) = (0, 0);
    for my $line (@_) {
        if ($started && $line eq "=cut\n") {
            $started = $first_line = 0;
        } elsif ($first_line) {
            $line = "<pod dropped>\n";
            $first_line = 0;
        } elsif ($started) {
            $line = "?\n";
        } elsif ($line =~ /^=\w/) {
            $started = $first_line = 1;
        }
    }
    return join '', @_;
}
