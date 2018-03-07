#
# This file is part of Dist-Zilla-PluginBundle-RSRCHBOY
#
# This software is Copyright (c) 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Pod::Weaver::Section::RSRCHBOY::LazyAttributes;
our $AUTHORITY = 'cpan:RSRCHBOY';
$Pod::Weaver::Section::RSRCHBOY::LazyAttributes::VERSION = '0.077';
# ABSTRACT: Prefaced lazy attributes section

use Moose;
use namespace::autoclean;
use autobox::Core;
use MooseX::NewDefaults;

extends 'Pod::Weaver::SectionBase::CollectWithIntro';

default_for command => 'lazyatt';

default_for content => [
    'These attributes are lazily constructed from another source (e.g.',
    'required attributes, external source, a BUILD() method, or some combo',
    'thereof). You can set these values at construction time, though this is',
    'generally neither required nor recommended.',
]->join(q{ });

__PACKAGE__->meta->make_immutable;
!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl Bowers Neil Romanov Sergey

=head1 NAME

Pod::Weaver::Section::RSRCHBOY::LazyAttributes - Prefaced lazy attributes section

=head1 VERSION

This document describes version 0.077 of Pod::Weaver::Section::RSRCHBOY::LazyAttributes - released March 05, 2018 as part of Dist-Zilla-PluginBundle-RSRCHBOY.

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
