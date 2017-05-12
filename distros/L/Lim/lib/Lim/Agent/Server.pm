package Lim::Agent::Server;

use common::sense;

use Lim ();
use Lim::Plugins ();

use base qw(Lim::Component::Server);

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

=head2 ReadVersion

=cut

sub ReadVersion {
    my ($self, $cb) = @_;
    
    $self->Successful($cb, { version => $VERSION });
}

=head2 ReadPlugins

=cut

sub ReadPlugins {
    my ($self, $cb) = @_;
    
    $self->Successful($cb, { plugin => [ {
        name => Lim::Agent->Name,
        description => Lim::Agent->Description,
        module => 'Lim::Agent',
        version => $VERSION,
        loaded => 1 },
        Lim::Plugins->instance->All
    ] });
}

=head2 ReadPlugin

=cut

sub ReadPlugin {
    my ($self, $cb, $q) = @_;
    my @plugins = ( Lim::Plugins->instance->All );
    my $result = {
        plugin => [ {
            name => Lim::Agent->Name,
            description => Lim::Agent->Description,
            module => 'Lim::Agent',
            version => $VERSION,
            loaded => 1
        } ]
    };

    foreach my $plugin (ref($q->{plugin}) eq 'ARRAY' ? @{$q->{plugin}} : $q->{plugin}) {
        foreach my $loaded (@plugins) {
            if (lc($loaded->{name}) eq $plugin->{name}) {
                push(@{$result->{plugin}}, $loaded);
            }
        }
    }
    $self->Successful($cb, $result);
}

=head2 ReadPluginVersion

=cut

sub ReadPluginVersion {
    my ($self, $cb, $q) = @_;
    my @plugins = ( Lim::Plugins->instance->All );
    my $result = {};

    foreach my $plugin (ref($q->{plugin}) eq 'ARRAY' ? @{$q->{plugin}} : $q->{plugin}) {
        if ($plugin->{name} eq Lim::Agent->Name) {
            push(@{$result->{plugin}}, {
                name => Lim::Agent->Name,
                version => $VERSION
            });
            next;
        }
        foreach my $loaded (@plugins) {
            if (lc($loaded->{name}) eq $plugin->{name}) {
                push(@{$result->{plugin}}, {
                    name => $loaded->{name},
                    version => $loaded->{version}
                });
            }
        }
    }
    $self->Successful($cb, $result);
}

=head2 ReadPluginLoaded

=cut

sub ReadPluginLoaded {
    my ($self, $cb, $q) = @_;
    my @plugins = ( Lim::Plugins->instance->All );
    my $result = {};

    foreach my $plugin (ref($q->{plugin}) eq 'ARRAY' ? @{$q->{plugin}} : $q->{plugin}) {
        if ($plugin->{name} eq Lim::Agent->Name) {
            push(@{$result->{plugin}}, {
                name => Lim::Agent->Name,
                loaded => 1
            });
            next;
        }
        foreach my $loaded (@plugins) {
            if (lc($loaded->{name}) eq $plugin->{name}) {
                push(@{$result->{plugin}}, {
                    name => $loaded->{name},
                    loaded => $loaded->{loaded}
                });
            }
        }
    }
    $self->Successful($cb, $result);
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

1; # End of Lim::Agent
