#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::XML qw(file_xml_decode);

# The resident-size gate over the full profile, which t/15-leak.t does not
# reach: t/15 parses, walks and canonicalises under strict, where the whole
# document is one arena and one free. The full profile allocates outside
# that arena - the DTD's tables, an entity frame per reference, the bytes a
# resolver hands back and the release hook that gives them up, the
# validity pass's collected errors, a compiled XPath, the edit log and the
# writer's transcoder - and each of those is a place where an early return
# frees no SV and changes no reference count, so Test::LeakTrace sees
# nothing and only the process's resident size moves.
#
# This is an author test rather than a t/ one: it runs a hundred thousand
# rounds of the whole pipeline and takes minutes, and its bound is a
# heuristic that a loaded machine can push past. A failure here is a leak
# to find under ASan, not a release blocker on its own.
#
# The gate itself is t/15's: warm every allocator, read the resident size,
# run, read again. Growth over 1 MiB is a leak - twice t/15's bound,
# because a round here allocates in more places and glibc's arenas round up
# in more of them.

plan skip_all => 'set RELEASE_TESTING to run the author leak gate'
    unless $ENV{RELEASE_TESTING};

my $HAVE_PT = eval {
    require Proc::ProcessTable;
    my $t = Proc::ProcessTable->new(enable_ttys => 0);
    grep { $_ eq 'rss' } $t->fields or die "no rss field\n";
    1;
};
plan skip_all => 'Proc::ProcessTable is not installed; resident size is not gated'
    unless $HAVE_PT;

my $PT = Proc::ProcessTable->new(enable_ttys => 0);
sub rss_kb {
    for my $p (@{ $PT->table }) {
        return int($p->rss / 1024) if $p->pid == $$;
    }
    return undef;
}
plan skip_all => 'Proc::ProcessTable lists no row for this process'
    unless defined rss_kb();

my $XI = 'http://www.w3.org/2001/XInclude';

# what the resolver serves: an external subset with declarations the
# document depends on, an external entity, and a document to include
my %files = (
    'urn:t/ext.dtd' => qq{<!ELEMENT e ANY>\n<!ATTLIST e n CDATA #IMPLIED d CDATA "dd">\n}
                     . qq{<!ENTITY x "from the external subset">\n},
    'urn:t/ext.ent' => 'external &inner; text',
    'urn:t/inc.xml' => '<a y="1"><b/></a>',
);
my $fetches = 0;
my $resolver = sub {
    my %r = @_;
    $fetches++;
    die "no such resource: $r{system_id}\n" unless exists $files{ $r{system_id} };
    return $files{ $r{system_id} };
};

my $doc_bytes = join '',
    qq{<?xml version="1.0" encoding="UTF-8"?>\n},
    qq{<!DOCTYPE r SYSTEM "ext.dtd" [\n},
    qq{<!ELEMENT r (e|a)*>\n},
    qq{<!ATTLIST r id ID #IMPLIED k (p|q) "q">\n},
    qq{<!ENTITY inner "inner text">\n},
    qq{<!ENTITY ent "&inner; and &inner;">\n},
    qq{<!ENTITY ext SYSTEM "ext.ent">\n},
    qq{<!ENTITY % pe "<!ENTITY g 'through a parameter entity'>">\n},
    qq{%pe;\n},
    qq{]>\n},
    qq{<r id="r1" xmlns:xi="$XI">\n};
$doc_bytes .= qq{  <e n="$_">&ent; &g; &ext;</e>\n} for 1 .. 40;
$doc_bytes .= qq{  <xi:include href="inc.xml"/>\n</r>\n};

# a round: the whole processor over the one document, ending with
# everything it allocated given back
sub once {
    my $doc = file_xml_decode($doc_bytes,
        profile  => 'full',
        validate => 'collect',
        xinclude => 1,
        base     => 'urn:t/doc.xml',
        resolve  => $resolver,
    );
    my @errors = $doc->errors;

    my $n = () = $doc->xpath('//e[@n]');
    my $c = $doc->xpath('count(//*)');
    my $s = $doc->xpath('normalize-space(string(/r/e[1]))');

    my ($first) = $doc->root->elements;
    $first->set_attr('', 'edited', 'yes');
    $first->set_text('replaced');
    my $copy = $doc->root->append($doc->import_node($first));
    $copy->detach;

    my $out  = $doc->to_string(indent => 2);
    my $c14n = $doc->root->c14n(mode => 'exclusive', comments => 1);

    return $n + length($out) + length($c14n) + length($s) + scalar(@errors) + int($c);
}

my $answer = once();
ok($answer, "the full pipeline runs (answer $answer, $fetches fetches in the first round)");

# a refusal round: the half-built document, the DTD tables and whatever a
# resolver had already handed back are all given up on the way out, and
# none of that is an SV
my $bad = $doc_bytes;
$bad =~ s{</r>}{</wrong>};
sub once_refused {
    my $ok = eval {
        file_xml_decode($bad, profile => 'full', validate => 'collect',
                        xinclude => 1, base => 'urn:t/doc.xml', resolve => $resolver);
        1;
    };
    return $ok ? 0 : 1;
}
ok(once_refused(), 'a document that is not well formed is refused after the fetches');

# a resolver that dies: the path where the fetch machinery unwinds through
# a Perl exception, which is where a released buffer is easiest to lose
sub once_no_resolver {
    my $ok = eval {
        file_xml_decode($doc_bytes, profile => 'full', validate => 'collect',
                        xinclude => 1, base => 'urn:t/doc.xml',
                        resolve => sub { die "nothing here\n" });
        1;
    };
    return $ok ? 0 : 1;
}
ok(once_no_resolver(), 'a resolver that refuses everything refuses the parse');

my $ROUNDS = $ENV{FRX_LEAK_ROUNDS} || 100_000;

once() for 1 .. 2_000;
my $b0 = rss_kb();
for (1 .. $ROUNDS) {
    once() == $answer or die "the answer changed at round $_";
}
my $g0 = rss_kb() - $b0;
cmp_ok($g0, '<=', 1024,
    "$ROUNDS full-profile rounds are steady state (grew ${g0} KiB)");

once_refused() for 1 .. 2_000;
my $b1 = rss_kb();
once_refused() for 1 .. $ROUNDS;
my $g1 = rss_kb() - $b1;
cmp_ok($g1, '<=', 1024,
    "$ROUNDS refusals after a fetch are steady state (grew ${g1} KiB)");

once_no_resolver() for 1 .. 2_000;
my $b2 = rss_kb();
once_no_resolver() for 1 .. $ROUNDS;
my $g2 = rss_kb() - $b2;
cmp_ok($g2, '<=', 1024,
    "$ROUNDS resolver failures are steady state (grew ${g2} KiB)");

# a compiled expression evaluated many times against many documents: the
# XPath object outlives the documents, so a node set that kept a document
# alive would show here and nowhere else
{
    my $xp = File::Raw::XML::XPath->new('//e[@n mod 2 = 0]');
    my $d0 = file_xml_decode($doc_bytes, profile => 'full', validate => 'collect',
                             xinclude => 1, base => 'urn:t/doc.xml', resolve => $resolver);
    my $want = () = $xp->find($d0);
    ok($want, "the compiled expression selects $want nodes");

    for (1 .. 2_000) {
        my $d = file_xml_decode($doc_bytes, profile => 'full', validate => 'collect',
                                xinclude => 1, base => 'urn:t/doc.xml', resolve => $resolver);
        () = $xp->find($d);
    }
    my $b3 = rss_kb();
    for (1 .. $ROUNDS / 10) {
        my $d = file_xml_decode($doc_bytes, profile => 'full', validate => 'collect',
                                xinclude => 1, base => 'urn:t/doc.xml', resolve => $resolver);
        my $got = () = $xp->find($d);
        $got == $want or die "the node count changed";
    }
    my $g3 = rss_kb() - $b3;
    cmp_ok($g3, '<=', 1024,
        (int $ROUNDS / 10) . " documents through one compiled expression are steady state (grew ${g3} KiB)");
}

done_testing;
