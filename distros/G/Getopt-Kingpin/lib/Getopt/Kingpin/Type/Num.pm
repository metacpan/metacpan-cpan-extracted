package Getopt::Kingpin::Type::Num;
use 5.008001;
use strict;
use warnings;
use Carp;
use Scalar::Util 'looks_like_number';

our $VERSION = "0.10";

sub set_value {
    my $self = shift;
    my ($value) = @_;

    if (looks_like_number($value)) {
        # ok
    } else {
        printf STDERR "num parse error\n";
        return undef, 1;
    }
    return $value;
}

1;
__END__

=encoding utf-8

=head1 NAME

Getopt::Kingpin::Type::Num - command line option object

=head1 SYNOPSIS

    use Getopt::Kingpin;
    my $kingpin = Getopt::Kingpin->new;
    my $price = $kingpin->flag('price', 'set price')->num();
    $kingpin->parse;

    printf "price : %.02f\n", $price;

=head1 DESCRIPTION

Getopt::Kingpin::Type::Num is the type definition for Num within Getopt::Kingpin.

=head1 METHOD

=head2 set_value($value)

Set the value of $self->value. Allowed values are checked by looks_like_number
from L<Scalar::Util>.

=head1 LICENSE

Copyright (C) sago35.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

sago35 E<lt>sago35@gmail.comE<gt>

=cut

