package Mail::DKIM2::MessageInstance;
use strict;
use warnings;

our $VERSION = '0.25';


use Mail::DKIM2::Digest;
use Email::MIME;
use MIME::Base64 qw(encode_base64 decode_base64);
use List::Util qw(max);
use B ();
use Carp;

use Mail::DKIM2::TagValueList ();
use Mail::DKIM2::Common qw(
    MI_MISSING_M_ERROR
    parse_mime
    should_skip
    dkim2_canonicalize_header
    digest64
    encode_tag_json
    decode_tag_json
    extract_mi_version
    check_ignore_prefixes
    MAX_CHAIN_LENGTH
    chain_length_error
    chain_number_error
    mi_version_tag
    duplicate_number_error
);

our $DEBUG = 0;

# The PERMERROR for a message whose Message-Instance fields cannot form a
# chain, or undef.
sub _chain_error {
    my ($msg) = @_;
    return _chain_error_fields([ $msg->header_raw('Message-Instance') ],
                               scalar(my @sigs = $msg->header_raw('DKIM2-Signature')));
}

# The same from the Message-Instance field values and the number of
# DKIM2-Signature fields, for a caller that has no Email::MIME.
sub _chain_error_fields {
    my ($fields, $signatures) = @_;
    my @mi = @$fields;
    # The first field with no usable m= (none, or not a chain number), in
    # field order -- interop contract C9's step b.
    my ($unusable) = grep { defined }
                     map { my $raw = mi_version_tag($_);
                           defined $raw ? chain_number_error('Message-Instance', 'm', $raw)
                                        : MI_MISSING_M_ERROR } @mi;
    return chain_length_error({ 'message-instance' => scalar @mi,
                                'dkim2-signature'  => $signatures })
        // $unusable
        // duplicate_number_error('Message-Instance', 'm', map { extract_mi_version($_) } @mi);
}

# -07 §3.1: two hashing algorithms are defined. Verifiers MUST implement
# both; Signers MAY implement either or both (we default to sha256). Each
# is a function of the data to its raw digest, by Mail::DKIM2::Digest.
my %HASH_ALGS = map {
    my $alg = $_;
    $alg => sub { Mail::DKIM2::Digest::digest_data($alg, $_[0]) };
} qw(sha256 sha512);

sub hash_algs { return { %HASH_ALGS } }

# -07 §9.3: h= is hash-set *("," hash-set), hash-set = alg ":" hh ":" bh.
# Hash names are lowercased -- RFC 5234 makes ABNF quoted strings
# case-insensitive. All FWS is stripped (§2.12): it may appear anywhere
# inside a base64 value (e.g. a folded header), not just at either end.
# h= (-07 §9.3): hash-set *("," hash-set), each
# [FWS] hash-name [FWS] ":" header-hash ":" body-hash. FWS is trimmed from
# around the name and removed from inside the base64 hashes; anywhere else
# (inside the name, or a set missing a part) the value is malformed and this
# returns undef rather than skipping the set or joining the name up.
sub parse_hash_sets {
    my ($h_tag) = @_;
    my @sets;
    for my $item (split /,/, $h_tag, -1) {
        my ($name, $rest) = $item =~ /\A[ \t\r\n]*([A-Za-z0-9_-]+)[ \t\r\n]*:(.*)\z/s
            or return;
        $rest =~ s/[ \t\r\n]//g;
        my @hashes = split /:/, $rest, -1;
        return unless @hashes == 2 && length $hashes[0] && length $hashes[1];
        push @sets, [lc $name, @hashes];
    }
    return \@sets;
}

# FILTHY PATCHING (needed for undo to work with Email::Simple)
BEGIN {
    # function to replace headers from the bottom up
    if (!Email::Simple::Header->can('header_set_reverse')) {
        *Email::Simple::Header::header_set_reverse = sub {
            my $self = shift;
            my $h = shift;
            my @vals = @_;
            my $headers = $self->{headers};
            my $max = @$headers / 2 - 1;
            for my $idx (map { $_ * 2 } reverse 0..$max) {
                next unless lc($headers->[$idx]) eq lc($h);
                if (@vals) {
                    $headers->[$idx+1] = shift @vals;
                } else {
                    splice(@$headers, $idx, 2);
                }
            }
            unshift @$headers, ($h, $_) for @vals;
        };
    }

    # function to only keep headers that match an expression
    if (!Email::Simple::Header->can('header_filter')) {
        *Email::Simple::Header::header_filter = sub {
            my $self = shift;
            my $h = shift;
            my $keep = shift;
            my $headers = $self->{headers};
            my $max = @$headers / 2 - 1;
            for my $idx (map { $_ * 2 } reverse 0..$max) {
                next unless lc($headers->[$idx]) eq lc($h);
                next if $keep->($headers->[$idx+1]);
                splice(@$headers, $idx, 2);
            }
        };
    }
}

# --- Tag accessors ---

sub set_tag {
    my ($self, $k, $v) = @_;
    $self->{bits}{$k} = $v;
}

sub get_tag {
    my ($self, $k) = @_;
    return $self->{bits}{$k};
}

# The header-hash component (base64) of this Message-Instance's h= tag.
sub header_hash { return $_[0]->{bits}{h1} }
sub body_hash { return $_[0]->{bits}{b1} }

# The body hash (-07 section 6.1) of a raw body string with LF or CRLF
# line ends: no Email::MIME parse, for callers that hold the body alone.
# Streams the body through the digest a megabyte at a time (each piece
# ending at a LF, so a CRLF is never split): a large body is never copied
# whole.
use constant BODY_CHUNK => 1 << 20;

sub body_digest_raw {
    # Through a reference: "my ($body) = @_" would copy the body.
    my $bref = defined $_[0] ? \$_[0] : \'';
    my $alg = lc($_[1] // 'sha256');
    my $d = Mail::DKIM2::Digest->new($alg);    # croaks on an unknown $alg
    my $len = length $$bref;

    # $end: the body without its trailing line breaks, each a LF with an
    # optional CR before it, taken from the end.
    my $end = $len;
    while ($end > 0 && substr($$bref, $end - 1, 1) eq "\n") {
        $end--;
        $end-- if $end > 0 && substr($$bref, $end - 1, 1) eq "\r";
    }

    for (my $pos = 0; $pos < $end; ) {
        my $n = $end - $pos;
        if ($n > BODY_CHUNK) {
            my $nl = index($$bref, "\n", $pos + BODY_CHUNK);
            $n = $nl + 1 - $pos if $nl >= 0 && $nl < $end;
        }
        # s/\r?\n/\r\n/g, as two literal substitutions: several times
        # faster, the same result ("\r\r\n" stays "\r\r\n").
        my $piece = substr($$bref, $pos, $n);
        $piece =~ s/\r\n/\n/g if index($piece, "\r") >= 0;
        $piece =~ s/\n/\r\n/g;
        $d->add($piece);
        $pos += $n;
    }
    $d->add("\r\n");
    return encode_base64($d->digest, '');
}

# Mark the body Recipe as null per -07 §5.2: the body changed but the
# previous state cannot be recreated. as_string() then emits "b": null.
sub set_null_body_recipe {
    my ($self) = @_;
    $self->{bits}{rb} = \'null';   # scalar-ref sentinel
}

# True if this instance declares the previous state non-recreatable (a null
# "b" Recipe). Such an instance cannot be undone to a prior version. Under
# -07 §5.1 a header Recipe can no longer be null, so only the body
# Recipe can render an instance unrecoverable.
sub unrecoverable {
    my ($self) = @_;
    return $self->{bits}{rb_null} ? 1 : 0;
}

# --- Wire format: m=N; h=sha256:header_hash:body_hash; r=<b64json> ---

sub as_string {
    my ($self) = @_;
    my %data = %{$self->{bits}};
    my $m = delete $data{m};
    my $h1 = delete $data{h1};
    my $b1 = delete $data{b1};
    my $hashes = delete $data{hashes};
    unless ($hashes && %$hashes) {
        # Back-compat: bits built directly with bare h1/b1 and no hashes map
        # (e.g. hand-constructed objects in tests) still emit a sha256 set.
        $hashes = (defined $h1 || defined $b1) ? { sha256 => [ $h1 // '', $b1 // '' ] } : {};
    }

    # -07 §9.3: h= is hash-set *("," hash-set) -- one hash-set per
    # configured algorithm, emitted in the signer's chosen order (default:
    # sha256 only; the signer default MUST NOT change).
    my @algs = @{ $self->{algs} || ['sha256'] };
    my @sets;
    for my $alg (@algs) {
        my $pair = $hashes->{$alg} or next;
        push @sets, "$alg:$pair->[0]:$pair->[1]";
    }
    my $result = "m=$m; h=" . join(',', @sets);

    # Build r= tag JSON if there are Recipes
    my %recipe_json;
    if (exists $data{rb}) {
        if (ref $data{rb} eq 'SCALAR' && ${$data{rb}} eq 'null') {
            $recipe_json{b} = undef;          # encodes as JSON null
            delete $data{rb};
        } else {
            $recipe_json{b} = _encode_recipe_list(delete $data{rb});
        }
    }
    if (exists $data{rh}) {
        my $rh = delete $data{rh};
        my %encoded;
        # -07 §5.1: header field names in the JSON Recipes MUST be lower
        # case (matching against the message stays case-insensitive).
        for my $h (sort keys %$rh) {
            $encoded{lc $h} = _encode_recipe_list($rh->{$h});
        }
        $recipe_json{h} = \%encoded;
    }

    if (keys %recipe_json) {
        $result .= "; r=" . encode_tag_json(\%recipe_json);
    }
    $result .= ";";

    return $result;
}

# Convert internal Recipe list to wire format
# Internal: [from,to] arrays for copy ranges, strings for literal content
# Wire (draft -07 section 5): {"c": [from,to]} for a copy, {"d": [...]} for
# literals that are UTF-8, {"u": ["base64",...]} for literals that are not.
#
# A literal is the raw octets of a header value or body line. One that is
# valid UTF-8 (ASCII included) goes in a "d" step as JSON text. Anything
# else (ISO-2022-JP, GB18030, Big5, Latin-1 ...) goes in a "u" step,
# canonical base64 (RFC 4648 section 4) of the octets: JSON text is UTF-8, so
# the only way to carry such a literal in JSON unchanged is to encode it, and
# "u" SHOULD NOT be used where "d" would do (section 5).
# Consecutive literals of the same kind share one step.
sub _encode_recipe_list {
    my ($list) = @_;
    my @encoded;
    my $pending_kind = '';
    my @pending;
    my $flush = sub {
        return unless @pending;
        push @encoded, { $pending_kind => [@pending] };
        @pending = ();
    };
    for my $item (@$list) {
        if (ref $item eq 'ARRAY') {
            $flush->();
            # Force numeric: an index that was used as a hash key upstream
            # (de-duplicating copies) is stringified in place, and the JSON
            # encoder would then emit {"c":["2","2"]} -- strings, which the
            # section 5 schema forbids and Go rejects as invalid JSON.
            push @encoded, { c => [ map { 0 + $_ } @$item ] };
        } else {
            my $kind = Mail::DKIM2::Common::_is_utf8_octets($item) ? 'd' : 'u';
            $flush->() if $kind ne $pending_kind;
            $pending_kind = $kind;
            push @pending, $kind eq 'u' ? encode_base64($item, '') : $item;
        }
    }
    $flush->();
    return \@encoded;
}

# --- Parsing ---

sub parse {
    my ($class, $header) = @_;
    my $self = bless {}, ref($class) || $class;

    # Strip leading whitespace
    $header =~ s/^\s+//;

    # Parse tag-value format: m=N; h=...; r=... Tag identifiers are case
    # insignificant and there MUST be only one of each kind (-07 §9), so
    # names are lowercased, and a repeat in any case is a syntax error --
    # never a silent overwrite, which let a wrong h= ahead of the right one
    # pass (review R5).
    # The list must parse as a whole (TagValueList's grammar): a fragment
    # that is not a tag is a syntax error, not something to skip
    # (follow-up review F3).
    my ($pairs, $ok) = Mail::DKIM2::TagValueList::split_tag_list($header);
    my (%tags, $dup, $raw_h);
    for my $p (@$pairs) {
        my ($name, $val) = (lc $p->[0], $p->[1]);
        $raw_h = $val if $name eq 'h';
        $val =~ s/\s//gs;
        $dup = 1 if exists $tags{$name};
        $tags{$name} = $val;
    }

    die "missing m= tag in Message-Instance header"
        unless exists $tags{m};
    die "PERMERROR: Message-Instance m=$tags{m} syntax error\n" if $dup || !$ok;
    # -07 section 9: h= is required.
    die "PERMERROR: Message-Instance m=$tags{m} tag=h missing\n" unless exists $tags{h};
    $self->{bits}{m} = $tags{m};

    # -07 section 9.3: h= is a list of hash-sets
    if (exists $tags{h}) {
        my $sets = parse_hash_sets($raw_h)
            or die "PERMERROR: Message-Instance m=$tags{m} syntax error\n";

        # §9.3: an algorithm MUST NOT be present more than once. Check the
        # LIST returned by parse_hash_sets, not a hash keyed by algorithm --
        # a hash would let the second occurrence silently overwrite the
        # first, hiding the duplicate. Hash names are already lowercased by
        # parse_hash_sets (RFC 5234 makes ABNF quoted strings
        # case-insensitive), so this comparison is case-insensitive too.
        # This must run before any hash is computed or compared.
        my %seen;
        for my $s (@$sets) {
            if ($seen{$s->[0]}++) {
                die "PERMERROR: Message-Instance m=$tags{m} has a duplicate hash algorithm\n";
            }
        }

        for my $s (@$sets) {
            $self->{bits}{hashes}{$s->[0]} = [$s->[1], $s->[2]];
        }
        # The order h= lists them in: the order they are checked in.
        $self->{hash_order} = [ map { $_->[0] } @$sets ];
        # Back-compatible aliases for the sha256 hash-set
        if (my $sha256 = $self->{bits}{hashes}{sha256}) {
            @{$self->{bits}}{qw(h1 b1)} = @$sha256;
        }
    }

    if (exists $tags{r}) {
        # -07 §14.2: a bad base64 r= value and a post-decode JSON parse
        # failure are different errors and must stay distinct: base64
        # failure -> "syntax error" (§14.2 lists this explicitly for
        # malformed field content); JSON failure -> "contains invalid JSON".
        # decode_base64() is lenient (silently drops non-alphabet
        # characters rather than failing), so a strict format check is
        # needed here to actually catch malformed base64 -- otherwise it
        # would just decode to garbage bytes that happen to also fail JSON
        # parsing, mislabelling the error.
        if ($tags{r} !~ m{\A(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?\z}) {
            die "PERMERROR: Message-Instance m=$tags{m} syntax error\n";
        }
        # Anything wrong with the JSON -- its syntax, or the -07 section 5
        # schema -- is the one error, "contains invalid JSON".
        my $invalid = "PERMERROR: Message-Instance m=$tags{m} contains invalid JSON\n";
        my $recipe_data = eval { decode_tag_json($tags{r}) };
        if ($@) {
            die $@ if ref $@;
            die $invalid;
        }
        die $invalid unless ref $recipe_data eq 'HASH';
        # Keys match without regard to case (decision 2 of the -07
        # contract: lowercase on the wire, any case accepted), and
        # decode_tag_json has already refused two that differ only in case.
        # Other top-level keys are ignored; at least one of h and b is
        # required.
        my %top = map { lc($_) => $recipe_data->{$_} } keys %$recipe_data;
        die $invalid unless exists $top{h} || exists $top{b};
        # A null "b" (section 5.2) means the previous body cannot be
        # recreated -- distinct from an absent one (no change).
        if (exists $top{b}) {
            if (ref $top{b} eq 'ARRAY') {
                $self->{bits}{rb} = _decode_recipe_list($top{b}, $invalid);
            } elsif (!defined $top{b}) {
                $self->{bits}{rb_null} = 1;
            } else {
                die $invalid;
            }
        }
        if (exists $top{h}) {
            # A non-empty object (minProperties 1); never null (section 5.1).
            die $invalid unless ref $top{h} eq 'HASH' && %{$top{h}};
            my %rh;
            for my $h (keys %{$top{h}}) {
                $rh{lc $h} = _decode_recipe_list($top{h}{$h}, $invalid);
            }
            $self->{bits}{rh} = \%rh;
        }
    }

    return $self;
}

# Convert wire format Recipe list to internal format
# Wire (-07 section 5): an array of steps, each an object with exactly one
# key, "c", "d" or "u" (in any case): {"c": [from,to]} copies, {"d": [...]}
# emits UTF-8 literals, {"u": [...]} emits base64 ones.
# Internal: [from,to] arrays for copy ranges, strings for literal content
#
# A "u" item is decoded here, so the rest of the module sees one kind of
# literal: a plain byte string. The schema's checks are all made here, and
# any failure dies with $invalid ("contains invalid JSON"): a copy range is
# exactly two JSON integers of at least 1; a "d" or "u" array has at least
# one string; a "u" string is canonical base64 -- the alphabet, padding to
# a multiple of four, and zero pad bits, the schema's three patterns -- with
# no FWS; and no literal, "d" text or decoded "u" octets, may contain CR or
# LF, since a literal is exactly one header value or one body line. "d"
# text is UTF-8 already: decode_tag_json refuses JSON that is not.
# The order and bounds of copy ranges are not the schema's: _check_recipe
# checks those, against the lines a Recipe applies to.
my $U_PATTERN = qr{\A(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/][AQgw]==|[A-Za-z0-9+/]{2}[AEIMQUYcgkosw048]=)?\z};
sub _decode_recipe_list {
    my ($list, $invalid) = @_;
    die $invalid unless ref $list eq 'ARRAY';
    my @decoded;
    for my $item (@$list) {
        die $invalid unless ref $item eq 'HASH' && keys %$item == 1;
        my ($key) = keys %$item;
        my $kind = lc $key;
        my $val  = $item->{$key};
        die $invalid unless ref $val eq 'ARRAY';
        if ($kind eq 'c') {
            die $invalid unless @$val == 2
                && !grep { !_is_json_integer($_) || $_ < 1 } @$val;
            push @decoded, $val;
        } elsif ($kind eq 'd') {
            die $invalid unless @$val;
            for my $text (@$val) {
                die $invalid unless _is_json_string($text) && $text !~ /[\r\n]/;
            }
            push @decoded, @$val;
        } elsif ($kind eq 'u') {
            die $invalid unless @$val;
            for my $b64 (@$val) {
                die $invalid unless _is_json_string($b64) && $b64 =~ $U_PATTERN;
                my $octets = decode_base64($b64);
                die $invalid if $octets =~ /[\r\n]/;
                push @decoded, $octets;
            }
        } else {
            die $invalid;
        }
    }
    return \@decoded;
}

# --- Digests ---

sub h_digest {
    my ($msg, $alg, $prefixes) = @_;
    $alg = lc($alg // 'sha256');

    my $data = '';
    for my $header (sort { lc($a) cmp lc($b) } $msg->header_names) {
        next if should_skip($header, $prefixes);
        for my $item (reverse $msg->header_raw($header)) {
            my $chead = dkim2_canonicalize_header("$header: $item\r\n");
            warn "cdigest: $chead" if $DEBUG;
            $data .= $chead;
        }
    }

    return _hash_data_b64($alg, $data);
}

sub b_digest {
    my ($msg, $alg) = @_;
    $alg = lc($alg // 'sha256');

    # DKIM simple body canonicalization: strip trailing empty lines,
    # ensure exactly one trailing CRLF
    my $body = $msg->body_raw;
    $body =~ s/(\r\n)+\z//;
    $body .= "\r\n";

    return _hash_data_b64($alg, $body);
}

# -07 §3.1/§3.5: hash $data with the named (implemented) algorithm and
# base64-encode the result. Equivalent to the historic digest64($digest)
# path for sha256 (verified byte-identical), generalised to any algorithm
# in %HASH_ALGS.
sub _hash_data_b64 {
    my ($alg, $data) = @_;
    my $fn = $HASH_ALGS{$alg} or croak "unsupported hash algorithm: $alg";
    return encode_base64($fn->($data), '');
}

# --- Body Recipe computation ---

# The capped Myers line diff, the same algorithm in every implementation in
# this repository so they emit identical Recipes (docs/superpowers/specs/
# 2026-10-09-capped-myers-body-diff-design.md).
#
# _body_diff(\@cur, \@prev, $max_literals) returns undef when the bodies are
# identical, 'too_big' when rebuilding @prev would take more than
# $max_literals literal lines or the search ran out of work budget, else the
# Recipe: [from,to] copy ranges (1-based, into @cur) and literal lines, in
# @prev order.
#
# The cap is on the Recipe's output, but it bounds the search exactly:
# literals = M - LCS and edits D = N + M - 2*LCS, so at most L literals
# means D <= N - M + 2L. MAX_DIFF_WORK bounds the rest -- CPU and trace
# memory when N is much larger than M and that edit bound is loose.
use constant MAX_RECIPE_LITERALS => 1000;
use constant MAX_DIFF_WORK       => 4_000_000;

sub _body_diff {
    my ($cur, $prev, $max) = @_;
    $max //= MAX_RECIPE_LITERALS;
    my ($C, $P) = (scalar @$cur, scalar @$prev);

    # 1. Trim the common prefix and suffix.
    my $pre = 0;
    $pre++ while $pre < $C && $pre < $P && $cur->[$pre] eq $prev->[$pre];
    return undef if $pre == $C && $pre == $P;
    my $suf = 0;
    $suf++ while $suf < $C - $pre && $suf < $P - $pre
        && $cur->[$C - 1 - $suf] eq $prev->[$P - 1 - $suf];

    # 2. Intern the middle lines and discard those that cannot be in the
    # LCS: a current line that never occurs in the previous middle is a pure
    # deletion, a previous line that never occurs in the current middle is
    # certainly a literal.
    my (%id, %cnt_a, %cnt_b);
    my @a_lines = @{$cur}[$pre .. $C - $suf - 1];
    my @b_lines = @{$prev}[$pre .. $P - $suf - 1];
    $cnt_b{$_}++ for @b_lines;
    $cnt_a{$_}++ for @a_lines;
    my (@A, @ai, @B, @bj);
    for my $i (0 .. $#a_lines) {
        my $l = $a_lines[$i];
        next unless $cnt_b{$l};
        push @A, $id{$l} //= scalar keys %id;
        push @ai, $i;
    }
    for my $j (0 .. $#b_lines) {
        my $l = $b_lines[$j];
        next unless $cnt_a{$l};
        push @B, $id{$l} //= scalar keys %id;
        push @bj, $j;
    }
    my ($N, $M) = (scalar @A, scalar @B);
    my $unique = @b_lines - $M;

    # A previous line occurring more often than in the current body needs
    # a literal for each extra copy: a lower bound on the literal count
    # that costs nothing to check before searching.
    my $floor = $unique;
    for my $l (keys %cnt_b) {
        my $extra = $cnt_b{$l} - ($cnt_a{$l} // 0);
        $floor += $extra if $extra > 0 && $cnt_a{$l};
    }
    return 'too_big' if $floor > $max;

    # 3. Myers' greedy O(ND) search over the reduced sequences, keeping each
    # round's V (packed, 32 bits a diagonal) for the backtrack. x indexes
    # @A (current), y indexes @B (previous); "down" takes a previous line as
    # a literal, "right" skips a current line, a diagonal step is a match.
    my @match;    # $match[$y] = $x for each matched @B line
    if ($N && $M) {
        my $dmax = $N - $M + 2 * ($max - $unique);
        $dmax = $N + $M if $dmax > $N + $M;
        return 'too_big' if $dmax < 0;
        my $off = $dmax + 1;
        my @v = (0) x (2 * $off + 1);
        my @trace;
        my $work = 0;
        my ($found, $x, $y);
        ROUND: for my $d (0 .. $dmax) {
            push @trace, pack('N*', @v[$off - $d - 1 .. $off + $d + 1]);
            for (my $k = -$d; $k <= $d; $k += 2) {
                $x = ($k == -$d
                      || ($k != $d && $v[$off + $k - 1] < $v[$off + $k + 1]))
                    ? $v[$off + $k + 1]
                    : $v[$off + $k - 1] + 1;
                $y = $x - $k;
                while ($x < $N && $y < $M && $A[$x] == $B[$y]) {
                    $x++; $y++; $work++;
                }
                $v[$off + $k] = $x;
                return 'too_big' if ++$work > MAX_DIFF_WORK;
                if ($x == $N && $y == $M) { $found = $d; last ROUND }
            }
        }
        return 'too_big' unless defined $found;

        # Backtrack: trace[d] holds V as it stood before round d, for
        # diagonals -d-1 .. d+1 (index k + d + 1).
        for (my $d = $found; $d > 0; $d--) {
            my $t = $trace[$d];
            my $k = $x - $y;
            my $down = $k == -$d
                || ($k != $d && vec($t, $k - 1 + $d + 1, 32) < vec($t, $k + 1 + $d + 1, 32));
            my $pk = $down ? $k + 1 : $k - 1;
            my $px = vec($t, $pk + $d + 1, 32);
            my $py = $px - $pk;
            my ($sx, $sy) = $down ? ($px, $py + 1) : ($px + 1, $py);
            while ($x > $sx) { $x--; $y--; $match[$y] = $x }
            ($x, $y) = ($px, $py);
        }
        while ($x > 0) { $x--; $y--; $match[$y] = $x }
    }

    # 4. Map back to whole-body indices and build the Recipe in @prev order,
    # merging copies that are adjacent in both bodies.
    my %src;
    for my $y (0 .. $#match) {
        next unless defined $match[$y];
        $src{$pre + $bj[$y]} = $pre + $ai[$match[$y]];
    }
    my @recipe;
    my $literals = 0;
    for my $j (0 .. $P - 1) {
        my $i = $j < $pre        ? $j
              : $j >= $P - $suf  ? $j - $P + $C
              :                    $src{$j};
        if (!defined $i) {
            push @recipe, $prev->[$j];
            $literals++;
        } elsif (@recipe && ref $recipe[-1] && $recipe[-1][1] == $i) {
            $recipe[-1][1] = $i + 1;
        } else {
            push @recipe, [$i + 1, $i + 1];
        }
    }
    return 'too_big' if $literals > $max;
    return \@recipe;
}

# --- Epilogue helpers ---

# Generate a random boundary string that is very unlikely to appear in message content.
sub _random_boundary {
    return sprintf('dkim2-epilogue-%08x%08x', int(rand(2**32)), int(rand(2**32)));
}

# Add $old_body into the MIME epilogue of $msg (an Email::MIME object),
# modifying it in place.  Returns the number of body lines that precede
# the epilogue, so the caller can build a line-range rb Recipe.
#
# If $msg is already multipart, the old body is appended after the final
# MIME boundary (--BOUNDARY--).  If it is not multipart, the current
# content is wrapped in a single-part multipart/mixed container and the
# old body goes after the new final boundary.  In the wrap case the
# caller's rh header-diff will automatically record the Content-Type change.
sub _add_epilogue {
    my ($msg, $old_body) = @_;

    my $ct = $msg->content_type // '';

    if ($ct =~ m{^multipart/}i) {
        # Already multipart: append old body after the final boundary line.
        my ($boundary) = ($ct =~ /boundary="?([^";]+)"?/i);
        croak "Cannot find MIME boundary in Content-Type: $ct" unless $boundary;

        my $body  = $msg->body_raw;
        my $final = "--$boundary--";

        # Find the first (and should be only) final-boundary occurrence.
        my $idx = index($body, "$final\r\n");
        if ($idx >= 0) {
            $body = substr($body, 0, $idx + length($final) + 2) . $old_body;
        } else {
            # Tolerate bare LF or missing trailing newline.
            $idx = index($body, "$final\n");
            if ($idx >= 0) {
                $body = substr($body, 0, $idx + length($final) + 1) . $old_body;
            } else {
                $idx = index($body, $final);
                $body = ($idx >= 0 ? substr($body, 0, $idx + length($final)) : $body)
                      . "\r\n" . $old_body;
            }
        }
        $msg->body_set($body);

    } else {
        # Not multipart: wrap current content in multipart/mixed; put old body in epilogue.
        my $boundary  = _random_boundary();
        my $orig_ct   = $msg->header('Content-Type') // 'text/plain';
        my $orig_cte  = $msg->header('Content-Transfer-Encoding');
        my $orig_body = $msg->body_raw;

        my $new_body  = "--$boundary\r\n";
        $new_body    .= "Content-Type: $orig_ct\r\n";
        $new_body    .= "Content-Transfer-Encoding: $orig_cte\r\n" if $orig_cte;
        $new_body    .= "\r\n";
        $new_body    .= $orig_body;
        $new_body    .= "\r\n--$boundary--\r\n";
        $new_body    .= $old_body;

        $msg->header_set('Content-Type', "multipart/mixed; boundary=\"$boundary\"");
        $msg->header_set('Content-Transfer-Encoding') if $orig_cte;
        $msg->body_set($new_body);
    }

    # Return number of lines before the epilogue so the caller can build
    # a line-range Recipe.  The old body occupies the last N lines of the
    # modified body, where N = lines in $old_body.
    my @all_lines = split /\r?\n/, $msg->body_raw;
    my @old_lines = split /\r?\n/, $old_body;
    return scalar(@all_lines) - scalar(@old_lines);  # 0-based count of prefix lines
}

# --- Calculate helpers ---

# The body Recipe rebuilding $prev_raw from $cur_raw (raw body strings):
# undef when they are the same body, "too_big" over $max literal lines.
# Lines split as the verifier rebuilds them, trailing line breaks dropped.
sub _body_recipe {
    my ($cur_raw, $prev_raw, $max) = @_;
    (my $s1 = $cur_raw)  =~ s/[\r\n]+$//;
    (my $s2 = $prev_raw) =~ s/[\r\n]+$//;
    return _body_diff([split /\r?\n/, $s1], [split /\r?\n/, $s2], $max);
}

# Store $old_body in the MIME epilogue of $current (modifying it in place),
# then return a rb line-range Recipe pointing at those lines.
sub _epilogue_recipe {
    my ($current, $old_body) = @_;
    my @old_lines  = split /\r?\n/, $old_body;
    return undef unless @old_lines;
    my $prefix_len = _add_epilogue($current, $old_body);
    return [[$prefix_len + 1, $prefix_len + @old_lines]];
}

# BodyRecipe 'none' with a caller-supplied BodyHash: croak unless the hash
# equals the body hash in the previous message's top Message-Instance, for
# every algorithm both carry (and at least one).
sub _check_body_unchanged {
    my ($previous, $body_hash, $algs) = @_;
    my %map = map { (extract_mi_version($_) // 0) => $_ }
        $previous->header_raw('Message-Instance');
    my $top = __PACKAGE__->parse($map{ max(keys %map) });
    my @common = grep { $top->{bits}{hashes}{$_} } @$algs;
    croak "BodyRecipe 'none' with BodyHash: the previous instance has no "
        . join('/', @$algs) . " body hash to compare" unless @common;
    for my $alg (@common) {
        croak "BodyRecipe 'none' with BodyHash: the body hash is not the "
            . "previous instance's, so the body changed"
            unless $body_hash->{$alg} eq $top->{bits}{hashes}{$alg}[1];
    }
}

# --- Calculate ---

# UseEpilogue and EpilogueThreshold are disabled (final review M5): the
# instance is computed over the message rewritten with the epilogue, but a
# caller holding the message as a string, as both milters do, signs and
# sends the original bytes, and that mail fails verification. Until that is
# fixed they croak. $ENABLE_BROKEN_EPILOGUE is for this distribution's own
# tests of the epilogue code, which hand in an Email::MIME and keep the
# rewritten object; it is not an interface.
our $ENABLE_BROKEN_EPILOGUE = 0;
use constant EPILOGUE_DISABLED =>
    "UseEpilogue and EpilogueThreshold are disabled in Mail::DKIM2 0.23: the "
  . "Message-Instance would be computed over the message rewritten with the "
  . "epilogue while the original bytes are signed, and the mail fails "
  . "verification. Leave them out (the default is a diff body Recipe, or a "
  . "null body Recipe over MaxRecipeLiterals)";

sub _check_epilogue {
    my (%opts) = @_;
    croak EPILOGUE_DISABLED
        if !$ENABLE_BROKEN_EPILOGUE && ($opts{UseEpilogue} || exists $opts{EpilogueThreshold});
    return;
}

sub calculate {
    my ($class, $current, $previous, %opts) = @_;
    Mail::DKIM2::Common::_check_options("$class->calculate", \%opts,
        qw(Algs BodyHash BodyRecipe EpilogueThreshold IgnorePrefixes
           MaxRecipeLiterals UseEpilogue));
    _check_epilogue(%opts);
    croak "need a message" unless $current;

    my $self = bless {}, $class;
    my $prefixes = check_ignore_prefixes($opts{IgnorePrefixes});

    # -07 §3.1: the signer chooses one or more hash algorithms; default
    # is sha256 only (the signer default MUST NOT change).
    $self->{algs} = ($opts{Algs} && @{$opts{Algs}}) ? [ @{$opts{Algs}} ] : ['sha256'];

    # BodyHash: the caller hashed the body (body_digest_raw), so $current
    # may be the header block alone.  Only where nothing here reads or
    # changes the body: m=1, or a caller-supplied BodyRecipe.
    croak "BodyRecipe needs a previous message"
        if exists $opts{BodyRecipe} && !$previous;

    # The literal-line cap on a diff body Recipe: MaxRecipeLiterals on the
    # default path (over it, a null body Recipe), EpilogueThreshold on the
    # epilogue path (over it, the epilogue).
    for my $opt (qw(MaxRecipeLiterals EpilogueThreshold)) {
        next unless exists $opts{$opt};
        croak "$opt must be a non-negative integer"
            unless defined $opts{$opt} && $opts{$opt} =~ /\A[0-9]+\z/;
    }
    croak "MaxRecipeLiterals and EpilogueThreshold are mutually exclusive"
        if exists $opts{MaxRecipeLiterals} && exists $opts{EpilogueThreshold};

    my $body_hash;
    if (exists $opts{BodyHash}) {
        my $bh = $opts{BodyHash};
        $bh = { sha256 => $bh } if defined $bh && !ref $bh;
        croak "BodyHash must be a base64 string or a hashref of algorithm => base64"
            unless ref $bh eq 'HASH';
        for my $alg (@{$self->{algs}}) {
            croak "BodyHash has no $alg hash" unless defined $bh->{$alg};
        }
        # Each value goes into the h= tag verbatim: it must be the base64
        # of a digest of that algorithm's length, nothing else.
        for my $alg (sort keys %$bh) {
            my $fn = $HASH_ALGS{$alg}
                or croak "BodyHash: unsupported hash algorithm $alg";
            my $v = $bh->{$alg};
            croak "BodyHash $alg is not a $alg digest in base64"
                unless defined $v && !ref $v
                    && $v =~ m{\A[A-Za-z0-9+/]+={0,2}\z}
                    && length(decode_base64($v)) == length($fn->(''));
        }
        croak "BodyHash needs BodyRecipe when there is a previous message"
            if $previous && !exists $opts{BodyRecipe};
        $body_hash = $bh;
        # The header block must be complete: a string whose last field has
        # no line break gets one (nothing reads the body here).
        $current .= "\r\n"
            if !ref $current && $current !~ /\n\z/;
    }

    unless (ref($current) && $current->isa('Email::MIME')) {
        $current = parse_mime($current);
    }

    # $rb_recipe is determined before hash computation because epilogue
    # strategies modify $current in place, and hashes must cover the
    # final (possibly modified) message.
    my $rb_recipe;

    if ($previous) {
        unless (ref($previous) && $previous->isa('Email::MIME')) {
            $previous = parse_mime($previous);
        }

        my @mi_cur = $current->header_raw('Message-Instance');
        my @mi_prev = $previous->header_raw('Message-Instance');
        die "Message already has " . MAX_CHAIN_LENGTH . " instances\n"
            if @mi_cur >= MAX_CHAIN_LENGTH;
        if (my $error = _chain_error($current)) {
            die "$error\n";
        }
        # No instances on either side is a first instance with Recipes
        # (-07 section 12.1: changes made as the message enters DKIM2).
        # Verify same message by checking MI headers match
        # header_raw returns values only, so prepend the name for canonicalization
        my $canon_cur  = join(',', map { dkim2_canonicalize_header("Message-Instance: $_") } @mi_cur);
        my $canon_prev = join(',', map { dkim2_canonicalize_header("Message-Instance: $_") } @mi_prev);
        die "This isn't the same message" unless ($canon_cur eq $canon_prev);

        my %map = map { extract_mi_version($_) => $_ } @mi_cur;
        $self->set_tag('m', (max(keys %map) // 0) + 1);

        if (exists $opts{BodyRecipe}) {
            # Caller supplies the body Recipe: no body diff runs.
            my $br = $opts{BodyRecipe};
            if (defined $br && !ref $br && $br eq 'none') {
                $rb_recipe = undef;
                # No b key declares the body unchanged: a caller-supplied
                # BodyHash must then be the previous instance's body hash.
                _check_body_unchanged($previous, $body_hash, $self->{algs})
                    if $body_hash;
            } elsif (defined $br && !ref $br && $br eq 'null') {
                $self->set_null_body_recipe;
            } elsif (ref $br eq 'ARRAY') {
                my $last = 0;
                for my $step (@$br) {
                    croak "BodyRecipe step is undefined" unless defined $step;
                    unless (ref $step) {
                        croak "BodyRecipe literal contains a line break"
                            if $step =~ /[\r\n]/;
                        next;
                    }
                    croak "BodyRecipe step must be [from,to] or a string"
                        unless ref $step eq 'ARRAY' && @$step == 2;
                    my ($f, $t) = @$step;
                    croak "BodyRecipe range [$f,$t] invalid"
                        unless $f =~ /^\d+\z/ && $t =~ /^\d+\z/
                            && $f >= 1 && $t >= $f && $f > $last;
                    $last = $t;
                }
                $rb_recipe = [ map { ref $_ ? [ @$_ ] : $_ } @$br ];
            } else {
                croak "BodyRecipe must be 'none', 'null' or an ARRAY ref";
            }
        }
        elsif ($opts{UseEpilogue}) {
            # Always store old body in MIME epilogue.
            $rb_recipe = _epilogue_recipe($current, $previous->body_raw);
        }
        elsif (defined $opts{EpilogueThreshold}) {
            # Use the epilogue only when the diff would need more literal
            # lines than the threshold. The diff has no side effects; the
            # epilogue rewrites $current.
            my $diff = _body_recipe($current->body_raw, $previous->body_raw,
                $opts{EpilogueThreshold});
            $rb_recipe = defined $diff && !ref $diff
                ? _epilogue_recipe($current, $previous->body_raw)
                : $diff;
        }
        else {
            # Default: a diff Recipe, which never modifies $current. A body
            # the diff cannot rebuild within MaxRecipeLiterals lines (default
            # MAX_RECIPE_LITERALS) is declared unrecoverable: a caller that
            # may rewrite the body asks for the epilogue instead.
            $rb_recipe = _body_recipe($current->body_raw, $previous->body_raw,
                $opts{MaxRecipeLiterals});
            if (defined $rb_recipe && !ref $rb_recipe) {
                $rb_recipe = undef;
                $self->set_null_body_recipe;
            }
        }
    }
    else {
        die "Already has Message-Instance headers" if $current->header_raw('Message-Instance');
        $self->set_tag('m', 1);
    }

    # Hashes are always of the current (newest) version of the message,
    # computed after any epilogue modification, for every configured
    # algorithm (-07 §9.3).
    for my $alg (@{$self->{algs}}) {
        $self->{bits}{hashes}{$alg} = [ h_digest($current, $alg, $prefixes),
            $body_hash ? $body_hash->{$alg} : b_digest($current, $alg) ];
    }
    if (my $sha256 = $self->{bits}{hashes}{sha256}) {
        @{$self->{bits}}{qw(h1 b1)} = @$sha256;
    }

    # nothing more to calculate without a previous version
    return $self unless $previous;

    # calculate the header difference (always, even for UseEpilogue, since
    # wrapping changes Content-Type and we need rh to undo that)
    my %all = map { lc($_) => 1 } ($current->header_names, $previous->header_names);
    my %hdiff;
    for my $h (sort keys %all) {
        next if should_skip($h, $prefixes);
        my @cur  = reverse $current->header_raw($h);
        my @prev = reverse $previous->header_raw($h);
        # Same number of instances AND the same values: zero instances and
        # one empty instance both join to "", and removing an empty field
        # (a bare "Bcc:") is still a change the Recipe must record.
        next if @cur == @prev
             && join("\n", map { dkim2_canonicalize_header($_) } @cur)
             eq join("\n", map { dkim2_canonicalize_header($_) } @prev);
        # headers are indexed from 1 from the bottom up
        my %known;
        push @{ $known{dkim2_canonicalize_header($cur[$_])} }, $_ + 1 for 0..$#cur;
        # Recipe: reconstruct @prev from @cur. Copy ranges must ascend (each
        # starts after the last one ends, -07 §5.1), so each field of
        # @cur is copied at most once and never out of turn: a repeat, or a
        # field the hop moved above one it left alone, goes in literally.
        # $last_end only grows, so each value's ascending index list is
        # consumed through a cursor that never moves back: linear overall.
        # (A grep over the whole list per field made N repeated fields cost
        # N^2 -- follow-up review F1.)
        my $last_end = 0;
        my %cursor;
        my @res = map {
            my $canon = dkim2_canonicalize_header($_);
            my $list = $known{$canon} || [];
            my $c = \($cursor{$canon} //= 0);
            $$c++ while $$c < @$list && $list->[$$c] <= $last_end;
            my $idx = $list->[$$c];
            $idx ? [$idx, $last_end = $idx] : $_
        } @prev;
        # combine adjacent ranges
        for (1..$#res) {
            next unless (ref $res[$_] && ref $res[$_-1]);
            next unless ($res[$_][0] == $res[$_-1][1] + 1);
            $res[$_][0] = $res[$_-1][0];
            $res[$_-1] = undef;
        }
        my @vals = grep { defined } @res;
        $hdiff{$h} = \@vals;
    }

    if ($rb_recipe) {
        $self->set_tag('rb', $rb_recipe);
    }
    if (keys %hdiff) {
        $self->set_tag('rh', \%hdiff);
    }

    return $self;
}

# --- First instance over earlier unsigned ones ---

sub calculate_first {
    my ($class, $current, $previous, %opts) = @_;
    Mail::DKIM2::Common::_check_options("$class->calculate_first", \%opts,
        qw(Algs EpilogueThreshold IgnorePrefixes MaxRecipeLiterals UseEpilogue));
    _check_epilogue(%opts);
    croak "need a message" unless $current;
    croak "need a previous message" unless $previous;

    $current = parse_mime($current) unless ref($current) && $current->isa('Email::MIME');
    # undo() (and so chain_verifies) rewrites the message it is given: work
    # on copies of $previous.
    my $prev_raw = ref($previous) ? $previous->as_string : $previous;
    $previous = parse_mime($prev_raw);

    # Only a chain that undoes cleanly says what the message was before it.
    my ($ok, $why) = $class->chain_verifies($prev_raw,
        (exists $opts{IgnorePrefixes} ? (IgnorePrefixes => $opts{IgnorePrefixes}) : ()));
    die(($why // 'Message-Instance chain does not verify') . "\n") unless $ok;

    # Undo every instance, m=1 included (its own Recipes, if any). Past a
    # null body Recipe the earlier body is gone: header Recipes only, and
    # the new instance declares the body unrecoverable.
    my $lost = 0;
    while (my @mi = $previous->header_raw('Message-Instance')) {
        my %by_v = map { (extract_mi_version($_) // 0) => $_ } @mi;
        $lost = 1 if $class->parse($by_v{ max(keys %by_v) })->unrecoverable;
        $previous = $class->undo($previous, HeadersOnly => $lost);
    }
    $current->header_set('Message-Instance');

    return $class->calculate($current, $previous, %opts,
        ($lost ? (BodyRecipe => 'null') : ()));
}

# --- Verify ---

sub verify {
    my ($class, $msg, %opts) = @_;
    Mail::DKIM2::Common::_check_options("$class->verify", \%opts,
        qw(HeadersOnly IgnorePrefixes BodyHashes));
    croak "need a message" unless $msg;
    check_ignore_prefixes($opts{IgnorePrefixes});

    unless (ref($msg) && $msg->isa('Email::MIME')) {
        $msg = parse_mime($msg);
    }

    if (my $error = _chain_error($msg)) {
        return wantarray ? (0, $error) : 0;
    }

    my %map = map { extract_mi_version($_) => $_ } $msg->header_raw('Message-Instance');
    my $num = keys %map ? max(keys %map) : 0;
    return 0 unless $num;

    # A crafted instance (duplicate algorithm, bad hash set, unparseable
    # Recipe) is a verdict, not an exception: this is the status-returning
    # half of the contract, and a host must not have to eval it.
    my $self = eval { $class->parse($map{$num}) };
    unless ($self) {
        die $@ if ref $@;
        my $err = _parse_error($@);
        return wantarray ? (0, $err) : 0;
    }

    my ($ok, $err) = $self->_check_hashes($num,
        sub { h_digest($msg, $_[0], $opts{IgnorePrefixes}) },
        # HeadersOnly: below a null body Recipe the body this instance
        # hashed is gone; its header hashes are still checkable.
        # BodyHashes: computed already (Mail::DKIM2::BodyPlan), from a body
        # $msg does not carry.
        $opts{HeadersOnly} ? undef
      : $opts{BodyHashes}  ? sub { $opts{BodyHashes}{$_[0]} // '' }
      :                      sub { b_digest($msg, $_[0]) });
    return wantarray ? (0, $err) : 0 unless $ok;
    return $num;
}

# A parse() failure in the words verify() reports it.
sub _parse_error {
    my ($err) = @_;
    $err =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//;
    $err =~ s/\s+\z//;
    return $err;
}

# Instance $num's hash-sets against the header and body hashes the two
# callbacks give for an algorithm ($body undef: headers only). Returns 1,
# or (0, $reason) at the first mismatch.
sub _check_hashes {
    my ($self, $num, $header, $body) = @_;

    # -07 §3.5: verify every hash-set whose algorithm we implement; ALL
    # of them must match. If none names an implemented algorithm, fail
    # closed rather than treating it as "no hash" -- an MI signed with only
    # sha512 (say) is perfectly valid and must verify via its sha512 set,
    # not be rejected just because h1/b1 (the sha256 alias) are undef.
    my $hashes = $self->get_tag('hashes') || {};
    my $impl = hash_algs();
    # h= order: as parsed, or as calculate() writes them (its algs).
    my @usable = grep { $impl->{$_} && $hashes->{$_} }
                 @{ $self->{hash_order} || $self->{algs} || [ sort keys %$hashes ] };

    return (0, "PERMERROR: Message-Instance m=$num no supported hash algorithm") unless @usable;

    # -07 section 14.7's words, naming the algorithm. Every header hash, in
    # h= order, before any body hash (interop contract C9), so every
    # verifier names the same one when several are wrong.
    for my $alg (@usable) {
        return (0, "FAIL: Message-Instance m=$num header hash $alg mismatch")
            if $hashes->{$alg}[0] ne $header->($alg);
    }
    return 1 unless $body;
    for my $alg (@usable) {
        return (0, "FAIL: Message-Instance m=$num body hash $alg mismatch")
            if $hashes->{$alg}[1] ne $body->($alg);
    }
    return 1;
}

# --- Undo ---

# Rebuild the previous lines from @$old by a Recipe of [from, to] copy ranges
# (1-based, inclusive) and literal lines. Each range must lie within @$old,
# and the ranges must ascend: each must start after the one before it ends
# (-07 §5.1, and the same rule for the body). The previous version is
# rebuilt from this one, and a hop's change never needs a line of it twice
# or in a different order -- a reordering is recorded literally. Without the
# check a few bytes of header could name a copy of billions of lines.
# Everything is checked before anything is copied.
#
# A bound must be a JSON integer (-07 §5 schema): {"c":["1","2"]} is
# malformed, and every verifier in the interop set rejects it. The JSON
# decoder gives a number an IV and a string a PV, so the distinction is
# read off the scalar's flags -- before anything stringifies it, which
# would set POK on a genuine number too.
sub _is_json_integer {
    my ($v) = @_;
    return 0 unless defined $v && !ref $v;
    my $flags = B::svref_2object(\$v)->FLAGS;
    return ($flags & B::SVf_IOK) && !($flags & (B::SVf_POK | B::SVf_NOK)) ? 1 : 0;
}

# A JSON string, read off the flags the same way: a JSON number is not one.
sub _is_json_string {
    my ($v) = @_;
    return 0 unless defined $v && !ref $v;
    return (B::svref_2object(\$v)->FLAGS & B::SVf_POK) ? 1 : 0;
}

# Recipe structure: integer bounds, from <= to, ascending, non-overlapping.
# $lines, when given, also bounds "to" by the old body/header; it is omitted
# when the thing the Recipe applies to is gone (a body below a null body
# Recipe), where the structure must still be valid.
sub _check_recipe {
    my ($what, $recipe, $lines) = @_;
    my $prev;
    for my $cmd (grep { ref($_) eq 'ARRAY' } @$recipe) {
        my ($from, $to) = @$cmd;
        die "$what Recipe has a malformed copy range\n"
            unless @$cmd == 2
                && _is_json_integer($from) && $from >= 0
                && _is_json_integer($to)   && $to   >= 0;
        unless (1 <= $from && $from <= $to && (!defined $lines || $to <= $lines)) {
            # No line count (structure-only check below a null body Recipe).
            die "$what Recipe has an invalid copy range $from-$to\n" unless defined $lines;
            die "$what Recipe copies lines $from-$to of $lines\n";
        }
        if ($prev && $from <= $prev->[1]) {
            if ($to >= $prev->[0]) {
                my $lo = $from > $prev->[0] ? $from : $prev->[0];
                my $hi = $to   < $prev->[1] ? $to   : $prev->[1];
                die "$what Recipe copies lines $lo-$hi twice\n";
            }
            die "$what Recipe copies lines $from-$to out of order\n";
        }
        $prev = [$from, $to];
    }
    return;
}

# recipe_order_error(): the message-independent part of _check_recipe for
# this instance's Recipes -- every copy range well formed, ascending, not
# overlapping -- as the reason (a string), or undef when they are. A
# verifier reports one as the instance's "contains invalid JSON" with its
# other field errors (contract C9); the bound a message gives is for
# applying the Recipe to find.
sub recipe_order_error {
    my ($self) = @_;
    my $bits = $self->{bits};
    my @lists = (['body', $bits->{rb}],
                 map { ["header $_", $bits->{rh}{$_}] } sort keys %{ $bits->{rh} || {} });
    for my $l (@lists) {
        next unless $l->[1];
        eval { _check_recipe(@$l); 1 } and next;
        die $@ if ref $@;
        (my $why = $@) =~ s/\s+\z//;
        return $why;
    }
    return undef;
}

sub _apply_recipe {
    my ($what, $recipe, $old) = @_;
    _check_recipe($what, $recipe, scalar @$old);

    return map {
        ref($_) eq 'ARRAY' ? @$old[$_->[0] - 1 .. $_->[1] - 1] : $_
    } @$recipe;
}

# Set a message's body to exactly these octets. Email::MIME->body_set encodes
# what it is given according to the Content-Transfer-Encoding header, so on a
# base64 or quoted-printable part the rebuilt previous body -- already in its
# wire encoding, since Recipes work on wire lines -- came back encoded twice,
# and every base64/QP message a list re-encoded failed its m=1 hash on undo
# (2026-10-04: 17 of 88 corpus samples through Mailman; the milter refused to
# sign them). This is Email::MIME::body_set without the encoding step.
sub _body_raw_set {
    my ($msg, $raw) = @_;
    $msg->{body_raw} = $raw;
    $msg->Email::Simple::body_set($raw);
    return;
}

sub undo {
    my ($class, $msg, %opts) = @_;
    Mail::DKIM2::Common::_check_options("$class->undo", \%opts, qw(HeadersOnly));
    croak "need a message" unless $msg;

    unless (ref($msg) && $msg->isa('Email::MIME')) {
        $msg = parse_mime($msg);
    }

    if (my $error = _chain_error($msg)) {
        die "$error\n";
    }

    my %map = map { extract_mi_version($_) => $_ } $msg->header_raw('Message-Instance');
    my $num = keys %map ? max(keys %map) : 0;
    return unless $num;

    $msg->header_obj->header_filter('Message-Instance', sub { extract_mi_version(shift) < $num });

    my $self = $class->parse($map{$num});

    my $rb = $self->get_tag('rb');
    my $rh = $self->get_tag('rh');

    if ($rb && !$opts{HeadersOnly}) {
        # Every line, trailing blank ones too: they are not hashed (§6.1),
        # but a Recipe may number and copy them, as the other
        # implementations in the interop set allow. Only the empty piece
        # after the last line break is not a line.
        my @old = split /\r?\n/, $msg->body_raw, -1;
        pop @old if @old && $old[-1] eq '';
        my @new = _apply_recipe('body', $rb, \@old);
        _body_raw_set($msg, join("\r\n", @new, ''));
    } elsif ($rb) {
        # The body is not rebuilt, but the Recipe must still be well formed.
        _check_recipe('body', $rb);
    }

    if ($rh) {
        for my $h (sort keys %$rh) {
            my $v = $rh->{$h};
            next unless defined $v;
            my @old = reverse $msg->header_raw($h);
            my @new = _apply_recipe("$h header", $v, \@old);
            $msg->header_obj->header_set_reverse($h, @new);
        }
    }

    return $msg;
}

# Verify the WHOLE Message-Instance chain reverses cleanly: check the top
# instance against the current content, then undo it and check the next one
# down, until m=1; past an instance with a null body Recipe, header-only
# (the body is gone but the header history is still checked). This is the
# undo check a recipient performs — running it before signing catches an
# upstream that emitted a non-reversible Recipe.
# Returns (1, undef) on success or (0, reason) on the first failure.
sub chain_verifies {
    my ($class, $msg, %opts) = @_;
    Mail::DKIM2::Common::_check_options("$class->chain_verifies", \%opts,
        qw(IgnorePrefixes));
    check_ignore_prefixes($opts{IgnorePrefixes});
    unless (ref($msg) && $msg->isa('Email::MIME')) {
        $msg = parse_mime("$msg");
    }
    if (my $error = _chain_error($msg)) {
        return (0, $error);
    }
    my $headers_only = 0;
    while (1) {
        my @mi = $msg->header_raw('Message-Instance');
        my %by_v = map { (extract_mi_version($_) // 0) => $_ } @mi;
        my $num = %by_v ? (sort { $b <=> $a } keys %by_v)[0] : 0;
        last unless $num;

        my ($ok, $err) = $class->verify($msg, %opts, HeadersOnly => $headers_only);
        return (0, $err // "FAIL: Message-Instance m=$num header hash mismatch") unless $ok;

        last if $num <= 1;
        # A null body Recipe loses the previous body, not the header
        # history: from here down, undo header Recipes only and check each
        # instance's header hashes, down to m=1.
        $headers_only = 1 if $class->parse($by_v{$num})->unrecoverable;

        my $prev = eval { $class->undo($msg, HeadersOnly => $headers_only) };
        die $@ if ref $@;
        # Every Recipe error is "contains invalid JSON" (the -07 contract);
        # a third value says which range, for a log.
        if ($@ || !$prev) {
            (my $why = $@ // '') =~ s/\s+\z//;
            return (0, $why) if $why =~ /\A(?:PERMERROR|FAIL|TEMPERROR): /;
            return (0, "PERMERROR: Message-Instance m=$num contains invalid JSON", $why);
        }
        $msg = $prev;
    }
    return (1, undef);
}


1;

__END__

=encoding utf8

=head1 NAME

Mail::DKIM2::MessageInstance - Compute, verify and undo Message-Instance headers

=head1 SYNOPSIS

    use Mail::DKIM2::MessageInstance;

    # First hop: record the message as it is.
    my $mi = Mail::DKIM2::MessageInstance->calculate($msg);
    print "Message-Instance: " . $mi->as_string . "\n";

    # A later hop that changed the message: record the new state and a
    # Recipe for getting back to the state it received.
    my $mi = Mail::DKIM2::MessageInstance->calculate($modified, $received);

    # Does the top instance describe this message?
    my $m = Mail::DKIM2::MessageInstance->verify($msg);
    my ($m, $why) = Mail::DKIM2::MessageInstance->verify($msg);

    # Does the whole chain undo cleanly, each instance matching?
    my ($ok, $why) = Mail::DKIM2::MessageInstance->chain_verifies($msg);

    # Apply the top Recipe: the message as the previous hop sent it.
    my $previous = Mail::DKIM2::MessageInstance->undo($msg);

=head1 DESCRIPTION

A Message-Instance header (-07 sections 4 to 9) records the message at
one point in its journey: a hash of its header fields and a hash of its
body, and, from the second instance on, a Recipe for turning this instance
back into the previous one. The wire format is

    m=N; h=<alg>:<header-hash>:<body-hash>[,<alg>:...]; r=<base64 JSON>;

where C<m=> numbers the instance from 1, C<h=> carries one hash set per
algorithm the signer chose (section 7.3: C<sha256>, C<sha512>, or both;
this module emits C<sha256> unless told otherwise and verifies every set it
implements), and C<r=> is the Recipe: C<"b"> for the body and C<"h"> for
header fields, each a list of steps (section 5): C<{"c":[start,end]}>
copies lines or field instances of this version, C<{"d":[...]}> gives
UTF-8 literals (ASCII included) as JSON text, and C<{"u":[...]}> gives
literals whose raw octets are not UTF-8 (a Latin-1 or ISO-2022-JP line,
say) as canonical base64. Copy ranges must ascend: each starts after the
one before it ends. This module emits every JSON key in lower case and
reads keys in any case; a Recipe that breaks the section 5 schema -- a
step with other than exactly one of C<c>, C<d> and C<u>, a "u" string
that is not canonical base64, a literal holding a CR or LF, two keys that
differ only in case, an empty C<"h"> -- is "contains invalid JSON".

Messages are accepted as L<Email::MIME> objects or as strings, which are
parsed. C<verify>, C<undo> and C<chain_verifies> look at the highest
numbered Message-Instance the message carries.

This module implements draft-ietf-dkim-dkim2-spec-07; see L<Mail::DKIM2/STATUS>
for what that means for the wire format and the API, and
L<Mail::DKIM2/CONVENTIONS> for the option, input and error conventions every
module here follows.

=head1 OPTIONS

The class methods below take these options after their positional
arguments:

=over 4

=item IgnorePrefixes

An arrayref of header-field-name prefixes to leave out of the header hash
and header Recipes; see L<Mail::DKIM2/Operator-local header fields>.

=item Algs

C<calculate> only: an arrayref of hash algorithm names for C<h=>, from
C<sha256> and C<sha512>. Default C<['sha256']>.

=item BodyRecipe

C<calculate> with a previous message only: the caller supplies the body
Recipe and no body diff runs (the body of C<$previous> is ignored, and may
be empty). One of C<'none'> (no C<b> key), C<'null'> (C<"b": null>), or an
ARRAY ref in the internal form: C<[from,to]> arrays for copy ranges (1-based
body lines of C<$msg>, ascending) and plain strings for literal lines,
each one line without its line break. An empty array gives C<"b": []>.
Croaks on a malformed value: C<undef>, an undefined step, a bad range, a
literal containing CR or LF, or C<BodyRecipe> with no C<$previous>.
C<'none'> declares the body unchanged; with C<BodyHash> as well, croaks
unless that hash equals the body hash of the top Message-Instance of
C<$previous> (for every algorithm both carry, and at least one).

=item BodyHash

C<calculate> only, with no C<$previous> or with C<BodyRecipe>: the body
hash, already computed with C<body_digest_raw> (below) over the body of C<$msg>.
A base64 string is the C<sha256> hash; a hashref maps each algorithm in
C<Algs> to its hash. The body of C<$msg> is then neither hashed nor read,
so C<$msg> may be the header block alone (the fields and the blank line
after them): a list manager sending many copies of a large body hashes
each body once and never has the module parse it. A string C<$msg> that
does not end in a line break gets a CRLF appended, so a header block
whose last field lacks one is still complete. Croaks if an algorithm is
missing or unsupported, if a value is not the base64 of a digest of that
algorithm's length (32 octets for C<sha256>, 64 for C<sha512>), or if the
body is needed (a previous message without C<BodyRecipe>, which runs the
body diff).

=item UseEpilogue, EpilogueThreshold, MaxRecipeLiterals

C<calculate> with a previous message only; see below. B<UseEpilogue> (true)
and B<EpilogueThreshold> are disabled in 0.23: they croak. The instance would
be computed over the message rewritten with the epilogue while a caller that
holds the message as a string signs the original bytes, and that mail fails
verification.

=back

=head1 CLASS METHODS

=head2 calculate($msg, [$previous], %options)

Returns a new instance describing C<$msg>. With no C<$previous>, C<$msg>
must carry no Message-Instance and the result is C<m=1>. With
C<$previous>, both messages must carry the same existing instances; the
result is the next C<m=> (C<m=1> when neither carries any: a first instance
with Recipes, -07 section 12.1), with hashes of C<$msg> and Recipes that rebuild
C<$previous> from it. Dies if the message cannot be processed: it already
has 32 instances, its instances do not form a chain, or C<$previous> is
not an earlier form of the same message.

The body Recipe is a line diff by default: a Myers diff with the fewest
literal lines, bounded by C<< MaxRecipeLiterals => N >> literal lines (default 1000)
and a fixed amount of work. A body it cannot rebuild within those bounds
gets the null body Recipe (the previous body is unrecoverable). (Disabled
in 0.23, see above:) With C<< UseEpilogue => 1 >>, the
previous body is instead appended after the final MIME boundary (the
message is wrapped in a C<multipart/mixed> container if it is not already
multipart) and the Recipe copies it from there; with C<< EpilogueThreshold
=> N >>, that happens only when the diff would need more than C<N> literal
lines (or more work than the fixed bound), and an unchanged body gets no
Recipe. C<EpilogueThreshold> and C<MaxRecipeLiterals> are mutually
exclusive; both must be non-negative integers. Both epilogue forms modify C<$msg> in place, and the
hashes cover the modified message.

=head2 calculate_first($msg, $previous, %options)

Returns an C<m=1> instance for a message none of whose instances is
signed: the hashes of C<$msg> less its Message-Instance fields, and Recipes
that rebuild C<$previous> as it was before its first instance (-07 section
12.1 lets the first instance record the changes made as the message enters
DKIM2). C<$previous> may carry instances, a stamped C<m=1> and local ones
over it; their whole chain must verify (C<chain_verifies>), and every one
is undone, C<m=1> included. Past a null body Recipe the earlier body is
gone and the result gets the null body Recipe. C<$msg>'s Message-Instance
fields are removed from it in place (pass a string to leave yours alone);
the caller removes them from the message it sends. Takes C<calculate>'s
options except C<BodyHash> and C<BodyRecipe>. Dies if the chain of
C<$previous> does not verify, with the reason C<chain_verifies> gives.

=head2 verify($msg, %options)

Checks the top instance against the message. Returns its C<m=> on success.
On failure, including an instance that does not parse, returns C<0> in
scalar context and C<(0, $reason)> in list context, the reason in the -07
words with its state, e.g. C<"FAIL: Message-Instance m=2 body hash sha256
mismatch"> or C<"PERMERROR: Message-Instance m=2 contains invalid JSON">.
Never dies.

With C<HeadersOnly =E<gt> 1> only the header hashes are checked and the body
hash is skipped; this is how instances below a null body Recipe are checked,
since the body they hashed is gone.

With C<BodyHashes =E<gt> { $alg =E<gt> $base64, ... }> the body hashes are
those given, computed elsewhere (L<Mail::DKIM2::BodyPlan>), not those of
C<$msg>'s body.

=head2 undo($msg, %options)

Applies the top instance's Recipes and removes that instance, returning
the L<Email::MIME> of the previous form of the message; undef if there is
no instance. Dies if the Recipe is malformed (a copy range outside the
message, overlapping another or out of order, or anything the section 5
schema forbids) or the instances do not form a chain.

With C<HeadersOnly =E<gt> 1> only the header Recipes are applied and the body
is left as it is.

=head2 chain_verifies($msg, %options)

Runs C<verify> and C<undo> down the whole chain to C<m=1>. Past an instance
with a null body Recipe (previous body unrecoverable) it carries on
header-only (C<HeadersOnly>), so every lower instance's header hashes are
still checked. Returns C<(1, undef)> only when the whole header history
checks out, or C<(0, $reason)> at the first instance that does not match or
does not undo, the reason as C<verify> gives it. Every Recipe that does not
undo is C<"PERMERROR: Message-Instance m=N contains invalid JSON"> (the
-07 contract); a third value then says why (C<"body Recipe copies lines
2-2 twice">). Never dies. A forwarder runs this before signing so it does
not put its name to a chain its recipients will reject.

=head2 parse($header_value)

Parses a Message-Instance header value into an object. Dies with a
C<PERMERROR: > string on a missing C<m=> or C<h=>, a hash set that is not
C<alg:hash:hash>, an algorithm named twice, a tag repeated in any case, or
a Recipe that is not valid JSON or breaks the section 5 schema
("PERMERROR: Message-Instance m=N contains invalid JSON").

=head2 recipe_order_error()

The message-independent part of the Recipe rules for a parsed instance:
every copy range well formed, ascending, and not overlapping another. Returns
the reason as a string, or undef when the Recipes keep the rules. A verifier
reports a failure as the instance's "contains invalid JSON", with the field's
other errors; whether a range lies within the message is for applying the
Recipe (L</undo>) to find.

=head2 hash_algs()

A hashref of the hash algorithms this module implements, name to
function.

=head2 parse_hash_sets($h_value)

Splits an C<h=> value into an arrayref of C<[alg, header_hash, body_hash]>,
lowercasing the names and stripping folding whitespace from around the names
and inside the hashes. Returns undef if any hash-set is malformed.

=head1 INSTANCE METHODS

=head2 as_string()

The header value in wire format, unfolded. Fold it with
L<Mail::DKIM2::Common/fold_header> before inserting it.

=head2 header_hash()

The base64 sha256 header hash, or undef if the instance carries no sha256
set.

=head2 body_hash()

The base64 sha256 body hash, or undef if the instance carries no sha256
set.

=head2 body_digest_raw($body, [$alg])

Function, not a method. The body hash of a raw body string with LF or CRLF
line ends, equal to what the instance records for a message with that body.
C<$alg> defaults to C<sha256>.

=head2 unrecoverable()

True if the body Recipe is C<null>: the body changed and the previous
state cannot be recreated (section 4.2), so the chain cannot be undone
past this instance.

=head2 set_null_body_recipe()

Marks the body Recipe C<null>.

=head2 get_tag($name), set_tag($name, $value)

The parsed fields: C<m>, C<hashes> (a hashref of algorithm to
C<[header_hash, body_hash]>), C<rb> and C<rh> (the body and header
Recipes in internal form), and C<h1>/C<b1>, the sha256 pair.

=head1 FUNCTIONS

=head2 h_digest($email_mime, [$alg], [\@prefixes])

The base64 header hash of a message: every field not excluded by
L<Mail::DKIM2::Common/should_skip>, canonicalized, sorted by name,
repeated fields in bottom-up order.

=head2 b_digest($email_mime, [$alg])

The base64 body hash, over the body with trailing empty lines removed and
one CRLF added.

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
