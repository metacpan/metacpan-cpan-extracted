package Dist::Zilla::PluginBundle::IDOPEREL;

# ABSTRACT: IDOPEREL's plugin bundle for Dist::Zilla.

use Moose;
use namespace::autoclean;

with 'Dist::Zilla::Role::PluginBundle::Easy',
     'Dist::Zilla::Role::PluginBundle::PluginRemover',
     'Dist::Zilla::Role::PluginBundle::Config::Slicer';

our $VERSION = "1.001000";
$VERSION = eval $VERSION;

use Dist::Zilla::PluginBundle::Filter;
use Dist::Zilla::PluginBundle::Basic;
use Dist::Zilla::PluginBundle::Git;
use Dist::Zilla::Plugin::VersionFromModule;
use Dist::Zilla::Plugin::MetaJSON;
use Dist::Zilla::Plugin::MinimumPerl;
use Dist::Zilla::Plugin::AutoPrereqs;
use Dist::Zilla::Plugin::Prereqs;
use Dist::Zilla::Plugin::NextRelease;
use Dist::Zilla::Plugin::GitHub::Meta;
use Dist::Zilla::Plugin::TestRelease;
use Dist::Zilla::Plugin::ReadmeAnyFromPod;
use Dist::Zilla::Plugin::CopyFilesFromBuild;
use Dist::Zilla::Plugin::InstallGuide;
use Dist::Zilla::Plugin::CheckChangesHasContent;
use Dist::Zilla::Plugin::Test::DistManifest;
use Dist::Zilla::Plugin::Signature;
use Dist::Zilla::Plugin::Encoding;

=head1 NAME

Dist::Zilla::PluginBundle::IDOPEREL - IDOPEREL's plugin bundle for Dist::Zilla.

=head1 SYNOPSIS

In your dist.ini file:

	[@IDOPEREL]

=head1 DESCRIPTION

This module is a bundle of plugins for L<Dist::Zilla> that is regularly
used by me (Ido Perlmuter). If you find it suits your needs, feel free
to install and use it.

This bundle provides the following plugins and bundles:

      [@Filter]
      -bundle = @Basic
      -remove = Readme

      [@Git]

      [VersionFromModule]
      [AutoPrereqs]
      [CheckChangesHasContent]
      [Test::DistManifest]
      [GitHub::Meta]
      [InstallGuide]
      [MetaJSON]
      [MinimumPerl]
      [NextRelease]
      [ReadmeFromPod]
      [TestRelease]
      [Signature]

      [ReadmeAnyFromPod]
      type = markdown
      filename = README.md
      location = build

      [CopyFilesFromBuild]
      copy = README.md

      [Encoding]
      encoding = bytes
      match = \.(jpg|png|gif|gz|zip)$

=head1 INTERNAL METHODS

=head2 configure

=cut

sub configure {
	my $self = shift;

	$self->add_bundle(Filter => {
		-bundle => '@Basic',
		-remove => [qw/Readme/],
	});

	$self->add_bundle('Git');

	my @plugins = ('VersionFromModule');
	if ($self->payload->{auto_prereqs_skip}) {
		push(@plugins, ['AutoPrereqs' => { skip => $self->payload->{auto_prereqs_skip} }]);
	} else {
		push(@plugins, 'AutoPrereqs');
	}

	push(@plugins,
		'CheckChangesHasContent',
		'Test::DistManifest',
		'GitHub::Meta',
		'InstallGuide',
		'MetaJSON',
		'MinimumPerl',
		'NextRelease',
		'TestRelease',
		'Signature',
		[ 'ReadmeAnyFromPod' => { type => 'markdown', location => 'build', filename => 'README.md' } ],
            [ 'CopyFilesFromBuild' => { copy => 'README.md' } ],
		[ 'Encoding' => { encoding => 'bytes', match => '\.(jpg|png|gif|gz|zip)$' } ]
	);

	$self->add_plugins(@plugins);
}

__PACKAGE__->meta->make_immutable;

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dist-zilla-pluginbundle-idoperel at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-PluginBundle-IDOPEREL>. I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Dist::Zilla::PluginBundle::IDOPEREL

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-PluginBundle-IDOPEREL>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dist-Zilla-PluginBundle-IDOPEREL>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dist-Zilla-PluginBundle-IDOPEREL>

=item * Search CPAN

L<http://search.cpan.org/dist/Dist-Zilla-PluginBundle-IDOPEREL/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2016 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
