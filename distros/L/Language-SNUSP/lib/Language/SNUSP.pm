use strict; use warnings;
package Language::SNUSP;
our $VERSION = '0.0.15';

my $input = '';     # SNUSP input
my $code = '';      # 2D code matrix
my $width = 1;      # 2D code width
my $pos = 0;        # 2D code execution pointer
my $max = 0;        # Maximum pos value (length of code)
my $dir = 1;        # Execution direction:
                    #   1=right -1=left $width=down -$width=up
my @args = ();      # Program input list
my @data = (0);     # Data slots
my $index = 0;      # Data slot index
my @stack = ();     # Subroutine call stack
my $count = 0;      # Execution counter

# I/O handlers
my $put = sub { print shift };
my $get = sub { substr shift(@args), 0, 1 };

# SNUSP opcode handler lookup table.
my %ops = (
    '>'  => sub { $data[++$index] ||= 0 },
    '<'  => sub { --$index >= 0 or $dir = 0 },
    '+'  => sub { ++$data[$index] },
    '-'  => sub { --$data[$index] },
    ','  => sub { $data[$index] = ord $get->() },
    '.'  => sub { $put->(chr $data[$index]) },
    '/'  => sub { $dir = -$width / $dir },
    '\\' => sub { $dir = $width / $dir },
    '!'  => sub { $pos += $dir },
    '?'  => sub { $pos += $dir if $data[$index] == 0 },
    '@'  => sub { push @stack, [ $pos + $dir, $dir ] },
    '#'  => sub { @stack ? ($pos, $dir) = @{pop @stack} : $dir = 0 },
    "\n" => sub { $dir = 0 },
);

# Runtime flags
my $file;           # Input SNUSP file
my $trace = 0;      # Run with trace execution
my $debug = 0;      # Run with 2D Curses debugger

sub run {
    my ($class, @args) = @_;
    $class->get_options(@args);

    open my $fh, '<', $file or die "Can't open '$file' for input.\n";
    $input = do { local $/; <$fh> };
    close $fh;

    for ($input =~ /^.*\n/gm) {
        $code .= $_;
        $width = length if length > $width;
    }
    $code =~ s/^.*/$& . ' ' x ($width - length $&) . "\n"/gem;
    $max = length($code) - 1;
    $width += 2;
    $pos = $code =~ /\$/ * $-[0];

    $trace ? run_trace() :
    $debug ? run_debug() :
             run_normal();

    exit $data[$index];
}

sub run_normal {
    while ($dir) {
        if (my $op = $ops{substr $code, $pos, 1}) { &$op }
        $pos += $dir;
        last if $pos < 0 or $pos > $max;
    }
}

sub run_trace {
    while ($dir) {
        my $char = substr $code, $pos, 1;
        $count++;
        print trace_line() . "\n";
        if (my $op = $ops{$char}) { &$op }
        $pos += $dir;
        last if $pos < 0 or $pos > $max;
        print "\n" if $char eq '.';
    }
}

sub run_debug {
    require Curses; Curses->import;
    require Term::ReadKey; Term::ReadKey->import;

    initscr();
    ReadMode(3);

    my $y = 0;
    addstr(
        $y++, 0,
        "(n)ext (SPACE)stop/start (+)faster (-)slower (q)uit",
    );
    my $top = ++$y;
    addstr($y++, 0, $&) while $code =~ /.+/g;

    my $key = '';
    my $sleep = 0.1;
    my $pause = 1;

    my $out = '';
    $put = sub { $out .= shift };

    while(1) {
        if ($dir and (not $pause or $key eq "n")) {
            $count++;
            if (my $op = $ops{substr $code, $pos, 1}) { &$op }
            last if $pos < 0 or $pos > $max;
            $pos += $dir;
            $pause = 1 if $dir == 0;
        }

        {
            addstr($top - 1, 0, trace_line());
            addstr($y, 0, $out);
            clrtoeol();
            move(int($pos / $width) + $top, $pos % $width);
            refresh();
        }

        no warnings 'uninitialized';
        $key = ReadKey($pause ? 0 : $sleep);
        if ($key =~ /^[\+\=]$/) {$sleep -= 0.01 if $sleep > 0.011}
        elsif ($key eq '-') {$sleep += 0.01}
        elsif ($key eq ' ') {$pause = not $pause}
        elsif ($key eq 'n') {$pause = 1}
        elsif ($key eq 'q') {last}
    }
    ReadMode(0);
    endwin();
}

sub trace_line {
    my $n = 0;
    my $display = join '', map {
        $n++ == $index ? "[$_] " : "$_ "
    } @data;
    return "$count)  \@${\scalar @stack}  < $display>";
}

sub get_options {
    my ($class, @options) = @_;

    for my $option (@options) {
        if ($option =~ /^(-v|--version)$/) {
            no strict 'refs';
            print qq!Language::SNUSP v${"VERSION"}!;
            exit 0;
        }
        if ($option =~ /^(-\?|-h|--help)$/) {
            die usage();
            exit 0;
        }
        if ($option =~ /^(-d|--debug)$/) {
            $debug = 1;
            next;
        }
        if ($option =~ /^(-t|--trace)$/) {
            $trace = 1;
            next;
        }
        if ($option =~ /^-/) {
            die "Unknown option: '$option'\n\n" . usage();
        }
        if ($file) {
            push @args, $option;
            next;
        }
        if (-f $option) {
            $file = $option;
        }
        else {
            die "Input file '$option' does not exist.\n";
        }
    }
    die usage() if not $file;
}

sub usage {
    <<'...';
Usage:
    snusp [options] input_file.snusp

Options:
    -d, --debug     # Run program in the visual debugger
    -t, --trace     # Run with trace on
    -v, --version   # Print version and exit
    -h, --help      # Print help and exit
...
}

1;
