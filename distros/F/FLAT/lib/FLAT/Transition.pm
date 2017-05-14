package FLAT::Transition;
use strict;
use Carp;

sub new {
    my ($pkg, @things) = @_;
    bless { map { $_ => 1 } @things }, $pkg;
}

sub does {
    my ($self, @things) = @_;
    return 1 if @things == 0;
    return !! grep $self->{$_}, @things;
}

sub add {
    my ($self, @things) = @_;
    @$self{@things} = (1) x @things;
}

sub delete {
    my ($self, @things) = @_;
    delete $self->{$_} for @things;
}

sub alphabet {
    my $self = shift;
    sort { $a cmp $b } keys %$self;
}

sub as_string {
    my $self = shift;
    join ",", map { length $_ ? $_ : "epsilon" } $self->alphabet;
}

1;

__END__

=head1 NAME

FLAT::Transition - a transition base class. 

=head1 SYNOPSIS

Default implementation of the Transition class, used to manage transitions
from one state to others.  This class is meant for internal use.

=head1 USAGE

used internally;

=head1 AUTHORS & ACKNOWLEDGEMENTS

FLAT is written by Mike Rosulek E<lt>mike at mikero dot comE<gt> and 
Brett Estrade E<lt>estradb at gmail dot comE<gt>.

The initial version (FLAT::Legacy) by Brett Estrade was work towards an 
MS thesis at the University of Southern Mississippi.

Please visit the Wiki at http://www.0x743.com/flat

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
