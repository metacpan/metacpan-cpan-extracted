package JQ::Lite::Value;

use strict;
use warnings;

use JSON::PP ();
use Scalar::Util qw(looks_like_number);
use B ();

# Older B releases do not expose the public SV flag constants.  The flag
# values themselves are part of Perl's long-standing SV layout, so retain
# their historical values when running with one of those releases.
my $SVf_IOK = B->can('SVf_IOK') ? B::SVf_IOK() : 0x00000100;
my $SVf_NOK = B->can('SVf_NOK') ? B::SVf_NOK() : 0x00000200;
my $SVf_POK = B->can('SVf_POK') ? B::SVf_POK() : 0x00000400;

# This module is deliberately internal.  It provides the jq-style value
# semantics needed by the 3.0 evaluator without changing the compatibility
# behaviour of the 2.x filters that still live in JQ::Lite::Util.

sub type_of {
    my ($value) = @_;

    return 'null' unless defined $value;
    return 'boolean' if JSON::PP::is_bool($value);
    return 'array' if ref($value) eq 'ARRAY';
    return 'object' if ref($value) eq 'HASH';
    if (!ref($value)) {
        my $flags = B::svref_2object(\$value)->FLAGS;
        # Test the public numeric flags first. Older Perl releases may promote
        # the cached PV to SVf_POK during interpolation even though IOK/NOK is
        # still present. Numeric identity therefore wins for dual-valued
        # scalars regardless of how the bundled JSON::PP treats dualvars.
        return 'number' if $flags & ($SVf_IOK | $SVf_NOK);
        return 'string' if $flags & $SVf_POK;
        return 'number' if looks_like_number($value);
    }
    return 'string';
}

sub compare {
    my ($left, $right) = @_;

    my %rank = (
        null    => 0,
        boolean => 1,
        number  => 2,
        string  => 3,
        array   => 4,
        object  => 5,
    );

    my $left_type  = type_of($left);
    my $right_type = type_of($right);
    return $rank{$left_type} <=> $rank{$right_type}
        if $left_type ne $right_type;

    return 0 if $left_type eq 'null';
    return (!!$left) <=> (!!$right) if $left_type eq 'boolean';
    return $left <=> $right if $left_type eq 'number';
    return $left cmp $right if $left_type eq 'string';

    if ($left_type eq 'array') {
        my $limit = @{$left} < @{$right} ? @{$left} : @{$right};
        for my $index ($limit ? (0 .. $limit - 1) : ()) {
            my $ordering = compare($left->[$index], $right->[$index]);
            return $ordering if $ordering;
        }
        return @{$left} <=> @{$right};
    }

    my @left_keys  = sort keys %{$left};
    my @right_keys = sort keys %{$right};
    my $key_ordering = compare(\@left_keys, \@right_keys);
    return $key_ordering if $key_ordering;
    for my $key (@left_keys) {
        my $ordering = compare($left->{$key}, $right->{$key});
        return $ordering if $ordering;
    }
    return 0;
}

sub equal {
    my ($left, $right) = @_;
    return compare($left, $right) == 0;
}

1;
