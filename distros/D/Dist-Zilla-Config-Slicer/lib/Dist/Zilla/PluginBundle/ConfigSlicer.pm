# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of Dist-Zilla-Config-Slicer
#
# This software is copyright (c) 2011 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Dist::Zilla::PluginBundle::ConfigSlicer;
our $AUTHORITY = 'cpan:RWSTAUNER';
# ABSTRACT: Load another bundle and override its plugin configurations
$Dist::Zilla::PluginBundle::ConfigSlicer::VERSION = '0.201';
use Moose;

extends 'Dist::Zilla::PluginBundle::Filter';
with qw(
  Dist::Zilla::Role::PluginBundle::Config::Slicer
);

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS

=head1 NAME

Dist::Zilla::PluginBundle::ConfigSlicer - Load another bundle and override its plugin configurations

=head1 VERSION

version 0.201

=head1 SYNOPSIS

  ; in your dist.ini:

  [@ConfigSlicer]
  -bundle = @Classic
  -remove = PodVersion
  -remove = Manifest
  option = for_classic
  ManifestSkip.skipfile = something.weird

=head1 DESCRIPTION

This plugin bundle actually wraps and modifies another plugin bundle.
It extends L<< C<@Filter>|Dist::Zilla::PluginBundle::Filter >>
and additionally consumes
L<Dist::Zilla::Role::PluginBundle::Config::Slicer|Dist::Zilla::Role::PluginBundle::Config::Slicer>
so that any plugin options will be passed in.

This way you can override the plugin configuration
for any bundle that doesn't consume
L<Dist::Zilla::Role::PluginBundle::Config::Slicer|Dist::Zilla::Role::PluginBundle::Config::Slicer>
as if it did!

=for test_synopsis 1;
__END__

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::PluginBundle::Filter>

=item *

L<Dist::Zilla::Role::PluginBundle::Config::Slicer>

=back

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
