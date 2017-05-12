package Games::Sequential::Position;
use strict;
use warnings;

use Carp;
use Storable qw(dclone);
use 5.006001;

our $VERSION = '0.3.1';

=head1 NAME

Games::Sequential::Position - base Position class for use with Games::Sequential 

=head1 SYNOPSIS

    package My::GamePos;
    use base Games::Sequential::Position;

    sub init { ... }   # setup initial state
    sub apply { ... }

    package main;
    my $pos = My::GamePos->new;
    my $game = Games::Sequential->new($pos);


=head1 DESCRIPTION

Games::Sequential::Position is a base class for position-classes
that can be used with L<Games::Sequential>. This class is
provided for convenience; you don't need this class to use
C<Games::Sequential>. It is also possible to use this class on
its own.

=head1 PURE VIRTUAL METHODS

Modules inheriting this class must implement at least the
C<apply()> method. If you chose to not use this class, you must
also implement a C<copy()> method which makes a deep copy of the
object.

=over 4

=item apply($move)

Accept a move and apply it to the current state producing the
next state. Return a reference to itself. Note that this method
is responsible for also advancing the state's perception of which
player's turn it is.

Something like this (sans error checking):

    sub apply {
        my ($self, $move) = @_;

        ... apply $move, creating next position ...

        return $self;
    }

=cut

sub apply {
    croak "apply(): Call to pure virtual method\n";
}

=back

=head1 METHODS

The following methods are provided by this class.

=over 4

=item new [@list]

Create and return an object. Any arguments is passed on to the
C<init()> method. Return a blessed hash reference.

=cut 

sub new {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $self = bless {}, $class;

    $self->init(@_) or carp "Failed to initialise object!";

    return $self;
}


=item init [@list]

Initialize an object. By default, this only means setting player
1 to be the current player.

This method is called by C<new()>. You You probably want to
override this method and initialise your position there. 

=cut

sub init {
    my $self = shift;
    my $args = @_ && ref($_[0]) ? shift : { @_ };
    my %config = (
        player      => 1,
    );

    @$self{keys %config} = values %config;

    # Override defaults
    while (my ($key, $val) = each %{ $args }) {
        $self->{$key} = $val if exists $self->{$key};
    }

    return $self;
}


=item copy

Clone a position.

=cut

sub copy {
    my $self = shift;
    return dclone($self);
}


=item player [$player]

Read and/or set the current player. If argument is given, that
will be set to the current player.

=cut

sub player {
    my $self = shift;
    $self->{player} = shift if @_;
    return $self->{player};
}



1;  # ensure using this module works
__END__

=back


=head1 SEE ALSO

The author's website, describing this and other projects:
L<http://brautaset.org/software/>


=head1 AUTHOR

Stig Brautaset, E<lt>stig@brautaset.orgE<gt>


=head1 COPYRIGHT AND LICENCE

Copyright (C) 2004, 2005 by Stig Brautaset

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

# vim: shiftwidth=4 tabstop=4 softtabstop=4 expandtab 
