package ForgeOps::Tracker::PiiScrubber;

use strict;
use warnings;
use Exporter qw(import);

# Redacts likely-sensitive content out of a payload before it ever leaves this process: the
# same patterns ForgeOps itself applies again on arrival (defense in depth: this layer keeps the
# data off the wire and out of any request logging in between; the server-side layer is what
# actually protects the database). Ported from app/services/pii_scrubber.rb: same key list, same
# 8 regex patterns, same "[LABEL FILTERED]" replacement format, same REDACTED constant.
# Deliberately does NOT support Project#additional_sensitive_keys: confirmed server-side only
# (see that file's own header comment: extending the pattern list to arbitrary customer regexes is
# a ReDoS risk best kept out of every client).
our @EXPORT_OK = qw(scrub scrub_string REDACTED);

use constant REDACTED => '[FILTERED]';

my @SENSITIVE_KEYS = qw(
    password passwd pwd
    secret apisecret clientsecret secretkey
    token accesstoken refreshtoken apikey apitoken authorization authtoken bearer sessiontoken csrftoken
    creditcard cardnumber cardnum cvv cvv2 cvc
    iban accountnumber routingnumber bankaccount
    ssn socialsecuritynumber socialsecurity
    privatekey
);

# Order matters no more than it does in any other port: each pattern is applied independently
# to the same string, left to right, same as every other language's version.
my @PATTERNS = (
    ['EMAIL',        qr/[a-zA-Z0-9._%+-]+\@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/],
    ['SSN',           qr/\b\d{3}-\d{2}-\d{4}\b/],
    ['CREDIT CARD',   qr/\b\d{4}[ -]\d{4}[ -]\d{4}[ -]\d{1,4}\b/],
    ['BEARER TOKEN',  qr/\bBearer\s+[A-Za-z0-9\-._~+\/]+=*/i],
    ['JWT',           qr/\bey[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b/],
    ['AWS KEY',       qr/\bAKIA[0-9A-Z]{16}\b/],
    ['STRIPE KEY',    qr/\b[sr]k_(?:live|test)_[A-Za-z0-9]{10,}\b/],
    ['GITHUB TOKEN',  qr/\bgh[pousr]_[A-Za-z0-9]{20,}\b/],
);

# scrub($value, $key): $value may be a scalar, an arrayref, or a hashref (Perl's own equivalent
# of Ruby's Hash/Array/String/other dispatch). $key is the enclosing hash key $value was found
# under (undef for a bare top-level value, or an array element), and is what the key-name check
# runs against, mirroring app/services/pii_scrubber.rb's own recursive `scrub` exactly.
sub scrub {
    my ($value, $key) = @_;

    if (_is_sensitive_key($key) && defined $value) {
        return REDACTED;
    }

    my $ref = ref $value;
    if ($ref eq 'HASH') {
        return { map { $_ => scrub($value->{$_}, $_) } keys %$value };
    }
    elsif ($ref eq 'ARRAY') {
        return [ map { scrub($_, $key) } @$value ];
    }
    elsif ($ref eq '' && defined $value) {
        return scrub_string($value);
    }

    return $value;
}

# Card numbers in any other shape, and IBANs: see sdks/PII_SCRUBBING.md, which every SDK follows,
# and sdks/pii_scrubbing_vectors.json (a copy is in t/fixtures), which pins the results. Word
# characters and digits are spelled out as ASCII classes: on a character string Perl's own \w, \d
# and \b are Unicode-aware, and the rule is ASCII only.
my $DIGIT_RUN = qr/(?<![A-Za-z0-9_])[0-9](?:[ -]?[0-9])*(?![A-Za-z0-9_])/;
my $CARD_PREFIXES = qr/\A(?:4|5[1-5]|2(?:22[1-9]|2[3-9][0-9]|[3-6][0-9][0-9]|7[01][0-9]|720)|3[47]|6011|64[4-9]|65|35(?:2[89]|[3-8][0-9])|36|30[0-5]|62)/;
my $IBAN = qr/(?<![A-Za-z0-9_])[A-Z]{2}[0-9]{2}(?:[A-Z0-9]{11,30}|(?: [A-Z0-9]{4}){2,7}(?: [A-Z0-9]{1,4})?)(?![A-Za-z0-9_])/;

sub scrub_string {
    my ($text) = @_;
    # IBANs first: a spaced IBAN's middle groups look like a formatted card number.
    $text =~ s/($IBAN)/_is_iban($1) ? '[IBAN FILTERED]' : $1/ge;
    for my $pattern (@PATTERNS) {
        my ($label, $regex) = @$pattern;
        $text =~ s/$regex/[$label FILTERED]/g;
    }
    $text =~ s/($DIGIT_RUN)/_scrub_card_numbers_in($1)/ge;
    return $text;
}

# From each group of the run on, the longest stretch of whole groups that is a card number is
# replaced, so a card followed by its CVV, two cards in a row, and Amex's 4-6-5 are all found.
sub _scrub_card_numbers_in {
    my ($run) = @_;
    my @parts = split /([ -])/, $run;
    my (@digits, @separators);
    while (@parts) {
        push @digits, shift @parts;
        push @separators, @parts ? shift @parts : '';
    }

    my $out = '';
    my $i = 0;
    while ($i < @digits) {
        my $found;
        for (my $last = $#digits; $last >= $i; $last -= 1) {
            if (_is_card_number(join '', @digits[$i .. $last])) {
                $found = $last;
                last;
            }
        }
        if (defined $found) {
            $out .= '[CREDIT CARD FILTERED]' . $separators[$found];
            $i = $found + 1;
        }
        else {
            $out .= $digits[$i] . $separators[$i];
            $i++;
        }
    }
    return $out;
}

sub _is_card_number {
    my ($digits) = @_;
    my $length = length $digits;
    return $length >= 13 && $length <= 19 && $digits =~ $CARD_PREFIXES && _passes_luhn($digits);
}

sub _passes_luhn {
    my ($digits) = @_;
    my $sum = 0;
    my $index = 0;
    for my $char (reverse split //, $digits) {
        my $value = ord($char) - ord('0');
        if ($index % 2) {
            $value *= 2;
            $value -= 9 if $value > 9;
        }
        $sum += $value;
        $index++;
    }
    return $sum % 10 == 0;
}

# The IBAN check, a digit at a time: the first four characters moved to the end, letters as two
# digits (A is 10), and the remainder by 97 is 1.
sub _is_iban {
    my ($candidate) = @_;
    (my $compact = $candidate) =~ s/ //g;
    my $length = length $compact;
    return 0 unless $length >= 15 && $length <= 34;

    my $rearranged = substr($compact, 4) . substr($compact, 0, 4);
    my $remainder = 0;
    for my $char (split //, $rearranged) {
        my $number = $char =~ /\A[A-Z]\z/ ? ord($char) - 55 : $char;
        for my $digit (split //, $number) {
            $remainder = ($remainder * 10 + ord($digit) - ord('0')) % 97;
        }
    }
    return $remainder == 1;
}

sub _is_sensitive_key {
    my ($key) = @_;
    return 0 unless defined $key;

    my $normalized = lc $key;
    $normalized =~ s/[^a-z0-9]//g;

    for my $sensitive (@SENSITIVE_KEYS) {
        return 1 if index($normalized, $sensitive) >= 0;
    }
    return 0;
}

1;
