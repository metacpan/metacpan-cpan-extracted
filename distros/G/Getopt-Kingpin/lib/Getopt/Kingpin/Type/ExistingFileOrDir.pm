package Getopt::Kingpin::Type::ExistingFileOrDir;
use 5.008001;
use strict;
use warnings;
use Carp;
use Path::Tiny;

our $VERSION = "0.10";

sub set_value {
    my $self = shift;
    my ($value) = @_;

    my $p = path($value);
    if ($p->exists) {
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

Getopt::Kingpin::Type::ExistingFileOrDir - command line option object

=head1 SYNOPSIS

    use Getopt::Kingpin;
    my $kingpin = Getopt::Kingpin->new;
    my $lib_dir = $kingpin->flag('lib_dir', 'set lib_dir')->existing_file_or_dir();
    $kingpin->parse;

    printf "lib_dir : %s\n", $lib_dir;

=head1 DESCRIPTION

Getopt::Kingpin::Type::ExistingFileOrDir is the type definition for ExistingFileOrDir within Getopt::Kingpin.

=head1 METHOD

=head2 set_value($value)

Set the value of $self->value. Converts strings to Path::Tiny objects and
checks C<exists> is true.

=head1 LICENSE

Copyright (C) sago35.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

sago35 E<lt>sago35@gmail.comE<gt>

=cut

