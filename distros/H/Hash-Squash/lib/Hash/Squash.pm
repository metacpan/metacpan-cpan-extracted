use strict;
use warnings;
package Hash::Squash;
# ABSTRACT: Remove numbered keys from a nested hash/array

use parent 'Exporter';
use List::Util qw/max/;

use version; our $VERSION = version->declare("v0.0.4");

our @EXPORT_OK = qw(squash unnumber);

sub squash   { _squash(shift) }
sub unnumber { _squash(shift, { keep_empty => 1 }) }

sub _squash {
    my ($obj, $arg) = @_;
    return $obj unless ref $obj;

    $obj = _squash_hash($obj, $arg);
    $obj = _squash_array($obj, $arg);

    return $obj;
}

sub _squash_hash {
    my ($obj, $arg) = @_;
    return $obj if ref $obj ne 'HASH';

    EMPTY_HASH: {
        last EMPTY_HASH if %{$obj};
        return (undef) unless exists $arg->{keep_empty};
        return (undef) unless $arg->{keep_empty};
        return +{};
    }

    my @keys = keys %{$obj};

    CONTAINS_NON_NUMERIC_KEYS: {
        last CONTAINS_NON_NUMERIC_KEYS unless grep {/\D/} @keys;
        my %hash = map { $_ => _squash($obj->{$_}, $arg) } @keys;
        return \%hash;
    }

    my $max = max(@keys) || 0;

    my @ar;
    for my $i (0 .. $max) {
        #
        # Some numbered keys might be partially discreated
        #
        push @ar, exists $obj->{$i} ? _squash($obj->{$i}, $arg) : (undef);
    }

    return \@ar;
}

sub _squash_array {
    my ($obj, $arg) = @_;
    return $obj if ref $obj ne 'ARRAY';

    my $keep_empty = exists $arg->{keep_empty} ? $arg->{keep_empty} : ();

    EMPTY_ARRAY: {
        last EMPTY_ARRAY if @{$obj} != 0;
        return (undef) unless $keep_empty;
        return [];
    }

    SINGLE_ELEMENT: {
        last SINGLE_ELEMENT if @{$obj} != 1;
        last SINGLE_ELEMENT if $keep_empty;
        return _squash($obj->[0]);
    }

    my @array = map { _squash($_, $arg) } @{$obj};

    return \@array;
}

1;
__END__

=head1 NAME

Hash::Squash - Remove numbered keys from a nested hash/array

=head1 DESCRIPTION

This package provides B<squash> and B<unnumber> subroutines to simplify
hash/array structures.

=head1 SYNOPSIS

=head2 C<squash>

B<squash> does 3 things to the argument recursively

1. Remove numbered keys from hashes and map them to arrays

2. Convert hashes/arrays with single element to single value

3. Convert empty hashes/arrays to `undef`

    use Hash::Squash qw(squash);
    my $hash = squash(+{
        foo => +{
            '0' => 'numbered',
            '1' => 'hash',
            '2' => 'structures',
        },
        bar => +{
            '0' => 'obviously a single value',
        },
        buz => [
            +{
                nest => +{
                    '0' => 'nested',
                    '2' => 'discreated',
                    '3' => 'array',
                },
            },
            +{
                nest => +{
                    '0' => 'FOO',
                    '1' => 'BAR',
                    '2' => 'BUZ',
                },
            },
        ],
    });

Turns to:

    +{
        foo => [
            'numbered',
            'hash',
            'structures',
        ],
        bar => 'obviously a single value',
        buz => [
            +{
                nest => [
                    'nested',
                    undef,
                    'discreated',
                    'array',
                ],
            },
            +{
                nest => [
                    'FOO',
                    'BAR',
                    'BUZ',
                ],
            }
        ],
    };

=head2 C<unnumber>

B<unnumber> is similar to B<squash>, but keep hashes/arrays

    use Hash::Squash qw(unnumber);
    my $hash = unnumber(+{
        foo => +{
            '0' => 'numbered',
            '1' => 'hash',
            '2' => 'structures',
        },
        bar => +{
            '0' => 'obviously a single value',
        },
        buz => [
            +{
                nest => +{
                    '0' => 'nested',
                    '2' => 'partial',
                    '3' => 'array',
                },
            },
        ],
    });

Turns to:

    +{
        foo => [
            'numbered',
            'hash',
            'structures',
        ],
        bar => ['obviously a single value'],
        buz => [
            +{
                nest => [
                    'nested',
                    undef,
                    'partial',
                    'array',
                ],
            },
        ],
    };

=head1 AUTHOR

Shin Kojima <shin@kojima.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
