package Lim::RPC::Server;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(blessed weaken);

use URI ();
use URI::Split ();

use Lim ();
use Lim::RPC ();
use Lim::RPC::Value ();
use Lim::RPC::Value::Collection ();
use Lim::RPC::Protocols ();
use Lim::RPC::Transports ();
use Lim::RPC::URIMaps ();

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
        protocol => {},
        transports => [],
        module => {},
        transport_modules => {}
    };
    bless $self, $class;
    weaken($self->{logger});

    unless (defined $args{uri}) {
        confess __PACKAGE__, ': No uri specified';
    }

    foreach my $uri (ref($args{uri}) eq 'ARRAY' ? @{$args{uri}} : $args{uri}) {
        my $modules;
        my $transport_config = {};

        if (ref($uri) eq 'HASH') {
            if (ref($uri->{plugin}) eq 'ARRAY') {
                $modules = { map { $_ => 1 } @{$uri->{plugin}} };
            }
            unless (defined $uri->{uri}) {
                next;
            }
            if (ref($uri->{transport}) eq 'HASH') {
                $transport_config = $uri->{transport};
            }
            $uri = $uri->{uri};
        }

        my ($scheme, $auth, $path, $query, $frag) = URI::Split::uri_split($uri);

        if ($scheme =~ /^([a-z0-9_\-\.]+)(?:\+([a-z0-9_\-\.\+]+))*/o) {
            my ($transport_name, $protocols) = ($1, $2);
            my (@protocols, $transport);
            $uri = URI->new('', 'http');
            $uri->query($query);
            $uri->host_port($auth);

            foreach my $protocol_name (split(/\+/o, $protocols)) {
                unless (exists $self->{protocol}->{$protocol_name}) {
                    my $protocol;

                    unless (defined ($protocol = Lim::RPC::Protocols->instance->protocol($protocol_name, server => $self))) {
                        confess __PACKAGE__, ': Protocol ', $protocol_name, ' does not exists';
                    }

                    $self->{protocol}->{$protocol_name} = $protocol;
                    push(@protocols, $protocol);
                }
                else {
                    push(@protocols, $self->{protocol}->{$protocol_name});
                }
            }

            unless (defined ($transport = Lim::RPC::Transports->instance->transport($transport_name,
                (ref($transport_config->{$transport_name}) eq 'HASH' ? (%{$transport_config->{$transport_name}}) : ()),
                server => $self, uri => $uri)))
            {
                confess __PACKAGE__, ': Transport ', $transport_name, ' does not exists';
            }

            $transport->add_protocol(@protocols);
            push(@{$self->{transports}}, $transport);
            if ($modules) {
                $self->{transport_modules}->{$transport} = $modules;
            }
        }
        else {
            confess __PACKAGE__, ': Unable to parse URI schema: ', $uri;
        }
    }

    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);

    delete $self->{transports};
    delete $self->{module};
    delete $self->{protocol};
}

=head2 serve

=cut

sub serve {
    my ($self) = shift;

    foreach my $module (@_) {
        my $obj;

        eval {
            $obj = $module->Server;
        };
        if ($@) {
            Lim::WARN and $self->{logger}->warn('Can not serve ', $module, ': ', $@);
            next;
        }
        unless (defined $obj) {
            Lim::DEBUG and $self->{logger}->debug('Can not serve ', $module, ': no object from Module->Server so may only have Client installed');
            next;
        }

        if ($obj->isa('Lim::Component::Server')) {
            my $name = lc($module->Name);

            if (exists $self->{module}->{$name}) {
                Lim::WARN and $self->{logger}->warn('Can not serve ', $name, ': plugin already served');
                next;
            }

            unless ($module->VERSION) {
                Lim::WARN and $self->{logger}->warn('Can not serve ', $name, ': no VERSION specified in plugin');
                next;
            }

            my $calls = $module->Calls;
            unless ($calls) {
                Lim::INFO and $self->{logger}->info('Not serving ', $name, ', nothing to serve');
                next;
            }
            unless (ref($calls) eq 'HASH') {
                Lim::WARN and $self->{logger}->warn('Can not serve ', $name, ': Calls() return was invalid');
                next;
            }
            unless (%$calls) {
                Lim::INFO and $self->{logger}->info('Not serving ', $name, ', nothing to serve');
                next;
            }

            my $uri_maps = {};

            foreach my $call (keys %$calls) {
                unless ($obj->can($call)) {
                    Lim::WARN and $self->{logger}->warn('Can not serve ', $name, ': Missing specified call ', $call, ' function');
                    undef($calls);
                    last;
                }

                my $create_call = 0;

                foreach my $protocol_name (keys %{$self->{protocol}}) {
                    my $base = 'Lim::RPC::ProtocolCall::'.$protocol_name.'::'.ref($obj);

                    if ($base->isa('UNIVERSAL') and $base->can($call)) {
                        next;
                    }
                    $create_call = 1;
                    last;
                }

                if ($create_call) {
                    my $call_def = $calls->{$call};

                    unless (ref($call_def) eq 'HASH') {
                        Lim::WARN and $self->{logger}->warn('Can not serve ', $name, ': call ', $call, ' has invalid definition');
                        undef($calls);
                        last;
                    }

                    if (exists $call_def->{uri_map}) {
                        unless (ref($call_def->{uri_map}) eq 'ARRAY') {
                            Lim::WARN and $self->{logger}->warn('Can not serve ', $name, ': call ', $call, ' has invalid uri_map parameter definition');
                            undef($calls);
                            last;
                        }

                        my $uri_map = Lim::RPC::URIMaps->new;

                        foreach my $map (@{$call_def->{uri_map}}) {
                            if (defined (my $redirect_call = $uri_map->add($map))) {
                                if ($redirect_call) {
                                    unless (exists $calls->{$redirect_call}) {
                                        Lim::WARN and $self->{logger}->warn('Can not serve ', $name, ': call ', $call, ' has invalid uri_map: redirected to non-existing call ', $redirect_call);
                                        undef($calls);
                                        last;
                                    }
                                }
                            }
                            else {
                                Lim::WARN and $self->{logger}->warn('Can not serve ', $name, ': call ', $call, ' has invalid uri_map: ', $@);
                                undef($calls);
                                last;
                            }
                        }
                        unless (defined $calls) {
                            last;
                        }

                        $uri_maps->{$call} = $uri_map;
                    }

                    if (exists $call_def->{in}) {
                        unless (ref($call_def->{in}) eq 'HASH') {
                            Lim::WARN and $self->{logger}->warn('Can not serve ', $name, ': call ', $call, ' has invalid in parameter definition');
                            undef($calls);
                            last;
                        }

                        my @keys = keys %{$call_def->{in}};
                        unless (scalar @keys) {
                            Lim::WARN and $self->{logger}->warn('Can not serve ', $name, ': call ', $call, ' has invalid in parameter definition');
                            undef($calls);
                            last;
                        }

                        my @values = ($call_def->{in});
                        while (defined $calls and (my $value = shift(@values))) {
                            foreach my $key (keys %$value) {
                                if (ref($value->{$key}) eq 'HASH') {
                                    if (exists $value->{$key}->{''}) {
                                        eval {
                                            my $collection = Lim::RPC::Value::Collection->new($value->{$key}->{''});
                                            delete $value->{$key}->{''};
                                            $value->{$key} = $collection->set_children($value->{$key});
                                        };
                                        unless ($@) {
                                            push(@values, $value->{$key}->children);
                                            next;
                                        }
                                        Lim::WARN and $self->{logger}->warn('Unable to create Lim::RPC::Value::Collection: ', $@);
                                    }
                                    else {
                                        push(@values, $value->{$key});
                                        next;
                                    }
                                }
                                elsif (blessed $value->{$key}) {
                                    if ($value->{$key}->isa('Lim::RPC::Value')) {
                                        next;
                                    }
                                    if ($value->{$key}->isa('Lim::RPC::Value::Collection')) {
                                        push(@values, $value->{$key}->children);
                                        next;
                                    }
                                }
                                else {
                                    eval {
                                        $value->{$key} = Lim::RPC::Value->new($value->{$key});
                                    };
                                    unless ($@) {
                                        next;
                                    }
                                    Lim::WARN and $self->{logger}->warn('Unable to create Lim::RPC::Value: ', $@);
                                }

                                Lim::WARN and $self->{logger}->warn('Can not server ', $name, ': call ', $call, ' has invalid in parameter definition');
                                undef($calls);
                            }
                        }

                        unless (defined $calls) {
                            last;
                        }
                    }

                    if (exists $call_def->{out}) {
                        unless (ref($call_def->{out}) eq 'HASH') {
                            Lim::WARN and $self->{logger}->warn('Can not serve ', $name, ': call ', $call, ' has invalid out parameter definition');
                            undef($calls);
                            last;
                        }

                        my @keys = keys %{$call_def->{out}};
                        unless (scalar @keys) {
                            Lim::WARN and $self->{logger}->warn('Can not serve ', $name, ': call ', $call, ' has invalid out parameter definition');
                            undef($calls);
                            last;
                        }

                        my @values = ($call_def->{out});
                        while (defined $calls and (my $value = shift(@values))) {
                            foreach my $key (keys %$value) {
                                if (ref($value->{$key}) eq 'HASH') {
                                    if (exists $value->{$key}->{''}) {
                                        eval {
                                            my $collection = Lim::RPC::Value::Collection->new($value->{$key}->{''});
                                            delete $value->{$key}->{''};
                                            $value->{$key} = $collection->set_children($value->{$key});
                                        };
                                        unless ($@) {
                                            push(@values, $value->{$key}->children);
                                            next;
                                        }
                                        Lim::WARN and $self->{logger}->warn('Unable to create Lim::RPC::Value::Collection: ', $@);
                                    }
                                    else {
                                        push(@values, $value->{$key});
                                        next;
                                    }
                                }
                                elsif (blessed $value->{$key}) {
                                    if ($value->{$key}->isa('Lim::RPC::Value')) {
                                        next;
                                    }
                                    if ($value->{$key}->isa('Lim::RPC::Value::Collection')) {
                                        push(@values, $value->{$key}->children);
                                        next;
                                    }
                                }
                                else {
                                    eval {
                                        $value->{$key} = Lim::RPC::Value->new($value->{$key});
                                    };
                                    unless ($@) {
                                        next;
                                    }
                                    Lim::WARN and $self->{logger}->warn('Unable to create Lim::RPC::Value: ', $@);
                                }

                                Lim::WARN and $self->{logger}->warn('Can not server ', $name, ': call ', $call, ' has invalid out parameter definition');
                                undef($calls);
                            }
                        }

                        unless (defined $calls) {
                            last;
                        }
                    }

                    my $logger = $self->{logger};
                    weaken($logger);

                    foreach my $protocol_name (keys %{$self->{protocol}}) {
                        my $base = 'Lim::RPC::ProtocolCall::'.$protocol_name.'::'.ref($obj);
                        my $protocol_call = $base.'::'.$call;
                        my $protocol = $self->{protocol}->{$protocol_name};
                        weaken($protocol);
                        my $weak_obj = $obj;
                        weaken($weak_obj);
                        weaken($call_def);

                        if ($base->isa('UNIVERSAL') and $base->can($call)) {
                            next;
                        }

                        no strict 'refs';
                        *$protocol_call = sub {
                            unless (defined $protocol and defined $weak_obj and defined $call_def) {
                                return;
                            }
                            my ($self, $cb, $q, @args);
                            eval {
                               ($self, $cb, $q, @args) = $protocol->precall($call, @_);
                            };
                            if ($@) {
                                Lim::WARN and defined $logger and $logger->warn($weak_obj, '->', $call, '() precall failed: ', $@);
                                $weak_obj->Error($cb);
                                return;
                            }

                            Lim::RPC_DEBUG and defined $logger and $logger->debug('Call to ', $weak_obj, ' ', $call);

                            if (!defined $q) {
                                $q = {};
                            }
                            if (ref($q) ne 'HASH') {
                                Lim::WARN and defined $logger and $logger->warn($weak_obj, '->', $call, '() called without data as hash');
                                $weak_obj->Error($cb);
                                return;
                            }

                            if (exists $call_def->{in}) {
                                eval {
                                    Lim::RPC::V($q, $call_def->{in});
                                };
                                if ($@) {
                                    Lim::WARN and defined $logger and $logger->warn($weak_obj, '->', $call, '() data validation failed: ', $@);
                                    Lim::DEBUG and defined $logger and eval {
                                        use Data::Dumper;
                                        $logger->debug(Dumper($q));
                                        $logger->debug(Dumper($call_def->{in}));
                                    };
                                    $weak_obj->Error($cb);
                                    return;
                                }
                            }
                            elsif (%$q) {
                                Lim::WARN and defined $logger and $logger->warn($weak_obj, '->', $call, '() have data but no definition');
                                $weak_obj->Error($cb);
                                return;
                            }
                            $cb->set_call_def($call_def);

                            eval {
                                $weak_obj->$call($cb, $q, @args);
                            };
                            if ($@) {
                                Lim::WARN and defined $logger and $logger->warn($weak_obj, '->', $call, '() failed: ', $@);
                                $weak_obj->Error($cb);
                            }
                            return;
                        };
                    }
                }
            }
            unless ($calls) {
                next;
            }

            Lim::DEBUG and $self->{logger}->debug('serving ', $name);

            $self->{module}->{$name} = {
                name => $name,
                module => $module,
                obj => $obj,
                calls => $calls,
                uri_maps => $uri_maps
            };

            foreach my $protocol (values %{$self->{protocol}}) {
                Lim::DEBUG and $self->{logger}->debug('serving ', $name, ' to protocol ', $protocol->name);
                $protocol->serve($module, $name);
            }
            foreach my $transport (@{$self->{transports}}) {
                if (exists $self->{transport_modules}->{$transport}
                    and !exists $self->{transport_modules}->{$transport}->{$module->Name})
                {
                    next;
                }
                Lim::DEBUG and $self->{logger}->debug('serving ', $name, ' to transport ', $transport->name, ' at ', $transport->uri);
                $transport->serve($module, $name);
            }
        }
    }

    $self;
}

=head2 have_module

=cut

sub have_module {
    my ($self, $module) = @_;

    unless (exists $self->{module}->{$module}) {
        return;
    }

    return 1;
}

=head2 have_module_call

=cut

sub have_module_call {
    my ($self, $module, $call) = @_;

    unless (exists $self->{module}->{$module}) {
        return;
    }

    unless (exists $self->{module}->{$module}->{calls}->{$call}) {
        return;
    }

    return 1;
}

=head2 module_obj

=cut

sub module_obj {
    my ($self, $module) = @_;

    unless (exists $self->{module}->{$module}) {
        return;
    }

    return $self->{module}->{$module}->{obj};
}

=head2 module_class

=cut

sub module_class {
    my ($self, $module) = @_;

    unless (exists $self->{module}->{$module}) {
        return;
    }

    return $self->{module}->{$module}->{module};
}

=head2 module_obj_by_protocol

=cut

sub module_obj_by_protocol {
    my ($self, $module, $protocol) = @_;

    unless (exists $self->{module}->{$module}) {
        return;
    }

    unless (exists $self->{protocol}->{$protocol}) {
        return;
    }

    bless {}, 'Lim::RPC::ProtocolCall::'.$protocol.'::'.$self->{module}->{$module}->{module}.'::Server';
}

=head2 process_module_call_uri_map

=cut

sub process_module_call_uri_map {
    my ($self, $module, $call, $uri, $data) = @_;

    unless (exists $self->{module}->{$module}) {
        return;
    }

    unless (ref($data) eq 'HASH') {
        return;
    }

    unless (exists $self->{module}->{$module}->{uri_maps}->{$call}) {
        return;
    }

    return $self->{module}->{$module}->{uri_maps}->{$call}->process($uri, $data);
}

=head2 transports

=cut

sub transports {
    @{$_[0]->{transports}};
}

=head2 close

=cut

sub close {
    my ($self, $cb) = @_;

    unless (ref($cb) eq 'CODE') {
        confess '$cb is not CODE';
    }

    my $cv = AnyEvent->condvar;
    $cv->begin(sub {
        $cb->();
        $cv = undef;
    });

    foreach my $transport (@{$self->{transports}}) {
        $cv->begin;
        Lim::DEBUG and $self->{logger}->debug('Closing transport ', $transport->name);
        $transport->close(sub {
            $cv->end;
        });
    }
    $cv->end;

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

1; # End of Lim::RPC::Server
