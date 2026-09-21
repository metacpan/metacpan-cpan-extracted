package File::SOPS::Metadata;
# ABSTRACT: SOPS metadata section handling
our $VERSION = '0.004';
use Moo;
use Carp qw(croak);
use POSIX qw(strftime);
use JSON::MaybeXS;
use Scalar::Util qw(blessed);
use File::SOPS::Encrypted;
use namespace::clean;

our $SOPS_VERSION = '3.7.3';

# The encryption rules this class models, in the order should_encrypt_path
# applies them.
our @ENCRYPTION_RULES = qw(
    unencrypted_suffix encrypted_suffix unencrypted_regex encrypted_regex
);

# Rules the reference implementation has and this distribution does not: they
# select values by the COMMENT attached to them, and neither of our parsers
# keeps comments. They are listed because they take part in the mutual
# exclusion below -- a document carrying one of these must not also carry one
# of ours, whether we understand it or not.
our @UNSUPPORTED_ENCRYPTION_RULES = qw(
    unencrypted_comment_regex encrypted_comment_regex
);

our $DEFAULT_UNENCRYPTED_SUFFIX = '_unencrypted';

# Every field that holds the data key wrapped for one recipient or one
# backend. key_groups is in the list although this class does not model it:
# whatever else it is, it holds wrapped copies of the data key, and a caller
# generating a new one has to know it is there.
our @KEY_MATERIAL_FIELDS = qw(
    age pgp kms gcp_kms azure_kv hc_vault key_groups
);
my %IS_KEY_MATERIAL = map { $_ => 1 } @KEY_MATERIAL_FIELDS;

# Everything this class holds in an attribute of its own. Anything else in a
# document's sops section goes to, and comes back out of, `extra`.
my %MODELLED_FIELD = map { $_ => 1 } qw(
    age pgp kms gcp_kms azure_kv hc_vault
    mac lastmodified version mac_only_encrypted
), @ENCRYPTION_RULES;

# The fields sops declares as a Go string. Everything a `sops` section holds
# is one of these except the per-backend key lists, mac_only_encrypted (bool)
# and shamir_threshold (int) -- and except a field neither implementation
# knows, which sops ignores whatever it holds. The two comment rules are in
# the list although this distribution does not implement them: it reads them,
# and to sops they are strings exactly like the four it does implement.
my @STRING_FIELDS = (
    qw( mac lastmodified version ),
    @ENCRYPTION_RULES,
    @UNSUPPORTED_ENCRYPTION_RULES,
);


has age => (is => 'rw', default => sub { [] });


has pgp => (is => 'rw', default => sub { [] });


has kms => (is => 'rw', default => sub { [] });


has gcp_kms => (is => 'rw', default => sub { [] });


has azure_kv => (is => 'rw', default => sub { [] });


has hc_vault => (is => 'rw', default => sub { [] });


has mac => (is => 'rw');


has lastmodified => (is => 'rw');


has version => (is => 'rw', default => sub { $SOPS_VERSION });


has unencrypted_suffix => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_unencrypted_suffix',
);

# The default applies only when NO other rule was asked for. sops does the
# same (`sops -e` writes `unencrypted_suffix: _unencrypted`, but
# `sops -e --encrypted-suffix _enc` writes only `encrypted_suffix: _enc`), and
# it is not cosmetic: the six rule fields are mutually exclusive and sops
# refuses a document carrying two of them outright, so a default that ignored
# the others would make every configured document unreadable.
sub _build_unencrypted_suffix {
    my ($self) = @_;
    return undef if $self->_other_rules_configured('unencrypted_suffix');
    return $DEFAULT_UNENCRYPTED_SUFFIX;
}


has encrypted_suffix => (is => 'rw');


has unencrypted_regex => (is => 'rw');


has encrypted_regex => (is => 'rw');


has mac_only_encrypted => (is => 'rw');


has extra => (is => 'rw', default => sub { {} });


sub BUILD {
    my ($self) = @_;

    # unencrypted_suffix's builder stands its default down as soon as another
    # rule is configured, so asking the object -- rather than counting the
    # constructor arguments -- cannot report the default as a conflict.
    my @set = grep {
        my $value = $self->rule_value($_);
        defined $value && length $value;
    } @ENCRYPTION_RULES, @UNSUPPORTED_ENCRYPTION_RULES;

    croak "Cannot use more than one of "
        . join(', ', @ENCRYPTION_RULES, @UNSUPPORTED_ENCRYPTION_RULES)
        . " in the same document (got " . join(' and ', @set) . "); "
        . "sops refuses such a file outright"
        if @set > 1;

    return;
}

# The name of a configured rule field other than $except, or undef if there is
# none. $except keeps unencrypted_suffix's lazy builder from asking for the
# value it is in the middle of producing.
sub _other_rules_configured {
    my ($self, $except) = @_;

    for my $rule (@ENCRYPTION_RULES, @UNSUPPORTED_ENCRYPTION_RULES) {
        next if $rule eq $except;
        my $value = $self->rule_value($rule);
        return $rule if defined $value && length $value;
    }

    return;
}

sub rule_value {
    my ($self, $rule) = @_;
    return $self->$rule if $self->can($rule);
    return $self->extra->{$rule};
}


sub policy_args {
    my ($self) = @_;

    # All four are handed over even when undef, because "no rule at all" is a
    # setting and not an absence: passing them through as explicit undef is
    # what stops the constructor's default from inventing an
    # unencrypted_suffix the source document did not have -- which would leave
    # every key ending in _unencrypted in plaintext on the next write.
    my %args = map { $_ => $self->$_ } @ENCRYPTION_RULES;
    $args{mac_only_encrypted} = 1 if $self->mac_only_encrypted;

    # Unmodelled fields come along, minus any that turn out to hold key
    # material: key_groups wraps the data key that is about to be replaced,
    # so carrying it over would leave the new document advertising a stale
    # copy of the old key.
    $args{extra} = {
        map  { $_ => $self->extra->{$_} }
        grep { !$IS_KEY_MATERIAL{$_} } keys %{ $self->extra }
    };

    return %args;
}


sub key_material_fields {
    my ($self) = @_;

    return grep {
        my $value = $self->can($_) ? $self->$_ : $self->extra->{$_};
        ref $value eq 'ARRAY' ? scalar @$value : defined $value;
    } @KEY_MATERIAL_FIELDS;
}


# What the `sops` entry turned out to be, for the refusal below. Names the
# shape only -- never the value, which in a document using that key for its own
# purposes is the user's data.
sub _shape_of {
    my ($value) = @_;
    return 'null'                unless defined $value;
    my $ref = ref $value;
    return 'a scalar'            unless $ref;
    return 'a list'              if $ref eq 'ARRAY';
    return 'a code reference'    if $ref eq 'CODE';
    return "a $ref reference";
}

###############################################################################
# Weak decoding -- the two fields in a `sops` section that are not strings
#
# sops decodes its whole metadata section through mapstructure with
# WeaklyTypedInput, so a field's TEXT is read as its type: `mac_only_encrypted:
# "false"` is the boolean false and `shamir_threshold: "2"` is the integer 2.
# Anything outside the accepted set is not guessed at -- sops stops with
# `cannot parse value as 'bool'` / `as 'int'` and exit 1.
#
# That is not a property of the untyped ENV and INI encodings, which is what
# decides that this lives HERE and not in File::SOPS::Metadata::Flat->unflatten:
# measured against sops 3.13.3 in a NESTED yaml section, a quoted "false" is
# false there too. Coercing in unflatten would leave the identical bug in the
# format that has a handler today. See docs/adr/0042, and t/55 for the tables.
#
# It matters most for mac_only_encrypted, which PICKS THE DIGEST: with it set
# the MAC covers only the encrypted values, behind a 32-byte prefix. Perl's
# 'false' is TRUE, so reading the string as Perl would means computing the
# wrong MAC for a document sops reads at exit 0.

# strconv.ParseBool's accepted set, exactly -- and it is short. `yes`, `no`,
# `on` and `off` are NOT in it, in any case, quoted or bare.
my %PARSE_BOOL = (
    '1' => 1, 't' => 1, 'T' => 1, 'TRUE'  => 1, 'true'  => 1, 'True'  => 1,
    '0' => 0, 'f' => 0, 'F' => 0, 'FALSE' => 0, 'false' => 0, 'False' => 0,
);

# A reference where sops wants a scalar: it refuses with "expected type 'bool',
# got unconvertible type". A JSON::PP::Boolean is not one of these -- it is the
# typed value itself.
sub _is_unconvertible {
    my ($value) = @_;
    return 0 unless ref $value;
    return 0 if blessed($value) && $value->isa('JSON::PP::Boolean');
    return 1;
}

# Whether the parser already typed this scalar. Asked of
# File::SOPS::Encrypted->detect_type rather than of the SV flags here, so that
# the question "is this a string or a number" has ONE answer in this
# distribution -- see ADR 0002. Only a string is decoded; a value that arrived
# typed is what sops's decoder does no work on.
sub _is_text {
    my ($value) = @_;
    return File::SOPS::Encrypted->detect_type($value) eq 'str' ? 1 : 0;
}

# The other side of the same weak decoding: the fields that ARE strings.
# mapstructure stringifies whatever scalar it finds there -- measured on sops
# 3.13.3, `unencrypted_suffix: 3` is read as "3", `true` as "1" and `1e20` as
# "100000000000000000000", and `sops rotate` writes that text back out -- but
# a LIST or a MAP is refused outright, in every one of them, exit 1. So this
# refuses the container and passes the scalar through; Perl's own text agrees
# with Go's for every spelling but a float outside positional range, which no
# document either implementation writes can carry. docs/adr/0043.
#
# The refusal is not decoration. Measured before it landed: `encrypted_regex:
# []` reached should_encrypt_key as the pattern, matched no key, and
# File::SOPS->rotate wrote every value of the document in PLAINTEXT and
# reported success -- for a document sops will not open at all. A reference in
# `lastmodified` becomes the AAD of the MAC, whose bytes are then a memory
# address.
sub _assert_string_field {
    my ($field, $value) = @_;

    croak "the 'sops' section's '$field' is " . _shape_of($value) . ", and a "
        . "string is what belongs there. sops refuses the same document with "
        . "\"'$field' expected type 'string', got unconvertible type\", exit 1."
        if _is_unconvertible($value);

    return $value;
}

sub _decode_bool_field {
    my ($field, $value) = @_;

    return $value unless defined $value;

    croak "the 'sops' section's '$field' is " . _shape_of($value) . ", and a "
        . "boolean is what belongs there. sops refuses the same document with "
        . "\"'$field' expected type 'bool', got unconvertible type\", exit 1."
        if _is_unconvertible($value);

    # A real boolean passes through, and so does a number: Go asks `!= 0` of
    # one, which is Perl's own truth for it.
    return $value unless _is_text($value);

    # mapstructure maps the empty string to the zero value before ParseBool
    # ever sees it, so `mac_only_encrypted: ""` is false and not an error.
    return JSON->false unless length $value;

    croak "the 'sops' section's '$field' is '$value', which sops cannot read "
        . "as a boolean. It decodes that section weakly, through "
        . "strconv.ParseBool -- 1, t, T, TRUE, true, True, 0, f, F, FALSE, "
        . "false, False, and the empty string as false -- and refuses "
        . "anything else with \"cannot parse value as 'bool'\", exit 1. Note "
        . "that yes, no, on and off are not in that set."
        unless exists $PARSE_BOOL{$value};

    # A JSON::PP::Boolean and not 1/0, so that every emitter writes `true` or
    # `false` rather than degrading it to an int on the next write.
    return $PARSE_BOOL{$value} ? JSON->true : JSON->false;
}

# Go's RFC3339 grammar, as the layout `2006-01-02T15:04:05Z07:00` and Go's
# fallback parser accept it. Deliberately lexical and deliberately without the
# range checks: Go applies those AFTER lexing, so a month of 13 or an offset
# hour of 25 only ever appears in a document sops refuses at exit 1, where the
# AAD we would derive is unobservable. What the corners look like is measured
# in docs/adr/0044 -- a one-digit HOUR is accepted where a one-digit month is
# not, the fraction may be introduced by a comma, and `T` and `Z` are
# case-sensitive.
my $RFC3339 = qr{
    \A
    ( [0-9]{4} ) - ( [0-9]{2} ) - ( [0-9]{2} )   # year, month, day
    T
    ( [0-9]{1,2} ) : ( [0-9]{2} ) : ( [0-9]{2} ) # hour (one digit or two), minute, second
    (?: [.,] [0-9]+ )?                           # fractional seconds, dropped
    (?: Z | ( [+-] ) ( [0-9]{2} ) : ( [0-9]{2} ) )
    \z
}x;

# `time.Parse(time.RFC3339, $text).Format(time.RFC3339)` -- the value sops
# hands to the MAC as its AAD, and writes back into the document. Returns
# undef exactly where the text does not parse, which is where from_hash keeps
# the document's own bytes.
#
# The round trip is purely lexical because the location Go builds is a fixed
# zone carrying the offset it just read: the wall-clock fields it formats back
# are the ones it parsed, so nothing is converted and no calendar is involved.
# The zone is the one part that IS recomputed, from the TOTAL offset -- +00:60
# comes back out as +01:00 -- and it is written `Z` whenever that total is
# zero, whichever sign the document spelled it with. See docs/adr/0044.
sub _go_rfc3339_form {
    my ($text) = @_;

    my ($year, $month, $day, $hour, $minute, $second, $sign, $zone_hour,
        $zone_minute) = $text =~ $RFC3339
        or return undef;

    my $zone = 'Z';
    if (defined $sign) {
        my $offset = $zone_hour * 60 + $zone_minute;
        $zone = sprintf '%s%02d:%02d', $sign, int($offset / 60), $offset % 60
            if $offset;
    }

    return sprintf '%s-%s-%sT%02d:%s:%s%s',
        $year, $month, $day, $hour, $minute, $second, $zone;
}

# `lastmodified` is a Go string where mapstructure decodes it and a
# `time.Time` everywhere after that, and the AAD of the metadata MAC is taken
# from the second one. A document is therefore free to spell the instant in
# any RFC3339 form -- sops reads it and authenticates the MAC with its own
# rendering -- so the value this class holds has to be that rendering rather
# than the document's text. Measured 45 spellings deep in docs/adr/0044, which
# also records why an unparseable one is passed through instead of refused.
sub _decode_lastmodified {
    my ($value) = @_;

    return $value unless defined $value;
    return $value unless _is_text($value);

    return _go_rfc3339_form($value) // $value;
}

sub _decode_int_field {
    my ($field, $value) = @_;

    return $value unless defined $value;

    croak "the 'sops' section's '$field' is " . _shape_of($value) . ", and an "
        . "integer is what belongs there. sops refuses the same document with "
        . "\"'$field' expected type 'int', got unconvertible type\", exit 1."
        if _is_unconvertible($value);

    return $value unless _is_text($value);

    # Same rule as above, one type over: the empty string is the zero value.
    return 0 unless length $value;

    my $number = _go_parse_int($value);

    croak "the 'sops' section's '$field' is '$value', which sops cannot read "
        . "as an integer. It decodes that section weakly, through "
        . "strconv.ParseInt(s, 0, 64): the spelling picks the base (0x hex, "
        . "0b binary, 0o or a bare leading zero octal, otherwise decimal), "
        . "underscores may separate digits, and the value has to fit Go's "
        . "int64. Anything else is refused with \"cannot parse value as "
        . "'int'\", exit 1."
        unless defined $number;

    return $number;
}

# strconv.ParseInt($text, 0, 64) -- the call mapstructure makes for an int
# field. Returns undef exactly where Go returns an error. Measured row for row
# against sops 3.13.3 (t/55): "010" is 8 and not 10, "0x10" is 16, "1_000" is
# 1000, and " 2", "2 ", "08", "1__0" and 2**63 are all refused.
sub _go_parse_int {
    my ($text) = @_;

    return undef unless _underscores_ok($text);

    my $rest     = $text;
    my $negative = ($rest =~ s/\A([+-])//) && $1 eq '-';

    # ParseUint's own emptiness check, which is why a bare sign is an error.
    return undef unless length $rest;

    # The base prefix. Go tests len(s) >= 3 here, so `0x` on its own is not a
    # prefix at all -- it falls through to the bare-leading-zero octal and
    # then fails on the digit `x`.
    my $base = 10;
    if (length($rest) >= 3 && $rest =~ /\A0([bBoOxX])/) {
        my $marker = lc $1;
        $base = $marker eq 'b' ? 2 : $marker eq 'o' ? 8 : 16;
        $rest = substr $rest, 2;
    }
    elsif ($rest =~ /\A0/) {
        $base = 8;
        $rest = substr $rest, 1;
    }

    $rest =~ tr/_//d;

    # Only the bare-leading-zero branch can empty $rest, and there Go's digit
    # loop runs zero times over a zero accumulator: "0" and "-0" are both 0.
    return 0 unless length $rest;

    my %DIGITS = (
        2  => qr/\A[01]+\z/,
        8  => qr/\A[0-7]+\z/,
        10 => qr/\A[0-9]+\z/,
        16 => qr/\A[0-9a-fA-F]+\z/,
    );
    return undef unless $rest =~ $DIGITS{$base};

    # Past a UV both of these hand back a double, which is far outside the
    # window and so refused below -- the rounding cannot pull a too-large
    # magnitude back inside it.
    my $magnitude = do {
        no warnings qw( portable overflow );
        $base == 10 ? 0 + $rest
      : $base == 16 ? oct("0x$rest")
      : $base == 2  ? oct("0b$rest")
      :               oct("0$rest");
    };

    # int64 reaches one further down than up, so a negative magnitude fits
    # exactly when magnitude-1 fits as a positive one. Asked of
    # File::SOPS::Encrypted rather than spelled here, because two copies of
    # that boundary is this distribution's signature defect.
    return undef unless File::SOPS::Encrypted->integer_fits_int64(
        $negative ? $magnitude - 1 : $magnitude);

    # Built from the magnitude's own decimal spelling, so that int64's floor
    # survives: negating a Perl UV of 2**63 produces a double, while numifying
    # '-9223372036854775808' produces the integer.
    return $negative ? 0 + ('-' . $magnitude) : $magnitude;
}

# A port of Go's strconv.underscoreOK, which is where ParseInt's underscore
# rule lives: an underscore may appear only between digits, or between a base
# prefix and the first digit.
sub _underscores_ok {
    my ($text) = @_;

    my $s = $text;
    $s =~ s/\A[+-]//;

    # '^' before the number, '0' after a digit or a base prefix, '_' after an
    # underscore, '!' after anything else.
    my $saw = '^';
    my $i   = 0;
    my $hex = 0;

    if (length($s) >= 2 && $s =~ /\A0([bBoOxX])/) {
        $i   = 2;
        $saw = '0';
        $hex = lc($1) eq 'x';
    }

    for (; $i < length $s; $i++) {
        my $c = substr $s, $i, 1;

        if ($c =~ /\A[0-9]\z/ || ($hex && $c =~ /\A[a-fA-F]\z/)) {
            $saw = '0';
            next;
        }

        if ($c eq '_') {
            return 0 unless $saw eq '0';
            $saw = '_';
            next;
        }

        return 0 if $saw eq '_';
        $saw = '!';
    }

    return $saw eq '_' ? 0 : 1;
}

sub from_hash {
    my ($class, $hash) = @_;

    # Returning undef here is how a document lost a key. Both format handlers
    # call this as from_hash(delete $data->{sops}) once they have seen the key
    # EXIST, so undef meant "there was a top-level sops entry, it was not a
    # mapping, and it has already been removed from the tree" -- and every
    # caller reads undef as "this document has no metadata". File::SOPS::encrypt
    # then wrote a document without the entry, over the original if the caller
    # had asked for that. `sops: mine` in a plaintext file was silently deleted.
    #
    # sops refuses such a document from both directions, and does not care what
    # the entry holds: `sops -e` stops with exit code 203 on the same
    # reserved-key message it gives an already-encrypted file, whether the entry
    # is a scalar, a list, null or an empty mapping; `sops -d` and `sops rotate`
    # stop with "Found sops entry that is not a mapping". Measured on 3.13.3.
    #
    # The check cannot live at the call sites' `delete`, which collapses "no
    # entry" and "entry holding null" into the same undef, and sops refuses the
    # second. So an undef arriving here is a caller that has already established
    # the key exists -- there is no reason to ask this method about a section
    # that is not there, and no caller in this distribution does.
    croak "the top-level 'sops' entry is " . _shape_of($hash) . ", not a "
        . "mapping. That name is reserved for the SOPS metadata section, so a "
        . "document using it for anything else can neither be read (there is "
        . "no metadata to read) nor encrypted (the entry is where the metadata "
        . "goes). If this is plaintext that happens to use the name, rename the "
        . "entry. sops refuses the same document: 'Found sops entry that is not "
        . "a mapping' when reading, exit code 203 when encrypting."
        unless ref $hash eq 'HASH';

    # Before anything is built out of the section: a reference where sops
    # wants a string. It refuses such a document at exit 1 without opening it,
    # and here the reference would reach an encryption rule and be used as the
    # suffix or the pattern.
    _assert_string_field($_, $hash->{$_})
        for grep { exists $hash->{$_} } @STRING_FIELDS;

    my %extra = map  { $_ => $hash->{$_} }
                grep { !$MODELLED_FIELD{$_} } keys %$hash;

    # The one unmodelled field with a type of its own. It stays in `extra`
    # because this class does not model what it MEANS -- only what it is.
    $extra{shamir_threshold}
        = _decode_int_field('shamir_threshold', $extra{shamir_threshold})
        if exists $extra{shamir_threshold};

    return $class->new(
        extra              => \%extra,
        age                => $hash->{age}                // [],
        pgp                => $hash->{pgp}                // [],
        kms                => $hash->{kms}                // [],
        gcp_kms            => $hash->{gcp_kms}            // [],
        azure_kv           => $hash->{azure_kv}           // [],
        hc_vault           => $hash->{hc_vault}           // [],
        mac                => $hash->{mac},
        lastmodified       => _decode_lastmodified($hash->{lastmodified}),
        version            => $hash->{version}            // $SOPS_VERSION,
        unencrypted_suffix => $hash->{unencrypted_suffix},
        encrypted_suffix   => $hash->{encrypted_suffix},
        unencrypted_regex  => $hash->{unencrypted_regex},
        encrypted_regex    => $hash->{encrypted_regex},
        mac_only_encrypted =>
            _decode_bool_field('mac_only_encrypted', $hash->{mac_only_encrypted}),
    );
}


sub to_hash {
    my ($self) = @_;

    # Unmodelled fields go down first so that a modelled one always wins: the
    # attributes are the truth about this document, extra is only what nobody
    # here has an opinion about.
    my $hash = {
        %{ $self->extra },
        kms      => $self->kms,
        gcp_kms  => $self->gcp_kms,
        azure_kv => $self->azure_kv,
        hc_vault => $self->hc_vault,
        age      => $self->age,
        pgp      => $self->pgp,
    };

    $hash->{lastmodified} = $self->lastmodified if defined $self->lastmodified;
    $hash->{mac}          = $self->mac          if defined $self->mac;
    $hash->{version}      = $self->version      if defined $self->version;

    $hash->{unencrypted_suffix} = $self->unencrypted_suffix
        if defined $self->unencrypted_suffix;
    $hash->{encrypted_suffix} = $self->encrypted_suffix
        if defined $self->encrypted_suffix;
    $hash->{unencrypted_regex} = $self->unencrypted_regex
        if defined $self->unencrypted_regex;
    $hash->{encrypted_regex} = $self->encrypted_regex
        if defined $self->encrypted_regex;
    # sops omits the key entirely when the option is off, so a false must not
    # be written back as `mac_only_encrypted: false`.
    $hash->{mac_only_encrypted} = JSON->true if $self->mac_only_encrypted;

    return $hash;
}


sub update_lastmodified {
    my ($self) = @_;
    $self->lastmodified(strftime('%Y-%m-%dT%H:%M:%SZ', gmtime));
    return $self;
}


sub add_age_recipient {
    my ($self, %args) = @_;
    my $recipient = $args{recipient} // croak "recipient required";
    my $enc       = $args{enc}       // croak "enc required";

    push @{$self->age}, {
        recipient => $recipient,
        enc       => $enc,
    };

    return $self;
}


sub get_age_encrypted_keys {
    my ($self) = @_;
    return @{$self->age};
}


###############################################################################
# The two regex rules, and the dialect they are matched in
###############################################################################

# unencrypted_regex and encrypted_regex are matched HERE with Perl and in sops
# with Go's RE2, and those are not the same dialect. Two consequences, both
# measured against sops 3.13.3 -- docs/adr/0048, k161.
#
# 1. RE2's \w \W \d \D \s \S \b \B and its POSIX classes are ASCII-only for
#    every subject. Perl's are Unicode-aware for any string carrying the UTF-8
#    flag -- which is every non-ASCII key our parsers produce. So an
#    `unencrypted_regex: ^\w+$` is a rule under which sops ENCRYPTS `café`,
#    `密`, `n٣` and `a<NBSP>b` and this library left them BARE. That is why the
#    patterns are compiled /a below: it is RE2's answer for these classes, and
#    it makes the answer independent of a flag ADR 0003 forbids reading
#    anywhere else in this distribution.
#
# 2. A pattern RE2 cannot COMPILE is not reported by sops. It matches with the
#    error discarded, so the rule silently matches NOTHING: measured,
#    `--encrypted-regex '(?=f)foo'` writes every value of the document in
#    PLAINTEXT at exit 0, and `--unencrypted-regex '(?=f)foo'` encrypts every
#    value. Neither is a classification that can be reproduced quietly, so the
#    constructs RE2 rejects are refused here instead.

# The escapes RE2 accepts, meaning by them what Perl means once the pattern is
# compiled /a. Every OTHER alphanumeric escape is refused, because RE2 either
# rejects it -- \Z \K \G \R \h \H \V \N \X \C \c \e \o \g \k \u \l \U \L are
# all "invalid escape sequence", measured through a .sops.yaml path_regex,
# which is the one place sops reports a compile error -- or reads it as
# something else:
#
#   \v   the vertical TAB to Go, the vertical-whitespace CLASS to Perl.
#   \Q   a quoted literal run to RE2, and NOTHING to Perl: \Q and \E are
#        double-quotish escapes, processed when a pattern is written out in
#        source and not by the regex compiler, so a pattern arriving in a
#        variable -- which is every pattern here -- keeps them as the literal
#        letters Q and E. Measured: `\Qa.b\E` selects the key `a.b` at sops
#        and the key `Qa.bE` here.
#
# \0 covers the octal escapes (\0, \00, \017); a leading 1..9 is a
# backreference here and an error there.
my %RE2_ESCAPE = map { $_ => 1 } qw(
    A B D P S W
    a b d f n p r s t w x z
    0
);

# The regex flags RE2 has, plus the `-` that turns one off. Perl's a, d, l, u,
# n, p and x are all "invalid or unsupported Perl syntax" there; U is the
# reverse case -- RE2 has it and Perl does not -- and fails to compile here,
# which is _rule_qr's other croak.
my %RE2_FLAG = map { $_ => 1 } qw( i m s U - );

# The escapes both dialects accept and do not mean the same thing by. These
# are the ones a whitelist cannot catch: nothing fails, the rule just selects
# different keys on the two sides.
my %RE2_MEANS_OTHER = (
    v => 'the vertical TAB to Go RE2 and the vertical-whitespace CLASS to '
       . 'Perl',
    Q => 'a quoted literal run to Go RE2 and nothing at all to Perl',
    E => 'the end of a quoted literal run to Go RE2 and nothing at all to '
       . 'Perl',
);

# What in this pattern, if any, the two dialects do not agree on. Returns the
# empty list when they do, and otherwise the construct and which KIND of
# disagreement it is:
#
#   'unsupported' -- RE2 cannot compile it, so the rule matches nothing there
#   'different'   -- both compile it and read it as different things
#
# The check is deliberately whitelist-shaped for escapes and for (?...) groups:
# a construct nobody here has measured is refused rather than assumed
# harmless, because the harm runs one way (a key sops encrypts, left bare).
sub _re2_divergent_construct {
    my ($pattern) = @_;
    return () unless defined $pattern;

    my @c         = split //, $pattern;
    my $i         = 0;
    my $in_class  = 0;
    my $class_pos = 0;   # how far into the current [...] we are; a ] at 0 is
                         # the literal character, in both dialects
    my $quantified = 0;  # the token just read was a quantifier

    while ($i < @c) {
        my $ch = $c[$i];

        if ($ch eq '\\') {
            my $next = $c[$i+1];
            return ('a trailing backslash', 'unsupported') unless defined $next;

            if ($next =~ /\A[0-9A-Za-z]\z/) {
                return ('a backreference (\\1, \\2, ...)', 'unsupported')
                    if $next =~ /\A[1-9]\z/;
                return ("the escape \\$next, which is $RE2_MEANS_OTHER{$next}",
                        'different')
                    if $RE2_MEANS_OTHER{$next};
                return ("the escape \\$next", 'unsupported')
                    unless $RE2_ESCAPE{$next};

                # Outside a character class \b is the word boundary both
                # dialects have; inside one it is BACKSPACE, which RE2 rejects.
                return ('the escape \\b inside a character class', 'unsupported')
                    if $next eq 'b' && $in_class;
            }

            $i += 2;
            $class_pos++ if $in_class;
            $quantified = 0;
            next;
        }

        if ($in_class) {
            if ($ch eq ']' && $class_pos > 0) {
                $in_class   = 0;
                $quantified = 0;
                $i++;
                next;
            }

            # [:alpha:] and [:^alpha:] carry a ] of their own.
            if ($ch eq '[' && defined $c[$i+1] && $c[$i+1] eq ':') {
                my $end = index($pattern, ':]', $i + 2);
                if ($end >= 0) {
                    $class_pos += $end + 2 - $i;
                    $i = $end + 2;
                    next;
                }
            }

            $class_pos++;
            $i++;
            next;
        }

        if ($ch eq '[') {
            $in_class   = 1;
            $class_pos  = 0;
            $quantified = 0;
            $i++;
            $i++ if defined $c[$i] && $c[$i] eq '^';   # [^...] is still at 0
            next;
        }

        if ($ch eq '(') {
            $quantified = 0;
            if (defined $c[$i+1] && $c[$i+1] eq '?') {
                my @divergent = _re2_divergent_group(substr($pattern, $i));
                return @divergent if @divergent;
            }
            $i++;
            next;
        }

        if ($ch eq '*' || $ch eq '+' || $ch eq '?') {
            return ('a possessive quantifier (*+, ++, ?+ or {n,m}+)',
                    'unsupported')
                if $ch eq '+' && $quantified;
            # A ? after a quantifier is the lazy form, which both dialects
            # have, and it ends the quantifier rather than extending it.
            $quantified = ($ch eq '?' && $quantified) ? 0 : 1;
            $i++;
            next;
        }

        if ($ch eq '{') {
            # A brace run that is a repetition; anything else is a literal
            # brace in both dialects.
            if (substr($pattern, $i) =~ /\A(\{[0-9]+(?:,[0-9]*)?\})/) {
                $i += length $1;
                $quantified = 1;
                next;
            }
            $quantified = 0;
            $i++;
            next;
        }

        $quantified = 0;
        $i++;
    }

    return ();
}

# What follows a `(?`, given the rest of the pattern from the `(`.
sub _re2_divergent_group {
    my ($rest) = @_;

    return () if $rest =~ /\A\(\?:/;              # (?:...)   non-capturing
    return () if $rest =~ /\A\(\?P</;             # (?P<n>..) named
    return ('a lookbehind ((?<=...) or (?<!...))', 'unsupported')
        if $rest =~ /\A\(\?<[=!]/;
    return () if $rest =~ /\A\(\?</;              # (?<n>...) named, Go 1.22+
    return ('a lookahead ((?=...) or (?!...))', 'unsupported')
        if $rest =~ /\A\(\?[=!]/;
    return ('an atomic group ((?>...))', 'unsupported')
        if $rest =~ /\A\(\?>/;
    return ('an inline comment ((?#...))', 'unsupported')
        if $rest =~ /\A\(\?#/;
    return ('a branch reset ((?|...))', 'unsupported')
        if $rest =~ /\A\(\?\|/;
    return ('embedded code ((?{...}))', 'unsupported')
        if $rest =~ /\A\(\?\??\{/;
    return ('a backreference ((?P=name))', 'unsupported')
        if $rest =~ /\A\(\?P=/;
    return ('a subpattern call or recursion', 'unsupported')
        if $rest =~ /\A\(\?(?:R\)|[0-9]|[&+]|-[0-9]|P>)/;
    return ("a named group in Perl's (?'name'...) spelling", 'unsupported')
        if $rest =~ /\A\(\?'/;
    return ('a flag reset ((?^...))', 'unsupported')
        if $rest =~ /\A\(\?\^/;

    if ($rest =~ /\A\(\?([a-zA-Z-]*)[:)]/) {
        my ($bad) = grep { !$RE2_FLAG{$_} } split //, $1;
        return defined $bad ? ("the regex flag (?$bad)", 'unsupported') : ();
    }

    return ('a (?...) group RE2 does not have', 'unsupported');
}

{
    # Everything in this block is compiled with ASCII-only character classes,
    # which is what RE2 gives the pattern on the other side. It is deliberately
    # /a and not /aa: measured, Go folds `k` to U+212A KELVIN SIGN and `s` to
    # U+017F LONG S under (?i), which /a keeps and /aa would break. What /a
    # does not reach is Perl's FULL case folding -- `(?i)^ss$` matches U+00DF
    # here and not there -- which is recorded as a limit in docs/adr/0048.
    use re '/a';

    # sops's own answer for a pattern RE2 cannot compile: it discards the
    # compile error, so the rule matches NOTHING. Compiled once, in here with
    # the real patterns, because that is the answer the read path uses.
    my $MATCHES_NOTHING = qr/(?!)/;

    # The one place a rule pattern is looked at. Returns the matcher to use,
    # the KIND of disagreement if there is one, and the refusal that goes with
    # it -- because the two paths need different halves of that answer:
    #
    #   'unsupported'  RE2 cannot compile it, so sops matches nothing. That is
    #                  reproducible, and $MATCHES_NOTHING reproduces it, so the
    #                  READ path is given a matcher and no refusal is raised.
    #   'different'    both dialects compile it and read it apart (\v, \Q, \E).
    #   'perl'         RE2 compiles it and we cannot ((?U) is the only measured
    #                  one; \C, \g and \k are rejected by BOTH).
    #
    # The last two have no answer to reproduce, so they are refused wherever
    # they are met. The write path refuses all three. See docs/adr/0051.
    sub _rule_verdict {
        my ($field, $pattern) = @_;

        my $shown = length($pattern) > 60
            ? substr($pattern, 0, 57) . '...'
            : $pattern;

        my ($construct, $kind) = _re2_divergent_construct($pattern);
        return (
            $kind eq 'unsupported' ? $MATCHES_NOTHING : undef,
            $kind,
            "Cannot use '$shown' as the $field: it uses $construct, "
            . ($kind eq 'unsupported'
                ? "which Go RE2 does not support. sops does not report that "
                . "-- it discards the compile error, so the rule silently "
                . "matches NOTHING. Measured on sops 3.13.3: an "
                . "encrypted_regex it cannot compile leaves every value of "
                . "the document in PLAINTEXT at exit 0, and an "
                . "unencrypted_regex it cannot compile encrypts every value."
                : "which both dialects accept and read DIFFERENTLY, so the "
                . "same rule selects different keys in the two "
                . "implementations.")
            . " Rewrite the pattern in constructs both dialects agree on. "
            . "See docs/adr/0048."
        ) if defined $construct;

        my $qr = eval { qr/$pattern/ };
        return ($qr, undef, undef) if defined $qr;

        return (undef, 'perl',
            "Cannot use '$shown' as the $field: it is not a valid Perl "
            . "regular expression (" . _regex_reason($@) . "). RE2 and Perl "
            . "do not accept the same patterns in either direction -- '(?U)' "
            . "compiles there and not here -- so a rule sops took can still "
            . "be one this side cannot match with. See docs/adr/0048.");
    }

    sub _rule_qr {
        my ($field, $pattern) = @_;

        my ($qr, undef, $refusal) = _rule_verdict($field, $pattern);

        # A pattern RE2 cannot compile arrives here WITH a matcher -- the one
        # that matches nothing, which is what sops matches with. Every other
        # refusal is one this side cannot reproduce, and it stands wherever
        # the rule is asked, read path included. docs/adr/0051.
        croak $refusal unless defined $qr;

        return $qr;
    }
}

sub _regex_reason {
    my ($error) = @_;
    my $reason = defined $error ? "$error" : '';
    $reason =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//;
    $reason =~ s/\s+/ /g;
    $reason =~ s/\A\s+|\s+\z//g;
    return length $reason ? $reason : 'no reason given';
}

# Private, and it lives here rather than with the modelled fields because it
# is not one: nothing constructs it, to_hash never sees it, and its only
# reader is the method below.
has _rule_matchers => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { {} },
);

# One compiled matcher per rule pattern. Keyed by the pattern itself, so a
# caller changing the attribute -- both are rw -- gets a matcher for what the
# attribute now holds rather than for what it held first.
sub _rule_matcher {
    my ($self, $field) = @_;

    my $pattern = $self->$field;
    return $self->_rule_matchers->{$field}{$pattern}
        ||= _rule_qr($field, $pattern);
}

sub should_encrypt_key {
    my ($self, $key) = @_;

    if (defined $self->unencrypted_suffix) {
        return 0 if $key =~ /\Q$self->{unencrypted_suffix}\E$/;
    }

    if (defined $self->encrypted_suffix) {
        return 1 if $key =~ /\Q$self->{encrypted_suffix}\E$/;
        return 0;
    }

    if (defined $self->unencrypted_regex) {
        return 0 if $key =~ $self->_rule_matcher('unencrypted_regex');
    }

    if (defined $self->encrypted_regex) {
        return 1 if $key =~ $self->_rule_matcher('encrypted_regex');
        return 0;
    }

    return 1;
}


sub should_encrypt_path {
    my ($self, $path) = @_;
    $path //= [];

    my $encrypted = 1;

    # Each rule attribute is read once. unencrypted_suffix is lazy, so it must
    # go through its accessor to fire the builder; the other three are plain rw
    # fields whose accessor is just a hash read, so reading them directly --
    # the same way should_encrypt_key and the grep below already read these
    # fields -- drops three sub calls from the common single-rule path without
    # changing what is read. The two suffix rules match through a qr cached by
    # value in _rule_matchers -- the same store, keying and rw-invalidation
    # _rule_matcher uses for the regex rules, so a changed attribute gets a
    # fresh matcher -- rather than recompiling qr/\Q$suffix\E$/ on every call;
    # the suffix and regex field names are disjoint, so they share the store
    # without colliding. Order and later-overrides-earlier are unchanged.
    my $us = $self->unencrypted_suffix;
    if (defined $us && length $us) {
        my $qr = $self->{_rule_matchers}{unencrypted_suffix}{$us}
            ||= qr/\Q$us\E$/;
        $encrypted = 0 if grep { $_ =~ $qr } @$path;
    }

    my $es = $self->{encrypted_suffix};
    if (defined $es && length $es) {
        my $qr = $self->{_rule_matchers}{encrypted_suffix}{$es}
            ||= qr/\Q$es\E$/;
        $encrypted = (grep { $_ =~ $qr } @$path) ? 1 : 0;
    }

    my $ur = $self->{unencrypted_regex};
    if (defined $ur && length $ur) {
        my $qr = $self->_rule_matcher('unencrypted_regex');
        $encrypted = 0 if grep { $_ =~ $qr } @$path;
    }

    my $er = $self->{encrypted_regex};
    if (defined $er && length $er) {
        my $qr = $self->_rule_matcher('encrypted_regex');
        $encrypted = (grep { $_ =~ $qr } @$path) ? 1 : 0;
    }

    return $encrypted;
}


sub assert_rule_regexes_agree {
    my ($self) = @_;

    for my $field (qw( unencrypted_regex encrypted_regex )) {
        my $pattern = $self->$field;
        next unless defined $pattern && length $pattern;

        my (undef, undef, $refusal) = _rule_verdict($field, $pattern);
        croak $refusal if defined $refusal;
    }

    return 1;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::SOPS::Metadata - SOPS metadata section handling

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use File::SOPS::Metadata;

    # Create new metadata
    my $meta = File::SOPS::Metadata->new(
        unencrypted_suffix => '_unencrypted',
    );

    # Add age recipient
    $meta->add_age_recipient(
        recipient => 'age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p',
        enc       => '-----BEGIN AGE ENCRYPTED FILE-----...',
    );

    # Update timestamp
    $meta->update_lastmodified;

    # Set MAC
    $meta->mac($mac_string);

    # Convert to hash for serialization
    my $hash = $meta->to_hash;

    # Parse from existing hash
    my $meta = File::SOPS::Metadata->from_hash($sops_section);

=head1 DESCRIPTION

File::SOPS::Metadata manages the C<sops> metadata section of encrypted files.
This section contains:

=over 4

=item * Encrypted data keys for each recipient/backend

=item * MAC for tamper detection

=item * Timestamp of last modification

=item * Rules for which keys should be encrypted

=item * SOPS version information

=back

=head2 age

ArrayRef of age-encrypted data keys. Each entry is a HashRef with:

    {
        recipient => 'age1...',
        enc       => '-----BEGIN AGE ENCRYPTED FILE-----...'
    }

Defaults to C<[]>.

=head2 pgp

ArrayRef of PGP-encrypted data keys. Not yet implemented. Defaults to C<[]>.

=head2 kms

ArrayRef of AWS KMS-encrypted data keys. Not yet implemented. Defaults to C<[]>.

=head2 gcp_kms

ArrayRef of Google Cloud KMS-encrypted data keys. Not yet implemented. Defaults to C<[]>.

=head2 azure_kv

ArrayRef of Azure Key Vault-encrypted data keys. Not yet implemented. Defaults to C<[]>.

=head2 hc_vault

ArrayRef of HashiCorp Vault-encrypted data keys. Not yet implemented. Defaults to C<[]>.

=head2 mac

Message Authentication Code over the entire encrypted data structure.

Stored as an encrypted value string: C<ENC[AES256_GCM,data:...,iv:...,tag:...,type:str]>

=head2 lastmodified

RFC 3339 timestamp of last modification, and B<the AAD the metadata MAC is
authenticated with>. Example: C<2026-01-10T12:00:00Z>.

Read out of a document by L</from_hash>, this holds Go's own rendering of the
instant the document spells and not the document's text -- because that
rendering is what sops feeds the MAC. A document saying
C<2026-01-10T12:00:00+00:00>, C<2026-01-10T12:00:00.123Z> or
C<2026-01-10T2:00:00Z> arrives here as the value above, the one that
authenticates. See L</from_hash> for the rule and docs/adr/0044 for the
measurement.

L</update_lastmodified> writes that rendering directly, and it is the only
thing every document this library produces ever carries.

=head2 version

SOPS version string. Defaults to C<3.7.3> for compatibility with the Go implementation.

B<sops semver-parses this field and refuses a document it cannot parse>, on
every read path -- C<3>, C<3.13>, C<true>, C<""> and an B<absent> version are
each exit 1. L</from_hash> accepts all of them and defaults an absent one to
C<3.7.3>, which is a deliberate divergence in the permissive direction:
nothing here reads the field, and no value read out of a document is ever
written back into one, because L</policy_args> does not carry it across a
re-encryption -- the divergence from sops here is that sops preserves the
document's own version verbatim on a rotate while we stamp C<3.7.3> instead.
See L</policy_args>, F<docs/adr/0058> (k151) and L</from_hash> for the
measured table and why a partial check would be worse than none.

=head2 unencrypted_suffix

Keys ending with this suffix are not encrypted (but are included in MAC).

Example: C<api_key_unencrypted> would not be encrypted.

Defaults to C<_unencrypted>, but B<only when no other encryption rule is
set> -- see L</Encryption rules are mutually exclusive>. Constructed with any
of L</encrypted_suffix>, L</unencrypted_regex> or L</encrypted_regex>, it
defaults to C<undef> instead.

Passing C<< unencrypted_suffix => undef >> explicitly means B<no rule at
all>, which is a different thing from leaving it out: with no rule every leaf
is encrypted, including one whose key ends in C<_unencrypted>. That is what
L</from_hash> does for a document that carries no rule field, and it is what
the reference implementation does with such a document.

=head2 encrypted_suffix

If set, a value is encrypted only when some component of its path ends with
this suffix -- see L</should_encrypt_path>.

Defaults to C<undef>. Mutually exclusive with the other rules, see
L</Encryption rules are mutually exclusive>.

=head2 unencrypted_regex

Regular expression: a value is not encrypted when some component of its path
matches it -- see L</should_encrypt_path>.

Defaults to C<undef>. Mutually exclusive with the other rules, see
L</Encryption rules are mutually exclusive>. Matched in Go RE2's dialect and
not in Perl's; a pattern RE2 cannot compile matches nothing, as it does at
sops, and one the two dialects read differently is refused rather than matched
-- see L</The regex rules are matched in RE2's dialect>.

=head2 encrypted_regex

Regular expression: a value is encrypted only when some component of its path
matches it -- see L</should_encrypt_path>.

Defaults to C<undef>. Mutually exclusive with the other rules, see
L</Encryption rules are mutually exclusive>. Matched in Go RE2's dialect and
not in Perl's; a pattern RE2 cannot compile matches nothing, as it does at
sops, and one the two dialects read differently is refused rather than matched
-- see L</The regex rules are matched in RE2's dialect>.

=head2 The regex rules are matched in RE2's dialect

B<New in 0.003, and it changes which keys get encrypted.> L</unencrypted_regex>
and L</encrypted_regex> are matched here with Perl and in sops with Go's RE2,
and those are not the same dialect. Two things follow.

B<The character classes are ASCII-only.> RE2's C<\w>, C<\W>, C<\d>, C<\D>,
C<\s>, C<\S>, C<\b>, C<\B> and its POSIX classes reach ASCII and nothing
else, for every subject. Perl's are Unicode-aware for any string carrying the
UTF-8 flag -- which is every non-ASCII key our parsers produce. Measured against
sops 3.13.3 with one ordinary F<.sops.yaml>, one C<sops -e> and no hand editing
anywhere:

    unencrypted_regex: '^\w+$'      key: cafE<eacute>

    sops                 encrypts the value
    File::SOPS (0.002)   left it READABLE

Twenty-nine such disagreements were measured over the class escapes, the
thirteen POSIX classes and both rule fields; twenty-two of them left a secret
readable that sops encrypts. The patterns are therefore compiled C</a>, which
is RE2's answer for these classes -- and, not incidentally, it takes the UTF-8
flag out of the answer, which ADR 0003 forbids reading everywhere else in this
distribution. It is C</a> and not C</aa> because RE2's C<(?i)> B<is>
Unicode-aware: Go folds C<k> to U+212A KELVIN SIGN and C<s> to U+017F LATIN
SMALL LETTER LONG S, which C</a> keeps and C</aa> would break.

An ASCII rule over ASCII keys does not move. Measured over the 15_960 decisions
this distribution's own test suite makes -- every rule pattern in it against
every key in it -- eighteen changed, all of them a non-ASCII key under
C<^\w+$>, and none of them an ASCII one.

B<A pattern the two dialects do not agree on is refused for writing.> sops does
not report a pattern RE2 cannot compile: it matches with the compile error
discarded, so the rule silently matches nothing. Measured --
C<< --encrypted-regex '(?=f)foo' >> writes B<every value of the document in
plaintext> at exit 0, under a C<sops> section that makes it look encrypted, and
C<< --unencrypted-regex '(?=f)foo' >> encrypts every value. Neither is a
document this library will produce, so writing under one of these dies:

=over 4

=item * lookahead and lookbehind, C<(?=)>, C<(?!)>, C<< (?<=) >> and C<< (?<!) >>

=item * backreferences, C<\1> and C<< (?P=name) >>

=item * atomic groups C<< (?>...) >> and possessive quantifiers C<*+>, C<++>,
C<?+>, C<{n,m}+>

=item * the escapes RE2 has no rule for: C<\Z>, C<\K>, C<\G>, C<\R>, C<\h>,
C<\H>, C<\V>, C<\N>, C<\X>, C<\C>, C<\c>, C<\e>, C<\o>, C<\g>, C<\k>,
C<\u>, C<\l>, C<\U>, C<\L>, and C<\b> inside a character class

=item * inline comments C<< (?#...) >>, branch resets C<< (?|...) >>, embedded
code, subpattern calls and recursion, the C<< (?'name'...) >> spelling of a
named group, the C<< (?^...) >> flag reset

=item * every regex flag RE2 does not have: C<x>, C<a>, C<d>, C<l>, C<u>, C<n>
and C<p>

=item * C<\v>, C<\Q> and C<\E>, which both dialects take and read
B<differently>: C<\v> is the vertical TAB to Go and the vertical-whitespace
class to Perl, and C<\Q>/C<\E> quote a literal run for RE2 while a Perl
pattern arriving in a variable keeps them as the letters C<Q> and C<E>
(measured: C<\Qa.b\E> selects the key C<a.b> at sops and the key C<Qa.bE>
here)

=back

Everything both dialects have is taken, C<(?i)>, C<(?m)>, C<(?s)>,
C<\p{...}>, C<[[:alpha:]]>, C<[[:^alpha:]]>, C<(?PE<lt>nameE<gt>)>, C<< (?<name>) >>
and the lazy quantifiers included. C<(?U)> is B<not> among them -- RE2 has that
flag and Perl does not, which is the next paragraph but one. The verdicts were read off RE2 itself, not
guessed: a F<.sops.yaml> C<path_regex> is the one place sops reports
I<error parsing regexp> rather than discarding it.

B<Reading such a document is a different question, and it gets a different
answer.> Since 0.003 the rule decides what a leaf B<is> on the way out as well
as on the way in, so this predicate is asked on the read path too. Where RE2
cannot compile the pattern, sops's answer -- the rule matches nothing -- is
reproducible, and it is reproduced: L<File::SOPS/decrypt>, L<File::SOPS/extract>
and L<File::SOPS/decrypt_file> read a document carrying such a rule exactly as
C<sops -d> reads it, at exit 0. What stops is B<writing>:
L<File::SOPS/encrypt>, L<File::SOPS/encrypt_file>,
L<File::SOPS/encrypt_in_place>, L<File::SOPS/rotate> and L<File::SOPS/edit> all
ask L</assert_rule_regexes_agree> once, before any leaf is walked. See
F<docs/adr/0051>.

A pattern B<Perl> cannot compile is refused everywhere, read path included,
with the reason: the dialects disagree in that direction as well, and
C<(?U)fo+> is a pattern sops takes and this side cannot. It is the only such
pattern measured -- C<\C>, C<\g> and C<\k> read like company for it and are
not, because RE2 rejects all three (measured on 3.13.3 through the
C<path_regex> oracle; F<docs/adr/0048> says otherwise and is wrong there).

=head3 Limits

Two measured disagreements survive, both recorded in F<docs/adr/0048>:

=over 4

=item * B<Full case folding.> Perl's C<(?i)> folds U+00DF to C<ss> and RE2's
does not, so C<< unencrypted_regex => '(?i)^ss$' >> leaves a key C<E<szlig>> readable
here and sops encrypts it. Perl has no flag for simple-only folding.

=item * B<C<$> before a trailing newline.> Perl's C<$> is C<< (?=\n?\z) >> and
RE2's is C<\z>, so C<^foo$> matches a key C<"foo\n"> here and not there.
C<\z> is in both dialects and says exactly what RE2's C<$> says.

=back

A C<\p{...}> naming a property Perl has and Go does not -- C<\p{Word}>,
C<\p{Alpha}>, C<\p{IsAlpha}> -- is a third: RE2 rejects it, so sops's rule
matches nothing, and this side cannot enumerate Go's table to tell that apart
from C<\p{Greek}>, which both accept.

A fourth arrived with the read path: a pattern B<neither> dialect can compile,
C<fo(> being the measured one. RE2 rejects it, so sops matches nothing and
reads the document at exit 0; here it reaches the Perl compile, which also
rejects it, and there is nothing to tell that apart from C<(?U)fo+> -- a
pattern RE2 B<does> compile and this side must not guess at. It is refused, so
a document carrying it is one sops reads and this library does not.

=head2 Encryption rules are mutually exclusive

L</unencrypted_suffix>, L</encrypted_suffix>, L</unencrypted_regex> and
L</encrypted_regex> -- together with C<unencrypted_comment_regex> and
C<encrypted_comment_regex>, which this distribution does not implement but
does recognise -- select which values get encrypted, and B<at most one of them
may be set>. Constructing a Metadata with two of them dies:

    Cannot use more than one of unencrypted_suffix, encrypted_suffix, ...
    in the same document (got unencrypted_suffix and encrypted_regex);
    sops refuses such a file outright

That is not a house rule; it is the reference implementation's, which reports
the same conflict and refuses the document before decrypting anything.
Constructing the object is the earliest point at which the conflict can be
seen, so it is where it is reported.

The consequence worth knowing is the one on L</unencrypted_suffix>: its
C<_unencrypted> default has to stand down as soon as any other rule is set,
or every configured document would carry two rules and be unreadable.

=head2 mac_only_encrypted

When true, the MAC covers only the values that are actually encrypted; when
false (the default) it covers every value in the document, encrypted or not.

Both MAC implementations honour this, and a MAC computed with it on additionally
starts from a fixed 32-byte initialization block (C<MACOnlyEncryptedInitialization>
in the Go source), so the two settings can never produce the same digest for the
same document.

C<undef> or false is emitted as no key at all in the C<sops> section, which is
what the Go implementation writes.

B<The constructor takes a Perl boolean; L</from_hash> takes a document's field
and decodes it the way sops does.> The two are deliberately different. A caller
writing C<< mac_only_encrypted => $flag >> means Perl's truth of C<$flag>,
which is the only thing that word can mean in a Perl API. A B<document> saying
C<mac_only_encrypted: "false"> means the boolean false -- measured, in a nested
YAML section as much as in a flat one -- and Perl's C<'false'> is B<true>, so
reading it as Perl would selects the other digest for a file sops reads at exit
0. See L</from_hash> for the accepted set and docs/adr/0042 for the
measurement.

B<What it costs, in YAML:> a leaf the MAC no longer covers is one no reader
verifies, and this distribution and sops do not resolve every YAML spelling the
same way. C<mode_unencrypted: 0755> is the realistic case -- sops reads the
integer B<493>, this module reads 755, and with C<mac_only_encrypted> set
neither the MAC nor C<sops -d> reports anything (measured, sops 3.13.3, exit 0).
The same holds for C<0o10>, C<0x1f>, C<1_000>, C<.inf>, C<Null>, C<TRUE> and a
date that is not exactly RFC3339. Without this option such a leaf is B<refused>
at encrypt time, because the document would fail its own MAC; with it set the
document is written and the divergence is B<warned> about instead, naming the
leaf's key path. See L<File::SOPS::Format::YAML/serialize> for the full rule and
docs/adr/0018 for the measurement.

=head2 extra

HashRef of the fields in a document's C<sops> section that this class does not
model, kept verbatim so that a rewrite does not drop them. Defaults to C<{}>.

The reference implementation knows more metadata fields than this
distribution does -- C<shamir_threshold>, C<key_groups>, and the two
comment-based encryption rules among them -- and it B<preserves the ones it
knows> across a rewrite. Measured against sops 3.13.3: C<sops rotate> on a
document carrying C<shamir_threshold: 2> writes it back out, and drops a field
it does not recognise. Modelling each of those fields here would mean
modelling C<key_groups>, whose semantics this distribution cannot implement,
so instead everything unrecognised is preserved. That is a superset of what Go
keeps, and a safe one: Go ignores a field it does not know, so preserving one
can never make a document unreadable, whereas dropping C<shamir_threshold>
demonstrably changes what sops does with it.

Fields this class does model are never stored here -- L</to_hash> lets the
attributes win -- so C<extra> cannot be used to shadow C<mac> or C<age>.

B<One unmodelled field is decoded on the way in rather than kept verbatim:>
C<shamir_threshold>, the only one of them that is not a string. L</from_hash>
reads it the way sops does and refuses what sops refuses -- see
L</Two fields are decoded weakly, because sops decodes them weakly>. It stays
in C<extra> because this class models what the field B<is>, not what it
B<means>: C<key_groups> is what gives a threshold its meaning, and that is the
field this distribution cannot implement.

The two comment-based encryption rules pass through here as well, and they are
B<checked> rather than decoded: they are strings to sops, so a list or a map in
one of them is refused with everything else in
L</The string fields are checked for their shape, and only for that>. A field
neither implementation knows keeps whatever it holds, C<key_groups>' list
included.

=head2 rule_value

    my $suffix = $meta->rule_value('unencrypted_suffix');
    my $regex  = $meta->rule_value('encrypted_comment_regex');

Returns the value of an encryption rule by name, or C<undef> if the document
does not carry it.

The point of going through a name rather than an accessor is the rules this
class does not model: C<unencrypted_comment_regex> and
C<encrypted_comment_regex> have no attribute, but a caller deciding whether it
can honour a document's rule has to be able to ask about them. The names worth
asking about are in C<@File::SOPS::Metadata::ENCRYPTION_RULES> and
C<@File::SOPS::Metadata::UNSUPPORTED_ENCRYPTION_RULES>.

=head2 policy_args

    my $fresh = File::SOPS::Metadata->new($meta->policy_args);

Returns the constructor arguments that describe B<how> a document is
encrypted, so they can be carried onto a new metadata object: the four
encryption rules and L</mac_only_encrypted>.

Deliberately B<not> included is everything that describes B<what> encrypted
this particular document, because none of it survives a re-encryption: the
per-backend key material (L</age>, L</pgp>, L</kms> and friends) wraps a data
key that is about to be replaced, L</mac> authenticates values that are about
to be rewritten, and L</lastmodified> is the AAD of that MAC.

B<L</version> is also deliberately not carried>, and this is a divergence from
the reference implementation: sops preserves the document's own version
verbatim across a C<sops rotate> (measured: C<3.7.3> stays C<3.7.3>, C<3.13.3>
stays C<3.13.3>, and so do C<v3.13.3>, C<1.2.3> and C<3.13.3-rc.1>);
L<File::SOPS/rotate> instead constructs a fresh
L<File::SOPS::Metadata> object, whose L</version> defaults to C<$SOPS_VERSION>
(C<3.7.3>), so a document written by sops 3.13.3 reads back here with
C<version: 3.7.3> after a rotation. The
stamp is a provenance field that goes backwards rather than forwards, and
nothing here reads it -- no MAC, no AAD, no decryption decision depends on
L</version> -- so the divergence is silent. A document whose version sops
itself refuses (which L</from_hash> accepts permissively, per
L<docs/adr/0043>) would be rewritten still refused, but no version sops
currently writes is in that set. The decision to keep the stamp rather than
carry the document's own value across is recorded in F<docs/adr/0058> (karr
k151).

This is what L<File::SOPS/rotate> passes to L<File::SOPS/encrypt> so that a
rotated file keeps the rules it was written under.

=head2 key_material_fields

    my @found = $meta->key_material_fields;
    # => ('age', 'pgp')

Returns the names of the fields in which this document actually carries a
wrapped copy of the data key -- L</age>, L</pgp>, L</kms>, L</gcp_kms>,
L</azure_kv>, L</hc_vault> and C<key_groups>, skipping the ones that are empty
or absent. C<key_groups> is included although this class does not model it,
because a caller about to replace the data key has to know it is there.

This is what L<File::SOPS/rotate> asks before it generates a new data key: age
is the only backend implemented here, so a document holding key material for
any other one cannot be rotated without either revoking those recipients or
leaving them a wrapped copy of a key that no longer encrypts anything.

=head2 from_hash

    my $meta = File::SOPS::Metadata->from_hash($hash);

Class method to create a Metadata object from a HashRef.

Typically used when parsing the C<sops> section from a YAML/JSON file.

An B<absent encryption rule stays absent>. Every rule field is passed to the
constructor whether the document had it or not, so a document with no rule
field produces a Metadata with no rule -- not one with the C<_unencrypted>
default a freshly constructed object gets. The asymmetry is deliberate and it
is the reference implementation's: a default belongs to B<creating> a
document, not to B<reading> one. Measured against sops 3.13.3 -- take a file
it wrote, delete C<unencrypted_suffix> from the C<sops> section, and it stops
treating a C<_unencrypted> key as plaintext, failing with C<Input string ...
does not match sops' data format>. Applying the default here would make this
library leave a value in plaintext that the document's own producer encrypts.

B<Dies if the input is not a HashRef>, naming the shape it got instead. Until
0.003 it returned C<undef>, and that return was a data-loss path rather than a
convenience: both format handlers call this as
C<< from_hash(delete $data->{sops}) >> after seeing the key B<exist>, so C<undef>
came back meaning "there was a top-level C<sops> entry, it was not a mapping,
and it is now gone from the tree" while every caller reads C<undef> as "this
document has no metadata". A plaintext file containing C<sops: mine> therefore
lost that key on the way through L<File::SOPS/encrypt_file> -- over the original
file if C<output> was omitted -- and L<File::SOPS/decrypt> reported the generic
C<No SOPS metadata found> for a document whose C<sops> section it had in fact
just discarded.

sops refuses such a document from both directions and does not care what the
entry holds -- a scalar, a list, C<null> or an empty mapping are all the same to
it. Measured against sops 3.13.3: C<sops encrypt> stops with exit code 203 and
the same reserved-key message it gives an already-encrypted file, C<sops decrypt>
and C<sops rotate> stop with C<Found sops entry that is not a mapping>.

C<undef> dies too, rather than being read as "no section". The distinction
between an absent C<sops> key and one holding C<null> does not survive the
C<delete> at the call site, and sops refuses both, so the only caller that can
tell them apart is the one that still has the document -- it asks C<exists>
first and does not call this method at all when the answer is no.

Dies if the document carries more than one encryption rule, see
L</Encryption rules are mutually exclusive>.

=head2 Two fields are decoded weakly, because sops decodes them weakly

Everything in a C<sops> section is a string except two fields, and B<sops reads
both of them out of text> -- it decodes the whole section through mapstructure
with C<WeaklyTypedInput>, so C<mac_only_encrypted: "false"> is the boolean
false and C<shamir_threshold: "2"> is the integer 2. Anything outside the
accepted set is not guessed at: sops stops with C<cannot parse value as 'bool'>
or C<as 'int'> and exit 1.

This method does the same, and B<refuses the same> -- naming the field and the
value it could not read.

=head3 It is not a flat-format concern, which is what decides it lives here

The obvious home looks like L<File::SOPS::Metadata::Flat/unflatten>, since the
ENV and INI encodings are untyped and hand back every leaf as a string. It is
the wrong home: measured against sops 3.13.3, the weak decoding applies to a
B<nested YAML> C<sops:> section just as much, so a fix there would leave a
quoted C<mac_only_encrypted: "false"> in a YAML document still reading as Perl
truth -- the identical bug in the format that has a handler today. C<unflatten>
therefore stays the structural inverse of C<flatten> with no schema at all, and
the coercion lives here, at the one place every format's parsed section
arrives. docs/adr/0042 records the measurement and the decision.

What it costs to get wrong is not cosmetic: L</mac_only_encrypted> B<selects
the digest>. With it set the MAC covers only the encrypted values, behind a
fixed 32-byte initialization block, so the two settings can never produce the
same digest for the same document.

=head3 C<mac_only_encrypted>: C<strconv.ParseBool>'s set, and nothing else

    "1"  "t"  "T"  "TRUE"   "true"   "True"     -> true
    "0"  "f"  "F"  "FALSE"  "false"  "False"    -> false
    ""                                          -> false
    everything else                             -> dies

C<yes>, C<no>, C<on> and C<off> are B<not> in that set, quoted or bare, and
neither is C<"tRuE">, C<" false"> or C<"2">: sops refuses each of them with
exit 1. The empty string is mapstructure's own rule rather than ParseBool's --
it maps an empty string to the zero value before ParseBool is reached.

A decoded value is a L<JSON::PP::Boolean>, never C<1> or C<0>, so that the next
write emits C<true> or C<false> rather than degrading it to an integer.

=head3 C<shamir_threshold>: C<strconv.ParseInt(s, 0, 64)>

Base B<0> means the spelling picks the base, and the surprise is real:

    "2"       -> 2          "010"     -> 8      (a leading zero is octal)
    "0x10"    -> 16         "0b101"   -> 5
    "0o17"    -> 15         "1_000"   -> 1000   (underscores separate digits)
    "+2"      -> 2          ""        -> 0
    everything else, and anything outside Go's int64  -> dies

So C<" 2">, C<"2 ">, C<"2.0">, C<"1e3">, C<"08">, C<"1__0"> and C<2**63> are
all refused, as sops refuses them. C<"010"> is the row that makes a
decimal-only parse unacceptable: it would read 10 where sops reads 8, silently.

=head3 Only a string is decoded

A value the parser already typed is passed through untouched -- a
L<JSON::PP::Boolean>, or a number, which Go tests as C<!= 0> and Perl tests the
same way. The question "is this scalar a string or a number" is asked of
L<File::SOPS::Encrypted/detect_type> rather than answered a second time here,
so this method cannot drift away from the rest of the distribution (ADR 0002).

A reference where sops wants a scalar dies too: sops refuses that document with
C<expected type 'bool', got unconvertible type>, exit 1.

B<Nothing moves for a document that already carried a real boolean or a real
number>, which is every document sops itself writes: measured before and after,
the MAC plaintext of a YAML and a JSON document with C<mac_only_encrypted>
absent, explicitly C<false>, and set, is unchanged in all six cases.

=head2 The string fields are checked for their shape, and only for that

Every other field the C<sops> section models is a Go string, and the same weak
decoding reaches them from the other side: sops B<stringifies whatever scalar
it finds> and reads on. Measured against sops 3.13.3 --
C<unencrypted_suffix: 3> is read as C<"3">, C<true> as C<"1">, C<false> as
C<"0">, C<1e20> as C<"100000000000000000000">, C<0755> as C<"493"> -- and
C<sops rotate> writes that text back out as a quoted string.

A B<list or a map> in one of those fields is a different answer: sops refuses
the document outright, without opening it, with

    '<field>' expected type 'string', got unconvertible type

exit 1. Measured for all nine of them -- L</mac>, L</lastmodified>,
L</version>, the four encryption rules and the two comment-based rules this
distribution recognises without implementing. B<This method refuses the same>,
naming the field and the shape it got.

That refusal is not tidiness. A reference in L</encrypted_regex> reached
L</should_encrypt_key> as the pattern, matched no key, and
L<File::SOPS/rotate> then wrote every value of the document in B<plaintext> and
reported success -- for a document C<sops -d> will not open. One in
L</lastmodified> becomes the AAD the MAC is authenticated with, whose bytes are
then a memory address. A field this class does B<not> model keeps whatever it
holds, because sops ignores an unknown field whatever shape it has (measured),
and because C<key_groups> is a list by definition.

=head3 What is deliberately not done: a non-string scalar is not restringified

C<< unencrypted_suffix => 3 >> stays the number 3 here rather than becoming
C<"3">. For every spelling Perl's own text and Go's agree -- a
L<JSON::PP::Boolean> numifies to C<1>/C<0>, an integer stringifies to its
digits -- so the suffix a rule matches with is the same either way. The one
spelling where they differ is a float outside positional range: Go's
C<strconv.FormatFloat(v, 'f', -1, 64)> writes C<1e20> as
C<100000000000000000000> where Perl writes C<1e+20>.

It is left alone because it is not reachable from any document either
implementation produced. sops writes these fields as B<quoted strings>, always
-- including when normalising a hand-written float, measured -- and this
library writes back the scalar the parser gave it. So the divergence needs a
hand-edited document to exist at all, and the first time sops touches such a
document it is gone. docs/adr/0043 records the measurement.

=head3 C<lastmodified> is re-formatted, because that is what becomes the AAD

The one string field that is only a string to C<mapstructure>. Everything in
sops after that decode holds a Go C<time.Time> and reads
C<LastModified.Format(time.RFC3339)> from it -- B<the MAC's AAD included>. So a
document is free to spell the instant in any RFC 3339 form: sops reads it and
authenticates with its own rendering, and taking the document's text instead
fails to decrypt a MAC C<sops -d> accepts.

This method stores that rendering. The round trip is purely lexical, because Go
parses into a fixed zone carrying the offset it just read:

    "2026-08-21T09:05:08+00:00"    -> 2026-08-21T09:05:08Z
    "2026-08-21T09:05:08-00:00"    -> 2026-08-21T09:05:08Z
    "2026-08-21T09:05:08.123456Z"  -> 2026-08-21T09:05:08Z
    "2026-08-21T09:05:08,5Z"       -> 2026-08-21T09:05:08Z
    "2026-08-21T9:05:08Z"          -> 2026-08-21T09:05:08Z
    "2026-08-21T11:05:08+02:00"    -> 2026-08-21T11:05:08+02:00   (NOT UTC)
    "2026-08-21T09:05:08+00:60"    -> 2026-08-21T09:05:08+01:00

The fraction is dropped -- C<time.RFC3339> has no fractional field -- the hour
is zero-padded, and the zone is re-derived from the B<total> offset and written
C<Z> whenever that total is zero, whichever sign the document used. A non-zero
offset is B<kept>: C<+02:00> is not the same AAD as the same instant in UTC,
measured.

A spelling Go's layout cannot parse is B<passed through unchanged> rather than
refused. sops stops at exit 1 on every one of them -- a lower-case C<t> or
C<z>, a one-digit month, C<+0000> without the colon, a five-digit year, a
leading or trailing space -- so nothing is silently mis-read; and this grammar
is a reimplementation of Go's parser, where being narrower than Go somewhere
unmeasured would refuse a document sops reads. That is the trade k145
recorded for L</version>, one field over. docs/adr/0044 carries the 45 measured
spellings.

B<Nothing moves for a document either implementation writes>: every one of
them carries the C<Z> form already, and the decode is the identity on it.

=head3 What is deliberately not done: L</version> is not parsed

sops does not merely stringify that field, it B<semver-parses> it and stops on
a document it cannot parse -- on every read path (C<sops -d>, C<-d --extract>,
C<rotate>), exit 1. Measured, sops 3.13.3:

    3.13.3  "3.13.3"  v3.13.3  3.13.3-rc.1  3.13.3+build.5  1.a.b     accepted
    3       3.13      true     ""  null  (and an ABSENT version)      refused
    03.13.3   3.13.03   3.13.3-   3.13.3+   3.13.3-!   3.13.3-01      refused

This method accepts every one of them, and defaults an absent one to C<3.7.3>.
That is permissive -- it reads documents sops refuses, it never writes one --
and it is deliberate rather than forgotten:

=over 4

=item * B<Nothing here reads the field.> It is not in the MAC, not in the AAD,
and not in any decryption decision; sops's own use of it is a comparison
against its binary version.

=item * B<Every write path stamps a fresh C<3.7.3>>, which sops accepts.
L</policy_args> does not carry L</version> across a re-encryption, so a value
read out of a document never reaches a document -- a divergence from sops,
which preserves the document's own version verbatim on a rotate; the
decision is recorded in F<docs/adr/0058>.

=item * B<A partial check would be worse than none.> Refusing what does not
look like C<N.N.N> would refuse C<v3.13.3>, C<3.13.3-rc.1>, C<3.13.3+build.5>
and C<1.a.b> -- every one of which sops reads at exit 0 and writes back
verbatim on a C<rotate>. Reproducing the refusal faithfully means reproducing
C<blang/semver>'s strict grammar (leading zeroes, uint64 bounds, prerelease and
build components) B<plus> two sops-specific rules on top of it: a leading C<v>
is stripped, and a version whose text begins C<1.> is accepted without being
parsed at all.

=back

=head2 to_hash

    my $hash = $meta->to_hash;

Converts the Metadata object to a HashRef for serialization.

This HashRef is written to the C<sops> section of the encrypted file.

=head2 update_lastmodified

    $meta->update_lastmodified;

Sets C<lastmodified> to the current time as C<%Y-%m-%dT%H:%M:%SZ> in UTC --
Go's own C<time.RFC3339> rendering, which is what makes it usable as the MAC's
AAD unchanged. L<File::SOPS/encrypt> is the only caller, and
L</policy_args> deliberately does not carry a document's own value across a
re-encryption, so this is the only spelling this library writes.

Returns C<$self> for chaining.

=head2 add_age_recipient

    $meta->add_age_recipient(
        recipient => 'age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p',
        enc       => '-----BEGIN AGE ENCRYPTED FILE-----...',
    );

Adds an age recipient with their encrypted data key.

The C<enc> parameter should be the PEM-armored age-encrypted data key.

Returns C<$self> for chaining.

=head2 get_age_encrypted_keys

    my @keys = $meta->get_age_encrypted_keys;

Returns a list of age-encrypted data key entries (HashRefs).

Each entry has C<recipient> and C<enc> fields.

=head2 should_encrypt_key

    if ($meta->should_encrypt_key('api_key')) {
        # Encrypt this key
    }

Determines if a single hash key, considered on its own, should be encrypted
based on suffix/regex rules.

B<This is not the rule a document is encrypted under> -- that is
L</should_encrypt_path>, which applies the same tests to every component of a
value's key path, and it is what L<File::SOPS> walks the tree with. The two
agree whenever a rule can only exclude (C<unencrypted_suffix>,
C<unencrypted_regex>), because an excluded branch stays excluded all the way
down. They disagree on C<encrypted_suffix> and C<encrypted_regex>: a leaf
whose own key does not match is still encrypted when a key above it does.

This method remains for callers asking about one key in isolation.

Rules are applied in this order:

=over 4

=item 1. If C<unencrypted_suffix> is set and key ends with it, return false

=item 2. If C<encrypted_suffix> is set, return true if key ends with it, else false

=item 3. If C<unencrypted_regex> is set and key matches, return false

=item 4. If C<encrypted_regex> is set and key matches, return true, else false

=item 5. Default: return true (encrypt everything)

=back

Returns true if the key should be encrypted, false otherwise.

B<Dies> where the rule is a regex this side cannot read the way sops reads it
-- a construct both dialects take and disagree about, or one Perl cannot
compile. A construct Go RE2 rejects matches B<nothing> instead, because that is
what it matches at sops. See L</The regex rules are matched in RE2's dialect>.

=head2 should_encrypt_path

    if ($meta->should_encrypt_path(['database', 'password'])) {
        # This leaf is one of the encrypted ones
    }

Whole-path counterpart of L</should_encrypt_key>, mirroring C<shouldBeEncrypted>
in the Go implementation: each rule is evaluated against B<every> component of
the path, in the same order, with later rules overriding earlier ones.

A leaf is unencrypted if any component carries C<unencrypted_suffix> or matches
C<unencrypted_regex>, and (when those are configured) encrypted only if some
component carries C<encrypted_suffix> or matches C<encrypted_regex>.

The two regex rules are matched in B<RE2's> dialect, not Perl's. A pattern RE2
cannot compile matches B<nothing> here, which is what it matches at sops; a
pattern the two dialects compile and read differently, or one Perl cannot
compile at all, is refused rather than matched -- which is why this method can
still die. See L</The regex rules are matched in RE2's dialect>.

This is the predicate L<File::SOPS> encrypts a document with, B<and the one it
decrypts it with>: since 0.003 it is asked about every leaf on the way out too,
and its answer is what decides whether a leaf is ciphertext at all rather than
a value that happens to spell C<ENC[...]>. It is also what decides which values
the MAC covers when L</mac_only_encrypted> is set. See
L<File::SOPS/The rule decides what a value is, in both directions>.
Measured against sops 3.13.3 with C<--encrypted-suffix _enc>: every value
under a C<top_enc:> block is encrypted, a C<nested_enc:> under an ordinary
parent is encrypted, and the elements of a C<list_enc:> array are encrypted
because an array contributes no path component of its own and its elements
carry the parent's path.

Returns true if the value at that path should be encrypted.

=head2 assert_rule_regexes_agree

    $meta->assert_rule_regexes_agree;   # or dies

Dies unless L</unencrypted_regex> and L</encrypted_regex> are patterns Go RE2
and Perl read the same way. Returns true otherwise, including when neither is
set.

B<This is the guard for writing, and L</should_encrypt_path> is deliberately
more permissive than it.> A pattern RE2 cannot compile is not an error at sops
-- it discards the compile error, so the rule matches nothing -- and that is
reproducible, so a document carrying one is still read. Writing under it is
not: a caller who asks for C<< encrypted_regex => '(?=foo)' >> and is given
"matches nothing" gets every secret in the document written to disk in
plaintext, under a C<sops> section that makes the file look encrypted, at exit
0. See L<File::SOPS/The rule decides what a value is, in both directions> and
F<docs/adr/0051>.

L<File::SOPS> asks this once per document, when the metadata for a write is
built, so the refusal names the rule and arrives before any leaf is walked.

=head1 SEE ALSO

=over 4

=item * L<File::SOPS> - Main SOPS interface

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
