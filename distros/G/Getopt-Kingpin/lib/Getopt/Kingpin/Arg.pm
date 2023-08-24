package Getopt::Kingpin::Arg;
use 5.008001;
use strict;
use warnings;
use Getopt::Kingpin::Base -base;

our $VERSION = "0.11";

sub help_name {
    my $self = shift;
    my $mode = shift;

    if (not defined $mode) {
        $mode = 0;
    }

    my $ret = '<' . $self->name . '>';
    if ($mode and $self->is_cumulative) {
        $ret = $ret . '...';
    }
    if ($self->is_hash) {
        $ret =~ s/</<KEY=/;
    }
    if (not $self->_required) {
        $ret = '[' . $ret . ']';
    }
    return $ret;
}

1;
__END__

=encoding utf-8

=head1 NAME

Getopt::Kingpin::Flag - command line option object

=head1 SYNOPSIS

    use Getopt::Kingpin;
    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->flag('name', 'set name')->string();
    $kingpin->parse;

    printf "name : %s\n", $name;

=head1 DESCRIPTION

Getopt::Kingpin::Arg is used from Getopt::Kingpin.

=head1 METHOD

=head2 new()

Create Getopt::Kingpin::Arg object.

=head2 help_name()

Return name for help.

=head1 LICENSE

Copyright (C) sago35.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

sago35 E<lt>sago35@gmail.comE<gt>

=cut

