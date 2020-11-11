package Getopt::Kingpin::Args;
use 5.008001;
use strict;
use warnings;
use Object::Simple -base;
use Getopt::Kingpin::Arg;
use Carp;

our $VERSION = "0.10";

has _args => sub {
    return [];
};

has _args_remain => sub {
    return [];
};

sub add {
    my $self = shift;
    my $hash = {@_};
    my ($name, $description) = ($hash->{name}, $hash->{description});

    my $arg = Getopt::Kingpin::Arg->new(
        name        => $name,
        description => $description,
    );
    push @{$self->_args}, $arg;

    return $arg;
}

sub count {
    my $self = shift;
    return scalar @{$self->_args};
}

sub get {
    my $self = shift;
    my ($name) = @_;

    foreach my $arg ($self->get_all) {
        if ($arg->name eq $name) {
            return $arg;
        }
    }
    croak "get($name) failed";
}

sub get_by_index {
    my $self = shift;
    my ($index) = @_;

    if ($self->count <= $index) {
        return;
    }

    return $self->_args->[$index];
}

sub get_all {
    my $self = shift;
    return @{$self->_args};
}

sub _help_length {
    my $self = shift;

    my $max_length_of_arg = 0;
    foreach my $arg ($self->get_all) {
        if ($max_length_of_arg < length $arg->help_name) {
            $max_length_of_arg = length $arg->help_name;
        }
    }
    return $max_length_of_arg;

}

sub help {
    my $self = shift;
    my $ret = "";

    $ret .= "Args:\n";

    my $len = $self->_help_length;
    foreach my $arg ($self->get_all) {
        $ret .= sprintf "  %-${len}s  %s\n",
            $arg->help_name,
            $arg->description;
    }

    return $ret;
}

1;
__END__

=encoding utf-8

=head1 NAME

Getopt::Kingpin::Args - command line arguments

=head1 SYNOPSIS

    use Getopt::Kingpin::Args;
    my $args = Getopt::Kingpin::Args->new;
    $args->add(
        name        => 'help',
        description => 'Show context-sensitive help.',
    )->bool();

=head1 DESCRIPTION

Getopt::Kingpin::Args is used from Getopt::Kingpin.

=head1 METHOD

=head2 new()

Create Getopt::Kingpin::Args object.

=head2 add(name => $name, description => $description)

Add Getopt::Kingpin::Arg instance which has $name and $description.

=head2 count()

Get count of Getopt::Kingpin::Arg objects.

=head2 get($name)

Get Getopt::Kingpin::Arg instance by $name.

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->arg('name', 'set name')->string();
    $kingpin->parse;

    my $name = $kingpin->args->get("name");

=head2 get_by_index($index)

Get Getopt::Kingpin::Arg instance by $index.

    $args->get_by_index(0);
    $args->get_by_index(1);

=head2 get_all()

Get all Getopt::Kingpin::Arg instances.

=head2 keys()

Get array of name of Getopt::Kingpin::Arg.
Get order is same as add() order.

=head2 values()

Get array of Getopt::Kingpin::Arg.
get order is same as add() order.

=head2 _help_length()

Internal use only.
Get length of help message.

=head2 help()

Return help message.

=head1 LICENSE

Copyright (C) sago35.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

sago35 E<lt>sago35@gmail.comE<gt>

=cut

