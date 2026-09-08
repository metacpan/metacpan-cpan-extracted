#!/usr/bin/env perl
# bench/stream.pl -- a file larger than you want in memory, one record at
# a time: File::Raw::XML's plugin and Reader against XML::LibXML::Reader,
# XML::Twig with purge, XML::Parser's handlers, and a whole-file DOM as
# the baseline that holds everything.
#
# Run from the dist root after `perl Makefile.PL && make`:
#
#   perl -Mblib bench/stream.pl
#
# Optional env knobs:
#   BENCH_MB=N        the size of the synthetic file, 16 by default
#   BENCH_KEEP=1      leave the file behind and print its path
#
# TIME AND MEMORY ARE MEASURED IN SEPARATE RUNS. Reading resident size
# costs a syscall and a walk of the process table, and sampling it inside
# the record callback would land in the middle of what is being timed, so
# each contender runs twice: once with the sampler a no-op, for the clock,
# and once with it live, for the peak. The numbers in a row come from two
# different processes and that is deliberate.
#
# EACH CONTENDER RUNS IN ITS OWN FORKED CHILD, because an allocator does
# not hand pages back: whichever contender ran first would set a floor
# under every one after it, and the DOM baseline would make the rest look
# free. A child reports through a pipe and leaves with _exit, so no END
# block or global destruction runs in it.
#
# WHAT THE COMPARISON IS. Every contender is asked for the same thing: the
# id attribute of each record, counted and summed. XML::Parser's handlers
# are the floor, not a rival - they never build a node, so they are what
# reading the bytes and nothing else costs. The rest hand back a record
# you can canonicalise or sign, which is the point.

use 5.010;
use strict;
use warnings;
use POSIX ();
use Time::HiRes qw(time);

$| = 1;    # a bench is watched while it runs, including down a pipe
use File::Temp qw(tempdir);
use File::Raw ();
use File::Raw::XML qw(:const);
use File::Raw::XML::Reader;

my $NS = 'urn:bench:log';

my $HAVE_LIBXML = eval { require XML::LibXML; require XML::LibXML::Reader; 1 };
my $HAVE_PARSER = eval { require XML::Parser; 1 };
my $HAVE_TWIG   = eval { require XML::Twig;   1 };
my $HAVE_PT     = eval {
    require Proc::ProcessTable;
    my $t = Proc::ProcessTable->new(enable_ttys => 0);
    grep { $_ eq 'rss' } $t->fields or die "no rss field\n";
    1;
};

my $PT = $HAVE_PT ? Proc::ProcessTable->new(enable_ttys => 0) : undef;

sub _rss_raw {
    return undef unless $PT;
    for my $p (@{ $PT->table }) {
        return $p->rss if $p->pid == $$;
    }
    return undef;
}

# Proc::ProcessTable's rss field is bytes on some platforms and KiB on
# others - darwin reports KiB, matching ps -o rss= exactly - and the
# module documents neither, because the field is filled by per-platform
# XS. So the unit is MEASURED, not assumed: allocate a known block and
# see how far the number moves. Assuming the wrong one here would scale
# every threshold below by 1024 and the gate would still say PASS.
my $RSS_IS_KIB = 1;
if ($PT) {
    my $before = _rss_raw() // 0;
    my $blob   = 'x' x (32 * 1024 * 1024);
    substr($blob, 0, 1) = 'y';               # touch it, so it is resident
    my $moved  = (_rss_raw() // 0) - $before;
    # ~32 MiB of movement is bytes; ~32 KiB of movement is KiB. No
    # movement at all reads as KiB, which reports a bytes platform 1024x
    # too high and fails loudly rather than passing quietly.
    $RSS_IS_KIB = $moved > 4 * 1024 * 1024 ? 0 : 1;
}

sub rss_kb {
    my $r = _rss_raw();
    return undef unless defined $r;
    return $RSS_IS_KIB ? $r : int($r / 1024);
}

warn "Proc::ProcessTable is not installed: the memory column will be empty\n"
    unless $HAVE_PT;

# ---- the file -------------------------------------------------------------

my $MB   = $ENV{BENCH_MB} || 16;
my $dir  = tempdir(CLEANUP => !$ENV{BENCH_KEEP});
my $path = "$dir/stream.xml";

my $RECORDS = 0;
{
    open my $fh, '>:raw', $path or die "$path: $!";
    print {$fh} qq{<?xml version="1.0" encoding="UTF-8"?>\n}
              . qq{<log xmlns="$NS" xmlns:m="urn:bench:meta">\n};
    my $written = 0;
    my $target  = $MB * 1024 * 1024;
    while ($written < $target) {
        $RECORDS++;
        my $rec = qq{  <record id="$RECORDS" m:kind="event">}
                . qq{<name>record $RECORDS</name>}
                . qq{<body>} . ('x' x 60) . qq{</body></record>\n};
        print {$fh} $rec;
        $written += length $rec;
    }
    print {$fh} "</log>\n";
    close $fh or die "$path: $!";
}
printf "%s\n%d records, %.1f MiB on disk\n\n",
    ($ENV{BENCH_KEEP} ? $path : "a synthetic log in a temporary directory"),
    $RECORDS, (-s $path) / (1024 * 1024);

# ---- one contender in one child -------------------------------------------

# $code is called with a sampler it should invoke once per record, and
# returns [ records seen, the sum of their ids ]. The sum is the verifier:
# a contender that skipped records or read the wrong attribute cannot
# match it.
sub in_child {
    my ($code, $sample) = @_;
    pipe(my $rd, my $wr) or die "pipe: $!";
    my $pid = fork;
    defined $pid or die "fork: $!";

    if (!$pid) {
        close $rd;
        my $base = rss_kb() // 0;
        my $peak = $base;
        # Reading resident size walks the whole process table, so it is
        # far too expensive to do once per record: every 256th call is
        # often enough to catch a peak that climbs with the file and cheap
        # enough not to dominate the run it is measuring.
        my $tick = 0;
        my $sampler = $sample
            ? sub {
                return if ++$tick % 256;
                my $k = rss_kb() // 0;
                $peak = $k if $k > $peak;
              }
            : sub { };
        my ($n, $sum) = (0, 0);
        my $t0 = time;
        my $err = '';
        eval { ($n, $sum) = @{ $code->($sampler) }; 1 } or $err = $@;
        my $dt = time - $t0;
        $sampler->();
        print {$wr} join("\t", $n, $sum, $dt, $base, $peak, $err =~ s/\n/ /gr), "\n";
        close $wr;
        POSIX::_exit(0);
    }

    close $wr;
    my $line = <$rd>;
    close $rd;
    waitpid $pid, 0;
    defined $line or return { err => 'the child produced nothing (killed?)' };
    chomp $line;
    my ($n, $sum, $dt, $base, $peak, $err) = split /\t/, $line, 6;
    return { n => $n, sum => $sum, dt => $dt, base => $base, peak => $peak,
             err => $err };
}

# ---- the contenders -------------------------------------------------------

my @C;

push @C, {
    label => 'File::Raw::XML plugin',
    code  => sub {
        my ($sample) = @_;
        my ($n, $sum) = (0, 0);
        File::Raw::each_line($path, sub {
            my ($doc) = @_;
            $n++;
            $sum += $doc->root->attr('id');
            $sample->();
        }, plugin => 'xml', record => [$NS, 'record']);
        return [ $n, $sum ];
    },
};

push @C, {
    label => 'File::Raw::XML Reader',
    code  => sub {
        my ($sample) = @_;
        my ($n, $sum) = (0, 0);
        my $r = File::Raw::XML::Reader->from_file($path);
        while (defined(my $kind = $r->next)) {
            next unless $kind && $kind == FRX_START();
            next unless $r->local eq 'record' && $r->ns eq $NS;
            my $doc = $r->subtree;
            $doc = $r->subtree while !$doc && !$r->done;   # a chunk boundary
            last unless $doc;
            $n++;
            $sum += $doc->root->attr('id');
            $sample->();
        }
        return [ $n, $sum ];
    },
};

push @C, {
    label => 'XML::LibXML::Reader',
    code  => sub {
        my ($sample) = @_;
        my ($n, $sum) = (0, 0);
        my $r = XML::LibXML::Reader->new(location => $path, no_network => 1);
        while ($r->nextElement('record', $NS)) {
            my $node = $r->copyCurrentNode(1);            # the whole subtree
            $n++;
            $sum += $node->getAttribute('id');
            $sample->();
        }
        return [ $n, $sum ];
    },
} if $HAVE_LIBXML;

push @C, {
    label => 'XML::Twig (purge)',
    code  => sub {
        my ($sample) = @_;
        my ($n, $sum) = (0, 0);
        XML::Twig->new(twig_handlers => {
            record => sub {
                my ($t, $elt) = @_;
                $n++;
                $sum += $elt->att('id');
                $sample->();
                $t->purge;                                # drop what is behind
            },
        })->parsefile($path);
        return [ $n, $sum ];
    },
} if $HAVE_TWIG;

push @C, {
    label => 'XML::Parser handlers',
    code  => sub {
        my ($sample) = @_;
        my ($n, $sum) = (0, 0);
        XML::Parser->new(Handlers => {
            Start => sub {
                my ($p, $el, %a) = @_;
                return unless $el eq 'record';
                $n++;
                $sum += $a{id};
                $sample->();
            },
        })->parsefile($path);
        return [ $n, $sum ];
    },
} if $HAVE_PARSER;

push @C, {
    label => 'XML::LibXML whole DOM',
    baseline => 1,
    code  => sub {
        my ($sample) = @_;
        my $doc = XML::LibXML->new(no_network => 1, load_ext_dtd => 0)
                             ->load_xml(location => $path);
        my ($n, $sum) = (0, 0);
        for my $node ($doc->documentElement->childNodes) {
            next unless $node->nodeType == XML::LibXML::XML_ELEMENT_NODE();
            $n++;
            $sum += $node->getAttribute('id');
            $sample->();
        }
        return [ $n, $sum ];
    },
} if $HAVE_LIBXML;

# ---- run ------------------------------------------------------------------

printf "%-24s %10s %10s %12s %12s\n",
    '', 'records', 'seconds', 'MiB/s', 'peak RSS KiB';
print '-' x 72, "\n";

my (%time, %peak, %sum);
for my $c (@C) {
    my $t = in_child($c->{code}, 0);
    if ($t->{err}) {
        printf "%-24s FAILED: %s\n", $c->{label}, $t->{err};
        next;
    }
    my $m = $HAVE_PT ? in_child($c->{code}, 1) : { peak => 0, base => 0 };

    $time{ $c->{label} } = $t->{dt};
    $peak{ $c->{label} } = $m->{peak};
    $sum { $c->{label} } = $t->{sum};

    printf "%-24s %10d %10.3f %12.1f %12s%s\n",
        $c->{label}, $t->{n}, $t->{dt},
        (-s $path) / $t->{dt} / (1024 * 1024),
        ($HAVE_PT ? $m->{peak} : '-'),
        ($c->{baseline} ? '   <- holds the whole document' : '');
}

# ---- did they all read the same file? -------------------------------------

print "\n";
my ($ref) = grep { defined $sum{$_} } map { $_->{label} } @C;
my @wrong = grep { $sum{$_} ne $sum{$ref} } grep { defined $sum{$_} } keys %sum;
if (@wrong) {
    printf "** these did not sum the record ids to the same value as %s: %s **\n",
        $ref, join ', ', @wrong;
    printf "   %-24s sum=%s\n", $_, $sum{$_} for sort keys %sum;
} else {
    printf "every contender summed %d record ids to %s\n",
        $RECORDS, $sum{$ref};
}

my @rank = sort { $time{$a} <=> $time{$b} } keys %time;
if (@rank > 1) {
    printf "\n%s is fastest\n", $rank[0];
    printf "  %-24s %.2fx slower\n", $_, $time{$_} / $time{ $rank[0] }
        for @rank[1 .. $#rank];
}

if ($HAVE_PT) {
    my @lean = sort { $peak{$a} <=> $peak{$b} } grep { $peak{$_} } keys %peak;
    if (@lean > 1) {
        printf "\n%s holds the least (%d KiB peak against a %.1f MiB file)\n",
            $lean[0], $peak{ $lean[0] }, (-s $path) / (1024 * 1024);
        printf "  %-24s %.2fx the peak\n", $_, $peak{$_} / $peak{ $lean[0] }
            for @lean[1 .. $#lean];
    }
}

print "\nDone.\n";
