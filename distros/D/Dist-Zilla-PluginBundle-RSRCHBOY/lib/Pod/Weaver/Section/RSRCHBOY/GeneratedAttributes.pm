#
# This file is part of Dist-Zilla-PluginBundle-RSRCHBOY
#
# This software is Copyright (c) 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Pod::Weaver::Section::RSRCHBOY::GeneratedAttributes;
our $AUTHORITY = 'cpan:RSRCHBOY';
$Pod::Weaver::Section::RSRCHBOY::GeneratedAttributes::VERSION = '0.077';
# ABSTRACT: Prefaced generated-only attributes

use Moose;
use namespace::autoclean;
use MooseX::NewDefaults;

extends 'Pod::Weaver::SectionBase::CollectWithIntro';

default_for command => 'genatt';

default_for content => join(q{ },
    'These attributes have their values built or supplied internally by the',
    'class; generally through a default, a builder, a BUILD method, a',
    "private writer, or some other mechanisim that you shouldn't be",
    'touching, anyways.',
);

__PACKAGE__->meta->make_immutable;
!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl Bowers Neil Romanov Sergey

=head1 NAME

Pod::Weaver::Section::RSRCHBOY::GeneratedAttributes - Prefaced generated-only attributes

=head1 VERSION

This document describes version 0.077 of Pod::Weaver::Section::RSRCHBOY::GeneratedAttributes - released March 05, 2018 as part of Dist-Zilla-PluginBundle-RSRCHBOY.

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
