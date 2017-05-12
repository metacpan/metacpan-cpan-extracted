use strict;
use warnings;

package Pod::Weaver::PluginBundle::SILEX;
our $VERSION = 'v0.0.2'; # VERSION

# Dependencies
use Moose 0.99;
use namespace::autoclean 0.09;

extends 'Pod::Weaver::PluginBundle::DAGOLDEN';

# ABSTRACT: SILEX's default Pod::Weaver config
#
# This file is part of Dist-Zilla-PluginBundle-SILEX
#
# This software is copyright (c) 2014 by SILEX.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::SILEX - SILEX's default Pod::Weaver config

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

This is a L<Pod::Weaver> PluginBundle.  It is roughly equivalent to the
following weaver.ini:

  [-WikiDoc]

  [@Default]

  [Support]
  perldoc = 0
  websites = none
  bugs = metadata
  bugs_content = ... stuff (web only, email omitted) ...
  repository_link = both
  repository_content = ... stuff ...

  [Contributors]

  [-Transformer]
  transformer = List

=head1 USAGE

This PluginBundle is used automatically with the C<@SILEX> L<Dist::Zilla>
plugin bundle.

It also has region collectors for:

=over 4

=item *

requires

=item *

construct

=item *

attr

=item *

method

=item *

func

=back

=for Pod::Coverage mvp_bundle_config

=head1 SEE ALSO

=over 4

=item *

L<Pod::Weaver::PluginBundle::DAGOLDEN>

=item *

L<Pod::Weaver>

=item *

L<Pod::Weaver::Plugin::WikiDoc>

=item *

L<Pod::Elemental::Transformer::List>

=item *

L<Pod::Weaver::Section::Contributors>

=item *

L<Pod::Weaver::Section::Support>

=item *

L<Dist::Zilla::Plugin::PodWeaver>

=back

=head1 AUTHOR

김도형 - Keedi Kim <keedi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by SILEX.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
