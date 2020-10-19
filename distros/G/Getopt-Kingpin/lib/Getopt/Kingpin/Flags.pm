package Getopt::Kingpin::Flags;
use 5.008001;
use strict;
use warnings;
use Object::Simple -base;
use Getopt::Kingpin::Flag;
use Carp;

our $VERSION = "0.09";

has _flags => sub {
    return {};
};

sub add {
    my $self = shift;
    my $hash = {@_};
    my ($name, $description) = ($hash->{name}, $hash->{description});

    if (exists $self->_flags->{$name}) {
        croak sprintf "flag %s is already exists", $name;
    }

    $self->_flags->{$name} = Getopt::Kingpin::Flag->new(
        name        => $name,
        description => $description,
        index       => (scalar keys %{$self->_flags}),
    );

    return $self->_flags->{$name};
}

sub unshift {
    my $self = shift;
    my @flags = @_;

    my $index_offset = scalar @flags;
    foreach my $name ($self->keys) {
        if ($name ne "help") {
            $self->_flags->{$name}->index($self->_flags->{$name}->index + $index_offset);
        }
    }

    my $index = 1;
    foreach my $f (@flags) {
        my $name = $f->name;

        if ($name eq "help") {

        } else {
            $f->index($index);
            $self->_flags->{$name} = $f;
            $index++;
        }
    }
}

sub get {
    my $self = shift;
    my ($name) = @_;

    if (not exists $self->_flags->{$name}) {
        return;
    }

    return $self->_flags->{$name};

}

sub keys {
    my $self = shift;
    my @keys = sort {$self->_flags->{$a}->index <=> $self->_flags->{$b}->index} keys %{$self->_flags};
    return @keys;
}

sub values {
    my $self = shift;
    my @values = sort {$a->index <=> $b->index} values %{$self->_flags};
    return @values;
}

sub count {
    my $self = shift;
    return scalar $self->values;
}

sub _help_length {
    my $self = shift;

    my $len = [0, 0, 0];
    foreach my $f (grep {$_->_hidden != 1} $self->values) {
        my $str = $f->help_str;

        for (my $i = 0; $i < scalar @{$len}; $i++) {
            if ($len->[$i] < length $str->[$i]) {
                $len->[$i] = length $str->[$i];
            }
        }
    }

    return $len;
}

sub help {
    my $self = shift;
    my $ret = "";

    $ret .= "Flags:\n";

    my $len = $self->_help_length;
    foreach my $f (grep {$_->_hidden != 1} $self->values) {
        my $x = "";

        my $long = $len->[1];
        if ($len->[0] > 0) {
            if (defined $f->short_name) {
                $x .= sprintf "  %s, %-${long}s  %s\n", @{$f->help_str};
            } else {
                $x .= sprintf "      %-${long}s  %s\n", @{$f->help_str}[1, 2];
            }
        } else {
            $x .= sprintf "  %-${long}s  %s\n", @{$f->help_str}[1, 2];
        }
        $x =~ s/ +$//;
        $ret .= $x;
    }
    return $ret;
}

1;
__END__

=encoding utf-8

=head1 NAME

Getopt::Kingpin::Flags - command line option object

=head1 SYNOPSIS

    use Getopt::Kingpin::Flags;
    my $flags = Getopt::Kingpin::Flags->new;
    $flags->add(
        name        => 'help',
        description => 'Show context-sensitive help.',
    )->bool();

=head1 DESCRIPTION

Getopt::Kingpin::Flags is used from Getopt::Kingpin.

=head1 METHOD

=head2 new()

Create Getopt::Kingpin::Flags object.

=head2 add(name => $name, description => $description)

Add Getopt::Kingpin::Flag instance which has $name and $description.

=head2 unshift(@flags)

Unshift Getopt::Kingpin::Flag instances to $self->_flags

=head2 get($name)

Get Getopt::Kingpin::Flag instance by $name.

=head2 keys()

Get all names of Getopt::Kingpin::Flag instances.
Their order is same as add() order.

=head2 values()

Get all Getopt::Kingpin::Flag instances.
Their order is same as add() order.

=head2 count()

Get count of Getopt::Kingpin::Arg objects.

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

