package Getopt::Kingpin::Type::Enum;
use 5.008001;
use strict;
use warnings;
use Carp;

our $VERSION = "0.11";

sub set_value {
    my $self = shift;
    my ($value) = @_;

    if ((scalar grep {$value eq $_} @{$self->{_options}}) == 0) {
        printf STDERR "error: enum value must be one of %s, got '%s', try --help\n", join(",", @{$self->{_options}}), $value;
        return undef, 1;
    }

    return $value;
}

1;
__END__

=encoding utf-8

=head1 NAME

Getopt::Kingpin::Type::Enum - command line option object

=head1 SYNOPSIS

    use Getopt::Kingpin;
    my $kingpin = Getopt::Kingpin->new;
    my $member = $kingpin->flag('member', 'select member name')->Enum('foo', 'bar', 'baz');
    $kingpin->parse;

    printf "member name : %s\n", $member;

=head1 DESCRIPTION

Getopt::Kingpin::Type::Enum is the type definition for Enum within Getopt::Kingpin.

=head1 METHOD

=head2 set_value($value)

Set the value of $self->value.

=head1 LICENSE

Copyright (C) sago35.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

sago35 E<lt>sago35@gmail.comE<gt>

=cut

