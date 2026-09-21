#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;

use File::SOPS;
use File::SOPS::Format::YAML;
use File::SOPS::Format::JSON;
use File::SOPS::Backend::Age;
use Crypt::Age;
use File::Temp qw(tempdir);
use File::Slurper qw(write_binary);
use lib 't/lib';
use SopsBin qw(find_sops_bin);

###############################################################################
# The order-preserving reparse is asked of the FORMAT, not hardwired to YAML::PP
# (k74, docs/adr/0036, refining docs/adr/0001)
#
# The MAC is order dependent and the order is the DOCUMENT's. File::SOPS
# recovers it by reparsing the raw text with key order preserved and walking
# that skeleton against the real tree. That reparse used to BE a YAML::PP call
# inside File::SOPS, which is fine for the two formats YAML::PP can read and is
# nothing at all for a format it cannot: an env or ini document would fall back
# to sorted key order silently, and an env file sops wrote is in DOCUMENT
# order, so every such file whose keys are not already sorted would fail
# verification with no indication why.
#
# What this file pins is therefore not a new behaviour for YAML or JSON -- for
# those the digest must not move at all -- but the SEAM: that the order comes
# from the handler that parsed the document, that a handler which is not
# YAML-shaped can supply it, and that every way of failing still fails SAFE.
###############################################################################

my ($public, $secret) = Crypt::Age->generate_keypair();

###############################################################################
# A format handler that is not YAML and does not pretend to be.
#
# This is the shape an ENV handler has: line oriented, flat, no nesting, no
# YAML::PP anywhere near it. It is here to prove the contract stated at
# File::SOPS::_parse_in_document_order can be met from outside YAML -- and to
# show what meeting it costs, which is the tie below. Perl's plain hash has no
# key order, so "order preserving" is a tied hash and nothing else.
###############################################################################

package t::OrderedHash;
use strict;
use warnings;

sub TIEHASH  { bless { order => [], value => {}, at => 0 }, $_[0] }
sub STORE    {
    my ($self, $key, $value) = @_;
    push @{ $self->{order} }, $key unless exists $self->{value}{$key};
    $self->{value}{$key} = $value;
}
sub FETCH    { $_[0]->{value}{ $_[1] } }
sub EXISTS   { exists $_[0]->{value}{ $_[1] } }
sub DELETE   {
    my ($self, $key) = @_;
    @{ $self->{order} } = grep { $_ ne $key } @{ $self->{order} };
    delete $self->{value}{$key};
}
sub CLEAR    { $_[0]->{order} = []; $_[0]->{value} = {} }
sub FIRSTKEY { $_[0]->{at} = 0; $_[0]->{order}[0] }
sub NEXTKEY  { $_[0]->{order}[ ++$_[0]->{at} ] }
sub SCALAR   { scalar @{ $_[0]->{order} } }

package t::LineFormat;
use strict;
use warnings;

# Every top-level key, in the order the file writes them, stopping where the
# metadata starts -- WHERE the metadata sits is the handler's knowledge, and
# dropping it is the handler's job.
sub _keys_in_order {
    my ($content) = @_;
    my @keys;
    for my $line (split /\n/, $content) {
        last if $line =~ /\Asops:/;
        push @keys, $1 if $line =~ /\A([A-Za-z][A-Za-z0-9_]*):/;
    }
    return @keys;
}

sub _ordered_hash {
    my (@keys) = @_;
    my %doc;
    tie %doc, 't::OrderedHash';
    $doc{$_} = undef for @keys;
    return \%doc;
}

sub parse_in_document_order {
    my ($class, $content) = @_;
    return _ordered_hash(_keys_in_order($content));
}

# The same handler with a WRONG answer, to show the answer is actually used.
package t::ReversedLineFormat;
use strict;
use warnings;
sub parse_in_document_order {
    my ($class, $content) = @_;
    return t::LineFormat::_ordered_hash(
        reverse t::LineFormat::_keys_in_order($content));
}

# A handler that can be asked but cannot answer for this document.
package t::DeclinesOrder;
use strict;
use warnings;
sub parse_in_document_order { return }

# A handler that blows up rather than declining politely.
package t::DiesOnOrder;
use strict;
use warnings;
sub parse_in_document_order { die "no idea how to read this\n" }

# A format class that never implements the interface at all.
package t::NotAFormatHandler;
use strict;
use warnings;
sub parse { die "never called" }

package main;

# Asking a handler must never take the test file down with it: before this
# change the shipped handlers had no such method, and a bare call would abort
# the run before a single assertion was counted.
sub ordered {
    my ($class, $content) = @_;
    my $result = eval { $class->parse_in_document_order($content) };
    diag("$class->parse_in_document_order died: $@") if $@;
    return $result;
}

sub ordered_keys { ref $_[0] eq 'HASH' ? keys %{ $_[0] } : () }
sub has_key      { ref $_[0] eq 'HASH' && exists $_[0]->{ $_[1] } }

###############################################################################
# 1. Both shipped handlers answer, and the answer is document order.
###############################################################################

{
    my $yaml = "zulu:\n    yankee: 1\n    bravo: 2\nalpha: a\n"
             . "sops:\n    version: 3.13.3\n";

    my $ordered = ordered('File::SOPS::Format::YAML', $yaml);
    is(ref($ordered), 'HASH', 'YAML handler answers with a hash');
    is_deeply([ ordered_keys($ordered) ], [ qw(zulu alpha) ],
        'YAML handler gives top-level keys in DOCUMENT order, not sorted');
    is_deeply([ ordered_keys(ref $ordered eq 'HASH' ? $ordered->{zulu} : undef) ],
        [ qw(yankee bravo) ],
        'and nested keys in document order too');
    ok(!has_key($ordered, 'sops'),
        'the handler dropped the metadata, so the MAC cannot hash itself');

    # ADR 0001's decision, still true and now stated in one place: ONE
    # order-preserving reader covers both formats, and it is the YAML one.
    my $json = qq({"zulu":{"yankee":1,"bravo":2},"alpha":"a",)
             . qq("sops":{"version":"3.13.3"}});

    my $jordered = ordered('File::SOPS::Format::JSON', $json);
    is(ref($jordered), 'HASH', 'JSON handler answers with a hash');
    is_deeply([ ordered_keys($jordered) ], [ qw(zulu alpha) ],
        'JSON handler gives top-level keys in document order');
    is_deeply([ ordered_keys(ref $jordered eq 'HASH' ? $jordered->{zulu} : undef) ],
        [ qw(yankee bravo) ],
        'and nested keys in document order');
    ok(!has_key($jordered, 'sops'), 'and dropped the metadata section');
}

###############################################################################
# 2. The dispatcher asks the class it was given, and nothing else.
#
#    Before k74 there was no second argument and YAML::PP read every
#    document whatever its format was. A handler with an answer of its own is
#    the only way to tell the two apart from outside.
###############################################################################

{
    my $doc = "delta: 1\nalpha: 2\ncharlie: 3\n";

    my $mine = File::SOPS::_parse_in_document_order($doc, 't::LineFormat');
    is_deeply([ ordered_keys($mine) ], [ qw(delta alpha charlie) ],
        'the dispatcher used the handler it was given');

    my $reversed = File::SOPS::_parse_in_document_order($doc, 't::ReversedLineFormat');
    is_deeply([ ordered_keys($reversed) ], [ qw(charlie alpha delta) ],
        'a different handler gives a different answer through the same call');

    # The one-argument form still means the YAML handler, which is what read
    # both formats before the split.
    my $default = File::SOPS::_parse_in_document_order($doc);
    is_deeply([ ordered_keys($default) ], [ qw(delta alpha charlie) ],
        'no format class still resolves to the YAML handler');
}

###############################################################################
# 3. Failing safe, every way there is to fail.
#
#    Losing the order costs a fallback to sorted keys -- which can make
#    verification FAIL and can never make it wrongly SUCCEED. Every one of
#    these has to end in undef, not in an exception the caller would read as a
#    damaged file.
###############################################################################

{
    is(File::SOPS::_parse_in_document_order(undef), undef,
        'no content declines');
    is(File::SOPS::_parse_in_document_order("a: 1\n", 't::DeclinesOrder'), undef,
        'a handler that declines declines');
    is(File::SOPS::_parse_in_document_order("a: 1\n", 't::DiesOnOrder'), undef,
        'a handler that dies declines -- it does not take the read down with it');
    is(File::SOPS::_parse_in_document_order("a: 1\n\tb: 2\n"), undef,
        'text that will not parse declines');
    is(File::SOPS::_parse_in_document_order("- one\n- two\n"), undef,
        'a document that is not a mapping declines');

    # THE trap ADR 0001 and k31 both name. YAML::XS::Load in scalar
    # context returns the LAST document of a stream and YAML::PP the FIRST, so
    # a reparse that read either side in scalar context would pair one
    # document's order with another document's values -- a wrong digest, not
    # an error. docs/adr/0033 closes this by reading BOTH sides in list
    # context (parse() and parse_in_document_order alike), so document i's
    # order now pairs with document i's values structurally instead of the
    # whole stream being declined. _verify_mac's remaining safety net is a
    # count-match check between the two readers, which can only make
    # verification FAIL, never wrongly succeed -- proved against a real sops
    # file in section 3b below.
    my $stream = "a: 1\nb: 2\n---\nc: 3\nd: 4\n";
    my $stream_ordered = ordered('File::SOPS::Format::YAML', $stream);
    is_deeply($stream_ordered,
        [ { a => 1, b => 2 }, { c => 3, d => 4 } ],
        'the YAML handler returns a document LIST, one hash per document, in order');

    is_deeply(File::SOPS::_parse_in_document_order($stream), $stream_ordered,
        'and the dispatcher returns the identical list');

    is_deeply(ordered('File::SOPS::Format::JSON', $stream), $stream_ordered,
        'the JSON handler returns the same list too -- it shares the reader');
}

###############################################################################
# 3b. The trap's replacement, proved against a REAL sops multi-document file:
#     the ordered document list verifies by index against sops's own stored
#     MAC, and swapping the two documents' values (not their shape) breaks
#     verification instead of silently agreeing with the wrong pairing. This
#     is the wire lane's own manual proof (docs/adr/0033), promoted to a test.
#     Interop-gated like every other test that drives the real binary.
###############################################################################

subtest 'a real sops multi-document file verifies by index, and a swap fails' => sub {
    my $sops_bin = find_sops_bin();
    plan skip_all =>
        "No sops binary found (checked \$SOPS_BIN, PATH, .sops-bin/sops, /tmp/sops) -- "
      . "this proves the multi-document MAC pairing against the real binary, "
      . "not just against this library's own two Perl readers. Fix: run "
      . "maint/fetch-sops .sops-bin to install the pinned binary where the "
      . "suite finds it automatically, or set SOPS_BIN=/path/to/sops."
        unless $sops_bin;
    diag("Using sops binary: $sops_bin");

    my ($public, $secret) = Crypt::Age->generate_keypair();
    my $tempdir = tempdir(CLEANUP => 1);
    write_binary("$tempdir/key.txt", $secret);
    local $ENV{SOPS_AGE_KEY_FILE} = "$tempdir/key.txt";

    # Two documents sharing a key NAME but not a value -- a shape mismatch
    # would croak for an unrelated reason (_document_leaves refusing a key the
    # paired document does not have); this makes the digest itself disagree
    # instead, which is what the trap actually protects against.
    write_binary("$tempdir/two.yaml", "greeting: hello\n---\ngreeting: world\n");
    my $enc = `$sops_bin --age $public -e $tempdir/two.yaml 2>&1`;
    is($? >> 8, 0, 'sops encrypted a two-document file') or do {
        diag("sops output: $enc");
        return;
    };

    my ($first, $metadata, $documents) = File::SOPS::Format::YAML->parse($enc);
    is(scalar @$documents, 2, 'we read back both documents sops wrote');

    my $data_key = File::SOPS::Backend::Age->decrypt_data_key(
        age_keys   => $metadata->age,
        identities => [$secret],
    );

    my $ok = eval {
        File::SOPS::_verify_mac(
            document     => $enc,
            data         => $documents,
            data_key     => $data_key,
            metadata     => $metadata,
            format_class => 'File::SOPS::Format::YAML',
        );
    };
    ok($ok, "the ordered document list matches sops's own stored MAC")
        or diag($@);

    my $swapped = eval {
        File::SOPS::_verify_mac(
            document     => $enc,
            data         => [ $documents->[1], $documents->[0] ],
            data_key     => $data_key,
            metadata     => $metadata,
            format_class => 'File::SOPS::Format::YAML',
        );
    };
    my $swap_err = $@;
    ok(!$swapped, 'swapping the two documents breaks verification');
    like($swap_err, qr/MAC verification failed/,
        'and it fails as a MAC mismatch, not a shape disagreement');
};

###############################################################################
# 4. A format class that cannot do this at all is LOUD.
#
#    This is the one failure that is not a document's fault. Falling back to
#    sorted order for it would silently degrade every document in that format
#    -- precisely the env/ini defect k74 exists to prevent -- so it is an
#    error about the distribution, not about the file.
###############################################################################

{
    my $err = do {
        local $@;
        eval { File::SOPS::_parse_in_document_order("a: 1\n", 't::NotAFormatHandler') };
        $@;
    };
    like($err, qr/parse_in_document_order/,
        'a format class without the method names the missing method');
    like($err, qr/sorted key order/,
        'and says what would otherwise have happened silently');
}

###############################################################################
# 5. The order the handler returns is the order the digest is taken in.
#
#    Three verifications over ONE document, differing only in which handler
#    supplies the order. If the seam were cosmetic -- if File::SOPS still read
#    the text itself -- all three would agree.
###############################################################################

my $ENCRYPTED = File::SOPS->encrypt(
    data       => { alpha => 'one', bravo => 'two', charlie => 'three', delta => 'four' },
    recipients => [$public],
    format     => 'yaml',
);

# Every key sorts before "sops", so the metadata block is last and the data
# lines can be reordered as whole lines.
my @LINES = grep { length } split /\n/, $ENCRYPTED;
my @DATA  = grep { /\A(?:alpha|bravo|charlie|delta):/ } @LINES;
is(scalar @DATA, 4, 'fixture has four single-line data leaves to reorder');

sub verify {
    my ($document, $format_class) = @_;
    my ($data, $metadata) = File::SOPS::Format::YAML->parse($document);
    my $data_key = File::SOPS::Backend::Age->decrypt_data_key(
        age_keys   => $metadata->age,
        identities => [$secret],
    );
    local $@;
    my $ok = eval {
        File::SOPS::_verify_mac(
            document     => $document,
            data         => $data,
            data_key     => $data_key,
            metadata     => $metadata,
            format_class => $format_class,
        );
    };
    return ($ok, $@);
}

{
    # As written: File::SOPS emits sorted keys, so document order IS sorted
    # order here and every honest handler agrees.
    my ($ok, $err) = verify($ENCRYPTED, 'File::SOPS::Format::YAML');
    ok($ok, 'the document verifies through the YAML handler') or diag($err);

    ($ok, $err) = verify($ENCRYPTED, 't::LineFormat');
    ok($ok, 'and through a flat, line-oriented, non-YAML handler') or diag($err);

    # Same bytes, same values, same digest input -- in a different order.
    ($ok, $err) = verify($ENCRYPTED, 't::ReversedLineFormat');
    ok(!$ok, 'a handler that reverses the order fails verification');
    like($err, qr/MAC verification failed/, 'and fails it as a MAC mismatch');
    like($err, qr/document order/,
        'reported as document order, because an order WAS recovered');
}

###############################################################################
# 6. And the other direction: the text really is where the order comes from.
###############################################################################

{
    my $reordered = do {
        my %by_key = map { /\A([a-z]+):/ ? ($1 => $_) : () } @DATA;
        my @rest;
        my $in_sops = 0;
        for my $line (@LINES) {
            $in_sops = 1 if $line =~ /\Asops:/;
            push @rest, $line if $in_sops;
        }
        join("\n", @by_key{ qw(delta alpha charlie bravo) }, @rest) . "\n";
    };

    my ($data) = File::SOPS::Format::YAML->parse($reordered);
    is_deeply([ sort keys %$data ], [ qw(alpha bravo charlie delta) ],
        'the reordered document holds exactly the same four leaves');

    my ($ok, $err) = verify($reordered, 'File::SOPS::Format::YAML');
    ok(!$ok, 'reordering the file breaks verification');
    like($err, qr/document order/, 'and the order that was used is named');

    ($ok, $err) = verify($reordered, 't::LineFormat');
    ok(!$ok, 'the non-YAML handler reads the same reordering out of the text');

    # The fallback, reached by declining: sorted order, which is the order this
    # document's MAC was actually taken in. This is the direction that has to
    # stay safe -- a lost order costs a fallback, and the fallback is only ever
    # right for a document that was written sorted.
    ($ok, $err) = verify($reordered, 't::DeclinesOrder');
    ok($ok, 'a declining handler falls back to sorted order') or diag($err);
}

###############################################################################
# 7. Nothing above changed what an ordinary decrypt does.
###############################################################################

{
    my $data = File::SOPS->decrypt(encrypted => $ENCRYPTED, identities => [$secret]);
    is_deeply($data,
        { alpha => 'one', bravo => 'two', charlie => 'three', delta => 'four' },
        'the ordinary decrypt path still verifies and returns the document');
}

done_testing();
