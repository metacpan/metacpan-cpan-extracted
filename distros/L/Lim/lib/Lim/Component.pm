package Lim::Component;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(blessed);

use Lim ();
use Lim::RPC::Value ();
use Lim::RPC::Value::Collection ();
use Lim::RPC::Call ();

=encoding utf8

=head1 NAME

Lim::Component - Base class for plugins

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;

=head1 SYNOPSIS

=over 4

package Lim::Plugin::MyPlugin;

use base qw(Lim::Component);

sub Name {
    'MyPlugin';
}

sub Calls {
    {
        ReadVersion => {
            out => {
                version => 'string'
            }
        }
    };
}

sub Commands {
    {
        version => 1
    };
}

=back

=head1 DESCRIPTION

This is the base class of all plugins in Lim. It defines the name, RPC calls and
CLI commands. It must be present for any plugin to work but the different plugin
parts does not have to exist everywhere. For example the CLI part does not have
to have the Server and Client but it will most likly have the Client part if you
want to communicate with the Server.

=head1 METHODS

=over 4

=item $plugin_name = Lim::Plugin::MyPlugin->Name

Returns the plugin's name.

This function must be overloaded or it will L<confess>.

=cut

sub Name {
    confess 'Name not overloaded';
}

=item $plugin_description = Lim::Plugin::MyPlugin->Description

Returns the plugin's description.

=cut

sub Description {
    'No description for this plugin';
}

=item $call_hash_ref = Lim::Plugin::MyPlugin->Calls

Returns a hash reference to the calls that can be made to this plugin, used both
in Server and Client to verify input and output arguments.

Read more about this in L<Lim::Component::Server>.

This function must be overloaded or it will L<confess>.

=cut

sub Calls {
    confess 'Calls not overloaded';
}

=item $command_hash_ref = Lim::Plugin::MyPlugin->Commands

Returns a hash reference to the CLI commands that can be made by this plugin.

This function must be overloaded or it will L<confess>.

=cut

sub Commands {
    confess 'Commands not overloaded';
}

=item $cli = Lim::Plugin::MyPlugin->CLI

Create a CLI object of the plugin, read more about this in
L<Lim::Component::CLI>.

=cut

sub CLI {
    my $self = shift;

    if (ref($self)) {
        confess __PACKAGE__, ': Should not be called with refered/blessed argument';
    }
    unless (defined $self) {
        confess __PACKAGE__, ': CLI not called correctly, should be Module->CLI';
    }
    $self .= '::CLI';

    eval 'use '.$self.' ();';
    if ($@) {
        return;
    }

    $self->new(@_);
}

=item $client = Lim::Plugin::MyPlugin->Client

Create a Client object of the plugin, read more about this in
L<Lim::Component::Client>.

=cut

sub Client {
    my $self = shift;

    if (ref($self)) {
        confess __PACKAGE__, ': Should not be called with refered/blessed argument';
    }
    unless (defined $self) {
        confess __PACKAGE__, ': Client not called correctly, should be Module->Client';
    }

    # TODO: Can we check if $self->can(...) ?
    my $calls = $self->Calls;
    my $plugin = $self->Name;
    $self .= '::Client';

    eval 'use '.$self.' ();';
    if ($@) {
        return;
    }

    if ($self->can('__lim_bootstrapped')) {
        return $self->new(@_);
    }

    no strict 'refs';
    foreach my $call (keys %$calls) {
        unless ($self->can($call)) {
            my $sub = $self.'::'.$call;
            my $call_def = $calls->{$call};

            unless (ref($call_def) eq 'HASH') {
                confess __PACKAGE__, ': Can not create client: call ', $call, ' has invalid definition';
            }

            if (exists $call_def->{in}) {
                unless (ref($call_def->{in}) eq 'HASH') {
                    confess __PACKAGE__, ': Can not create client: call ', $call, ' has invalid in parameter definition';
                }

                my @keys = keys %{$call_def->{in}};
                unless (scalar @keys) {
                    confess __PACKAGE__, ': Can not create client: call ', $call, ' has invalid in parameter definition';
                }

                my @values = ($call_def->{in});
                while (defined (my $value = shift(@values))) {
                    foreach my $key (keys %$value) {
                        if (ref($value->{$key}) eq 'HASH') {
                            if (exists $value->{$key}->{''}) {
                                my $collection = Lim::RPC::Value::Collection->new($value->{$key}->{''});
                                delete $value->{$key}->{''};
                                $value->{$key} = $collection->set_children($value->{$key});
                                push(@values, $value->{$key}->children);
                            }
                            else {
                                push(@values, $value->{$key});
                            }
                            next;
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
                            $value->{$key} = Lim::RPC::Value->new($value->{$key});
                            next;
                        }

                        confess __PACKAGE__, ': Can not create client: call ', $call, ' has invalid in parameter definition';
                    }
                }
            }

            if (exists $call_def->{out}) {
                unless (ref($call_def->{out}) eq 'HASH') {
                    confess __PACKAGE__, ': Can not create client: call ', $call, ' has invalid out parameter definition';
                }

                my @keys = keys %{$call_def->{out}};
                unless (scalar @keys) {
                    confess __PACKAGE__, ': Can not create client: call ', $call, ' has invalid out parameter definition';
                }

                my @values = ($call_def->{out});
                while (defined $calls and (my $value = shift(@values))) {
                    foreach my $key (keys %$value) {
                        if (ref($value->{$key}) eq 'HASH') {
                            if (exists $value->{$key}->{''}) {
                                my $collection = Lim::RPC::Value::Collection->new($value->{$key}->{''});
                                delete $value->{$key}->{''};
                                $value->{$key} = $collection->set_children($value->{$key});
                                push(@values, $value->{$key}->children);
                            }
                            else {
                                push(@values, $value->{$key});
                            }
                            next;
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
                            $value->{$key} = Lim::RPC::Value->new($value->{$key});
                            next;
                        }

                        confess __PACKAGE__, ': Can not create client: call ', $call, ' has invalid out parameter definition';
                    }
                }
            }

            *$sub = sub {
                unless (Lim::RPC::Call->new($plugin, $call, $call_def, @_)) {
                    confess __PACKAGE__, ': Unable to create Lim::RPC::Call for ', $sub;
                }
            };
        }
    }

    my $sub = $self.'::__lim_bootstrapped';
    *$sub = sub {
        1;
    };

    $self->new(@_);
}

=item $client = Lim::Plugin::MyPlugin->Server

Create a Server object of the plugin, read more about this in
L<Lim::Component::Server>.

=cut

sub Server {
    my $self = shift;

    if (ref($self)) {
        confess __PACKAGE__, ': Should not be called with refered/blessed argument';
    }
    unless (defined $self) {
        confess __PACKAGE__, ': Server not called correctly, should be Module->Server';
    }
    $self .= '::Server';

    eval 'use '.$self.' ();';
    if ($@) {
        return;
    }

    $self->new(@_);
}

=back

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::Component

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

1; # End of Lim::Component
