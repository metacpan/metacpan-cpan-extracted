package Getopt::Kingpin::Commands;
use 5.008001;
use strict;
use warnings;
use Object::Simple -base;
use Getopt::Kingpin::Command;
use Carp;

our $VERSION = "0.11";

has _commands => sub {
    return [];
};

sub add {
    my $self = shift;
    my $hash = {@_};
    my ($name, $description, $parent) = ($hash->{name}, $hash->{description}, $hash->{parent});

    my $command = Getopt::Kingpin::Command->new(name => $name, description => $description, parent => $parent);
    push @{$self->_commands}, $command;

    return $command;
}

sub count {
    my $self = shift;
    return scalar @{$self->_commands};
}

sub get {
    my $self = shift;
    my ($name) = @_;
    foreach my $cmd (@{$self->_commands}) {
        if ($cmd->name eq $name) {
            return $cmd;
        }
    }
    return;
}

sub get_all {
    my $self = shift;
    return @{$self->_commands};
}

sub help {
    my $self = shift;
    my $ret = "";

    $ret .= "Commands:\n";

    foreach my $cmd ($self->get_all) {
        if ($cmd->commands->count > 1) {
            foreach my $sub ($cmd->commands->get_all) {
                next if $sub->name eq "help";
                $ret .= sprintf "  %s %s\n", $cmd->name, $sub->name;
                $ret .= sprintf "    %s\n", $sub->description;
                $ret .= sprintf "\n";
            }
        } else {
            $ret .= sprintf "  %s\n", $cmd->help_short;
            $ret .= sprintf "    %s\n", $cmd->description;
            $ret .= sprintf "\n";
        }
    }

    return $ret;
}

1;
__END__

=encoding utf-8

=head1 NAME

Getopt::Kingpin::Commands - command line option object

=head1 SYNOPSIS

    use Getopt::Kingpin::Commands;
    my $commands = Getopt::Kingpin::Commands->new;
    $commands->add(
        name        => 'post',
        description => 'post image',
    );

=head1 DESCRIPTION

Getopt::Kingpin::Commands is used from Getopt::Kingpin.

=head1 METHOD

=head2 new()

Create Getopt::Kingpin::Commands object.

=head2 add(name => $name, description => $description)

Add Getopt::Kingpin::Command instance which has $name and $description.

=head2 count()

Get count of Getopt::Kingpin::Command objects.

=head2 get($name)

Get Getopt::Kingpin::Arg instance by $name.

=head2 get_all()

Get all Getopt::Kingpin::Commands instances.

=head2 help()

Return help message.

=head1 LICENSE

Copyright (C) sago35.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

sago35 E<lt>sago35@gmail.comE<gt>

=cut

