package File::SOPS::Format::YAML;
# ABSTRACT: YAML format handler for SOPS
our $VERSION = '0.004';
use Moo;
use B ();
use Carp qw(carp croak);
use Scalar::Util qw(blessed dualvar refaddr);
use YAML::PP;
use YAML::PP::Parser;
use YAML::PP::Common qw( PRESERVE_ORDER YAML_PLAIN_SCALAR_STYLE );
use YAML::XS qw(Load Dump);
use File::SOPS::Encrypted;
use File::SOPS::Metadata;
use namespace::clean;

# Carp reports the caller of the frame croak stands in, and every frame between
# a caller and this module is this distribution's own: File::SOPS::encrypt calls
# emit(), emit() calls File::SOPS::Encrypted->canonical_float_tree, and the walk
# calls the guards below BACK. So a refusal named a line in Encrypted.pm -- the
# walk's own recursion -- where the house rule asks for the line the caller
# wrote encrypt() or emit() on (k71). Naming both packages here makes Carp
# walk out of them: it skips a frame when either side trusts the other, so this
# one list also fixes the guard that croaks from inside the walk.
#
# It is the frames, not the messages, that this changes. Every message still
# names the leaf's key path (k68), which is what a caller acts on.
our @CARP_NOT = qw( File::SOPS File::SOPS::Encrypted );

# 'JSON::PP' here is one of YAML::XS's own two mode names (the other is
# 'boolean'), not a module this distribution loads or talks to. It makes
# Load/Dump round-trip YAML true/false as JSON::PP::Boolean objects -- the same
# class JSON::MaybeXS blesses into on every backend. Do not "modernise" this
# string to 'JSON::MaybeXS'; YAML::XS would reject it.
#
# LOCALISED around our own calls, never assigned at load time. $YAML::XS::Boolean
# is a process-global that changes what YAML::XS::Load and ::Dump do for
# EVERYONE in the program, and setting it as a side effect of `use File::SOPS`
# silently rewrote the semantics of unrelated code that merely happened to share
# the interpreter.
our $BOOLEAN_MODE = 'JSON::PP';


sub parse {
    my ($class, $content) = @_;
    croak "content required" unless defined $content;

    local $YAML::XS::Boolean = $BOOLEAN_MODE;

    # LIST context is load-bearing, and it is the whole of the trap this ADR
    # names. YAML::XS::Load in SCALAR context returns only the LAST document of
    # a multi-document stream, so `a: 1\n---\nb: 2` parsed to just {b=>2} -- and
    # encrypt_file then wrote that back as the whole file. In LIST context @docs
    # holds every document, in order.
    #
    # sops supports multi-document YAML as ONE tree with N branches carrying ONE
    # metadata section (written into every document) and ONE MAC spanning all
    # documents in order (docs/adr/0033, k31). This method now returns the
    # DOCUMENT LIST rather than refusing above one document -- see
    # _parse_multidoc. The single-document path below is untouched, so a
    # one-document file is byte-identical to before.
    #
    # parse_in_document_order moved to a document list in the SAME commit, and
    # it had to: that reparse supplies the MAC walk's key ORDER while the tree
    # here supplies the VALUES, so if one became a list and the other did not
    # the walk would pair one document's order with another's values -- a wrong
    # MAC with no error. Both are lists now.
    #
    # The retries below exist for TWO tokens and run only after YAML::XS has
    # already refused the document. See _without_merge_tags and
    # _without_bool_tags; _refuse_unreadable_tag names the tag for the ones
    # that carry a type this module cannot reproduce, and reports libyaml's own
    # message, unchanged, for everything that is not a tag at all.
    my @docs = eval { Load($content) };
    if (my $load_error = $@) {
        my $retry = _without_redundant_tags($content);
        _refuse_unreadable_tag($content, $load_error) unless defined $retry;
        @docs = eval { Load($retry) };
        _refuse_unreadable_tag($content, $load_error) if $@;
    }

    return _parse_multidoc($content, \@docs) if @docs > 1;

    my $data = $docs[0];
    croak "YAML did not parse to a hash" unless ref $data eq 'HASH';

    my $metadata;
    if (exists $data->{sops}) {
        # The RAW section, read before from_hash and not from $metadata:
        # from_hash stores the timestamp Go RE-FORMATS (docs/adr/0044), and the
        # question here is about the text the document holds. Warns, never
        # refuses -- see _warn_plain_lastmodified for why, and for what it can
        # never fire on.
        my $section = delete $data->{sops};
        _warn_plain_lastmodified($section, $content);

        $metadata = File::SOPS::Metadata->from_hash($section);
    }

    # AFTER the split, so the sops section is never rewritten -- and after the
    # HashRef check, so there is a tree to walk. See _restring_non_finite_leaf.
    _restring_non_finite_leaves($data, {});

    # Same position shape: AFTER _restring_non_finite_leaves, because that walk
    # produces its own dualvar and reads SVf_NOK; this one reads SVf_IOK and
    # produces another dualvar. So they cannot collide, but the dualvars they
    # each leave must be the only ones anyone sees -- hence the order.
    _go_repair_int_leaves($data, {});

    # AFTER _restring_non_finite_leaves, and that order is load-bearing: the
    # walk above turns a leaf whose PUBLIC NOK and POK are both set and whose
    # NV is non-finite back into its string half, which is exactly the shape of
    # the dualvar the walk below produces. Second, it would undo this one leaf
    # for leaf.
    #
    # It runs for EVERY document, plaintext included. It used to be gated on
    # `if $metadata`, and k123 and docs/adr/0034 are why that gate is
    # gone: sops has one parse, and this had two.
    _restore_plain_infinities($data, $content);

    # The document list is [$data] for a single document, so a caller wanting a
    # uniform shape (the api lane, k31 step 4) can read the third value
    # without special-casing the count. The two-value unpacking every current
    # caller uses ignores it, so the single-document path is byte-identical.
    return ($data, $metadata, [$data]);
}

###############################################################################
# A multi-document stream, parsed into a DOCUMENT LIST (docs/adr/0033, k31)
#
# Reached only when YAML::XS::Load returned more than one document. The wire
# machinery below this -- the MAC over all documents (File::SOPS::_compute_mac,
# _verify_mac) and the order-preserving reparse (parse_in_document_order) -- is
# built to consume this list, but the public API return shape, the one-instance
# metadata attach/detach and the emitter's separators are NOT in place yet
# (k31 steps 4-5). Until they are, File::SOPS refuses a multi-document
# read or write at its own boundary rather than processing only the first
# document, which is the k14 data-loss defect this whole ticket exists to
# fix. So this returns a correct, non-corrupting list; it does not yet round
# trip.
#
# The single-document walks are run once PER DOCUMENT here, each with a fresh
# visited set -- which is what docs/adr/0033 Decision 4 requires for the
# overflow-literal (docs/adr/0023) and comment-leaf (docs/adr/0024) repairs.
sub _parse_multidoc {
    my ($content, $docs) = @_;

    my @documents;
    for my $doc (@$docs) {
        # An empty document is a real document that reads back as {} (measured;
        # `a: 1\n---\n---\nb: 2\n` is three documents to YAML::XS and to sops).
        $doc = {} unless defined $doc;

        # Every document must be a mapping. sops has a distinct multi-document
        # code path with two distinct messages -- its fingerprint -- for the two
        # non-mapping shapes; both are refused, as the single-document HashRef
        # check refuses them.
        croak "YAML documents that are sequences are not supported"
            if ref $doc eq 'ARRAY';
        croak "YAML documents that are values are not supported"
            unless ref $doc eq 'HASH';

        push @documents, $doc;
    }

    # Metadata comes from the FIRST document only (measured: a stream carrying
    # it only in a later document is `sops metadata not found` at sops). Later
    # documents' sops sections are stripped from the value trees so the walks
    # see clean document contents; the read-side policy (reject metadata that is
    # only in a later document) and the write-side one-instance attach are the
    # api lane's, k31 step 4.
    my $metadata;
    my $first = $documents[0];
    if (exists $first->{sops}) {
        my $section = delete $first->{sops};
        _warn_plain_lastmodified($section, $content);
        $metadata = File::SOPS::Metadata->from_hash($section);
    }
    delete $_->{sops} for @documents[1 .. $#documents];

    # Fresh visited set per document (docs/adr/0023, 0024 via 0033 Decision 4).
    for my $doc (@documents) {
        _restring_non_finite_leaves($doc, {});
        _go_repair_int_leaves($doc, {});
    }

    # The plain-infinity repair (docs/adr/0026) reparses the raw text and pairs
    # it against the value trees. On a stream that pairing has to be
    # document-by-document -- list context yields N reparsed documents, and the
    # single-tree pairing has no counterpart (docs/adr/0033 Decision 4).
    _restore_plain_infinities_multi(\@documents, $content);

    return ($documents[0], $metadata, \@documents);
}

###############################################################################
# The !!merge tag sops writes on a merge key (k116, docs/adr/0028)
#
# sops does not expand a YAML merge key. It reads the document into a
# yaml.Node tree, where go-yaml performs no merge resolution, so `<<` survives
# as an ordinary key -- and go-yaml's emitter then writes the tag its resolver
# assigned back out EXPLICITLY:
#
#     derived:
#         !!merge <<:
#             x: ENC[AES256_GCM,...,type:int]
#         "y": ENC[AES256_GCM,...,type:int]
#
# YAML::XS accepts exactly three tags on a scalar -- !!str, !!int, !!float --
# and dies on every other one, so this document could not be opened here at
# all: `bad tag found for scalar: 'tag:yaml.org,2002:merge'`, a parse error
# rather than a MAC error, on a file `sops -d` reads at exit 0. It is not only
# a document sops authored: measured, `sops rotate -i` on a document THIS
# library wrote with a `<<` key adds the tag, so one sops write-back was enough
# to make our own output unreadable to us.
#
# For everything below the parse the tag carries nothing. Measured against
# sops 3.13.3, `<<` is a completely ordinary key on both sides of the wire:
# it is a path component in the AAD (`derived:<<:x:` decrypts and authenticates
# the leaf under a merge key), and it is in the digest with its subtree, in the
# document's own order, exactly like any other key. So dropping the tag before
# YAML::XS sees it changes no path, no digest and no emitted byte -- the tree
# is the tree sops has.
#
# WHY TEXT AND NOT A SECOND PARSER. YAML::PP reads the tag and gives the same
# literal `<<` key, but it is not this module's parser and cannot become one
# for one class of document: types come from the parser (ADR 0002) and the two
# resolvers disagree, so a document would be typed by which tag it happened to
# carry. YAML::XS has no hook -- no tag handler, and $YAML::XS::LoadBlessed
# does not reach the yaml.org tags (measured, both settings die). What is left
# is removing a tag that is redundant by construction: a plain `<<` key
# resolves to this very tag, which is why go-yaml can add it back when reading
# our untagged output (measured, `sops -d` prints `!!merge <<:` for a document
# we wrote as `<<:`).
#
# WHY THIS TEXT SURGERY AND NOT THE ONE ADR 0019 REJECTED. There the surgery
# would have had to find an arbitrary key path at arbitrary nesting in a
# FINISHED document about to go on the wire, and a mis-hit would have written a
# corrupt file. Here the target is one fixed token in one lexical position, on
# the READ path, on a document YAML::XS has already refused -- and the
# substitution is reconciled against ground truth before its result is parsed:
# YAML::PP's PARSER (events only, no tree, no resolver) says how many
# merge-tagged scalars the document really has, and unless the substitution
# removed exactly that many, nothing is retried and libyaml's original error
# stands. That closes the mis-hit: a tag the pattern missed is still in the
# text and YAML::XS refuses again, so a successful retry with matching counts
# proves every removal landed on a real tag. The case that gets no repair is a
# tag the pattern cannot see -- flow style, or a %TAG-directive spelling --
# which sops does not write and which fails exactly as it does today.
my $MERGE_TAG = 'tag:yaml.org,2002:merge';

# Tag position, block style: the start of the node, i.e. after the line's
# indentation and after any block-sequence indicators (`- !!merge <<:`).
my $MERGE_TAG_IN_TAG_POSITION = qr/^([ \t]*(?:-[ \t]+)*)!!merge[ \t]+(?=<<[ \t]*:)/m;

sub _without_merge_tags {
    my ($content) = @_;

    # Cheapest gate first, and the only one that runs for a document that
    # failed to parse for any other reason.
    return unless $content =~ /!!merge/;

    my $wanted = _merge_tagged_scalars($content);
    return unless $wanted;

    my $stripped = $content;
    # s///g returns the empty string, not 0, when it matches nothing -- which
    # is exactly the flow-style case below, and `'' == 1` is a warning.
    my $removed  = ($stripped =~ s/$MERGE_TAG_IN_TAG_POSITION/$1/g) || 0;

    return unless $removed == $wanted;
    return $stripped;
}

# Ground truth, from the parser and not from the tree: YAML::PP's loader would
# resolve values and blur the question, its parser only reports what the
# document says. Fails safe -- a document YAML::PP refuses counts as nothing to
# repair, which leaves today's error in place rather than guessing.
sub _merge_tagged_scalars {
    my ($content) = @_;

    # YAML::XS::Load takes bytes and hands back characters; YAML::PP wants the
    # characters. Same decode as File::SOPS::_parse_in_document_order, and for
    # the same reason.
    my $text = $content;
    utf8::decode($text) unless utf8::is_utf8($text);

    my $count = 0;
    my $ok = eval {
        YAML::PP::Parser->new(receiver => sub {
            my (undef, $name, $event) = @_;
            return unless $name eq 'scalar_event';
            $count++ if ($event->{tag} // '') eq $MERGE_TAG;
        })->parse_string($text);
        1;
    };

    return unless $ok;
    return $count;
}

###############################################################################
# The OTHER yaml.org tags on a scalar (k118, docs/adr/0030)
#
# YAML::XS accepts exactly three tags on a scalar -- !!str, !!int and !!float
# -- and dies on every other one with `bad tag found for scalar`, which reads
# like a bug in a foreign library rather than a statement about the document.
# sops accepts them all, resolves them, and writes the resolved value with the
# tag gone. So a hand-written plaintext that `sops -e` encrypts at exit 0 could
# not be opened here at all. Measured, sops 3.13.3, one leaf encrypted and the
# same leaf under a `_unencrypted` key, with the stored MAC decrypted out of
# each document and reproduced here leaf by leaf:
#
#   plaintext leaf         type   ciphertext plaintext = MAC bytes   unencrypted slot
#   !!bool true            bool   True                               true
#   !!bool True            bool   True                               true
#   !!binary aGVsbG8=      str    hello                              hello
#   !!timestamp 2026-08-21 time   2026-08-21T00:00:00Z               2026-08-21T00:00:00Z
#   !!null ~               -      (not encrypted, nothing hashed)    null
#   !!str 5                str    5                                  "5"
#   !!int 0755             int    493                                493
#   !!float 1              float  1                                  1
#
# Only ONE of them carries nothing. `!!bool true` produces a document that is
# byte-identical to the one a bare `true` produces -- same type:bool, same
# plaintext `True`, and the two MAC digests measured out identical -- because a
# plain `true` resolves to this very tag on both sides. That is the same shape
# as the !!merge repair above, so it gets the same treatment: the tag is
# removed from the text and the parse is retried, reconciled against YAML::PP's
# parser so a mis-hit cannot reach libyaml.
#
# EVERY OTHER TAG HERE CARRIES A TYPE, and the type comes from the scalar in
# this distribution (ADR 0002), so removing the tag is not a no-op:
#
#   !!binary    sops base64-DECODES it. `aGVsbG8=` becomes the value `hello`.
#               Dropping the tag would encrypt the base64 text -- a different
#               value and a different digest, not a tag removal. Decoding it
#               here would be a value transformation on the wire path, which
#               is not this module's to make.
#   !!timestamp sops resolves it to a time.Time and re-renders it in RFC3339
#               under type:time. Dropping the tag leaves the SOURCE spelling as
#               a string, so `2026-08-21` would digest as `2026-08-21` here and
#               as `2026-08-21T00:00:00Z` there.
#   !!bool on a spelling libyaml does not resolve (True, False, TRUE, FALSE,
#               or a quoted `true`): sops types the leaf bool, dropping the tag
#               types it str here. The digest bytes still agree -- `True` both
#               sides -- so such a file would verify; the TYPE would not.
#   !!null on a spelling libyaml does not resolve (Null, NULL): sops makes it a
#               null, which is hashed as nothing at all; dropping the tag makes
#               it the string `Null`.
#   !!value !!set !!omap !!seq !!map on a scalar: sops leaves the text verbatim
#               under type:str, but only because the tag suppressed its own
#               resolver -- `!!value 1` is the string `1` there and would be
#               the integer 1 here.
#
# So those are REFUSED, by name, saying what sops resolves the tag to. That is
# all this changes for them: they died before and they die now, with a message
# about the document instead of one about libyaml. !!str, !!int, !!float and
# !!merge are not spoken for here -- the first three YAML::XS reads, and the
# fourth is the repair above -- so a document that fails on one of them keeps
# libyaml's own message, unchanged.

my $BOOL_TAG = 'tag:yaml.org,2002:bool';

# Same lexical position as the merge tag, plus the node itself: the tag is only
# removed from a PLAIN `true`/`false` ending the node, which is the only
# spelling measured to be equivalent. Every other spelling fails the count
# reconciliation below and lands in the refusal instead.
my $BOOL_TAG_ON_A_PLAIN_BOOLEAN = qr/
    ( ^[ \t]* (?: -[ \t]+ )* | :[ \t]+ | -[ \t]+ )
    !!bool [ \t]+
    (?= (?: true | false ) [ \t]* (?: \# | $ ) )
/mx;

sub _without_redundant_tags {
    my ($content) = @_;

    # Composed, not chained: a document may carry both, and each repair is
    # reconciled against its own count. Either one landing is enough to retry.
    my $repaired = _without_merge_tags($content);
    my $with_bools = _without_bool_tags(defined $repaired ? $repaired : $content);
    return defined $with_bools ? $with_bools : $repaired;
}

sub _without_bool_tags {
    my ($content) = @_;

    return unless $content =~ /!!bool/;

    my $wanted = _plain_boolean_tagged_scalars($content);
    return unless $wanted;

    my $stripped = $content;
    # s///g returns the empty string, not 0, when it matches nothing.
    my $removed  = ($stripped =~ s/$BOOL_TAG_ON_A_PLAIN_BOOLEAN/$1/g) || 0;

    return unless $removed == $wanted;
    return $stripped;
}

# The count is deliberately NOT "how many !!bool tags are in the document" but
# "how many of them sit on a plain true/false" -- the ones the substitution is
# allowed to touch. A document mixing `!!bool true` with `!!bool True` therefore
# has its equivalent tag removed, fails the parse again on the other one, and
# gets the refusal that names it. Fails safe like its merge twin: a document
# YAML::PP refuses counts as nothing to repair.
sub _plain_boolean_tagged_scalars {
    my ($content) = @_;

    my $text = $content;
    utf8::decode($text) unless utf8::is_utf8($text);

    my $count = 0;
    my $ok = eval {
        YAML::PP::Parser->new(receiver => sub {
            my (undef, $name, $event) = @_;
            return unless $name eq 'scalar_event';
            return unless ($event->{tag} // '') eq $BOOL_TAG;
            return unless ($event->{style} // 0) == YAML_PLAIN_SCALAR_STYLE;
            $count++ if $event->{value} eq 'true' || $event->{value} eq 'false';
        })->parse_string($text);
        1;
    };

    return unless $ok;
    return $count;
}

# Which scalar tags this module has measured and can therefore speak about, and
# for each one whether THIS scalar is readable here. A tag outside the table is
# left to libyaml.
my %TAG_IS_READABLE = (
    binary    => sub { 0 },
    timestamp => sub { 0 },
    value     => sub { 0 },
    set       => sub { 0 },
    omap      => sub { 0 },
    seq       => sub { 0 },
    map       => sub { 0 },
    bool      => sub {
        my ($event) = @_;
        return 0 unless ($event->{style} // 0) == YAML_PLAIN_SCALAR_STYLE;
        return $event->{value} eq 'true' || $event->{value} eq 'false';
    },
    null      => sub {
        my ($event) = @_;
        return $event->{value} =~ /\A(?: | ~ | null )\z/x ? 1 : 0;
    },
);

my %TAG_REFUSAL = (
    binary => 'sops resolves !!binary by base64-DECODING the scalar and '
        . 'encrypting the decoded bytes -- measured against sops 3.13.3, '
        . '`!!binary aGVsbG8=` becomes the value `hello` under type:str, and '
        . 'those decoded bytes are what its MAC covers. Removing the tag here '
        . 'would encrypt the base64 text instead: a different value, a '
        . 'different digest, and a document that disagrees with the one sops '
        . 'writes from the same plaintext. Decode the value yourself and write '
        . 'it as a plain scalar, or quote the base64 text to keep it a string '
        . 'on both sides',
    timestamp => 'sops resolves !!timestamp to a Go time.Time and re-renders '
        . 'it in RFC3339 under type:time -- measured against sops 3.13.3, '
        . '`2026-08-21` becomes `2026-08-21T00:00:00Z` and '
        . '`2001-12-14t21:59:43.10-05:00` becomes `2001-12-14T21:59:43.1-05:00` '
        . '-- and that rendering is what its MAC covers. This module has no '
        . 'date type and would keep the source spelling as a string, so the two '
        . 'would digest different bytes. Remove the tag and quote the scalar to '
        . 'make it a string on both sides, or write the RFC3339 form sops would '
        . 'have written',
    bool => 'File::SOPS supports !!bool on a plain `true` or `false`, where the '
        . 'tag carries nothing and is dropped before parsing -- measured '
        . 'against sops 3.13.3, `!!bool true` and a bare `true` produce the '
        . 'identical document, type:bool with the plaintext True, down to the '
        . 'MAC. This scalar is spelled some other way. sops also resolves '
        . 'True, False, TRUE and FALSE under the tag; libyaml leaves those a '
        . 'string, so File::SOPS would write type:str where sops writes '
        . 'type:bool. Spell the value `true` or `false`',
    null => 'File::SOPS reads !!null on `~`, `null` or an empty scalar. sops '
        . 'also resolves Null and NULL, and a null is hashed as nothing at all, '
        . 'so removing the tag would turn a value the MAC does not cover into a '
        . 'string it does. Spell the value `null`',
);

my $TAG_REFUSAL_GENERIC =
      'YAML::XS accepts only !!str, !!int and !!float on a scalar. sops '
    . 'resolves this tag and writes the resolved value without it -- measured '
    . 'against sops 3.13.3, a scalar under !!value, !!set, !!omap, !!seq or '
    . '!!map keeps its text under type:str, which is NOT what removing the tag '
    . 'would give here (`!!value 1` is the string `1` there and the integer 1 '
    . 'here). Remove the tag and write the value sops would have written';

# Runs only on a document YAML::XS has already refused. It answers from the
# document rather than from libyaml's message, which names whichever tag it
# reached first and not necessarily the one that is still there after a repair.
# No value is ever quoted back: an error message is no place for plaintext
# (the same rule every guard in this distribution follows).
sub _refuse_unreadable_tag {
    my ($content, $load_error) = @_;

    my ($where, $tag) = _first_unreadable_tag($content);
    die $load_error unless defined $tag;

    croak sprintf(
        '%s: this document tags a scalar !!%s, which File::SOPS cannot read. %s.',
        $where, $tag, ($TAG_REFUSAL{$tag} // $TAG_REFUSAL_GENERIC)
    );
}

# The key path is tracked the way the rest of this distribution paths a leaf:
# mapping keys join with a colon and a sequence contributes NO component, which
# is the AAD rule (see File::SOPS::_encrypt_tree). Fails safe -- a document
# YAML::PP cannot parse either yields no tag and leaves libyaml's message.
sub _first_unreadable_tag {
    my ($content) = @_;

    my $text = $content;
    utf8::decode($text) unless utf8::is_utf8($text);

    my (@stack, $found);
    my $close_value = sub {
        return unless @stack && $stack[-1]{kind} eq 'map';
        $stack[-1]{expect} = 'key';
    };
    my $inspect = sub {
        my ($event) = @_;
        return if $found;
        my $tag = $event->{tag} // '';
        return unless $tag =~ m{\Atag:yaml\.org,2002:(\w+)\z};
        my $short = $1;
        my $readable = $TAG_IS_READABLE{$short} or return;
        return if $readable->($event);
        my @path = map { $_->{key} } grep { defined $_->{key} } @stack;
        $found = [ (@path ? join(':', @path) : '(document root)'), $short ];
    };

    my $ok = eval {
        YAML::PP::Parser->new(receiver => sub {
            my (undef, $name, $event) = @_;
            if ($name eq 'mapping_start_event') {
                $close_value->() if @stack && $stack[-1]{kind} eq 'seq';
                push @stack, { kind => 'map', expect => 'key' };
                return;
            }
            if ($name eq 'sequence_start_event') {
                push @stack, { kind => 'seq' };
                return;
            }
            if ($name eq 'mapping_end_event' || $name eq 'sequence_end_event') {
                pop @stack;
                $close_value->();
                return;
            }
            return unless $name eq 'scalar_event' || $name eq 'alias_event';
            if (@stack && $stack[-1]{kind} eq 'map' && $stack[-1]{expect} eq 'key') {
                $inspect->($event) if $name eq 'scalar_event';
                $stack[-1]{key}    = $event->{value};
                $stack[-1]{expect} = 'value';
                return;
            }
            $inspect->($event) if $name eq 'scalar_event';
            $close_value->();
        })->parse_string($text);
        1;
    };

    return unless $ok && $found;
    return @$found;
}

###############################################################################
# A comment sops wrote as a list element (k108, k76, docs/adr/0041)
#
# sops attaches a YAML comment to the node that FOLLOWS it. Above a mapping key
# that is a `#ENC[...,type:comment]` line, which YAML::XS discards before this
# module sees it -- and sops does not hash it either, so both sides agree and
# the document reads correctly. Above a SEQUENCE entry there is no comment line
# to write, so sops emits the comment as a real element:
#
#     list:
#         - ENC[AES256_GCM,...,type:comment]
#         - ENC[AES256_GCM,...,type:str]
#
# and every parser keeps it. THIS MODULE NO LONGER GUARDS AGAINST THAT. Under
# docs/adr/0024 parse croaked on any type:comment leaf, because reading one as a
# value put a string in the caller's list that the file does not contain
# (k108). Under docs/adr/0041 the leaf is PRESERVED instead: File::SOPS
# decrypts it into a File::SOPS::Comment, keeps it at its index, leaves it out
# of the digest -- measured, that is exactly the digest sops computes -- and
# writes it back as a type:comment element. There is nothing left for a parse
# guard to catch, and the two refusals that remain are on the WRITE side, where
# the shape is one no SOPS store writes (File::SOPS::_encrypt_tree, and
# _reject_unwritable_leaf below for a comment this emitter is asked to write as
# plain text). The read-side twin of the first lives in File::SOPS::_decrypt_tree
# rather than here, because the same document is read through the JSON handler
# too -- which never had this guard, and carried k108's defect unnoticed
# the whole time (measured against sops 3.13.3: `sops -e --output-type json`
# writes type:comment leaves into JSON).
#
# Mapping-position comments are unchanged and remain the open half of k76:
# YAML::XS drops them on the way in and no emitter here can write one.

###############################################################################
# A literal libyaml numifies past the end of a double (k102, docs/adr/0023)
#
# `1e400`, a 401-digit integer, `Inf`, `NaN`: libyaml resolves each of them to a
# number, and the number it lands on is +Inf, -Inf or NaN. go-yaml resolves none
# of them -- strconv.ParseFloat answers ErrRange and yaml.v3 keeps a STRING --
# so sops writes `type:str` and digests the token's own bytes. Ours said `float`
# and digested `+Inf`, which is a document sops wrote that we cannot read and a
# value we cannot write.
#
# The repair is at PARSE time and nowhere else, because what is wrong is our
# parse result and not any guard downstream. _go_scalar_bytes already models the
# Go side correctly for all 29 spellings measured; detect_type already reads the
# SV and nothing else (ADR 0002); the non-finite guard from k59 is right
# about every value it was written for and is untouched here. What this does is
# hand the rest of the distribution the leaf go-yaml sees.
#
# The predicate is the SV, not the text (ADR 0002): a leaf whose PUBLIC SVf_NOK
# and SVf_POK are both set and whose NV is NaN or +-Inf. It cannot collide with
# the tokens Go DOES resolve to a non-finite float -- `.inf .Inf .INF +.inf
# +.Inf +.INF -.inf -.Inf -.INF .nan .NaN .NAN`, the twelve in %GO_CONSTANT --
# because YAML::XS hands every one of those back POK-ONLY. Measured against
# sops 3.13.3: those twelve are `type:float` to sops and fire nothing here; the
# 29 spellings that do fire are `type:str` to sops, every one. The two sets are
# disjoint, and that disjointness is what keeps this from retyping a leaf Go
# reads as a float.
#
# JSON is deliberately NOT walked. sops refuses such a JSON document at
# unmarshal time (`strconv.ParseFloat: value out of range`, exit 2), so the
# croak Format::JSON's leaf earns there is the reference behaviour -- see
# ADR 0020, which predicted this lever and expected it to answer for both
# parsers at once. Measured, it must not.
my $POSITIVE_INFINITY = 9**9**9;

sub _restring_non_finite_leaves {
    no warnings 'recursion';
    my ($node, $seen) = @_;

    # A recursive YAML anchor (`root: &a\n  b: *a`) really does come back from
    # YAML::XS as a cycle, so this walk carries its own visited set. That keeps
    # THIS walk terminating; the encrypt and decrypt walks do not and hang on
    # such a document today, which is k110 and not widened into here.
    return if $seen->{refaddr($node)}++;

    if (ref $node eq 'HASH') {
        for my $key (keys %$node) {
            ref $node->{$key}
                ? _restring_non_finite_leaves($node->{$key}, $seen)
                : _restring_non_finite_leaf($node->{$key});
        }
    }
    elsif (ref $node eq 'ARRAY') {
        for my $entry (@$node) {
            ref $entry
                ? _restring_non_finite_leaves($entry, $seen)
                : _restring_non_finite_leaf($entry);
        }
    }

    return;
}

# $_[0] is the caller's element by alias, deliberately: the flags are read off
# the SV the tree holds rather than off a copy, and the replacement is written
# back into the same slot. Nothing here numifies anything -- B reads the NV and
# the PV out of the SV's own slots, so this cannot retype a scalar the way a
# numeric comparison on it would (k32).
sub _restring_non_finite_leaf {
    return unless defined $_[0];

    my $sv    = B::svref_2object(\$_[0]);
    my $flags = $sv->FLAGS;
    return unless ($flags & B::SVf_NOK()) && ($flags & B::SVf_POK());

    my $nv = $sv->NV;
    return unless $nv != $nv
        || $nv == $POSITIVE_INFINITY
        || $nv == -$POSITIVE_INFINITY;

    # The string half is what go-yaml kept, so it is what replaces the number.
    # An empty one is not a token Go reads as anything but a null, and there is
    # nothing to hand back, so the leaf is left exactly as it came.
    my $pv = $sv->PV;
    return unless length $pv;

    $_[0] = $pv;
    return;
}

###############################################################################
# A bare leading-zero integer libyaml and Go disagree about (k127, docs/adr/0054)
#
# `v: 0755` is parsed by YAML::XS as a Perl dualvar: POK with PV="0755", IOK
# with IV=755. go-yaml's resolver reads `0755` through strconv.ParseInt(_, 0, 64),
# which interprets a leading zero as octal and reads it as 493. sops digests the
# bytes Go produced -- so a document f-sops wrote (data:"755") and a document
# sops wrote (data:"493") were both verified by their own readers, and neither
# could read the other; on a wire that crosses implementations the encrypted-slot
# value was silently different.
#
# The fix is the same shape _restring_non_finite_leaves uses -- a tree walk that
# reads the SV's own flags and rewrites the integer leaves whose PV is a bare
# leading-zero token, leaving a non-disagreeing leaf alone. The whole scalar is
# replaced with the integer Go reads, dropping the source spelling: a
# dualvar(493, "0755") is exactly the shape Encrypted::assert_representable
# refuses (a value that carries its own, different string form), so carrying
# the PV across would just trade today's silent value divergence for today's
# loud dualvar refusal. The repaired leaf is a plain integer Go's number, the
# digest covers Go's number, the emitter writes Go's number, and the whole
# chain is one value the MAC covers and sops reads -- which is the entire
# shape the encrypted slot has been missing, and the unencrypted slot gets as
# a side effect because the slot is the slot the parse handed back.
#
# PREDICATE, measured, on eight spellings of the same family:
#
#   "0755"  POK+IOK+PV="0755"+IV=755  => becomes 493, plain int   (the ticket)
#   "010"   POK+IOK+PV="010"+IV=8     => already agrees, no-op
#   "017"   POK+IOK+PV="017"+IV=15    => already agrees, no-op
#   "007"   POK+IOK+PV="007"+IV=7     => already agrees (7 is 7 in both bases)
#   "0o10"  POK-only (PV="0o10")      => predicate skips, no repair (string PV)
#   "0x1f"  POK-only (PV="0x1f")      => predicate skips, no repair
#   "1_000" POK-only (PV="1_000")     => predicate skips, no repair (string PV)
#   "0755e0" POK+IOK+NOK+PV="0755e0" => predicate skips (not bare integer syntax)
#
# So the predicate is exactly: scalar with SVf_IOK, PV present, PV matches
# /\A[+-]?0\d+\z/, _go_scalar_bytes(PV) returns a decimal that does not equal
# IV. Anything else is left alone. The mirror order to the call below is
# exactly the order from _restring_non_finite_leaves -- AFTER the non-finite
# repair, which can produce its own dualvar and which reads NOK+POK, never IOK,
# so the two predicates do not collide.

sub _go_repair_int_leaves {
    no warnings 'recursion';
    my ($node, $seen) = @_;

    return if $seen->{refaddr($node)}++;

    if (ref $node eq 'HASH') {
        for my $key (keys %$node) {
            ref $node->{$key}
                ? _go_repair_int_leaves($node->{$key}, $seen)
                : _go_repair_int_leaf($node->{$key});
        }
    }
    elsif (ref $node eq 'ARRAY') {
        for my $entry (@$node) {
            ref $entry
                ? _go_repair_int_leaves($entry, $seen)
                : _go_repair_int_leaf($entry);
        }
    }

    return;
}

# $_[0] is the caller's slot by alias, deliberately, and the rewrite is
# written back into the same place. The PV is dropped, not kept as a dualvar:
# a dualvar(493, "0755") is exactly the shape Encrypted::assert_representable
# refuses (a "value that carries its own, different string form" -- YAML::XS
# writes the string half, the digest covers the int, and the two disagree).
# So the repaired scalar is a plain integer Go's number, with no public PV,
# and the assert_representable check at Encrypted.pm line 1596 skips it
# entirely: _has_public_pv is false and the int branch is bypassed. The same
# is what sops itself does on the parse side -- it loses the source spelling
# of `0755` because Go's resolver reads it as the integer 493, and that is
# the trailing edge of k127.
sub _go_repair_int_leaf {
    return unless defined $_[0] and !ref $_[0];

    my $sv = B::svref_2object(\$_[0]);
    return unless $sv->FLAGS & B::SVf_IOK;

    my $pv = $sv->PV;
    return unless length $pv;
    return unless $pv =~ /\A[+-]?0\d+\z/;

    my $go_bytes = _go_scalar_bytes($pv);
    return unless defined $go_bytes && $go_bytes =~ /\A-?\d+\z/;
    return if $go_bytes + 0 == $sv->IV;       # already agrees; no-op

    $_[0] = $go_bytes + 0;
    return;
}

###############################################################################
# A YAML infinity the DOCUMENT wrote plain (k105, docs/adr/0026)
#
# The mirror image of the walk above, and it needs a different authority.
# libyaml leaves `.inf` a STRING; gopkg.in/yaml.v3 resolves it to the float
# +Inf, and sops digests `+Inf`. So a document sops writes and `sops -d`
# verifies failed its MAC here, naming nothing.
#
# What makes this repair unlike every other one in this distribution is that
# the missing fact is NOT in the SV. Measured against sops 3.13.3, one
# unencrypted slot per row:
#
#   v_unencrypted: .inf      Go: float +Inf,  digested `+Inf`   <- we digested `.inf`
#   v_unencrypted: ".inf"    Go: string,      digested `.inf`   <- we agree, today
#
# and YAML::XS hands back the SAME POK-only scalar for both. Both spellings
# also occur in ONE document as easily as in two -- measured, sops writes this
# and reads it back at exit 0:
#
#   list_unencrypted:
#       - .inf          <- digested `+Inf`
#       - ".inf"        <- digested `.inf`
#
# So a repair keyed on the leaf's TEXT fixes the first row and silently breaks
# the second, which works today. The question is not what the value is; it is
# whether the document wrote the scalar PLAIN, and that is a fact about the
# bytes.
#
# YAML::PP -- already this distribution's second parser (ADR 0001) -- answers
# it. Its Core schema resolves a scalar to a non-finite number IFF the scalar
# was written plain and its token is one of the twelve in %GO_CONSTANT.
# Measured: 12 of 12 plain tokens yes; 0 of 24 quoted; 0 of 12 near misses
# (`.INf` `.iNF` `.Nan` `.NAn` `+.nan` `-.nan` `-.NAN` `.infinity` `.Infinity`
# `Inf` `inf` `NaN`), every one of which is a type:str to sops and reads
# correctly here today. On the WIRE -- which is what this path sees -- sops has
# already normalised `!!float .inf` and `&a .inf` to a bare `.inf` and
# `!!str .inf` and `'.inf'` to a quoted `".inf"`, so only those two spellings
# arrive, and the oracle separates them in all four cases.
#
# This is NOT the "ask YAML::PP instead of modelling Go" that ADR 0013 and
# ADR 0023 rejected. There the question was what a value IS, and YAML::PP
# answers it the way libyaml does -- `0755` is 755 to both and 493 to Go, so it
# agrees with the side that is already wrong. Here it is asked whether a scalar
# was written plain, which is syntax rather than resolution; the VALUE still
# comes from %GO_CONSTANT, and the token has to be in %GO_CONSTANT before
# YAML::PP is consulted at all.
#
# FOR EVERY DOCUMENT, PLAINTEXT INCLUDED (k123, docs/adr/0034). This was
# gated on a `sops:` section until 0.003, on the argument that a plaintext has
# no MAC for a foreign reader to disagree with and that ADR 0013's guard gives
# a better error on the encrypt path anyway -- "a worse message for no gain,
# since neither path can write the document".
#
# ADR 0031 removed the premise: an unencrypted YAML slot holding one of these
# tokens IS written now, byte-identical to what sops writes. So the gate was
# refusing three documents this library can produce, and the two parses
# disagreed about identical bytes -- measured, `decrypt_file` wrote
# `v_unencrypted: .inf` and `encrypt_file` refused to read its own output back.
# sops resolves a plain scalar the same way on every parse; so does this now.
#
# WHAT IS WRITTEN BACK is a dualvar, not a bare infinity, and that is measured
# rather than tidy: YAML::XS writes a bare non-finite NV as `Inf` / `-Inf` /
# `NaN`, tokens go-yaml resolves as STRINGS, and writes dualvar(+Inf, '.inf')
# as `.inf`, the token sops itself writes. So decrypt_file reproduces sops's
# own plaintext byte for byte instead of degrading the value on the first
# round trip. Same shape as ADR 0011's carrier: a float leaf whose string half
# is the text the document contains.
#
# Since k113 (docs/adr/0031) such a document is written back as well: the
# non-finite guard lets a leaf carrying one of these tokens through to
# ADR 0013's foreign-resolution guard, which measures the token the emitter
# really writes. An ENCRYPTED slot is still refused there (k122).
my $PLAIN_STYLE_LOADER = YAML::PP->new(schema => [qw( Core )]);

sub _restore_plain_infinities {
    my ($data, $content) = @_;

    # The cheapest gate first, and a sound one: a PLAIN scalar is literal text,
    # so a token this walk could repair is in the raw bytes or it is nowhere.
    # The only way the string `.inf` reaches a leaf without those four bytes
    # being in the document is an escape in a QUOTED scalar, which this walk
    # does not repair anyway -- so the pre-filter can only be conservative in
    # the direction that changes nothing. A document that never mentions one
    # pays a single scan and no tree walk at all.
    return unless _go_non_finite_in_text($content);

    # Then the tree, because `config.info` and `.infrastructure` carry those
    # bytes too: one flag per leaf and, for a leaf starting `.`, `+` or `-`,
    # one hash lookup. YAML::PP parses nothing unless a candidate is really
    # there.
    return unless _has_plain_infinity_candidate($data, {});

    # FAIL SAFE, deliberately: YAML::PP is a second parser and refuses things
    # YAML::XS accepts. Measured, the one that really occurs is a recursive
    # anchor -- `Found cyclic ref for alias 'a'` where YAML::XS hands back a
    # real Perl cycle -- and such a document is refused downstream anyway
    # (k110). Nothing is repaired then, which is exactly today's behaviour
    # and today's MAC error, never a partially repaired tree whose digest would
    # be wrong in a new way.
    my $theirs = eval { $PLAIN_STYLE_LOADER->load_string($content) };
    return unless ref $theirs eq 'HASH';
    delete $theirs->{sops};

    # Collected first and applied only if the two trees turned out structurally
    # identical, for the same reason.
    my @fix;
    return unless _pair_plain_infinities($data, $theirs, \@fix, {});

    for my $entry (@fix) {
        my ($slot, $token) = @$entry;
        $$slot = dualvar(_go_non_finite_double($token), $token);
    }

    return;
}

# The multi-document counterpart of _restore_plain_infinities (docs/adr/0033
# Decision 4, ADR 0026). The single-document version reparses $content in scalar
# context, which yields the FIRST document only -- on a stream that would pair
# the first reparsed document against every value tree. Here the reparse is in
# LIST context, N documents, and each is paired against its own value tree by
# index. Everything else is the single-document version's mechanism unchanged:
# the same pre-filters, the same structural pairing that abandons the whole
# repair on any disagreement, the same fail-safe on a document YAML::PP refuses.
sub _restore_plain_infinities_multi {
    my ($documents, $content) = @_;

    return unless _go_non_finite_in_text($content);

    my $any = 0;
    for my $doc (@$documents) {
        $any = 1, last if _has_plain_infinity_candidate($doc, {});
    }
    return unless $any;

    # FAIL SAFE, as in the single-document path: a document YAML::PP refuses
    # yields nothing, and nothing is repaired -- today's behaviour and today's
    # MAC error, never a partially repaired tree.
    my @theirs = eval { $PLAIN_STYLE_LOADER->load_string($content) };
    return unless @theirs == @$documents;
    for my $t (@theirs) {
        # An empty document reparses to undef; treat it as {} the way the value
        # side does, so the structural pairing lines up.
        $t = {} unless defined $t;
        return unless ref $t eq 'HASH';
    }
    # The value trees had `sops` stripped from every document; strip it from
    # every reparsed document too, or the key-set comparison in
    # _pair_plain_infinities would disagree on the metadata-bearing ones.
    delete $_->{sops} for @theirs;

    my @fix;
    for my $i (0 .. $#$documents) {
        return unless _pair_plain_infinities($documents->[$i], $theirs[$i],
                                             \@fix, {});
    }

    for my $entry (@fix) {
        my ($slot, $token) = @$entry;
        $$slot = dualvar(_go_non_finite_double($token), $token);
    }

    return;
}

sub _has_plain_infinity_candidate {
    my ($node, $seen) = @_;

    if (ref $node eq 'HASH') {
        return 0 if $seen->{refaddr($node)}++;
        _has_plain_infinity_candidate($node->{$_}, $seen) and return 1
            for keys %$node;
        return 0;
    }
    if (ref $node eq 'ARRAY') {
        return 0 if $seen->{refaddr($node)}++;
        _has_plain_infinity_candidate($_, $seen) and return 1 for @$node;
        return 0;
    }
    return 0 if ref $node;
    return defined _plain_infinity_token($node);
}

# The two trees walked side by side, the way _document_leaves already pairs the
# ordered reparse against the real one (ADR 0001). Any disagreement about shape
# -- a container against a leaf, a different key set, a different length --
# abandons the whole repair rather than guessing which side is right.
sub _pair_plain_infinities {
    my ($ours, $theirs, $fix, $seen) = @_;

    if (ref $ours eq 'HASH') {
        return 0 unless ref $theirs eq 'HASH';
        return 1 if $seen->{refaddr($ours)}++;
        return 0 unless keys %$ours == keys %$theirs;
        for my $key (keys %$ours) {
            return 0 unless exists $theirs->{$key};
            return 0
                unless _pair_plain_infinities($ours->{$key}, $theirs->{$key},
                                              $fix, $seen);
            my $token = _plain_infinity_leaf($ours->{$key}, $theirs->{$key});
            push @$fix, [ \$ours->{$key}, $token ] if defined $token;
        }
        return 1;
    }

    if (ref $ours eq 'ARRAY') {
        return 0 unless ref $theirs eq 'ARRAY';
        return 1 if $seen->{refaddr($ours)}++;
        return 0 unless @$ours == @$theirs;
        for my $i (0 .. $#$ours) {
            return 0
                unless _pair_plain_infinities($ours->[$i], $theirs->[$i],
                                              $fix, $seen);
            my $token = _plain_infinity_leaf($ours->[$i], $theirs->[$i]);
            push @$fix, [ \$ours->[$i], $token ] if defined $token;
        }
        return 1;
    }

    # A leaf on our side has to be a leaf on theirs, or the trees do not
    # describe the same document and nothing here can be trusted.
    return ref($theirs) ? 0 : 1;
}

# $_[0] is OUR leaf and $_[1] is YAML::PP's, both by alias: the flags come off
# the SVs the trees hold rather than off copies, and B reads the NV and the PV
# out of the SV's own slots. Nothing numifies anything, so this cannot retype a
# scalar the way a numeric comparison on it would (k32).
sub _plain_infinity_leaf {
    return undef unless defined $_[0] && !ref $_[0];
    return undef unless defined $_[1] && !ref $_[1];

    # Ours has to be a plain string -- what YAML::XS returns for all twelve
    # tokens. A leaf that already carries a number is not one of them.
    my $ours = B::svref_2object(\$_[0]);
    my $flags = $ours->FLAGS;
    return undef unless $flags & B::SVf_POK();
    return undef if $flags & (B::SVf_NOK() | B::SVf_IOK());

    my $token = $ours->PV;
    return undef unless defined _go_non_finite_double($token);

    # And theirs has to be the non-finite number, which is how YAML::PP says
    # `this scalar was written plain`.
    my $theirs = B::svref_2object(\$_[1]);
    return undef unless $theirs->FLAGS & B::SVf_NOK();
    my $nv = $theirs->NV;
    return undef unless $nv != $nv
        || $nv == $POSITIVE_INFINITY
        || $nv == -$POSITIVE_INFINITY;

    return $token;
}

# The gate's own predicate, without a second tree to pair against.
sub _plain_infinity_token {
    return undef unless defined $_[0];

    my $flags = B::svref_2object(\$_[0])->FLAGS;
    return undef unless $flags & B::SVf_POK();
    return undef if $flags & (B::SVf_NOK() | B::SVf_IOK());

    my $token = B::svref_2object(\$_[0])->PV;
    return undef unless $token =~ /\A[-+.]/;
    return defined _go_non_finite_double($token) ? $token : undef;
}

###############################################################################
# A `lastmodified` the DOCUMENT wrote plain (k159, docs/adr/0050)
#
# The mirror of _quote_sops_timestamp below, on the read side. That one exists
# because YAML::XS emits an RFC3339 timestamp bare and go-yaml resolves a bare
# RFC3339 scalar to a time.Time, where sops's decoder wants a string:
#
#   decoding failed due to the following error(s):
#   'lastmodified' expected type 'string', got unconvertible type 'time.Time'
#
# So this library has never WRITTEN such a document. It has always READ one,
# and k144 / docs/adr/0044 could not close that from Metadata.pm: a bare
# and a quoted scalar arrive at from_hash as the same Perl string. The missing
# fact is not in the SV, it is in the bytes -- the same shape as
# _restore_plain_infinities above, and the reason both live in this file.
#
# THE MECHANISM IS NOT ADR 0026's, though. There YAML::PP is asked as a
# RESOLVER: its Core schema answers `+Inf` for a plain `.inf` and the string
# `.inf` for a quoted one, so the resolution IS the plain/quoted answer. That
# does not carry here, measured: YAML 1.2's Core schema has no timestamp type,
# so YAML::PP hands back the same Perl string for `lastmodified: 2026-08-21T...`
# and `lastmodified: "2026-08-21T..."`. What carries is the QUESTION, and
# YAML::PP's parser answers it directly -- the scalar event's style, the same
# oracle _plain_boolean_tagged_scalars already uses for the !!bool retry.
#
# WHAT IS REFUSED IS NOTHING. This warns, and that is the measured choice
# rather than the timid one. Every write path here re-stamps and quotes the
# timestamp, so `rotate` on such a document produces one `sops -d` reads at
# exit 0 -- measured. A refusal would take the one tool that can still repair
# the file and make the file unopenable by every tool, which in a secrets
# library is a worse outcome than the divergence it closes.
#
# THE GUARD NEVER FIRES ON A DOCUMENT SOPS READS, which is k145's
# condition and the reason that ticket was closed unimplemented. Measured
# against sops 3.13.3, one document per spelling, each carrying a `mac` built
# under the AAD ADR 0044 derives:
#
#   * all 15 RFC3339 spellings sops accepts QUOTED (exit 0) are refused BARE
#     (exit 1, `unconvertible type 'time.Time'`) -- there is no accepted bare
#     one to warn about wrongly;
#   * `!!str 2026-08-21T09:05:08Z` -- bare, but TAGGED -- is exit 0 at sops,
#     because an explicit tag stops go-yaml's implicit resolver before
#     parseTimestamp runs. Hence the tag check below; without it this guard
#     would fire on a document sops reads, which is the whole thing k145
#     was protecting.
#
# The two places where _go_timestamp and go-yaml's own parseTimestamp were
# measured to disagree both land in the safe direction: `...09:05:08,123Z` (a
# comma fraction) is a timestamp to go-yaml and not to this model, so the
# guard stays quiet on a document sops refuses; `...09:05:08+25:00` is a
# timestamp to this model and a string to go-yaml, so the guard fires on a
# document sops refuses anyway -- for the other of its two reasons.
sub _warn_plain_lastmodified {
    my ($section, $content) = @_;

    # The cheapest gate first: no metadata, or a `lastmodified` that is not a
    # scalar, and there is nothing a plain/quoted question could be about.
    # ADR 0043 refuses a reference here further down the read path.
    return unless ref $section eq 'HASH';
    my $text = $section->{lastmodified};
    return unless defined $text && !ref $text;

    # Then the model, which is a regex and no parse: go-yaml only resolves a
    # scalar to a timestamp when parseTimestamp takes it, and _go_timestamp is
    # this module's measured reimplementation of that (see _go_scalar_bytes,
    # where the emit-side guard asks the same question of the same tokens).
    return unless defined _go_timestamp($text);

    # Only then the second parser, and only for the style of one scalar.
    return unless _plain_lastmodified($content);

    carp "sops:lastmodified: this timestamp is written as a PLAIN scalar. "
        . "gopkg.in/yaml.v3 resolves a bare RFC3339 scalar to a Go time.Time "
        . "where sops's decoder wants a string, so sops refuses this whole "
        . "document before decrypting anything -- measured against sops "
        . "3.13.3: `'lastmodified' expected type 'string', got unconvertible "
        . "type 'time.Time'`. Nothing here is affected: the values and the MAC "
        . "are read normally, and every file this library writes quotes the "
        . "timestamp, so re-encrypting the document (rotate, edit, "
        . "encrypt_in_place, or decrypt_file plus encrypt_file) repairs it. "
        . "Quoting the line by hand does the same";

    return;
}

# Was the `sops` section's `lastmodified` value written as a plain scalar?
# 1 yes, 0 no, undef for "this parser could not say" -- an unreadable document,
# or no such key in that position at all.
#
# Ground truth from the PARSER, not from a regex over the text and not from a
# tree: a plain scalar may sit on the line below its key, inside a flow
# mapping, or behind an explicit `? key`, and all three are the ordinary YAML
# a hand edit produces. Measured over 17 spellings, the event stream places
# every one of them; the value's own bytes are never looked at.
#
# A TAGGED scalar answers 0 whatever its style. go-yaml runs parseTimestamp
# only for an untagged node, so `!!str 2026-08-21T09:05:08Z` is a string there
# and sops reads the document at exit 0 -- measured. The one tag that would
# resolve to a timestamp, `!!timestamp`, never reaches here: YAML::XS refuses
# it at parse and %TAG_REFUSAL names it (docs/adr/0032).
#
# An ALIAS answers 0 as well. `lastmodified: *t` carries the anchor's resolved
# type in go-yaml, so it CAN be a time.Time there, but the event carries no
# style of its own and nothing here would be measuring the right scalar. A
# quiet miss on a document sops refuses is this guard's safe direction.
#
# Fails safe like its merge and !!bool twins: a document YAML::PP will not read
# answers undef, which leaves today's behaviour exactly in place.
sub _plain_lastmodified {
    my ($content) = @_;

    # YAML::XS::Load takes bytes and hands back characters; YAML::PP wants the
    # characters. Same decode as parse_in_document_order, for the same reason.
    my $text = $content;
    utf8::decode($text) unless utf8::is_utf8($text);

    # One frame per open collection, innermost last. @key holds the key each
    # mapping frame is currently on, so the target is recognised by position:
    # the value of `lastmodified` in the mapping that is the value of `sops`
    # in the root mapping -- never a user's own `lastmodified` somewhere else.
    my (@kind, @expect_key, @key);
    my ($plain, $done);

    my $ok = eval {
        YAML::PP::Parser->new(receiver => sub {
            my (undef, $name, $event) = @_;
            return if $done;

            if ($name eq 'mapping_start_event' || $name eq 'sequence_start_event') {
                _consume_node_slot(\@kind, \@expect_key, \@key, undef);
                push @kind, $name eq 'mapping_start_event' ? 'map' : 'seq';
                push @expect_key, 1;
                push @key, undef;
                return;
            }
            if ($name eq 'mapping_end_event' || $name eq 'sequence_end_event') {
                pop @kind; pop @expect_key; pop @key;
                return;
            }
            # The one-document rule is parse()'s, held here independently: a
            # second document's `sops` section is not the one that was read.
            if ($name eq 'document_end_event') {
                $done = 1;
                return;
            }
            return unless $name eq 'scalar_event' || $name eq 'alias_event';

            my $slot = _consume_node_slot(\@kind, \@expect_key, \@key,
                $name eq 'scalar_event' ? $event->{value} : undef);
            return unless ($slot // '') eq 'value';
            return unless @kind == 2
                && $kind[0] eq 'map'
                && ($key[0] // '') eq 'sops'
                && ($key[1] // '') eq 'lastmodified';

            $plain = $name eq 'scalar_event'
                && !defined $event->{tag}
                && ($event->{style} // 0) == YAML_PLAIN_SCALAR_STYLE ? 1 : 0;
        })->parse_string($text);
        1;
    };

    return unless $ok;
    return $plain;
}

# One node has started. Tell the enclosing mapping whether it is that
# mapping's key or its value, and advance it; a sequence element is neither.
# Returns 'key', 'value' or undef for "not inside a mapping".
sub _consume_node_slot {
    my ($kind, $expect_key, $key, $scalar) = @_;

    return undef unless @$kind && $kind->[-1] eq 'map';

    if ($expect_key->[-1]) {
        # A complex key -- `? [a, b] : v` -- has no name this walk can use, and
        # undef is not a key any sops document writes, so it matches nothing.
        $key->[-1] = $scalar;
        $expect_key->[-1] = 0;
        return 'key';
    }

    $expect_key->[-1] = 1;
    return 'value';
}


###############################################################################
# The order-preserving reparse behind MAC verification (docs/adr/0001, 0036)
#
# The MAC is order dependent and the order is the DOCUMENT's, which a Perl hash
# cannot carry. File::SOPS recovers it by reparsing the raw text with key order
# preserved and walking that skeleton against the real tree. This is the half
# of the mechanism that has to know the format, so it lives here rather than in
# File::SOPS -- see parse_in_document_order's POD for the contract a handler
# has to meet.
#
# YAML::PP supplies ORDER AND NOTHING ELSE. Values still come from parse()'s
# tree, so a scalar this loader resolves differently from YAML::XS cannot reach
# the digest -- which is why the boolean mode below is set for consistency and
# not because anything reads what it produces.
my $ORDERED_LOADER = YAML::PP->new(
    boolean  => 'JSON::PP',
    preserve => PRESERVE_ORDER,
);

sub parse_in_document_order {
    my ($class, $content) = @_;
    return unless defined $content;

    # YAML::XS::Load hands back decoded characters, so the reparse has to
    # decode too or a non-ASCII key would not match its twin in the tree.
    my $text = $content;
    utf8::decode($text) unless utf8::is_utf8($text);

    # LIST context, matching parse(): the two loaders disagree ONLY in scalar
    # context on a multi-document stream (YAML::PP->load_string returns the
    # FIRST document, YAML::XS::Load the LAST), and the MAC walk takes its order
    # from here and its values from parse()'s tree. Both read the stream in list
    # context now, so document i's order is paired with document i's values
    # (docs/adr/0033, k31). A stream that cannot be read this way still
    # declines to nothing, which falls back to sorted order -- can make
    # verification fail, never wrongly succeed.
    my @docs = eval { $ORDERED_LOADER->load_string($text) };
    return unless @docs;

    # The metadata MAC lives in the `sops` mapping and must not hash itself.
    # WHERE it sits is format knowledge, so the handler drops it structurally
    # (the same way parse() does) rather than by pattern-matching "mac:" in the
    # raw text -- which used to swallow any user key ending in "mac". On a
    # stream sops writes an identical block into every document, so it is
    # dropped from every document here.
    for my $doc (@docs) {
        # An empty document reparses to undef; {} keeps it a real, empty
        # document so its shape lines up with the value tree's.
        $doc = {} unless defined $doc;
        return unless ref $doc eq 'HASH';
        delete $doc->{sops};
    }

    # A single document stays a bare HashRef, byte-identical to before, so every
    # existing caller and test is unaffected. A stream is returned as an
    # ArrayRef of ordered documents -- an unambiguous reference in any context,
    # which File::SOPS::_parse_in_document_order pairs against the value trees.
    return @docs == 1 ? $docs[0] : \@docs;
}


sub serialize {
    my ($class, %args) = @_;
    my $data     = $args{data}     // croak "data required";
    my $metadata = $args{metadata} // croak "metadata required";

    # A stream is an ArrayRef of encrypted document trees; a single document is a
    # bare HashRef and stays byte-identical -- a one-element list attaches the
    # same one metadata block and emits through the same Dump call (docs/adr/0033
    # Decision 1, k31). The SAME metadata is written into EVERY document,
    # byte-identical (same age blob, lastmodified and mac), which is the exact
    # inverse of the read-side detach in parse/_parse_multidoc (point 1). An
    # empty document is a real document and STILL gets its own metadata block
    # (point 6): here it is `{}` and comes out carrying only the `sops:` section.
    my @docs = ref $data eq 'ARRAY' ? @$data : ($data);
    croak "data required" unless @docs;

    # to_hash once, so every document gets a byte-identical block rather than N
    # freshly built ones that only happen to match.
    my $section = $metadata->to_hash;

    my @output;
    for my $doc (@docs) {
        # The metadata goes into `sops`, so a value already there would be
        # overwritten -- and since the digest was computed over the tree BEFORE
        # serialization, the document that came out failed its own MAC. Refuse
        # instead, as sops does (exit 203). See File::SOPS::encrypt. Checked per
        # document, so a `sops` key in any document of a stream is refused.
        croak "data contains a top-level 'sops' entry, which is where the SOPS "
            . "metadata section goes"
            if exists $doc->{sops};

        push @output, { %$doc, sops => $section };
    }

    # The timestamp fixup applies to the metadata section only, so it sits here
    # rather than in emit -- a plaintext document has no `sops:` block to fix. On
    # a stream it rewrites the bare RFC3339 lastmodified inside EVERY `sops:`
    # block: it already resets its state at each column-0 line, so a `---`
    # separator and each later document's `sops:` are handled the same as the
    # first.
    #
    # mac_covered turns on the foreign-resolution guard (k86, ADR 0013):
    # this document carries a MAC, and sops recomputes that MAC from the values
    # ITS parser resolves out of these bytes.
    #
    # For mac_only_encrypted the digest covers encrypted values only, so an
    # unencrypted leaf cannot make such a document disagree with its own MAC and
    # refusing it would refuse a document that works today -- measured, sops -d
    # exit 0. It still reads 493 out of a `0755` this module reads as 755, so
    # the same check runs there and WARNS instead (k87, ADR 0018).
    return _quote_sops_timestamp($class->emit(
        @output == 1 ? $output[0] : \@output,
        $metadata->mac_only_encrypted ? (warn_foreign_resolution => 1)
                                      : (mac_covered            => 1)));
}

# YAML::XS emits plain (unquoted) scalars for anything its resolver does not
# recognise as a YAML core-schema type. $YAML::XS::QuoteNumericStrings (on by
# default) already covers numbers, booleans and nulls -- '3.8', '123', 'true'
# and 'null' all come out quoted -- but the resolver has no notion of
# timestamps, so an RFC3339 lastmodified is emitted bare.
#
# Go's yaml.v3 DOES resolve a bare RFC3339 scalar, to time.Time, and sops then
# refuses the whole file before it decrypts anything:
#
#   decoding failed due to the following error(s):
#   'lastmodified' expected type 'string', got unconvertible type 'time.Time'
#
# sops itself writes lastmodified: "2026-08-08T21:28:58Z" -- quoted. YAML::XS
# exposes no per-scalar style control (no tag, no forced-quote hook), so the
# only way to get a quoted scalar out of this emitter is to quote it after the
# dump. Kept deliberately narrow: it rewrites one key, only inside the
# top-level `sops:` block, so a user's own `lastmodified:` in the data section
# is never touched. JSON needs none of this -- JSON has no timestamp type and
# its strings are always quoted.
sub _quote_sops_timestamp {
    my ($yaml) = @_;

    my @lines = split /\n/, $yaml, -1;
    my $in_sops = 0;

    for my $line (@lines) {
        if ($line =~ /\A sops : \s* \z/x) {
            $in_sops = 1;
            next;
        }
        # any other column-0 line ends the sops block (Dump sorts keys, so a
        # data key sorting after "sops" can follow it)
        $in_sops = 0 if $in_sops && $line =~ /\A\S/;
        next unless $in_sops;

        # already-quoted values are left alone
        $line =~ s{
            \A (\s+ lastmodified: [ \t]+) (?!['"]) (\S.*?) [ \t]* \z
        }{$1"$2"}x;
    }

    return join "\n", @lines;
}


# The one place this distribution turns a Perl tree into YAML. serialize() is
# this plus the metadata section, and File::SOPS::_serialize_plaintext (what
# decrypt_file writes and what edit hands the editor) is this on its own.
#
# It stays ONE sub because the emitter options are not local taste: the MAC's
# encrypt side walks the tree in sorted order and is correct only because this
# emitter writes keys sorted, and the boolean mode decides whether a
# JSON::PP::Boolean reaches the file as `true` or as
# `!!perl/scalar:JSON::PP::Boolean 1`. A second copy of those options is a
# second answer to a question that has one -- which is what k35 found: the
# plaintext emitter used to work only because this module set
# $YAML::XS::Boolean process-wide at load time.
#
# Consequence, deliberately accepted: this sub is on the wire path. Changing
# what it emits changes the encrypted document too, so it is not a plaintext
# formatting knob.
# The safely-quotable non-finite spellings (docs/adr/0070), scoped to EXACTLY
# the seven ADR 0038/0039 measured. A str leaf whose value is one of these came
# unambiguously from a QUOTED source or a caller's own Perl string, because
# _restore_plain_infinities (docs/adr/0026, 0034) already resolved a bare one to
# a float at parse -- so writing it double-quoted states the type it already
# has, and sops writes and reads the same bytes (measured, sops -d exit 0). The
# other five non-finite tokens in %GO_CONSTANT (`+.Inf +.INF -.Inf -.INF .NAN`)
# are deliberately NOT here: the corpus did not measure them, and "no wider than
# the nine rows" keeps them refused as they are today.
my %QUOTABLE_NON_FINITE =
    map { $_ => 1 } ( '.inf', '.Inf', '.INF', '+.inf', '-.inf', '.nan', '.NaN' );

sub emit {
    my ($class, $data, %args) = @_;
    croak "data required" unless defined $data;

    # A multi-document stream is an ArrayRef of document trees (docs/adr/0033,
    # k31). A bare HashRef is one document and stays byte-identical.
    my @docs = ref $data eq 'ARRAY' ? @$data : ($data);
    croak "data required" unless @docs;

    # Only a document that a reader re-derives values from has anything to
    # disagree with. serialize sets one of these; the plaintext emitters
    # (decrypt_file, edit) set neither, and must not -- refusing there would
    # refuse to WRITE OUT a document this module reads correctly, and warning
    # would warn about a file with no MAC and no second reader. The two differ in
    # the verdict only: croak where the MAC covers the leaf, carp where
    # mac_only_encrypted means it does not. See docs/adr/0013 and docs/adr/0018.
    my $reject_scalar =
        $args{mac_covered}             ? \&_reject_foreign_resolution
      : $args{warn_foreign_resolution} ? \&_warn_foreign_resolution
      :                                  undef;

    # Force-quoting runs on EVERY path except mac_only_encrypted (warn):
    #
    #   * MAC-covered (docs/adr/0070): a divergent leaf makes the file fail its
    #     own MAC (the non-finite class) or silently retypes a caller's string
    #     (the True/False class), and quoting the safe subset is what lets such a
    #     document be written at all.
    #   * Plaintext -- decrypt_file, edit (k186): sops writes `".inf"` and
    #     `"True"` double-quoted, and without this the plaintext emitter wrote
    #     them bare, so a decrypt_file -> re-encrypt round trip flipped the leaf
    #     from string to float/bool (a bare `.inf` resolves to +Inf at the next
    #     parse, docs/adr/0026). Quoting the same safe subset makes the plaintext
    #     emitter a faithful inverse of what sops wrote.
    #
    # The mac_only_encrypted (warn) path is the one exception, kept as ADR 0070
    # left it: there the document already works and the leaf is not MAC-covered,
    # so its bytes are unchanged. Neither the MAC-covered digest (computed over
    # the original tree before emit) nor the plaintext output (never hashed) has
    # a digest quoting could move, so this is safe on every path it runs.
    my $force_quote = !$args{warn_foreign_resolution};

    return _emit_docs($class, \@docs, $reject_scalar) unless $force_quote;

    # Replace exactly the safely-quotable divergent leaves (the True/False type
    # divergence, and the seven parse-unambiguous non-finite str leaves) with
    # unique random sentinels, in a COPY of each document. A sentinel is an
    # ordinary string the guard passes; every OTHER divergent leaf is left in
    # place and still reaches the guard below and is refused. The digest was
    # computed over the original tree in File::SOPS::_compute_mac before emit, so
    # this copy touches no digest byte and no key's sort position.
    my %sentinel;
    my @quoted = map {
        _sentinel_quotable_leaves($docs[$_], \%sentinel, [], $_)
    } 0 .. $#docs;

    # Nothing to quote -> today's single Dump, byte-identical.
    return _emit_docs($class, \@docs, $reject_scalar) unless %sentinel;

    # The guard runs here on the sentinel'd copy. A remaining non-safe divergent
    # leaf croaks exactly as today -- a refused document is refused whether or not
    # it also held a quotable leaf -- and that croak propagates unchanged.
    my $yaml = _emit_docs($class, \@quoted, $reject_scalar);

    # Surgery + FAIL-CLOSED verification (docs/adr/0070). On any miss the whole
    # surgery is abandoned and the ORIGINAL tree is emitted the old way, which
    # reproduces today's exact refusal/carp for these leaves. A file that failed
    # verification is never shipped.
    my $surgical = _quote_sentinels($yaml, \%sentinel);
    return defined $surgical ? $surgical
                             : _emit_docs($class, \@docs, $reject_scalar);
}

# The one Dump call, unchanged from before docs/adr/0070. Each document is run
# through canonical_float_tree on its own, so each keeps its own sorted key order
# (the MAC's encrypt side rides on that, docs/adr/0001); YAML::XS::Dump then emits
# the whole list as one stream, prepending `---` to EVERY document -- N documents
# joined by `---` with no leading empty document, which is the separator rule
# (docs/adr/0033 point 5). $reject_scalar is the caller's foreign-resolution
# guard, or undef for a plaintext emit.
sub _emit_docs {
    my ($class, $docs, $reject_scalar) = @_;

    local $YAML::XS::Boolean = $BOOLEAN_MODE;
    return Dump(map {
        File::SOPS::Encrypted->canonical_float_tree(
            $_,
            roundtrips => \&_float_roundtrips,
            carrier    => \&_float_carrier,
            reject     => \&_reject_unwritable_leaf,
            ($reject_scalar ? (reject_scalar => $reject_scalar) : ()),
        )
    } @$docs);
}

# docs/adr/0070: a COPY of $node with every safely-quotable leaf replaced by a
# unique random sentinel, recording sentinel => { value, doc, path } for the
# post-Dump surgery. Containers are rebuilt (new hashes/arrays); leaves are
# shared, so the caller's tree is never mutated. No cycle guard: canonical_float_tree
# has none either, so a cyclic document already hangs downstream (k110) and
# this adds no new behaviour there.
sub _sentinel_quotable_leaves {
    no warnings 'recursion';
    my ($node, $sentinel, $path, $doc) = @_;

    if (ref $node eq 'HASH') {
        return { map {
            push @$path, $_;
            my $r = _sentinel_quotable_leaves($node->{$_}, $sentinel, $path, $doc);
            pop @$path;
            ($_ => $r);
        } keys %$node };
    }
    if (ref $node eq 'ARRAY') {
        return [ map {
            push @$path, $_;
            my $r = _sentinel_quotable_leaves($node->[$_], $sentinel, $path, $doc);
            pop @$path;
            $r;
        } 0 .. $#$node ];
    }

    return $node unless _is_quotable_leaf($node, $path);

    my $token = _fresh_sentinel($sentinel);
    $sentinel->{$token} = { value => $node, doc => $doc, path => [ @$path ] };
    return $token;
}

# Is this leaf one of docs/adr/0070's nine safely-quotable rows? Reuses the
# guard's own verdict, so there is no second model of Go:
#
#   * a `type` divergence -- True/False, a str here and a bool to Go. The digest
#     bytes already agree (`True` both sides), so quoting is MAC-neutral and only
#     removes the divergence (docs/adr/0019). Measured: _foreign_resolution_token
#     returns 'type' for exactly True/False and nothing else, because any other
#     spelling Go reads as a bool (TRUE, FALSE) disagrees on bytes and is 'mac'.
#   * a `mac` divergence whose token is one of the seven spellings
#     %QUOTABLE_NON_FINITE holds and whose leaf is a str -- unambiguously from a
#     quoted or caller source (docs/adr/0026, 0034), so quoting states its real
#     type.
#
# Everything else -- the sixteen ambiguous rows, an int/float `0755`, and every
# adversarial neighbour -- returns 0 and is left for the guard.
sub _is_quotable_leaf {
    my ($leaf, $path) = @_;
    return 0 unless defined $leaf;

    my ($token, $kind) = _foreign_resolution_token($leaf, $path, undef);
    return 0 unless defined $token;

    return 1 if $kind eq 'type';
    return 1 if $kind eq 'mac'
             && $QUOTABLE_NON_FINITE{$token}
             && File::SOPS::Encrypted->detect_type($leaf) eq 'str';
    return 0;
}

# A unique random 128-bit sentinel token. Spaceless and alphanumeric, so
# YAML::XS emits it BARE and on ONE line at any depth (a YAML plain scalar folds
# only at a space, and there is none), and its first byte `S` is one Go's
# resolver never looks at, so the guard passes it as an ordinary string.
# Collision with document text is astronomically improbable at 128 bits AND
# caught by the occurrence-count check in _quote_sentinels, which fails closed.
sub _fresh_sentinel {
    my ($sentinel) = @_;
    my @hex = (0 .. 9, 'a' .. 'f');
    while (1) {
        my $token = 'SOPSQUOTE'
            . join('', map { $hex[int rand 16] } 1 .. 32)
            . 'ENDSOPSQUOTE';
        return $token unless exists $sentinel->{$token};
    }
}

# The generalisation of _quote_sops_timestamp: replace each sentinel token in the
# finished YAML with the original value rendered as a double-quoted scalar, then
# verify FAIL CLOSED. Returns the surgical text, or undef to fall back to today's
# refusal/carp -- never a document that did not verify.
#
# Two checks, both of which docs/adr/0070 requires:
#   1. each sentinel occurs exactly once (0 or >1 abandons the whole surgery --
#      the 0 case is the only way a spaceless sentinel could go missing, e.g. an
#      emitter that folded it, and a >1 the only way a 128-bit token could
#      collide);
#   2. the finished document re-Loads and each forced leaf, at its recorded
#      position, is byte-for-byte the original string.
# The second is stronger than a count: it reads the emitted bytes back the way a
# reader will, so a substitution that produced a different value cannot pass.
sub _quote_sentinels {
    my ($yaml, $sentinel) = @_;

    my $out = $yaml;
    for my $token (keys %$sentinel) {
        my $count = () = ($out =~ /\Q$token\E/g);
        return undef unless $count == 1;
        my $quoted = _yaml_double_quote($sentinel->{$token}{value});
        $out =~ s/\Q$token\E/$quoted/;
    }

    my @back = do {
        local $YAML::XS::Boolean = $BOOLEAN_MODE;
        my @d = eval { Load($out) };
        return undef if $@ || !@d;
        @d;
    };

    for my $token (keys %$sentinel) {
        my $entry = $sentinel->{$token};
        return undef unless $entry->{doc} <= $#back;
        my $leaf = _navigate_path($back[$entry->{doc}], $entry->{path});
        return undef unless defined $leaf && !ref $leaf;
        return undef unless $leaf eq $entry->{value};
    }

    return $out;
}

# Walk a re-Loaded tree to the leaf at $path (hash keys and array indices
# interleaved, as _sentinel_quotable_leaves recorded them). undef on any
# structural surprise, which fails the verification closed.
sub _navigate_path {
    my ($node, $path) = @_;
    for my $step (@$path) {
        return undef unless ref $node;
        if (ref $node eq 'HASH') {
            return undef unless exists $node->{$step};
            $node = $node->{$step};
        }
        elsif (ref $node eq 'ARRAY') {
            return undef unless $step <= $#$node;
            $node = $node->[$step];
        }
        else { return undef }
    }
    return $node;
}

# The original value as a YAML double-quoted scalar that Loads back to the exact
# string. The nine safe rows are all plain ASCII (`.inf`, `True`, ...), so the
# escape branches below are defensive: a value with a space, quote, backslash or
# control character never reaches here, because _emitted_plain_scalar returns
# undef for it (it is not a bare token) and _is_quotable_leaf then returns 0.
sub _yaml_double_quote {
    my ($s) = @_;
    my $out = $s;
    $out =~ s/\\/\\\\/g;
    $out =~ s/"/\\"/g;
    $out =~ s/\t/\\t/g;
    $out =~ s/\n/\\n/g;
    $out =~ s/\r/\\r/g;
    $out =~ s/([\x00-\x08\x0b\x0c\x0e-\x1f])/sprintf('\\x%02X', ord $1)/ge;
    return '"' . $out . '"';
}

# A referenced leaf YAML::XS cannot write as the text the digest covers.
#
# detect_type calls every blessed leaf but a JSON::PP::Boolean `str`, so the
# digest covers its STRINGIFICATION. YAML::XS writes it as a Perl-specific
# tagged structure instead -- measured against sops 3.13.3, one document per
# row, leaf under _unencrypted:
#
#   Math::BigFloat->new("1.5")  !!perl/hash:Math::BigFloat + guts   exit 51
#   bless {a=>1}, 'Foo'         !!perl/hash:Foo + guts              exit 51
#   an object overloading ""    !!perl/hash:Overloaded + guts       exit 51
#   bless \$s, 'Bar'            !!perl/scalar:Bar x                 exit 51
#   sub { 1 }                   !!perl/code '{ "DUMMY" }'           exit 51
#   \1  (unblessed)             !!perl/ref + `=: 1`                 exit 51
#   qr/abc/                     !!perl/regexp (?^:abc)              exit 0 (!)
#
# All seven fail their own MAC check here. qr// is the one sops accepts, because
# yaml.v3 resolves the unknown tag to the scalar text -- which is what we
# digested -- while YAML::XS reconstructs a Regexp from it, so File::SOPS cannot
# read back what it just wrote. Both halves of the same disagreement.
#
# JSON has refused all of these since before ADR 0006 (Cpanel::JSON::XS will not
# encode a blessed reference without allow_blessed/convert_blessed/allow_tags),
# which is the asymmetry this closes. See docs/adr/0008.
#
# The exception is the EXACT class, not ->isa: detect_type accepts a
# JSON::PP::Boolean subclass as bool, but YAML::XS writes one as
# `!!perl/scalar:MyBool 1` while the digest still says True -- the same defect
# wearing the whitelist. The exact class is what $YAML::XS::Boolean = 'JSON::PP'
# knows how to write, so it is the only reference that survives this emitter.
#
# Unblessed refs are in scope deliberately: \1 and a coderef fail identically,
# and the callback already has them in hand.
#
# Not in assert_representable: that runs on the verify side too, and over
# leaves that are about to become ENC[...] strings. A blessed leaf in an
# ENCRYPTED slot works in both formats today (type:str, plaintext = the same
# stringification) and must keep working.
#
# $where is the leaf's key path from canonical_float_tree, in the shape the MAC
# walk's messages already use. It goes in FRONT of the message: the class alone
# told a caller what was wrong and left finding it a manual search (k68).
sub _reject_unwritable_leaf {
    my ($node, $where) = @_;

    return if ref($node) eq 'JSON::PP::Boolean';

    # A comment leaf reaching the emitter AS A VALUE. Two ways in, and the
    # answer is the same for both: an unencrypted slot in a document being
    # serialized (sops leaves such a comment as a plain `# ...` LINE, measured),
    # and a PLAINTEXT emit -- decrypt_file and edit -- where every leaf is
    # written as itself. YAML::XS can write neither, having no way to emit a
    # comment at all; and a comment line written into an editor's buffer would
    # be dropped by YAML::XS on the way back in, so writing one would be a
    # silent loss rather than a round trip. Its own message, because the
    # !!perl/-tagged-structure sentence below is true of it and tells the caller
    # nothing. See docs/adr/0041.
    croak "$where: cannot write a sops comment into this document. A comment "
        . "is a leaf only where it is ENCRYPTED into a sequence entry -- the "
        . "one shape sops writes -- and this document would have to carry it "
        . "as plain text, which YAML::XS cannot emit as a comment (it has no "
        . "way to write one) and would not read back as a comment either. "
        . "That is why decrypt_file and edit refuse a document with a comment "
        . "in it rather than dropping the comment on the way through: use "
        . "decrypt, which hands back the comment as a File::SOPS::Comment, or "
        . "read the file with sops"
        if File::SOPS::Encrypted->is_comment($node);

    my $what = blessed($node) ? "a leaf blessed into " . ref($node)
                              : "an unblessed " . ref($node) . " reference";

    croak "$where: cannot write $what to a SOPS document: YAML::XS writes it "
        . "as a Perl-specific !!perl/ tagged structure while the digest covers its "
        . "stringification, so the document and its own MAC would state "
        . "different things and neither sops nor this module could read the "
        . "file. Pass a plain Perl scalar, or the string you want stored. A "
        . "boolean has to be an exact JSON::PP::Boolean (JSON->true / "
        . "JSON->false); a subclass of it is written as a tag as well";
}

###############################################################################
# The reader on the other side of the file (k86, docs/adr/0013)
#
# Everything above asks THIS distribution's emitter what it does. This asks what
# Go's gopkg.in/yaml.v3 -- the parser sops uses -- makes of the bytes we are
# about to write, because sops recomputes the MAC from the values ITS parser
# resolves. YAML::XS is libyaml, whose resolver is YAML 1.1 as libyaml
# implements it; yaml.v3's is neither 1.1 nor 1.2 but its own. Where the two
# land on different values, the document and its own MAC state different things.
#
# Measured against sops 3.13.3, leaf under _unencrypted, one document per row:
#
#   source   we read        Go reads    sops -d
#   0755     int 755        493         exit 51    <- `mode: 0755`, the real case
#   010      int 10         8           exit 51
#   007      int 7          7           exit 0     <- agrees, 7 is 7 in both bases
#   08       int 8          float 8     exit 0     <- agrees, same digest bytes
#   0o10     str "0o10"     int 8       exit 51    <- the mirror case: WE say str
#   0x1f     str            int 31      exit 51
#   1_000    str            int 1000    exit 51
#   .inf     str            +Inf        exit 51
#   Null     str            null        exit 51
#   TRUE     str            bool        exit 51
#   True     str "True"     bool        exit 0     <- agrees, Go digests `True`
#   2015-01-01            str  time     exit 51    <- rendered 2015-01-01T00:00:00Z
#   2015-01-01T12:00:00Z  str  time     exit 0     <- rendered identically
#
# sops itself resolves a plaintext `mode: 0755` to the INTEGER 493 and writes
# that, so the spelling never survives a `sops -e` -- which is why the read path
# needs nothing here, and why the message can name 493 as what to pass instead.
#
# This is NOT typing by text (ADR 0002). detect_type still reads the SV and
# nothing else, and this runs after it. What is inspected here is what a foreign
# parser will make of bytes -- a question the SV cannot answer, because the SV is
# on this side of the file. _quote_sops_timestamp two hundred lines up has
# matched a text pattern in the emitted document for the same reason since 0.003.

# Go's resolveTable: the first byte decides whether the resolver looks at a
# plain scalar at all. Anything else is a string to it, immediately -- which is
# what keeps `localhost` and `supersecret` from paying for any of this.
my $GO_LOOKS_AT = qr/\A[-+.0-9yYnNtTfFoO~]/;

# Go's resolveMap, mapped to the bytes sops's ToBytes derives from each value.
# A bool is Title-cased (the same rule Encrypted::value_to_bytes follows) and a
# null contributes nothing -- measured: a sops-written `x_unencrypted: null`
# verifies against this module's own digest, which covers the empty string.
my %GO_CONSTANT = (
    'true'  => 'True',  'True'  => 'True',  'TRUE'  => 'True',
    'false' => 'False', 'False' => 'False', 'FALSE' => 'False',
    ''      => '',      '~'     => '',
    'null'  => '',      'Null'  => '',      'NULL'  => '',
    '.inf'  => '+Inf',  '.Inf'  => '+Inf',  '.INF'  => '+Inf',
    '+.inf' => '+Inf',  '+.Inf' => '+Inf',  '+.INF' => '+Inf',
    '-.inf' => '-Inf',  '-.Inf' => '-Inf',  '-.INF' => '-Inf',
    '.nan'  => 'NaN',   '.NaN'  => 'NaN',   '.NAN'  => 'NaN',
);

# The DOUBLE go-yaml resolves one of those tokens to, or undef for a token it
# does not resolve to a number at all. Derived from %GO_CONSTANT's own byte
# string rather than from a second list of spellings: there is one token list
# in this module, and a copy of it is how a repair and the guard it depends on
# drift apart (ADR 0002's defect class, and k89's shape one level down).
#
# It lives HERE rather than beside its caller because it reads %GO_CONSTANT,
# and a `my` hash is not in scope above its own declaration. See
# _restore_plain_infinities, k105 and docs/adr/0026.
# The four bytes a repairable token cannot be written without. Built from the
# same %GO_CONSTANT keys, so widening that table widens this with it.
my $GO_NON_FINITE_TEXT = do {
    my @token = grep { $GO_CONSTANT{$_} =~ /\A(?:[-+]Inf|NaN)\z/ } keys %GO_CONSTANT;
    my %tail  = map  { (substr($_, -4) => 1) } @token;
    my $alt   = join '|', map { quotemeta } sort keys %tail;
    qr/(?:$alt)/;
};

sub _go_non_finite_in_text {
    return $_[0] =~ $GO_NON_FINITE_TEXT ? 1 : 0;
}

sub _go_non_finite_double {
    my ($token) = @_;

    my $bytes = $GO_CONSTANT{$token};
    return undef unless defined $bytes;

    return  $bytes eq '+Inf' ?  $POSITIVE_INFINITY
          : $bytes eq '-Inf' ? -$POSITIVE_INFINITY
          : $bytes eq 'NaN'  ?  $POSITIVE_INFINITY - $POSITIVE_INFINITY
          :                     undef;
}

# strconv.ParseInt/ParseUint with base 0, as a digit string. The magnitude is
# accumulated in Perl's own integer space, guarded by a STRING comparison
# against the base's uint64 maximum -- dividing to test for overflow is exactly
# where a double stops being exact, and a wrong answer here is a document
# refused or written for the wrong reason.
my %GO_BASE_MAX = (
    2  => '1111111111111111111111111111111111111111111111111111111111111111',
    8  => '1777777777777777777777',
    10 => '18446744073709551615',
    16 => 'ffffffffffffffff',
);
my $INT64_MAGNITUDE = 9223372036854775808;   # 2**63: int64 min is -this

sub _go_digits {
    my ($digits, $base) = @_;

    (my $d = lc $digits) =~ s/\A0+(?=.)//;
    my $max = $GO_BASE_MAX{$base};
    return undef if length($d) > length($max);
    return undef if length($d) == length($max) && $d gt $max;

    my $v = 0;
    $v = $v * $base + index('0123456789abcdef', $_) for split //, $d;
    return $v;
}

# undef: not an integer to Go. 'RANGE': an integer it reads as a uint64, which
# sops has no case for -- measured, `sops -e` on a plaintext 9223372036854775808
# fails with `Cannot walk value, unknown type: uint64`, exit 23. Otherwise the
# decimal text sops would digest.
sub _go_int {
    my ($p) = @_;

    my $neg = ($p =~ s/\A-//) ? 1 : 0;
    $p =~ s/\A\+//;
    return undef unless length $p;

    my $v;
    if    ($p =~ /\A0[xX]([0-9a-fA-F]+)\z/) { $v = _go_digits($1, 16) }
    elsif ($p =~ /\A0[bB]([01]+)\z/)        { $v = _go_digits($1, 2) }
    elsif ($p =~ /\A0[oO]([0-7]+)\z/)       { $v = _go_digits($1, 8) }
    elsif ($p =~ /\A0([0-7]*)\z/)           { $v = _go_digits($1, 8) }
    elsif ($p =~ /\A[1-9][0-9]*\z/)         { $v = _go_digits($p, 10) }
    else                                    { return undef }

    return undef unless defined $v;         # past uint64: Go falls through to float
    # `-0` is the integer 0 to Go, sign and all: strconv.Itoa(0) is `0`, and a
    # document holding `-0` verifies against a digest covering `0` (measured,
    # exit 0). The sign only survives on a FLOAT, which is ADR 0006's -0.0.
    return $neg && $v ? "-$v" : "$v"
        if $neg ? $v <= $INT64_MAGNITUDE : $v < $INT64_MAGNITUDE;
    return undef if $neg;                   # ParseUint rejects a sign
    return 'RANGE';
}

# strconv.ParseFloat, through the one conversion this distribution has for a
# double. The CANONICAL TEXT decides whether Go got a number, never a numeric
# comparison of the scalar: `$nv == 0` sets the public IOK on an integral NV and
# takes the sign off -0.0 with it, which is ADR 0002's contamination in the one
# place that must not have it.
#
# The copy is pack/unpack for the same reason, and this one was learned twice.
# It was `value_to_bytes($p * 1.0)` until k89, and Perl's arithmetic settles
# a token like `-0.0e0` on its INTEGER path: the model answered 0, this module
# answered 0, the guard saw agreement, and a document sops -d rejects with exit
# 51 was written silently. A model that shares a conversion with the code it
# checks can only catch the cases where the two happen to differ. Measured, the
# same token scalar three times in one process:
#
#   $p * 1.0    0 | 0 | 0        0 + $p     0 | 0 | 0
#   $p * 1      0 | 0 | 0        $p - 0.0   0 | 0 | 0
#   unpack('d', pack('d', $p))   -0 | -0 | -0
#
# `-0.0` WITHOUT an exponent survives `* 1.0` as an NV, which is why the guard
# was right for it and why this gap outlived ADR 0013. See ADR 0015 and the
# k89 amendment in ADR 0013.
sub _go_float {
    my ($p) = @_;

    my $bytes = File::SOPS::Encrypted->value_to_bytes(unpack('d', pack('d', $p)));
    return undef if $bytes =~ /\A[-+]Inf\z/;   # Go: ErrRange, so not a float to it
    return $bytes;
}

# Go's parseTimestamp: four layouts, and sops digests what comes out of it as
# RFC3339 NANO -- always a capital T, `Z` for a zero offset, and a fractional
# second that keeps at most nine digits and no trailing zero. So a token agrees
# with itself only when it is already spelled exactly that way; every other shape
# Go PARSES renders differently, and every shape it does not parse is a string to
# it and agrees for free. Measured, leaf under _unencrypted:
#
#   2015-01-01T12:00:00Z            exit 0    <- already RFC3339
#   2015-01-01T12:00:00.5Z          exit 0    <- Nano keeps the fraction
#   2015-01-01T12:00:00.123456789Z  exit 0
#   2015-01-01T12:00:00.50Z         exit 51   <- trailing zero trimmed
#   2015-01-01T12:00:00.0Z          exit 51   <- fraction disappears entirely
#   2015-01-01T12:00:00.1234567891Z exit 51   <- truncated to nine digits
#   2015-01-01T12:00:00+00:00       exit 51   <- a zero offset renders as Z
#   2015-01-01                      exit 51   <- becomes 2015-01-01T00:00:00Z
#   2015-1-01T12:00:00Z             exit 51   <- a short field is padded
#   2016-02-29                      exit 51   <- a real date, so it is parsed
#   2015-02-29                      exit 0    <- not a date, so Go leaves a string
#   2015-01-01T24:00:00Z            exit 0    <- hour 24: same, a string
#
# The calendar check is what tells 2016-02-29 from 2015-02-29 -- one is a date
# and the other is not -- and it is why `2024-13-45` and `1234-5678` are not
# refused either.
sub _go_timestamp {
    my ($s) = @_;

    my ($y, $mo, $d, $h, $mi, $sec, $frac, $zone);
    if ($s =~ /\A([0-9]{4})-([0-9]{1,2})-([0-9]{1,2})[Tt]([0-9]{1,2}):([0-9]{1,2}):([0-9]{1,2})(?:\.([0-9]+))?(Z|[-+][0-9]{2}:[0-9]{2})\z/) {
        ($y, $mo, $d, $h, $mi, $sec, $frac, $zone) = ($1, $2, $3, $4, $5, $6, $7, $8);
    }
    elsif ($s =~ /\A([0-9]{4})-([0-9]{1,2})-([0-9]{1,2}) ([0-9]{1,2}):([0-9]{1,2}):([0-9]{1,2})(?:\.([0-9]+))?\z/) {
        ($y, $mo, $d, $h, $mi, $sec, $frac, $zone) = ($1, $2, $3, $4, $5, $6, $7, 'Z');
    }
    elsif ($s =~ /\A([0-9]{4})-([0-9]{1,2})-([0-9]{1,2})\z/) {
        ($y, $mo, $d, $h, $mi, $sec, $frac, $zone) = ($1, $2, $3, 0, 0, 0, undef, 'Z');
    }
    else { return undef }

    return undef if $mo < 1 || $mo > 12 || $d < 1 || $h > 23 || $mi > 59 || $sec > 59;
    my @length = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
    my $last = $mo == 2 && (($y % 4 == 0 && $y % 100 != 0) || $y % 400 == 0)
        ? 29 : $length[$mo - 1];
    return undef if $d > $last;

    my $nano = '';
    if (defined $frac) {
        (my $digits = substr($frac, 0, 9)) =~ s/0+\z//;
        $nano = ".$digits" if length $digits;
    }
    $zone = 'Z' if $zone =~ /\A[-+]00:00\z/;
    return sprintf('%04d-%02d-%02dT%02d:%02d:%02d%s%s',
                   $y, $mo, $d, $h, $mi, $sec, $nano, $zone);
}

# The bytes sops digests for this token when it stands BARE in a YAML document,
# or undef for "this module cannot prove what Go does with it".
#
# A model, and treated as one: written from yaml.v3's resolve() and sops's
# ToBytes, and verified branch by branch against the binary rather than trusted.
# There is no oracle to ask instead -- the reader is in another process, in
# another language, and YAML::PP, this distribution's second parser, resolves
# 0755 as 755 like libyaml and unlike Go, so it agrees with the side that is
# already wrong.
sub _go_scalar_bytes {
    my ($s) = @_;

    return '' unless length $s;
    return $s unless $s =~ $GO_LOOKS_AT;
    return $GO_CONSTANT{$s} if exists $GO_CONSTANT{$s};

    my $first = substr($s, 0, 1);

    # Hinted only because it could have been a constant, and it was not.
    return $s if index('yYnNtTfFoO~', $first) >= 0;

    # Go's case '.': ParseFloat on the token as it stands, underscores included --
    # they are part of a Go float literal, but only BETWEEN digits, which is why
    # `._5` is a string to it and `.5_0` is the number 0.5. `.`, `..`,
    # `.gitignore` and `.env` match nothing here and stay strings, as they are on
    # both sides (measured, exit 0).
    if ($first eq '.') {
        (my $stripped = $s) =~ tr/_//d;
        return _go_float($stripped) // $s
            if $s =~ /\A\.[0-9]+(?:_[0-9]+)*(?:[eE][-+]?[0-9]+(?:_[0-9]+)*)?\z/;
        return $s;
    }

    # A timestamp is tried before any number, and only for exactly four leading
    # digits followed by `-` (Go's own quick check), so `12345-01-01` is not one.
    return _go_timestamp($s) // $s if $s =~ /\A[0-9]{4}-/;

    my $plain = $s;
    $plain =~ tr/_//d;                       # Go strips every underscore first

    my $int = _go_int($plain);
    if (defined $int) {
        return undef if $int eq 'RANGE';
        return $int;
    }

    # yamlStyleFloat, the regexp resolve.go gates ParseFloat with.
    return _go_float($plain) // $s
        if $plain =~ /\A[-+]?(?:\.[0-9]+|[0-9]+(?:\.[0-9]*)?)(?:[eE][-+]?[0-9]+)?\z/;

    return $s;
}

# What YAML::XS actually writes for this leaf, when it writes it as a bare
# single-line plain scalar -- and undef when it does not, because a quoted or
# block scalar is a string to every YAML reader and cannot be resolved into
# anything else. Measured rather than modelled: libyaml quotes a string its OWN
# resolver would read as a number, a boolean or a null ('007', '5432', 'yes',
# '1:30' all come back quoted), and that is most of the reason this guard fires
# as rarely as it does.
sub _emitted_plain_scalar {
    my ($leaf) = @_;

    local $YAML::XS::Boolean = $BOOLEAN_MODE;
    my $dump = eval { Dump({ v => $leaf }) };
    return undef unless defined $dump && $dump =~ /\A---\nv: (.*)\n\z/;

    my $token = $1;
    return undef if $token =~ /\A['"|>&*!]/;
    return $token;
}

sub _go_agrees {
    my ($token, $text) = @_;

    my $bytes = _go_scalar_bytes($token);
    return defined $bytes && $bytes eq $text ? 1 : 0;
}

# WHY the two disagree, for the message. A property of the spelling, never the
# spelling itself: an error goes into bug reports.
sub _foreign_resolution_reason {
    my ($token) = @_;

    return 'a leading-zero integer, which libyaml reads as decimal and Go as octal'
        if $token =~ /\A[-+]?0[0-9]+\z/;
    return 'a 0o / 0x / 0b prefixed number, which Go resolves and libyaml does not'
        if $token =~ /\A[-+]?0[obxOBX]/;
    return 'a number written with _ digit separators, which Go strips and libyaml does not'
        if $token =~ /_/;
    return 'a date or timestamp, which Go resolves to a time and renders back in RFC3339'
        if $token =~ /\A[0-9]{4}-/;
    return 'a YAML 1.2 constant -- an infinity, a not-a-number, a null, or a '
        . 'boolean spelled in a case libyaml leaves a string'
        if $token =~ /\A[-+]?\./ || exists $GO_CONSTANT{$token};
    return 'a number outside the int64 range, which sops refuses to write at all'
        unless defined _go_scalar_bytes($token);
    return 'a spelling the two resolvers do not agree on';
}

# Could Go's resolver look at what the emitter will write for this leaf? A gate,
# never an answer: it decides whether the emit below is worth paying for, and
# the verdict is taken from the token that emit returns.
#
# The stringification stands in for the token here, and it may: for a leaf that
# is not a boolean the two are the same string, or the token is quoted. Probed
# over 2119 non-bool leaves -- every printable ASCII character alone and in
# either position, 600 integers, 900 floats over 30 orders of magnitude, the
# int64 and subnormal edges, dualvars, embedded newlines, leading whitespace,
# non-ASCII -- 2 tokens start with a different byte, and both are the UTF-8
# encoding of a non-ASCII first character. Neither can matter: every UTF-8 byte
# is >= \x80 and every byte in $GO_LOOKS_AT is ASCII.
#
# A BOOLEAN is the exception and gets the second clause. Its stringification is
# `1` or the empty string while both emitters write a bare `true`/`false`
# (docs/adr/0016), so the empty one slipped past this gate entirely. detect_type
# is the same ladder the digest goes through and the same predicate the emitters
# use -- not a second answer to the question of what a boolean is.
sub _go_might_look_at {
    my ($leaf) = @_;

    return 1 if "$leaf" =~ $GO_LOOKS_AT;
    return File::SOPS::Encrypted->detect_type($leaf) eq 'bool' ? 1 : 0;
}

# The token this emitter writes for a leaf whose SPELLING this module cannot
# prove Go resolves the way it does, and WHICH KIND of disagreement it is --
# and the empty list when there is nothing to say.
#
#   'mac'   Go derives different BYTES from the token, so the document would
#           state one value and its own MAC cover another.
#   'type'  Go derives the same bytes and a different TYPE. The MAC holds and
#           sops reads the file; what it reads is not what this module reads.
#
# ONE check, three verdicts. What a document does with the answer depends on
# whether its MAC covers the leaf (refuse: the file would fail its own MAC) or
# not (warn: the two implementations simply read different values). A 'type'
# disagreement is never refused -- the MAC covers the same bytes either way and
# there is nothing to refuse -- and since docs/adr/0070 the mac_covered path
# force-quotes the safe set (True/False among it) BEFORE this check runs, so a
# 'type' leaf reaches the check, and is warned about, only under
# mac_only_encrypted. A second copy of the check for a second verdict is the
# defect class this whole layer keeps producing, so there is one. See
# docs/adr/0018, docs/adr/0019 and docs/adr/0070.
#
# Runs on the encrypt path only, and never over the `sops` branch: the digest
# does not cover the metadata, and the one leaf there that Go resolves
# differently -- lastmodified, which it reads as a time -- is already handled,
# by _quote_sops_timestamp and the other way round, by quoting it.
#
# Encrypted slots cannot reach this at all: _encrypt_tree has replaced every
# encrypted leaf with an ENC[...] string long before the emitter runs, and that
# string starts with `E`, which no resolver looks twice at.
sub _foreign_resolution_token {
    my ($leaf, $path, $text) = @_;

    return if @$path && $path->[0] eq 'sops';
    return unless _go_might_look_at($leaf);

    # WHAT THE EMITTER WRITES is the only thing Go gets to resolve, so it is the
    # only thing asked about. The leaf's stringification decided this until
    # k91 -- it is the same string for every leaf class but a boolean, and
    # for a boolean it was wrong in both directions: k90 reached a document
    # through exactly that step, because `1` resolved to the `1` the digest then
    # covered and the guard returned before asking the emitter anything. A
    # quoted or multi-line scalar is a string to every YAML reader, and undef
    # here says so. See docs/adr/0017.
    my $token = _emitted_plain_scalar($leaf);
    return unless defined $token;

    # THE one conversion -- the text the MAC digest covers. The walk hands it
    # over where it already derived one (and for a carrier that is the ORIGINAL
    # value's text, which is what the digest has); otherwise it comes from the
    # same method on the same scalar. Never a second rendering derived here.
    $text //= File::SOPS::Encrypted->value_to_bytes($leaf);
    return ($token, 'mac') unless _go_agrees($token, $text);

    # The bytes agree and the TYPE does not. A second axis, invisible to
    # everything above: the digest cannot see it, so neither could this guard
    # until k92. See docs/adr/0019.
    return ($token, 'type') if _go_retypes($leaf, $token);

    return;
}

# The tokens Go resolves to a boolean, derived from the one table rather than
# listed a second time next to it.
my %GO_BOOL_TOKEN = map { $_ => 1 }
    grep { $GO_CONSTANT{$_} eq 'True' || $GO_CONSTANT{$_} eq 'False' }
    keys %GO_CONSTANT;

# Does Go read a BOOLEAN out of a token whose bytes already agree with the
# digest? Only `True` and `False` can be here: libyaml quotes `true` and
# `false` (its own resolver knows them), and `TRUE` / `FALSE` disagree on bytes
# -- sops digests a boolean Title-cased -- so they are refused one step up.
#
# What that leaves is a string here and a bool to sops, in a document neither of
# them complains about: measured, sops -d exit 0 and `true` in its output. It is
# not stable, either -- `sops rotate`, `sops set` and `sops edit` each write the
# resolved value back as a bare `true`, after which this module reads a boolean
# too, so the caller's string is gone.
#
# Both authorities are the ones already in use: %GO_CONSTANT for what Go makes
# of the token, detect_type for what the leaf is. A leaf that really is a
# boolean writes `true` and is read as one on both sides -- nothing to say.
sub _go_retypes {
    my ($leaf, $token) = @_;

    return 0 unless $GO_BOOL_TOKEN{$token};
    return File::SOPS::Encrypted->detect_type($leaf) eq 'bool' ? 0 : 1;
}

# The MAC holds and the two implementations still read different things, so
# there is nothing to refuse and something to say. The message does not depend
# on the MAC mode, which is why one sub serves both call sites. Since
# docs/adr/0070 the mac_covered path force-quotes a True/False leaf before the
# guard runs, so in normal operation this carp fires only under
# mac_only_encrypted; the mac_covered site (_reject_foreign_resolution) reaches
# it only on the fail-closed fallback, when the sentinel surgery is abandoned.
# See docs/adr/0019, docs/adr/0070 and k92.
sub _carp_foreign_retyping {
    my ($where) = @_;

    carp "$where: this leaf is a string here and a boolean to sops. libyaml "
        . "leaves the spelling a string while Go's yaml.v3 resolves it as a "
        . "boolean, and both digest the same bytes, so the MAC holds and sops "
        . "reads the file (measured, sops -d exit 0). What differs is the type: "
        . "sops hands the value on as a boolean, and any sops write-back "
        . "(rotate, set, edit) rewrites the spelling to a bare true/false, after "
        . "which this module reads a boolean as well. Encrypt the leaf -- an "
        . "ENC[...] string carries the text verbatim and is a string to both -- "
        . "or write the document as JSON, where every string is quoted";
}

# WHAT TO DO ABOUT IT depends on what the leaf IS, and until k135 the
# message answered for an `int` leaf whatever it was handed.
#
# For a NUMERIC leaf the sentence is right and re-measured against sops 3.13.3:
# a plaintext `mode: 0755` really does leave `sops -e` as the integer 493, the
# spelling does not survive in any form, and passing the decimal produces the
# document sops itself would have written.
#
# For a leaf that is ALREADY A STRING it was wrong in both halves. Given the
# string, sops resolves nothing -- measured, one document per spelling: a
# plaintext `v_unencrypted: "1_000"` leaves `sops -e` as `v_unencrypted:
# "1_000"`, double-quoted and intact, and `sops -d` reads it back at exit 0 for
# all 22 spellings of this class. And there is no decimal to pass, because the
# value is not a number: what is missing is a way to write a string as anything
# but this bare token, which YAML::XS does not have (no tag, no forced-quote
# hook -- probed over every SV shape and every setting of
# $YAML::XS::QuoteNumericStrings; a dualvar carrier makes it WORSE, writing even
# `0755` bare). YAML::XS cannot quote it directly, so the fifteen ambiguous
# spellings of this class -- whose bare and quoted sources are indistinguishable
# -- stay refused (docs/adr/0008), and this message names the two remedies
# measured to work for all 22 of the class: encrypt it (22 of 22 sops -d exit 0)
# or write the document as JSON (22 of 22). The other seven -- the
# parse-unambiguous non-finite str spellings -- no longer reach this message:
# since k99/docs/adr/0070 the emitter force-quotes them through a fail-closed
# sentinel substitution and writes them, rather than refusing. See
# docs/adr/0039, k135, docs/adr/0070 and k99.
#
# detect_type is the ladder the digest already goes through, not a second
# opinion about what the leaf is -- and not a pattern on its text.
sub _foreign_resolution_remedy {
    my ($leaf) = @_;

    return "This leaf is already a STRING here, and sops does not resolve a "
        . "string away: it writes one double-quoted and reads it back "
        . "(measured, sops -d exit 0). What this emitter cannot do is write it "
        . "that way -- YAML::XS has no per-scalar style control, so the only "
        . "token it produces for this leaf is the bare one Go resolves into "
        . "something else, and there is no other spelling of the same string to "
        . "pass instead. Encrypt the leaf -- an ENC[...] string carries it "
        . "verbatim and is unaffected by this rule -- or write the document as "
        . "JSON, where every string is quoted"
        if File::SOPS::Encrypted->detect_type($leaf) eq 'str';

    return "sops itself resolves such a spelling when it writes: a plaintext "
        . "`mode: 0755` becomes the integer 493 in its output, and that decimal "
        . "is what to pass here. To keep the spelling as text, encrypt the leaf "
        . "-- an ENC[...] string carries it verbatim and is unaffected by this "
        . "rule";
}

# The document carries a MAC that covers this leaf, so the disagreement is with
# the file's own verification and there is nothing to write.
sub _reject_foreign_resolution {
    my ($leaf, $where, $path, $text) = @_;

    my ($token, $kind) = _foreign_resolution_token($leaf, $path, $text);
    return unless defined $token;
    return _carp_foreign_retyping($where) if $kind eq 'type';

    croak "$where: cannot write this leaf to a SOPS YAML document: its spelling "
        . "is " . _foreign_resolution_reason($token) . ". The MAC digest covers "
        . "the value this module resolves, while sops re-reads the document with "
        . "Go's yaml.v3 and resolves a different one, so the file would fail its "
        . "own MAC and neither sops nor this module could read it back (measured, "
        . "sops -d exit 51). " . _foreign_resolution_remedy($leaf);
}

# mac_only_encrypted: the digest covers encrypted values only, so this leaf
# cannot make the document disagree with its own MAC and refusing it would
# refuse a file that works. What is left is that the two implementations read
# different VALUES out of a document neither of them complains about -- measured
# for `mode_unencrypted: 0755`, sops -d exit 0 and it reads 493 where this
# module reads 755. Nothing tells the caller that but this line. See k87
# and docs/adr/0018.
#
# carp rather than warn, for the same reason the refusals croak: the line worth
# printing is the caller's, and @CARP_NOT above already walks out of the emitter
# and the walk. The value never appears here -- a warning goes to logs.
sub _warn_foreign_resolution {
    my ($leaf, $where, $path, $text) = @_;

    my ($token, $kind) = _foreign_resolution_token($leaf, $path, $text);
    return unless defined $token;
    return _carp_foreign_retyping($where) if $kind eq 'type';

    carp "$where: this leaf's spelling is " . _foreign_resolution_reason($token)
        . ", so sops resolves a different value from the one this module reads. "
        . "With mac_only_encrypted set the MAC does not cover this leaf, so "
        . "nothing will fail -- the document is written and sops reads it. "
        . _foreign_resolution_warning_remedy($leaf);
}

# The same split as the refusal's, and for the same measured reason: there is no
# value to pass for a leaf that is already a string, because the string IS the
# value and the emitter cannot write it quoted. See docs/adr/0039 and k135.
sub _foreign_resolution_warning_remedy {
    my ($leaf) = @_;

    return "This leaf is already a string here, and sops writes such a string "
        . "double-quoted rather than resolving it away -- this emitter cannot, "
        . "because YAML::XS has no per-scalar style control, so there is no "
        . "value to pass instead. Encrypt the leaf, or write the document as "
        . "JSON where every string is quoted, to make the two agree"
        if File::SOPS::Encrypted->detect_type($leaf) eq 'str';

    return "Pass the value sops itself would write (measured: a `mode: 0755` is "
        . "493 to sops and 755 here), or encrypt the leaf, to make the two agree";
}

###############################################################################

# Does YAML::XS's own rendering of this float come back as the same double?
#
# Measured, not modelled: the value goes through the real Dump and the real
# Load. YAML::XS renders a float by Perl stringification, which is ~15
# significant digits, so 0.1+0.2 comes back as 0.3 -- a different number from
# the one value_to_bytes digested, and a document that fails its own MAC.
#
# It answers YES far more often than that suggests, and that is the point:
# YAML::XS retains the PV of every float it PARSES and emits it verbatim, so a
# value read from a document round-trips by construction and keeps the exact
# bytes it arrived with. Only floats that reach us as bare NVs -- computed by
# the caller, or parsed out of JSON -- ever need the carrier.
#
# Equality is decided by value_to_bytes on both sides rather than by ==, so it
# means the same thing the digest means. == cannot tell -0.0 from 0.0.
sub _float_roundtrips {
    my ($value, $text) = @_;

    my $back = eval { Load(Dump({ v => $value }))->{v} };
    return 0 unless defined $back;
    return File::SOPS::Encrypted->value_to_bytes($back) eq $text ? 1 : 0;
}

# A dualvar's numeric half keeps the value a float for anything that looks at
# the SV; YAML::XS writes the string half, unquoted, as a plain scalar.
#
# Note what this is: a raw-text primitive with no guard rail. YAML::XS emits
# whatever the PV says -- dualvar(0.3, 'hello') writes `v: hello` -- so this is
# safe only because $text came from value_to_bytes. Do not derive it here.
#
# The ONE exception, and the only place in this distribution where a written
# decimal is not value_to_bytes's output verbatim: a negative zero. Its
# canonical text is `-0`, which YAML resolves as an INTEGER -- Go's yaml.v3 and
# YAML::XS agree on that -- so a document carrying `-0` is digested as `0` by
# every reader while our MAC covers `-0`. Measured against sops 3.13.3, one
# document per spelling, leaf under _unencrypted, digest `-0`:
#
#   -0        sops -d exit 51 (MAC mismatch)   self-MAC FAIL   <- k62
#   !!float -0  sops -d exit 51                self-MAC FAIL
#   -0.0      sops -d exit 0, reads back -0    self-MAC OK     <- this
#   -0.       sops -d exit 0                   self-MAC OK
#   -0.0e0    sops -d exit 0                   self-MAC OK     <- k89
#
# sops cannot write this value either: `sops -e` on a plaintext `-0.0` emits
# `-0` and then rejects its own file with exit 51, in YAML and in JSON alike.
# So `-0.0` is not "the bytes sops writes", it is the only spelling both
# implementations read as the double the digest covers -- which is exactly what
# ADR 0006 asks of an emitted decimal, and it says so: the text has to parse
# back to the same double, not to be spelled canonically.
#
# Narrow on purpose. `-0` is the only canonical float text an integer
# resolution changes the digest of: every other integral one digests the same
# whether Go reads it as an int or a float (`3` is `3` either way), and every
# float that needs a fraction already carries a `.`. A general "append .0"
# would move bytes for cases nobody has measured.
sub _float_carrier {
    my ($value, $text) = @_;
    return dualvar($value, $text eq '-0' ? '-0.0' : $text);
}


sub format_name { 'yaml' }


sub file_extensions { qw(yaml yml) }


sub detect {
    my ($class, $filename) = @_;
    return 1 if $filename =~ /\.ya?ml$/i;
    return 0;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::SOPS::Format::YAML - YAML format handler for SOPS

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use File::SOPS::Format::YAML;

    # Parse YAML with SOPS metadata
    my ($data, $metadata) = File::SOPS::Format::YAML->parse($yaml_content);

    # Serialize data with SOPS metadata
    my $yaml = File::SOPS::Format::YAML->serialize(
        data     => $encrypted_data,
        metadata => $metadata_obj,
    );

    # Check if filename is YAML
    if (File::SOPS::Format::YAML->detect('secrets.yaml')) {
        # It's a YAML file
    }

=head1 DESCRIPTION

YAML format handler for File::SOPS. Handles parsing and serialization of
SOPS-encrypted YAML files.

Uses L<YAML::XS> for fast, spec-compliant YAML processing.

Booleans are round-tripped as C<JSON::PP::Boolean> objects, by setting
YAML::XS's C<$YAML::XS::Boolean> mode to C<'JSON::PP'>. That is the class
L<JSON::MaybeXS> blesses booleans into on every one of its backends, so a
C<true> loaded from YAML and a C<true> decoded from JSON are the same kind of
object throughout this distribution, and both are emitted as bare C<true> /
C<false> rather than degrading to C<1> / C<0> on the next write.

The mode is set with C<local> around this module's own C<Load> and C<Dump>
calls. C<$YAML::XS::Boolean> is a process global that changes what L<YAML::XS>
does for every other user of it in the same interpreter, so before 0.003 merely
loading File::SOPS changed how unrelated code parsed YAML.

=head2 Multi-document YAML

B<A YAML stream with more than one document is refused.> L</parse> dies rather
than returning part of it.

This is a restriction, not a preference: it replaces silent data loss. Until
0.003 the stream was loaded in scalar context, which yields only the B<last>
document, so C<a: 1\n---\nb: 2> parsed to C<{b =E<gt> 2}> and
L<File::SOPS/encrypt_file> wrote that back as the entire file. Every document
but the last disappeared with no error.

sops itself does support multi-document YAML, so this is a gap to close rather
than a rule to keep. Its model, measured against sops 3.13.3, is not "several
independent files in one":

=over 4

=item * One metadata section for the whole stream, written into B<every>
document -- the same age blob, C<lastmodified> and C<mac> byte for byte. On
read it is taken from the B<first> document; a stream carrying it only in a
later document is rejected with C<sops metadata not found>.

=item * B<One MAC spanning all documents, in order.> Removing a document or
swapping two of them fails verification.

=item * The AAD carries B<no> document index. A given key path has the same
AAD in every document, so a value encrypted in one document decrypts in
another document's slot at that path.

=item * Documents are joined by C<--->; a B<leading> separator is dropped,
while a trailing one is preserved as a real (empty) document. An empty document
anywhere is a document: it gets its own metadata block and reads back as C<{}>.

=item * Every document must be a mapping. sops rejects a top-level sequence or
scalar itself (C<YAML documents that are sequences are not supported>), which
is the same rule as the HashRef check in L</parse>.

=back

Supporting that means one tree of N branches with a shared metadata and a
digest spanning all of them, which reaches into encryption, MAC computation and
the shape of the public API -- not this parser alone.

=head2 parse

    my ($data, $metadata) = File::SOPS::Format::YAML->parse($yaml_string);

Class method to parse a YAML string.

Returns a two-element list:

=over 4

=item 1. C<$data> - HashRef of the data (without the C<sops> section)

=item 2. C<$metadata> - L<File::SOPS::Metadata> object, or C<undef> if no C<sops> section

=back

Dies if the YAML is invalid, doesn't parse to a HashRef, or contains more
than one document. See L</Multi-document YAML>.

Dies too if the document has a top-level C<sops> entry that is B<not> a
mapping -- C<sops: mine>, a list, or an explicit C<null>. Until 0.003 that
entry was deleted from the tree and reported as no metadata at all, so
L<File::SOPS/encrypt_file> wrote the document back without it. See
L<File::SOPS::Metadata/from_hash>, which is where the refusal lives.

=head3 A literal that overflows a double comes back as a string

C<1e400>, a 401-digit integer, and the bare spellings C<Inf>, C<inf>, C<INF>,
C<Infinity>, C<NaN>, C<nan>, C<NAN>, C<-Inf> and C<+Inf> are all resolved to a
B<number> by libyaml, and the number each of them lands on is C<+Inf>, C<-Inf>
or C<NaN>. go-yaml -- the parser sops reads a document with -- resolves none of
them: C<strconv.ParseFloat> answers C<ErrRange> and it keeps a B<string>. So
sops writes C<type:str> for such a leaf and digests the literal's own text.

Since 0.003 this method hands back the string go-yaml sees, so that
L<File::SOPS::Encrypted/detect_type> and the MAC agree with sops. Before it,
such a document could be neither read (17 of 20 measured documents that sops
writes failed MAC verification here) nor written (all 20 hit the non-finite
refusal in L<File::SOPS::Encrypted/assert_representable>).

Three things this is B<not>. It does not touch the twelve spellings go-yaml
really does resolve to a non-finite float -- C<.inf .Inf .INF +.inf +.Inf
+.INF -.inf -.Inf -.INF .nan .NaN .NAN> -- because L<YAML::XS> returns every
one of those as a plain string with no numeric half at all; those have a
repair of their own since 0.003, and a different one, described in
L</A plain infinity comes back as the float go-yaml reads>. It does not loosen
L<File::SOPS::Encrypted/assert_representable>: a caller who passes
L<File::SOPS/encrypt> a real C<9**9**9> still gets the refusal, because what is
repaired here is a parse result and not a rule about values. And it does not
apply to L<File::SOPS::Format::JSON>, where sops refuses the equivalent
document itself, at unmarshal time.

The cost is that the leaf is written back B<quoted> -- C<v: '1e400'> where sops
writes C<v: 1e400>. Both are a string to both parsers, so the digest is the same
text either way. See
L<docs/adr/0023|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0023-a-yaml-literal-that-overflows-a-double-is-a-string-not-a-float.md>.

=head3 A plain infinity comes back as the float go-yaml reads

The mirror image of the section above, and it needs a different authority.
L<YAML::XS> leaves C<.inf> a B<string>; go-yaml resolves it to the float
C<+Inf>, and sops digests C<+Inf>. So a document sops writes and C<sops -d>
verifies used to fail MAC verification here, with an error that named nothing.

Since 0.003 a leaf the document wrote as a B<plain> scalar, and whose token is
one of the twelve above, comes back as a L<Scalar::Util/dualvar>: the float
go-yaml resolved, carrying the document's own token as its text. So
L<File::SOPS::Encrypted/value_to_bytes> derives C<+Inf> / C<-Inf> / C<NaN> --
the bytes sops put in the MAC -- while every emitter writes the file back
exactly as it read it, and L<File::SOPS/decrypt_file> reproduces sops's own
plaintext byte for byte.

B<The word "plain" is the whole of it>, and it is why this repair is not the
one above. Measured against sops 3.13.3, in one document:

    list_unencrypted:
        - .inf          # go-yaml: a float,  digested +Inf
        - ".inf"        # go-yaml: a string, digested .inf

Both spellings arrive here as the same L<YAML::XS> string, and the two have
different digests. Anything that decided from the leaf's B<text> would fix the
first element and silently break the second, which reads correctly today. So
the document is asked instead: L<YAML::PP>, already this distribution's second
parser, resolves such a scalar to a non-finite number exactly when it was
written plain, and only a token that is already in this module's model of
go-yaml is repaired at all. If L<YAML::PP> refuses the document, or the two
parse trees disagree about its shape, B<nothing> is repaired.

B<This runs on every document, plaintext included>, and the plaintext half is
newer than the rest. Until 0.003 it was gated on the C<sops:> section, on the
argument that a plaintext has no MAC for anyone to disagree with; that gate is
gone, because the document such a plaintext turns into I<can> now be written
(see below), so the gate was refusing a document this module produces. sops
resolves a plain scalar the same way on every parse it makes, and so does this.

B<Such a document is written back> since 0.003: an B<unencrypted> YAML slot
holding one of the twelve tokens reaches the file as that token, with the
digest covering C<+Inf> / C<-Inf> / C<NaN>, which is what sops writes and what
sops digests for the same document. An B<encrypted> slot is still refused --
the wire form there is C<type:float> with the plaintext C<+Inf>, which
L<File::SOPS::Encrypted/encrypt_value> refuses because it cannot see which
format is being written (k122).

See
L<docs/adr/0026|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0026-a-plain-yaml-infinity-is-the-float-go-yaml-reads.md>,
L<docs/adr/0031|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0031-a-non-finite-float-that-carries-go-yamls-own-token-is-written.md>
and
L<docs/adr/0034|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0034-a-plain-scalar-is-resolved-the-same-way-on-every-parse.md>.

=head3 A plain C<lastmodified> in the C<sops> section is warned about

The read-side mirror of what L</serialize> does on the way out. sops writes
C<lastmodified: "2026-08-21T09:05:08Z"> B<quoted>, and so does this
distribution, because go-yaml resolves a B<bare> RFC3339 scalar to a Go
C<time.Time> where sops's own decoder wants a string. Measured against sops
3.13.3:

    lastmodified: "2026-08-21T09:05:08Z"    sops -d exit 0
    lastmodified: 2026-08-21T09:05:08Z      sops -d exit 1
          'lastmodified' expected type 'string', got unconvertible type
          'time.Time'

This method reads both, and since 0.003 it B<carps> on the second: the values
and the MAC are unaffected, but the file is one no sops can open. It is not
refused, because every write path here re-stamps and quotes the timestamp --
so C<rotate>, C<edit>, C<encrypt_in_place> and C<decrypt_file> plus
C<encrypt_file> all turn such a document into one C<sops -d> reads at exit 0,
and a refusal would take that away and leave the file unopenable by every tool.

The warning cannot fire on a document sops reads. All 15 RFC3339 spellings sops
accepts quoted were measured refused bare, and a B<tagged> plain scalar --
C<!!str 2026-08-21T09:05:08Z>, where the explicit tag stops go-yaml's implicit
resolver -- is read by sops at exit 0 and is not warned about here.

The question is B<plain or quoted>, which is a fact about the source bytes and
not about the value: both spellings arrive at
L<File::SOPS::Metadata/from_hash> as the same Perl string, which is why this
lives here and not there. Unlike the infinity above, the answer does not come
from a resolver -- YAML 1.2's Core schema has no timestamp type, so L<YAML::PP>
reads both spellings as the same string too -- but from L<YAML::PP>'s B<parser>,
asked for one scalar's style. A document that parser will not read is not warned
about. See
L<docs/adr/0050|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0050-a-plain-lastmodified-is-warned-about-because-only-we-can-still-repair-it.md>
and
L<docs/adr/0044|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0044-the-macs-aad-is-the-timestamp-go-re-formats-not-the-text-the-document-holds.md>.

=head3 A merge key keeps its C<< << >>, and loses its C<!!merge> tag

sops does not expand a YAML merge key. It unmarshals into a C<yaml.Node> tree,
where go-yaml resolves no merges, so C<< << >> survives as an ordinary mapping
key -- and go-yaml's emitter writes the tag its resolver assigned back out
B<explicitly>:

    derived:
        !!merge <<:
            x: ENC[AES256_GCM,...,type:int]
        "y": ENC[AES256_GCM,...,type:int]

L<YAML::XS> accepts C<!!str>, C<!!int> and C<!!float> on a scalar and dies on
every other tag, so before 0.003 such a document could not be B<opened> here at
all: C<bad tag found for scalar: 'tag:yaml.org,2002:merge'>, a parse error
rather than a MAC error, on a file C<sops -d> reads at exit 0. Nor was it only
sops's own documents -- measured, one C<sops rotate -i> on a document
L<File::SOPS> had written with a C<< << >> key added the tag, and File::SOPS
could no longer read its own output.

Since 0.003 the tag is dropped from the text and the parse retried. Only that
tag, only after L<YAML::XS> has already refused the document, and only when
L<YAML::PP>'s parser confirms the substitution removed exactly as many
merge-tagged scalars as the document really contains; otherwise nothing is
retried and libyaml's own error stands. A document that parses today therefore
takes the identical path it always did.

B<Nothing about the value layer changes>, which is why this is a parser repair
and not a wire one. Measured against sops 3.13.3 across five documents, one per
position sops writes the tag in: C<< << >> is a path component in the AAD
(a leaf under it authenticates as C<< derived:<<:x: >> and under nothing else)
and a member of the MAC digest with its whole subtree, in the document's own
order. No AAD path, no digest byte and no emitted byte moves.

Two things this is B<not>. It does not make L<YAML::XS> resolve the merge:
C<< <<: *b >> still gives a literal C<< << >> key holding the aliased mapping,
with nothing folded into the parent -- which is what makes the round trip
correct, because sops does not fold it either. And it does not put the tag
back on the way out; this module writes the plain C<< <<: >> spelling, which
go-yaml re-tags for itself (measured, C<sops -d> on a document we wrote as
C<< <<: >> prints C<< !!merge <<: >>).

A merge tag this cannot see -- flow style, or a C<%TAG>-directive spelling --
is refused as it is today. The other tags L<YAML::XS> rejects are covered by
the section below; sops was not measured to write any of them into an
encrypted document. See
L<docs/adr/0028|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0028-the-merge-tag-is-dropped-because-the-merge-key-is-an-ordinary-key.md>.

=head3 An explicit type tag on a scalar

L<YAML::XS> accepts exactly three tags on a scalar -- C<!!str>, C<!!int> and
C<!!float> -- and dies on every other one. sops accepts them all, resolves
them, and writes the resolved value with the tag gone, so a hand-written
plaintext that C<sops -e> encrypts at exit 0 could not be B<opened> here.

Since 0.003, C<!!bool> on a plain C<true> or C<false> is dropped from the text
and the parse retried, by the same count-reconciled mechanism as C<!!merge>
above and under the same conditions: only after L<YAML::XS> has already refused
the document, and only when L<YAML::PP>'s parser confirms the substitution
removed exactly as many such scalars as the document really contains. That tag
is the only one here that carries nothing. Measured against sops 3.13.3 with
the stored C<mac:> decrypted out of each document, C<!!bool true> and a bare
C<true> produce byte-identical output -- C<type:bool>, plaintext C<True>, and
the same MAC digest.

B<Every other tag here carries a type>, and in this distribution the type comes
from the scalar rather than from the document's text, so removing one would
retype the leaf. Those are refused, naming the tag, the leaf's key path, and
what sops resolves the tag to -- in place of libyaml's
C<bad tag found for scalar>, which reads like a defect in a foreign library.
The scalar's own text is never quoted back; it is plaintext. Measured:

    !!binary aGVsbG8=        sops base64-DECODES it   -> the value `hello`
    !!timestamp 2026-08-21   sops re-renders it       -> `2026-08-21T00:00:00Z`, type:time
    !!bool True              sops resolves it bool    -> a string to libyaml
    !!null Null              sops resolves it null    -> a string to libyaml
    !!value 1                sops keeps the text      -> the integer 1 to libyaml

C<!!null> on C<~>, C<null> or an empty scalar has always been read and still is.
A tag L<YAML::XS> accepts but cannot resolve -- C<!!int 0x10>, C<!!int 1_000>,
C<!!float .inf>, all of which sops resolves -- keeps libyaml's own message,
because that is a resolver disagreement rather than a tag this module refuses.
See
L<docs/adr/0032|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0032-a-scalar-tag-is-dropped-only-where-it-carries-no-type.md>.

=head3 A comment inside a list is kept

sops attaches a YAML comment to the node that B<follows> it. Above a mapping key
the comment stays a comment -- C<#ENC[...,type:comment]> on a line of its own,
which L<YAML::XS> discards and sops does not hash, so such a document reads
correctly here and always has. Above an entry of a B<sequence> there is no
comment line to write, so sops emits the comment as a real element:

    list:
        - ENC[AES256_GCM,...,type:comment]
        - ENC[AES256_GCM,...,type:str]

This method hands that element on like any other. L<File::SOPS/decrypt> turns it
into a C<File::SOPS::Comment> (see L<File::SOPS::Comment>), keeps it at
its index, leaves it out of the MAC digest -- which is what sops does with it --
and writes it back as a C<type:comment> element. Before 0.003 the comment was
read as an ordinary list element: strict mode failed MAC verification, and
C<ignore_mac =E<gt> 1> returned a list with the comment's text in it as a silent
extra string, which a C<decrypt> plus C<encrypt> cycle then made a permanent
value. See
L<docs/adr/0041|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0041-a-sops-comment-is-a-leaf-of-its-own-not-a-value-and-not-a-refusal.md>,
which supersedes
L<docs/adr/0024|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0024-a-sops-comment-leaf-is-refused-not-read-as-a-value.md>.

What is still refused is a comment this emitter would have to write as B<plain
text>: L</emit> croaks on a C<File::SOPS::Comment> leaf, naming its path, because
L<YAML::XS> has no way to write a comment at all and would not read one back
either. That is what makes C<decrypt_file> and C<edit> refuse a document with a
comment in it, rather than dropping the comment on the way through. A comment in
a B<mapping value> slot is refused too, by L<File::SOPS> and in both formats,
because no SOPS store writes that shape.

A comment above a B<mapping> key -- and one on the file's first line, which sops
writes the same way -- is still B<lost> on a read here, as it always has been:
L<YAML::XS> discards it before this method sees a tree, and nothing here can
write one back. That is the open half of k76, filed as k148, and it
is not a lane handoff but a wall: L<YAML::XS> is libyaml, whose emitter cannot
write a comment at all, and L<YAML::PP>'s emitter has no comment event either --
its own documentation lists comment-preserving round trips as a TODO. The read
half is nearer than that reads: L<YAML::PP>'s B<parser> keeps the comment text
in its raw token stream, so the line can be seen. But there is nowhere to put
it. A sequence comment is preserved because a sequence B<element> is a slot the
tree model already has; a mapping-position comment sits before a key, and a
Perl hash has no slot before a key.

The two positions therefore behave differently, and the difference is measured:
a document whose comment is a sequence element is B<refused> by L</emit> --
which is what makes L<File::SOPS/decrypt_file> and L<File::SOPS/edit> refuse it
rather than drop it -- while a document whose only comment is above a mapping
key is written back B<silently without it>. C<sops -d> returns both comments
intact for both documents.

=head2 parse_in_document_order

    my $ordered = File::SOPS::Format::YAML->parse_in_document_order($content);

Reparses C<$content> for its B<key order only> and returns its mappings
iterating in the order the file writes them, with the C<sops> section removed.
A single document comes back as a HashRef; a B<multi-document> stream comes
back as an ArrayRef of such HashRefs, one per document in document order
(C<docs/adr/0033>). Returns nothing when the text cannot be read that way.

This is the format half of the MAC's order recovery (C<docs/adr/0001>), and
L<File::SOPS> asks the handler that parsed the document rather than reaching
for a parser of its own (C<docs/adr/0036>). What comes back supplies B<order
and shape>; the values are never looked at, so the loader used here does not
have to agree with L<YAML::XS> about how a scalar resolves -- only about where
the mappings, sequences and leaves are.

Declining is safe and losing the order is not an error: the caller then hashes
in sorted key order, which can make verification fail but can never make it
wrongly succeed. The stream is read in B<list context>, matching L</parse>, so
document C<i>'s order is paired with document C<i>'s values -- the scalar-context
trap C<docs/adr/0033> names (L<YAML::PP> yielding the first document where
L<YAML::XS> yields the last) cannot arise.

=head2 serialize

    my $yaml = File::SOPS::Format::YAML->serialize(
        data     => \%data,           # one document
        metadata => $metadata_obj,
    );

    my $stream = File::SOPS::Format::YAML->serialize(
        data     => [ \%doc1, \%doc2 ],  # a multi-document stream
        metadata => $metadata_obj,
    );

Class method to serialize data and metadata to YAML.

The C<data> parameter is a HashRef for a single document, or an B<ArrayRef of
HashRefs> for a multi-document stream (docs/adr/0033, k31); a one-element
ArrayRef is byte-identical to the bare HashRef. The C<metadata> parameter must be
a L<File::SOPS::Metadata> object.

For a stream, the B<same> metadata section is written into B<every> document,
byte-identical (same age blob, C<lastmodified> and C<mac>) -- the exact inverse
of the read-side detach in L</parse>, which takes the metadata from the first
document only. The documents are joined by C<--->; an empty document in the list
is a real document and comes out as C<{}> carrying only its own C<sops:> section.

Dies if any document has a top-level C<sops> key: that is where the metadata
section is written, so the value would be overwritten. Until 0.003 it was,
silently, and the resulting document failed its own MAC because the digest had
already covered the discarded value.

Returns a YAML string with the C<sops> section appended to each document.

B<A leaf whose YAML spelling Go's parser resolves differently is refused here,
and only here.> The document this method writes carries a MAC, and sops
recomputes that MAC from the values C<gopkg.in/yaml.v3> resolves out of these
bytes -- so a leaf that libyaml and Go read differently makes the file
disagree with its own MAC. C<mode: 0755> is the realistic case: this module
reads 755, Go reads 493, and the file was written silently and rejected later
with C<MAC mismatch>. Refused as well: C<0o10>, C<0x1f>, C<0b101>, C<1_000>,
C<Null>, C<TRUE> and a date that is not already exactly RFC3339 -- all spellings
libyaml leaves a string and Go resolves to something else. C<007>, C<08>,
C<1e3>, C<True>, C<null>, C<yes>, C<1:30> and C<2015-01-01T12:00:00Z> are B<not>
refused: measured, the two resolvers derive the same digest bytes from each of
them. C<.inf> and C<.nan> are B<no longer> refused either -- since
C<docs/adr/0070> they belong to the nine-leaf safe set this emitter force-quotes
instead (see below).

B<Where the refused leaf is already a string, fifteen of these spellings stay
refused as a limitation this distribution states; the seven parse-unambiguous
non-finite ones are the exception and are written double-quoted.> sops does not
resolve a string away: given the string C<".inf">, C<"1_000"> or C<"2015-01-01">
it writes it double-quoted and reads it back -- measured against sops 3.13.3, 22
such spellings, C<sops -d> exit 0 for every one, and this module reads all 22 of
those documents correctly, in both slots, with the MAC verified. For fifteen of
them it cannot B<write> the leaf: a bare C<2015-01-01> and a quoted
C<"2015-01-01"> arrive as the same Perl string, while sops writes
C<2015-01-01T00:00:00Z> for the first and C<"2015-01-01"> for the second, so
quoting a leaf whose source may have been bare would turn a loud refusal into a
silent value divergence. Those fifteen stay refused, and the message names the
two remedies measured to work for them -- encrypt the leaf, or write the
document as JSON. The other seven -- the non-finite str spellings C<.inf>,
C<.Inf>, C<.INF>, C<+.inf>, C<-.inf>, C<.nan> and C<.NaN> -- parse
B<unambiguously>: a bare one is resolved to a float at parse (C<docs/adr/0026>),
so a leaf still holding the string can only have come from a quoted source or a
caller's own Perl string, and double-quoting it states the type it already has.
Since C<docs/adr/0070> this emitter writes those seven double-quoted through a
fail-closed sentinel substitution -- the same nine-leaf safe set as C<True> and
C<False> below -- byte-identical to what sops writes. See
L<docs/adr/0039|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0039-a-string-leaf-this-emitter-cannot-quote-stays-refused-and-says-so.md>,
k135,
L<docs/adr/0070|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0070-a-scoped-per-scalar-quote-is-feasible-for-the-non-ambiguous-divergent-string-leaves.md>
and k99.

B<A C<True> or C<False> string is written double-quoted where the MAC covers
it, and warned about where it does not.> The digest bytes agree -- sops renders
a boolean Title-cased, which is the same text this module derives from the
string -- so the MAC holds and C<sops -d> exits 0. What differs is the B<type>:
L<YAML::XS> writes the string as a bare C<True> because libyaml's resolver knows
only C<true> and C<false>, and Go's yaml.v3 reads a boolean out of it. Measured,
sops 3.13.3: from a bare C<True> C<sops -d> hands the value on as C<true>, and
C<sops rotate>, C<sops set> and C<sops edit> each rewrite the leaf to a bare
C<true>, after which this module reads a C<JSON::PP::Boolean> where the caller
put a string. Until C<docs/adr/0019> this was a C<carp> in both MAC modes;
since C<docs/adr/0070> the MAC-covered path double-quotes the leaf instead --
through the same fail-closed sentinel substitution as the seven non-finite
spellings above -- so it stays a string on both sides and a sops write-back
keeps it (C<sops -e "True"> writes C<"True">). In a C<mac_only_encrypted>
document the leaf is B<not> MAC-covered and the document already works, so the
safe-set force-quoting is deliberately not run there and the C<carp> remains:
its message names the two remedies -- encrypt the leaf, or write the document as
JSON, where every string is quoted. Neighbours that look like this one do
B<not> warn or quote, because measured they do not diverge: C<Yes>, C<No>,
C<on>, C<off>, C<y>, C<n> and the rest of YAML 1.1's boolean family are strings
to yaml.v3 and to libyaml alike, C<~> and C<null> are written quoted, and an
RFC3339 timestamp -- a string here and a C<time.Time> to Go -- comes back from
C<sops rotate> as the identical token. See
L<docs/adr/0019|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0019-a-string-go-resolves-as-a-boolean-is-warned-about-in-both-modes.md>,
k92,
L<docs/adr/0070|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0070-a-scoped-per-scalar-quote-is-feasible-for-the-non-ambiguous-divergent-string-leaves.md>
and k99.

The refuse-or-warn rule does not apply to an B<encrypted> slot (an C<ENC[...]>
string carries any spelling verbatim), to L</emit> on its own (a plaintext
document has no MAC for a reader to disagree with -- though the nine-leaf
safe-set force-quoting still runs there, so that C<decrypt_file> and C<edit>
write what sops writes, C<docs/adr/0071>; see L</emit>), or to the C<sops>
metadata section (the digest does not cover it). See
L<docs/adr/0013|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0013-a-yaml-spelling-the-go-parser-resolves-differently-is-refused.md>
and k86.

B<In a C<mac_only_encrypted> document the same leaf is warned about rather than
refused.> There the digest covers encrypted values only, so an unencrypted leaf
cannot make the document disagree with its own MAC -- measured, the same
C<mode_unencrypted: 0755> is C<sops -d> exit 0 with the flag set. What remains
is that sops reads B<493> out of it where this module reads 755, in a file
neither of them complains about, so the check runs and C<carp>s instead of
refusing: the document is written exactly as before. The warning names the
leaf's key path and never the value. Silence it with a local C<$SIG{__WARN__}>
if the divergence is known and accepted. Measured over 217 such documents: 66
warn, all 66 really do diverge, none is refused, and 0 warn about a leaf the two
implementations agree on. See
L<docs/adr/0018|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0018-a-mac-only-encrypted-document-warns-where-it-cannot-refuse.md>
and k87.

=head2 emit

    my $yaml = File::SOPS::Format::YAML->emit(\%data);

Class method to emit a data structure as YAML, with no C<sops> section and no
metadata of any kind -- a plain document. This is what L<File::SOPS/decrypt_file>
writes and what L<File::SOPS/edit> hands to the editor.

Returns UTF-8 encoded bytes, unconditionally: L<YAML::XS> encodes regardless of
whether the strings it is given carry Perl's UTF-8 flag. See
L<File::SOPS/Character encoding>.

The output B<begins with the document-start marker C<--->>, because L<YAML::XS>
always emits one. sops writes none, in either direction. The line is cosmetic --
YAML resolves a document with or without it identically, C<sops -d> accepts
these files, and the MAC covers values rather than serialized text -- and it is
kept rather than stripped, since the MAC's encrypt side rides on this emitter
(C<docs/adr/0001>). See L<File::SOPS/Every YAML file starts with C<--->, where
sops writes none> and k83.

Called on its own -- which is what the plaintext emitters do -- it writes most
YAML spellings unchanged, C<0755> and C<2015-01-01> included, and a bare
C<type:float> C<.inf> stays bare. What it does B<not> pass through untouched is
the safe set L</serialize> force-quotes: a C<True> or C<False> string and the
seven parse-unambiguous non-finite C<str> spellings (C<.inf>, C<.Inf>, C<.INF>,
C<+.inf>, C<-.inf>, C<.nan>, C<.NaN>) are double-quoted here too. That is what
sops itself writes for those leaves, so C<decrypt_file> and C<edit> are faithful
inverses of it: a decrypt then re-encrypt round trip no longer flips such a leaf
from string to float or bool (a bare C<.inf> would resolve to C<+Inf> at the
next parse). It reuses ADR 0070's fail-closed sentinel mechanism unchanged. See
L<docs/adr/0071|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0071-the-plaintext-emitter-quotes-the-same-safe-set-so-it-is-a-faithful-inverse.md>
and k186.

The refuse-or-warn guard L</serialize> installs against the rest of the divergent
class is deliberately still not here: a plaintext document carries no MAC for a
reader to disagree with, and refusing them would refuse to write out documents
this module reads correctly. L</serialize> turns it on with one of the two
arguments this method takes beyond the tree -- C<< mac_covered => 1 >> to refuse
such a leaf, or C<< warn_foreign_resolution => 1 >> to warn about it, which is
what a C<mac_only_encrypted> document gets. Force-quoting the safe set runs on
every path B<except> the warn one, so a C<True>/C<False> leaf is quoted under
C<mac_covered> and on this plaintext path but still reaches the guard, and is
warned about, under C<warn_foreign_resolution>. See L</serialize>.

L</serialize> is this method plus the metadata section, so both go through the
same emitter options rather than two copies of them. Those options are not
cosmetic -- sorted key emission is what the MAC's encrypt side relies on -- so a
change here moves the encrypted document as well as the plaintext one.

B<Floats are written in a form that parses back to the same double.> L<YAML::XS>
renders a float by Perl stringification, roughly 15 significant digits, while
the MAC digest covers the shortest decimal that round-trips -- up to 17. For a
value needing 16 or 17 the document stated one number and the digest another,
and the file failed its own verification. This method now reparses its own
output and substitutes the canonical decimal from
L<File::SOPS::Encrypted/value_to_bytes> only where the value does not survive,
so a float that already emitted faithfully keeps exactly the bytes it had. In
practice that is most of them: YAML::XS retains the text of every float it
parsed, so only bare NVs -- computed by the caller, or parsed out of JSON --
are ever rewritten. C<NaN> and C<Inf> are unchanged -- they have no YAML form
Go reads back, and L<File::SOPS::Encrypted/assert_representable> refuses them
on the encrypt path. A negative zero B<is> rewritten, and it is the one value
whose written decimal is not L<File::SOPS::Encrypted/value_to_bytes>'s output
verbatim: that is C<-0>, which YAML resolves as an B<integer> and every reader
digests as C<0>, so this emitter writes C<-0.0> instead -- the spelling
measured to read back as the same double in sops 3.13.3 and here. See
L<docs/adr/0006|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0006-floats-are-emitted-in-a-form-that-parses-back-to-the-same-double.md>.

B<An integer leaf whose string form contradicts its number is refused.>
L<YAML::XS> writes the string half bare -- C<five> for a
C<Scalar::Util::dualvar> of C<5> -- while
L<File::SOPS::Encrypted/detect_type> calls the leaf an C<int>, so the MAC
digest covers the B<number>. The document and its own MAC then state different
things: measured against sops 3.13.3, C<sops -d> exit 51. A source B<spelling>
is not refused here, and that is measured too -- a C<007>, C<+7>, C<-0> or
C<1e3> this emitter received from a YAML parse is written back exactly as it
came, and Go reads the same number the digest covers (exit 0), where
L<File::SOPS::Format::JSON> has to refuse them because it quotes them. The
refusal names the leaf's key path and neither half of the value; an
B<encrypted> slot is unaffected. See k84 and
L<docs/adr/0012|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0012-an-integer-leaf-whose-string-half-disagrees-is-refused.md>.

B<A reference as a leaf value is refused>, with one exception. L<YAML::XS>
writes a blessed reference as a Perl-specific C<!!perl/> tagged structure --
C<!!perl/hash:Math::BigFloat>, C<!!perl/scalar:Foo>, C<!!perl/regexp> -- and an
unblessed one as C<!!perl/ref> or C<!!perl/code>, while
L<File::SOPS::Encrypted/detect_type> calls the leaf C<str> so the MAC digest
covers its B<stringification>. The document and its own MAC then state
different things, and the file is unreadable to sops and to this module alike.
Until 0.003 it was written anyway, without a word; now it dies naming the class
(never the value).

The exception is an exact L<JSON::PP::Boolean>, which this emitter writes as
bare C<true> / C<false> -- the one reference whose document form and digest
agree. A B<subclass> of it is not covered: C<detect_type> calls it C<bool> but
L<YAML::XS> writes it as a tag, so it is refused like any other object.

Only leaves that reach the document B<verbatim> can trigger this -- values
excluded by the encryption rules, everything in a plaintext document, and the
C<sops> section. A value that gets encrypted is an C<ENC[...]> string by the
time this method sees it, so an object in an encrypted slot is unaffected and
still stores its stringification as C<type:str>. L<File::SOPS::Format::JSON>
has refused the same leaves all along; see
L<docs/adr/0008|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0008-a-leaf-the-emitter-cannot-write-as-what-the-digest-covers-is-refused.md>.

=head2 format_name

Returns C<'yaml'>.

=head2 file_extensions

Returns a list of file extensions: C<('yaml', 'yml')>.

=head2 detect

    if (File::SOPS::Format::YAML->detect($filename)) {
        # File is YAML based on extension
    }

Class method to detect if a filename is YAML based on extension.

Returns true if filename ends with C<.yaml> or C<.yml> (case-insensitive).

=head1 SEE ALSO

=over 4

=item * L<File::SOPS> - Main SOPS interface

=item * L<YAML::XS> - YAML parser/serializer

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-file-sops/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
