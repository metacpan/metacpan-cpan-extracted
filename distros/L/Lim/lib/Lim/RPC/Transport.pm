package Lim::RPC::Transport;

use common::sense;
use Carp;

use Scalar::Util qw(blessed weaken);
use Log::Log4perl ();

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
    my %args = ( @_ );
    my $self = {
        logger => Log::Log4perl->get_logger($class),
        __protocols => []
    };
    bless $self, $class;
    weaken($self->{logger});

    unless (blessed($args{server}) and $args{server}->isa('Lim::RPC::Server')) {
        confess __PACKAGE__, ': No server specified or invalid';
    }
    $self->{__server} = $args{server};
    weaken($self->{__server});

    $self->Init(@_);

    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);

    $self->Destroy;
    delete $self->{__protocols};
    delete $self->{__server};
}

=head2 Init

=cut

sub Init {
}

=head2 Destroy

=cut

sub Destroy {
}

=head2 name

=cut

sub name {
    confess 'function name not overloaded';
}

=head2 uri

=cut

sub uri {
    confess 'function uri not overloaded';
}

=head2 add_protocol

=cut

sub add_protocol {
    my $self = shift;

    foreach (@_) {
        unless (blessed($_) and $_->isa('Lim::RPC::Protocol')) {
            confess 'Argument is not a Lim::RPC::Protocol';
        }
    }
    push(@{$self->{__protocols}}, @_);

    $self;
}

=head2 protocols

=cut

sub protocols {
    @{$_[0]->{__protocols}};
}

=head2 server

=cut

sub server {
    $_[0]->{__server};
}

=head2 host

=cut

sub host {
    confess 'function host not overloaded';
}

=head2 port

=cut

sub port {
    confess 'function port not overloaded';
}

=head2 serve

=cut

sub serve {
    confess 'function serve not overloaded';
}

=head2 close

=cut

sub close {
    my ($self, $cb) = @_;

    unless (ref($cb) eq 'CODE') {
        confess '$cb is not CODE';
    }

    $cb->();

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

1; # End of Lim::RPC::Transport
