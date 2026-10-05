package Mail::DKIM2::MessageInstance;
use strict;
use warnings;

our $VERSION = '0.13';


use Crypt::Digest::SHA256;
use Crypt::Digest::SHA512 qw(sha512 sha512_b64);
use Email::MIME;
use MIME::Base64 qw(encode_base64 decode_base64);
# Algorithm::Diff is loaded lazily by the two body-recipe builders below.
# Recipes are only ever COMPUTED by a hop that modifies an already-signed
# message; signing an originating message and verifying any message both
# apply recipes without diffing. Keeping the load lazy means deployments
# that only sign and verify -- which is all three Fastmail paths -- need
# not install it at all.
use List::Util qw(max);
use B ();
use Carp;

use Mail::DKIM2::Common qw(
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
    duplicate_number_error
);

our $DEBUG = 0;

# The PERMERROR for a message whose Message-Instance fields cannot form a
# chain, or undef.
sub _chain_error {
    my ($msg) = @_;
    my @mi = $msg->header_raw('Message-Instance');
    return chain_length_error($msg)
        // ((grep { !defined extract_mi_version($_) } @mi)
               ? 'PERMERROR Message-Instance without m= tag' : undef)
        // duplicate_number_error('Message-Instance', 'm', map { extract_mi_version($_) } @mi);
}

# spec-06 §3.1: two hashing algorithms are defined. Verifiers MUST implement
# both; Signers MAY implement either or both (we default to sha256).
my %HASH_ALGS = (
    sha256 => \&Crypt::Digest::SHA256::sha256,
    sha512 => \&Crypt::Digest::SHA512::sha512,
);

sub hash_algs { return { %HASH_ALGS } }

# spec-06 §7.3: h= is hash-set *("," hash-set), hash-set = alg ":" hh ":" bh.
# Hash names are lowercased -- RFC 5234 makes ABNF quoted strings
# case-insensitive. All FWS is stripped (§2.12): it may appear anywhere
# inside a base64 value (e.g. a folded header), not just at either end.
sub parse_hash_sets {
    my ($h_tag) = @_;
    my @sets;
    for my $item (split /,/, $h_tag) {
        $item =~ s/[\s\r\n]//g;
        my @parts = split /:/, $item;
        next unless @parts == 3;
        push @sets, [lc $parts[0], $parts[1], $parts[2]];
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

# Mark the body Recipe as null per spec-06 §4.2: the body changed but the
# previous state cannot be recreated. as_string() then emits "b": null.
sub set_null_body_recipe {
    my ($self) = @_;
    $self->{bits}{rb} = \'null';   # scalar-ref sentinel
}

# True if this instance declares the previous state non-recreatable (a null
# "b" Recipe). Such an instance cannot be undone to a prior version. Under
# draft-06 §5.1 a header Recipe can no longer be null, so only the body
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

    # spec-06 §7.3: h= is hash-set *("," hash-set) -- one hash-set per
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
        # spec-06 §5.1: header field names in the JSON Recipes MUST be lower
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
# Wire: {"c": [from,to]} for copy, {"d": ["val1",...]} for ASCII literals,
# {"b": ["base64",...]} for literals carrying any octet >= 0x80.
#
# A literal is the raw octets of a header value or body line. Pure ASCII
# goes in a "d" step as JSON text. Anything with a high bit set goes in a
# "b" step, base64 (RFC 4648 section 4) of the octets: JSON text is UTF-8,
# and most such literals are not (ISO-2022-JP, GB18030, Big5, Latin-1 ...),
# so the only way to carry them in JSON unchanged is to encode them.
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
            # spec-06 §5 schema forbids and Go rejects as invalid JSON.
            push @encoded, { c => [ map { 0 + $_ } @$item ] };
        } else {
            my $kind = ($item =~ /[^\x00-\x7F]/) ? 'b' : 'd';
            $flush->() if $kind ne $pending_kind;
            $pending_kind = $kind;
            push @pending, $kind eq 'b' ? encode_base64($item, '') : $item;
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

    # Parse tag-value format: m=N; h=...; r=...
    my %tags;
    for my $part (split /\s*;\s*/, $header) {
        next unless $part =~ /^(\w+)\s*=\s*(.*)/s;
        my ($name, $val) = ($1, $2);
        $val =~ s/\s//gs;
        $tags{$name} = $val;
    }

    die "missing m= tag in Message-Instance header"
        unless exists $tags{m};
    $self->{bits}{m} = $tags{m};

    # spec-06 §7.3: h= is a list of hash-sets
    if (exists $tags{h}) {
        my $sets = parse_hash_sets($tags{h});

        # §7.3: an algorithm MUST NOT be present more than once. Check the
        # LIST returned by parse_hash_sets, not a hash keyed by algorithm --
        # a hash would let the second occurrence silently overwrite the
        # first, hiding the duplicate. Hash names are already lowercased by
        # parse_hash_sets (RFC 5234 makes ABNF quoted strings
        # case-insensitive), so this comparison is case-insensitive too.
        # This must run before any hash is computed or compared.
        my %seen;
        for my $s (@$sets) {
            if ($seen{$s->[0]}++) {
                die "PERMERROR Message-Instance m=$tags{m} has a duplicate hash algorithm\n";
            }
        }

        for my $s (@$sets) {
            $self->{bits}{hashes}{$s->[0]} = [$s->[1], $s->[2]];
        }
        # Back-compatible aliases for the sha256 hash-set
        if (my $sha256 = $self->{bits}{hashes}{sha256}) {
            @{$self->{bits}}{qw(h1 b1)} = @$sha256;
        }
    }

    if (exists $tags{r}) {
        # spec-06 §11.2: a bad base64 r= value and a post-decode JSON parse
        # failure are different errors and must stay distinct: base64
        # failure -> "syntax error" (§11.2 lists this explicitly for
        # malformed field content); JSON failure -> "contains invalid JSON".
        # decode_base64() is lenient (silently drops non-alphabet
        # characters rather than failing), so a strict format check is
        # needed here to actually catch malformed base64 -- otherwise it
        # would just decode to garbage bytes that happen to also fail JSON
        # parsing, mislabelling the error.
        if ($tags{r} !~ m{\A(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?\z}) {
            die "PERMERROR Message-Instance m=$tags{m} syntax error\n";
        }
        my $recipe_data = eval { decode_tag_json($tags{r}) };
        if ($@) {
            die $@ if ref $@;
            die "PERMERROR Message-Instance m=$tags{m} contains invalid JSON\n";
        }
        # A present-but-null "b"/"h" (spec §4.1/§4.2) means the previous state
        # cannot be recreated — distinct from an absent field (no change).
        if (exists $recipe_data->{b}) {
            if (defined $recipe_data->{b} && ref($recipe_data->{b}) eq 'ARRAY') {
                $self->{bits}{rb} = _decode_recipe_list($recipe_data->{b}, $tags{m});
            } else {
                $self->{bits}{rb_null} = 1;
            }
        }
        if (exists $recipe_data->{h}) {
            if (defined $recipe_data->{h} && ref($recipe_data->{h}) eq 'HASH' && keys %{$recipe_data->{h}}) {
                my %rh;
                for my $h (keys %{$recipe_data->{h}}) {
                    $rh{$h} = _decode_recipe_list($recipe_data->{h}{$h}, $tags{m});
                }
                $self->{bits}{rh} = \%rh;
            } else {
                # spec-06 §5.1 disallows the null header Recipe: a present "h"
                # MUST be a non-empty object. Reject anything else.
                die "header recipe is null: not permitted under draft-06 §5.1\n";
            }
        }
    }

    return $self;
}

# Convert wire format Recipe list to internal format
# Wire: {"c": [from,to]} for copy, {"d": ["val1",...]} for text literals,
# {"b": ["base64",...]} for base64 literals
# Internal: [from,to] arrays for copy ranges, strings for literal content
#
# A "b" item is decoded here, so the rest of the module sees one kind of
# literal: a plain byte string. decode_base64() is lenient (it drops
# characters it does not know), so the alphabet and padding are checked
# first; and no literal, "d" text or decoded "b" octets, may contain CR or
# LF (§5.1/§5.2), since a literal is exactly one header value or one body
# line. Each of these is a malformed Recipe: $m is the instance number for
# the PERMERROR text.
sub _decode_recipe_list {
    my ($list, $m) = @_;
    $m //= '?';
    my @decoded;
    for my $item (@$list) {
        if (ref $item eq 'HASH') {
            if (exists $item->{c}) {
                push @decoded, $item->{c};
            } elsif (exists $item->{d}) {
                # schema: "d" is an array of at least one string
                die "PERMERROR Message-Instance m=$m Recipe has an empty literal step\n"
                    unless ref $item->{d} eq 'ARRAY' && @{$item->{d}};
                # §5.1/§5.2: the text strings MUST NOT contain CR or LF
                for my $text (@{$item->{d}}) {
                    die "PERMERROR Message-Instance m=$m Recipe literal contains CR or LF\n"
                        if !defined $text || ref $text || $text =~ /[\r\n]/;
                }
                push @decoded, @{$item->{d}};
            } elsif (exists $item->{b}) {
                die "PERMERROR Message-Instance m=$m Recipe has a malformed base64 literal\n"
                    unless ref $item->{b} eq 'ARRAY';
                die "PERMERROR Message-Instance m=$m Recipe has an empty literal step\n"
                    unless @{$item->{b}};
                for my $b64 (@{$item->{b}}) {
                    die "PERMERROR Message-Instance m=$m Recipe has a malformed base64 literal\n"
                        unless defined $b64 && !ref $b64
                            && $b64 =~ m{\A(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?\z};
                    my $octets = decode_base64($b64);
                    die "PERMERROR Message-Instance m=$m Recipe literal contains CR or LF\n"
                        if $octets =~ /[\r\n]/;
                    push @decoded, $octets;
                }
            }
            # {"z": true} is ignored — spec-04 removed it from the JSON schema
            # but §11 still uses it for truncated-body DSNs (spec inconsistency;
            # see spec-review-notes.md). Keep ignoring for backward compatibility.
        } elsif (ref $item eq 'ARRAY') {
            # Legacy bare array format — accept for backward compat
            push @decoded, $item;
        } else {
            # Legacy bare string — accept for backward compat
            push @decoded, $item;
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

# spec-06 §3.1/§3.4: hash $data with the named (implemented) algorithm and
# base64-encode the result. Equivalent to the historic digest64($digest)
# path for sha256 (verified byte-identical), generalised to any algorithm
# in %HASH_ALGS.
sub _hash_data_b64 {
    my ($alg, $data) = @_;
    my $fn = $HASH_ALGS{$alg} or croak "unsupported hash algorithm: $alg";
    return encode_base64($fn->($data), '');
}

# --- Body Recipe computation ---

# Straight line-level diff using Algorithm::Diff.
sub _body_recipe_linediff {
    require Algorithm::Diff;
    my ($l1, $l2) = @_;

    my $diff = Algorithm::Diff->new($l1, $l2);
    $diff->Base(1);

    my @list;
    my $dirty = 0;
    while ($diff->Next()) {
        if ($diff->Same()) {
            push @list, [$diff->Min(1), $diff->Max(1)];
        } else {
            $dirty = 1;
            push @list, map { $_ } $diff->Items(2);
        }
    }

    return (@list > 1 || $dirty) ? \@list : undef;
}

# Build a cumulative offset table: entry i is the flat byte offset
# where line i starts.  Final entry is the total flat length.
sub _line_offsets {
    my ($lines) = @_;
    my @offsets = (0);
    for my $line (@$lines) {
        push @offsets, $offsets[-1] + length($line);
    }
    return \@offsets;
}

# Map a flat byte position to a 0-based line index.
sub _flat_to_line {
    my ($offsets, $byte_pos) = @_;
    for my $i (0 .. $#$offsets - 1) {
        return $i if $byte_pos < $offsets->[$i + 1];
    }
    return $#$offsets - 1;
}

# Build Recipe entries for a region, using line-level matching.
sub _recipe_for_region {
    require Algorithm::Diff;
    my ($cur_lines, $cur_start, $cur_end,
        $prev_lines, $prev_start, $prev_end) = @_;

    my @cur_region  = @{$cur_lines}[$cur_start .. $cur_end - 1];
    my @prev_region = @{$prev_lines}[$prev_start .. $prev_end - 1];

    return () unless @prev_region;
    if ("@cur_region" eq "@prev_region"
        and @cur_region == @prev_region) {
        # Check element-by-element since join could false-match.
        my $match = 1;
        for my $i (0 .. $#cur_region) {
            if ($cur_region[$i] ne $prev_region[$i]) {
                $match = 0;
                last;
            }
        }
        return ([$cur_start + 1, $cur_end]) if $match;
    }

    my $diff = Algorithm::Diff->new(\@cur_region, \@prev_region);
    $diff->Base(0);

    my @recipe;
    while ($diff->Next()) {
        if ($diff->Same()) {
            push @recipe,
                [$cur_start + $diff->Min(1) + 1,
                 $cur_start + $diff->Max(1) + 1];
        } else {
            push @recipe, $diff->Items(2);
        }
    }
    return @recipe;
}

# Estimate the wire cost of a Recipe.
sub _recipe_cost {
    my ($recipe) = @_;
    return 999999 unless $recipe;
    my $cost = 0;
    for my $item (@$recipe) {
        if (ref $item eq 'ARRAY') {
            $cost += 8;    # [N, M] is cheap
        } else {
            $cost += length($item);
        }
    }
    return $cost;
}

# Byte-level prefix/suffix matching strategy.
# Flattens both bodies, finds common prefix and suffix, maps back
# to line boundaries, then uses line-level matching on the middle.
sub _body_recipe_flat {
    my ($l1, $l2) = @_;

    my $cur_flat  = join('', @$l1);
    my $prev_flat = join('', @$l2);

    # Find common prefix length.
    my $min_len = length($cur_flat) < length($prev_flat)
        ? length($cur_flat) : length($prev_flat);
    my $prefix = 0;
    while ($prefix < $min_len
           and substr($cur_flat, $prefix, 1)
               eq substr($prev_flat, $prefix, 1)) {
        $prefix++;
    }

    # Find common suffix length (not overlapping prefix).
    my $suffix = 0;
    my $max_suffix = $min_len - $prefix;
    while ($suffix < $max_suffix
           and substr($cur_flat, -1 - $suffix, 1)
               eq substr($prev_flat, -1 - $suffix, 1)) {
        $suffix++;
    }

    # If no significant prefix or suffix, this strategy won't help.
    return undef unless $prefix > 0 or $suffix > 0;

    my $cur_offsets  = _line_offsets($l1);
    my $prev_offsets = _line_offsets($l2);

    # Find last complete line within the common prefix.
    my $cur_prefix_end = 0;
    for my $i (0 .. $#$l1) {
        if ($cur_offsets->[$i + 1] <= $prefix) {
            $cur_prefix_end = $i + 1;
        } else {
            last;
        }
    }
    my $prev_prefix_end = 0;
    for my $i (0 .. $#$l2) {
        if ($prev_offsets->[$i + 1] <= $prefix) {
            $prev_prefix_end = $i + 1;
        } else {
            last;
        }
    }

    # Find first complete line within the common suffix.
    my $cur_suffix_start = scalar @$l1;
    if ($suffix > 0) {
        my $tail_start = length($cur_flat) - $suffix;
        for my $i (reverse 0 .. $#$l1) {
            if ($cur_offsets->[$i] >= $tail_start) {
                $cur_suffix_start = $i;
            } else {
                last;
            }
        }
    }
    my $prev_suffix_start = scalar @$l2;
    if ($suffix > 0) {
        my $tail_start = length($prev_flat) - $suffix;
        for my $i (reverse 0 .. $#$l2) {
            if ($prev_offsets->[$i] >= $tail_start) {
                $prev_suffix_start = $i;
            } else {
                last;
            }
        }
    }

    # Ensure suffix doesn't overlap prefix.
    $cur_suffix_start = $cur_prefix_end
        if $cur_suffix_start < $cur_prefix_end;
    $prev_suffix_start = $prev_prefix_end
        if $prev_suffix_start < $prev_prefix_end;

    # Build Recipe: prefix region + middle region + suffix region.
    my @recipe;
    push @recipe, _recipe_for_region(
        $l1, 0, $cur_prefix_end,
        $l2, 0, $prev_prefix_end);
    push @recipe, _recipe_for_region(
        $l1, $cur_prefix_end, $cur_suffix_start,
        $l2, $prev_prefix_end, $prev_suffix_start);
    push @recipe, _recipe_for_region(
        $l1, $cur_suffix_start, scalar @$l1,
        $l2, $prev_suffix_start, scalar @$l2);

    return @recipe ? \@recipe : undef;
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

# Count literal string items in a Recipe (non-array items = lines not in current body).
sub _recipe_literal_lines {
    my ($recipe) = @_;
    return 0 unless $recipe;
    return scalar grep { !ref $_ } @$recipe;
}

# Return the cheaper of the two diff strategies for two raw body strings.
# Returns undef if bodies are identical (no Recipe needed).
sub _best_body_diff {
    my ($cur_raw, $prev_raw) = @_;
    (my $s1 = $cur_raw)  =~ s/[\r\n]+$//;
    (my $s2 = $prev_raw) =~ s/[\r\n]+$//;
    return undef if $s1 eq $s2;
    my @l1 = split /\r?\n/, $s1;
    my @l2 = split /\r?\n/, $s2;
    my $line = _body_recipe_linediff(\@l1, \@l2);
    my $flat = _body_recipe_flat(\@l1, \@l2);
    return undef unless $line || $flat;
    return $flat unless $line;
    return $line unless $flat;
    return _recipe_cost($flat) < _recipe_cost($line) ? $flat : $line;
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

# --- Calculate ---

sub calculate {
    my ($class, $current, $previous, %opts) = @_;
    croak "need a message" unless $current;

    my $self = bless {}, $class;
    my $prefixes = check_ignore_prefixes($opts{IgnorePrefixes});

    # spec-06 §3.1: the signer chooses one or more hash algorithms; default
    # is sha256 only (the signer default MUST NOT change).
    $self->{algs} = ($opts{Algs} && @{$opts{Algs}}) ? [ @{$opts{Algs}} ] : ['sha256'];

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
        die "Previous message has no existing instances" unless @mi_prev;
        # Verify same message by checking MI headers match
        # header_raw returns values only, so prepend the name for canonicalization
        my $canon_cur  = join(',', map { dkim2_canonicalize_header("Message-Instance: $_") } @mi_cur);
        my $canon_prev = join(',', map { dkim2_canonicalize_header("Message-Instance: $_") } @mi_prev);
        die "This isn't the same message" unless ($canon_cur eq $canon_prev);

        my %map = map { extract_mi_version($_) => $_ } @mi_cur;
        $self->set_tag('m', max(keys %map) + 1);

        if ($opts{UseEpilogue}) {
            # Always store old body in MIME epilogue.
            $rb_recipe = _epilogue_recipe($current, $previous->body_raw);
        }
        elsif (defined $opts{EpilogueThreshold}) {
            # Use epilogue only when the diff would exceed the threshold of
            # literal (non-range) lines.  Compute diff first (no side effects),
            # then fall back to epilogue if it is too large.
            my $diff = _best_body_diff($current->body_raw, $previous->body_raw);
            if (!defined $diff || _recipe_literal_lines($diff) > $opts{EpilogueThreshold}) {
                $rb_recipe = _epilogue_recipe($current, $previous->body_raw);
            }
            else {
                $rb_recipe = $diff;
            }
        }
        else {
            # Default: compute diff Recipe (does not modify $current).
            $rb_recipe = _best_body_diff($current->body_raw, $previous->body_raw);
        }
    }
    else {
        die "Already has Message-Instance headers" if $current->header_raw('Message-Instance');
        $self->set_tag('m', 1);
    }

    # Hashes are always of the current (newest) version of the message,
    # computed after any epilogue modification, for every configured
    # algorithm (spec-06 §7.3).
    for my $alg (@{$self->{algs}}) {
        $self->{bits}{hashes}{$alg} = [ h_digest($current, $alg, $prefixes), b_digest($current, $alg) ];
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
        # starts after the last one ends, spec-06 §5.1), so each field of
        # @cur is copied at most once and never out of turn: a repeat, or a
        # field the hop moved above one it left alone, goes in literally.
        my $last_end = 0;
        my @res = map {
            my $canon = dkim2_canonicalize_header($_);
            my ($idx) = grep { $_ > $last_end } @{ $known{$canon} || [] };
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

# --- Verify ---

sub verify {
    my ($class, $msg, %opts) = @_;
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
        (my $err = $@) =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//;
        $err =~ s/\s+\z//;
        return wantarray ? (0, $err) : 0;
    }

    # spec-06 §3.4: verify every hash-set whose algorithm we implement; ALL
    # of them must match. If none names an implemented algorithm, fail
    # closed rather than treating it as "no hash" -- an MI signed with only
    # sha512 (say) is perfectly valid and must verify via its sha512 set,
    # not be rejected just because h1/b1 (the sha256 alias) are undef.
    my $hashes = $self->get_tag('hashes') || {};
    my $impl = hash_algs();
    my @usable = sort grep { $impl->{$_} } keys %$hashes;

    unless (@usable) {
        return wantarray ? (0, "Message-Instance m=$num no supported hash algorithm") : 0;
    }

    for my $alg (@usable) {
        my ($h1, $b1) = @{ $hashes->{$alg} };
        my $hd = h_digest($msg, $alg, $opts{IgnorePrefixes});
        my $bd = b_digest($msg, $alg);
        if ($h1 ne $hd) {
            return wantarray ? (0, "$alg header hash mismatch ($h1 != $hd)") : 0;
        }
        if ($b1 ne $bd) {
            return wantarray ? (0, "$alg body hash mismatch ($b1 != $bd)") : 0;
        }
    }

    return $num;
}

# --- Undo ---

# Rebuild the previous lines from @$old by a Recipe of [from, to] copy ranges
# (1-based, inclusive) and literal lines. Each range must lie within @$old,
# and the ranges must ascend: each must start after the one before it ends
# (spec-06 §5.1, and the same rule for the body). The previous version is
# rebuilt from this one, and a hop's change never needs a line of it twice
# or in a different order -- a reordering is recorded literally. Without the
# check a few bytes of header could name a copy of billions of lines.
# Everything is checked before anything is copied.
#
# A bound must be a JSON integer (spec-06 §5 schema): {"c":["1","2"]} is
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

sub _apply_recipe {
    my ($what, $recipe, $old) = @_;
    my $lines = @$old;
    my $prev;
    for my $cmd (grep { ref($_) eq 'ARRAY' } @$recipe) {
        my ($from, $to) = @$cmd;
        die "$what Recipe has a malformed copy range\n"
            unless @$cmd == 2
                && _is_json_integer($from) && $from >= 0
                && _is_json_integer($to)   && $to   >= 0;
        die "$what Recipe copies lines $from-$to of $lines\n"
            unless 1 <= $from && $from <= $to && $to <= $lines;
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
    my ($class, $msg) = @_;
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

    if ($rb) {
        my @old = split /\r?\n/, $msg->body_raw;
        my @new = _apply_recipe('body', $rb, \@old);
        _body_raw_set($msg, join("\r\n", @new, ''));
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
# down, until m=1 or an instance that declares the previous state
# unrecoverable. This is the undo check a recipient performs — running it
# before signing catches an upstream that emitted a non-reversible Recipe.
# Returns (1, undef) on success or (0, reason) on the first failure.
sub chain_verifies {
    my ($class, $msg, %opts) = @_;
    check_ignore_prefixes($opts{IgnorePrefixes});
    unless (ref($msg) && $msg->isa('Email::MIME')) {
        $msg = parse_mime("$msg");
    }
    if (my $error = _chain_error($msg)) {
        return (0, $error);
    }
    while (1) {
        my @mi = $msg->header_raw('Message-Instance');
        my %by_v = map { (extract_mi_version($_) // 0) => $_ } @mi;
        my $num = %by_v ? (sort { $b <=> $a } keys %by_v)[0] : 0;
        last unless $num;

        my ($ok, $err) = $class->verify($msg, %opts);
        return (0, "Message-Instance m=$num does not match content"
                 . ($err ? " ($err)" : '')) unless $ok;

        last if $num <= 1;
        my $self = $class->parse($by_v{$num});
        last if $self->unrecoverable;

        my $prev = eval { $class->undo($msg) };
        die $@ if ref $@;
        return (0, "Message-Instance m=$num did not undo cleanly"
                 . ($@ ? ": $@" : '')) if $@ || !$prev;
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

A Message-Instance header (spec-06 sections 4 to 7) records the message at
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
ASCII literals as JSON text, and C<{"b":[...]}> gives literals whose raw
octets are not ASCII (a Latin-1 or ISO-2022-JP line, say) as base64. Copy
ranges must ascend: each starts after the one before it ends. The C<"b">
step and the ascending rule for body Recipes are an agreed extension to
spec-06 that is being proposed to the working group; this module emits
C<"b"> for every non-ASCII literal and rejects a Recipe that breaks either
rule.

Messages are accepted as L<Email::MIME> objects or as strings, which are
parsed. C<verify>, C<undo> and C<chain_verifies> look at the highest
numbered Message-Instance the message carries.

This module implements draft-ietf-dkim-dkim2-spec-06; see L<Mail::DKIM2/STATUS>
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

=item UseEpilogue, EpilogueThreshold

C<calculate> with a previous message only; see below.

=back

=head1 CLASS METHODS

=head2 calculate($msg, [$previous], %options)

Returns a new instance describing C<$msg>. With no C<$previous>, C<$msg>
must carry no Message-Instance and the result is C<m=1>. With
C<$previous>, both messages must carry the same existing instances; the
result is the next C<m=>, with hashes of C<$msg> and Recipes that rebuild
C<$previous> from it. Dies if the message cannot be processed: it already
has 32 instances, its instances do not form a chain, or C<$previous> is
not an earlier form of the same message.

The body Recipe is a line diff by default. With C<< UseEpilogue => 1 >>,
the previous body is instead appended after the final MIME boundary (the
message is wrapped in a C<multipart/mixed> container if it is not already
multipart) and the Recipe copies it from there; with C<< EpilogueThreshold
=> N >>, that happens only when the diff would carry more than C<N>
literal lines. Both epilogue forms modify C<$msg> in place, and the hashes
cover the modified message. Recipe computation uses L<Algorithm::Diff>,
loaded on first use.

=head2 verify($msg, %options)

Checks the top instance against the message. Returns its C<m=> on success.
On failure, including an instance that does not parse, returns C<0> in
scalar context and C<(0, $reason)> in list context. Never dies.

=head2 undo($msg)

Applies the top instance's Recipes and removes that instance, returning
the L<Email::MIME> of the previous form of the message; undef if there is
no instance. Dies if the Recipe is malformed (a copy range outside the
message, overlapping another or out of order, or a C<"b"> literal that is
not base64 or decodes to a CR or LF) or the instances do not form a chain.

=head2 chain_verifies($msg, %options)

Runs C<verify> and C<undo> down the whole chain to C<m=1> or to an
instance that declares the previous state unrecoverable. Returns C<(1,
undef)>, or C<(0, $reason)> at the first instance that does not match or
does not undo. Never dies. A forwarder runs this before signing so it does
not put its name to a chain its recipients will reject.

=head2 parse($header_value)

Parses a Message-Instance header value into an object. Dies with a
C<PERMERROR> string on a missing C<m=>, a hash set that is not
C<alg:hash:hash>, or an algorithm named twice.

=head2 hash_algs()

A hashref of the hash algorithms this module implements, name to
function.

=head2 parse_hash_sets($h_value)

Splits an C<h=> value into an arrayref of C<[alg, header_hash, body_hash]>,
lowercasing the names and stripping folding whitespace.

=head1 INSTANCE METHODS

=head2 as_string()

The header value in wire format, unfolded. Fold it with
L<Mail::DKIM2::Common/fold_header> before inserting it.

=head2 header_hash()

The base64 sha256 header hash, or undef if the instance carries no sha256
set.

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
