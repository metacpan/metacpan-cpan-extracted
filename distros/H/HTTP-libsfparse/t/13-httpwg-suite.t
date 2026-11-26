#!perl

# The HTTP Working Group's conformance suite for Structured Field Values,
# vendored in t/structured-field-tests/. Each JSON file holds an array of test
# records; see that directory's README.md for the format, and LICENSE.md for
# the terms it is included under.
#
# The suite describes expected values as JSON, which cannot represent the
# Structured Fields types directly, so both sides are reduced to the same
# tagged form before comparison: [ $kind, $value ]. That keeps a token from
# comparing equal to a string of the same characters, and an integer from
# comparing equal to a decimal.
#
# This module reports dictionary and parameter keys as they appear, so both
# sides also have the RFC's rule for a repeated key applied before they are
# compared; see resolve_duplicates() below.

use strict;
use warnings;

use File::Basename qw( dirname );
use File::Spec ();
use Test2::V0;

eval { require JSON::PP; JSON::PP->VERSION('2.27103'); 1 }
    or plan skip_all => 'JSON::PP is required for the httpwg test suite';

eval { require B; 1 }
    or plan skip_all => 'B is required for the httpwg test suite';

use HTTP::libsfparse qw(
    parse_item parse_list parse_dictionary :types :index
);

my $suite_dir = $ENV{SF_TESTS_DIR};

if ( !defined $suite_dir ) {
    $suite_dir
        = File::Spec->catdir( dirname($0), 'structured-field-tests' );
}

# Read the directory rather than globbing it: a glob pattern would split a
# build path that contains a space.
opendir my $dh, $suite_dir
    or plan skip_all => "no test suite in $suite_dir: $!";

my @files = sort grep { /\.json\z/ } readdir $dh;

closedir $dh;

plan skip_all => "no test suite found in $suite_dir" unless @files;

# ---------------------------------------------------------------------------
# Reading the suite's JSON
# ---------------------------------------------------------------------------

# A JSON number is an integer or a decimal depending on how it was written:
# 1 and 1.0 are different Structured Fields types but the same Perl number.
# JSON::PP leaves the distinction in the scalar's flags, so read it there,
# before anything stringifies or numifies the value.
sub json_scalar_kind {
    my $flags = B::svref_2object( \$_[0] )->FLAGS;

    return 'integer' if $flags & B::SVp_IOK();
    return 'decimal' if $flags & B::SVp_NOK();
    return 'string';
}

# The suite carries byte sequences as base32 (RFC 4648), not base64.
sub base32_decode {
    my ($encoded) = @_;

    my %value;
    @value{ split //, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567' } = 0 .. 31;

    ( my $text = uc $encoded ) =~ s/=+\z//;

    my $bits = '';

    for my $char ( split //, $text ) {
        die "unexpected base32 character '$char'\n"
            unless exists $value{$char};

        $bits .= sprintf '%05b', $value{$char};
    }

    # The final partial group is padding, not data.
    return pack 'B*', substr $bits, 0, int( length($bits) / 8 ) * 8;
}

# ---------------------------------------------------------------------------
# One canonical form for decimals, reached from either side
# ---------------------------------------------------------------------------

sub normalise_decimal {
    my ($text) = @_;

    # RFC 9651 decimals never need an exponent, so a number that stringified
    # into one has to be written out in full first.
    $text = sprintf '%.3f', $text if $text =~ /[eE]/;

    my ( $sign, $int, $frac ) = $text =~ /\A(-?)([0-9]+)(?:\.([0-9]*))?\z/
        or die "cannot read '$text' as a decimal\n";

    $frac = '' unless defined $frac;
    $frac =~ s/0+\z//;              # 1.100, 1.10 and 1.1 are one value
    $frac = '0' if $frac eq '';     # but keep a digit, as the RFC does
    $sign = '' if $int !~ /[1-9]/ && $frac eq '0';    # no negative zero

    return "$sign$int.$frac";
}

# ---------------------------------------------------------------------------
# Dictionaries and parameter lists
# ---------------------------------------------------------------------------

# RFC 9651 resolves a repeated key by overwriting the earlier value while
# keeping its position, and that is the form the suite's expected values are
# written in. This module reports the members as they appear instead, leaving
# the resolution to the caller, so the suite's rule is applied here.
sub resolve_duplicates {
    my ($pairs) = @_;

    my ( @order, %position );

    for my $pair (@$pairs) {
        my ( $key, $value ) = @$pair;

        if ( defined $position{$key} ) {
            $order[ $position{$key} ] = [ $key, $value ];
        }
        else {
            $position{$key} = scalar @order;
            push @order, [ $key, $value ];
        }
    }

    return \@order;
}

# Both sides end up as pairs resolved the RFC's way, compared member by
# member in field order.
sub canonical_pairs {
    my ($pairs) = @_;

    return resolve_duplicates($pairs);
}

# ---------------------------------------------------------------------------
# The suite's expected structures, reduced to tagged form
# ---------------------------------------------------------------------------

sub expected_bare {
    my ($bare) = @_;

    # An inner list is a JSON array of items.
    return [ 'innerlist', [ map { expected_item($_) } @$bare ] ]
        if ref $bare eq 'ARRAY';

    if ( ref $bare eq 'HASH' ) {
        my $type = $bare->{__type};

        return [ 'token',      $bare->{value} ] if $type eq 'token';
        return [ 'dispstring', $bare->{value} ] if $type eq 'displaystring';
        return [ 'date',   sprintf '%d', $bare->{value} ] if $type eq 'date';
        return [ 'binary', base32_decode( $bare->{value} ) ]
            if $type eq 'binary';

        die "unexpected __type '$type'\n";
    }

    # JSON::PP::Boolean, and anything else blessed, is a boolean.
    return [ 'boolean', $bare ? 1 : 0 ] if ref $bare;

    my $kind = json_scalar_kind($bare);

    return [ 'integer', "$bare" ]                      if $kind eq 'integer';
    return [ 'decimal', normalise_decimal("$bare") ]    if $kind eq 'decimal';
    return [ 'string',  $bare ];
}

sub expected_params {
    my ($params) = @_;

    return canonical_pairs(
        [ map { [ $_->[0], expected_bare( $_->[1] ) ] } @$params ] );
}

sub expected_item {
    my ($item) = @_;

    die "an item should be a bare item and parameters\n"
        unless ref $item eq 'ARRAY' && @$item == 2;

    return [ expected_bare( $item->[0] ), expected_params( $item->[1] ) ];
}

sub expected_structure {
    my ( $header_type, $expected ) = @_;

    return expected_item($expected) if $header_type eq 'item';
    return [ map { expected_item($_) } @$expected ] if $header_type eq 'list';
    return canonical_pairs(
        [ map { [ $_->[0], expected_item( $_->[1] ) ] } @$expected ] )
        if $header_type eq 'dictionary';

    die "unexpected header_type '$header_type'\n";
}

# ---------------------------------------------------------------------------
# This module's structures, reduced to the same tagged form
# ---------------------------------------------------------------------------

sub got_bare {
    my ($value) = @_;

    my ( $type, $bare ) = @{$value}[ SFP_TYPE, SFP_VALUE ];

    return [ 'innerlist', [ map { got_item($_) } @$bare ] ]
        if $type == SFPARSE_TYPE_INNER_LIST;
    return [ 'boolean', $bare ? 1 : 0 ] if $type == SFPARSE_TYPE_BOOLEAN;
    return [ 'integer', "$bare" ]       if $type == SFPARSE_TYPE_INTEGER;
    return [ 'date',    "$bare" ]       if $type == SFPARSE_TYPE_DATE;
    # A decimal never has more than three fractional digits, so "%.3f"
    # recovers every digit the field carried before normalising.
    return [ 'decimal', normalise_decimal( sprintf '%.3f', $bare ) ]
        if $type == SFPARSE_TYPE_DECIMAL;

    # The suite calls a byte sequence "binary".
    return [ 'binary',     $bare ] if $type == SFPARSE_TYPE_BYTESEQ;
    return [ 'string',     $bare ] if $type == SFPARSE_TYPE_STRING;
    return [ 'token',      $bare ] if $type == SFPARSE_TYPE_TOKEN;
    return [ 'dispstring', $bare ] if $type == SFPARSE_TYPE_DISPSTRING;

    die "unexpected type constant '$type'\n";
}

sub got_params {
    my ($params) = @_;

    return canonical_pairs(
        [ map { [ $_->[SFP_KEY], got_bare( $_->[SFP_ITEM] ) ] } @$params ] );
}

sub got_item {
    my ($item) = @_;

    return [ got_bare($item), got_params( $item->[SFP_PARAMS] ) ];
}

sub got_structure {
    my ( $header_type, $field ) = @_;

    return got_item( parse_item($field) ) if $header_type eq 'item';

    return [ map { got_item($_) } @{ parse_list($field) } ]
        if $header_type eq 'list';

    return canonical_pairs(
        [ map { [ $_->[SFP_KEY], got_item( $_->[SFP_ITEM] ) ] }
                @{ parse_dictionary($field) } ] )
        if $header_type eq 'dictionary';

    die "unexpected header_type '$header_type'\n";
}

# ---------------------------------------------------------------------------
# Check the two readings above against known values before trusting them
# ---------------------------------------------------------------------------

{
    my $probe = JSON::PP->new->decode('[1, 1.0, "42", true, false]');

    is json_scalar_kind( $probe->[0] ), 'integer',
        'a JSON integer is told apart from';
    is json_scalar_kind( $probe->[1] ), 'decimal', '... a JSON decimal, and';
    is json_scalar_kind( $probe->[2] ), 'string',  '... a JSON string';

    is expected_bare( $probe->[3] ), [ 'boolean', 1 ], 'JSON true';
    is expected_bare( $probe->[4] ), [ 'boolean', 0 ], 'JSON false';

    is base32_decode('NBSWY3DP'), 'hello', 'base32, as the suite writes it';
    is base32_decode('MZXW6==='), 'foo',   'base32 with padding';
    is base32_decode(''),         '',      'empty base32';

    is normalise_decimal('1.000'), '1.0', 'decimals are normalised';
    is normalise_decimal('-0.0'),  '0.0', '... including negative zero';
    is normalise_decimal( sprintf '%.3f', 1.001 ), '1.001',
        'and a parsed decimal reads exactly';
    is normalise_decimal( sprintf '%.3f', -1.5 ), '-1.5',
        '... with its sign';
    is normalise_decimal( sprintf '%.3f', 1.0 ), '1.0',
        '... and with trailing zeros removed';
}

# ---------------------------------------------------------------------------
# Run the suite
# ---------------------------------------------------------------------------

my $json = JSON::PP->new->utf8;
my %total = ( pass => 0, rejected_as_required => 0, allowed_failure => 0 );

for my $name (@files) {
    my $file = File::Spec->catfile( $suite_dir, $name );

    subtest $name => sub {
        open my $fh, '<:raw', $file or die "cannot read $file: $!";
        my $cases = $json->decode( do { local $/; <$fh> } );
        close $fh;

        plan tests => scalar @$cases;

        for my $case (@$cases) {
            # Several field lines of the same name are combined with ", ".
            my $field = join ', ', @{ $case->{raw} };

            # The JSON holds the field value as text; the parser wants the
            # bytes that text stands for.
            utf8::encode($field);

            my $got = eval { got_structure( $case->{header_type}, $field ) };
            my $error = $@;

            if ( $case->{must_fail} ) {
                my $ok = ok !defined $got, "$case->{name} (must fail)";

                diag 'parsed when it should not have' if !$ok;
                $total{rejected_as_required}++ if $ok;

                next;
            }

            if ( !defined $got ) {
                # can_fail marks a SHOULD: failing is permitted.
                if ( $case->{can_fail} ) {
                    ok 1, "$case->{name} (failure allowed)";
                    $total{allowed_failure}++;
                }
                else {
                    fail "$case->{name}";
                    diag $error;
                }

                next;
            }

            my $want = eval {
                expected_structure( $case->{header_type}, $case->{expected} );
            };

            if ( !defined $want ) {
                fail "$case->{name}";
                diag "cannot read the expected value: $@";

                next;
            }

            my $ok = is $got, $want, $case->{name};

            $total{pass}++ if $ok;
        }
    };
}

note sprintf
    'httpwg suite: %d parsed as expected, %d rejected as required, %d allowed failures',
    $total{pass}, $total{rejected_as_required}, $total{allowed_failure};

done_testing;
