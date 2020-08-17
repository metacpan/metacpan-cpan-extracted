package Dist::Zilla::Plugin::Code;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.003';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Code - dynamically create plugins from a bundle

=head1 VERSION

Version 0.003

=head1 DESCRIPTION

=over 4

=item L<Dist::Zilla::Plugin::Code::AfterBuild>

something that runs after building is mostly complete

=item L<Dist::Zilla::Plugin::Code::AfterRelease>

something that runs after release is mostly complete

=item L<Dist::Zilla::Plugin::Code::BeforeArchive>

something that runs before the archive file is built

=item L<Dist::Zilla::Plugin::Code::BeforeBuild>

something that runs before building really begins

=item L<Dist::Zilla::Plugin::Code::BeforeRelease>

something that runs before release really begins

=item L<Dist::Zilla::Plugin::Code::BuildRunner>

something used as a delegating agent during 'dzil run'

=item L<Dist::Zilla::Plugin::Code::EncodingProvider>

something that sets a files' encoding

=item L<Dist::Zilla::Plugin::Code::FileFinder>

something that finds files within the distribution

=item L<Dist::Zilla::Plugin::Code::FileGatherer>

something that gathers files into the distribution

=item L<Dist::Zilla::Plugin::Code::FileMunger>

something that munges files within the distribution

=item L<Dist::Zilla::Plugin::Code::FilePruner>

something that prunes files from the distribution

=item L<Dist::Zilla::Plugin::Code::Initialization>

something that runs when plugins are initialized

=item L<Dist::Zilla::Plugin::Code::InstallTool>

something that creates an install program for a dist

=item L<Dist::Zilla::Plugin::Code::LicenseProvider>

something that offers a license for a dist

=item L<Dist::Zilla::Plugin::Code::MetaProvider>

something that provides data to merge into the distribution metadata

=item L<Dist::Zilla::Plugin::Code::NameProvider>

something that provides a name for the dist

=item L<Dist::Zilla::Plugin::Code::PrereqSource>

something that registers prereqs of the dist

=item L<Dist::Zilla::Plugin::Code::ReleaseStatusProvider>

something that provides a release status for the dist

=item L<Dist::Zilla::Plugin::Code::Releaser>

something that makes a release of the dist

=item L<Dist::Zilla::Plugin::Code::TestRunner>

something that tests the dist

=item L<Dist::Zilla::Plugin::Code::VersionProvider>

something that provides a version number for the dist

=item L<Dist::Zilla::PluginBundle::Code>

a dynamic bundle

=back

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/Dist-Zilla-Plugin-Code/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/Dist-Zilla-Plugin-Code>

  git clone https://github.com/skirmess/Dist-Zilla-Plugin-Code.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=head1 SEE ALSO

L<Dist::Zilla>

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
