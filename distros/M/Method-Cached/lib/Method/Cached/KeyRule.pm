package Method::Cached::KeyRule;

use strict;
use warnings;
use Scalar::Util;

{
    no strict 'refs';

    sub regularize {
        my $key_rule = shift;
        my $ref = ref $key_rule;
        $ref || return &{$key_rule || 'LIST'}(@_);
        $ref eq 'CODE' && return $key_rule->(@_);
        my $key;
        for my $rule (@{$key_rule}) {
            $key = ref $rule ? $rule->(@_) : &{$rule}(@_);
        }
        return $key;
    }
}

sub SELF_SHIFT {
    my ($method_name, $args) = @_;
    shift @{$args};
    return;
}

sub PER_OBJECT {
    my ($method_name, $args) = @_;
    $args->[0] = Scalar::Util::refaddr $args->[0];
    return;
}

sub LIST {
    my ($method_name, $args) = @_;
    local $^W = 0;
    $method_name . join chr(28), @{$args};
}

sub HASH {
    my ($method_name, $args) = @_;
    local $^W = 0;
    my ($ser, %hash) = (q{}, @{$args});
    map {
        $ser .= chr(28) . $_ . (defined $hash{$_} ? '=' . $hash{$_} : q{})
    } sort keys %hash;
    $method_name . $ser;
}

1;

__END__

=head1 NAME

Method::Cached::KeyRule - Generation rule of key built in

=head1 AUTHOR

Satoshi Ohkubo E<lt>s.ohkubo@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
