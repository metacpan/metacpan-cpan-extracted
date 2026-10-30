package Mail::DKIM2::Common;
use 5.20.0;
use strict;
use warnings;

our $VERSION = '0.28';

use Carp ();
use B ();
use Encode ();
use MIME::Base64 qw(encode_base64 decode_base64);
use JSON;
use Crypt::PK::RSA;
use Crypt::PK::Ed25519;
use Crypt::Digest::SHA256 qw(sha256 sha256_b64 sha256_hex);

use Email::MIME;
use Mail::DKIM2::TagValueList ();
use Email::MIME::ContentType ();

use Exporter 'import';
our @EXPORT_OK = qw(
    should_skip
    split_any_all
    combine_sets
    parse_mime
    check_ignore_prefixes
    dkim2_canonicalize_header
    dkim2_canonicalize_sig_header
    digest64
    encode_tag_json
    decode_tag_json
    fold_header
    fold_value
    build_signing_input
    extract_mi_version
    mi_version_tag
    strip_mi_versions
    extract_domain
    domain_of
    to_alabel
    from_domain
    from_authentic
    from_refusal_note
    to_rfc5321_path
    relaxed_domain_match
    parse_dkim_pubkey
    parse_dkim_key_record
    load_private_key
    load_private_key_data
    DKIM2_DRAFT
    DKIM2_REPO
    DKIM2_DATE
    MAX_CHAIN_LENGTH
    MAX_CHAIN_NUMBER
    MAX_SIGNATURE_ITEMS
    FUTURE_LIMIT
    EXPIRY
    chain_length_error
    valid_sequence
    UNKEYABLE_SIGNATURE_ERROR
    MI_MISSING_M_ERROR
    unkeyable_signature_error
    chain_number_error
    duplicate_number_error
);

# Provenance emitted in X-DKIM2-Info headers by the milter, the reflector, and
# the mailman/sympa handlers. This is the single source of truth for the Perl
# implementation. DKIM2_DRAFT is the spec revision implemented; DKIM2_DATE is
# the date this implementation's DKIM2 behaviour last changed (a software
# version stamp, not the draft's date) -- bump it on any change to what we
# emit, not only on a spec bump. See ../spec/draft-gondwana-dkim2-debug-header.
use constant DKIM2_DRAFT => 'ietf-dkim-dkim2-spec-08';
use constant DKIM2_REPO  => 'github.com/dkim2wg/interop';
use constant DKIM2_DATE  => '2026-10-28';

# -08 section 14.3: a DKIM2-Signature whose t= is more than a day after
# delivery is "from the future", and one made more than 14 days before it
# has "expired". Seconds.
use constant FUTURE_LIMIT => 86400;
use constant EXPIRY       => 14 * 86400;

# Local policy, not -08: a message carrying more Message-Instance or
# DKIM2-Signature fields than this is a PERMERROR, found before any key is
# fetched, signature checked or recipe applied. Every hop costs a verifier a
# DNS lookup, a signature check and an undo of the whole message, and the
# sender chooses how many hops there are.
use constant MAX_CHAIN_LENGTH => 32;

# The largest number a DKIM2-Signature i= or m=, or a Message-Instance m=, may
# be written as: at most three ASCII digits naming 1..100. Anything else is
# malformed before it is ever compared with MAX_CHAIN_LENGTH, and is never
# converted to a number big enough to be a loop bound.
use constant MAX_CHAIN_NUMBER => 100;

# Local policy, not -08: the most items one DKIM2-Signature's s= may carry.
# -08 dropped its own limit, and every item may cost a key lookup and a
# signature check, so a crafted s= of thousands of selectors would cost
# thousands of each (the -08 contract, D3). The same limit as the key
# prefetch's; refused before any key is fetched.
use constant MAX_SIGNATURE_ITEMS => 8;

# Headers excluded from hashing per draft-ietf-dkim-dkim2-spec-08 Section 4.
# spec-05 narrowed the old /^arc-/ prefix to the three RFC 8617 field names and
# added a /^received-/ prefix rule so future trace fields of that form need no
# change here. spec-08 took auto-submitted and vbr-info off the list.
my %SKIP_EXACT = map { $_ => 1 } qw(
    apparently-to arc-authentication-results arc-message-signature arc-seal
    authentication-results delivered-to dkim-signature
    dkim2-signature dl-expansion-history message-instance original-recipient
    received return-path sio-label-history x400-received x400-trace
);

# should_skip($name, \@prefixes)
#
# True when the field is excluded from the header hash: by the spec's list
# above, or by one of the caller's prefixes. The prefixes are an operator's
# own field names, put on the wrong side of the signature by its own systems:
# added at its border on the way in, stripped at its border on the way out.
# A signer that hashed one would sign a message no recipient ever sees; a
# verifier that hashed one would fail the operator's own forwards. The spec
# knows nothing of them and neither does a remote verifier, so the operator
# also has to make sure no field with one of these names ever leaves its
# network. They are local policy, so they travel as an argument -- never as
# state shared by every Signer and Verifier in the process.
# The IgnorePrefixes option as every entry point validates it: undef, or an
# array reference. A bare string is a configuration mistake and croaks, so it
# does not surface later as a 'fail' on every message.
sub check_ignore_prefixes {
    my ($prefixes) = @_;
    return unless defined $prefixes;
    Carp::croak("IgnorePrefixes must be an array reference of header-name prefixes")
        unless ref $prefixes eq 'ARRAY';
    return $prefixes;
}

sub should_skip {
    my ($name, $prefixes) = @_;
    my $hname = lc $name;
    return 1 if $SKIP_EXACT{$hname};
    return 1 if $hname =~ m/^x-/;
    return 1 if $hname =~ m/^received-/;
    return 1 if $prefixes && grep { index($hname, lc $_) == 0 } @$prefixes;
    return 0;
}

# The PERMERROR for a message over MAX_CHAIN_LENGTH, or undef. Takes an
# Email::MIME, or a hashref of field counts keyed by lower-cased name for a
# caller counting as it parses.
sub chain_length_error {
    my ($msg) = @_;
    for my $field ('Message-Instance', 'DKIM2-Signature') {
        my $count = ref($msg) eq 'HASH'
                  ? ($msg->{lc $field} // 0)
                  : scalar(my @values = $msg->header_raw($field));
        return "PERMERROR: more than " . MAX_CHAIN_LENGTH . " $field fields"
            if $count > MAX_CHAIN_LENGTH;
    }
    return;
}

# A DKIM2-Signature's i= must be a positive integer (ASCII digits) for the
# signature to be placed in the chain and keyed. One that is not -- no i=,
# i=, i=0, i=abc, or a header that does not parse -- is a PERMERROR, never
# silently skipped: a signer gate that counts which instances are signed by
# m= must not be fooled by a junk signature naming an m=.
# The -07 C6 forms: a missing i= is "i= tag=i missing" (there is no number
# to name the field by); one that is not a positive integer is named as
# written, "i=<value> syntax error" (unkeyable_signature_error).
use constant UNKEYABLE_SIGNATURE_ERROR =>
    'PERMERROR: DKIM2-Signature i= tag=i missing';

# The same for a Message-Instance with no m= tag: nothing to name it by.
use constant MI_MISSING_M_ERROR =>
    'PERMERROR: Message-Instance m= tag=m missing';

# The PERMERROR for a DKIM2-Signature header value that no verifier can
# key: UNKEYABLE_SIGNATURE_ERROR without an i= tag, else "PERMERROR:
# DKIM2-Signature i=<as written> syntax error".
sub unkeyable_signature_error {
    my ($contents) = @_;
    my $i = _raw_tag($contents, 'i');
    return defined $i ? "PERMERROR: DKIM2-Signature i=$i syntax error"
                      : UNKEYABLE_SIGNATURE_ERROR;
}

# The raw value of a tag in a header value (whitespace removed), or undef.
sub _raw_tag {
    my ($header, $tag) = @_;
    return unless defined $header;
    for my $part (split /;/, $header) {
        next unless $part =~ /\A\s*\Q$tag\E\s*=(.*)\z/si;    # tag names are case insignificant
        (my $v = $1) =~ s/\s//g;
        return $v;
    }
    return;
}

sub valid_sequence {
    my ($i) = @_;
    return (defined $i && $i =~ /\A[0-9]+\z/ && $i > 0) ? 1 : 0;
}

# The PERMERROR for an i= or m= value that is not a chain number, or undef
# (also undef for a missing value, which is left to the callers). A value must
# be 1*DIGIT in ASCII -- "4294967297x" is malformed, never its digit prefix --
# with at most three digits naming 1..MAX_CHAIN_NUMBER, so "01" and "001" are
# 1; and since each number names one hop, no more than MAX_CHAIN_LENGTH.
# Checking this before anything walks 1..max keeps a value like
# 99999999999999999999 from being used as a loop bound.
#
# The field is named by its own number as written (a DKIM2-Signature by its
# i=, a Message-Instance by its m=, -07 C6): $ident, defaulting to $n. So a
# signature's bad m= is "DKIM2-Signature i=2 syntax error", and an
# out-of-range one "DKIM2-Signature i=2 m=101 exceeds ...".
sub chain_number_error {
    my ($field, $tag, $n, $ident) = @_;
    return unless defined $n;
    my $id_tag = $field eq 'Message-Instance' ? 'm' : 'i';
    my $who = "$field $id_tag=" . ($ident // $n);
    return "PERMERROR: $who syntax error"
        unless $n =~ /\A[0-9]+\z/ && $n =~ /[1-9]/;
    $who .= " $tag=$n" if $tag ne $id_tag;
    return "PERMERROR: $who exceeds the maximum chain number of "
        . MAX_CHAIN_NUMBER if length($n) > 3 || $n > MAX_CHAIN_NUMBER;
    return "PERMERROR: $who exceeds the maximum chain length of "
        . MAX_CHAIN_LENGTH if $n > MAX_CHAIN_LENGTH;
    return;
}

# The PERMERROR for the lowest number that appears twice among a field's
# m= or i= values, or undef. Each number names one hop, so a second field
# with the same number is never a valid chain, and taking either one would
# let the other go unchecked.
sub duplicate_number_error {
    my ($field, $tag, @numbers) = @_;
    my %count;
    $count{$_ + 0}++ for grep { defined } @numbers;
    # The lowest number given twice (interop contract C9), not the first met.
    my ($n) = sort { $a <=> $b } grep { $count{$_} > 1 } keys %count;
    return defined $n ? "PERMERROR: $field $tag=$n appears more than once" : undef;
}

# The groups of an h= or s= value (-08 sections 9.3, 10.9): any-of groups
# split by "|", each an all-of list split by ",", as [[item, ...], ...] with
# each item's text untrimmed (its own parser trims the FWS around it). Undef
# when a member is empty -- a leading, trailing or doubled "|" or "," -- which
# is a syntax error (the -08 contract, D2).
sub split_any_all {
    my ($value) = @_;
    my @groups;
    for my $group (split /\|/, $value, -1) {
        my @items = split /,/, $group, -1;
        return if !@items || grep { /\A[ \t\r\n]*\z/ } @items;
        push @groups, \@items;
    }
    return \@groups;
}

# combine_sets(\@groups, $none_passed) -> ($state, $text): the result of an
# h= or s= value from its members' own (-08 sections 14.6, 14.7). @groups is
# [[[$state, $text], ...], ...] -- the "|" groups of "," lists, in the
# order the value gives them -- with each $state one of pass, fail,
# temperror, permerror and $text the member's own error. An all-of list
# passes if every member does; is a temperror if every member that does not
# is one; else fails if any member fails; else is a permerror. The any-of
# groups pass if one does; else are a temperror if one is; else fail if one
# does; else are a permerror. The text (contract D3/D4): with one group, the
# first member whose state is the result's; with several, $none_passed for a
# fail, else the first member anywhere whose state is the result's.
sub combine_sets {
    my ($groups, $none_passed) = @_;
    my @all;
    for my $g (@$groups) {
        my @bad = grep { $_->[0] ne 'pass' } @$g;
        push @all, !@bad                                    ? 'pass'
                 : !grep({ $_->[0] ne 'temperror' } @bad)   ? 'temperror'
                 : grep({ $_->[0] eq 'fail' } @bad)         ? 'fail'
                 :                                            'permerror';
    }
    my %have = map { $_ => 1 } @all;
    my ($state) = grep { $have{$_} } qw(pass temperror fail permerror);
    return ('pass') if $state eq 'pass';
    return ($state, $none_passed) if @$groups > 1 && $state eq 'fail';
    my @members = @$groups == 1 ? @{ $groups->[0] } : map { @$_ } @$groups;
    my ($first) = grep { $_->[0] eq $state } @members;
    return ($state, $first->[1]);
}

# DKIM2 header canonicalization for HEADER HASH per -08 Section 5.2:
# 1. Lowercase header name
# 2. Unfold continuation lines (remove CRLF before WSP)
# 3. Collapse runs of WSP to single SP
# 4. Strip trailing WSP before CRLF
# 5. Remove WSP around the colon
sub dkim2_canonicalize_header {
    my ($line) = @_;
    # Unfold: remove CRLF followed by WSP
    $line =~ s/\r?\n[ \t]/ /g;
    # Split on colon
    my ($name, $value) = split(/:/, $line, 2);
    return $line unless defined $value;
    # Lowercase name
    $name = lc($name);
    # Collapse WSP runs to single SP
    $value =~ s/[ \t]+/ /g;
    # Strip leading and trailing WSP from value
    $value =~ s/^[ \t]+//;
    $value =~ s/[ \t]*\r?\n?$//;
    return "$name:$value\r\n";
}

# DKIM2 header canonicalization for SIGNATURE INPUT per -08 Section 12.8:
# Same as header hash canonicalization except step 3 deletes ALL WSP
# characters rather than collapsing to single SP.
sub dkim2_canonicalize_sig_header {
    my ($line) = @_;
    # Unfold: remove CRLF followed by WSP
    $line =~ s/\r?\n[ \t]//g;
    # Split on colon
    my ($name, $value) = split(/:/, $line, 2);
    return $line unless defined $value;
    # Lowercase name
    $name = lc($name);
    # Delete ALL WSP characters
    $value =~ s/[ \t]+//g;
    # Strip trailing CRLF/LF
    $value =~ s/\r?\n?$//;
    return "$name:$value\r\n";
}

# Base64-encode a digest object (CryptX b64digest includes padding)
sub digest64 {
    my ($sha) = @_;
    return $sha->b64digest;
}

# Encode data as base64 JSON for a tag value
sub encode_tag_json {
    my ($data) = @_;
    return encode_base64(JSON->new->canonical(1)->encode($data), '');
}

# Decode a base64 JSON tag value. The JSON text must be UTF-8 (RFC 8259
# section 8.1; -08 section 5): anything else dies. Every string in the
# result, object keys included, is UTF-8 octets, as the message's own
# header values and body lines are, so a literal compares and hashes
# byte for byte; a string holding a lone surrogate (a "\ud800" escape) is
# not UTF-8 and dies too.
sub decode_tag_json {
    my ($b64) = @_;
    my $octets = decode_base64($b64);
    my $text = eval { Encode::decode('UTF-8', $octets, Encode::FB_CROAK() | Encode::LEAVE_SRC()) };
    die $@ if ref $@;
    die "JSON text is not UTF-8\n" unless defined $text;
    my $data = JSON->new->decode($text);
    # A key given twice in one object is invalid here: JSON parsers disagree
    # on which value wins (first or last), so {"b":[...],"b":null} would be a
    # null body Recipe to some verifiers and signers and a real one to others.
    # A key that is not lowercase is invalid too (-08 §5).
    if (defined(my $error = _json_lexical_error($text))) {
        die $error;
    }
    return _json_octets($data);
}

# A decoded JSON value with every string -- object keys included --
# turned into UTF-8 octets. Numbers and booleans are returned untouched:
# MessageInstance tells a JSON integer from a JSON string by its flags.
sub _json_octets {
    my ($v) = @_;
    return { map { _json_octet_string($_) => _json_octets($v->{$_}) } keys %$v }
        if ref $v eq 'HASH';
    return [ map { _json_octets($_) } @$v ] if ref $v eq 'ARRAY';
    return $v if !defined $v || ref $v;
    return $v unless B::svref_2object(\$v)->FLAGS & B::SVf_POK;
    return _json_octet_string($v);
}

sub _json_octet_string {
    my ($s) = @_;
    die "JSON string is not UTF-8\n" if $s =~ /[\x{D800}-\x{DFFF}]/;
    utf8::encode($s);
    return $s;
}

# True if $octets is valid UTF-8 (ASCII included): strict, so no surrogate,
# nothing above U+10FFFF, no overlong form. Internal.
sub _is_utf8_octets {
    my ($octets) = @_;
    return 1 unless $octets =~ /[^\x00-\x7F]/;
    my $ok = eval { Encode::decode('UTF-8', $octets, Encode::FB_CROAK() | Encode::LEAVE_SRC()); 1 };
    die $@ if ref $@;
    return $ok ? 1 : 0;
}

# The first problem the decoded value cannot show in $text (already known to
# be valid JSON), or undef: a key that is not lowercase (has an ASCII
# capital), a key that appears twice in one object, compared after
# unescaping, or a number with a fraction or
# an exponent. Every number in a Recipe is an integer (-08 section 5), and
# whether 1e0 decodes as an integer depends on the JSON backend -- JSON::XS
# gives an NV, JSON::PP an IV -- so it is refused here, from the text.
sub _json_lexical_error {
    my ($text) = @_;
    my $json = JSON->new->allow_nonref;
    my @stack;   # one entry per open container: undef for an array, a hash of keys for an object
    my $want_key = 0;
    pos($text) = 0;
    while (pos($text) < length $text) {
        if ($text =~ /\G\s+/gc) { next }
        if ($text =~ /\G\{/gc) { push @stack, {}; $want_key = 1; next }
        if ($text =~ /\G\[/gc) { push @stack, undef; $want_key = 0; next }
        if ($text =~ /\G[\}\]]/gc) { pop @stack; $want_key = 0; next }
        if ($text =~ /\G,/gc) { $want_key = ref $stack[-1] ? 1 : 0; next }
        if ($text =~ /\G:/gc) { next }
        if ($text =~ /\G("(?:[^"\\]|\\.)*")/gcs) {
            if ($want_key && ref $stack[-1]) {
                my $k = $json->decode($1);
                # -08 §5: keys MUST be lowercase (the -08 contract, D10).
                return "JSON object key is not lowercase\n" if $k =~ /[A-Z]/;
                return "duplicate JSON object key\n" if $stack[-1]{$k}++;
                $want_key = 0;
            }
            next;
        }
        $text =~ /\G([^\s,:\[\]\{\}"]+)/gc or last;   # number, true, false, null
        return "JSON number is not an integer\n" if $1 =~ /^-?[0-9].*[.eE]/;
    }
    return;
}

# Fold a header line at 72 characters.
# Fold a header line to $margin characters (default 72).
# Only for headers we are creating — never for headers read from elsewhere.
# First tries to fold at "; " tag boundaries, then breaks any remaining
# long segments at character positions.
# Input: a complete header line like "DKIM2-Signature: i=1; v=1; ..."
# Output: folded with "\r\n\t" continuation lines
# Tab = 8 chars visually, so continuation lines get 64 chars of content.
# First line target: 72 chars.  Continuation: 64 content + 8 tab = 72.
# Parse a message with Email::MIME for the verifier's and the Message-Instance
# code's purposes: raw header fields and the raw body. DKIM2 never reads MIME
# parameters, so a sender's broken Content-Type -- `text/plain; Windows-1252`
# and worse, as 2003 spam and some list software emit -- must not stop a
# message from being verified. Email::MIME::ContentType croaks on such a
# parameter by default; relax that for the duration of the parse only (it is
# a package variable, and the host application's own parsing keeps its
# setting). Found 2026-10-04 replaying the SpamAssassin corpus through a list.
sub parse_mime {
    my ($raw) = @_;
    local $Email::MIME::ContentType::STRICT_PARAMS = 0;
    local $SIG{__WARN__} = sub { };   # the relaxed parser warns instead
    return Email::MIME->new($raw);
}

sub fold_header {
    my ($line, $margin, %opts) = @_;
    _check_options('fold_header', \%opts, qw(delimiters_only));
    $margin //= 72;
    # delimiters_only: break only after a ";" or a "," -- never at a space,
    # never mid-token. For X-DKIM2-Info (draft-gondwana-dkim2-debug-header-01
    # Section 5): a consumer ignores whitespace next to ";" and ",", and an
    # emitter MUST NOT fold inside a token, so a hex digest or a quoted detail
    # that will not fit stays whole on an over-long line (RFC 5322's 78 is a
    # SHOULD; its 998 is the MUST, and nothing here approaches it).
    my $delimiters_only = $opts{delimiters_only};
    my $cont_margin = $margin - 8;  # content chars on continuation lines

    return $line if length($line) <= $margin;

    my @folded;
    my $remaining = $line;
    my $limit = $margin;
    my %fold_state;    # where the emitted text ends: see _dkim2_fold_feed

    while (length($remaining) > $limit) {
        # Find the best break point: prefer "; " boundaries, then
        # any space.  Look backwards from the limit.
        my $break = -1;

        # Try to break at "; " (tag boundary)
        my $search = substr($remaining, 0, $limit);
        my $pos = rindex($search, '; ');
        if ($pos > 0) {
            # Break after the semicolon, before the space
            $break = $pos + 1;
        }

        # If no tag boundary, try breaking at any space
        if ($break < 0 && !$delimiters_only) {
            $pos = rindex($search, ' ');
            $break = $pos if $pos > 0;
        }

        # If a space occurs within 2 chars before the limit, fold at
        # the space rather than leaving a 1-2 char orphan before the
        # next forced break.
        if (!$delimiters_only && ($break < 0 || $limit - $break <= 2)) {
            # Check for a space near the limit
            for my $i (reverse ($limit - 3)..($limit - 1)) {
                next if $i < 0 || $i >= length($remaining);
                if (substr($remaining, $i, 1) eq ' ') {
                    $break = $i;
                    last;
                }
            }
        }

        # A list-valued tag (the hn= header-name list in X-DKIM2-Info) has
        # no spaces at all, so break after a comma rather than in the middle
        # of a name: "lis" + "t-help" is not a header field that exists.
        if ($break < 0 && $delimiters_only) {
            $pos = rindex($search, ',');
            $break = $pos + 1 if $pos > 0;
        }

        # Delimiters only and none before the limit: take the first one
        # after it, or give up and leave the rest whole.
        if ($break < 0 && $delimiters_only) {
            my ($semi, $comma) = (index($remaining, ';', $limit), index($remaining, ',', $limit));
            my @after = sort { $a <=> $b } grep { $_ >= 0 } $semi, $comma;
            last unless @after && $after[0] < length($remaining) - 1;
            $break = $after[0] + 1;
        }

        # A DKIM2 field: the latest point before the limit where its grammar
        # allows FWS (_dkim2_fold_ok), else the first one after it. A token
        # with no such point -- a long d= Domain -- stays whole on an
        # over-long line rather than being split into a different value
        # (follow-up review F2). One pass, carrying the tag state forward a
        # character at a time: an s= of thousands of items folds in linear
        # time.
        if ($break < 0) {
            my %st = %fold_state;
            for my $i (1 .. length($remaining) - 1) {
                last if $i > $limit && $break >= 0;
                my $prev = substr($remaining, $i - 1, 1);
                _dkim2_fold_feed(\%st, $prev);
                next unless $prev eq ';' || _dkim2_fold_ok(\%st, $prev, substr($remaining, $i, 1));
                if ($i <= $limit) { $break = $i; next }
                $break = $i if $break < 0;
                last;
            }
            last if $break < 0;
        }

        my $chunk = substr($remaining, 0, $break);
        $remaining = substr($remaining, $break);

        # Strip trailing WSP from chunk, leading WSP from remainder
        $chunk =~ s/\s+$//;
        $remaining =~ s/^\s+//;

        _dkim2_fold_feed(\%fold_state, $_) for split //, $chunk;
        push @folded, $chunk;
        $limit = $cont_margin;
    }
    push @folded, $remaining if length($remaining);

    # RFC 5322 §2.1.1: 998 is a MUST. Nothing a DKIM2 signer emits has a
    # token that long, so this is a caller error, not a field to send.
    if (!$delimiters_only) {
        for (@folded) {
            Carp::croak("fold_header: a line exceeds 998 characters with no place to fold")
                if length > 998;
        }
    }

    return join("\r\n\t", @folded);
}

# fold_header's view of a DKIM2 field read so far, one character at a time:
# the current tag's name (undef until its "=", with the text before it in
# pending) and how many ":" the current list item has had.
sub _dkim2_fold_feed {
    my ($st, $c) = @_;
    if ($c eq ';') { %$st = (); return }
    if (!defined $st->{name}) {
        $st->{pending} .= $c;
        return unless $c eq '=';
        ($st->{name}) = $st->{pending} =~ /\A\s*(?:[A-Za-z0-9-]+:\s*)?([A-Za-z][A-Za-z0-9_]*)\s*=\z/;
        $st->{name} = defined $st->{name} ? lc $st->{name} : '';
        $st->{colons} = 0;
        return;
    }
    if    ($c eq ',' || $c eq '|') { $st->{colons} = 0 }
    elsif ($c eq ':') { $st->{colons}++ }
}

# May the field fold between $prev and $next, in state $st (_dkim2_fold_feed,
# fed up to and including $prev)? The grammars (-08 §9, §10) allow FWS
# inside a base64string (§2.13) and in a few list positions, and nowhere in
# a Domain, selector, algorithm or hash name, so only these are offered:
#   - between two base64 characters of mf=, rt=, r=, of an h= digest (after
#     the hash name's ":"), or of an s= signature value (after both ":"s);
#   - on either side of a ":" in s= and h=, and of a "," or "|" joining
#     their members (-08 §9.3, §10.9);
#   - after a "," in any other list: f= allows FWS around commas, a
#     base64string (rt=) may start with FWS, and an unknown tag's
#     x-tag-value allows FWS between characters (X-DKIM2-Info's hn= list
#     folds here too).
sub _dkim2_fold_ok {
    my ($st, $prev, $next) = @_;
    my $name = $st->{name};
    return 0 unless defined $name && length $name;
    # sig-set and hash-set allow FWS on either side of their ":"s, and the
    # lists of them on either side of each "," and "|" (§10.9, §9.3) -- but
    # not after a header hash, before the ":" ending it: its padding is
    # the end of the base64string, and the grammar has no FWS there.
    return 0 if $prev eq '=' && $next eq ':';
    return 1 if ($name eq 's' || $name eq 'h')
             && grep { $_ eq ':' || $_ eq ',' || $_ eq '|' } $prev, $next;
    return 1 if $prev eq ',';
    return 0 unless $prev =~ m{[A-Za-z0-9+/=]} && $next =~ m{[A-Za-z0-9+/=]};
    return 1 if $name eq 'mf' || $name eq 'rt' || $name eq 'r';
    return $st->{colons} >= 1 if $name eq 'h';
    return $st->{colons} >= 2 if $name eq 's';
    return 0;
}

# Fold a string at arbitrary character positions.
# Only safe for content that has NOT been signed — e.g. the s= tag value
# after signature computation but before insertion into the message.
sub fold_value {
    my ($line, $margin) = @_;
    $margin //= 64;  # 64 content + 8 tab = 72 visible

    return $line if length($line) <= $margin;

    my @parts;
    while (length($line) > 0) {
        push @parts, substr($line, 0, $margin, '');
    }
    return join("\r\n\t", @parts);
}

# The raw m= value of a Message-Instance header value (whitespace removed,
# as MessageInstance->parse does), or undef if it has no m= tag.
sub mi_version_tag {
    my ($header) = @_;
    $header = $header->[0] if ref($header) eq 'ARRAY';
    $header = $$header if ref($header);
    return unless defined $header;
    for my $part (split /;/, $header) {
        next unless $part =~ /\A\s*m\s*=(.*)\z/s;    # tag-names are case-sensitive (-08 §8)
        (my $v = $1) =~ s/\s//g;
        return $v;
    }
    return;
}

# The m= number of a Message-Instance header value, or undef when it has no
# m= or the m= is not all ASCII digits (never a digit prefix). Numeric, so
# "01" and "001" are 1. Callers check chain_number_error(mi_version_tag(...))
# before using it as a bound.
sub extract_mi_version {
    my $v = mi_version_tag(@_);
    return unless defined $v && $v =~ /\A[0-9]+\z/;
    return length($v) <= 15 ? 0 + $v : $v;
}

# Strip Message-Instance headers with the given version numbers from a raw message string.
# The message must use CRLF line endings.  Returns the modified message string.
sub strip_mi_versions {
    my ($message, @versions) = @_;
    return $message unless @versions;
    my %to_strip = map { $_ => 1 } @versions;

    my $EOL = "\015\012";
    my $sep_pos = index($message, $EOL . $EOL);
    return $message if $sep_pos < 0;

    my $hdrs_raw = substr($message, 0, $sep_pos);
    my $rest     = substr($message, $sep_pos);   # includes blank line + body

    # Parse folded headers into whole-header strings
    my @entries;
    my $cur = '';
    for my $line (split /\015\012/, $hdrs_raw, -1) {
        if ($line =~ /^[ \t]/ && $cur ne '') {
            $cur .= $EOL . $line;
        } else {
            push @entries, $cur if $cur ne '';
            $cur = $line;
        }
    }
    push @entries, $cur if $cur ne '';

    # Keep all headers except Message-Instance ones with versions in %to_strip
    my @kept;
    for my $entry (@entries) {
        if ($entry =~ /^Message-Instance:/i) {
            my ($val) = $entry =~ /^[^:]+:\s*(.*)/s;
            if (defined $val) {
                $val =~ s/\015?\012[ \t]+/ /g;   # unfold for version extraction
                my $ver = extract_mi_version($val);
                next if defined $ver && $to_strip{$ver};
            }
        }
        push @kept, $entry;
    }

    return join($EOL, @kept) . $rest;
}

# Extract the domain from an email address (handles <user@domain> and user@domain)
sub extract_domain {
    my ($addr) = @_;
    return unless $addr;
    $addr =~ s/^.*<//;
    $addr =~ s/>.*$//;
    return unless $addr =~ /\@(.+)$/;
    return $1;
}

# Wrap an address as an RFC5321 reverse-/forward-path for mf=/rt= (spec
# §9.5/§9.6): angle brackets MUST be present. Empty/undef -> "<>"; an
# already-bracketed value (incl. "<>") is returned unchanged.
sub to_rfc5321_path {
    my ($addr) = @_;
    return '<>' unless defined $addr && length $addr;
    return $addr if $addr =~ /^<.*>$/s;
    return "<$addr>";
}

# domain_of($addr): the domain of an address or path, as ($domain,
# $is_literal), or the empty list when there is none (no "@", or "<>").
# The text between the last "@" and the closing ">" (or the end),
# lowercased, with one trailing dot taken off: Postfix hands on
# "<A@Example.COM.>" as it was given. A domain literal ("[192.0.2.1]") is
# returned with $is_literal true; it never matches anything (-08 section
# 7.2).
sub domain_of {
    my ($addr) = @_;
    return unless defined $addr;
    my $at = rindex($addr, '@');
    return if $at < 0;
    my $dom = substr($addr, $at + 1);
    $dom =~ s/>.*\z//s;
    $dom =~ s/\A\s+|\s+\z//g;
    $dom =~ tr/A-Z/a-z/;    # ASCII only: the octets may be UTF-8
    $dom =~ s/\.\z//;
    return unless length $dom;
    return ($dom, $dom =~ /\A\[/ ? 1 : 0);
}

# to_alabel($domain): $domain with each label that is not ASCII lowercased
# and written as its A-label, "xn--" and the RFC 3492 Punycode of the label
# (-08 section 18). ASCII labels are left as they are. The input is UTF-8
# octets, as a header field or a decoded mf=/rt= carries it (a character
# string is taken as it is); a label that is not valid UTF-8 is left alone.
# This is the label mapping only, not UTS 46.
sub to_alabel {
    my ($domain) = @_;
    return $domain unless defined $domain && $domain =~ /[^\x00-\x7F]/;
    require URI::_punycode;
    return join '.', map {
        my $label = $_;
        if ($label =~ /[^\x00-\x7F]/) {
            my $chars = utf8::is_utf8($label) ? $label
                : eval { Encode::decode('UTF-8', $label, Encode::FB_CROAK() | Encode::LEAVE_SRC()) };
            die $@ if ref $@;
            $label = 'xn--' . URI::_punycode::encode_punycode(lc $chars) if defined $chars;
        }
        $label;
    } split /\./, $domain, -1;
}

# from_domain(@values): the domain a From header field is Authentic for
# (-08 section 11), from the values of every From field in one version of
# the header (each as header_raw gives it, folded or not): the lowercased
# A-label domain of its one mailbox, or undef when there is none -- no From
# field or more than one, a field that is not exactly one mailbox (a list
# of them, a group), no "@", or a domain literal. Lenient otherwise: the
# display name, quoted or RFC 2047 encoded, and comments are skipped; the
# mailbox is "Name <addr>" or a bare addr-spec ("Name addr", display text
# with no angle brackets, is not one).
sub from_domain {
    my (@values) = @_;
    return undef unless @values == 1 && defined $values[0];
    (my $v = $values[0]) =~ s/\r?\n(?=[ \t])//g;
    # One pass: comments dropped, quoted strings kept whole, and the
    # structure outside them ($skel) and the angle brackets found.
    my ($out, $skel, $depth, $inq, @lt, @gt) = ('', '', 0, 0);
    for (my $i = 0; $i < length $v; $i++) {
        my $c = substr($v, $i, 1);
        if ($inq) {
            if ($c eq '\\') { $out .= substr($v, $i++, 2); next }
            $inq = 0 if $c eq '"';
            $out .= $c;
            next;
        }
        if ($depth) {
            if    ($c eq '\\') { $i++ }
            elsif ($c eq '(')  { $depth++ }
            elsif ($c eq ')')  { $depth-- }
            next;
        }
        if ($c eq '(') { $depth = 1; $out .= ' '; next }
        if ($c eq '"') { $inq = 1; $out .= $c; next }
        push @lt, length $out if $c eq '<';
        push @gt, length $out if $c eq '>';
        $skel .= $c;
        $out  .= $c;
    }
    return undef if $inq || $depth;
    # A "," is a second mailbox; a ":" or ";" a group (or an obsolete route).
    return undef if $skel =~ /[,:;]/;
    my $addr = $out;
    if (@lt || @gt) {
        return undef unless @lt == 1 && @gt == 1 && $lt[0] < $gt[0]
                         && substr($out, $gt[0] + 1) !~ /\S/;
        $addr = substr($out, $lt[0] + 1, $gt[0] - $lt[0] - 1);
    }
    $addr =~ s/\A\s+|\s+\z//g;
    # White space (or a comment) between two parts of the address: "Name
    # a@b", display text with no angle brackets, is not one mailbox.
    return undef if ($addr =~ s/"(?:[^"\\]|\\.)*"/""/gr) =~ /\s/;
    return undef unless index($addr, '@') > 0;
    my ($dom, $literal) = domain_of($addr);
    return undef if !$dom || $literal || $dom =~ /\s/;
    return to_alabel($dom) =~ tr/A-Z/a-z/r;
}

# from_authentic($d, @values): true if the From field(s) of one version of
# the header, as from_domain takes them, are Authentic for signing domain
# $d: from_domain gives a domain and it relaxed-matches $d (-08 section 11).
sub from_authentic {
    my ($d, @values) = @_;
    my $dom = from_domain(@values);
    return defined $dom && relaxed_domain_match($dom, $d) ? 1 : 0;
}

# from_refusal_note($d, @values): for the log of a signer's From refusal,
# the From domain against the signing domain $d, with what to do about it
# (final review I3): a DKIM2 list rewrites From to its posting address, and
# a milter signing with a domain that is not that one's, or above it,
# refuses every post.
sub from_refusal_note {
    my ($d, @values) = @_;
    my $from = from_domain(@values);
    unless (defined $from) {
        if (@values == 1 && defined $values[0]) {
            (my $text = $values[0]) =~ s/[\r\n]+/ /g;
            $text =~ s/\A\s+|\s+\z//g;
            $from = '(not one mailbox: ' . substr($text, 0, 100) . ')';
        } else {
            $from = '(' . scalar(@values) . ' From fields)';
        }
    }
    return "From domain $from is not d=" . ($d // '(none)') . " or below it: a DKIM2 "
         . "list's posting address must be in the domain this milter signs with";
}

# relaxed_domain_match($p1, $p2): the relaxed domain match of -08 section
# 7.2. Both are compared as A-labels, without regard to case, and without
# one trailing dot. A domain literal on either side never matches. Otherwise
# labels come off the LEFT of $p1 only, until it equals $p2 (a match) or
# has no dot left (no match): so $p1 may be $p2 or below it, never above.
sub relaxed_domain_match {
    my ($p1, $p2) = @_;
    return 0 unless defined $p1 && defined $p2 && length $p1 && length $p2;
    ($p1, $p2) = map { my $d = to_alabel($_) =~ tr/A-Z/a-z/r; $d =~ s/\.\z//; $d } $p1, $p2;
    return 0 if $p1 =~ /\A\[/ || $p2 =~ /\A\[/;
    while (1) {
        return 1 if $p1 eq $p2;
        $p1 =~ s/\A[^.]*\.// or return 0;
    }
}

# Build the signing input for DKIM2 signature signing/verification.
# Args (hash):
#   mi_headers  => arrayref of { v => N, raw => "..." } sorted by v ascending
#   dk2_headers => arrayref of { i => N, raw => "...", sig => $sig_obj } sorted by i ascending
#   signing_i   => the i= value being signed/verified (gets empty s= value)
#   signature   => the Signature object for the entry being signed/verified
#   signing_header => optional folded header string (signer path)
#
# Per draft-ietf-dkim-dkim2-spec-08 Section 10.5:
#   1. All Message-Instance headers in ascending v= order
#   2. All prior DKIM2-Signature headers in ascending i= order
#   3. The incomplete DKIM2-Signature (with empty s=) being signed/verified
sub build_signing_input {
    my (%args) = @_;
    my @mi_headers  = @{$args{mi_headers}  || []};
    my @dk2_headers = @{$args{dk2_headers} || []};
    my $signing_i   = $args{signing_i};
    my $signature   = $args{signature};

    my $signing_input = '';

    # 1. All MI headers in ascending m= order
    for my $mi (@mi_headers) {
        $signing_input .= dkim2_canonicalize_sig_header($mi->{raw});
    }

    # 2. Prior DKIM2-Signature headers (i < signing_i) in ascending i= order
    for my $dk2 (@dk2_headers) {
        next if $dk2->{i} == $signing_i;
        $signing_input .= dkim2_canonicalize_sig_header($dk2->{raw});
    }

    # 3. The incomplete signature being signed/verified
    # Signer passes signing_header (folded); verifier uses default (unfolded)
    my $sig_header = $args{signing_header} // $signature->as_string_without_data();
    $sig_header .= "\r\n" unless $sig_header =~ /\r\n$/;
    $signing_input .= dkim2_canonicalize_sig_header($sig_header);

    return $signing_input;
}

# Every eval in the library rethrows a reference: the library only ever dies
# with strings, so an object is the host's, typically a milter or MTA
# signalling a timeout, and swallowing it would let the caller run on past
# its deadline. That includes Reflector, Split and Validate, so the promise
# in Mail::DKIM2's CONVENTIONS holds without exceptions (review R16).

# A base64string (-08 §2.13), FWS already removed: base64 characters,
# padded with "=" to a multiple of four ("MUST be padded"). Internal.
sub _is_base64string {
    my ($s) = @_;
    return defined $s && length $s && length($s) % 4 == 0
        && $s =~ m{\A[A-Za-z0-9+/]+={0,2}\z};
}

# _check_options($what, \%opts, @known): croak on an option not in @known.
# Every public constructor and class method taking named options calls this
# first (Mail::DKIM2 CONVENTIONS: a misspelling is an error, not a silently
# ignored setting -- Algz => ['sha512'] used to compute SHA-256). Internal.
sub _check_options {
    my ($what, $opts, @known) = @_;
    my %known = map { $_ => 1 } @known;
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;    # blame our caller's caller
    for my $k (sort keys %$opts) {
        Carp::croak("unknown option $k for $what") unless $known{$k};
    }
    return;
}

# Parse and validate a key record (draft-ietf-dkim-dkim2-dns §3.2, §3.4.1;
# -08 §14.5 says a Verifier MUST NOT use a malformed one). Returns the
# key object, or (undef, $why) where $why completes "public key <selector>
# ...": "has a syntax error", "has been revoked" or "has an unsupported key
# type". The whole record is checked, not searched: a repeated tag (an empty
# p= before a good one, say) makes it invalid, and v=, if present, must be
# the first tag and exactly DKIM1. Tag names are case sensitive here, as in
# DKIM1. Unknown and retired tags (h=, n=, s=, t=) are ignored, once their
# values have passed the tag-list grammar.
sub parse_dkim_key_record {
    my ($txt) = @_;
    my $syntax = 'has a syntax error';
    return (undef, $syntax) unless defined $txt;
    my (%tag, @order);
    for my $spec (split /;/, $txt, -1) {
        next if $spec =~ /\A[ \t\r\n]*\z/;    # empty spec, e.g. after a trailing ";"
        my ($name, $value) = $spec =~ /\A[ \t\r\n]*([A-Za-z][A-Za-z0-9_]*)[ \t\r\n]*=(.*)\z/s
            or return (undef, $syntax);
        return (undef, $syntax) if exists $tag{$name};
        $value =~ s/\A[ \t\r\n]+|[ \t\r\n]+\z//g;
        # Every value, unknown tags' included, must fit the tag-list grammar
        # (RFC 6376 §3.2 VALCHAR): ignoring a tag comes after parsing it
        # (follow-up review F5).
        return (undef, $syntax) unless $value =~ /\A$Mail::DKIM2::TagValueList::TAG_VALUE\z/;
        $tag{$name} = $value;
        push @order, $name;
    }
    return (undef, $syntax) unless @order;
    if (exists $tag{v}) {
        return (undef, $syntax) unless $order[0] eq 'v' && $tag{v} eq 'DKIM1';
    }
    return (undef, $syntax) unless exists $tag{p};
    (my $p = $tag{p}) =~ s/[ \t\r\n]//g;
    return (undef, 'has been revoked') unless length $p;
    return (undef, $syntax) unless _is_base64string($p);
    my $k = $tag{k} // 'rsa';
    my $key = _key_from_p($k, $p);
    return $key if $key;
    # -08 §14.5 (contract D7): base64 that is not a usable key of its type.
    return (undef, $k eq 'rsa' || $k eq 'ed25519' ? 'is malformed' : 'has an unsupported key type');
}

# A key object from a valid record: the key, or nothing (a key type this
# library does not implement, or p= that is not a key of that type).
sub parse_dkim_pubkey {
    my ($key_txt) = @_;
    my ($key) = parse_dkim_key_record($key_txt);
    return $key;
}

sub _key_from_p {
    my ($k, $p) = @_;
    if ($k eq 'ed25519') {
        # -08 §14.5: an Ed25519 key is exactly 32 octets (RFC 8032), the
        # raw key; anything else -- a DER SubjectPublicKeyInfo included --
        # is malformed. Never die on one: return undef so the verifier
        # reports a clean permerror instead of aborting the whole operation
        # (the RSA branch below is likewise eval-wrapped).
        my $raw = decode_base64($p);
        return unless length($raw) == 32;
        my $key = eval {
            my $pk = Crypt::PK::Ed25519->new();
            $pk->import_key_raw($raw, 'public');
            $pk;
        };
        die $@ if ref $@;
        return $key;
    }
    # Any other key type is unrecognised, and ignored: never read as RSA.
    return unless $k eq 'rsa';
    # RSA: p= is base64-encoded SubjectPublicKeyInfo DER. -08 §3.2: a
    # Verifier MUST NOT validate with a key of less than 1024 bits.
    my $der = decode_base64($p);
    my $rsa = eval { Crypt::PK::RSA->new(\$der) };
    die $@ if ref $@;
    return unless $rsa && $rsa->size * 8 >= 1024;
    return $rsa;
}

# Load a private key from a PEM file.
# Returns a Crypt::PK::RSA or Crypt::PK::Ed25519 object depending on key type.
sub load_private_key {
    my ($file) = @_;
    # Try RSA first, then Ed25519
    my $key = eval { Crypt::PK::RSA->new($file) };
    die $@ if ref $@;
    return $key if $key;
    return Crypt::PK::Ed25519->new($file);
}

# Load a private key from key MATERIAL rather than a filename, for callers whose
# keys live in a database rather than on disk.
#
# Accepts PEM as stored, and also bare base64 with the armor stripped, which is
# how some key stores keep it. Returns a Crypt::PK::RSA or Crypt::PK::Ed25519
# object, or undef -- never dies, so a caller signing live mail can log and
# carry on rather than losing the message.
sub load_private_key_data {
    my ($data) = @_;
    return unless defined $data && length $data;

    if ($data =~ /-----BEGIN/) {
        my $key = eval { Crypt::PK::RSA->new(\$data) };
        die $@ if ref $@;
        return $key if $key;
        $key = eval { Crypt::PK::Ed25519->new(\$data) };
        die $@ if ref $@;
        return $key;
    }

    (my $b64 = $data) =~ s/\s+//g;
    return unless length $b64;
    my $der = eval { decode_base64($b64) };
    die $@ if ref $@;
    return unless defined $der && length $der;
    my $key = eval { Crypt::PK::RSA->new(\$der) };
    die $@ if ref $@;
    return $key if $key;
    $key = eval { Crypt::PK::Ed25519->new(\$der) };
    die $@ if ref $@;
    return $key;
}

1;

__END__

=encoding utf8

=head1 NAME

Mail::DKIM2::Common - Canonicalization, hashing, folding and key handling for DKIM2

=head1 SYNOPSIS

    use Mail::DKIM2::Common qw(
        should_skip dkim2_canonicalize_header fold_header
        load_private_key parse_dkim_pubkey
        extract_domain relaxed_domain_match
        DKIM2_DRAFT MAX_CHAIN_LENGTH
    );

    my $key = load_private_key('/etc/dkim2/sel1.pem');
    my $pub = parse_dkim_pubkey('v=DKIM1; k=rsa; p=MIIB...');

    my $folded = fold_header("Message-Instance: " . $mi->as_string);

=head1 DESCRIPTION

The functions the other modules share. Nothing is exported by default.
Those under L</CANONICALIZATION> and L</SIGNING INPUT> define bytes the
spec defines and are of interest to anyone checking this implementation
against another; the rest are conveniences.

This module implements draft-ietf-dkim-dkim2-spec-08; see L<Mail::DKIM2/STATUS>
for what that means for the wire format and the API, and
L<Mail::DKIM2/CONVENTIONS> for the option, input and error conventions every
module here follows.

=head1 CONSTANTS

=head2 DKIM2_DRAFT, DKIM2_REPO, DKIM2_DATE

The spec revision implemented (C<ietf-dkim-dkim2-spec-08>), where the
code lives, and the date this implementation's DKIM2 behaviour last
changed. Emitted in X-DKIM2-Info debug headers
(draft-gondwana-dkim2-debug-header).

=head2 MAX_CHAIN_LENGTH

32: a message carrying more Message-Instance or DKIM2-Signature fields
than this, or an C<i=> or C<m=> naming a larger number, is a PERMERROR,
found before any key is fetched. Local policy, not spec.

=head2 MAX_CHAIN_NUMBER

100: the largest number an C<i=> or C<m=> may be written as (at most
three digits). See L</chain_number_error($field, $tag, $n)>.

=head2 MAX_SIGNATURE_ITEMS

8: the most items one DKIM2-Signature's C<s=> may carry. Local policy:
-08 sets no limit, and each item may cost a key lookup and a signature
check. The Verifier refuses a field with more, before fetching any key,
as "has more than 8 signatures". New in 0.28.

=head1 CANONICALIZATION

=head2 should_skip($header_name, [\@prefixes])

True if the field is excluded from the header hash: the -08 section 4
list (C<Received>, C<Return-Path>, C<Message-Instance>,
C<DKIM2-Signature>, C<DKIM-Signature>, C<Authentication-Results>, the ARC
fields and others), any C<X-*> or C<Received-*> field, or a field whose
name starts with one of the caller's prefixes, case-insensitively. The
prefixes are an operator's local policy; pass them as C<IgnorePrefixes> to
L<Mail::DKIM2::Verifier> and the L<Mail::DKIM2::MessageInstance> class
methods.

=head2 check_ignore_prefixes($value)

Croaks unless C<$value> is undef or an array reference; returns it. Every
entry point that takes C<IgnorePrefixes> calls this.

=head2 dkim2_canonicalize_header($line)

Header-hash canonicalization (section 5.2) of one complete header line
including its CRLF: unfold, lowercase the name, collapse whitespace runs to
one space, trim whitespace around the colon and at the end. Returns
C<name:value\r\n>.

=head2 dkim2_canonicalize_sig_header($line)

Signing-input canonicalization (section 8.5): as above, but all whitespace
in the value is removed rather than collapsed.

=head2 extract_mi_version($header_value)

The C<m=> number of a Message-Instance value, as a number (so C<01> is
1), or undef when there is no C<m=> or it is not all ASCII digits.
Accepts a string, a scalar ref, or an arrayref (first element).

=head2 mi_version_tag($header_value)

The raw C<m=> value of a Message-Instance value with whitespace removed,
or undef when there is none. Pass it to
L</chain_number_error($field, $tag, $n)> before trusting it.

=head2 strip_mi_versions($message, @m)

Removes the Message-Instance fields with the given C<m=> numbers from a
CRLF message string and returns the result.

=head1 SIGNING INPUT

=head2 build_signing_input(%args)

The bytes a DKIM2-Signature signs (section 8.5): the canonicalized
Message-Instance headers in ascending C<m=> order, the DKIM2-Signature
headers below the one being signed in ascending C<i=> order, and that one
with empty C<s=> values. Arguments: C<mi_headers>, an arrayref of C<< { v
=> N, raw => $line } >> sorted by C<v>; C<dk2_headers>, an arrayref of C<<
{ i => N, raw => $line, sig => $signature } >> sorted by C<i>;
C<signing_i>, the C<i=> being signed or verified; C<signature>, its
L<Mail::DKIM2::Signature>; and optionally C<signing_header>, the exact
folded text to use for it, which the Signer passes so that the folds it
chose are signed.

=head2 chain_length_error($msg_or_counts)

The PERMERROR string for a message over L</MAX_CHAIN_LENGTH>, or undef.
Takes an L<Email::MIME> or a hashref of field counts keyed by lowercased
name.

=head2 valid_sequence($i)

True when C<$i> (a DKIM2-Signature C<i=> value) is a positive integer
written in ASCII digits. A signature whose C<i=> is not is one no verifier
can place in the chain or key: L<Mail::DKIM2::Verifier> reports it as
L</UNKEYABLE_SIGNATURE_ERROR>.

=head2 UNKEYABLE_SIGNATURE_ERROR

The PERMERROR string for a DKIM2-Signature with no C<i=> tag, or one that
does not parse: C<"PERMERROR: DKIM2-Signature i= tag=i missing">.

=head2 MI_MISSING_M_ERROR

The PERMERROR string for a Message-Instance with no C<m=> tag:
C<"PERMERROR: Message-Instance m= tag=m missing">. New in 0.25.

=head2 unkeyable_signature_error($value)

The PERMERROR string for a DKIM2-Signature header value whose C<i=> is
missing (L</UNKEYABLE_SIGNATURE_ERROR>) or not a positive integer
(C<"PERMERROR: DKIM2-Signature i=E<lt>as writtenE<gt> syntax error">). New
in 0.23.

=head2 chain_number_error($field, $tag, $n, $ident)

The PERMERROR string for an C<i=> or C<m=> value that is not a chain
number, or undef (also for an undefined C<$n>, which is left to the
caller). The field is named by its own number as written, C<$ident>
(default C<$n>): a DKIM2-Signature by C<i=>, a Message-Instance by C<m=>.
A value that is not 1*DIGIT in ASCII, or is zero, is
C<"PERMERROR: $field i=$ident syntax error"> (C<m=> for a
Message-Instance; -08 section 14.2). More than three digits or above
L</MAX_CHAIN_NUMBER> is C<"PERMERROR: DKIM2-Signature i=$ident exceeds the
maximum chain number of 100">, with C<" m=$n"> after C<$ident> for a
signature's C<m=>. Above L</MAX_CHAIN_LENGTH>, likewise C<"... exceeds the
maximum chain length of 32">: every C<i=> and C<m=> names one hop, so none
can be larger than the chain. C<01> and C<001> are 1.

=head2 duplicate_number_error($field, $tag, @numbers)

The PERMERROR string for the first number that appears twice, or undef.

=head1 ADDRESSES

=head2 split_any_all($value)

The groups of an C<h=> or C<s=> value (-08 sections 9.3 and 10.9): an
arrayref of C<|>-separated groups, each an arrayref of its C<,>-separated
members, untrimmed. Undef if any member is empty (a leading, trailing or
doubled C<|> or C<,>), which is a syntax error.

=head2 combine_sets(\@groups, $none_passed)

The overall C<($state, $text)> of an C<h=> or C<s=> value from its
members' results (-08 sections 14.6 and 14.7). C<@groups> holds one
arrayref per C<|> group, of C<[$state, $text]> per member, C<$state> being
C<pass>, C<fail>, C<temperror> or C<permerror>. A group passes if every
member does; is a temperror if every member that does not pass is one; else
fails if any member fails; else is a permerror. The value passes if any
group does; else is a temperror, fail or permerror if any group is, in that
order. C<$text> is the first member's (in value order) with the overall
state, or C<$none_passed> when several groups give a fail. A pass has no
text.

=head2 extract_domain($address)

The domain of C<user@domain> or C<< <user@domain> >>, or undef.

=head2 to_rfc5321_path($address)

Wraps an address in angle brackets if it has none; undef or empty becomes
C<< <> >>. The form C<mf=> and C<rt=> carry.

=head2 domain_of($address)

The domain of an address or RFC 5321 path, as C<($domain, $is_literal)>:
the text between the last C<@> and the closing C<< > >>, lowercased, with
one trailing dot removed (C<< <A@Example.COM.> >> gives C<example.com>).
C<$is_literal> is true for a domain literal such as C<[192.0.2.1]>. The
empty list when there is no domain, as for C<< <> >>. New in 0.23.

=head2 to_alabel($domain)

The domain with each non-ASCII label lowercased and written as its A-label
(C<xn--> and the RFC 3492 Punycode), as -08 section 18 has mf=, rt= and
From domains compared: C<b\x{fc}cher.example>, as UTF-8 octets, gives
C<xn--bcher-kva.example>. ASCII labels are unchanged; a label that is not
valid UTF-8 is left as it is. No UTS 46 mapping. New in 0.23.

=head2 from_domain(@values)

The domain a From header field is Authentic for (-08 section 11), given the
values of every From field in one version of the header: the lowercased
A-label domain of its one mailbox, or undef when there is no From field,
more than one, a field holding other than exactly one mailbox (a list, a
group), or a domain literal. Display names (quoted or RFC 2047) and
comments are skipped; C<< Name <addr> >> and a bare C<addr> both work. New in
0.23.

=head2 from_authentic($d, @values)

True if C<from_domain(@values)> gives a domain and it relaxed-matches the
signing domain C<$d>. New in 0.23.

=head2 from_refusal_note($d, @values)

For the log of a signer that refused a From not Authentic for C<$d>: a line
naming the From domain (as L</from_domain> finds it, or what is wrong with
the field) and C<$d>, and saying that a DKIM2 list's posting address must be
in the domain the milter signs with. Both milters log it. New in 0.23.

=head2 relaxed_domain_match($p1, $p2)

The relaxed domain match of -08 section 7.2: true if C<$p1> is C<$p2> or a
subdomain of it. Labels come off the left of C<$p1> only. Both are compared
as A-labels (C<to_alabel>), without regard to case and without a trailing
dot. A domain literal on either side never matches (new in 0.23).

=head1 FOLDING

Only for a header this code is creating. A header read from anywhere else
is never refolded: a fold where there was no whitespace changes its
canonical form and breaks every signature over it.

=head2 parse_mime($raw)

Parse C<$raw> into an L<Email::MIME> for the library's own use (raw header
fields, raw body), with L<Email::MIME::ContentType>'s parameter check relaxed
for the duration of the parse. DKIM2 never reads a MIME parameter, so a
sender's broken C<Content-Type> must not stop a message from being verified or
make every verification warn. The package variable is restored afterwards.

=head2 fold_header($line, [$margin], %opts)

Folds a complete header line at C<$margin> characters (default 72) with
CRLF-tab continuations, breaking at C<; > first, then at a space, then
where a DKIM2 field's grammar allows folding whitespace: inside a base64
value (C<mf=>, C<rt=>, C<r=>, an C<h=> digest, an C<s=> signature value),
beside the C<:>s of an C<s=> or C<h=> item, or after a list comma other
than in C<s=>. It never splits a domain, selector,
algorithm or hash name: such a token that will not fit stays whole on a
longer line, and a line that would exceed RFC 5322's 998 characters croaks.
With C<< delimiters_only => 1 >> it breaks
only after C<;> or C<,>, never inside a token, leaving a value that fits
nowhere whole on an over-long line (the rule for X-DKIM2-Info).

=head2 fold_value($string, [$margin])

Folds a string at arbitrary positions, C<$margin> content characters per
line (default 64).

=head1 KEYS

=head2 load_private_key($pem_file)

A L<Crypt::PK::RSA> or L<Crypt::PK::Ed25519> from a PEM file, whichever
it holds. Dies if the file is neither.

=head2 load_private_key_data($data)

The same from key material in memory: PEM, or bare base64 DER as some key
stores keep it. Returns undef rather than dying, so a signer of live mail
can log and carry on.

=head2 parse_dkim_key_record($txt_record)

Validates a whole key record (draft-ietf-dkim-dkim2-dns sections 3.2 and
3.4.1) and returns the public key object: a C<Crypt::PK::RSA> for C<k=rsa>
(the default) or a C<Crypt::PK::Ed25519> for C<k=ed25519>, the raw 32
octets of RFC 8463 (-08 section 14.5). Otherwise returns C<(undef, $why)>,
where C<$why> completes "public key E<lt>selectorE<gt> ...":

=over

=item C<has a syntax error>

Not a tag-list; a tag given twice; C<v=> present but not the first tag or
not exactly C<DKIM1>; no C<p=>; C<p=> not base64.

=item C<is malformed>

C<p=> is base64 but not a usable key of its type (-08 section 14.5): an
Ed25519 key that is not exactly 32 octets (DER included), an RSA key of
fewer than 1024 bits (section 3.2), or one that does not load.

=item C<has been revoked>

An empty C<p=>.

=item C<has an unsupported key type>

A C<k=> other than C<rsa> or C<ed25519>.

=back

Unknown tags and the retired C<h=>, C<n=>, C<s=> and C<t=> are ignored.
Tag names are case sensitive, as in DKIM1.

=head2 parse_dkim_pubkey($txt_record)

The key object from C<parse_dkim_key_record>, or undef for a record that
gives no usable key.

=head1 TAG ENCODING

=head2 encode_tag_json($data), decode_tag_json($base64)

Canonical JSON in base64, the encoding of the C<r=> Recipe tag. C<decode_tag_json> dies on invalid JSON, including JSON text that is not
UTF-8 and an object that gives the same key twice, compared without regard
to case (parsers disagree on which value wins). Every string it returns,
object keys included, is UTF-8 octets.

=head2 digest64($digest_object)

The base64 of a CryptX digest object's result.

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
