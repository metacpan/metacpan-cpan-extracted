package File::SOPS::Encrypted;
# ABSTRACT: Parse and generate SOPS encrypted values
our $VERSION = '0.004';
use Moo;
use B ();
use Carp qw(croak);
use Scalar::Util qw(blessed dualvar);
use MIME::Base64 qw(encode_base64 decode_base64);
use Crypt::AuthEnc::GCM qw(gcm_encrypt_authenticate gcm_decrypt_verify);
use Crypt::PRNG ();
use JSON::MaybeXS;
# The type ladder's own value: detect_type produces the type from it and
# _deserialize_value produces it from the type (docs/adr/0041). It loads
# nothing from this distribution, so the dependency runs one way only.
use File::SOPS::Comment;
use namespace::clean;


has algorithm => (is => 'ro', default => 'AES256_GCM');


has data => (is => 'ro', required => 1);


has iv => (is => 'ro', required => 1);


has tag => (is => 'ro', required => 1);


has type => (is => 'ro', default => 'str');


my $ENC_REGEX = qr/^ENC\[([^,]+),data:([^,]+),iv:([^,]+),tag:([^,]+),type:([^\]]+)\]$/;

sub parse {
    my ($class, $string) = @_;

    return unless defined $string && $string =~ $ENC_REGEX;

    my ($algo, $data, $iv, $tag, $type) = ($1, $2, $3, $4, $5);

    return $class->new(
        algorithm => $algo,
        data      => _decode_base64_strict($data, 'data'),
        iv        => _decode_base64_strict($iv,   'iv'),
        tag       => _decode_base64_strict($tag,  'tag'),
        type      => $type,
    );
}

# MIME::Base64::decode_base64 IGNORES anything outside the alphabet and stops
# at a short group, so a corrupted field decoded to a shorter string and turned
# into "Authentication failed - data may be corrupted" three calls later, or --
# for the iv and the tag -- into a wrong length passed straight to the cipher.
# Go decodes with base64.StdEncoding, which fails on the spot and says so, and
# the field it fails on is the useful half of the message.
sub _decode_base64_strict {
    my ($encoded, $field) = @_;

    croak "Invalid base64 in the '$field' field of an ENC value: "
        . "characters outside the standard alphabet"
        unless $encoded =~ m{\A[A-Za-z0-9+/]*={0,2}\z};
    croak "Invalid base64 in the '$field' field of an ENC value: "
        . "length is not a multiple of 4"
        if length($encoded) % 4;

    return decode_base64($encoded);
}


sub is_encrypted {
    my ($class, $string) = @_;
    return defined $string && $string =~ $ENC_REGEX;
}


# The type LABEL, without decoding anything. The third sharer of $ENC_REGEX,
# alongside is_encrypted and parse -- one anchored pattern, so a caller asking
# "what kind of leaf is this" can never disagree with a caller asking "is this a
# leaf at all".
#
# Deliberately not `parse($s)->type`: parse decodes all three base64 fields and
# croaks on a damaged one, and the caller this exists for -- the comment guard
# in File::SOPS::Format::YAML -- has to recognise a comment leaf whose
# ciphertext is broken. Measured against sops 3.13.3: a comment whose ciphertext
# was swapped for another value's is NOT fatal to sops (`sops -d` exit 0, with a
# warning), so identifying it by the label alone is what matches the reference.
sub encrypted_type {
    my ($class, $string) = @_;

    return unless defined $string && $string =~ $ENC_REGEX;
    return $5;
}


# Is this PERL VALUE a comment rather than a value? The plaintext side of the
# question detect_type answers with the label -- same predicate, one place, so
# a walk that has to skip comments and the ladder that types them can never
# disagree.
#
# Deliberately NOT true for an ENC[...,type:comment] string. That is what the
# FILE says a leaf is, which is a different question with a different answer:
# on the encrypt side such a string is a caller's plain string and is written
# as a type:str value. Reading them as one predicate is how the digest and the
# document end up covering different leaves. encrypted_type is the wire half,
# and File::SOPS::_is_comment_leaf is where the two meet, each under the
# condition that makes it the right one.
sub is_comment {
    my ($class, $value) = @_;
    return blessed($value) && $value->isa('File::SOPS::Comment') ? 1 : 0;
}


sub to_string {
    my ($self) = @_;

    my $data = _encode_base64_oneline($self->data);
    my $iv   = _encode_base64_oneline($self->iv);
    my $tag  = _encode_base64_oneline($self->tag);

    return sprintf('ENC[%s,data:%s,iv:%s,tag:%s,type:%s]',
        $self->algorithm, $data, $iv, $tag, $self->type);
}


sub encrypt_value {
    my ($class, %args) = @_;
    my $value    = $args{value};
    my $key      = $args{key}      // croak "key required";
    my $aad      = _aad_bytes($args{aad});
    my $type     = $args{type}     // $class->detect_type($value);

    $value //= '';

    # THE SLOT, from the one place that cannot be wrong about it: this method
    # exists to put a value in an encrypted slot, so every value it is handed
    # is in one. That is what lets assert_representable stop asking about a
    # non-finite float here -- an encrypted slot's wire form for one is
    # type:float plus the plaintext Go's strconv.FormatFloat writes, which is
    # what sops itself puts in BOTH formats, so the scalar's string half plays
    # no part and there is nothing left to refuse. See docs/adr/0040.
    $class->assert_representable($value, encrypted => 1);

    my $plaintext = $class->value_to_bytes($value, $type);

    # AES-GCM ciphertext is exactly as long as its plaintext, so an empty
    # value produces an empty `data:` field -- and neither implementation's
    # parser accepts that. Ours requires one character ([^,]+); sops stops with
    # "Input string ENC[...] does not match sops' data format" (exit 25). sops
    # never produces the shape either: it leaves an empty value unencrypted,
    # which is what File::SOPS::encrypt does before it ever gets here.
    croak "Cannot encrypt an empty value: the SOPS wire format has no "
        . "representation for empty ciphertext. Leave the value unencrypted "
        . "instead, which is what sops does with an empty scalar."
        unless length $plaintext;

    my $iv = _random_bytes(32);  # SOPS uses 32-byte nonce

    my ($ciphertext, $tag) = gcm_encrypt_authenticate('AES', $key, $iv, $aad, $plaintext);

    return $class->new(
        algorithm => 'AES256_GCM',
        data      => $ciphertext,
        iv        => $iv,
        tag       => $tag,
        type      => $type,
    );
}


sub decrypt_bytes {
    my ($self, %args) = @_;
    my $key = $args{key} // croak "key required";
    my $aad = _aad_bytes($args{aad});

    croak "Unsupported algorithm: " . $self->algorithm
        unless $self->algorithm eq 'AES256_GCM';

    my $plaintext = gcm_decrypt_verify('AES', $key, $self->iv, $aad, $self->data, $self->tag);
    croak "Authentication failed - data may be corrupted" unless defined $plaintext;

    # The stringify is load-bearing, and `return $plaintext` is a silent
    # data-corruption bug -- do not "simplify" it away.
    #
    # CryptX (measured on 0.087) hands back the plaintext in an SV whose PV
    # buffer is NOT NUL-terminated at SvCUR. Perl's own string-to-number
    # conversion depends on that terminator: sv_2nv only
    # consults SvCUR through grok_number, and for anything grok_number cannot
    # settle as an integer inside a UV -- every float, and every integer wider
    # than 64 bits -- it falls through to Atof(SvPVX), a C string read with no
    # length. So a numeric read of the raw scalar runs off the end of the
    # plaintext into whatever the allocator left there, and when that byte is
    # one of the ten digit characters it joins the number: the
    # 100000000000000000000 Go writes for 1e20 came back as 1e21, on maybe one
    # leaf in a hundred, with the ciphertext and the MAC both intact.
    # Assignment through a stringify goes via sv_setpvn, which allocates a
    # buffer Perl terminates itself.
    #
    # It belongs here rather than at the two conversions in _deserialize_value
    # because this is the boundary the foreign scalar crosses: the type
    # conversion, the MAC digest and any caller doing arithmetic on what this
    # method returns are all downstream of it, and a fix at the conversions
    # would have to be repeated at each new one. See t/18-decrypt-determinism.t.
    #
    # This is the ONLY such normalisation, deliberately: the ciphertext, the tag
    # and the IV come out of CryptX just as unterminated, and are left alone
    # because nothing ever reads them as anything but length-delimited bytes.
    # docs/adr/0004 has the measurements and says why "normalise every CryptX
    # boundary" is not the rule -- and why "normalise every foreign scalar"
    # would break ADR 0002 outright.
    return "$plaintext";
}


sub decrypt_value {
    my ($self, %args) = @_;
    return _deserialize_value($self->decrypt_bytes(%args), $self->type);
}


# Perl's own boolean SV -- the value !!1, $x > 3, 'a' eq 'a' and
# builtin::true produce -- asked through the same predicate BOTH emitters ask.
#
# YAML::XS and Cpanel::JSON::XS write exactly such an SV as a bare true/false,
# and they use SvIsBOOL to decide it. That is not a flag pattern this module
# could reimplement: measured on YAML::XS 0.910.0 and Cpanel::JSON::XS 4.43,
# dualvar(1, '1') carries the same IV, the same PV and the same PUBLIC flags as
# !!1, and both emitters write it as `1`. The two differ only in whether the PV
# buffer is perl's own static PL_Yes, which B does not expose. A lookalike test
# here would therefore type a dualvar `bool` and digest `True` while the
# document said `1` -- this defect again, introduced by its own fix.
#
# builtin::is_bool is the only way to reach SvIsBOOL from Perl. It arrived with
# the SV mark in 5.36; on an older perl there is no such SV for either emitter
# to recognise, so `sub { 0 }` is the whole answer there and not a degraded
# one. Loaded through a string eval because `use builtin` and
# `no warnings 'experimental::builtin'` are each a compile-time error on a perl
# that has neither, and this distribution declares 5.010.
#
# This is NOT a return to the pattern match ADR 0002 removed: nothing looks at
# the value's text. It reads a mark Perl itself put on the scalar, exactly as
# _sv_kind reads IOK. See docs/adr/0016.
my $IS_BOOL_SV = do {
    my $probe = eval q{
        no warnings 'experimental::builtin';
        use builtin qw(is_bool);
        sub { is_bool($_[0]) }
    };

    # VERIFIED, not assumed: it has to say yes to both sentinels and no to the
    # integer and the string that share their flags and their PV. A predicate
    # that answers anything else is not the one the emitters use, and typing a
    # leaf by it would write a document that fails its own MAC.
    $probe = undef unless $probe
        && $probe->(!!1) && $probe->(!!0)
        && !$probe->(1)  && !$probe->(0)
        && !$probe->('') && !$probe->('1');

    # Below 5.36 there is no boolean SV, so "no" is the whole answer and the
    # emitters agree. At or above it there is one, both emitters write it as a
    # bare true/false, and having no way to recognise it means every boolean
    # this process encrypts is a document nothing can read -- which is a thing
    # to say at load time, not to discover from a MAC mismatch.
    croak "File::SOPS::Encrypted: perl $] has a boolean SV (SvIsBOOL) but "
        . "builtin::is_bool is not usable here, so a Perl boolean cannot be "
        . "told from the integer 1. Every such value would be written as "
        . "type:int while both emitters write it as a bare true/false, and the "
        . "document would fail its own MAC. See docs/adr/0016."
        if !$probe && $] >= 5.036;

    $probe || sub { 0 };
};

sub detect_type {
    my ($class, $value) = @_;
    return 'str' unless defined $value;
    # JSON::PP::Boolean is the class every JSON::MaybeXS backend blesses into
    # (Cpanel::JSON::XS and JSON::XS included), and the class YAML::XS blesses
    # into under $YAML::XS::Boolean = 'JSON::PP', so this test is
    # backend-agnostic. blessed() guard: ->isa dies on an unblessed ref, and a
    # plain SCALAR/CODE ref can reach here from encrypt_value or the
    # _encrypt_tree leaf branch.
    # A comment is not a value and has no scalar of its own, so it gets a class
    # -- the same move type:bool makes with JSON::PP::Boolean. Before that
    # check because the two are independent: what matters is that neither can
    # be reached by the ref -> 'str' line below. See docs/adr/0041.
    return 'comment' if blessed($value) && $value->isa('File::SOPS::Comment');
    return 'bool' if blessed($value) && $value->isa('JSON::PP::Boolean');
    return 'str'  if ref $value;
    # Before the flag ladder: a boolean sentinel publishes IOK, so _sv_kind
    # would call it an int and value_to_bytes would digest 1 / 0 against a
    # document both emitters write as true / false. k90.
    return 'bool' if $IS_BOOL_SV->($value);
    return _sv_kind($value);
}


# Go's int is int64 on every platform SOPS ships for, and its range is what
# strconv.Atoi accepts on the way back in. Written as MAX-1 plus one so the
# literal itself never has to survive as a negative UV.
my $INT64_MAX = 9223372036854775807;
my $INT64_MIN = -9223372036854775807 - 1;

# Range test on the DECIMAL TEXT, not on a numified copy. -9223372036854775809
# rounds to exactly -2**63 as a double, so `0 + $s >= $INT64_MIN` says yes to a
# value Go says no to. $s has already been matched against /\A[+-]?[0-9]+\z/.
sub _decimal_fits_int64 {
    my ($s) = @_;
    my ($sign, $digits) = $s =~ /\A([+-]?)0*([0-9]+)\z/;
    my $limit = $sign eq '-' ? '9223372036854775808' : '9223372036854775807';
    return 0 if length($digits) > length($limit);
    return 0 if length($digits) == length($limit) && $digits gt $limit;
    return 1;
}

# The same boundary asked of a scalar Perl already holds as a NUMBER, for a
# format handler that has read the SV's flags itself and needs the limit
# without spelling it a second time (k101, ADR 0021). One definition of
# int64 in this distribution, here, is the point of the method.
#
# The unpacking COPIES, and that is load-bearing rather than house style: a
# comparison against $_[1] would numify the CALLER's scalar in place, and
# measured, that sets the PUBLIC SVf_IOK -- `'5432' > $INT64_MAX` leaves
# detect_type calling '5432' an int. That is k32's mechanism and ADR
# 0002's rule; the copy is what keeps this predicate from retyping the
# document it is asked about. Do not "optimise" it away.
#
# The argument has to be an INTEGER, which is the caller's cheap first gate
# and never this method's business (asking would be a second type ladder).
# Neither other kind is answered correctly, and both for the same rounding:
# an NV of exactly 2**63 says yes, because the comparison promotes the IV
# limit to a double and 2**63-1 becomes 2**63; and a decimal STRING is the
# trap _decimal_fits_int64 exists for, from the other side. Text goes there.
sub integer_fits_int64 {
    my ($class, $value) = @_;
    return $value >= $INT64_MIN && $value <= $INT64_MAX ? 1 : 0;
}


# Canonical texts no emitter has a wire form for that it derives from the
# NUMBER alone: Go's strconv.FormatFloat produces them, and Perl's encoders
# produce something else (`null`, `Inf`) for the same double. Everything below
# that treats a non-finite float differently keys on this one regex, and it
# matches the output of value_to_bytes, never a rendering derived beside it.
#
# -0 used to be on this list and is not any more: k62 measured a YAML
# spelling that works, and the format that needed one supplies it in its own
# carrier. See docs/adr/0006.
my $NO_AGREED_FORM = qr/\A(?:NaN|[+-]Inf)\z/;

# The text value_to_bytes covers for a non-finite float, and undef for every
# other float. THE one statement of the rule: _float_bytes calls this and
# returns its answer, so what the digest covers and what the guards below ask
# about cannot become two comparisons against 9**9**9 that drift apart.
#
# It answers in three comparisons rather than through _float_bytes's whole
# shortest-round-trip loop, and that is measured rather than assumed: with the
# loop in the way, encrypt_value on a float leaf cost 130ms -> 272ms per 5000
# calls, a tax on every encrypted float for a guard about three values.
#
# The scalar is read numerically, which is what the digest does to it anyway.
# Nothing here reads or writes its string half.
my $POSITIVE_INFINITY = 9**9**9;

sub _non_finite_bytes {
    my ($n) = @_;

    return 'NaN' if $n != $n;                       # only NaN is unequal to itself
    return $n > 0 ? '+Inf' : '-Inf'
        if $n == $POSITIVE_INFINITY || $n == -$POSITIVE_INFINITY;
    return undef;
}

# The bytes go-yaml derives from a plain scalar it resolves to a non-finite
# float, for the twelve tokens that are the only spellings it does that for --
# and undef for everything else, `.INf`, `+.nan` and `.infinity` included.
#
# A SECOND STATEMENT of twelve rows of Go's resolveMap, whose single home is
# %GO_CONSTANT in Format::YAML, and deliberately so: this is a GATE and not a
# verdict. It decides only whether a leaf is worth deferring to the emitter's
# own foreign-resolution guard, which answers from `_go_scalar_bytes` -- the one
# model of resolve.go -- and has the last word on every document that carries a
# MAC. Both drift directions therefore fail CLOSED: a row here that
# %GO_CONSTANT lacks is refused by that guard on bytes, and a row %GO_CONSTANT
# gains that is missing here is refused by this gate. Neither can put a file on
# disk. See docs/adr/0031.
sub _go_non_finite_token_bytes {
    my ($token) = @_;
    return '+Inf' if $token =~ /\A\+?\.(?:inf|Inf|INF)\z/;
    return '-Inf' if $token =~ /\A-\.(?:inf|Inf|INF)\z/;
    return 'NaN'  if $token =~ /\A\.(?:nan|NaN|NAN)\z/;
    return undef;
}

# Does this scalar carry, as its OWN public string half, a token a foreign
# reader resolves back to exactly the double it holds?
#
# Both halves have to agree. dualvar(+Inf, '-.inf') is a contradiction -- the
# document would say one infinity and the digest cover the other -- and it is
# refused, the same answer docs/adr/0012 gives an integer whose halves disagree,
# and measured the same way (sops -d exit 51 for every mismatched pairing).
#
# The PUBLIC SVf_POK, for the reason _has_public_pv gives: merely printing a
# float sets the private flag, and a gate that read that one would take a
# caller's logging for a promise about the wire. Nothing here numifies the
# string half or stringifies the number (docs/adr/0002, k32).
sub _carries_go_non_finite_token {
    my ($value, $text) = @_;
    return 0 unless _has_public_pv($value);
    my $bytes = _go_non_finite_token_bytes("$value");
    return defined $bytes && $bytes eq $text ? 1 : 0;
}

sub assert_representable {
    my ($class, $value, %args) = @_;
    return 1 unless defined $value;

    # k67: an unblessed reference in an encrypted slot would be
    # stringified as 'SCALAR(0x...)' / 'ARRAY(0x...)' / 'HASH(0x...)' /
    # 'CODE(0x...)' -- a heap address that differs per process run -- and
    # value_to_bytes would feed that same address into the MAC digest. The
    # document verifies (the doc and the digest agree on the address), but the
    # stored value is unrecognisable and impossible to reproduce on a later
    # read. Refused here, the same shape as the int64 check below. A blessed
    # object passes: ADR 0008 measured that an encrypted Math::BigFloat, an
    # object overloading "" and a qr// all round-trip correctly -- they have a
    # stringification the caller chose.
    if (ref $value) {
        return 1 if blessed($value);
        croak "cannot encrypt an unblessed " . ref($value)
            . " reference; the SOPS digest covers the reference's heap "
            . "address (e.g. SCALAR(0x...)), which differs per run, and "
            . "storing that as an encrypted value is almost never what the "
            . "caller means. Pass a string (the value the ref was holding, "
            . "or its stringification), or a blessed object whose "
            . "stringification is the value you mean.";
    }

    # k59: a non-finite float (NaN, +Inf, -Inf) has no agreed form on the
    # wire OF ITS OWN. value_to_bytes writes +Inf / -Inf / NaN -- the same text
    # Go's strconv.FormatFloat produces -- but the emitters write something
    # else for the same double: Cpanel::JSON::XS writes `null`, and YAML::XS
    # writes a bare `Inf` / `-Inf` / `NaN`, which go-yaml resolves as a STRING.
    # Measured against sops 3.13.3, unencrypted YAML leaf: `Inf` is `sops -d`
    # exit 51, and `-Inf` / `NaN` are exit 0 with the leaf silently retyped
    # from a float to a string -- which is worse, not better. Refused here, the
    # same shape as the ref and int64 checks.
    #
    # NARROWED for k113 / docs/adr/0031: that premise is about a scalar
    # whose only form is its number. One that also carries a plain YAML token
    # go-yaml resolves back to exactly that double -- the shape docs/adr/0026's
    # parse produces for a document sops wrote -- does have a wire form, and
    # refusing it left this library reading a document it could not write back
    # (rotate croaked on a file `sops -d` reads at exit 0). Measured, all twelve
    # tokens, unencrypted YAML slot: `sops -e` -> File::SOPS->rotate ->
    # `sops -d` exit 0, the wire byte-identical.
    #
    # This is a GATE, not the verdict. Whether the document being written can
    # really carry the token is a question about one emitter and one foreign
    # reader, and it is answered where the format is known: by docs/adr/0013's
    # foreign-resolution guard in Format::YAML, which compares the token that
    # emitter actually writes against Go's own resolution -- the single copy of
    # that model. canonical_float_tree hands the leaf over, and refuses it in a
    # MAC-covered document whose handler installs no such guard.
    #
    # Reading is unaffected -- a type:float plaintext of +Inf or NaN is accepted
    # by _deserialize_value today (k59's request, and Go writes it) and
    # stays accepted: assert_representable is encrypt-side only.
    #
    # NARROWED AGAIN for k122 / docs/adr/0040, and this time by SLOT. All
    # of the above is about a leaf the DOCUMENT carries as a token, which is
    # the unencrypted slot and nothing else. An encrypted slot carries
    # type:float and the plaintext value_to_bytes writes, in both formats, and
    # measured against sops 3.13.3 that is exactly what `sops -e` puts there --
    # `--output-type json` included, exit 0. So the emitters' inability to
    # spell the number says nothing about that slot, and the leaf is written.
    # The caller supplies the slot; the two that do are encrypt_value, which is
    # the encrypted slot by construction, and File::SOPS::_compute_mac's leaf
    # sweep, which asks the encryption rules.
    #
    # What stays refused in an encrypted slot is a scalar that STATES a string
    # half contradicting its number -- dualvar(+Inf, 'banana'), and the JSON
    # literal of 400 zeros whose text is its digits (docs/adr/0020). The wire
    # is derived from the number, so that text would be dropped without a
    # trace, and choosing between a scalar's two halves is the guess
    # docs/adr/0012 refuses to make.
    #
    # NARROWED AGAIN for k141 / docs/adr/0060, and this time by PUBLIC PV.
    # All of the above is about a leaf WITH a public PV -- the case where the
    # scalar already states a string half. A leaf WITHOUT one (a bare NV, like
    # `9**9**9`) has only the number to say what it is, and docs/adr/0037's
    # _non_finite_token_leaf manufactures the carrying dualvar for it in YAML:
    # the carrier consults go-yaml's own twelve tokens and the YAML emitter
    # writes the token the digest covers. JSON has no such carrier, and the
    # refusal there is the emit walk's croak -- where the question of "can this
    # format spell this number" actually belongs, not in assert_representable,
    # which sees both formats the same.
    #
    # What stays refused in an unencrypted slot is the same shape that stayed
    # refused in an encrypted slot: a public PV that contradicts its number.
    # A caller who constructs dualvar(+Inf, 'banana') by hand -- no parse and
    # no decryption produces one -- is told which half they meant.
    if (_sv_kind($value) eq 'float') {
        my $form = _non_finite_bytes($value);

        croak "value is a non-finite float ($form) that also states a string "
            . "half of its own, and an encrypted slot carries only one of "
            . "them: the wire holds type:float and the plaintext $form, "
            . "derived from the NUMBER, so the text beside it would be "
            . "dropped without a trace. Which half you meant is yours to say "
            . "and this library does not guess -- the same answer an integer "
            . "whose two halves disagree gets. Pass the number on its own to "
            . "store it as a float, which is what sops writes for the same "
            . "value; or pass the text as a string (type:str), which is "
            . "written verbatim and round-trips exactly through both."
            if $args{encrypted} && defined $form && _has_public_pv($value)
            && !_carries_go_non_finite_token($value, $form);

        croak "value is a non-finite float ($form) that also states a string "
            . "half of its own, and an unencrypted slot can carry only one "
            . "of them: the wire holds the token the emitter writes -- the "
            . "public PV when it is one of go-yaml's twelve non-finite "
            . "tokens, and a token the YAML carrier manufactures for a bare "
            . "number. Yours is neither, so the text beside it would be "
            . "dropped without a trace. Which half you meant is yours to say "
            . "-- pass the number on its own to let the carrier write, or "
            . "pass the text as a string (type:str), which is written verbatim "
            . "and round-trips exactly through both."
            if !$args{encrypted} && defined $form && _has_public_pv($value)
            && !_carries_go_non_finite_token($value, $form);
    }

    return 1 unless _sv_kind($value) eq 'int';

    # The same decimal value_to_bytes would write, tested by the same rule the
    # decrypt side uses -- so what we refuse to write is exactly what we refuse
    # to read.
    return 1 if _decimal_fits_int64('' . (0 + $value));

    # Only the POSITIVE window [2**63 .. 2**64-1] can reach this croak, and
    # that is structural rather than lucky: SVf_IOK means the SV carries an IV
    # or a UV, an IV bottoms out at exactly int64min and a UV cannot be
    # negative, so no integer SV exists below the range. Measured for karr
    # k104 -- 14 negative decimals bracketing int64min, uint64max and beyond,
    # through 13 construction routes each (Perl literals, arithmetic,
    # sprintf/int clamps, dualvar, a numerically-read PV, and the JSON and
    # YAML parsers): 182 rows, 36 of them `int`, zero below int64min, zero
    # croaks. Below the range a value arrives NOK or POK and takes the float
    # rung instead (ADR 0020). This confirms the premise ADR 0021's decision
    # rests on; the message below therefore never has to speak about a
    # negative value.
    #
    # The two answers it offers were both measured against sops 3.13.3, 12
    # literals across the window x 2 formats x 2 slots. The STRING answer:
    # 48 of 48 `sops -d` exit 0, digits verbatim in every cell. The FLOAT
    # answer: 41 of 48 exit 0 with sops's own normalisation, 7 refused HERE by
    # ADR 0013's guard (all of them unencrypted YAML, where ADR 0011's repair
    # has to write the canonical decimal bare and Go's resolver reads it as a
    # uint64) -- and zero cells that put a file on disk sops rejects. That
    # 7-of-48 is why the float is offered as an answer and not as a promise;
    # note the split is NOT "canonical decimal past uint64max", which is only
    # one of the two ways through.
    #
    # `unpack('d', pack('d', $value))` is named in the message because the
    # obvious spellings do not work: measured, `$value + 0.0` and
    # `$value * 1.0` on a UV come back IOK+IVisUV and land on this croak
    # again, Perl having kept the integer.
    croak
        "value is an integer outside the range the SOPS int type can hold "
      . "($INT64_MIN .. $INT64_MAX, Go's int64). Perl's integers are wider "
      . "than Go's, and there is no SOPS wire form that preserves this one: "
      . "written as type:int, sops refuses the file with "
      . "\"strconv.Atoi: value out of range\"; written as type:float it would "
      . "silently lose digits. Two answers, and which one you want is yours "
      . "to say: pass it as a string to store the digits exactly -- type:str, "
      . "written verbatim, in both formats and both slots -- or as a float, "
      . "which is unpack('d', pack('d', \$value)) and not \$value + 0.0, to "
      . "get what sops itself writes for these digits: type:float and the "
      . "double's canonical decimal, at the cost of the digits the double "
      . "cannot hold. That second answer is the one a bare JSON number in "
      . "this range already takes, because Go's own decoder reads it as a "
      . "float64. It is not unconditional: in an unencrypted YAML slot the "
      . "float may be refused again, by the guard that keeps this library's "
      . "digest and Go's YAML resolver agreeing.";
}


sub value_to_bytes {
    my ($class, $value, $type) = @_;
    return '' unless defined $value;
    $type //= $class->detect_type($value);

    # A comment's wire plaintext is its text, verbatim and UTF-8 encoded --
    # the same treatment a string gets, and for the same reason (docs/adr/0003:
    # the flag is not consulted, here either). Measured against sops 3.13.3:
    # the plaintext is everything after the `#`, leading space included, so
    # nothing is trimmed on the way out. See docs/adr/0041.
    if (blessed($value) && $value->isa('File::SOPS::Comment')) {
        return _utf8_bytes($value->text);
    }
    # SOPS uses Titlecase for bools: "True" / "False"
    if (blessed($value) && $value->isa('JSON::PP::Boolean')) {
        return $value ? 'True' : 'False';
    }
    if ($type eq 'bool') {
        # Explicit rule, symmetric with _deserialize_value, for a caller who
        # forced type => 'bool' on a plain scalar. The old test ended in
        # "|| $value", a bare Perl truthiness fallback, so the non-empty
        # string 'false' came out as 'True'.
        return (lc("$value") eq 'true' || "$value" eq '1') ? 'True' : 'False';
    }

    # SOPS's binary type is not text, so there is nothing to encode. Mirrors
    # _deserialize_value, which does not decode it either. This is also the
    # only way a caller can say "these really are bytes" -- see the encoding
    # note on _utf8_bytes.
    return "$value" if $type eq 'bytes';

    # Everything else is decided by what the scalar IS, not by the label:
    # a number is written in the canonical form Go would re-derive from it,
    # a string is written verbatim.
    my $kind = ref($value) ? 'str' : _sv_kind($value);
    my $str
        = $kind eq 'int'   ? '' . (0 + $value)
        : $kind eq 'float' ? _float_bytes($value)
        :                    "$value";

    return _utf8_bytes($str);
}


sub canonical_float_tree {
    my ($class, $tree, %args) = @_;
    my $roundtrips = $args{roundtrips} // croak "roundtrips callback required";
    my $carrier    = $args{carrier}    // croak "carrier callback required";
    my $reject     = $args{reject};
    my $scalars    = $args{reject_scalar};

    return _canonical_floats($tree, $roundtrips, $carrier, $reject, $scalars,
                             _document_carries_mac($tree), []);
}

# Does the document about to be written carry a MAC a foreign reader will
# recompute from these bytes?
#
# Read off the tree, because that is the only place it is available here: a
# handler's serialize() puts the metadata under `sops` before it calls its
# emitter, and the plaintext emitters (decrypt_file, edit) hand over the tree
# without one. The YAML handler additionally says so by installing a
# reject_scalar (docs/adr/0013), but the JSON handler's emit is the IDENTICAL
# call on both paths, so for that one this is the only signal there is.
#
# The same fact docs/adr/0026's parse-side walk keys on, read from the same
# place. It cannot answer wrongly in the direction that matters: serialize
# always adds the key and refuses a tree that already has one, and a
# multi-document stream is refused one layer up, so the root is always the
# single document's hash. A caller who invokes a handler's emit() directly on a
# plaintext tree that happens to carry a top-level `sops` key gets a leaf
# refused that would have been written -- fail-closed, and the only reachable
# false answer. See docs/adr/0031.
sub _document_carries_mac {
    my ($tree) = @_;
    return ref $tree eq 'HASH' && exists $tree->{sops} ? 1 : 0;
}

# WHERE a rejected leaf sits, in the shape File::SOPS::_at_path already uses for
# the MAC walk's messages -- keys colon-joined, '(document root)' for the empty
# path. One copy of the convention, here, rather than one per reject callback:
# a caller who has to learn two notations for the same document is the reason
# k68 exists at all.
#
# Array INDICES are carried, where the MAC's own _sorted_leaves drops them --
# that omission is the AAD rule (SOPS gives every element of an array its
# parent's path), and this string is a diagnostic, never an AAD. `items:3:key`
# is the same shape _extract_path reports a navigation failure at.
sub _leaf_location {
    my ($path) = @_;
    return ($path && @$path) ? join(':', @$path) : '(document root)';
}

# The leaf as it will be WRITTEN, handed to the handler's foreign-resolution
# check on its way out. Every plain-scalar return path in _canonical_floats goes
# through here, so the check sees the carrier's replacement rather than the
# scalar the carrier replaced -- for a negative zero those two are `-0.0` and
# `-0`, and only the first is what a reader gets to resolve.
sub _written_leaf {
    my ($leaf, $text, $reject_scalar, $path) = @_;
    $reject_scalar->($leaf, _leaf_location($path), $path, $text) if $reject_scalar;
    return $leaf;
}

# The one spelling per non-finite value that `sops -e` itself writes, keyed by
# the bytes value_to_bytes covers for it. The INVERSE of
# _go_non_finite_token_bytes, narrowed to three of its twelve rows: sops
# normalises `.Inf`, `+.INF` and the rest away, so these are the only ones a
# document sops wrote can hold, and the only ones worth manufacturing.
#
# Not a third statement of Go's resolveMap. Every token this table produces is
# handed straight back to _go_non_finite_token_bytes by the check below, so a
# row here that gate does not accept REFUSES the document rather than writing
# it -- the same fail-closed pairing docs/adr/0031 set up between that gate and
# %GO_CONSTANT, one layer in.
my %GO_NON_FINITE_TOKEN = ('+Inf' => '.inf', '-Inf' => '-.inf', 'NaN' => '.nan');

# A non-finite float whose only form is its NUMBER, in the shape the emitter
# writing this document can put on the wire -- or a croak, where it has none.
#
# k134: an encrypted type:float decrypts to a bare Perl infinity, and
# YAML::XS writes one as `Inf` / `-Inf` / `NaN`, which go-yaml resolves as a
# STRING. So the plaintext decrypt_file and edit produce says a string where
# the document held a number, the editor hands that string back, and the leaf
# is re-encrypted as type:str -- silently, `sops -d` exit 0. Measured against
# sops 3.13.3, encrypted slot, three spellings: `sops -d` writes `.inf`,
# `-.inf` and `.nan`, and `sops edit` keeps the leaf a type:float. In JSON the
# same leaf reached the file as `null`, and edit replaced the whole ENC[...]
# with a bare unencrypted null -- where `sops -d --output-type json` and
# `sops edit` both refuse the document, exit 4.
#
# ASKED OF THE EMITTER, through the carrier -- the one hook whose job is
# already "the replacement, format-specific", and the only format signal that
# exists on this path. docs/adr/0031 read the same distinction off
# reject_scalar, which a plaintext emit installs in neither format, deliberately
# (docs/adr/0013). Measured, neither carrier needed changing: the YAML one
# returns dualvar($double, '.inf'), which YAML::XS writes as the bare token, and
# the JSON one croaks, because Math::BigFloat cannot reproduce a token it was
# never given.
#
# VERIFIED, not trusted, and with docs/adr/0031's own gate: the answer has to be
# an unreferenced scalar whose public string half is a token go-yaml resolves to
# these bytes AND whose number still renders as them. Both halves, so a carrier
# that returns something else -- or dies -- refuses the document instead of
# putting a wrong one on disk.
#
# NO VALUE IN THE MESSAGE. assert_representable's neighbouring refusal names the
# form (`+Inf`), because there the scalar came from the caller. This one is
# reached for a leaf that came out of an ENCRYPTED slot, and which of the three
# it is, is the plaintext.
sub _non_finite_token_leaf {
    my ($node, $text, $carrier, $path) = @_;

    my $leaf = eval { $carrier->($node, $GO_NON_FINITE_TOKEN{$text}) };

    return $leaf
        if defined $leaf && !ref $leaf
        && _carries_go_non_finite_token($leaf, $text)
        && __PACKAGE__->value_to_bytes($leaf) eq $text;

    croak _leaf_location($path) . ": cannot write a non-finite float to this "
        . "SOPS document: the only form both implementations read back as the "
        . "same number is a YAML plain scalar Go's yaml.v3 resolves to it "
        . "(`.inf`, `-.inf`, `.nan`), and the emitter writing this document "
        . "has none -- JSON has no spelling for one at all, so the leaf would "
        . "reach the file as `null` or as a quoted string and stop being a "
        . "number on the next read. sops refuses the same document rather "
        . "than writing one (measured, `sops -d --output-type json` and "
        . "`sops edit` are both exit 4). The value is still readable with "
        . "decrypt or extract; to write it out, write the document as YAML, "
        . "or store it as a string (type:str), which is written verbatim and "
        . "round-trips exactly through both implementations";
}

sub _canonical_floats {
    no warnings 'recursion';
    my ($node, $roundtrips, $carrier, $reject, $reject_scalar, $mac_covered,
        $path) = @_;

    if (ref $node eq 'HASH') {
        return { map {
                    push @$path, $_;
                    my $result = _canonical_floats($node->{$_}, $roundtrips,
                                                   $carrier, $reject,
                                                   $reject_scalar, $mac_covered,
                                                   $path);
                    pop @$path;
                    $_ => $result;
                } keys %$node };
    }
    if (ref $node eq 'ARRAY') {
        return [ map {
                    push @$path, $_;
                    my $result = _canonical_floats($node->[$_], $roundtrips,
                                                   $carrier, $reject,
                                                   $reject_scalar, $mac_covered,
                                                   $path);
                    pop @$path;
                    $result;
                } 0 .. $#$node ];
    }

    # Blessed leaves (JSON::PP::Boolean) and anything else with a reference are
    # not floats and must reach the emitter untouched -- unless the caller's
    # emitter says it cannot write this one faithfully.
    if (ref $node) {
        $reject->($node, _leaf_location($path)) if $reject;
        return $node;
    }
    return $node unless defined $node;

    # A boolean sentinel, before the kind ladder. It publishes IOK, so
    # _sv_kind calls it an int and the guard below would ask the emitter about
    # every boolean in every document -- an emit and a reparse per leaf, to
    # arrive at "yes, it writes it faithfully". detect_type calls it a bool
    # (k90), both emitters write a bare true/false, and that token is what
    # the digest's True/False resolves from: nothing here to repair or refuse.
    # No text is derived on the way past, for the same reason the string branch
    # below derives none -- the handler's check has its own gate and its own
    # call to the one conversion.
    return _written_leaf($node, undef, $reject_scalar, $path)
        if __PACKAGE__->detect_type($node) eq 'bool';

    my $kind = _sv_kind($node);

    # k84: an INTEGER leaf that carries its own string form. detect_type
    # calls it an int, so value_to_bytes derives the digest from the NUMBER,
    # while both emitters write the STRING half -- YAML::XS bare,
    # Cpanel::JSON::XS quoted whenever that half differs from its own rendering
    # of the number. Measured against sops 3.13.3, leaf x_unencrypted:
    #
    #   dualvar(5, 'five')     digest 5   yaml: five     json: "five"   exit 51
    #   dualvar(0, 'zero')     digest 0   yaml: zero     json: "zero"   exit 51
    #   YAML-parsed 007        digest 7   yaml: 007 (0)  json: "007"    exit 51 (json)
    #   YAML-parsed +7 / -0    digest 7/0 yaml: ok (0)   json: quoted   exit 51 (json)
    #
    # The float branch below cannot see any of it: it only runs for a leaf
    # whose SV kind is float, and an int leaf reaches neither callback.
    #
    # ASKED OF THE EMITTER, not modelled. YAML::XS keeps the source text of
    # every scalar it parses, so `007`, `+7`, `-0` and `1e3` all arrive here
    # with a public PV that differs from the canonical decimal -- and YAML
    # writes them back exactly as they came, where Go reads the same number the
    # digest covers (measured, exit 0). Only the emitter can say which of those
    # it survives, which is what $roundtrips already measures for floats.
    #
    # REFUSED rather than repaired, unlike the float leaf one line below (see
    # docs/adr/0011 and 0012). Both halves of such a scalar are a candidate for
    # what the caller meant, the two repairs write different documents, and
    # nothing measurable separates a spelling (`007` for 7) from a
    # contradiction (`five` for 5): dualvar(0, 'zero') numifies to the very
    # number it would be compared against, and pattern-matching a value's text
    # is what ADR 0002 removed. Nothing that worked stops working -- every
    # input that croaks here produced a document that failed its own MAC.
    #
    # Two gates before the emitter is asked, and both are facts about the leaf
    # rather than models of the emitter. It has to carry a PUBLIC PV at all --
    # an int without one is rendered by both emitters from the number itself,
    # which is what the digest covers -- and that PV has to DIFFER from the
    # digest's text, which is the disagreement this guard is about. Every int
    # in a YAML-parsed tree carries a PV (YAML::XS keeps the source text), so
    # without the second gate every one of them would pay an emit-and-reparse:
    # measured, 1000 such leaves cost 11ms -> 38ms in YAML and 2ms -> 10ms in
    # JSON. With it, an ordinary `port: 5432` costs one string comparison.
    if ($kind eq 'int' && _has_public_pv($node)) {
        # THE one conversion again -- the text the digest covers, from the same
        # method on the same scalar. The halves agreeing is the ordinary case
        # and ends here, without asking the emitter anything.
        my $text = __PACKAGE__->value_to_bytes($node);
        return _written_leaf($node, $text, $reject_scalar, $path) if "$node" eq $text;

        croak _leaf_location($path) . ": cannot write an integer leaf that "
            . "carries its own, different string form to a SOPS document: the "
            . "MAC digest covers the NUMBER, while the emitter writes the "
            . "string half -- YAML::XS bare, Cpanel::JSON::XS quoted -- so the "
            . "document and its own MAC would state different things and "
            . "neither sops nor this module could read the file back "
            . "(measured, sops -d exit 51 in both formats). Perl produces such "
            . "a scalar as a Scalar::Util::dualvar, or as a value a YAML "
            . "parser kept the source spelling of. Which half is meant cannot "
            . "be read off the scalar, so it is not guessed: pass 0 + \$value "
            . "to store the number, or \"\$value\" to store the text"
            unless $roundtrips->($node, $text);
        return _written_leaf($node, $text, $reject_scalar, $path);
    }

    # A string leaf, or an integer without a string form of its own: neither is
    # rewritten here, and both still have to survive the reader on the other side
    # of the file. No text is derived for them on the way past -- value_to_bytes
    # encodes, and a handler with a cheap gate of its own should not pay a
    # conversion for every leaf it waves through.
    return _written_leaf($node, undef, $reject_scalar, $path) unless $kind eq 'float';

    # THE one conversion. This is the same method, on the same scalar, that the
    # MAC digest goes through -- not a second rendering that happens to agree
    # today. Do not inline a copy of it here.
    my $text = __PACKAGE__->value_to_bytes($node);

    # NaN and the infinities. The leaf is never REWRITTEN here -- neither the
    # round-trip test nor the carrier can help it, and k113 measured what
    # happens if they are asked: YAML::XS writes the token and libyaml reads it
    # back as a STRING, so $roundtrips answers no for a leaf that is perfectly
    # writable, and the carrier then replaces the document's own `.inf` with a
    # bare `+Inf` -- `sops -d` exit 0 and the leaf silently retyped to a string,
    # in both formats. A local reparse cannot answer a question about a foreign
    # resolver (docs/adr/0013). What changes is only who gets to CHECK it.
    #
    # A leaf whose string half is a token go-yaml resolves back to this same
    # double goes to the handler's foreign-resolution guard, which is the single
    # copy of Go's resolution model (docs/adr/0013 and 0017) and compares the
    # token the emitter really writes. A MAC-covered document whose handler
    # installs no such guard has nothing that can vouch for the leaf, and it is
    # refused rather than written: that is JSON, where a non-finite float has no
    # spelling at all (measured, unencrypted slot, all twelve tokens, `sops -d`
    # exit 51).
    #
    # A leaf with NO string half of its own -- the shape a decrypted type:float
    # arrives in -- has stated no spelling, so one is asked of the emitter and
    # it enters that same verdict carrying it. This used to `return $node`, and
    # the plaintext then said `Inf` where the document held a number
    # (k134, docs/adr/0037). It is the ONLY leaf this manufactures a token
    # for: one that publishes a string half has stated one, and it is left
    # alone whatever it says, so `dualvar(+Inf, 'banana')` is not overwritten on
    # the strength of the number beside it (docs/adr/0012's answer to the same
    # question for an integer, and docs/adr/0031's `banana` row).
    #
    # Nothing a caller can construct becomes writable to a MAC-covered document
    # that was not writable before: assert_representable runs first, from
    # _compute_mac's leaf sweep, and its gate is untouched. A bare NV cannot
    # reach this walk on the encrypt path at all.
    if ($text =~ $NO_AGREED_FORM) {
        # k140: refuse the contradiction the MAC-covered paths already
        # refuse -- a non-finite float whose public PV disagrees with its
        # number. The MAC-covered paths caught it through assert_representable
        # in _compute_mac's leaf sweep, and the mac_covered croak below
        # refuses the JSON case where the handler has no spelling for a
        # non-finite value at all. Only the plaintext emit path silently
        # wrote the string half verbatim, the leaf retyped to str on a later
        # parse, and a decrypt_file -> encrypt_file round trip changed the
        # type without warning.
        #
        # The predicate is the same one assert_representable uses
        # (encrypted => 0 already gates on !_carries_go_non_finite_token, see
        # the k59 message above for the wire-form reasoning). Consulting
        # it here keeps the rule in one place -- the gate does not drift if
        # the wire format changes -- and reaches every caller of the walk:
        # decrypt_file, edit, _serialize_plaintext, and a direct emit() call
        # on a tree the caller constructed.
        #
        # Bare NV leaves are not in scope: _non_finite_token_leaf below
        # manufactures a token PV for them in YAML and croaks in JSON, which
        # is the existing k113 / k134 behaviour. Without that
        # filter here, assert_representable would refuse the bare-NV case
        # that k134 / ADR 0037 made writable.
        if (_has_public_pv($node)) {
            eval { __PACKAGE__->assert_representable($node, encrypted => 0); 1 }
                or croak _leaf_location($path) . ": "
                    . ($@ =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//r);
        }

        $node = _non_finite_token_leaf($node, $text, $carrier, $path)
            unless _has_public_pv($node);
        return _written_leaf($node, $text, $reject_scalar, $path)
            if $reject_scalar;
        return $node unless $mac_covered;

        croak _leaf_location($path) . ": cannot write a non-finite float to "
            . "this SOPS document: the only wire form for one that both "
            . "implementations read back as the same number is a YAML plain "
            . "scalar Go's yaml.v3 resolves to it (`.inf`, `-.inf`, `.nan` and "
            . "their case variants), and the handler writing this document has "
            . "no such form -- JSON has none, so the document would state a "
            . "quoted string where its own MAC covers the number, and neither "
            . "sops nor this module could read the file back (measured, sops "
            . "-d exit 51). Store the value as a string (type:str), which is "
            . "written verbatim and round-trips exactly through both "
            . "implementations, or write the document as YAML";
    }

    # The emitter's own output already comes back as this number: leave the
    # scalar alone, so the document keeps the bytes it has always had.
    return _written_leaf($node, $text, $reject_scalar, $path) if $roundtrips->($node, $text);

    # The CARRIER is what gets written, and $text is what the digest covers --
    # for a negative zero those are `-0.0` and `-0`, and the check needs both.
    return _written_leaf($carrier->($node, $text), $text, $reject_scalar, $path);
}


sub canonical_float_dualvar {
    my ($class, $value) = @_;

    return $value unless defined $value;
    return $value if ref $value;
    return $value unless _sv_kind($value) eq 'float';

    # THE one conversion, again. The string half is the text the wire carries
    # and the digest covers, taken from the same method on the same scalar --
    # never a second rendering that agrees with it today.
    my $text = $class->value_to_bytes($value, 'float');
    return $value if $text =~ $NO_AGREED_FORM;

    return dualvar($value, $text);
}


# Which of Perl's three scalar shapes this is, read off the SV rather than off
# its text. The PUBLIC IOK/NOK flags deliberately, not the private pIOK/pNOK
# that JSON::PP's number heuristic uses: the private ones are set by merely
# READING a string numerically, which would make a caller's `$h{port} > 1024`
# rewrite the document's type fields. The public ones are set less often, but
# not never -- see the contamination note in detect_type's POD.
#
# Nothing on the encrypt path numifies a leaf before this runs. The one thing
# that touches it is _encrypt_tree's `$node eq ''`, which is a string
# comparison: it can set pPOK on a number, never IOK or NOK on a string.
#
# \$_[0] aliases the caller's scalar instead of copying it. Copying preserves
# the flags too, but the alias makes that independent of how Perl chooses to
# implement assignment.
#
# The one place the public IOK is not taken at face value: Perl caches an IV on
# an NV whenever `(NV)(IV)nv == nv`, and for a NEGATIVE ZERO that test passes
# while the sign does not survive the cast -- the IV 0 is a different value from
# the NV -0.0, and the wire has a spelling for each. So a scalar publishing both
# halves is asked which half is the value, not which flag came first. This is
# still the SV deciding (ADR 0002): the NV is read only where it is already
# public, never derived from the text and never numified into existence.
#
# YAML::XS is where such a scalar comes from in practice -- it caches the IV for
# an integral float in EXPONENT notation, so `-0.0e0` arrives IOK+NOK where
# `-0.0` arrives NOK alone. k89, docs/adr/0015.
my $NEGATIVE_ZERO_BITS = pack('d', -0.0);

sub _sv_kind {
    my $sv    = B::svref_2object(\$_[0]);
    my $flags = $sv->FLAGS;
    if ($flags & B::SVf_IOK()) {
        return 'float'
            if ($flags & B::SVf_NOK())
            && pack('d', $sv->NV) eq $NEGATIVE_ZERO_BITS;
        return 'int';
    }
    return 'float' if $flags & B::SVf_NOK();
    return 'str';
}

# Does this scalar carry a string form of its OWN, on top of its number? The
# public SVf_POK again, for the same reason _sv_kind reads the public IOK/NOK:
# merely stringifying a number sets the private pPOK (measured: `my $s = "$i"`,
# `$i eq ''` and `length($i)` all leave SVf_POK clear), and a guard that read
# the private flag would fire on a caller who logged the value.
sub _has_public_pv {
    my $flags = B::svref_2object(\$_[0])->FLAGS;
    return $flags & B::SVf_POK() ? 1 : 0;
}

# strconv.FormatFloat(v, 'f', -1, 64).
#
# 'f' means positional notation, never an exponent. -1 means the shortest
# digit string that parses back to the same float64. Perl's own
# stringification is neither: it is roughly %.15g, so it exponentiates 1e20
# and truncates 0.1+0.2 to 0.3, and both of those disagree with what the Go
# side re-derives when it recomputes the MAC.
#
# The shortest-form test is `0 + "$g"` and NOT the obvious `$g + 0`, which
# numifies $g IN PLACE: the digits then left the loop carrying the double as
# well, so value_to_bytes returned a scalar detect_type called a float -- and
# for a negative zero an INT, since the text `-0` numifies to an IV. Text in,
# a number back out, from the one method whose whole job is to say what the
# wire carries. k72 and k73 are the same mechanism on the input side;
# this is k80 on the output side. Stringifying first numifies a COPY and
# leaves the digits a string, which is what they are.
sub _float_bytes {
    my ($n) = @_;

    # NaN and the infinities, from the one sub that decides what they are --
    # the same answer assert_representable and the emit walk ask for.
    my $non_finite = _non_finite_bytes($n);
    return $non_finite if defined $non_finite;

    my $g;
    for my $precision (1 .. 17) {                   # 17 always round-trips a double
        $g = sprintf('%.*g', $precision, $n);
        last if 0 + "$g" == $n;
    }

    return _expand_exponent($g);
}

# "1.5e-07" -> "0.00000015", "1e+20" -> "100000000000000000000".
sub _expand_exponent {
    my ($s) = @_;
    return $s unless $s =~ /\A([+-]?)(\d+)(?:\.(\d+))?[eE]([+-]?\d+)\z/;

    my ($sign, $int, $frac, $exp) = ($1, $2, $3 // '', $4 + 0);
    my $digits = $int . $frac;
    my $point  = length($int) + $exp;   # where the decimal point lands in $digits

    return $sign . '0.' . ('0' x -$point) . $digits         if $point <= 0;
    return $sign . $digits . ('0' x ($point - length $digits))
        if $point >= length $digits;
    return $sign . substr($digits, 0, $point) . '.' . substr($digits, $point);
}

# The plaintext's crossing from characters into bytes. CryptX takes bytes, so a
# character string arriving at the cipher is either downgraded to Latin-1
# (U+0080..U+00FF) or dies outright with "Wide character in subroutine entry"
# (above U+00FF).
#
# UNCONDITIONAL, by the same argument as _aad_bytes below: for a string whose
# characters are all under U+0100 Perl's UTF-8 flag is storage, not meaning,
# and neither emitter consults it -- YAML::XS::Dump and Format::JSON's encoder
# (utf8) write "caf\x{e9}" as caf\xc3\xa9 whichever way Perl is holding it.
# Under the old flag-guarded rule an unflagged "caf\x{e9}" reached the wire as
# caf\xe9, which is not UTF-8 at all, with two measured consequences: an
# UNENCRYPTED value went into the document as UTF-8 and into the digest as
# Latin-1, so the file failed its own MAC and sops reported "MAC mismatch";
# and an encrypted one was self-consistent but came back out of `sops -d` as
# `!!binary Y2Fm6Q==` rather than as café. See ADR 0003.
#
# The cost is a caller who passes UTF-8 BYTES rather than characters: their
# plaintext is now double-encoded, because Perl cannot tell that scalar apart
# from an unflagged Latin-1 string and the ambiguity has to be resolved the
# same way everywhere. Note the emitters were already double-encoding such a
# caller's unencrypted values, so this was never a whole guarantee. A caller
# who really means bytes says so with type => 'bytes', which skips this
# entirely (see value_to_bytes).
sub _utf8_bytes {
    my ($str) = @_;
    return $str unless defined $str;
    utf8::encode($str);   # no-op for ASCII, correct for the rest
    return $str;
}

# The AAD's crossing, which has always been unconditional and is where the rule
# above came from.
#
# The AAD is derived from the document's key path, and the key it names is
# written to the file by YAML::XS::Dump / Format::JSON's encoder (utf8). Both of
# those encode a key to UTF-8 whether or not it carries Perl's UTF-8 flag,
# because for a string whose characters are all below U+0100 that flag is an
# internal storage detail and not a statement about the string's meaning. So
# "caf\x{e9}" is written to the file as the five bytes caf\xc3\xa9 no matter how
# Perl happens to be holding it, and the AAD has to say the same thing.
#
# Under a flag-guarded rule it did not: an unflagged "caf\x{e9}" authenticated
# against caf\xe9: while the emitter wrote caf\xc3\xa9, so the very next read of
# our own file re-derived the UTF-8 form and the document failed its own MAC.
# Matching the emitter is what makes the AAD single-valued for a given
# document, and it is also what Go does, where a map key is UTF-8 by
# construction. The value conversion above now says the same thing about the
# same scalar; a document cannot hold two answers to that question.
sub _aad_bytes {
    my ($aad) = @_;
    return '' unless defined $aad;
    utf8::encode($aad);   # unconditional: no-op for ASCII, correct for the rest
    return $aad;
}

sub _deserialize_value {
    my ($data, $type) = @_;

    # SOPS's binary type. Not text, so there is nothing to decode -- see the
    # boundary note in the decrypt_value POD.
    return $data if $type eq 'bytes';

    # Go reads this back with strconv.Atoi, so int64 is the whole range, and
    # anything outside it stops sops with "value out of range". int() would
    # instead route it through a double and hand back a DIFFERENT number
    # without saying so -- the silent half of the same defect. Refuse, and
    # leave decrypt_bytes as the way to recover the digits.
    if ($type eq 'int') {
        croak "type:int plaintext is not an integer"
            unless $data =~ /\A[+-]?[0-9]+\z/;
        croak "type:int plaintext is outside the int64 range "
            . "($INT64_MIN .. $INT64_MAX); sops refuses such a value too "
            . "(\"strconv.Atoi: value out of range\"). "
            . "Use decrypt_bytes to recover the plaintext."
            unless _decimal_fits_int64($data);
        return 0 + $data;
    }
    # Go reads this back with strconv.ParseFloat, which fails on anything that
    # is not a number. Perl's numeric conversion turns it into 0 and says
    # nothing.
    if ($type eq 'float') {
        croak "type:float plaintext is not a number"
            unless $data =~ /\A[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)
                             (?:[eE][+-]?[0-9]+)?\z/x
                || $data =~ /\A[+-]?(?:Inf(?:inity)?|NaN)\z/i;

        # NOT `$data + 0.0`. That addition hands back a scalar carrying the
        # PUBLIC SVf_IOK flag whenever the result is integral -- grok_number
        # settles a text like `2` as an integer and pp_add calls SvIV_please --
        # so detect_type called the value an int and the next write relabelled
        # a leaf the document itself had marked type:float. Measured on a
        # document sops wrote: three of five type:float leaves came back
        # type:int after our rotate, exit 0 both times, silently (k73).
        #
        # pack 'd' lays the scalar's numeric value out as a native double and
        # unpack builds a fresh SV from those bytes with sv_setnv, so the
        # result is NOK and nothing else. It is also float64 whatever this
        # Perl's NV is, which is the width Go's strconv.ParseFloat works in.
        # No arithmetic form does this: `0.0 + $data` and `$data * 1.0` set IOK
        # too, and a dualvar INHERITS it from its numeric argument. See ADR
        # 0009.
        my $number = unpack('d', pack('d', $data));

        # strconv.ParseFloat("-0", 64) is NEGATIVE zero in Go. The conversion
        # above still is not: grok_number settles the text -0 as an INTEGER
        # zero, which has no sign to keep, so pack sees a plain 0 and measured
        # hands back a POSITIVE zero -- exactly as `+ 0.0` did before it, which
        # additionally lost the sign a second time to IEEE round-to-nearest
        # (-0.0 + 0.0 is +0.0). So the sign has to come back from the
        # plaintext, which is the only place it survived.
        #
        # The MAC does not catch this -- the digest covers decrypt_bytes, the
        # plaintext "-0", not what this returns -- so every document involved
        # verified while our own rotate turned a sops-written `negzero: -0`
        # into `negzero: 0`, exit 0, both formats (k72).
        #
        # Reading a value's TEXT is what ADR 0002 forbids; this is not that.
        # The type is not being guessed here, it came from the type: label on
        # the wire, and $data is authenticated plaintext this module just
        # decrypted, not a caller's scalar. The condition is "negative sign,
        # and the conversion produced a zero", so a negative underflow such as
        # -1e-400 lands on -0 too, which is what Go parses it to.
        if ($data =~ /\A-/) {
            # The zero test runs on a THROWAWAY copy, and that is load-bearing.
            # Perl's == calls SvIV_please on an NV whose value is integral and
            # sets the PUBLIC IOK flag in place, so comparing $number itself
            # retypes it: measured, a type:float plaintext of 0.0 came back as
            # a value detect_type calls int, and the next write relabelled the
            # leaf type:int. ADR 0002, from the other side.
            my $is_zero = $number;
            return -0.0 if $is_zero == 0;
        }

        return $number;
    }

    if ($type eq 'bool') {
        # SOPS uses "True"/"False" (titlecase)
        # Return JSON::PP::Boolean to preserve bool type through YAML/JSON serialization
        return (lc($data) eq 'true' || $data eq '1') ? JSON->true : JSON->false;
    }

    # str, time and comment are all text on the wire, and all come back as the
    # text they are.
    #
    #   time    -- Go stores a time.Time as RFC3339, which is what the
    #              plaintext holds. Measured against sops 3.13.3: a bare
    #              `2026-08-09T12:00:00Z` and a bare `2026-08-09` both become
    #              type:time, the latter as `2026-08-09T00:00:00Z`. Perl has no
    #              native date, and handing back a DateTime would make this
    #              module a data-model library, so the RFC3339 string is the
    #              value. It is also what the YAML and JSON parsers give the
    #              caller for the same scalar when it is NOT encrypted, so the
    #              document reads consistently either way.
    #   comment -- a YAML comment. sops attaches a comment to the node that
    #              FOLLOWS it, so where that node is a MAPPING entry the comment
    #              stays a `#ENC[...]` line, which YAML::XS drops before this
    #              module sees it. Where it is a SEQUENCE entry there is no
    #              comment line to write and sops emits the comment as a real
    #              sequence element, `- ENC[...,type:comment]` -- so File::SOPS
    #              very much does meet one through a document, and read it as an
    #              ordinary value until k108. It comes back as a
    #              File::SOPS::Comment and NOT as the text, which is the whole
    #              of how a comment is kept apart from a value: an object
    #              nothing here compares equal to a string, the same move
    #              type:bool makes with JSON::PP::Boolean. k76,
    #              docs/adr/0041, which supersedes docs/adr/0024's refusal.
    #
    # utf8::decode leaves the scalar alone and returns false if the plaintext
    # is not valid UTF-8, which is the graceful direction -- such a value comes
    # back as the bytes it was.
    if ($type eq 'str' || $type eq 'time' || $type eq 'comment') {
        utf8::decode($data);
        return $type eq 'comment'
            ? File::SOPS::Comment->new(text => $data)
            : $data;
    }

    # Everything else used to fall through to the branch above and return the
    # raw string, so a document this library could not actually interpret
    # looked like it had been read. Go stops here, and so do we.
    croak "Unknown datatype: $type";
}

sub _encode_base64_oneline {
    my ($data) = @_;
    my $encoded = encode_base64($data, '');
    return $encoded;
}

# The only source of random bytes in this distribution. Both things that must
# never repeat come from here: the per-value GCM nonce above, and the data key
# in File::SOPS::encrypt, which calls this directly. It lived in both files
# once, byte-identical; nothing made them stay that way.
#
# The length check is not defensive noise, and it is the reason this is a sub
# at all rather than a bare call. A short return is invisible to everything
# downstream of it -- measured here against CryptX 0.087 and sops 3.13.3:
#
#   * A data key truncated to 16 or 24 bytes is a valid AES-128 or AES-192
#     key. Encryption succeeds, our own decrypt succeeds, and `sops -d`
#     accepts the document and exits 0. The key is silently weaker than the
#     one every part of the system believes it is using, and no error exists
#     anywhere to say so.
#   * An IV truncated to anything from 1 to 31 bytes is accepted by GCM
#     identically at both ends, because the nonce length is not fixed by the
#     construction. A 1-byte nonce also round-trips through `sops -d` with
#     exit 0 -- from an 8-bit space, so it repeats under the same data key
#     within a couple of hundred values, which is the one thing GCM does not
#     survive.
#
# Only two short lengths fail on their own: a data key that is not 16, 24 or
# 32 bytes, and an IV of exactly 0 bytes. Both fail inside CryptX as "FATAL:
# ccm_memory failed: Invalid key size" attributed to the gcm call, naming
# neither the CSPRNG nor which of the two values was short. Nothing else in
# either implementation looks at these lengths, so this is the only place that
# can look at them.
#
# Crypt::PRNG is not optional and there is no fallback: it ships in CryptX,
# the same distribution as the Crypt::AuthEnc::GCM this module already loads at
# compile time, so an install missing it cannot compile this file. The
# /dev/urandom branch that used to stand here was unreachable, and if it had
# ever been reached it would have downgraded a seeded CSPRNG to an unchecked
# read without telling anyone.
sub _random_bytes {
    my ($length) = @_;

    my $bytes = Crypt::PRNG::random_bytes($length);

    # Lengths only. The bytes themselves are the data key or the nonce, and an
    # error message is something a user pastes into a bug report.
    croak "Refusing to use the result: Crypt::PRNG::random_bytes($length) "
        . "returned "
        . (defined $bytes ? length($bytes) . " bytes" : "undef")
        . ". A wrong length here becomes a data key or a GCM nonce of that "
        . "length, which neither this implementation nor sops rejects."
        unless defined $bytes && length($bytes) == $length;

    return $bytes;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::SOPS::Encrypted - Parse and generate SOPS encrypted values

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use File::SOPS::Encrypted;

    # Parse an encrypted value string
    my $enc = File::SOPS::Encrypted->parse(
        'ENC[AES256_GCM,data:xyz,iv:abc,tag:def,type:str]'
    );

    # Check if a string is encrypted
    if (File::SOPS::Encrypted->is_encrypted($string)) {
        my $decrypted = $enc->decrypt_value(key => $data_key, aad => $path);
    }

    # Encrypt a value
    my $enc = File::SOPS::Encrypted->encrypt_value(
        value => 'secret',
        key   => $data_key,
        aad   => 'database:password',
    );

    # Get encrypted string representation
    my $string = $enc->to_string;
    # => ENC[AES256_GCM,data:...,iv:...,tag:...,type:str]

=head1 DESCRIPTION

File::SOPS::Encrypted handles parsing and generation of SOPS encrypted value
strings. Each encrypted value in a SOPS file is represented as:

    ENC[AES256_GCM,data:base64,iv:base64,tag:base64,type:str]

Values are encrypted with AES-256-GCM using:

=over 4

=item * A shared data key (32 bytes, encrypted separately for each recipient)

=item * A random initialization vector (IV) per value (32 bytes -- see L</iv>)

=item * Additional Authenticated Data (AAD) derived from the value's path

=item * Type preservation (str, int, float, bool, bytes)

=back

=head2 algorithm

Encryption algorithm. Currently only C<AES256_GCM> is supported. Defaults to C<AES256_GCM>.

=head2 data

Encrypted ciphertext as raw bytes. Required.

=head2 iv

Initialization vector (IV) as raw bytes, B<32 bytes>. Required.

Note that this is deliberately B<not> the conventional 12-byte (96-bit) AES-GCM
nonce. The SOPS reference implementation generates a 32-byte nonce and builds
its cipher with Go's C<cipher.NewGCMWithNonceSize>, so 32 bytes is part of the
on-the-wire format rather than a choice this module is free to make. AES-GCM
derives its initial counter block differently for non-96-bit nonces (the nonce
is folded through GHASH instead of being used directly), which means an IV of a
different length does not merely look unusual -- it produces a value the Go
implementation cannot authenticate, and vice versa.

C<encrypt_value> generates 32 random bytes accordingly. Do not "correct" this
to 12.

=head2 tag

Authentication tag as raw bytes, 16 bytes for AES-GCM. Required.

=head2 type

Original value type for deserialization. One of C<str>, C<int>, C<float>,
C<bool>, C<bytes>, C<time> or C<comment> -- the seven the reference
implementation writes. Anything else makes L</decrypt_value> die with
C<Unknown datatype>, as Go does; until 0.003 it silently returned the raw
plaintext, so a document this module could not actually interpret looked like
it had been read.

C<time> is read but never produced here: it is Go's C<time.Time>, stored as
RFC3339 and returned as that string, because Perl has no native date type.

C<comment> is a YAML comment, and since 0.003 it is both read and written. sops
attaches one to the node that B<follows> it: above a mapping key it stays a
C<#ENC[...]> line, which L<YAML::XS> discards, but above a B<sequence entry>
sops writes it as a real sequence element (C<- ENC[...,type:comment]>) and every
parser keeps it. Such a leaf is not a value, so it has a Perl value of its own
-- L<File::SOPS::Comment> -- which L</decrypt_value> hands back, L</detect_type>
types, and the MAC digest leaves out. Before 0.003 the leaf was read as an
ordinary string, which failed MAC verification and, under
C<ignore_mac =E<gt> 1>, put a value in the caller's list that the file does not
contain. See
L<docs/adr/0041|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0041-a-sops-comment-is-a-leaf-of-its-own-not-a-value-and-not-a-refusal.md>.

Defaults to C<str>.

=head2 parse

    my $enc = File::SOPS::Encrypted->parse($string);
    # Returns undef if $string is not encrypted

Parses a SOPS encrypted value string.

Takes a string like C<ENC[AES256_GCM,data:...,iv:...,tag:...,type:str]> and
returns a File::SOPS::Encrypted object with decoded attributes.

Returns C<undef> if the string is not in the encrypted format.

B<Dies if the string has the shape but not the content>: a C<data>, C<iv> or
C<tag> field that is not valid standard base64 -- a character outside the
alphabet, or a length that is not a multiple of four. L<MIME::Base64> silently
drops what it cannot read, so such a field used to decode to something shorter
and fail much later, as C<Authentication failed - data may be corrupted> or as
a cipher rejecting the nonce length. Go decodes with C<base64.StdEncoding>,
which fails immediately and names the problem.

L</is_encrypted> is unaffected and never dies: it answers about the B<shape>,
which is what decides whether a value is a candidate for decryption at all.

=head2 is_encrypted

    if (File::SOPS::Encrypted->is_encrypted($string)) {
        # It's an encrypted value
    }

Class method to check if a string is in SOPS encrypted format.

Returns true if the string matches the C<ENC[...]> pattern.

=head2 encrypted_type

    my $type = File::SOPS::Encrypted->encrypted_type($string);
    # 'str', 'int', 'comment', ... or undef

Class method. Returns the C<type:> label of an C<ENC[...]> string without
decoding its base64 fields, or C<undef> if the string is not an encrypted value.

It shares one anchored pattern with L</is_encrypted> and L</parse>, and it
answers for a value whose ciphertext is damaged -- which L</parse> does not,
because it decodes. That is the case it exists for: a C<type:comment> leaf has
to be recognised as a comment before anyone tries to decrypt it.

=head2 is_comment

    if (File::SOPS::Encrypted->is_comment($value)) { ... }

Class method. True for a L<File::SOPS::Comment>, which is what a B<plaintext>
tree holds where the document holds a comment. False for everything else,
C<undef> and every other reference included.

It is the predicate behind L</detect_type>'s C<comment> rung, kept as a method
of its own because the MAC walk has to ask the same question without asking for
a type. It is B<not> true for an C<ENC[...,type:comment]> string -- that is what
the file says a leaf is, which L</encrypted_type> answers, and on the encrypt
side such a string is an ordinary string a caller passed.

See L<docs/adr/0041|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0041-a-sops-comment-is-a-leaf-of-its-own-not-a-value-and-not-a-refusal.md>.

=head2 to_string

    my $string = $enc->to_string;
    # => ENC[AES256_GCM,data:xyz==,iv:abc==,tag:def==,type:str]

Serializes the encrypted value to SOPS string format.

Returns a string representation with base64-encoded components.

=head2 encrypt_value

    my $enc = File::SOPS::Encrypted->encrypt_value(
        value => 'secret',
        key   => $data_key,        # 32 bytes
        aad   => 'database:password',  # Additional Authenticated Data
        type  => 'str',            # optional, auto-detected
    );

Class method to encrypt a value.

Encrypts a scalar value using AES-256-GCM with a random IV. Returns a
File::SOPS::Encrypted object.

The C<aad> (Additional Authenticated Data) is typically the path to the value
in the data structure (e.g., C<database:password:>), used to prevent value
substitution attacks.

Both C<value> and C<aad> are B<always> encoded to UTF-8 before they reach the
cipher, which is what the Go implementation authenticates against, and
B<neither consults Perl's UTF-8 flag>. For a string whose characters are all
below U+0100 that flag is an internal storage detail rather than a statement
about meaning: C<"caf\x{e9}"> may be held as one byte or as two, Perl considers
both the same string, and C<YAML::XS::Dump> and the JSON emitter (built with
C<utf8>) write both to the file as C<caf\xc3\xa9>. Anything that reads the flag
therefore disagrees with the bytes our own emitter wrote, which is a document
that fails its own MAC.

The exception is C<type =E<gt> 'bytes'>, SOPS's binary type, which is passed
through untouched -- and which is how a caller says that a scalar really is
bytes rather than characters. See L</value_to_bytes> and
L<docs/adr/0003|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0003-value-encoding-is-unconditional-like-the-aad.md>.

B<Known limitation as of sops 3.13.3:> a document that contains a C<type:bytes>
cell cannot be opened by the reference implementation. C<sops -d> exits 2 with
C<panic: runtime error: hash of unhashable type []uint8> in C<aes/stashKey> on
the very first such leaf -- measured against sops 3.13.3 on YAML, dotenv and
INI, on payloads of "hello" and a 4-byte blob, all identical. The label is what
trips it: the same payload under C<type:str> reads back at exit 0. No sops store
produces a C<type:bytes> cell (YAML's C<!!binary> and the binary input store
both surface as C<type:str>), so this is a sops-side bug we can only warn
about: a caller who uses the documented C<type =E<gt> 'bytes'> escape hatch
above writes a document sops cannot open in any format, as of 3.13.3. The
B<read> path is unaffected -- a foreign C<type:bytes> cell decrypts correctly
through L</decrypt_value> -- because the panic is sops's own aes cache, keyed by
plaintext, refusing to index on a byte slice. See k136 and the "Known
limitation" section of
L<docs/adr/0003|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0003-value-encoding-is-unconditional-like-the-aad.md>.

Type is auto-detected from the value if not specified, by L</detect_type>.

Passing C<type> explicitly overrides the B<label> only, never the bytes: those
always come from what the value is. C<encrypt_value(value =E<gt> '007', type
=E<gt> 'int')> writes the label C<int> and the plaintext C<007>, because a
Perl string is written verbatim. That is how you reproduce a document some
other producer wrote; it is not how you write C<007> as an integer, which no
SOPS implementation does (see L</value_to_bytes>).

Dies if the value is one no SOPS document can carry -- today, an integer wider
than Go's C<int64>. See L</assert_representable>.

A B<non-finite float> (C<NaN>, C<+Inf>, C<-Inf>) B<is written>, in both
formats, as C<type:float> and the plaintext L</value_to_bytes> derives from the
number. That is what C<sops -e> stores for a plain C<.inf>, C<-.inf> or C<.nan>
-- measured against sops 3.13.3, six documents, C<--output-type yaml> and
C<--output-type json> alike, exit 0 with C<type:float> on the wire in both.
Every release before this one refused it here. See L</assert_representable>,
k122 and
L<docs/adr/0040|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0040-an-encrypted-slot-carries-a-non-finite-float-because-sops-writes-one.md>.

This method passes C<encrypted =E<gt> 1> to L</assert_representable>, which it
may because it B<is> the encrypted slot. The one non-finite shape still refused
is a scalar that states a string half contradicting its number, which an
encrypted slot would drop without a trace.

Dies if the value's plaintext is B<empty> (which includes C<undef>). GCM
ciphertext is the length of its plaintext, so the result would be an
C<ENC[AES256_GCM,data:,...]> that neither L</parse> nor sops accepts -- sops
stops with C<Input string ENC[...] does not match sops' data format>. Until
0.003 such a string was built and returned. Empty values belong in the document
unencrypted, which is what sops does with them and what L<File::SOPS/encrypt>
does before calling this.

=head2 decrypt_bytes

    my $bytes = $enc->decrypt_bytes(
        key => $data_key,  # 32 bytes
        aad => 'database:password:',
    );

Decrypts the value and returns the authenticated plaintext B<as raw bytes>,
with no type conversion and B<no character decoding> applied.

C<aad> is UTF-8 encoded before verification by the same unconditional rule
L</encrypt_value> uses, so the two sides derive the same AAD from the same key
path however Perl happens to be storing it.

This is what the MAC is computed over. L</decrypt_value> runs the same bytes
through a type conversion (C<0 + $x>, C<unpack('d', pack('d', $x))>,
C<JSON::PP::Boolean>) whose inverse is not exact in Perl: C<'007'> comes back
as C<7>, C<'1.50'> as C<1.5>, and the C<100000000000000000000> that Go writes
for C<1e20> restringifies as C<1e+20>. Feeding a re-serialization of the
converted value to the digest therefore produces a different hash than the one
the producer computed over the plaintext. Anything hashing a decrypted value
must use this method, not L</decrypt_value> -- the one exception being
C<type:bool>, where SOPS's C<ToBytes> titlecases whatever spelling it parsed,
so the caller normalises C<true>/C<false> to C<True>/C<False>.

Dies if authentication fails (wrong key, corrupted data, or mismatched AAD).

=head2 decrypt_value

    my $value = $enc->decrypt_value(
        key => $data_key,  # 32 bytes
        aad => 'database:password',
    );

Decrypts the encrypted value.

Returns the decrypted value with type conversion applied (int, float, bool
are converted to appropriate Perl types) and, for textual types, B<decoded
from UTF-8 into a character string> -- the inverse of what L</encrypt_value>
accepted. This is the Perl-facing side of the boundary; L</decrypt_bytes> is
the wire side and is what anything feeding a digest must use.

C<type:bytes> is the one exception: it is SOPS's binary type, so it is returned
as raw bytes with nothing decoded. A C<type:str> whose plaintext is not valid
UTF-8 is also returned as bytes rather than being mangled.

C<type:comment> comes back as a L<File::SOPS::Comment> and B<not> as its text,
because a comment is not a value: an object cannot be mistaken for a string by
a caller walking the tree, and it is what tells L<File::SOPS/encrypt> to write
the leaf back as a comment. Until 0.003 this returned the text.

A C<type:float> value comes back as a scalar Perl calls a float B<even when its
digits spell a whole number>, so C<detect_type> still says C<float> and the
next write keeps the C<type:float> label the document already carried. The
conversion is C<unpack('d', pack('d', $plaintext))> rather than C<+ 0.0>,
because the addition sets the public C<SVf_IOK> flag on an integral result and
that flag is what L</detect_type> reads: a C<whole: 2.0> written by sops came
back out of our own C<rotate> as C<type:int>, in both formats, at exit 0 and
without a word. See k73 and
L<docs/adr/0009|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0009-a-decrypted-float-comes-back-as-a-float.md>.

That conversion is a C<float64>, as Go's is, so a plaintext carrying more
integer precision than a double can hold comes back rounded to the double Go
also reads -- C<9007199254740993> as C<9007199254740992>. L</decrypt_bytes>
still returns the plaintext digits verbatim.

A C<type:float> plaintext of C<-0> comes back as a B<negative> zero, which is
what Go's C<strconv.ParseFloat> returns for it and what the document meant.
Neither conversion gets there on its own: both settle that text as an integer
zero, which has no sign to keep, and C<+ 0.0> additionally lost it a second
time to IEEE round-to-nearest (C<-0.0 + 0.0> is C<+0.0>). Nothing in Perl shows the difference -- C<==> and C<print>
cannot tell the two zeroes apart -- but L</value_to_bytes> can, so the value
writes back out as C<-0> where it used to write C<0> and silently change a
document sops itself had produced. See k72.

Dies if authentication fails (wrong key, corrupted data, or mismatched AAD).

Also dies, rather than guessing, on a plaintext that does not match its label:

=over 4

=item * a C<type:int> plaintext that is not a decimal integer, or is one Go's
C<strconv.Atoi> would refuse -- that is, outside C<int64>. Until 0.003 that
went through Perl's C<int()>, which is exact up to C<2**64-1> on a 64-bit Perl
and silently rounds above it, so the same document produced one answer here and
C<value out of range> in sops.

=item * a C<type:float> plaintext that is not a number, which Perl's numeric
conversion turns into C<0> without a word and C<strconv.ParseFloat> rejects.

=item * an unrecognised C<type:> altogether -- C<Unknown datatype>, as Go says.

=back

L</decrypt_bytes> still returns the authenticated plaintext in every one of
those cases, which is how a value is recovered from such a file.

=head2 detect_type

    my $type = File::SOPS::Encrypted->detect_type($value);
    # => 'str' | 'int' | 'float' | 'bool' | 'comment'

Class method. Returns the SOPS type of a Perl scalar, B<from the scalar
itself> rather than from a pattern match on its text.

=over 4

=item * a L<File::SOPS::Comment> is C<comment>

=item * a L<JSON::PP::Boolean> (C<JSON-E<gt>true>, C<JSON-E<gt>false>, or a
C<true>/C<false> loaded by L<YAML::XS> or L<JSON::MaybeXS>) is C<bool>

=item * a scalar B<Perl itself marks as a boolean> -- C<!!1>, C<!!0>,
C<$x E<gt> 3>, C<builtin::true>, any comparison's result -- is C<bool> too,
on perl 5.36 and newer. See below.

=item * a scalar Perl holds as an integer is C<int>

=item * a scalar Perl holds as a floating point number is C<float>

=item * a B<negative zero> is C<float>, even where Perl also holds an integer
for it -- the one place a scalar's two numeric halves contradict each other and
the integer half is the wrong one. See below.

=item * everything else, including every string, is C<str>

=back

This is the rule the Go implementation uses -- it takes the type from what the
YAML/JSON parser returned -- and both parsers this distribution uses preserve
the distinction, so a quoted scalar is a string end to end. Measured against
sops 3.13.3: bare C<false> is C<type:bool>, but C<"false">, C<"true">, C<"1">,
C<"0">, C<"007"> and C<"1.50"> are B<all> C<type:str>.

The corollary is that Perl's own literals decide the type for a structure
passed straight to L<File::SOPS/encrypt>: C<5432> is C<int> and C<'5432'> is
C<str>. The string C<'true'> is a string.

Past Perl's own integer limit both parsers hand this ladder the same shape,
and in a B<JSON> document that is new. A bare integer literal too wide for an
C<IV> or a C<UV> -- C<100000000000000000000>, C<-9223372036854775809> --
arrives as the double carrying its source spelling, a
L<Scalar::Util/dualvar> publishing C<NOK> and C<POK>, so the C<float> rung
answers it. L<YAML::XS> has always returned that; until 0.003
L<Cpanel::JSON::XS> returned a plain string SV instead, bit-identical to the
same digits B<quoted>, so one number was a C<float> read out of a YAML
document and a C<str> read out of a JSON one -- and L<File::SOPS/rotate>
wrote a JSON B<string> where the reference had written a number. There is no
big integer in the SOPS data model: past C<int64> a JSON number is a
C<float64> to Go, and sops 3.13.3 writes such a leaf as C<type:float> in an
encrypted slot and rounds it to its own double in an unencrypted one, so
C<float> is the reference's answer too. A B<quoted>
C<"100000000000000000000"> is unaffected and stays a C<str>; the two are told
apart at parse time by the decoder's own type map, never by a pattern match
on the text. See k63 and
L<docs/adr/0020|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0020-a-json-number-perl-cannot-hold-is-a-float-not-a-string.md>.

The same leaf reaches this ladder one magnitude lower, where the limit crossed
is B<Go's> and not Perl's. A bare JSON literal in C<[2**63 .. 2**64-1]> is a
C<UV> to Perl and a C<float64> to Go, so C<sops -e> normalises it before this
library ever sees the file -- C<9223372036854775808> is written back as
C<9223372036854776000> -- and marks it C<type:float> in an encrypted slot and
an unencrypted one alike (measured, sops 3.13.3, twelve literals across the
window, both slots). L<File::SOPS::Format::JSON> hands such a literal over as
the same dualvar, so the C<float> rung answers it and L</assert_representable>'s
C<int64> refusal -- which used to make L<File::SOPS/rotate> croak on a document
sops itself had written -- is not reached. The window is JSON's alone: C<yaml.v3>
resolves those digits as a C<uint64> sops cannot walk at all, so no such YAML
document exists to read, and one built by hand is still refused. A caller's own
Perl C<UV> in the window is still refused as well -- no parser has spoken for
it, so calling it a float would be this library guessing. See k101 and
L<docs/adr/0021|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0021-a-json-number-go-cannot-hold-is-a-float-not-a-refusal.md>.

Perl has no boolean B<type>, but since 5.36 it has a boolean B<SV>, and that
is what C<type:bool> reads on a plain scalar. C<!!1>, C<!!0>, C<$x E<gt> 3>,
C<'a' eq 'a'>, C<defined $x> and C<builtin::true> all produce it, the mark
survives assignment and storage in a hash, and both emitters write such an SV
as a bare C<true>/C<false>. It is asked for through C<builtin::is_bool>, which
is the same predicate the emitters use -- a C<Scalar::Util/dualvar> carrying
C<1> and C<'1'> is indistinguishable from C<!!1> in every public flag, and is
B<not> a boolean to any of the three. On a perl older than 5.36 there is no
such SV, and there C<type:bool> still needs a L<JSON::PP::Boolean> or an
explicit C<type>.

Until 0.003 such a scalar was an C<int>: the digest covered C<1>/C<0> while the
document said C<true>/C<false>, so C<File::SOPS-E<gt>encrypt(data =E<gt> {
admin =E<gt> ($user-E<gt>{level} E<gt> 3) })> wrote a file that failed its own
MAC. See k90 and
L<docs/adr/0016|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0016-perls-own-boolean-is-a-bool-not-an-int.md>.

Note that Perl marks a scalar as numeric B<in place> the first time it is used
in numeric context, so C<if ($cfg-E<gt>{port} E<gt> 1024)> before encrypting
turns C<'8080'> into an C<int>. See
L<docs/adr/0002|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0002-value-type-comes-from-the-scalar-not-from-a-pattern.md>.

A B<negative zero> is the one exception to reading the integer flag first, and
it exists because that in-place marking is not harmless for this value. Perl
caches an integer on a float whenever the cast round-trips, and for C<-0.0> it
decides the cast round-trips while the B<sign does not survive it>: the cached
integer is C<0>, which is a different number on the wire (C<0> against C<-0>)
and a different MAC digest. So a scalar publishing both halves is asked which
half it is, and for this one value the answer is the float.

The route in is ordinary code, in both directions. C<YAML::XS> caches that
integer for an integral float written in B<exponent> notation, so C<-0.0e0>,
C<-0e0> and C<-0.000e2> arrive here carrying it where C<-0.0> does not; and any
C<$v E<gt> 1>, C<$v == 0> or C<int($v)> on a caller's own C<-0.0> sets it
before C<encrypt> ever sees the tree. Until 0.003 that turned the value into a
C<0> in the document -- and for the YAML spellings into a file C<sops -d>
rejected with C<MAC mismatch>. See k89 and
L<docs/adr/0015|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0015-a-negative-zero-is-a-float-even-when-perl-cached-an-integer-on-it.md>.

=head2 integer_fits_int64

    File::SOPS::Encrypted->integer_fits_int64($value)   # 1 or 0

Class method. True where C<$value> is inside Go's C<int64> range --
C<-9223372036854775808 .. 9223372036854775807> -- which is the only range the
SOPS C<int> type covers, and false where Perl holds an integer Go cannot.
Perl's integers are unsigned-capable and reach C<2**64-1>, so that window is
real: see L</assert_representable> for what this distribution refuses to
B<write> there, and L<File::SOPS/Integers are Go's int64, and Perl's are
wider> for why.

It exists so that a format handler can ask the question without spelling the
boundary a second time. A JSON document can carry a bare integer literal in
that window -- C<sops -e> writes one itself, having normalised it through the
C<float64> Go reads it as -- and telling that leaf apart from an ordinary
C<port: 5432> is a decision the JSON parser makes per leaf. Two copies of a
constant are this distribution's signature defect: when they drift they are
wrong B<together>, so the wire bytes stay self-consistent and only the
reference implementation disagrees.

B<C<$value> must be a scalar Perl holds as an integer> -- one L</detect_type>
calls an C<int>. That is not checked here, deliberately: the caller's own
flag test is the cheap fact and has to come first, and a second type ladder
inside this method is exactly what ADR 0002 removed. Neither other kind is
answered correctly. A B<float> of exactly C<2**63> answers true, because the
comparison promotes C<2**63-1> to a double and the two become the same
number. A decimal B<string> is worse -- C<'-9223372036854775809'> numifies to
exactly C<-2**63> and answers true to a value Go refuses -- which is why the
text form of this test is a separate, private one that reads digits and never
numifies.

=head2 assert_representable

    File::SOPS::Encrypted->assert_representable($value);
    File::SOPS::Encrypted->assert_representable($value, encrypted => 1);

Class method. Dies if C<$value> is something no SOPS document can carry, and
returns true otherwise. Called for every leaf L<File::SOPS/encrypt> is about to
write -- encrypted or not -- before anything is emitted.

C<encrypted> says which slot the leaf is going into, and defaults to false,
which is the stricter answer. It changes exactly one of the checks below, the
non-finite float: an encrypted slot's wire form for one is C<type:float> and
the plaintext L</value_to_bytes> writes, which is what C<sops -e> stores in
B<both> formats, so the emitters' inability to spell the number says nothing
about that slot. The two callers inside this distribution supply it from what
they structurally know -- L</encrypt_value> is the encrypted slot, and
L<File::SOPS>'s MAC sweep asks
L<File::SOPS::Metadata/should_encrypt_path>. See
L<docs/adr/0040|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0040-an-encrypted-slot-carries-a-non-finite-float-because-sops-writes-one.md>.

There are three such values today:

=over 4

=item B<An unblessed reference.> C<\1>, C<\$x>, C<\@arr>, C<\%hash>, C<sub {}>.
B<detect_type> calls a reference C<str>, so L</value_to_bytes> would digest
its stringification -- C<SCALAR(0x...)>, C<ARRAY(0x...)>, C<HASH(0x...)> or
C<CODE(0x...)>, the ref's heap address. _encrypt_tree would feed that same
address into the encrypted slot, and the document would verify against itself
(doc and digest agree on the address) but store a value that differs per run
and is meaningless on a later read. The pre-fix code wrote the file silently
and the caller had no reason to notice; that is the defect k67 exists to
close. A blessed object B<passes>: ADR 0008 measured that an encrypted
L<Math::BigFloat>, an object overloading C<"">, and a L<Regexp> all
round-trip correctly today -- they have a stringification the caller chose,
which is exactly what an encrypted slot carries. The exception is the same
class B<detect_type> uses for the digest, which is C<blessed($v)> and so
covers any subclass: the encrypted-slot rule and the unencrypted-slot guard
asked the same question in different ways and the encrypted slot is the
looser one.

=item B<A non-finite float:> C<NaN>, C<+Inf>, C<-Inf> -- B<unless it carries
go-yaml's own token for that double>. L</value_to_bytes> writes them as
C<NaN> / C<+Inf> / C<-Inf> -- the same text Go's C<strconv.FormatFloat>
produces -- but no emitter derives that text from the B<number>: Cpanel's
JSON encoder writes C<null> (the document is silently rounded), JSON::XS
writes bare C<inf> (invalid JSON, sops refuses with C<invalid character i>),
and YAML::XS writes a bare C<Inf> / C<-Inf> / C<NaN>, which Go's yaml.v3
resolves as a B<string>. Measured against sops 3.13.3 in an unencrypted YAML
slot, C<Inf> is C<sops -d> exit 51 and C<-Inf> / C<NaN> are exit 0 with the
leaf silently retyped from a float to a string -- which is worse, not
better. The pre-fix code wrote the file anyway, and the caller had no reason
to notice; that is the defect k59 exists to close.

B<Narrowed since 0.003> (k113, C<docs/adr/0031>): a scalar that also
carries, as its own string half, one of the twelve plain tokens go-yaml
resolves to exactly that double -- C<.inf>, C<+.Inf>, C<-.INF>, C<.nan> and
their case variants -- B<is> written, in an unencrypted YAML slot. That is
the shape L<File::SOPS::Format::YAML/parse> produces for a document sops
wrote (C<docs/adr/0026>), and refusing it left this library reading a
document it could not write back: C<rotate> croaked on a file C<sops -d>
reads at exit 0. Measured, all twelve tokens: C<sops -e> E<gt>
C<File::SOPS-E<gt>rotate> E<gt> C<sops -d> exit 0, the wire byte-identical.

Both halves have to agree. C<dualvar(+Inf, '-.inf')> is a contradiction and
stays refused, the same answer C<docs/adr/0012> gives an integer whose halves
disagree, and so does any other spelling -- C<.INf> and C<+.nan> are strings
to sops, and a C<dualvar(+Inf, 'banana')> would put a document on disk that
fails its own MAC. This check is a B<gate>: whether the document being
written can really carry the token is answered where the format is known, by
the foreign-resolution guard C<docs/adr/0013> installs in the YAML handler.
A JSON document has no such spelling in an unencrypted slot (measured,
C<sops -d> exit 51) and is refused there.

B<Everything in this item is about the UNENCRYPTED slot>, which is the only
one whose leaf reaches the document as a token. With C<encrypted =E<gt> 1>
the value is written instead: the wire carries C<type:float> and the
plaintext C<+Inf> / C<-Inf> / C<NaN>, in both formats, which is what
C<sops -e> writes for the same value (k122, C<docs/adr/0040>). The one
exception is a scalar that B<states> a string half its number contradicts --
C<dualvar(+Inf, 'banana')>, or the JSON literal of 400 zeros whose text is
its digits -- because the encrypted slot is derived from the number and that
text would be dropped without a trace.

Store the value as a B<string> instead where none of that applies -- that is
C<type:str>, written verbatim, and the same number (or its deliberate
stringification) is round-tripped exactly through both implementations.
Reading is unaffected: a C<type:float> plaintext of C<+Inf> or C<NaN> is
accepted by L</decrypt_value> today, and sops itself writes such a value, so
the read path has to keep accepting it.

Since 0.003 a B<parsed document> can reach this guard on its own, where the
route in used to be Perl code or a YAML C<.inf>: a bare JSON integer literal
that overflows a double -- C<1> followed by 400 zeros -- is a C<float>
(L</detect_type>) whose value is C<+Inf>, and it used to be read as a string
and written back as one. The croak is the closer answer, because sops
refuses that document itself and one step earlier, at unmarshal time
(measured, sops 3.13.3, exit 2, C<strconv.ParseFloat: value out of range>).

=item B<An integer outside Go's C<int64> range.> Perl's integers reach
C<2**64-1>, Go's C<int> stops at C<2**63-1>, and the reference implementation
writes C<type:int> only within that range. Measured against sops 3.13.3, a
wider integer produces a document it will not read:

=over 4

=item * encrypted, it is C<type:int> with a plaintext C<strconv.Atoi> rejects
-- C<sops -d> stops with C<value out of range>

=item * unencrypted, it reaches the document verbatim, and C<sops -d> either
refuses to walk it (YAML: C<unknown type: uint64>) or recomputes the digest
from the C<float64> it parsed and reports C<MAC mismatch> (JSON)

=back

sops's own JSON store truncates such an integer to a C<float64> and writes the
truncated value. File::SOPS does not: a value silently losing digits on its way
through a library whose job is to preserve it is the defect this method exists
to prevent. Store the digits as a B<string> instead -- that is C<type:str>,
written verbatim, and it round-trips exactly through both implementations.

Since 0.003 the message offers a B<second> answer, because since ADR 0021 there
is one: hand the guard the double instead, C<unpack('d', pack('d', $value))>,
and the leaf takes the C<float> rung and gets exactly what sops writes for the
same digits -- C<type:float> and the double's canonical decimal -- at the cost
of the digits the double cannot hold. It is an answer and not a promise: 12
literals across the window in both formats and both slots gave 41 of 48 cells
C<sops -d> exit 0, and 7 -- all of them B<unencrypted YAML> -- refused here by
ADR 0013's guard instead, because the decimal L</value_to_bytes> makes the
emitter write there is one C<yaml.v3> resolves as a C<uint64>. C<$value + 0.0>
is B<not> that conversion: Perl keeps the integer and the value lands back on
this croak.

The window is positive-only, and structurally so: C<SVf_IOK> means the SV
carries an C<IV> or a C<UV>, an C<IV> bottoms out at exactly C<int64min> and a
C<UV> cannot be negative, so B<no integer SV exists below the range>. Measured
for k104 across 14 negative decimals bracketing C<int64min> and
C<uint64max> and 13 construction routes each: 182 rows, 36 of them C<int>, and
not one below C<int64min>. Below the range a value arrives as a C<float> (or a
string) and takes the C<float> rung instead (ADR 0020).

=back

This is a B<write>-side rule only. Reading is unaffected: sops's truncated
C<12345678901234567000> parses back as a Perl integer above C<int64>, and
L</value_to_bytes> must still hash it as those digits or a legitimate sops
document would fail verification. An older file this library itself wrote
under 0.003 with an unblessed ref in an encrypted slot is read back as the
heap address that was stored, which is unrecognisable but verifiable; the
guard refuses the B<new> write and leaves the read path alone.

=head2 value_to_bytes

    my $bytes = File::SOPS::Encrypted->value_to_bytes($value);
    my $bytes = File::SOPS::Encrypted->value_to_bytes($value, $type);

Class method. Returns the wire plaintext for a value: the bytes that get
encrypted, and the bytes the MAC digest is taken over. Those are the same
bytes by definition, which is why there is one method and not two -- the
ciphertext and the digest disagreeing is this distribution's signature defect,
and it is invisible from inside Perl because both sides are then consistently
wrong.

C<$type> defaults to L</detect_type>. It selects the boolean spelling and
nothing else; the bytes always come from the value:

=over 4

=item * a boolean is C<True> or C<False> (SOPS titlecases them)

=item * a comment (L<File::SOPS::Comment>) is its text, verbatim -- what sops
puts after the C<#>, leading space included

=item * an integer is its canonical decimal form -- Perl's C<0 + $value>,
which is what Go's C<strconv.Itoa> writes

=item * a float is C<strconv.FormatFloat($v, 'f', -1, 64)>: the shortest
decimal that round-trips, in positional notation and never in exponent
notation. Measured against sops 3.13.3, which stores C<1.0> as C<1>, C<1.50>
as C<1.5>, C<.5> as C<0.5> and C<1e20> as C<100000000000000000000>

=item * anything else, including every string, is written verbatim

=back

C<type =E<gt> 'bytes'> is the one type that is B<not> UTF-8 encoded on its way
out, mirroring L</decrypt_value>, which does not decode it either. It is
SOPS's binary type, so it is not text, and it is the only way to tell this
module that an unflagged scalar really is a byte string rather than a Perl
string that happens to be stored as bytes -- a distinction Perl itself does not
make. Everything else is encoded unconditionally; see L</encrypt_value>.

B<Sops 3.13.3 cannot read a document that contains a C<type:bytes> cell.> The
write-side escape hatch this paragraph describes therefore produces a document
sops cannot open in any format -- exit 2 with C<panic: runtime error: hash of
unhashable type []uint8> in C<aes/stashKey>, on the first such leaf, regardless
of payload. The label is what trips it. See L</encrypt_value> for the full
warning, and k136.

So a Perl string is never renormalised -- C<'007'> stays C<007> and C<'1.50'>
stays C<1.50> -- while a Perl number always is. A document that gets this
wrong is not merely odd-looking: Go recomputes the MAC by re-serializing the
value it parsed out of the plaintext, so C<007> stored under C<type:int>
digests as C<7> on the reading side and C<sops -d> rejects the whole file.

That renormalisation now reaches a wide B<JSON> integer literal as well. Such
a leaf carries B<both> halves -- the double and its own digits, which is what
either parser returns past Perl's integer limit (see L</detect_type>) -- and
the bytes come from the number, so C<99999999999999999999> is written as
C<100000000000000000000>. Inside the range a sops-written document can carry,
that costs nothing: the digits sops writes are already the double's canonical
decimal, so the two texts are the same string and the digest does not move at
all (measured against sops 3.13.3, every positional literal it writes). A
B<hand-written> literal that is not its double's canonical decimal does move
-- to exactly the value C<sops -e> rounds the identical document to itself.

Character strings are UTF-8 encoded on the way out, by the same unconditional
rule L</encrypt_value> documents.

=head3 In an untyped store these bytes are also what the emitter writes

For YAML and JSON the emitter and the digest legitimately write different text:
C<Format::YAML> writes a bare C<true> where this method returns C<True>, and
that is correct, because go-yaml parses C<true> back into a boolean and Go
re-derives C<True> from it.

B<The flat formats have no such reader.> ENV and INI carry no type syntax, so
sops hands the digest the literal text of the line -- and for an
B<unencrypted> leaf, where there is no C<type:> label either, the document
verifies only if the text written B<is> the text this method returns.
docs/adr/0035 therefore decides that the ENV and INI emitters (k36,
k37) write exactly what this method returns, and refuse nothing for its
type.

That is not a divergence dressed up as one. Measured against sops 3.13.3, one
document per row, both formats, both slots: B<the C<sops_mac> plaintext is
SHA-512 of this method's output on every row of the ladder> -- C<True>, C<1>,
C<-0>, C<100000000000000000000>, the empty string for a null. sops's own
emitter then writes a B<display> form into the unencrypted slot for three of
them and cannot read the file back:

    value       sops wrote      digest covers   sops -d
    true        true            True            MAC mismatch, exit 51
    null        <nil>           (empty)         exit 51 -- and exit 25 in an
                                                encrypted slot, where the
                                                placeholder reaches the file raw
    1.0         1.0             1               exit 51
    1e20        1E+20           100000000000000000000   exit 51
    -0.0        -0.0            -0              exit 51
    42          42              42              exit 0
    1.5         1.5             1.5             exit 0

Writing this method's output instead leaves the digest exactly where it is and
repairs the one line that disagreed with it: each of those texts is a line sops
itself writes for the corresponding string, and a document carrying it reads
back at exit 0. The cost is that an unencrypted flat-format value loses its
type on the way back -- a boolean returns as the string C<True>, an integer as
C<"42"> -- which is what sops's own untyped reader does to every value in that
slot. See k124 and k125, and
L<docs/adr/0035|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0035-an-untyped-stores-unencrypted-leaf-is-written-as-the-bytes-the-digest-covers.md>.

The B<type label> needs no format rule at all: an ENV or INI parser hands the
walk plain string SVs, so L</detect_type> answers C<str> for the whole document
by itself, which is what makes C<sops -e> on a plaintext C<.env> write
C<type:str> for C<NUM=5>. A typed source keeps its types in a flat document in
both implementations alike.

The return is a B<plain string> -- a scalar carrying its text and not the
number that text spells. This matters to a caller who feeds the result back in:
L</detect_type> reads the SV and not the characters (ADR 0002), so a return
still carrying its numeric half went back onto the wire as C<type:float>, or as
C<type:int> for the text C<-0>, where the caller meant the C<type:str> they
were holding. k80; the bytes were never affected, only what the scalar
says it is.

=head2 canonical_float_tree

    my $tree = File::SOPS::Encrypted->canonical_float_tree(
        $data,
        roundtrips => sub { my ($value, $text) = @_; ... },
        carrier    => sub { my ($value, $text) = @_; ... },
    );

Class method. Returns a B<copy> of C<$data> in which every float leaf that the
caller's emitter cannot write faithfully has been replaced by a carrier holding
the canonical decimal from L</value_to_bytes> -- the same text the MAC digest
covers.

This exists because the digest and the document have to state the same number.
L</value_to_bytes> writes a float as Go's
C<strconv.FormatFloat($v, 'f', -1, 64)>, up to 17 significant digits, while
every emitter in this distribution renders a double with 15. For a value that
needs 16 or 17 the document said one number and the digest covered another, and
the file failed its own MAC. See
L<docs/adr/0006|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0006-floats-are-emitted-in-a-form-that-parses-back-to-the-same-double.md>.

Two callbacks, both given the original scalar and its canonical text:

=over 4

=item * C<roundtrips> answers whether the emitter's own rendering of this value
parses back to the same value. It must B<measure> that -- emit and reparse --
rather than model it, which is what keeps this correct if an emitter changes.
Returning true leaves the scalar untouched, so a value the emitter already
writes faithfully keeps exactly the bytes it has today.

It is asked about two leaf classes. For a B<float> a false answer selects the
carrier below. For an B<integer that carries its own, different string form> --
a L<Scalar::Util/dualvar>, or a value a YAML parser kept the source spelling of
-- a false answer is a B<refusal>: L</detect_type> calls such a leaf an C<int>,
so the digest covers the number, while both emitters write the string half, and
the document then fails its own MAC (measured, C<sops -d> exit 51 in both
formats). It is refused rather than repaired because both halves are a
candidate for what the caller meant and nothing measurable separates a spelling
(C<007> for C<7>) from a contradiction (C<five> for C<5>). The emitter is asked
only where the two halves actually differ; an C<int> whose string half is the
digest's text costs one string comparison. See k84 and
L<docs/adr/0012|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0012-an-integer-leaf-whose-string-half-disagrees-is-refused.md>.

=item * C<carrier> returns the replacement, and is format-specific: L<YAML::XS>
emits a L<Scalar::Util/dualvar>'s string half verbatim and unquoted, while
every JSON backend quotes it and needs a L<Math::BigFloat> under
C<allow_bignum> instead.

=item * C<reject> is optional and is called as C<< $reject->($leaf, $where) >>
for every blessed or otherwise referenced leaf, so a handler can refuse one its
emitter cannot write as the text the digest covers. C<$where> is that leaf's
key path, colon-joined, or the string C<(document root)> -- the same shape the
MAC walk's own messages use, with array indices carried because this is a
diagnostic and not an AAD. Both handlers put it in front of their message, so
one bad leaf in a large document is named rather than searched for (k68).
L</detect_type> calls every reference but a
L<JSON::PP::Boolean> C<str>, so the digest covers its stringification, and an
emitter that writes something else instead produces a document that fails its
own MAC. Both handlers use it: L<File::SOPS::Format::YAML> refuses every
reference except an exact L<JSON::PP::Boolean>, because L<YAML::XS> writes the
rest as C<!!perl/> tagged structures; L<File::SOPS::Format::JSON> refuses
every reference except an exact L<JSON::PP::Boolean>, for the same reason --
under C<allow_bignum> Cpanel::JSON::XS writes a Math::BigFloat or Math::BigInt
as a bare number and an unblessed C<\1> / C<\0> as bare C<true> / C<false>.
Both messages name the class or ref kind and never the value; the exception
is the exact class (a C<JSON::PP::Boolean> subclass is refused the same way
C<detect_type> accepts it -- the guard's question is what the emitter can
write). See
L<docs/adr/0008|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0008-a-leaf-the-emitter-cannot-write-as-what-the-digest-covers-is-refused.md>
(k65 on the YAML side, k66 closing the known gap on the JSON side).

=item * C<reject_scalar> is optional and is called as
C<< $reject_scalar->($leaf, $where, $path, $text) >> for every plain scalar leaf
on its way out -- the leaf B<as it will be written>, so a carried float arrives
as the carrier rather than as the scalar it replaced. C<$where> is the same
key-path string C<reject> is given; C<$path> is that path as an array reference,
for a handler that has to answer a question about B<where> in the document the
leaf sits rather than only report it. C<$text> is the text the MAC digest covers
-- the walk passes the one it already derived, which for a carried float is the
B<original> value's, and leaves it C<undef> for a leaf it never converted, so a
handler with a cheap gate of its own does not pay a conversion per string.

This is the one hook that asks about a B<reader> instead of about this
distribution's own emitters. A document's leaves are resolved again by whoever
opens the file, and where that resolver disagrees with L</detect_type> the
document and its own MAC state different things -- Go's C<yaml.v3> reads a
leading-zero integer as octal and C<0o10>, C<0x1f>, C<1_000>, C<.inf>, C<Null>
and C<2015-01-01> as numbers, an infinity, a null and a timestamp, where
L<YAML::XS> reads all of them as this module's type. L<File::SOPS::Format::YAML>
installs it on the encrypt path only. See
L<docs/adr/0013|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0013-a-yaml-spelling-the-go-parser-resolves-differently-is-refused.md>
(k86).

Where C<$text> is C<undef> a handler takes it from L</value_to_bytes>, on the
leaf it was handed. It must not render one itself: that is the second conversion
this whole walk exists to avoid.

=back

The canonical text is B<not> recomputed by the caller and must not be: a second
conversion is how the ciphertext and the digest came to disagree in the first
place, and it is invisible from inside Perl because both sides are then
consistently wrong.

Call this at B<emit time, on a copy, after the digest has been taken>. The
walk that computes the MAC must never see a carrier: the L<Math::BigFloat> one
is a blessed reference, which L</detect_type> calls C<str>, so the digest would
cover its stringification instead of the number.

C<NaN>, C<+Inf> and C<-Inf> never go through C<roundtrips>. That callback
reparses with this side's own parser, which reads C<.inf> back as a string, so
it answers no for a leaf that is perfectly writable, and the carrier would then
be handed C<+Inf> as the text and write a bare C<+Inf> -- a document C<sops -d>
reads at exit 0 with the leaf silently retyped to a string.

What the walk does with one depends on whether anything can vouch for it. A
non-finite leaf whose B<string half> is a plain token go-yaml resolves back to
that same double -- C<.inf>, C<-.inf>, C<.nan> and their case variants, the
shape a sops-written YAML document parses to (C<docs/adr/0026>) -- is passed to
C<reject_scalar>, whose model of the foreign resolver is the one that decides.
In a document that carries a MAC and whose handler installed no C<reject_scalar>
the leaf is B<refused>, naming the key path: that is JSON, where a non-finite
float has no spelling at all (measured, C<sops -d> exit 51 unencrypted, exit 4
encrypted). See
L<docs/adr/0031|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0031-a-non-finite-float-that-carries-go-yamls-own-token-is-written.md>
(k113).

A non-finite leaf with B<no string half of its own> -- the shape a decrypted
C<type:float> arrives in, and a bare C<9**9**9> -- has stated no spelling, so
one is asked of C<carrier>: it is called with C<.inf>, C<-.inf> or C<.nan>, and
the leaf it returns is accepted only if it carries that token as its public
string half and still renders as the same bytes. The YAML carrier answers with
a C<dualvar>, which L<YAML::XS> writes as the bare token; the JSON carrier
croaks, and the leaf is B<refused> naming the key path, as C<sops -d
--output-type json> and C<sops edit> refuse the same document (exit 4). So
C<decrypt_file> reproduces sops's own C<.inf> byte for byte for an B<encrypted>
C<type:float> as well as for an unencrypted slot, where it used to write C<Inf>
and turn the leaf into a string on the next read. A leaf that does publish a
string half keeps it, whatever it says. See
L<docs/adr/0037|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0037-a-non-finite-float-is-written-as-a-token-or-not-at-all.md>
(k134).

Whether the document carries a MAC is read off the tree this walk is handed: a
handler's C<serialize> puts the metadata under C<sops> before calling its
emitter, and the plaintext emitters hand over the tree without one. The YAML
handler also says so by installing C<reject_scalar>, but the JSON handler's
C<emit> is the identical call on both paths.

A negative zero I<is> carried, and it is the one case where the carrier's text
is not the canonical decimal: C<value_to_bytes> writes C<-0>, which Go's
yaml.v3 resolves as an B<integer> and digests as C<0>. The rule ADR 0006 states
is that the emitted decimal has to B<parse back to the same double>, not that
it has to be spelled canonically, so the YAML carrier writes C<-0.0>. See
L<File::SOPS::Format::YAML/emit>.

=head2 canonical_float_dualvar

    my $value = File::SOPS::Encrypted->canonical_float_dualvar($value);

Class method. Returns C<$value> with its stringification replaced by the
canonical decimal from L</value_to_bytes> -- numerically the same double, as a
string the text the document actually contains. Anything that is not a plain
float scalar comes back untouched: a reference, C<undef>, a string, an int, a
boolean, and a non-finite float, whose C<NaN> / C<+Inf> / C<-Inf> are wire
spellings rather than a number's decimal.

This exists because a decrypted float is a bare NV with no string form of its
own, so Perl renders it at 15 significant digits: an encrypted
C<0.30000000000000004> printed as C<0.3>, where C<sops -d --extract> prints all
17. See k61 and
L<docs/adr/0010|https://github.com/Getty/p5-file-sops/blob/main/docs/adr/0010-extract-returns-a-float-that-prints-all-its-digits.md>.

B<Only for a value on its way out to a caller.> The result is a
L<Scalar::Util/dualvar>, and a dualvar inside a tree changes the bytes the
emitters write. Not the value and not the type -- both formats write the
canonical decimal as a B<number>, measured, C<sops -d> exit 0 reading the same
double (L<YAML::XS> writes the string half verbatim; L<Cpanel::JSON::XS> quotes
it, which sends the leaf to the L<Math::BigFloat> carrier that writes it bare,
k78 / ADR 0011). What changes is the B<spelling>: this text is always
positional, where an emitter's own rendering switches to an exponent at the
extremes, so C<1e300> is written as 301 digits and C<1e-7> as C<0.0000001> --
in both formats. Correct documents, different bytes from the same value passed
as a plain number. L<File::SOPS/extract> therefore calls this on the single
leaf it returns and on nothing else; L<File::SOPS/decrypt> and
L<File::SOPS/decrypt_file> do not call it at all.

The digest is unaffected either way: L</detect_type> reads C<SVf_NOK> before
C<POK>, so a dualvar is still a C<float>, and L</value_to_bytes> re-derives the
identical text from its numeric half.

=head1 SEE ALSO

=over 4

=item * L<File::SOPS> - Main SOPS interface

=item * L<File::SOPS::Comment> - the leaf a C<type:comment> value becomes

=item * L<Crypt::AuthEnc::GCM> - AES-GCM implementation from CryptX

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
