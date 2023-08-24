package Getopt::Kingpin::Type::Int;
use 5.008001;
use strict;
use warnings;
use Carp;

our $VERSION = "0.11";

sub set_value {
    my $self = shift;
    my ($value) = @_;

    if ($value =~ /^-?[0-9]+$/) {
        # ok
    } else {
        printf STDERR "int parse error\n";
        return undef, 1;
    }
    return $value;
}

1;
__END__

=encoding utf-8

=head1 NAME

Getopt::Kingpin::Type::Int - command line option object

=head1 SYNOPSIS

    use Getopt::Kingpin;
    my $kingpin = Getopt::Kingpin->new;
    my $age = $kingpin->flag('age', 'set age')->int();
    $kingpin->parse;

    printf "age : %s\n", $age;

=head1 DESCRIPTION

Getopt::Kingpin::Type::Int is the type definition for Int within Getopt::Kingpin.

=head1 METHOD

=head2 set_value($value)

Set the value of $self->value. Tests it against the regular expression
C<< /^-?[0-9]+$/ >>.

=head1 LICENSE

Copyright (C) sago35.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

sago35 E<lt>sago35@gmail.comE<gt>

=cut

