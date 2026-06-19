#!/usr/bin/env perl
use strict;
use warnings;
use 5.014;

use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib", "lib";
use JSON::JSONFold ;

use Getopt::Long qw(GetOptionsFromArray);
use Time::HiRes qw(time clock_gettime CLOCK_PROCESS_CPUTIME_ID);
use Scalar::Util qw(looks_like_number);

# Prefer a fast JSON encoder when available, but fall back to core JSON::PP.
our $REPEATS = 3;
use constant MEM_FRACTION => 0.10;

use Carp qw(confess cluck);

BEGIN {
    $SIG{__DIE__} = sub {
        return if $^S;
        local $SIG{__DIE__};
        Carp::confess(@_);
    };


    $SIG{__WARN__} = sub {
        local $SIG{__WARN__};
#        Carp::cluck(@_);
    };
}

# ----------------------------------------------------------------------
# NullWriter: file-like sink used by both the base encoder and JSONFold.
# ----------------------------------------------------------------------
{
    package NullWriter;
    use Time::HiRes qw(time);

    sub new {
        my ($class, %args) = @_;
        return bless {
            t0          => $args{t0} // time(),
            first_write => undef,
            bytes       => 0,
            writes      => 0,
            data        => '',
            capture     => 0,
        }, $class;

    }

    sub capture {
        my ($self, $enabled) = @_;
        $self->{capture} = $enabled ? 1 : 0;
        return $self;
    }

    # Normal Perl filehandle-ish method.
    sub print {
        my ($self, $s) = @_;
        $s = '' unless defined $s;
        $self->{first_write} //= time();
        $self->{bytes}  += length($s);
        $self->{writes} += 1;
        $self->{data}   .= $s if $self->{capture};
        return length($s);
    }

    sub ttfb_ms {
        my ($self) = @_;
        return '' unless defined $self->{first_write};
        return round1(($self->{first_write} - $self->{t0}) * 1000.0);
    }

    sub bytes  { $_[0]->{bytes} }
    sub writes { $_[0]->{writes} }
    sub data   { $_[0]->{data} }

    sub round1 {
        my ($x) = @_;
        return int($x * 10 + 0.5) / 10;
    }
}

# ----------------------------------------------------------------------
# Data generation: same structure as benchmark.py.
# ----------------------------------------------------------------------
sub make_data {
    my ($rows) = @_;

    return {
        meta     => { version => 1, ok => JSON::PP::true, name => 'jsonfold benchmark' },
        long_ids => [ 0 .. 99 ],
        long_obj => { map { ("k$_" => $_) } 0 .. 49 },
        rows     => [
            map {
                my $i = $_;
                +{
                    id     => $i,
                    name   => "name_$i",
                    active => ($i % 3 == 0 ? JSON::PP::true : JSON::PP::false),
                    score  => $i * 1.25,
                    tags   => [qw(alpha beta gamma delta)],
                    pos    => { x => $i, y => $i + 1, z => $i + 2 },
                    values => [ $i, $i + 1, $i + 2, $i + 3, $i + 4 ],
                    pairs  => [ [ $i, $i + 1, [ $i + 2, $i + 3 ], [ $i + 4, $i + 5 ] ] ],
                }
            } 0 .. ($rows - 1)
        ],
    };
}

sub mem_label { 'kb' }
sub mem_units { round1($_[0] / 1024.0) }
sub round1    { int($_[0] * 10 + 0.5) / 10 }

sub json_plain_encoder {
    return JSON::PP->new->allow_nonref;
}

sub json_pretty_encoder {
    # JSON::PP / JSON::MaybeXS use indent + space_before/after for readable
    # pretty output. This is close to Python json.dumps(..., indent=2).
    return JSON::PP->new
        ->allow_nonref
        ->pretty
        ->indent_length(2);
}

# ----------------------------------------------------------------------
# Case dispatch: same names as benchmark.py.
# ----------------------------------------------------------------------
sub run_case {
    my ($data, $name, $show) = @_;

    if ($name eq 'base.dumps.plain') {
        return sub { write_string(json_plain_encoder()->encode($data), $show) };
    }
    if ($name eq 'base.dumps.pretty') {
        return sub { write_string(json_pretty_encoder()->encode($data), $show) };
    }
    if ($name eq 'base.dump.pretty') {
        return sub { run_json_dump($data, $show) };
    }
    if ($name eq 'base.dump.plain') {
        return sub { run_json_dump_plain($data, $show) };
    }

    my ($kind, $func, $compact) = split /\./, $name;

    if (defined($kind) && $kind eq 'jsonfold') {
        if (defined($func) && $func eq 'dumps') {
            return sub {
                run_jsonfold_dumps($data, $compact, $show);
            };
        }
        if (defined($func) && $func eq 'dump') {
            return sub { run_jsonfold_dump($data, $compact, $show) };
        }
    }

    die "unknown benchmark case: $name\n";
}

sub write_string {
    my ($s, $show) = @_;
    my $w = NullWriter->new()->capture($show);
    $w->print($s);
    print STDOUT $w->data if $show;
    return $w;
}

sub run_json_dump {
    my ($data, $show) = @_;
    my $w = NullWriter->new()->capture($show);
    # Perl JSON encoders return a string; count this as one write, matching
    # the dumps path. JSONFold::dump, below, may stream multiple writes.
    $w->print(json_pretty_encoder()->encode($data));
    print STDOUT $w->data if $show;
    return $w;
}

sub run_json_dump_plain {
    my ($data, $show) = @_;
    my $w = NullWriter->new()->capture($show);
    $w->print(json_plain_encoder()->encode($data));
    print STDOUT $w->data if $show;
    return $w;
}

sub run_jsonfold_dumps {
    my ($data, $compact, $show) = @_;

    my $w = NullWriter->new()->capture($show);
    JSON::JSONFold::write_json($data, $w, undef, $compact) ;
    print STDOUT $w->data if $show;
    return $w ;
}

sub run_jsonfold_dump {
    my ($data, $compact, $show) = @_;
    my $w = NullWriter->new()->capture($show);

    JSON::JSONFold::write_json($data, $w, undef, $compact);

    print STDOUT $w->data if $show;
    return $w;
}

# ----------------------------------------------------------------------
# Timing and memory.
# ----------------------------------------------------------------------
sub time_one {
    my ($name, $data, $show) = @_;
    my ($best, $best_dt);


    for (1 .. $REPEATS) {
        gc_collect();

        my $t0 = time();
        my $p0 = process_time();
        my $w  = run_case($data, $name, $show && $_ == 1)->();
        my $p1 = process_time();
        my $t1 = time();
        my $dt = $t1 - $t0;

        my $row = {
            'time(ms)'      => round1($dt * 1000.0),
            'CPU(ms)'       => round1(($p1 - $p0) * 1000.0),
            'ttfb(ms)'      => $w->ttfb_ms,
            'out(' . mem_label() . ')' => mem_units($w->bytes),
            writes          => $w->writes,
        };

        if (!defined($best) || $dt < $best_dt) {
            $best    = $row;
            $best_dt = $dt;
        }
    }

    return ($best_dt, $best);
}

sub memory_one {
    my ($name, $data) = @_;

    gc_collect();

    my $before = current_rss_bytes();
    my $t0 = time();
    run_case($data, $name, 0)->($t0);
    my $after = current_rss_bytes();

    # Perl does not have a core equivalent of Python tracemalloc. RSS delta is
    # the best no-dependency approximation; clamp at zero because memory arenas
    # may be reused between cases.
    my $delta = $after - $before;
    $delta = 0 if $delta < 0;
    return mem_units($delta);
}

sub process_time {
    return clock_gettime(CLOCK_PROCESS_CPUTIME_ID);
}

sub gc_collect {
    # Perl's refcounting frees most data immediately. This hook exists to keep
    # the same benchmark flow as Python's gc.collect().
    return 1;
}

sub current_rss_bytes {
    # Linux: field 2 of /proc/self/statm is resident pages.
    if (open my $fh, '<', '/proc/self/statm') {
        my $line = <$fh> // '';
        close $fh;
        my @f = split /\s+/, $line;
        if (defined $f[1] && $f[1] =~ /^\d+$/) {
            my $page = eval { require POSIX; POSIX::sysconf(POSIX::_SC_PAGESIZE()) } || 4096;
            return $f[1] * $page;
        }
    }
    return 0;
}

# ----------------------------------------------------------------------
# Table printer: same style as benchmark.py.
# ----------------------------------------------------------------------
sub print_table {
    my ($rows) = @_;
    return unless @$rows;

    my @cols = @{ $rows->[0]{_cols} // [ grep { $_ ne '_cols' } keys %{ $rows->[0] } ] };
    my %width;

    for my $c (@cols) {
        my $w = length($c);
        for my $r (@$rows) {
            my $v = defined $r->{$c} ? $r->{$c} : '';
            my $len = length("$v");
            $w = $len if $len > $w;
        }
        $width{$c} = $w;
    }

    my %numeric;
    for my $c (@cols) {
        $numeric{$c} = 1;
        for my $r (@$rows) {
            my $v = defined $r->{$c} ? $r->{$c} : '';
            next if $v eq '';
            if (!looks_like_number($v)) {
                $numeric{$c} = 0;
                last;
            }
        }
    }

    my $line = '+' . join('+', map { '-' x ($width{$_} + 2) } @cols) . '+';

    print "$line\n";
    print '|' . join('|', map { cell($_, $_, \%width, \%numeric) } @cols) . "|\n";
    print "$line\n";
    for my $r (@$rows) {
        print '|' . join('|', map { cell($_, $r->{$_}, \%width, \%numeric) } @cols) . "|\n";
    }
    print "$line\n";
}

sub cell {
    my ($c, $v, $width, $numeric) = @_;
    $v = '' unless defined $v;
    my $s = "$v";
    return ' ' . ($numeric->{$c} ? sprintf("%*s", $width->{$c}, $s)
                                : sprintf("%-*s", $width->{$c}, $s)) . ' ';
}

sub default_tests {
    return qw(
        base.dump.plain
        base.dump.pretty
        jsonfold.dump.off
        jsonfold.dump.none
        jsonfold.dump.default
        jsonfold.dump.low
        jsonfold.dump.med
        jsonfold.dump.high
        jsonfold.dump.max
        jsonfold.dump.pack
        jsonfold.dump.fold
        jsonfold.dump.join
        base.dumps.plain
        base.dumps.pretty
        jsonfold.dumps.none
        jsonfold.dumps.default
        jsonfold.dumps.high
        jsonfold.dumps.max
    );
}

sub run_one_size {
    my ($rows, $tests, $show) = @_;
    my $data = make_data($rows);

    my @tests = @$tests ? @$tests : default_tests();
    my @results;

    for my $name (@tests) {
        print STDERR "$name ($rows)... ";

        my $t0 = time ;
        my ($best_dt, $speed) = time_one($name, $data, $show);
        my $peak = memory_one($name, $data);
        my $t1 = time ;
        my $dt = $t1 - $t0 ;

        print STDERR round1($dt * 1000.0) . " ms\n";

        my @cols = ('rows', 'name', 'time(ms)', 'CPU(ms)', 'ttfb(ms)', 'out(' . mem_label() . ')', 'writes', 'peak(' . mem_label() . ')');
        push @results, {
            _cols => \@cols,
            rows  => $rows,
            name  => $name,
            %$speed,
            'peak(' . mem_label() . ')' => $peak,
        };
    }

    return @results;
}

sub usage {
    return <<'USAGE';
usage: benchmark.pl [--show] [--repeat=N] [TEST ...] [ROWS ...] [-]

Examples:
  perl benchmark.pl
  perl benchmark.pl 100 1000
  perl benchmark.pl jsonfold.dump.default jsonfold.dump.max 1000
  perl benchmark.pl jsonfold.dumps.default --show 3

Arguments match benchmark.py:
  TEST    case name, e.g. base.dump.pretty or jsonfold.dump.default
  ROWS    row count; runs the current test filter for that size
  -       clears the current test filter

Options:
  --show       print generated JSON for each tested case
  --repeat=N   override repeat count for this process
  --help       show this help
USAGE
}

sub main {
    my (@argv) = @_;
    my $show = 0;
    my $help = 0;
    my $repeat = $REPEATS;

    GetOptionsFromArray(
        \@argv,
        'show!'   => \$show,
        'repeat=i' => \$repeat,
        'help|h'  => \$help,
    ) or die usage();

    if ($help) {
        print usage();
        return 0;
    }

    # Redefine REPEATS-like value locally by patching the loop count through a
    # package variable would be overkill. For compatibility, --repeat is parsed;
    # the default implementation uses the constant above.
    if ($repeat != $REPEATS) {
        $REPEATS = $repeat;
    }

    my @filter;
    my $last_sz;
    my @results;

    my $t0 = time ;
    for my $arg (@argv) {
        if ($arg eq '-') {
            @filter = ();
            next;
        }

        if ($arg =~ /^\d+$/) {
            $last_sz = int($arg);
            push @results, run_one_size($last_sz, \@filter, $show);
        }
        else {
            push @filter, $arg;
        }
    }

    if (!defined $last_sz) {
        push @results, run_one_size(1_000, \@filter, $show);
    }
    my $t1 = time ;
    print_table(\@results) unless $show;
    print STDERR "Completed in: ", round1($t1-$t0), " Seconds\n" ;

    return 0;
}

exit main(@ARGV);
