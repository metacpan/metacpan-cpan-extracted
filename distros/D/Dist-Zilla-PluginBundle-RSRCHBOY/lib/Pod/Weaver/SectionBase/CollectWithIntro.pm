#
# This file is part of Dist-Zilla-PluginBundle-RSRCHBOY
#
# This software is Copyright (c) 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Pod::Weaver::SectionBase::CollectWithIntro;
our $AUTHORITY = 'cpan:RSRCHBOY';
$Pod::Weaver::SectionBase::CollectWithIntro::VERSION = '0.077';
# ABSTRACT: Extends CollectWithIntro to provide a better default plugin name

use Moose;
use namespace::autoclean;
use autobox::Core;
use MooseX::AttributeShortcuts;
use MooseX::NewDefaults;

extends 'Pod::Weaver::Section::CollectWithIntro';

default_for plugin_name => sub { shift->ref->split(qr/::/)->pop };

__PACKAGE__->meta->make_immutable;
!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl Bowers Neil Romanov Sergey

=head1 NAME

Pod::Weaver::SectionBase::CollectWithIntro - Extends CollectWithIntro to provide a better default plugin name

=head1 VERSION

This document describes version 0.077 of Pod::Weaver::SectionBase::CollectWithIntro - released March 05, 2018 as part of Dist-Zilla-PluginBundle-RSRCHBOY.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla::PluginBundle::RSRCHBOY|Dist::Zilla::PluginBundle::RSRCHBOY>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/rsrchboy/dist-zilla-pluginbundle-rsrchboy/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
