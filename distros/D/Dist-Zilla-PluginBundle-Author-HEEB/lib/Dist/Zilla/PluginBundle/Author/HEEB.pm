use strict;
use warnings;
package Dist::Zilla::PluginBundle::Author::HEEB;
$Dist::Zilla::PluginBundle::Author::HEEB::VERSION = '1.0.1';
# ABSTRACT: plugin bundle for distributions built by HEEB
use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

use namespace::autoclean;

sub configure {
    my ($self) = @_;

    $self->add_plugins(
        qw(
            GatherDir
            PruneCruft
        ),
        [
            PruneFiles => { filename => 'debian' },
        ],
        qw(
            ManifestSkip
            MetaYAML
            License
            Readme
            PodWeaver
            PkgVersion
            PodVersion
            PodCoverageTests
            PodSyntaxTests
            ExtraTests
            ExecDir
            ShareDir
            AutoPrereqs
            Test::Perl::Critic
            MakeMaker
            Manifest
            FakeRelease
        )
    );
}

__PACKAGE__->meta->make_immutable;
1;

#pod =head1 DESCRIPTION
#pod
#pod This bundle is meant to allow consistency and control over the
#pod build process for distributions built by PAUSE author HEEB.
#pod It started out as a copy of the
#pod L<@Classic|Dist::Zilla::PluginBundle::Classic> plugin bundle.
#pod
#pod The list of Dist::Zilla plugins it includes is best seen with
#pod C<perldoc -m Dist::Zilla::PluginBundle::Author::HEEB>
#pod
#pod =head1 SEE ALSO
#pod
#pod L<@Basic|Dist::Zilla::PluginBundle::Basic>
#pod L<@Classic|Dist::Zilla::PluginBundle::Classic>
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::HEEB - plugin bundle for distributions built by HEEB

=head1 VERSION

version 1.0.1

=head1 AUTHOR

Elmar S. Heeb <elmar@heebs.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Elmar S. Heeb.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
