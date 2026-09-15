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

sub scrub_string {
    my ($text) = @_;
    for my $pattern (@PATTERNS) {
        my ($label, $regex) = @$pattern;
        $text =~ s/$regex/[$label FILTERED]/g;
    }
    return $text;
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
