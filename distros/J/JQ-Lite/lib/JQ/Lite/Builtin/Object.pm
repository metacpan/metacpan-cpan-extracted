package JQ::Lite::Builtin::Object;

use strict;
use warnings;

use JQ::Lite::Util ();

sub register {
    my ($class, $register) = @_;

    $register->('keys', sub {
        my ($owner, $inputs) = @_;
        return [ map {
            ref($_) eq 'HASH' ? [ sort keys %{$_} ]
                : ref($_) eq 'ARRAY' ? [ 0 .. $#{$_} ]
                : die 'keys(): argument must be an object or array'
        } @{$inputs} ];
    });
    $register->(['keys_unsorted', 'keys_unsorted()'], sub {
        my ($owner, $inputs) = @_;
        return [ map {
            ref($_) eq 'HASH' ? [ keys %{$_} ]
                : ref($_) eq 'ARRAY' ? [ 0 .. $#{$_} ] : undef
        } @{$inputs} ];
    });
    $register->(['to_entries', 'to_entries()'], sub {
        my ($owner, $inputs) = @_;
        return [ map { JQ::Lite::Util::_to_entries($_) } @{$inputs} ];
    });
    $register->(['from_entries', 'from_entries()'], sub {
        my ($owner, $inputs) = @_;
        return [ map { JQ::Lite::Util::_from_entries($_) } @{$inputs} ];
    });
    $register->(['merge_objects', 'merge_objects()'], sub {
        my ($owner, $inputs) = @_;
        return [ map { JQ::Lite::Util::_apply_merge_objects($_) } @{$inputs} ];
    });
    $register->(qr/^has\((.+)\)$/, sub {
        my ($owner, $inputs, $arguments) = @_;
        my @args = JQ::Lite::Util::_parse_arguments($arguments);
        my $needle = @args ? $args[0] : undef;
        return [ map { JQ::Lite::Util::_apply_has($_, $needle) } @{$inputs} ];
    });
    $register->(qr/^contains\((.+)\)$/, sub {
        my ($owner, $inputs, $argument) = @_;
        my $needle = JQ::Lite::Util::_parse_literal_argument($argument);
        return [ map { JQ::Lite::Util::_apply_contains($_, $needle) } @{$inputs} ];
    });
    $register->(qr/^contains_subset\((.+)\)$/, sub {
        my ($owner, $inputs, $argument) = @_;
        my $needle = JQ::Lite::Util::_parse_literal_argument($argument);
        return [ map { JQ::Lite::Util::_apply_contains_subset($_, $needle) } @{$inputs} ];
    });
    $register->(qr/^inside\((.+)\)$/, sub {
        my ($owner, $inputs, $argument) = @_;
        my $container = JQ::Lite::Util::_parse_literal_argument($argument);
        return [ map { JQ::Lite::Util::_apply_inside($_, $container) } @{$inputs} ];
    });
}

1;
