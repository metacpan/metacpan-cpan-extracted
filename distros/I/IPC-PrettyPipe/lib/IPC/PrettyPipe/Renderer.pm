package IPC::PrettyPipe::Renderer;

# ABSTRACT: role for renderer backends

use Moo::Role;

our $VERSION = '0.13';

use namespace::clean;

requires qw[ render ];

1;

#
# This file is part of IPC-PrettyPipe
#
# This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory renderer

=head1 NAME

IPC::PrettyPipe::Renderer - role for renderer backends

=head1 VERSION

version 0.13

=head1 SYNOPSIS

  package IPC::PrettyPipe::Render::My::Backend;

  sub render { }

  with 'IPC::PrettyPipe::Renderer';

=head1 DESCRIPTION

This role defines the required interface for rendering backends for
B<L<IPC::PrettyPipe>>.  Backend classes must consume this role.

=head1 METHODS

The following methods must be defined:

=over

=item B<render>

Return the rendered the pipeline.

=back

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-ipc-prettypipe@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=IPC-PrettyPipe

=head2 Source

Source is available at

  https://gitlab.com/djerius/ipc-prettypipe

and may be cloned from

  https://gitlab.com/djerius/ipc-prettypipe.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<IPC::PrettyPipe|IPC::PrettyPipe>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
