package Lim::RPC::Transports;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(blessed weaken);
use Module::Find qw(findsubmod);

use Lim ();

=encoding utf8

=head1 NAME

Lim::RPC::Transports - Lim's RPC transport loader and container

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;
our $INSTANCE;

=head1 SYNOPSIS

  use Lim::RPC::Transports;
  $transport = Lim::RPC::Transports->instance->transport('name');

=head1 METHODS

=over 4

=cut

sub _new {
    my $this = shift;
    my $class = ref($this) || $this;
    my %args = ( @_ );
    my $self = {
        logger => Log::Log4perl->get_logger($class),
        transport => {},
        transport_name => {}
    };
    bless $self, $class;
    weaken($self->{logger});

    $self->load;

    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);

    delete $self->{transport};
}

END {
    undef($INSTANCE);
}

=item $instance = Lim::RPC::Transports->instance

Returns the singelton instance of this class.

=cut

sub instance {
    $INSTANCE ||= Lim::RPC::Transports->_new;
}

=item $instance->load

Loads all classes that exists on the system under Lim::RPC::Transport::. Returns
the reference to itself even on error.

=cut

sub load {
    my ($self) = @_;

    foreach my $module (findsubmod Lim::RPC::Transport) {
        if ($module =~ /::Clients?$/o) {
            next;
        }
        if (exists $self->{transport}->{$module}) {
            Lim::WARN and $self->{logger}->warn('Transport ', $module, ' already loaded');
            next;
        }

        if ($module =~ /^([\w:]+)$/o) {
            $module = $1;
        }
        else {
            next;
        }

        my $name;
        eval {
            eval "require $module;";
            die $@ if $@;
            $name = $module->name;
        };

        if ($@) {
            Lim::WARN and $self->{logger}->warn('Unable to load transport ', $module, ': ', $@);
            $self->{transport}->{$module} = {
                name => $name,
                module => $module,
                loaded => 0,
                error => $@
            };
            next;
        }

        unless ($name =~ /^[a-z0-9_\-\.]+$/o) {
            Lim::WARN and $self->{logger}->warn('Unable to load transport ', $module, ': Illegal characters in transport name');
            $self->{transport}->{$module} = {
                module => $module,
                loaded => 0,
                error => 'Illegal characters in transport name'
            };
            next;
        }

        if (exists $self->{transport_name}->{$name}) {
            Lim::WARN and $self->{logger}->warn('Transport name ', $name, ' already loaded by module ', $self->{transport_name}->{$name});
            next;
        }

        Lim::DEBUG and $self->{logger}->debug('Loaded ', $module);
        $self->{transport}->{$module} = {
            name => $name,
            module => $module,
            version => $module->VERSION,
            loaded => 1
        };
        $self->{transport_name}->{$name} = $module;
    }

    $self;
}

=item $transport = $instance->transport($name, ...)

=cut

sub transport {
    my $self = shift;
    my $name = shift;

    if (defined $name) {
        my $module;

        foreach (keys %{$self->{transport}}) {
            if ($self->{transport}->{$_}->{loaded} and $self->{transport}->{$_}->{name} eq $name) {
                $module = $self->{transport}->{$_}->{module};
                last;
            }
        }

        if (defined $module) {
            my $transport;
            eval {
                $transport = $module->new(@_);
            };
            if ($@) {
                Lim::WARN and $self->{logger}->warn('Unable to create new instance of transport ', $name, '(', $module, '): ', $@);
            }
            else {
                return $transport;
            }
        }
    }
    return;
}

=back

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::RPC::Transports

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

1; # End of Lim::RPC::Transports
