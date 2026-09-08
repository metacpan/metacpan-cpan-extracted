#!/usr/bin/env perl
# bench/xml-codec.pl -- compare File::Raw::XML to XML::LibXML, XML::Parser
# and XML::Twig on parse, serialise, canonicalise, XPath and event
# workloads.
#
# Run from the dist root after `perl Makefile.PL && make`:
#
#   perl -Mblib bench/xml-codec.pl
#
# Optional env knobs:
#   BENCH_SECS=N           how long each contender runs per cell, 0.35 by
#                          default; the whole run is about a minute
#   BENCH_SIZES=a,b        a subset of small,medium,large; small,medium by
#                          default, because the large fixture is slow for
#                          one specific reason worth knowing about:
#                          libxml2's canonicaliser is superlinear in
#                          document size. On this machine it runs 23x
#                          slower than this dist at 605 bytes and 870x
#                          slower at 120 KB, so a 5 MB c14n cell costs
#                          tens of seconds on its own. Ask for `large`
#                          when you want to see how far that goes.
#
# WHAT IS AND IS NOT BEING COMPARED. XML::LibXML wraps libxml2, which
# parses a superset of what this dist does: DOCTYPE, entities, DTD
# validation, RelaxNG, XSD, XInclude, HTML, encodings this dist refuses.
# The fixtures are namespaced documents with no DOCTYPE precisely because
# that is the one workload every contender here handles the same way; a
# document with a DOCTYPE is not a comparison, it is one parser refusing.
# libxml2 is given no_network and no external DTD loading, which is what
# any caller parsing untrusted input sets and is the nearest configuration
# to what this dist is by construction. Read the numbers as "on the safe
# subset", not as "faster than libxml2 at XML".
#
# Every workload verifies its contenders against each other before timing
# and prints the answer each one gave. A benchmark whose contenders are
# not computing the same thing is measuring nothing, and c14n in
# particular is checked byte for byte: the canonical form is what a
# signature is over, so File::Raw::XML and libxml2 either agree exactly or
# the run says so and the timing below it is not worth reading.

use 5.010;
use strict;
use warnings;
use Time::HiRes qw(time);

$| = 1;    # a bench is watched while it runs, including down a pipe
use Digest::MD5 qw(md5_hex);
use File::Raw::XML qw(file_xml_decode file_xml_events);
use File::Raw::XML::XPath;

# ---- what is installed ----------------------------------------------------

my $HAVE_LIBXML = eval { require XML::LibXML; 1 };
my $HAVE_PARSER = eval { require XML::Parser; 1 };
my $HAVE_TWIG   = eval { require XML::Twig;   1 };
my $HAVE_READER = $HAVE_LIBXML && eval { require XML::LibXML::Reader; 1 };

printf "File::Raw::XML %s\n", File::Raw::XML->VERSION;
printf "XML::LibXML    %s (libxml2 %s)\n", XML::LibXML->VERSION,
    XML::LibXML::LIBXML_DOTTED_VERSION() if $HAVE_LIBXML;
printf "XML::Parser    %s\n", XML::Parser->VERSION if $HAVE_PARSER;
printf "XML::Twig      %s\n", XML::Twig->VERSION   if $HAVE_TWIG;
print  "\n";

my $libxml = $HAVE_LIBXML
    ? XML::LibXML->new(no_network => 1, load_ext_dtd => 0, expand_entities => 0)
    : undef;

# ---- fixtures -------------------------------------------------------------

# A namespaced feed: a default namespace, a prefixed one, attributes in
# both, an xml:lang, entity references in text and in an attribute value,
# a CDATA section and a comment. No DOCTYPE, for the reason in the header.
my $NS_FEED = 'urn:bench:feed';
my $NS_META = 'urn:bench:meta';

sub fixture {
    my ($entries) = @_;
    my $x = qq{<?xml version="1.0" encoding="UTF-8"?>\n}
          . qq{<feed xmlns="$NS_FEED" xmlns:m="$NS_META" id="root">\n}
          . qq{  <!-- a feed of $entries entries -->\n};
    for my $i (1 .. $entries) {
        $x .= qq{  <entry id="e$i" m:seq="$i" m:href="?a=1&amp;b=$i">}
            . qq{<title>Entry &amp; number $i</title>}
            . qq{<m:tag k="a">alpha</m:tag><m:tag k="b">beta</m:tag>}
            . qq{<body xml:lang="en">text &lt; $i &gt; more</body>}
            . qq{<raw><![CDATA[ <not> markup & ]]></raw>}
            . qq{</entry>\n};
    }
    return $x . "</feed>\n";
}

my %FIXTURE = (
    small  => { entries =>      2 },
    medium => { entries =>    500 },
    large  => { entries => 10_000 },
);

# Contenders here are up to a hundred times apart, so no one iteration
# count serves them: it is either too few to time the fast one or too many
# to sit through for the slow one. Each is given a slice of wall clock
# instead and reports the rate it managed in it.
my $SECS = $ENV{BENCH_SECS} || 0.35;
$FIXTURE{$_}{bytes} = fixture($FIXTURE{$_}{entries}) for keys %FIXTURE;

my @SIZES = $ENV{BENCH_SIZES} ? split(/,/, $ENV{BENCH_SIZES})
                              : qw(small medium);

for my $s (@SIZES) {
    $FIXTURE{$s} or die "no such fixture: $s\n";
    printf "fixture %-7s %6d entries, %9d bytes\n",
        $s, $FIXTURE{$s}{entries}, length $FIXTURE{$s}{bytes};
}

# An answer for the eye. The comparison above is over the whole value; a
# canonical form is a document, and printing it would bury the run, so
# anything long shows as its length and digest - two contenders that agree
# have the same digest, which is all the line is for.
sub show {
    my ($v) = @_;
    return 'undef' unless defined $v;
    return $v if length($v) <= 32;
    return sprintf '%d bytes/md5:%.8s', length($v), md5_hex($v);
}

# Run $code until $SECS have passed, in growing batches so the clock is
# read once per batch rather than once per call, and return the count and
# the elapsed. The batch never grows by more than 4x, so a contender that
# turns out slow cannot overshoot the slice by an order of magnitude.
sub time_it {
    my ($code, $bytes, $size) = @_;
    $code->($bytes, $size);                        # warm up
    my ($n, $batch) = (0, 1);
    my $t0 = time;
    my $dt;
    while (1) {
        $code->($bytes, $size) for 1 .. $batch;
        $n += $batch;
        $dt = time - $t0;
        last if $dt >= $SECS;
        my $rate = $n / ($dt > 0 ? $dt : 1e-6);
        my $want = int($rate * ($SECS - $dt)) + 1;
        $batch = $want > 4 * $n ? 4 * $n : $want;
        $batch = 1 if $batch < 1;
    }
    return ($n, $dt);
}

# ---- the runner -----------------------------------------------------------

# A workload is a name, a list of contenders and, for each, `run` (the
# thing timed, given the fixture bytes) and `verify` (the same work
# reduced to one scalar every contender can be held to). Verification is
# out of band so that the cost of reducing to that scalar is not timed.
sub run_workload {
    my ($name, $note, $contenders) = @_;

    print "\n", '=' x 68, "\n$name\n";
    print "$note\n" if $note;
    print '=' x 68, "\n";

    @$contenders or do { print "  no contender is installed\n"; return };

    for my $size (@SIZES) {
        my $f = $FIXTURE{$size};

        printf "\n--- %s (%d bytes per op, %.2gs per contender) ---\n",
            $size, length $f->{bytes}, $SECS;

        # verify first: a contender whose answer differs is timed anyway,
        # but its row is marked, because an unmarked wrong answer is worse
        # than a missing one
        my (%answer, %bad);
        for my $c (@$contenders) {
            $answer{ $c->{label} } = eval { $c->{verify}->($f->{bytes}, $size) };
            $answer{ $c->{label} } = "DIED: $@" if $@;
        }
        my $ref = $answer{ $contenders->[0]{label} };
        for my $c (@$contenders) {
            my $got = $answer{ $c->{label} };
            $bad{ $c->{label} } = 1 if !defined $got || !defined $ref
                                    || $got ne $ref;
        }
        printf "  answers: %s\n", join ', ',
            map { sprintf '%s=%s', $_->{label}, show($answer{ $_->{label} }) }
            @$contenders;
        print "  ** the contenders do not agree; the timings below compare",
              " different work **\n" if grep { $_ } values %bad;

        my %rate;
        for my $c (@$contenders) {
            next if ref $answer{ $c->{label} } || ($answer{ $c->{label} } // '') =~ /^DIED/;
            my ($n, $dt) = eval { time_it($c->{run}, $f->{bytes}, $size) };
            if ($@) { printf "  %-22s  FAILED: %s", $c->{label}, $@; next }
            $rate{ $c->{label} } = $n / $dt;
            printf "  %-22s %8d ops in %.3fs  %10.0f ops/s  %8.1f MB/s%s\n",
                $c->{label}, $n, $dt, $n / $dt,
                ($n * length($f->{bytes})) / $dt / (1024 * 1024),
                $bad{ $c->{label} } ? '   (DIFFERENT ANSWER)' : '';
        }

        my @rank = sort { $rate{$b} <=> $rate{$a} } keys %rate;
        next unless @rank > 1;
        printf "  -> %s is fastest\n", $rank[0];
        printf "     %-22s %.2fx slower\n", $_, $rate{ $rank[0] } / $rate{$_}
            for @rank[1 .. $#rank];
    }
}

# ---- parse ----------------------------------------------------------------
#
# Bytes to a document. The verifier is the element count, which every
# tree here can be asked for in its own idiom.

my @parse;
push @parse, {
    label  => 'File::Raw::XML',
    run    => sub { file_xml_decode($_[0]) },
    verify => sub { file_xml_decode($_[0])->xpath('count(//*)') },
};
push @parse, {
    label  => 'XML::LibXML',
    run    => sub { $libxml->parse_string($_[0]) },
    verify => sub { $libxml->parse_string($_[0])->findvalue('count(//*)') },
} if $HAVE_LIBXML;
push @parse, {
    label  => 'XML::Twig',
    run    => sub { XML::Twig->new->parse($_[0]) },
    verify => sub {
        # Twig models text as #PCDATA/#CDATA pseudo-elements, which are
        # not elements: a gi beginning with # is not counted
        my $t = XML::Twig->new->parse($_[0]);
        return 1 + grep { $_->gi !~ /^#/ } $t->root->descendants;
    },
} if $HAVE_TWIG;
push @parse, {
    label  => 'XML::Parser (Tree)',
    run    => sub { XML::Parser->new(Style => 'Tree')->parse($_[0]) },
    verify => sub {
        # Tree style is [ tag, [ {attrs}, tag, [...], 0, 'text', ... ] ];
        # walk it with an explicit stack and count the tags
        # Tree style is [ tag, content ], and a content list is
        # [ {attrs}, (tag => content)* ] with the tag 0 meaning the text
        # in the slot beside it
        my $tree = XML::Parser->new(Style => 'Tree')->parse($_[0]);
        my @todo = ($tree->[1]);
        my $n    = 1;                                    # the root itself
        while (my $content = pop @todo) {
            for (my $i = 1; $i < $#$content; $i += 2) {
                next if $content->[$i] eq '0';           # a text slot
                $n++;
                push @todo, $content->[$i + 1];
            }
        }
        return $n;
    },
} if $HAVE_PARSER;

run_workload('PARSE  bytes to a document tree', undef, \@parse);

# ---- serialise ------------------------------------------------------------
#
# The tree back to markup. Timed over a tree parsed once, so the parse is
# not counted twice. The verifier re-parses what was written and counts
# elements: the byte-level output differs between these (declaration,
# whitespace, empty-element form) and the invariant that matters is that
# the document survives the round trip.

my @ser;
{
    my %tree;
    push @ser, {
        label  => 'File::Raw::XML',
        run    => sub { ($tree{"frx$_[1]"} ||= file_xml_decode($_[0]))->to_string },
        verify => sub {
            file_xml_decode(file_xml_decode($_[0])->to_string)->xpath('count(//*)');
        },
    };
    push @ser, {
        label  => 'XML::LibXML',
        run    => sub { ($tree{"lx$_[1]"} ||= $libxml->parse_string($_[0]))->toString },
        verify => sub {
            $libxml->parse_string($libxml->parse_string($_[0])->toString)
                   ->findvalue('count(//*)');
        },
    } if $HAVE_LIBXML;
    push @ser, {
        label  => 'XML::Twig',
        run    => sub { ($tree{"tw$_[1]"} ||= XML::Twig->new->parse($_[0]))->sprint },
        verify => sub {
            my $s = XML::Twig->new->parse($_[0])->sprint;
            my $t = XML::Twig->new->parse($s);
            return 1 + grep { $_->gi !~ /^#/ } $t->root->descendants;
        },
    } if $HAVE_TWIG;
}

run_workload('SERIALISE  a parsed tree back to markup',
    'each fixture is parsed once, outside the timing loop', \@ser);

# ---- canonicalise ---------------------------------------------------------
#
# The workload this dist exists for. Only libxml2 competes: XML::Parser
# and XML::Twig have no canonical form. The verifier is the canonical
# bytes themselves, so the two implementations are held to being
# byte-identical, which is the only agreement a signature cares about.

for my $mode (['inclusive', 'Canonical XML 1.0'], ['exclusive', 'Exclusive XML Canonicalization 1.0']) {
    my ($m, $title) = @$mode;
    my @c14n;
    my %tree;

    push @c14n, {
        label  => 'File::Raw::XML',
        run    => sub { ($tree{"frx$_[1]"} ||= file_xml_decode($_[0]))->root->c14n(mode => $m) },
        verify => sub { file_xml_decode($_[0])->root->c14n(mode => $m) },
    };
    push @c14n, {
        label  => 'XML::LibXML',
        run    => sub {
            my $d = $tree{"lx$_[1]"} ||= $libxml->parse_string($_[0]);
            $m eq 'inclusive' ? $d->documentElement->toStringC14N(0)
                              : $d->documentElement->toStringEC14N(0);
        },
        verify => sub {
            my $d = $libxml->parse_string($_[0])->documentElement;
            my $s = $m eq 'inclusive' ? $d->toStringC14N(0) : $d->toStringEC14N(0);
            utf8::encode($s) if utf8::is_utf8($s);   # c14n is bytes on both sides
            return $s;
        },
    } if $HAVE_LIBXML;

    run_workload("CANONICALISE $m  ($title)",
        'each fixture is parsed once, outside the timing loop; the verifier is the'
        . "\ncanonical bytes, so the two must agree exactly", \@c14n);
}

# ---- xpath ----------------------------------------------------------------
#
# One expression compiled once and evaluated many times, which is the
# shape a signature verifier uses. The verifier is the size of the node
# set.

my @xp;
{
    my $EXPR = '//m:tag[@k = "a"]';
    my %tree;
    my $frx_xp = File::Raw::XML::XPath->new($EXPR, ns => { m => $NS_META });

    push @xp, {
        label  => 'File::Raw::XML',
        run    => sub {
            my $d = $tree{"frx$_[1]"} ||= file_xml_decode($_[0]);
            my @n = $frx_xp->find($d->document);
            return scalar @n;
        },
        verify => sub { scalar( () = $frx_xp->find(file_xml_decode($_[0])->document) ) },
    };
    if ($HAVE_LIBXML) {
        my $ctx = XML::LibXML::XPathContext->new;
        $ctx->registerNs(m => $NS_META);
        my $comp = XML::LibXML::XPathExpression->new($EXPR);
        push @xp, {
            label  => 'XML::LibXML',
            run    => sub {
                my $d = $tree{"lx$_[1]"} ||= $libxml->parse_string($_[0]);
                my @n = $ctx->findnodes($comp, $d);
                return scalar @n;
            },
            verify => sub {
                scalar( () = $ctx->findnodes($comp, $libxml->parse_string($_[0])) );
            },
        };
    }
}

run_workload('XPATH  //m:tag[@k = "a"], compiled once',
    'each fixture is parsed once, outside the timing loop', \@xp);

# ---- events ---------------------------------------------------------------
#
# No tree: the callback shape, where the document is never held whole.
# The verifier is the number of start-element events.

my @ev;
push @ev, {
    label  => 'File::Raw::XML',
    run    => sub {
        my $n = 0;
        file_xml_events($_[0], start => sub { $n++ }, text => sub { });
        return $n;
    },
    verify => sub {
        my $n = 0;
        file_xml_events($_[0], start => sub { $n++ }, text => sub { });
        return $n;
    },
};
push @ev, {
    label  => 'XML::LibXML::Reader',
    run    => sub {
        my $r = XML::LibXML::Reader->new(string => $_[0], no_network => 1);
        my $n = 0;
        while ($r->read) { $n++ if $r->nodeType == XML::LibXML::Reader::XML_READER_TYPE_ELEMENT() }
        return $n;
    },
    verify => sub {
        my $r = XML::LibXML::Reader->new(string => $_[0], no_network => 1);
        my $n = 0;
        while ($r->read) { $n++ if $r->nodeType == XML::LibXML::Reader::XML_READER_TYPE_ELEMENT() }
        return $n;
    },
} if $HAVE_READER;
push @ev, {
    label  => 'XML::Parser (handlers)',
    run    => sub {
        my $n = 0;
        XML::Parser->new(Handlers => { Start => sub { $n++ }, Char => sub { } })
                   ->parse($_[0]);
        return $n;
    },
    verify => sub {
        my $n = 0;
        XML::Parser->new(Handlers => { Start => sub { $n++ }, Char => sub { } })
                   ->parse($_[0]);
        return $n;
    },
} if $HAVE_PARSER;

run_workload('EVENTS  a callback per node, no tree kept', undef, \@ev);

print "\nDone.\n";
