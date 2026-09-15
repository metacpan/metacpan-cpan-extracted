package JQ::Lite::Builtin::Type;

use strict;
use warnings;

use B qw(SVp_IOK SVp_NOK);

sub register {
    my ($class, $register) = @_;

    $register->('length', sub {
        my ($owner, $inputs) = @_;
        return [ map {
            !defined($_) ? 0
                : ref($_) eq 'ARRAY' ? scalar(@{$_})
                : ref($_) eq 'HASH' ? scalar(keys %{$_})
                : (!ref($_) || ref($_) eq 'JSON::PP::Boolean') ? length("$_")
                : 0
        } @{$inputs} ];
    });

    $register->(['type', 'type()'], sub {
        my ($owner, $inputs) = @_;
        return [ map {
            if (!defined $_) { 'null' }
            elsif (ref($_) eq 'ARRAY') { 'array' }
            elsif (ref($_) eq 'HASH') { 'object' }
            elsif (ref($_) eq '') {
                my $flags = B::svref_2object(\$_)->FLAGS;
                ($flags & (SVp_IOK | SVp_NOK)) ? 'number' : 'string';
            }
            elsif (ref($_) eq 'JSON::PP::Boolean') { 'boolean' }
            else { 'unknown' }
        } (@{$inputs} ? @{$inputs} : (undef)) ];
    });

    $register->(['arrays', 'arrays()'], sub {
        my ($owner, $inputs) = @_;
        return [ grep { ref($_) eq 'ARRAY' } @{$inputs} ];
    });
    $register->(['objects', 'objects()'], sub {
        my ($owner, $inputs) = @_;
        return [ grep { ref($_) eq 'HASH' } @{$inputs} ];
    });
    $register->(['scalars', 'scalars()'], sub {
        my ($owner, $inputs) = @_;
        return [ grep { !defined($_) || !ref($_) || ref($_) eq 'JSON::PP::Boolean' } @{$inputs} ];
    });
    $register->('values', sub {
        my ($owner, $inputs) = @_;
        return [ map { ref($_) eq 'HASH' ? [ values %{$_} ] : $_ } @{$inputs} ];
    });
    $register->('count', sub {
        my ($owner, $inputs) = @_;
        return [ map { ref($_) eq 'ARRAY' ? scalar(@{$_}) : defined($_) ? 1 : 0 } @{$inputs} ];
    });
    $register->('empty', sub { return [] });
}

1;
