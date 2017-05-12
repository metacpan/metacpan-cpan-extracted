package Games::Dukedom::Signal;

our $VERSION = 'v0.1.2';

use Moo;
with 'Throwable';

use overload
  q{""}    => 'as_string',
  fallback => 1;

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    unshift( @_, 'msg' ) if @_ == 1 && !ref( $_[0] );

    return $class->$orig( {@_} );
};

has msg => (
    is      => 'ro',
    default => undef,
);

has action => (
    is      => 'ro',
    default => undef,
);

has default => (
    is      => 'ro',
    default => undef,
);

sub as_string {
    my $self = shift;

    my $str = ref($self);
    for ( keys(%{$self}) ) {
        $str .= "\n  $_: " . ($self->{$_} || '');
    }

    return $str;
}

1;

__END__

=pod

=head1 NAME

Games::Dukedom::Signal = provide "interrupts" to drive the state-machine

=head1 SYNOPSIS

  
 use Games::Dukedom;
  
 my $game = Games::Dukedom->new();
  
 $game->throw( 'This is a simple message' );
  
 $game->throw(
    msg     => 'This is also a simple message',
 )
  
 $game->throw(
    msg     => 'Do you want to be King? ',
    action  => 'get_yn',
 )
  
 $game->throw(
    msg     => 'Are you sure [Y/n]? ',
    action  => 'get_yn',
    default => 'Y'
 )
  

=head1 DESCRIPTION

This module is used to signal the application code that a display or input
action is needed. This is accomplished by means of the L<Throwable> role.

=head1 ATTRIBUTES

All attributes have read-only accessors.

=head2 msg

Holds a message to be presented to the user by the caller, if present.

=head2 action

Tells the caller what action should be taken before re-entering the main
state-machine loop, if present. Currently takes one of the following values:

=over 4

=item C<undef>

Indicates that no action is needed other than displaying any message that
is present.

=item C<get_yn>

Indicates that the caller should supply a "y" or "n" response in
C<< $game->input >>.

=item C<get_value>

Indicates that the caller should supply a numeric response in
C<< $game->input >>.

=back

=head2 default

Provides a default response, if present, that may be used if desired to
satisfy the requested action.

=head1 METHODS

=head2 as_string

This method will provide a string representing the error, containing the
error's message.

=head1 SEE ALSO

L<Games::Dukedom>

=head1 AUTHOR

Jim Bacon, E<lt>jim@nortx.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Jim Bacon

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version  or,
at your option, any later version of Perl 5 you may have available.

=cut

