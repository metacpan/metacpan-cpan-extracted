package Mail::DKIM2::Common;
use 5.20.0;
use strict;
use warnings;

our $VERSION = '0.13';

use Carp ();
use MIME::Base64 qw(encode_base64 decode_base64);
use JSON;
use Crypt::PK::RSA;
use Crypt::PK::Ed25519;
use Crypt::Digest::SHA256 qw(sha256 sha256_b64 sha256_hex);

use Email::MIME;
use Email::MIME::ContentType ();

use Exporter 'import';
our @EXPORT_OK = qw(
    should_skip
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
    strip_mi_versions
    extract_domain
    to_rfc5321_path
    relaxed_domain_match
    parse_dkim_pubkey
    load_private_key
    load_private_key_data
    DKIM2_DRAFT
    DKIM2_REPO
    DKIM2_DATE
    MAX_CHAIN_LENGTH
    chain_length_error
    duplicate_number_error
);

# Provenance emitted in X-DKIM2-Info headers by the milter, the reflector, and
# the mailman/sympa handlers. This is the single source of truth for the Perl
# implementation. DKIM2_DRAFT is the spec revision implemented; DKIM2_DATE is
# the date this implementation's DKIM2 behaviour last changed (a software
# version stamp, not the draft's date) -- bump it on any change to what we
# emit, not only on a spec bump. See ../spec/draft-gondwana-dkim2-debug-header.
use constant DKIM2_DRAFT => 'ietf-dkim-dkim2-spec-06';
use constant DKIM2_REPO  => 'github.com/dkim2wg/interop';
use constant DKIM2_DATE  => '2026-10-04';

# Local policy, not spec-06: a message carrying more Message-Instance or
# DKIM2-Signature fields than this is a PERMERROR, found before any key is
# fetched, signature checked or recipe applied. Every hop costs a verifier a
# DNS lookup, a signature check and an undo of the whole message, and the
# sender chooses how many hops there are.
use constant MAX_CHAIN_LENGTH => 32;

# Headers excluded from hashing per draft-ietf-dkim-dkim2-spec-06 Section 4.
# spec-05 narrowed the old /^arc-/ prefix to the three RFC 8617 field names and
# added a /^received-/ prefix rule so future trace fields of that form need no
# change here.
my %SKIP_EXACT = map { $_ => 1 } qw(
    apparently-to arc-authentication-results arc-message-signature arc-seal
    authentication-results auto-submitted delivered-to dkim-signature
    dkim2-signature dl-expansion-history message-instance original-recipient
    received return-path sio-label-history vbr-info x400-received x400-trace
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
        return "PERMERROR more than " . MAX_CHAIN_LENGTH . " $field fields"
            if $count > MAX_CHAIN_LENGTH;
    }
    return;
}

# The PERMERROR for the first number that appears twice among a field's
# m= or i= values, or undef. Each number names one hop, so a second field
# with the same number is never a valid chain, and taking either one would
# let the other go unchecked.
sub duplicate_number_error {
    my ($field, $tag, @numbers) = @_;
    my %seen;
    for my $n (grep { defined } @numbers) {
        return "PERMERROR $field $tag=$n appears more than once"
            if $seen{$n + 0}++;
    }
    return;
}

# DKIM2 header canonicalization for HEADER HASH per spec-06 Section 5.2:
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

# DKIM2 header canonicalization for SIGNATURE INPUT per spec-06 Section 8.5:
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

# Decode a base64 JSON tag value
sub decode_tag_json {
    my ($b64) = @_;
    return JSON->new->decode(decode_base64($b64));
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
        # Base64 tag values contain no commas, so signed headers still fall
        # through to the hard break below, which their parsers tolerate.
        if ($break < 0) {
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

        # Last resort: hard break at limit
        $break = $limit if $break < 0;

        my $chunk = substr($remaining, 0, $break);
        $remaining = substr($remaining, $break);

        # Strip trailing WSP from chunk, leading WSP from remainder
        $chunk =~ s/\s+$//;
        $remaining =~ s/^\s+//;

        push @folded, $chunk;
        $limit = $cont_margin;
    }
    push @folded, $remaining if length($remaining);

    return join("\r\n\t", @folded);
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

# Extract the revision number from a Message-Instance header value (m= tag)
sub extract_mi_version {
    my ($header) = @_;
    $header = $header->[0] if ref($header) eq 'ARRAY';
    $header = $$header if ref($header);
    return unless $header =~ m/^\s*m=(\d+)/;
    return $1;
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
# §7.5/§7.6): angle brackets MUST be present. Empty/undef -> "<>"; an
# already-bracketed value (incl. "<>") is returned unchanged.
sub to_rfc5321_path {
    my ($addr) = @_;
    return '<>' unless defined $addr && length $addr;
    return $addr if $addr =~ /^<.*>$/s;
    return "<$addr>";
}

# Check if mf_domain is a subdomain of (or equal to) check_domain
sub relaxed_domain_match {
    my ($mf_domain, $check_domain) = @_;
    return 0 unless $mf_domain && $check_domain;
    $mf_domain = lc($mf_domain);
    $check_domain = lc($check_domain);
    while ($mf_domain) {
        return 1 if $mf_domain eq $check_domain;
        $mf_domain =~ s/^[^.]+\.// or return 0;
    }
    return 0;
}

# Build the signing input for DKIM2 signature signing/verification.
# Args (hash):
#   mi_headers  => arrayref of { v => N, raw => "..." } sorted by v ascending
#   dk2_headers => arrayref of { i => N, raw => "...", sig => $sig_obj } sorted by i ascending
#   signing_i   => the i= value being signed/verified (gets empty s= value)
#   signature   => the Signature object for the entry being signed/verified
#   signing_header => optional folded header string (signer path)
#
# Per draft-ietf-dkim-dkim2-spec-06 Section 8.5:
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

# Every eval a Signer or Verifier can reach rethrows a reference: the library
# only ever dies with strings, so an object is the host's, typically a milter
# or MTA signalling a timeout, and swallowing it would let the caller run on
# past its deadline. Reflector, Split and Validate are outside the rule --
# they run the demo server and the web validator, never inside a host.

# Parse a DKIM TXT record and return the appropriate key object.
# For RSA keys: returns a Crypt::PK::RSA object.
# For ed25519 keys: returns a Crypt::PK::Ed25519 object.
# Returns undef if the key record can't be parsed.
sub parse_dkim_pubkey {
    my ($key_txt) = @_;
    return unless $key_txt;
    my ($k) = $key_txt =~ /\bk=([^;\s]+)/;
    $k //= 'rsa';  # default per RFC 6376
    # h= (hash algorithm list) MUST be ignored per spec-06 Section 10.3
    my ($p) = $key_txt =~ /\bp=([A-Za-z0-9+\/=]+)/;
    return unless $p;
    if ($k eq 'ed25519') {
        # RFC 8463 publishes the raw 32-byte key in p=, but some signers
        # publish a DER SubjectPublicKeyInfo (as RSA does). Accept either, and
        # never die on a malformed/oversized key: return undef so the verifier
        # reports a clean fail/temperror instead of aborting the whole operation
        # (the RSA branch below is likewise eval-wrapped).
        my $raw = decode_base64($p);
        my $key = eval {
            my $pk = Crypt::PK::Ed25519->new();
            if (length($raw) == 32) {
                $pk->import_key_raw($raw, 'public');
            } else {
                $pk->import_key(\$raw);   # DER SubjectPublicKeyInfo
            }
            $pk;
        };
        die $@ if ref $@;
        return $key;
    }
    # RSA: p= is base64-encoded SubjectPublicKeyInfo DER
    my $der = decode_base64($p);
    my $rsa = eval { Crypt::PK::RSA->new(\$der) };
    die $@ if ref $@;
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

This module implements draft-ietf-dkim-dkim2-spec-06; see L<Mail::DKIM2/STATUS>
for what that means for the wire format and the API, and
L<Mail::DKIM2/CONVENTIONS> for the option, input and error conventions every
module here follows.

=head1 CONSTANTS

=head2 DKIM2_DRAFT, DKIM2_REPO, DKIM2_DATE

The spec revision implemented (C<ietf-dkim-dkim2-spec-06>), where the
code lives, and the date this implementation's DKIM2 behaviour last
changed. Emitted in X-DKIM2-Info debug headers
(draft-gondwana-dkim2-debug-header).

=head2 MAX_CHAIN_LENGTH

32: a message carrying more Message-Instance or DKIM2-Signature fields
than this is a PERMERROR, found before any key is fetched. Local policy,
not spec.

=head1 CANONICALIZATION

=head2 should_skip($header_name, [\@prefixes])

True if the field is excluded from the header hash: the spec-06 section 4
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

The C<m=> number of a Message-Instance value, or undef. Accepts a string,
a scalar ref, or an arrayref (first element).

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

=head2 duplicate_number_error($field, $tag, @numbers)

The PERMERROR string for the first number that appears twice, or undef.

=head1 ADDRESSES

=head2 extract_domain($address)

The domain of C<user@domain> or C<< <user@domain> >>, or undef.

=head2 to_rfc5321_path($address)

Wraps an address in angle brackets if it has none; undef or empty becomes
C<< <> >>. The form C<mf=> and C<rt=> carry.

=head2 relaxed_domain_match($domain, $parent)

True if C<$domain> is C<$parent> or a subdomain of it, case-insensitively.

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
after a C<,>, then anywhere. With C<< delimiters_only => 1 >> it breaks
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

=head2 parse_dkim_pubkey($txt_record)

The public key object from a DKIM TXT record (C<k=> and C<p=>; C<h=> is
ignored per section 10.3). Ed25519 keys are accepted as the raw 32 bytes
of RFC 8463 or as DER. Returns undef for a record it cannot parse.

=head1 TAG ENCODING

=head2 encode_tag_json($data), decode_tag_json($base64)

Canonical JSON in base64, the encoding of the C<r=> Recipe tag.

=head2 digest64($digest_object)

The base64 of a CryptX digest object's result.

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
