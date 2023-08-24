package Getopt::Kingpin::Type::File;
use 5.008001;
use strict;
use warnings;
use Carp;
use Path::Tiny;

our $VERSION = "0.11";

sub set_value {
    my $self = shift;
    my ($value) = @_;

    my $p = path($value);
    return $p;
}

1;
__END__

=encoding utf-8

=head1 NAME

Getopt::Kingpin::Type::File - command line option object

=head1 SYNOPSIS

    use Getopt::Kingpin;
    my $kingpin = Getopt::Kingpin->new;
    my $readme = $kingpin->flag('readme', 'set readme')->file();
    $kingpin->parse;

    printf "readme : %s\n", $readme;

=head1 DESCRIPTION

Getopt::Kingpin::Type::File is the type definition for File within Getopt::Kingpin.

=head1 METHOD

=head2 set_value($value)

Set the value of $self->value. Converts strings to Path::Tiny objects.

=head1 LICENSE

Copyright (C) sago35.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

sago35 E<lt>sago35@gmail.comE<gt>

=cut

