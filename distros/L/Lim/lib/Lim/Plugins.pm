package Lim::Plugins;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(blessed weaken);
use Module::Find qw(findsubmod);

use Lim ();

=encoding utf8

=head1 NAME

Lim::Plugins - Lim's plugin loader and container

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;
our $INSTANCE;

=head1 SYNOPSIS

=over 4

use Lim::Plugins;

Lim::Plugins->instance->Load;

=back

=head1 METHODS

=over 4

=cut

sub _new {
    my $this = shift;
    my $class = ref($this) || $this;
    my %args = ( @_ );
    my $self = {
        logger => Log::Log4perl->get_logger($class),
        plugin => {}
    };
    bless $self, $class;
    weaken($self->{logger});

    $self->Load;

    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);

    delete $self->{plugin};
}

END {
    undef($INSTANCE);
}

=item $instance = Lim::Plugins->instance

Returns the singelton instance of this class.

=cut

sub instance {
    $INSTANCE ||= Lim::Plugins->_new;
}

=item $instance->Load

Loads all plugins that exists on the system under Lim::Plugin::. Returns the
reference to itself even on error.

=cut

sub Load {
    my ($self) = @_;
    my @modules;

    if (Lim::Config->{plugin}->{load_all}) {
        @modules = findsubmod Lim::Plugin;
    }
    else {
        foreach (findsubmod Lim::Plugin) {
            my $name = $_;
            $name =~ s/.*:://o;
            if (exists Lim::Config->{plugin}->{load}->{$_}
                or exists Lim::Config->{plugin}->{load}->{$name})
            {
                push(@modules, $_);
            }
        }
    }

    foreach my $module (@modules) {
        if (exists Lim::Config->{plugin} and exists Lim::Config->{plugin}->{load}) {
            if (exists Lim::Config->{plugin}->{load}->{$module} and !Lim::Config->{plugin}->{load}->{$module}) {
                Lim::WARN and $self->{logger}->warn('Skipping ', $module, ' configured not to load.');
                next;
            }

            my $name = $module;
            $name =~ s/.*:://o;
            if (exists Lim::Config->{plugin}->{load}->{$name} and !Lim::Config->{plugin}->{load}->{$name}) {
                Lim::WARN and $self->{logger}->warn('Skipping ', $module, ' configured not to load.');
                next;
            }
        }

        if (exists $self->{plugin}->{$module}) {
            Lim::WARN and $self->{logger}->warn('Plugin ', $module, ' already loaded');
            next;
        }

        if ($module =~ /^([\w:]+)$/o) {
            $module = $1;
        }
        else {
            next;
        }

        my ($name, $description);
        eval {
            eval "require $module;";
            die $@ if $@;
            $name = $module->Name;
            $description = $module->Description;
        };

        if ($@) {
            Lim::WARN and $self->{logger}->warn('Unable to load plugin ', $module, ': ', $@);
            $self->{plugin}->{$module} = {
                name => $name,
                description => $description,
                module => $module,
                version => -1,
                loaded => 0,
                error => $@
            };
            next;
        }

        $self->{plugin}->{$module} = {
            name => $name,
            description => $description,
            module => $module,
            version => $module->VERSION,
            loaded => 1
        };
    }

    if (exists Lim::Config->{plugin} and exists Lim::Config->{plugin}->{load}) {
        foreach my $module (keys %{Lim::Config->{plugin}->{load}}) {
            unless (Lim::Config->{plugin}->{load}->{$module}) {
                next;
            }

            unless (exists $self->{plugin}->{$module} or exists $self->{plugin}->{'Lim::Plugin::'.$module}) {
                Lim::ERR and $self->{logger}->error('Required module ', $module, ' not found');
                # TODO Should we die here?
            }
        }
    }

    $self;
}

=item @modules = $instance->LoadedModules

Returns a list of loaded plugin's module name (eg Lim::Plugin::Example).

=cut

sub LoadedModules {
    my ($self) = @_;
    my @modules;

    foreach my $module (values %{$self->{plugin}}) {
        if ($module->{loaded}) {
            push(@modules, $module->{module});
        }
    }

    return @modules;
}

=item @modules = $instance->Loaded

Returns a list of hash references of loaded plugins.

=over 4

{
    name => Short name (eg Example),
    module => Module name (Lim::Plugin::Example),
    version => Version (Lim::Plugin::Example->VERSION),
    loaded => True or false if the plugin is loaded (True)
}

=back

=cut

sub Loaded {
    my ($self) = @_;
    my @modules;

    foreach my $module (values %{$self->{plugin}}) {
        if ($module->{loaded}) {
            push(@modules, $module);
        }
    }

    return @modules;
}

=item @modules = $instance->All

Returns a list of hash references of all known plugins, check C<Loaded> for how
the hash reference looks.

=cut

sub All {
    values %{$_[0]->{plugin}};
}

=back

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::Plugins

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

1; # End of Lim::Plugins
