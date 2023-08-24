package Getopt::Kingpin::Type::Bool;
use 5.008001;
use strict;
use warnings;
use Carp;

our $VERSION = "0.11";

sub set_value {
    my $self = shift;
    my ($value) = @_;

    return $value;
}

1;
__END__

=encoding utf-8

=head1 NAME

Getopt::Kingpin::Type::Bool - command line option object

=head1 SYNOPSIS

    use Getopt::Kingpin;
    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->flag('name', 'set name')->bool();
    $kingpin->parse;

    printf "name : %s\n", $name;

=head1 DESCRIPTION

Getopt::Kingpin::Type::Bool is the type definition for Bool within Getopt::Kingpin.

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

