package JQ::Lite::Builtin::Math;

use strict;
use warnings;

use Scalar::Util qw(looks_like_number);
use JQ::Lite::Util ();

sub register {
    my ($class, $register) = @_;

    $register->('abs', sub {
        my ($owner, $inputs) = @_;
        return [ map {
            !defined($_) ? undef
                : !ref($_) ? (looks_like_number($_) ? abs($_) : $_)
                : ref($_) eq 'ARRAY'
                    ? [ map { looks_like_number($_) ? abs($_) : $_ } @{$_} ]
                    : $_
        } @{$inputs} ];
    });
    $register->(['ceil', 'ceil()'], _numeric(\&JQ::Lite::Util::_ceil));
    $register->(['floor', 'floor()'], _numeric(\&JQ::Lite::Util::_floor));
    $register->(['round', 'round()'], _numeric(\&JQ::Lite::Util::_round));
    $register->(['to_number', 'to_number()'], _map(\&JQ::Lite::Util::_apply_to_number));
    $register->(['tonumber', 'tonumber()'], _map(\&JQ::Lite::Util::_tonumber));
    $register->(qr/^clamp\((.*)\)$/, sub {
        my ($owner, $inputs, $arguments) = @_;
        my @args = JQ::Lite::Util::_parse_arguments($arguments);
        my $min = @args ? JQ::Lite::Util::_normalize_numeric_bound($args[0]) : undef;
        my $max = @args > 1 ? JQ::Lite::Util::_normalize_numeric_bound($args[1]) : undef;
        ($min, $max) = ($max, $min) if defined($min) && defined($max) && $min > $max;
        return [ map { JQ::Lite::Util::_apply_clamp($_, $min, $max) } @{$inputs} ];
    });
}

sub _numeric {
    my ($function) = @_;
    return sub {
        my ($owner, $inputs) = @_;
        return [ map { JQ::Lite::Util::_apply_numeric_function($_, $function) } @{$inputs} ];
    };
}

sub _map {
    my ($function) = @_;
    return sub {
        my ($owner, $inputs) = @_;
        return [ map { $function->($_) } @{$inputs} ];
    };
}

1;
