#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::XML qw(file_xml_decode file_xml_events);

# Two leak gates, because one leak is two different things.
#
# Test::LeakTrace counts the SVs the interpreter is still holding after a
# block runs, which is the seam between the XS and Perl: a mortal that was
# never made mortal, a +1 SV returned twice, an AV a list-returning method
# built and dropped. It sees every one of those and none of the C below.
#
# THE ARENA IS INVISIBLE TO IT. A document is one malloc'd arena hung off
# an IV with free magic, so an arena leaked because an early return in the
# parse path skipped frx_doc_free frees no SV, changes no reference count,
# and passes no_leaks_ok every time. That leak shows only as resident size,
# which is why the second gate is still here: a twenty-kilobyte document
# parsed, canonicalised and walked five thousand times to warm every
# allocator, the process's resident size read, a hundred thousand more,
# and read again. Growth over 512 KiB is a leak.
#
# Neither is a proof: an arena leaked once per parse at 20 KiB would show,
# one leaked once per refusal would not, and ASan under tools/fuzz/build.sh
# is where the proof lives. This is the pair that fails in CI on the day
# frx_doc_free is skipped or an SV is returned without being mortalised.
#
# Both modules are optional and each gate skips by name without its own,
# so a run with neither installed still says which coverage it did not get.

# The import has to happen at compile time: no_leaks_ok is prototyped
# (&;$), and without the prototype in scope the `{` opening its block is
# guessed to be an anonymous hash and the file does not parse as intended.
our $HAVE_LT;
BEGIN { $HAVE_LT = eval { require Test::LeakTrace; Test::LeakTrace->import; 1 } ? 1 : 0 }

my $HAVE_PT = eval {
    require Proc::ProcessTable;
    # AIX and some Cygwin builds have a process table with no rss column
    my $t = Proc::ProcessTable->new(enable_ttys => 0);
    grep { $_ eq 'rss' } $t->fields or die "no rss field\n";
    1;
};

my $PT = $HAVE_PT ? Proc::ProcessTable->new(enable_ttys => 0) : undef;

# the raw field for this process; table() re-reads on every call
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

my $bytes = qq{<r xmlns="urn:d" xmlns:p="urn:p" ID="root">\n};
my $i = 0;
while (length $bytes < 20 * 1024) {
    $i++;
    $bytes .= qq{<p:e ID="e$i" a="$i" p:b="&amp;$i"><f xmlns="">t &lt; $i</f><![CDATA[c$i]]><!-- $i --></p:e>\n};
}
$bytes .= "</r>\n";
my $sig = 'e' . int($i / 2);

sub once {
    my $doc = file_xml_decode($bytes, id_attrs => ['ID']);
    my $root = $doc->root;
    my $n = () = $root->descendants(undef, 'f');
    my $node = $doc->by_id(ID => $sig);
    my $out = $root->c14n(mode => 'exclusive', without => [$node]);
    my $text = $node->text;
    return length($out) + $n + length($text);
}

my $answer = once();
ok($answer, 'the document parses, walks and canonicalises');

# ---- the SV gate ----------------------------------------------------------
#
# A small document, because Test::LeakTrace runs each block several times
# and counts what the interpreter allocated; the size of the document is
# not what is being measured. Every path that hands an SV back across the
# seam gets its own block, so a failure names the method.

SKIP: {
    skip 'Test::LeakTrace is not installed; the SV seam is not gated', 9
        unless $HAVE_LT;

    my $small = '<r xmlns="urn:d" xmlns:p="urn:p" ID="root">'
              . '<p:e ID="e1" a="1" p:b="&amp;1"><f xmlns="">t &lt; 1</f>'
              . '<![CDATA[c1]]><!-- 1 --></p:e></r>';

    # every block is run once here first: the first call through any of
    # these paths interns a string or fills a cache, and that one-time
    # allocation is not a leak
    my $warm = sub {
        my $d = file_xml_decode($small, id_attrs => ['ID']);
        my $r = $d->root;
        () = $r->descendants(undef, 'f');
        () = $r->elements;
        $r->c14n;
        $d->by_id(ID => 'e1')->text;
        $d->to_string;
        () = $d->xpath('//f');
        eval { file_xml_decode('<r>'); 1 };
        file_xml_events($small, start => sub { }, text => sub { });
    };
    $warm->() for 1 .. 3;

    no_leaks_ok { file_xml_decode($small, id_attrs => ['ID']) } 'parse leaks no SV';

    no_leaks_ok {
        my $d = file_xml_decode($small, id_attrs => ['ID']);
        () = $d->root->descendants(undef, 'f');
        () = $d->root->elements;
    } 'the list-returning walkers leak no SV';

    no_leaks_ok {
        my $d = file_xml_decode($small, id_attrs => ['ID']);
        $d->by_id(ID => 'e1')->text;
    } 'by_id and text leak no SV';

    no_leaks_ok {
        my $d = file_xml_decode($small, id_attrs => ['ID']);
        my $n = $d->by_id(ID => 'e1');
        $d->root->c14n(mode => 'exclusive', without => [$n]);
    } 'c14n leaks no SV';

    no_leaks_ok {
        my $d = file_xml_decode($small);
        $d->to_string(indent => 2);
    } 'the writer leaks no SV';

    no_leaks_ok {
        my $d = file_xml_decode($small);
        () = $d->xpath('//f');
    } 'xpath leaks no SV';

    no_leaks_ok {
        file_xml_events($small, start => sub { }, text => sub { });
    } 'the reader leaks no SV';

    # a refusal: the message SV is mortal and the half-built document is
    # freed on the way out, which is the path the arena gate cannot see
    # and this one can only half see
    no_leaks_ok {
        eval { file_xml_decode('<r><a></b></r>'); 1 };
    } 'a refused parse leaks no SV';

    no_leaks_ok {
        my $d = File::Raw::XML->new_document;
        my $r = $d->document->append($d->new_element('urn:x', 'x:r'));
        $r->append($d->new_element('urn:x', 'x:a'))->set_attr('', 'n', 1)->set_text('t');
        $r->c14n;
    } 'building and editing leak no SV';
}

# ---- the arena gate -------------------------------------------------------

SKIP: {
    skip 'Proc::ProcessTable is not installed; resident size is not gated', 4
        unless $HAVE_PT;
    skip 'Proc::ProcessTable lists no row for this process', 4
        unless defined rss_kb();

    once() for 1 .. 5_000;
    my $before = rss_kb();
    for (1 .. 100_000) {
        once() == $answer or die "the answer changed";
    }
    my $after = rss_kb();
    my $growth = $after - $before;
    cmp_ok($growth, '<=', 512,
        "parse, walk and c14n are steady state over 100k rounds (grew ${growth} KiB)");

    # edits: 100k documents built and freed are steady state; 100k
    # edit cycles on one document grow its arena, which is the documented cost
    my $build = sub {
        my $d = File::Raw::XML->new_document;
        my $r = $d->document->append($d->new_element('urn:x', 'x:r'));
        $r->append($d->new_element('urn:x', 'x:a'))->set_attr('', 'n', $_[0])->set_text('t');
        return length $r->c14n;
    };
    $build->($_) for 1 .. 2_000;
    my $b0 = rss_kb();
    $build->($_) for 1 .. 100_000;
    my $g1 = rss_kb() - $b0;
    cmp_ok($g1, '<=', 512, "100k documents built, edited and freed are steady state (grew ${g1} KiB)");

    my $d = file_xml_decode('<r><a n="0"/></r>');
    my ($a) = $d->root->elements;
    my $b1 = rss_kb();
    for my $i (1 .. 100_000) {
        $a->set_attr('', 'n', $i);
        $a->set_text("v$i");
    }
    my $g2 = rss_kb() - $b1;
    cmp_ok($g2, '>', 0, "100k edits on one document grow its arena, as the documentation says (grew ${g2} KiB)");
    is($a->attr('n'), '100000', 'and the last edit is what is there');
}

done_testing;
