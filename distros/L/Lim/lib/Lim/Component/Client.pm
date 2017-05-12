package Lim::Component::Client;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(blessed weaken);

use Lim ();

=encoding utf8

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {
        logger => Log::Log4perl->get_logger($class),
        call => {}
    };
    bless $self, $class;
    weaken($self->{logger});

    eval {
        $self->Init(@_);
    };
    if ($@) {
        Lim::WARN and $self->{logger}->warn('Unable to initialize module '.$class.': '.$@);
        return;
    }

    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);

    $self->Destroy;
}

=head2 Init

=cut

sub Init {
}

=head2 Destroy

=cut

sub Destroy {
}

=head2 _addCall

=cut

sub _addCall {
    my ($self, $call) = @_;

    unless (blessed $call and $call->isa('Lim::RPC::Call')) {
        confess __PACKAGE__, ': call is not a Lim::RPC::Call';
    }

    unless (exists $self->{call}->{$call}) {
        $self->{call}->{$call} = $call;
    }

    $self;
}

=head2 _deleteCall

=cut

sub _deleteCall {
    my ($self, $call) = @_;

    unless (blessed $call and $call->isa('Lim::RPC::Call')) {
        confess __PACKAGE__, ': call is not a Lim::RPC::Call';
    }

    if (exists $self->{call}->{$call}) {
        delete $self->{call}->{$call};
    }

    $self;
}

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim

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

1; # End of Lim::Component::Client
