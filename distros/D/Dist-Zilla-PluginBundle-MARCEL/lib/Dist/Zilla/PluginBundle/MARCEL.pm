use 5.008;
use strict;
use warnings;

package Dist::Zilla::PluginBundle::MARCEL;
$Dist::Zilla::PluginBundle::MARCEL::VERSION = '1.161760';
# ABSTRACT: Build and release a distribution like MARCEL
use Moose;
use Moose::Autobox;

use Dist::Zilla::PluginBundle::Git ();

with 'Dist::Zilla::Role::PluginBundle',
     'Dist::Zilla::Role::PluginBundle::PluginRemover',
     'Dist::Zilla::Role::PluginBundle::Config::Slicer',
     'Dist::Zilla::Role::BundleDeps';
sub mvp_multivalue_args { qw(weaver_finder) }

sub bundle_config {
    my ($self, $section) = @_;

    # my $class = ref($self) || $self;
    my $arg = $section->{payload};

    # params for AutoVersion
    my $major_version =
      defined $arg->{major_version} ? $arg->{major_version} : 1;
    my $version_format =
        q<{{ $major }}.{{ cldr('yyDDD') }}>
      . sprintf('%01u', ($ENV{N} || 0))
      . ($ENV{DEV} ? (sprintf '_%03u', $ENV{DEV}) : '');

    # params for autoprereq
    my $prereq_params =
      defined $arg->{skip_prereq}
      ? { skip => $arg->{skip_prereq} }
      : {};

    # params for compiletests
    my $compile_params = {
      ':version' => '1.100220',
      defined $arg->{fake_home} ? (fake_home => $arg->{fake_home}) : (),
    };

    # params for pod weaver
    $arg->{weaver} ||= 'pod';
    my $pod_weaver_params = { config_plugin => '@MARCEL' };
    if (defined $arg->{weaver_finder}) {
        $pod_weaver_params->{finder} = $arg->{weaver_finder};
    }

    # long list of plugins
    my @wanted = (

        # -- static meta-information
        [   AutoVersion => {
                major     => $major_version,
                format    => $version_format,
                time_zone => 'Europe/Vienna',
            }
        ],

        # -- fetch & generate files
        # README will be generated from POD
        [ GatherDir              => { 'exclude_match' => [ '^README$' ] } ],
        [ 'Test::Compile'        => $compile_params ],
        [ 'Test::Perl::Critic'   => {} ],
        [ MetaTests              => {} ],
        [ PodCoverageTests       => {} ],
        [ PodSyntaxTests         => {} ],
        [ 'Test::PodSpelling'    => { stopwords => [ qw<CPAN multi> ] } ],
        [ 'Test::Kwalitee'       => {} ],
        [ 'Test::Portability'    => {} ],
        [ 'Test::Synopsis'       => {} ],
        [ 'Test::MinimumVersion' => {} ],
        [ HasVersionTests        => {} ],
        [ 'Test::CheckChanges'   => {} ],
        [ 'Test::DistManifest'   => {} ],
        [ 'Test::UnusedVars'     => {} ],
        [ 'Test::NoTabs'         => {} ],
        [ 'Test::EOL'            => {} ],
        [ InlineFilesMARCEL      => {} ],
        [ 'Test::ReportPrereqs'  => {} ],

        # -- remove some files
        [ PruneCruft   => {} ],
        [ PruneFiles   => { filenames => [qw(dist.ini)] } ],
        [ ManifestSkip => {} ],

        # -- get prereqs
        [ AutoPrereqs => $prereq_params ],

        # -- gather metadata
        [ Repository => {} ],
        [ Bugtracker => {} ],
        [ Homepage   => {} ],

        # -- munge files
        [ ExtraTests          => {} ],
        [ NextRelease         => {} ],
        [ PkgVersion          => {} ],
        (   $arg->{weaver} eq 'task'
            ? [ 'TaskWeaver' => {} ]
            : [ 'PodWeaver' => $pod_weaver_params ]
        ),

        # -- dynamic meta-information
        [ ExecDir                 => {} ],
        [ ShareDir                => {} ],
        [ 'MetaProvides::Package' => {} ],

        # -- generate meta files
        [ License       => {} ],
        [ MakeMaker     => {} ],
        [ MetaYAML      => {} ],
        [ MetaJSON      => {} ],
        [ Pod2Readme    => {} ],
        [ InstallGuide  => {} ],
        [ Manifest      => {} ],    # should come last

        # -- keep a copy of generated files in the repo
        [ CopyFilesFromBuild   => { copy     => [ 'README' ] } ],

        # -- release
        [ CheckChangeLog => {} ],

        #[ @Git],
        [ UploadToCPAN => {} ],
    );

    # create list of plugins
    my @plugins;
    for my $wanted (@wanted) {
        my ($name, $arg) = @$wanted;
        my $class = "Dist::Zilla::Plugin::$name";
        push @plugins, [ "$section->{name}/$name" => $class => $arg ];
    }

    # add git plugins
    my @gitplugins = Dist::Zilla::PluginBundle::Git->bundle_config(
        {   name    => "$section->{name}/Git",
            payload => {},
        }
    );
    push @plugins, @gitplugins;
    return @plugins;
}
__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=for test_synopsis 1;
__END__

=for stopwords AutoPrereqs AutoVersion Test::Compile PodWeaver TaskWeaver PluginRemover
Quelin Mengu Mengué

=head1 NAME

Dist::Zilla::PluginBundle::MARCEL - Build and release a distribution like MARCEL

=head1 VERSION

version 1.161760

=head1 SYNOPSIS

In your F<dist.ini>:

    [@MARCEL]
    major_version = 1          ; this is the default
    weaver        = pod        ; default, can also be 'task'
    skip_prereq   = ::Test$    ; no default

This bundle implements the L<PluginRemover|Dist::Zilla::PluginBundle::PluginRemover>
and L<Config::Slicer|Dist::Zilla::PluginBundle::Config::Slicer> roles.

=head1 DESCRIPTION

This is a plugin bundle to load all plugins that I am using. It is
equivalent to:

    [AutoVersion]

    ; -- fetch & generate files
    [GatherDir]
    exclude_match = ^README$
    [Test::Compile]
    [Test::Perl::Critic]
    [MetaTests]
    [PodCoverageTests]
    [PodSyntaxTests]
    [Test::PodSpelling]
    stopwords = CPAN
    stopwords = multi
    [Test::Kwalitee]
    [Test::Portability]
    [Test::Synopsis]
    [Test::MinimumVersion]
    [HasVersionTests]
    [Test::CheckChanges]
    [Test::DistManifest]
    [Test::UnusedVars]
    [Test::NoTabs]
    [Test::EOL]
    [InlineFilesMARCEL]
    [Test::ReportPrereqs]

    ; -- remove some files
    [PruneCruft]
    [PruneFiles]
    filenames = dist.ini

    [ManifestSkip]

    ; -- get prereqs
    [AutoPrereqs]

    ; -- gather metadata
    [Repository]
    [Bugtracker]
    [Homepage]

    ; -- munge files
    [ExtraTests]
    [NextRelease]
    [PkgVersion]
    [PodWeaver]
    config_plugin = '@MARCEL'

    ; -- dynamic meta-information
    [ExecDir]
    [ShareDir]
    [MetaProvides::Package]

    ; -- generate meta files
    [License]
    [MakeMaker]
    [MetaYAML]
    [MetaJSON]
    [Pod2Readme]
    [InstallGuide]
    [Manifest] ; should come last

    ; -- keep a copy in the repo
    [CopyFilesFromBuild]
    copy = README

    ; -- release
    [CheckChangeLog]
    [@Git]
    [UploadToCPAN]

The following options are accepted:

=over 4

=item * C<major_version> - passed as C<major> option to the
L<AutoVersion|Dist::Zilla::Plugin::AutoVersion> plugin. Default to 1.

=item * C<weaver> - can be either C<pod> (default) or C<task>, to load
respectively either L<PodWeaver|Dist::Zilla::Plugin::PodWeaver> or
L<TaskWeaver|Dist::Zilla::Plugin::TaskWeaver>.

=item * C<weaver_finder> - a multi-value argument that overrides the default
file finders used by L<PodWeaver|Dist::Zilla::Plugin::PodWeaver>.

=item * C<skip_prereq> - passed as C<skip> option to the
L<AutoPrereqs|Dist::Zilla::Plugin::AutoPrereqs> plugin if set. No default.

=item * C<fake_home> - passed to
L<Test::Compile|Dist::Zilla::Plugin::Test::Compile> to control whether
to fake home.

=back

=head1 METHODS

=head2 mvp_multivalue_args

Defines that C<weaver_finder> is a multi-value argument.

=head2 bundle_config

Defines the bundle's contents and passes on this bundle's configuration to the
individual plugins as described above.

=head1 SEE ALSO

=over 4

=item *

L<Pod::Weaver::PluginBundle::MARCEL>

=item *

L<Dist::Zilla::Role::PluginBundle::PluginRemover>

=item *

L<Dist::Zilla::Role::PluginBundle::Config::Slicer>

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-PluginBundle-MARCEL>.

=head1 AVAILABILITY

The project homepage is L<http://search.cpan.org/dist/Dist-Zilla-PluginBundle-MARCEL/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::PluginBundle::MARCEL/>.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Jerome Quelin <jquelin@cpan.org>

=item *

Olivier Mengue <dolmen@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Olivier Mengué.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
