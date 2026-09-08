#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use Socket;
use IO::Handle;
use File::Raw::XML qw(:all);
use File::Raw::XML::Reader;

# The pull reader: every event kind, the same sequence whatever the
# chunking (whole, halves, one byte at a time), entities as their own text
# events, namespaces and depth and offset, the subtree cut, the push form,
# a reader over a file, and a reader over a socketpair that delivers more
# than the kernel buffers.

my $SAMPLE = <<'XML';
<?xml version="1.0"?>
<!DOCTYPE doc [
<!ENTITY greet "hi &amp; <b>there</b>">
<!ATTLIST doc dflt CDATA "d">
]>
<?pi before?>
<!-- top -->
<doc xmlns="urn:d" xmlns:p="urn:p" a="1" p:b="two">
  text &greet; more<![CDATA[ <cdata> ]]>tail
  <p:child id="c1"><leaf/>x<!-- inner --><?target data?></p:child>
  <empty/>
</doc>
<!-- after -->
XML

sub snapshot {
    my ($r, $kind) = @_;
    my $row = [ $kind, $r->name, $r->local, $r->ns, $r->prefix, $r->value, $r->depth, $r->offset ];
    push @$row, $r->attrs, $r->empty if $kind == FRX_START;
    push @$row, $r->entity if $kind == FRX_TEXT;
    push @$row, $r->target if $kind == FRX_PI;
    push @$row, $r->doctype if $kind == FRX_DOCTYPE;
    return $row;
}

# every event of $bytes, fed in pieces of $piece bytes (0: whole), with
# the number of times next asked for more
sub events {
    my ($bytes, $piece, %o) = @_;
    my $r = File::Raw::XML::Reader->new(profile => 'full', %o);
    my (@ev, $asked);
    $asked = 0;
    my @pieces = $piece ? ($bytes =~ /(.{1,$piece})/gs) : ($bytes);
    my $eof = 0;
    my $pump = sub {
        while (1) {
            my $k = $r->next;
            last unless defined $k;
            if (!$k) { $asked++; last }
            push @ev, snapshot($r, $k);
        }
    };
    for my $i (0 .. $#pieces) {
        $r->feed($pieces[$i], $i == $#pieces ? 1 : 0);
        $pump->();
    }
    $pump->() unless @pieces;
    return (\@ev, $asked, $r);
}

# the deliverable: the whole and the byte-at-a-time feed agree
{
    my ($whole, $asked0) = events($SAMPLE, 0);
    my ($bytes, $asked1) = events($SAMPLE, 1);
    my ($halves) = events($SAMPLE, int(length($SAMPLE) / 2));
    is($asked0, 0, 'fed whole, the reader never asks for more');
    cmp_ok($asked1, '>', 100, 'fed a byte at a time it asks for more on most bytes');
    is_deeply($bytes, $whole, 'and produces the same event sequence');
    is_deeply($halves, $whole, 'so do two halves');

    my @kinds = map { $_->[0] } @$whole;
    is_deeply([ @kinds[0 .. 3] ], [FRX_DOCTYPE, FRX_PI, FRX_COMMENT, FRX_START], 'DOCTYPE, PI, comment, then the root');
    my ($dt) = grep { $_->[0] == FRX_DOCTYPE } @$whole;
    is($dt->[-1]{name}, 'doc', 'the DOCTYPE event carries the doctype');
    like($dt->[-1]{internal_subset}, qr/ENTITY greet/, 'with its subset');

    my ($root) = grep { $_->[0] == FRX_START } @$whole;
    is_deeply([ @$root[1 .. 6] ], [ 'doc', 'doc', 'urn:d', '', '', 1 ], 'the root: name, local, ns, no prefix, no value, depth 1');
    is_deeply($root->[8], [ ['', '', 'a', '1'], ['urn:p', 'p', 'b', 'two'], ['', '', 'dflt', 'd'] ], 'attributes resolved, the default appended, no xmlns');

    my @text = grep { $_->[0] == FRX_TEXT } @$whole;
    is_deeply([ map { [ $_->[5], $_->[8] ] } @text[0 .. 3] ],
              [ [ "\n  text ", undef ], [ 'hi & ', 'greet' ], [ 'there', 'greet' ], [ " more <cdata> tail\n  ", undef ] ],
              'text splits at the entity boundary and names the entity; CDATA merges with its neighbours');
    my ($b) = grep { $_->[0] == FRX_START && $_->[2] eq 'b' } @$whole;
    is($b->[6], 2, 'the element from the entity is at depth 2');
    my ($child) = grep { $_->[0] == FRX_START && $_->[2] eq 'child' } @$whole;
    is_deeply([ @$child[3, 4, 6] ], [ 'urn:p', 'p', 2 ], 'a prefixed child: namespace, prefix, depth');
    is($child->[7], index($SAMPLE, '<p:child'), 'the offset is where the tag began');
    my ($leaf) = grep { $_->[0] == FRX_START && $_->[2] eq 'leaf' } @$whole;
    ok($leaf->[9], 'an empty element start is flagged empty');
    is(scalar(grep { $_->[0] == FRX_END && $_->[2] eq 'leaf' } @$whole), 0, 'and has no end event');
    my ($pi) = grep { $_->[0] == FRX_PI && $_->[8] eq 'target' } @$whole;
    is_deeply([ @$pi[5, 6] ], [ 'data', 2 ], 'an inner PI: data and the depth of the element it is in');
    is_deeply([ map { $_->[2] } grep { $_->[0] == FRX_END } @$whole ], [qw(b child doc)], 'the end events, in order');
    is($whole->[-1][0], FRX_COMMENT, 'the trailing comment is the last event');
}

# next returns 0 before eof and undef after; a refusal dies with the stream offset
{
    my $r = File::Raw::XML::Reader->new;
    is($r->next, 0, 'nothing fed: needs more');
    $r->feed('<a>x');
    is($r->next, FRX_START, 'the start tag');
    is($r->next, 0, 'the text may go on: needs more');
    $r->feed('y</a', 0);
    is($r->next, 0, 'the text is complete but what ends it is cut, so it waits: adjacent text merges');
    $r->feed('>', 1);
    is($r->next, FRX_TEXT, 'then the text, whole');
    is($r->value, 'xy', 'across the feeds');
    is($r->next, FRX_END, 'and the end tag');
    ok(!defined $r->next, 'undef at the end');
    ok($r->done, 'done says so');

    $r = File::Raw::XML::Reader->new;
    $r->feed('<a>' . ('x' x 100));
    ok(eval { $r->next; $r->next; 1 }, 'a text run waits for its end');
    $r->feed('<b><c></b>', 1);
    ok(!eval { $r->next while 1; 1 }, 'a mismatched end tag dies');
    like($@, qr/^File::Raw::XML: end tag does not match the open element at byte offset 109 near "<\/b>"/, 'with the stream offset and context');

    $r = File::Raw::XML::Reader->new(max_token_bytes => 50);
    $r->feed('<a>' . ('x' x 30));
    is($r->next, FRX_START, 'under max_token_bytes');
    is($r->next, 0, 'waiting');
    $r->feed('y' x 30);
    ok(!eval { $r->next; 1 }, 'a token longer than max_token_bytes is refused rather than retried');
    like($@, qr/longer than max_token_bytes/, 'saying so');
    $r = File::Raw::XML::Reader->new;
    $r->feed('<a/>', 1);
    $r->next;
    ok(!eval { $r->feed('x'); 1 }, 'a feed after eof dies');
}

# a chunk boundary inside every construct the sample has: a UTF-16
# stream fed a byte at a time, and a multi-byte character cut in two
{
    require Encode;
    my $u16 = "\xFF\xFE" . Encode::encode('UTF-16LE', qq{<?xml version="1.0" encoding="UTF-16"?><r a="\x{e9}">caf\x{e9} \x{1F600}<!-- c --></r>});
    my ($whole) = events($u16, 0);
    my ($bytes) = events($u16, 1);
    is_deeply($bytes, $whole, 'a UTF-16 stream a byte at a time gives the whole stream\'s events');
    is($whole->[1][5], "caf\x{e9} \x{1F600}", 'with the characters right');
    my ($w8) = events("<r>caf\xC3\xA9 \xF0\x9F\x98\x80</r>", 0);
    my ($b8) = events("<r>caf\xC3\xA9 \xF0\x9F\x98\x80</r>", 1);
    is_deeply($b8, $w8, 'and a UTF-8 stream cut inside its sequences');
}

# strict: the same reader, no DOCTYPE
{
    my $r = File::Raw::XML::Reader->new;
    $r->feed('<!DOCTYPE a><a/>', 1);
    ok(!eval { $r->next; 1 }, 'strict refuses a DOCTYPE in the reader too');
    like($@, qr/^File::Raw::XML: DOCTYPE and every other declaration are refused/, 'with the 0.01 message');
    ok(!eval { File::Raw::XML::Reader->new(bogus => 1); 1 }, 'an unknown option dies');
}

# subtree: the element as a document, equal to the tree's node
{
    my ($ev, $asked, $r) = events($SAMPLE, 0);
    my $doc = file_xml_decode($SAMPLE, profile => 'full');
    my ($child) = $doc->root->find('urn:p', 'child');
    $r = File::Raw::XML::Reader->new(profile => 'full');
    $r->feed($SAMPLE, 1);
    my $sub;
    while (my $k = $r->next) {
        next unless $k == FRX_START && $r->local eq 'child';
        $sub = $r->subtree;
        last;
    }
    ok($sub, 'subtree at the start event returns a document');
    isa_ok($sub, 'File::Raw::XML::Document');
    is($sub->root->local, 'child', 'rooted at the element');
    is($sub->root->c14n, $child->c14n, 'exclusive canonical form equals the node\'s in place');
    is($sub->root->c14n(mode => 'inclusive'), $child->c14n(mode => 'inclusive'), 'so does inclusive: the in-scope namespaces travelled');
    is($r->next, FRX_TEXT, 'the reader continues after the subtree');
    is($r->next, FRX_START, 'with the next element');
    is($r->local, 'empty', 'which is <empty/>');
    my $e = $r->subtree;
    is($e->root->c14n, '<empty xmlns="urn:d"></empty>', 'an empty element subtree');

    # a subtree the input ends inside: undef, feed, again
    $r = File::Raw::XML::Reader->new;
    $r->feed('<r><rec a="1"><x>1</x>');
    $r->next; $r->next;
    is($r->local, 'rec', 'at the record');
    ok(!defined $r->subtree, 'subtree needs more');
    ok($r->capturing, 'and says it is capturing');
    ok(!eval { $r->next; 1 }, 'next while capturing dies');
    like($@, qr/feed and call subtree again/, 'naming the way on');
    $r->feed('<y/></rec><rec a="2"/></r>', 1);
    my $d = $r->subtree;
    ok($d, 'after the feed the subtree completes');
    is($d->root->c14n, '<rec a="1"><x>1</x><y></y></rec>', 'whole');
    is($r->next, FRX_START, 'and the reader is past it');
    is($r->attr('a'), '2', 'at the second record');
    ok(!eval { File::Raw::XML::Reader->new->subtree; 1 }, 'subtree with no event dies');
}

# the push form
{
    my (@starts, @texts, $doctype, $ends);
    file_xml_events($SAMPLE, profile => 'full',
        start   => sub { push @starts, $_[0]->local },
        text    => sub { push @texts, $_[0]->value },
        end     => sub { $ends++ },
        doctype => sub { $doctype = $_[0]->doctype->{name} },
    );
    is_deeply(\@starts, [qw(doc b child leaf empty)], 'file_xml_events: every start, in order');
    is($ends, 3, 'and every end');
    is($doctype, 'doc', 'the doctype callback');
    is(scalar @texts, 7, 'seven text events');
    ok(!eval { file_xml_events('<a><b></a>', start => sub { }); 1 }, 'a refusal dies');
    like($@, qr/^File::Raw::XML: end tag does not match/, 'as the codec would');

    # the option tail is split into callbacks and reader options
    ok(!eval { file_xml_events('<a/>', start => 'not a sub'); 1 },
       'a callback that is not a code reference is refused');
    like($@, qr/the start callback is not a code reference/, 'and says which');
    ok(!eval { file_xml_events('<a/>', 'start'); 1 }, 'an odd tail is refused');
    like($@, qr/options must be key\/value pairs/, 'in the house shape');
    ok(!eval { file_xml_events('<a/>', profile => 'sideways', start => sub { }); 1 },
       'a bad reader option is still the reader\'s to refuse');

    # a callback that dies unwinds through the loop
    ok(!eval { file_xml_events($SAMPLE, profile => 'full',
                               start => sub { die "from the callback\n" }); 1 },
       'a callback that dies stops the walk');
    is($@, "from the callback\n", 'with its own message');

    # every kind reaches the callback named for it
    my %seen;
    file_xml_events($SAMPLE, profile => 'full',
        map { my $n = $_; ($n => sub { $seen{$n}++ }) }
            qw(start end text comment pi doctype));
    is_deeply([sort keys %seen], [sort qw(start end text comment pi doctype)],
              'every event name dispatches');
}

# a reader over a file
{
    my ($fh, $path) = tempfile(UNLINK => 1);
    print {$fh} $SAMPLE;
    close $fh;
    my $r = File::Raw::XML::Reader->from_file($path, profile => 'full');
    my @ev;
    while (defined(my $k = $r->next)) { push @ev, snapshot($r, $k) }
    my ($whole) = events($SAMPLE, 0);
    is_deeply(\@ev, $whole, 'from_file gives the same events');
}

# a reader over a file of many chunks: from_file pulls 64 KiB through
# File::Raw and feeds it in C, so this is the refill loop running several
# hundred times with element and text tokens across the boundaries
{
    my ($fh, $path) = tempfile(UNLINK => 1);
    print {$fh} qq{<?xml version="1.0" encoding="UTF-8"?>\n<doc>};
    print {$fh} qq{<r n="$_">text of record $_</r>} for 1 .. 20_000;
    print {$fh} qq{</doc>};
    close $fh;
    cmp_ok(-s $path, '>', 8 * 64 * 1024, 'the file is many chunks long');

    my $r = File::Raw::XML::Reader->from_file($path);
    my ($starts, $ends, $texts, $blocked) = (0, 0, 0, 0);
    while (defined(my $k = $r->next)) {
        $blocked++, next unless $k;
        $starts++ if $k == FRX_START;
        $ends++   if $k == FRX_END;
        $texts++  if $k == FRX_TEXT;
    }
    is($starts, 20_001, 'every start, across every chunk boundary');
    is($ends,   20_001, 'and every end');
    is($texts,  20_000, 'and every text');
    is($blocked, 0, 'next never asked the caller for bytes');
    ok($r->done, 'and the document ended');
}

# subtree over a file of many chunks. The block above proves next refills
# by itself; subtree has to as well, and for a sharper reason: a reader
# from from_file owns its file, so its caller has no feed to call, and
# next refuses while a capture is open. A subtree that answered undef at
# a chunk boundary would leave the caller with nothing it could do, and a
# `while (!$doc) { $doc = $r->subtree }` loop would spin for ever.
{
    my ($fh, $path) = tempfile(UNLINK => 1);
    print {$fh} qq{<?xml version="1.0" encoding="UTF-8"?>\n<doc xmlns="urn:d">};
    # ~90 bytes a record over 20k records, so records land on chunk
    # boundaries repeatedly rather than by luck
    print {$fh} qq{<r n="$_"><name>record $_</name><body>} . ('x' x 40)
              . qq{</body></r>} for 1 .. 20_000;
    print {$fh} qq{</doc>};
    close $fh;
    cmp_ok(-s $path, '>', 8 * 64 * 1024, 'the file is many chunks long');

    my $r = File::Raw::XML::Reader->from_file($path);
    my ($seen, $sum, $undefs) = (0, 0, 0);
    while (defined(my $k = $r->next)) {
        next unless $k && $k == FRX_START && $r->local eq 'r';
        my $doc = $r->subtree;
        # bounded, so a regression fails the test instead of hanging it
        while (!$doc && !$r->done && $undefs < 1000) {
            $undefs++;
            $doc = $r->subtree;
        }
        last unless $doc;
        $seen++;
        $sum += $doc->root->attr('n');
    }
    is($seen, 20_000, 'every record came back as a subtree, across every boundary');
    is($sum, 20_000 * 20_001 / 2, 'and each one is the record it should be');
    is($undefs, 0, 'subtree never asked the caller for bytes it cannot supply');
    ok($r->done, 'and the document ended');
}

# from_file on a file that is not there
{
    ok(!eval { File::Raw::XML::Reader->from_file('/no/such/dir/nope.xml'); 1 },
       'from_file on a missing file dies');
    like($@, qr/^File::Raw::XML::Reader: cannot open /,
         'with the message it has always given');
}

# the file handle goes with the reader
{
    my ($fh, $path) = tempfile(UNLINK => 1);
    print {$fh} $SAMPLE;
    close $fh;
    # If the chunk handle outlived the reader, this would run the process
    # out of descriptors long before the end.
    for (1 .. 400) {
        my $r = File::Raw::XML::Reader->from_file($path, profile => 'full');
        $r->next;
    }
    my $r = File::Raw::XML::Reader->from_file($path, profile => 'full');
    ok(defined $r->next, 'still opening files after 400 readers went out of scope');
}

# a reader over a socketpair: more bytes than the kernel buffers, read in
# small pieces, so several feeds are needed and the reader waits between them
SKIP: {
    skip 'fork and socketpair are not the thing on MSWin32', 4 if $^O eq 'MSWin32';
    socketpair(my $child, my $parent, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or skip "socketpair: $!", 4;
    my $records = 20_000;
    my $pid = fork;
    skip "fork: $!", 4 unless defined $pid;
    if (!$pid) {
        close $parent;
        $child->autoflush(1);
        print {$child} qq{<?xml version="1.0"?>\n<log>\n};
        for my $i (1 .. $records) {
            print {$child} qq{  <rec n="$i"><name>record $i</name><body>} . ('x' x 80) . qq{</body></rec>\n};
        }
        print {$child} "</log>\n";
        close $child;
        exit 0;
    }
    close $child;
    my $r = File::Raw::XML::Reader->new;
    my ($seen, $feeds, $waits) = (0, 0, 0);
    my $done = 0;
    until ($done) {
        my $k = $r->next;
        if (!defined $k) { $done = 1; last }
        if (!$k) {
            $waits++;
            my $n = sysread $parent, my $buf, 4096;
            die "sysread: $!" unless defined $n;
            $feeds++;
            if ($n) { $r->feed($buf) } else { $r->feed('', 1) }
            next;
        }
        $seen++ if $k == FRX_START && $r->local eq 'rec';
    }
    waitpid $pid, 0;
    is($seen, $records, "every record seen over the socket ($records)");
    cmp_ok($feeds, '>', 100, "read across many feeds ($feeds)");
    cmp_ok($waits, '>', 100, "and waited for bytes as often ($waits)");
    ok($r->done, 'and the stream ended cleanly');
}

done_testing;
