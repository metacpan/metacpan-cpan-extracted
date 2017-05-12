package Games::Sequential;
use Carp;
use 5.006001;
use strict;
use warnings;

our $VERSION = '0.4.2';

=head1 NAME

Games::Sequential - sequential games framework with OO interface

=head1 SYNOPSIS

    package My::GamePos;
    use base qw(Games::Sequential::Position);

    sub apply { ... }

    package main;
    use My::GamePos;
    use Games::Sequential;

    my $pos = My::GamePos->new;
    my $game = Games::Sequential->new($pos);

    $game->debug(1);
    $game->move($mv);
    $game->undo;


=head1 DESCRIPTION

Games::Sequential is a framework for producing sequential games.
Among other things it keeps track of the sequence of moves, and
provides an unlimited C<undo()> mechanism. It also has methods to
C<clone()> or take a C<snapshot()> of a game.

Users must pass an object representing the initial state of the
game as the first argument to C<new()>. This object must provide
the two methods C<copy()> and C<apply()>. You can use
L<Games::Sequential::Position> as a base class, in which case the
C<copy()> method will be provided for you. The C<apply()> method
must take a move and apply it to the current position, producing
the next position in the game. 

=head1 METHODS

Users must not modify the referred-to values of references
returned by any of the below methods.

=over 4

=item new $initialpos [@list]

Create and return a new L<Games::Sequential> object. The first
argument must be an object representing the initial position of
the game. The C<debug> option can also be set here. 

=cut 

sub new {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $self = bless {}, $class;

    $self->_init(@_) or carp "Failed to init object!";
    return $self;
}


=item _init [@list]

I<Internal method>

Initialize a L<Games::Sequential> object.

=cut

sub _init {
    my $self = shift;
    my $pos = shift or croak "No initial position given!";
    my $args = @_ && ref($_[0]) ? shift : { @_ };

    my %config = (
        # Stacks for backtracking
        pos_hist    => [ $pos ],
        move_hist   => [],

        # Debug and statistics
        debug       => 0,
    );

    # Set defaults
    @$self{keys %config} = values %config;

    # Override defaults
    while (my ($key, $val) = each %{ $args }) {
        $self->{$key} = $val if exists $self->{$key};
    }

    croak "no apply() method defined for position object" 
        unless $pos->can("apply");

    return $self;
}


=item debug [$value]

Return current debug level and, if invoked with an argument, set
to new value.

=cut

sub debug {
    my $self = shift;
    my $prev = $self->{debug};
    $self->{debug} = shift if @_;
    return $prev;
}


=item peek_pos

Return reference to current position.
Use this for drawing the board etc.

=cut

sub peek_pos {
    my $self = shift;
    return $self->{pos_hist}[-1];
}


=item peek_move

Return reference to last applied move.

=cut

sub peek_move {
    my $self = shift;
    return $self->{move_hist}[-1];
}


=item move $move

Apply $move to the current position, keeping track of history.
A reference to the new position is returned, or undef on failure.

=cut

sub move {
    my ($self, $move) = @_;
    my ($pos, $npos) = $self->peek_pos;

    $npos = $pos->copy or croak "$pos->copy() failed";
    $npos->apply($move) or croak "$pos->apply() failed";

    push @{ $self->{pos_hist} }, $npos;
    push @{ $self->{move_hist} }, $move;

    return $self->peek_pos;
}


=item undo

Undo last move. A reference to the previous position is returned,
or undef if there was no more moves to undo.

=cut

sub undo {
    my $self = shift;
    return unless pop @{ $self->{move_hist} };
    pop @{ $self->{pos_hist} } 
        or croak "move and pos stack out of sync!";
    return $self->peek_pos;
}


1;  # ensure using this module works
__END__

=back


=head1 TODO

Implement the missing methods C<clone()>, C<snapshot()>,
C<save()> E<amp> C<resume()>.


=head1 SEE ALSO

The author's website, describing this and other projects:
L<http://brautaset.org/software/>


=head1 AUTHOR

Stig Brautaset, E<lt>stig@brautaset.orgE<gt>


=head1 COPYRIGHT AND LICENCE

Copyright (C) 2004-2005 by Stig Brautaset

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

# vim: shiftwidth=4 tabstop=4 softtabstop=4 expandtab 
