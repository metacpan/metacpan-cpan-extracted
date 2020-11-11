package Getopt::Kingpin::Flag;
use 5.008001;
use strict;
use warnings;
use Getopt::Kingpin::Base -base;

our $VERSION = "0.10";

has _placeholder => undef;
has _hidden      => 0;

sub placeholder {
    my $self = shift;
    my $placeholder = shift;

    $self->_placeholder($placeholder);

    return $self;
}

sub hidden {
    my $self = shift;

    $self->_hidden(1);

    return $self;
}

sub help_str {
    my $self = shift;

    my $ret = ["", "", ""];

    if (defined $self->short_name) {
        $ret->[0] = sprintf "-%s", $self->short_name;
    }

    my $default = $self->_default;
    my $printable_default = defined $default;
    if (ref $default) {
        $printable_default = Scalar::Util::blessed($default) && overload::Method($default, q[""]);
    }

    if ($self->type eq "Bool") {
        $ret->[1] = sprintf "--%s", $self->name;
    } elsif ($self->is_hash) {
        if (defined $self->_placeholder and $self->_placeholder =~ /=/) {
            $ret->[1] = sprintf '--%s %s', $self->name, $self->_placeholder;
        } elsif (defined $self->_placeholder) {
            $ret->[1] = sprintf '--%s KEY=%s', $self->name, $self->_placeholder;
        } else {
            $ret->[1] = sprintf "--%s KEY=VALUE", $self->name;
        }
    } else {
        if (defined $self->_placeholder) {
            $ret->[1] = sprintf '--%s=%s', $self->name, $self->_placeholder;
        } elsif ($printable_default) {
            $ret->[1] = sprintf '--%s="%s"', $self->name, $default;
        } else {
            $ret->[1] = sprintf "--%s=%s", $self->name, uc $self->name;
        }
    }

    $ret->[2] = defined $self->description ? $self->description : "";

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

Getopt::Kingpin::Flag is used from Getopt::Kingpin.

=head1 METHOD

=head2 new()

Create Getopt::Kingpin::Flag object.

=head2 placeholder()

Set placeholder value for flag in the help.

=head2 hidden()

If set hidden(), flag does not appear in the help.

=head2 help_str()

Return help messages.

=head1 LICENSE

Copyright (C) sago35.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

sago35 E<lt>sago35@gmail.comE<gt>

=cut

