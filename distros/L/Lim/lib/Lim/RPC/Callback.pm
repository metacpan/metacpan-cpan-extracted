package Lim::RPC::Callback;

use common::sense;
use Carp;
use Scalar::Util qw(blessed weaken);

use Log::Log4perl ();

use Lim ();

=encoding utf8

=head1 NAME

Lim::RPC::Callback - Base class of all RPC callbacks

=head1 VERSION

See L<Lim> for version.

=cut

=head1 SYNOPSIS

=over 4

package Lim::RPC::Callback::MyCallback;

use base qw(Lim::RPC::Callback);

=back

=head1 METHODS

=over 4

=item $callback = Lim::RPC::Callback::MyCallback->new(key => value...)

Create a new callback object.

=over 4

=item cb => $callback (required)

Set the callback function related to this callback. This is set by
L<Lim::RPC::Server> depending on what protocol in incoming.

=item client => $client (required)

Set the L<Lim::RPC::Server::Client> related to this callback. This is set by
L<Lim::RPC::Server> on incoming calls.

=back

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my %args = ( @_ );
    my $self = {
        logger => Log::Log4perl->get_logger($class),
        request => undef
    };
    bless $self, $class;
    weaken($self->{logger});

    unless (defined $args{cb} and ref($args{cb}) eq 'CODE') {
        confess __PACKAGE__, ': cb not given or invalid';
    }
    unless (defined $args{reset_timeout} and ref($args{reset_timeout}) eq 'CODE') {
        confess __PACKAGE__, ': reset_timeout not given or invalid';
    }
    if (exists $args{request} and (!blessed $args{request} or !$args{request}->isa('HTTP::Request'))) {
        confess __PACKAGE__, ': request is not HTTP::Request';
    }

    $self->{cb} = $args{cb};
    $self->{reset_timeout} = $args{reset_timeout};
    if (exists $args{request}) {
        $self->{request} = $args{request};
    }

    $self->Init(@_);

    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $self;
}

sub DESTROY {
    my ($self) = @_;

    $self->Destroy;

    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
}

=item $callback->Init(...)

Called from C<new> on object creation with the same arguments as passed to
C<new>.

Should be overloaded if you wish to do initial things on creation.

=cut

sub Init {
}

=item $callback->Destroy(...)

Called from C<DESTROY> on object destruction.

Should be overloaded if you wish to do things on destruction.

=cut

sub Destroy {
}

=item $callback->cb

Return the callback.

=cut

sub cb {
    $_[0]->{cb};
}

=item $callback->call_def

Return the call definition set by C<set_call_def>.

=cut

sub call_def {
    $_[0]->{call_def};
}

=item $callback->set_call_def

Set the call definition related to this callback. Returns the references to it
self.

=cut

sub set_call_def {
    if (ref($_[1]) eq 'HASH') {
        $_[0]->{call_def} = $_[1];
    }

    $_[0];
}

=item $callback->reset_timeout

Reset the timeout of the client related to this callback.

=cut

sub reset_timeout {
    $_[0]->{reset_timeout}->();
}

=item $callback->request

Return the HTTP::Request object associated with the callback, may return undef
if there isnt any.

=cut

sub request {
    $_[0]->{request};
}

=back

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::RPC::Callback

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::RPC::Callback
