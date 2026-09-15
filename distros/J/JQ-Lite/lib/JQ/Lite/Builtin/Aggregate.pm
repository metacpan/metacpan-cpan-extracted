package JQ::Lite::Builtin::Aggregate;

use strict;
use warnings;

use List::Util qw(sum min max);
use JQ::Lite::Util ();

sub register {
    my ($class, $register) = @_;

    $register->(['add', 'sum'], sub {
        my ($owner, $inputs) = @_;
        return [ map { ref($_) eq 'ARRAY' ? sum(map { 0 + $_ } @{$_}) : $_ } @{$inputs} ];
    });
    $register->('product', sub {
        my ($owner, $inputs) = @_;
        return [ map {
            if (ref($_) eq 'ARRAY') {
                my ($product, $seen) = (1, 0);
                for my $value (@{$_}) {
                    next unless defined $value;
                    $product *= 0 + $value;
                    $seen = 1;
                }
                $seen ? $product : 1;
            }
            else { $_ }
        } @{$inputs} ];
    });
    $register->('min', _extreme(\&min));
    $register->('max', _extreme(\&max));
    $register->('avg', sub {
        my ($owner, $inputs) = @_;
        return [ map { ref($_) eq 'ARRAY' && @{$_}
            ? sum(map { 0 + $_ } @{$_}) / scalar(@{$_}) : 0 } @{$inputs} ];
    });
    $register->('median', sub {
        my ($owner, $inputs) = @_;
        return [ map {
            if (ref($_) eq 'ARRAY' && @{$_}) {
                my @numbers = sort { $a <=> $b }
                    JQ::Lite::Util::_extract_numeric_values($_);
                if (@numbers) {
                    my $middle = int(@numbers / 2);
                    @numbers % 2 ? $numbers[$middle]
                        : ($numbers[$middle - 1] + $numbers[$middle]) / 2;
                }
                else { undef }
            }
            else { $_ }
        } @{$inputs} ];
    });
}

sub _extreme {
    my ($function) = @_;
    return sub {
        my ($owner, $inputs) = @_;
        return [ map {
            ref($_) eq 'ARRAY' ? do {
                my @numbers = JQ::Lite::Util::_extract_numeric_values($_);
                @numbers ? $function->(@numbers) : undef;
            } : $_
        } @{$inputs} ];
    };
}

1;
