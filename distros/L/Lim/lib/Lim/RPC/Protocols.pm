package Lim::RPC::Protocols;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(blessed weaken);
use Module::Find qw(findsubmod);

use Lim ();

=encoding utf8

=head1 NAME

Lim::RPC::Protocols - Lim's RPC protocol loader and container

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;
our $INSTANCE;

=head1 SYNOPSIS

  use Lim::RPC::Protocols;
  $protocol = Lim::RPC::Protocols->instance->protocol('name');

=head1 METHODS

=over 4

=cut

sub _new {
    my $this = shift;
    my $class = ref($this) || $this;
    my %args = ( @_ );
    my $self = {
        logger => Log::Log4perl->get_logger($class),
        protocol => {},
        protocol_name => {}
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

    delete $self->{protocol};
}

END {
    undef($INSTANCE);
}

=item $instance = Lim::RPC::Protocols->instance

Returns the singelton instance of this class.

=cut

sub instance {
    $INSTANCE ||= Lim::RPC::Protocols->_new;
}

=item $instance->load

Loads all classes that exists on the system under Lim::RPC::Protocol::. Returns
the reference to itself even on error.

=cut

sub load {
    my ($self) = @_;

    foreach my $module (findsubmod Lim::RPC::Protocol) {
        if (exists $self->{protocol}->{$module}) {
            Lim::WARN and $self->{logger}->warn('Protocol ', $module, ' already loaded');
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
            Lim::WARN and $self->{logger}->warn('Unable to load protocol ', $module, ': ', $@);
            $self->{protocol}->{$module} = {
                module => $module,
                loaded => 0,
                error => $@
            };
            next;
        }

        unless ($name =~ /^[a-z0-9_\-\.]+$/o) {
            Lim::WARN and $self->{logger}->warn('Unable to load protocol ', $module, ': Illegal characters in protocol name');
            $self->{protocol}->{$module} = {
                module => $module,
                loaded => 0,
                error => 'Illegal characters in protocol name'
            };
            next;
        }

        if (exists $self->{protocol_name}->{$name}) {
            Lim::WARN and $self->{logger}->warn('Protocol name ', $name, ' already loaded by module ', $self->{protocol_name}->{$name});
            next;
        }

        Lim::DEBUG and $self->{logger}->debug('Loaded ', $module);
        $self->{protocol}->{$module} = {
            name => $name,
            module => $module,
            version => $module->VERSION,
            loaded => 1
        };
        $self->{protocol_name}->{$name} = $module;
    }

    $self;
}

=item $protocol = $instance->protocol($name, ...)

=cut

sub protocol {
    my $self = shift;
    my $name = shift;

    if (defined $name) {
        my $module;

        foreach (keys %{$self->{protocol}}) {
            if ($self->{protocol}->{$_}->{loaded} and $self->{protocol}->{$_}->{name} eq $name) {
                $module = $self->{protocol}->{$_}->{module};
                last;
            }
        }

        if (defined $module) {
            my $protocol;
            eval {
                $protocol = $module->new(@_);
            };
            if ($@) {
                Lim::WARN and $self->{logger}->warn('Unable to create new instance of protocol ', $name, '(', $module, '): ', $@);
            }
            else {
                return $protocol;
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

    perldoc Lim::RPC::Protocols

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

1; # End of Lim::RPC::Protocols
