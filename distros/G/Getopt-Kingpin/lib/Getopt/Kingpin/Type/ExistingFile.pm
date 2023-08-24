package Getopt::Kingpin::Type::ExistingFile;
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
    if ($p->is_dir) {
        printf STDERR "error: '%s' is a directory, try --help\n", $value;
        return undef, 1;
    } elsif ($p->is_file) {
        # ok
    } else {
        printf STDERR "error: path '%s' does not exist, try --help\n", $value;
        return undef, 1;
    }
    return $p;
}

1;
__END__

=encoding utf-8

=head1 NAME

Getopt::Kingpin::Type::ExistingFile - command line option object

=head1 SYNOPSIS

    use Getopt::Kingpin;
    my $kingpin = Getopt::Kingpin->new;
    my $readme = $kingpin->flag('readme', 'set readme')->existing_file();
    $kingpin->parse;

    printf "readme : %s\n", $readme;

=head1 DESCRIPTION

Getopt::Kingpin::Type::ExistingFile is the type definition for ExistingFile within Getopt::Kingpin.

=head1 METHOD

=head2 set_value($value)

Set the value of $self->value. Converts strings to Path::Tiny objects and
checks C<is_file> is true.

=head1 LICENSE

Copyright (C) sago35.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

sago35 E<lt>sago35@gmail.comE<gt>

=cut

