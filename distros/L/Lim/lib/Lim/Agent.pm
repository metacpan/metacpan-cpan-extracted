package Lim::Agent;

use common::sense;

use Lim ();

use base qw(Lim::Component);

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

=head2 Name

=cut

sub Name {
    'Agent';
}

=head2 Description

=cut

sub Description {
    'This is the core plugin of the Lim Agent Daemon, it manage other plugins and provides system information.';
}

=head2 Calls

=cut

sub Calls {
    {
        ReadVersion => {
            out => {
                version => 'string'
            }
        },
        ReadPlugins => {
            out => {
                plugin => {
                    name => 'string',
                    description => 'string optional',
                    module => 'string',
                    version => 'string',
                    loaded => 'bool'
                }
            }
        },
        ReadPlugin => {
            uri_map => [
                'plugin.name=\w+',
                'plugin.name=\w+/version => ReadPluginVersion',
                'plugin.name=\w+/loaded => ReadPluginLoaded'
            ],
            in => {
                plugin => {
                    name => 'string'
                }
            },
            out => {
                plugin => {
                    name => 'string',
                    description => 'string optional',
                    module => 'string',
                    version => 'string',
                    loaded => 'bool'
                }
            }
        },
        ReadPluginVersion => {
            uri_map => [
                'plugin.name=\w+'
            ],
            in => {
                plugin => {
                    name => 'string'
                }
            },
            out => {
                plugin => {
                    name => 'string',
                    version => 'string'
                }
            }
        },
        ReadPluginLoaded => {
            uri_map => [
                'plugin.name=\w+'
            ],
            in => {
                plugin => {
                    name => 'string'
                }
            },
            out => {
                plugin => {
                    name => 'string',
                    loaded => 'bool'
                }
            }
        }
    };
}

=head2 Commands

=cut

sub Commands {
    {
        version => 1,
        plugins => 1
    };
}

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::Agent

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
