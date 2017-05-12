use strict;
use warnings;
use utf8;

package Dist::Zilla::PluginBundle::Author::LESPEA;
$Dist::Zilla::PluginBundle::Author::LESPEA::VERSION = '1.008000';
BEGIN {
  $Dist::Zilla::PluginBundle::Author::LESPEA::AUTHORITY = 'cpan:LESPEA';
}

# ABSTRACT: LESPEA's Dist::Zilla Configuration

use Moose;
use Carp;
with 'Dist::Zilla::Role::PluginBundle::Easy';





#  Declare which options can be specified multiple times
sub mvp_multivalue_args { return qw( -remove copy_file move_file ) }



#  Returns true for strings of 'true', 'yes', or positive numbers;
#  false for for 'false', 'no', or 0; and dies otherwise
sub _parse_bool {
    my $setting = shift // q{};

    return 1 if $setting =~ m{^(?:true|yes|1)$}xsmi;
    return   if $setting =~ m{^(?:false|no|0)$}xsmi;

    die "Invalid boolean value $setting. Valid values are true/yes/1 or false/no/0";
}





#  Setup DZIL how I like it
sub configure {
    my $self = shift;

    my $defaults = {
        # By default release to cpan
        release => 'real',

        # Include dotfiles in the package
        include_dotfiles => 0,

        # Archive releases
        archive => 1,
        archive_directory => 'releases',

        # Copy README.pod from build dir to dist dir, for Github and suchlike.
        #copy_file => [ ],
        #move_file => [ ],

        # Add CPAN meta-info (adds git stuff too)
        add_meta => 1,

        # Assume that synopsis is perl code and should compile cleanly.
        compile_synopsis => 1,
    };

    my %args = (%$defaults, %{$self->payload});


    #  Actually set everything up
    return if _add_variable($self, %args);
    _add_static($self);

    return;
}



#  Add the "variable" plugins
sub _add_variable {
    my ($self, %args) = @_;

    # Use the @Filter bundle to handle '-remove'.
    if ($args{'-remove'}) {
        $self->add_bundle('@Filter' => { %args, -bundle => '@Author::LESPEA' });  ## no critic 'RequireInterpolationOfMetachars'
        return 1;
    }

    #   Bring everything together so we can start processing everything
    if ($args{include_dotfiles}) {
        $self->add_plugins( ['GatherDir' => {include_dotfiles => 1}] );
    }
    else {
        $self->add_plugins( 'GatherDir' );
    }

    # Copy files from build dir
    my %copy_args;
    $copy_args{copy} = $args{copy_file}  if  defined $args{copy_file};
    $copy_args{move} = $args{move_file}  if  defined $args{move_file};

    $self->add_plugins(
        [ 'CopyFilesFromBuild' => \%copy_args],
    );

    # Choose release plugin
    if (lc $args{release} eq 'real') {
        $self->add_plugins('UploadToCPAN');
    }
    elsif (lc $args{release} eq 'fake') {
        $self->add_plugins('FakeRelease');
    }
    elsif (lc $args{release} eq 'none') {
        # No release plugin
    }
    else {
        $self->add_plugins("$_")
    }

    # Choose whether and where to archive releases
    if (_parse_bool($args{archive})) {
        $self->add_plugins(
            ['ArchiveRelease' => {
                directory => $args{archive_directory},
            } ],
        );
    }

    if (_parse_bool($args{add_meta})) {
        $self->add_plugins(
            ['AutoMetaResources' => {
                'homepage'          => 'http://search.cpan.org/dist/%{dist}',
                'bugtracker.rt'     => 1,
                'repository.github' => 'user:lespea',
            }],
            'Authority',
        );
    }

    # Decide whether to test SYNOPSIS for syntax.
    if (_parse_bool($args{compile_synopsis})) {
        $self->add_plugins('Test::Synopsis');
    }

    return;
}



#  Add the "static" plugins
sub _add_static {
    my $self = shift;

    $self->add_plugins(
        ################################
        ##        PRE-PROCESS         ##
        ################################
        #   Set all our version strings
        'PkgVersion',

        #   Generates all the pod documentation into its final form
        'PodWeaver',

        #   Auto generate the next release info into the change file
        'NextRelease',



        ################################
        ##          PRE-REQS          ##
        ################################

        #   Guess the minimum version of perl required
        'MinimumPerl',

        #   Get all of the modules used
        'AutoPrereqs',

        #   Put all the dzil modules used into the meta data
        'MetaConfig',



        ################################
        ##           TESTS            ##
        ################################

        #  Pretty much every test plugin available
        'Test::Compile',
        'ConsistentVersionTest',
        'Test::Perl::Critic',
        'Test::DistManifest',
        'HasVersionTests',
        'Test::Kwalitee',
        'MetaTests',
        'Test::MinimumVersion',
        'Test::NoTabs',
        'Test::EOL',
        'PodCoverageTests',
        'PodSyntaxTests',
        'Test::Portability',
        #'Test::UnusedVars',
        'Test::CPAN::Changes',
        'SpellingCommonMistakesTests',

        #   Move all the xt/*.t files into the normal test directory
        'ExtraTests',



        ################################
        ##       FILE ARRANGING       ##
        ################################

        #   Remove junk that isn't needed in the package
        'PruneCruft',
        #['PruneCruft' => { except => 'share/.*' }],
        'ManifestSkip',

        #   If there is a "bin" folder then install any scripts in there as programs
        'ExecDir',

        #   Install any thing that's in "share" into the global share dir
        'ShareDir',

        #   All the modules we're using (for test reporting)
        'ReportVersions::Tiny',

        #   Generate the builders that will install the module(s)
        'ModuleBuild',
        'MakeMaker',
        'DualBuilders',



        ################################
        ##         META DATA          ##
        ################################

        #   Don't let cpan index the following dirs
        ['MetaNoIndex' => {
            directory => [qw/ inc t xt utils share example examples /],
            file      => [qw/ README.html /],
        }],

        #   Generate the meta data
        'License',
        'InstallGuide',
        'MetaJSON',
        'MetaYAML',

        #   Readme's
        ['ReadmeAnyFromPod', 'html.build', {
            filename => 'README.html',
            type => 'html',
        }],
        ['ReadmeAnyFromPod', 'text.build', {
            filename => 'README',
            type => 'text',
        }],
        # This one gets copied out of the build dir by default, and does not become part of the dist.
        ['ReadmeAnyFromPod', 'pod.root', {
            filename => 'README.pod',
            type => 'pod',
            location => 'root',
        }],

        #   Generates the manifest (needs to come last!)
        'Manifest',



        ################################
        ##          RELEASE           ##
        ################################

        #   Make double sure we pass all the tests before we push
        'TestRelease',

        #   In case the command was an accident, make sure we really want to release
        'ConfirmRelease',
    );

    return;
}



__PACKAGE__->meta->make_immutable;
no Moose;


# Happy ending
1;

__END__

=pod

=head1 NAME

Dist::Zilla::PluginBundle::Author::LESPEA - LESPEA's Dist::Zilla Configuration

=head1 VERSION

version 1.008000

=head1 SYNOPSIS

    #  In dist.ini:
    [@Author::LESPEA]

=head1 DESCRIPTION

This plugin bundle, in its default configuration, is equivalent to:

    [ArchiveRelease]
    [Authority]
    [AutoMetaResources]
    [AutoPrereqs]
    [ConfirmRelease]
    [ConsistentVersionTest]
    [CopyFilesFromBuild]
    [DualBuilders]
    [ExecDir]
    [ExtraTests]
    [FakeRelease]
    [GatherDir]
    [HasVersionTests]
    [InstallGuide]
    [License]
    [MakeMaker]
    [ManifestSkip]
    [Manifest]
    [MetaConfig]
    [MetaJSON]
    [MetaNoIndex]
    [MetaTests]
    [MetaYAML]
    [MinimumPerl]
    [ModuleBuild]
    [NextRelease]
    [NoTabsTests]
    [PkgVersion]
    [PodCoverageTests]
    [PodSyntaxTests]
    [PodWeaver]
    [PortabilityTests]
    [PruneCruft]
    [ReportVersions::Tiny]
    [ShareDir]
    [SynopsisTests]
    [Test::CPAN::Changes]
    [Test::Compile]
    [Test::DistManifest]
    [Test::EOL]
    [Test::Kwalitee]
    [Test::MinimumVersion]
    [Test::NoTabs]
    [Test::Perl::Critic]
    [TestRelease]
    [UploadToCPAN]

=head1 OPTIONS

=head2 -remove

This option can be used to remove specific plugins from the bundle. It
can be used multiple times.

Obviously, the default is not to remove any plugins.

Example:

    ; Remove these two plugins from the bundle
    -remove = CriticTests
    -remove = SynopsisTests

=head2 copy_file, move_file

If you want to copy or move files out of the build dir and into the
distribution dir, use these two options to specify those files. Both
of these options can be specified multiple times.

The most common reason to use this would be to put automatically
generated files under version control. For example, Github likes to
see a README file in your distribution, but if your README file is
auto-generated during the build, you need to copy each newly-generated
README file out of its build directory in order for Github to see it.

If you want to include an auto-generated file in your distribution but
you I<don't> want to include it in the build, use C<move_file> instead
of C<copy_file>.

Example:

    copy_file = README
    move_file = README.pod
    copy_file = README.txt

=head2 release

This option chooses the type of release to do. The default is 'real,'
which means "really upload the release to CPAN" (i.e. load the
C<UploadToCPAN> plugin). You can set it to 'fake,' in which case the
C<FakeRelease> plugin will be loaded, which simulates the release
process without actually doing anything. You can also set it to 'none'
if you do not want this module to load any release plugin, in which
case your F<dist.ini> file should load a release plugin directly. Any
other value for this option will be interpreted as a release plugin
name to be loaded.

Examples:

    ; Release to CPAN for real (default)
    release = real
    ; For testing, you can do fake releases
    release = fake
    ; Or you can choose no release plugin
    release = none
    ; Or you can specify a specific release plugin.
    release = OtherReleasePlugin

=head2 archive, archive_directory

If set to true, the C<archive> option copies each released version of
the module to an archive directory, using the C<ArchiveRelease>
plugin. This is the default. The name of the archive directory is
specified using C<archive_directory>, which is F<releases> by default.

Examples:

    ; archive each release to the "releases" directory
    archive = true
    archive_directory = releases
    ; Or don't archive
    archive = false

=head2 include_dotfiles

If this is set to true (not the default), then any file that includes a leading
'.' will be included in the package

Example:

    include_dotfiles = true

=head2 compile_synopsis

If this is set to true (the default), then the SynopsisTests plugin
will be enabled. This plugin checks the perl syntax of the SYNOPSIS
sections of your modules. Obviously, if your SYNOPSIS section is not
perl code (case in point: this module), you should set this to false.

Example:

    compile_synopsis = false

=head2 add_meta

If this is set to true (the default), then the AutoMetaResources and Authority
plugins will be enabled. These plugins adds various metatdata such as the github
repo, cpan links, etc to the metadata of the plugin.

Example:

    add_meta = false

=encoding utf8

=for Pod::Coverage configure mvp_multivalue_args

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla::Plugin::ArchiveRelease|Dist::Zilla::Plugin::ArchiveRelease>

=item *

L<Dist::Zilla::Plugin::Authority|Dist::Zilla::Plugin::Authority>

=item *

L<Dist::Zilla::Plugin::AutoMetaResources|Dist::Zilla::Plugin::AutoMetaResources>

=item *

L<Dist::Zilla::Plugin::AutoPrereqs|Dist::Zilla::Plugin::AutoPrereqs>

=item *

L<Dist::Zilla::Plugin::ConfirmRelease|Dist::Zilla::Plugin::ConfirmRelease>

=item *

L<Dist::Zilla::Plugin::ConsistentVersionTest|Dist::Zilla::Plugin::ConsistentVersionTest>

=item *

L<Dist::Zilla::Plugin::CopyFilesFromBuild|Dist::Zilla::Plugin::CopyFilesFromBuild>

=item *

L<Dist::Zilla::Plugin::DualBuilders|Dist::Zilla::Plugin::DualBuilders>

=item *

L<Dist::Zilla::Plugin::ExecDir|Dist::Zilla::Plugin::ExecDir>

=item *

L<Dist::Zilla::Plugin::ExtraTests|Dist::Zilla::Plugin::ExtraTests>

=item *

L<Dist::Zilla::Plugin::FakeRelease|Dist::Zilla::Plugin::FakeRelease>

=item *

L<Dist::Zilla::Plugin::GatherDir|Dist::Zilla::Plugin::GatherDir>

=item *

L<Dist::Zilla::Plugin::HasVersionTests|Dist::Zilla::Plugin::HasVersionTests>

=item *

L<Dist::Zilla::Plugin::InstallGuide|Dist::Zilla::Plugin::InstallGuide>

=item *

L<Dist::Zilla::Plugin::License|Dist::Zilla::Plugin::License>

=item *

L<Dist::Zilla::Plugin::MakeMaker|Dist::Zilla::Plugin::MakeMaker>

=item *

L<Dist::Zilla::Plugin::Manifest|Dist::Zilla::Plugin::Manifest>

=item *

L<Dist::Zilla::Plugin::ManifestSkip|Dist::Zilla::Plugin::ManifestSkip>

=item *

L<Dist::Zilla::Plugin::MetaConfig|Dist::Zilla::Plugin::MetaConfig>

=item *

L<Dist::Zilla::Plugin::MetaJSON|Dist::Zilla::Plugin::MetaJSON>

=item *

L<Dist::Zilla::Plugin::MetaNoIndex|Dist::Zilla::Plugin::MetaNoIndex>

=item *

L<Dist::Zilla::Plugin::MetaTests|Dist::Zilla::Plugin::MetaTests>

=item *

L<Dist::Zilla::Plugin::MetaYAML|Dist::Zilla::Plugin::MetaYAML>

=item *

L<Dist::Zilla::Plugin::MinimumPerl|Dist::Zilla::Plugin::MinimumPerl>

=item *

L<Dist::Zilla::Plugin::ModuleBuild|Dist::Zilla::Plugin::ModuleBuild>

=item *

L<Dist::Zilla::Plugin::NextRelease|Dist::Zilla::Plugin::NextRelease>

=item *

L<Dist::Zilla::Plugin::PkgVersion|Dist::Zilla::Plugin::PkgVersion>

=item *

L<Dist::Zilla::Plugin::PodCoverageTests|Dist::Zilla::Plugin::PodCoverageTests>

=item *

L<Dist::Zilla::Plugin::PodSyntaxTests|Dist::Zilla::Plugin::PodSyntaxTests>

=item *

L<Dist::Zilla::Plugin::PodWeaver|Dist::Zilla::Plugin::PodWeaver>

=item *

L<Dist::Zilla::Plugin::PruneCruft|Dist::Zilla::Plugin::PruneCruft>

=item *

L<Dist::Zilla::Plugin::ReadmeAnyFromPod|Dist::Zilla::Plugin::ReadmeAnyFromPod>

=item *

L<Dist::Zilla::Plugin::ReportVersions::Tiny|Dist::Zilla::Plugin::ReportVersions::Tiny>

=item *

L<Dist::Zilla::Plugin::ShareDir|Dist::Zilla::Plugin::ShareDir>

=item *

L<Dist::Zilla::Plugin::SpellingCommonMistakesTests|Dist::Zilla::Plugin::SpellingCommonMistakesTests>

=item *

L<Dist::Zilla::Plugin::Test::CPAN::Changes|Dist::Zilla::Plugin::Test::CPAN::Changes>

=item *

L<Dist::Zilla::Plugin::Test::Compile|Dist::Zilla::Plugin::Test::Compile>

=item *

L<Dist::Zilla::Plugin::Test::DistManifest|Dist::Zilla::Plugin::Test::DistManifest>

=item *

L<Dist::Zilla::Plugin::Test::EOL|Dist::Zilla::Plugin::Test::EOL>

=item *

L<Dist::Zilla::Plugin::Test::Kwalitee|Dist::Zilla::Plugin::Test::Kwalitee>

=item *

L<Dist::Zilla::Plugin::Test::MinimumVersion|Dist::Zilla::Plugin::Test::MinimumVersion>

=item *

L<Dist::Zilla::Plugin::Test::NoTabs|Dist::Zilla::Plugin::Test::NoTabs>

=item *

L<Dist::Zilla::Plugin::Test::Perl::Critic|Dist::Zilla::Plugin::Test::Perl::Critic>

=item *

L<Dist::Zilla::Plugin::Test::Portability|Dist::Zilla::Plugin::Test::Portability>

=item *

L<Dist::Zilla::Plugin::Test::Synopsis|Dist::Zilla::Plugin::Test::Synopsis>

=item *

L<Dist::Zilla::Plugin::TestRelease|Dist::Zilla::Plugin::TestRelease>

=item *

L<Dist::Zilla::Plugin::UploadToCPAN|Dist::Zilla::Plugin::UploadToCPAN>

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AUTHOR

Adam Lesperance <lespea@gmail.com>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dist::Zilla::PluginBundle::Author::LESPEA

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Dist-Zilla-PluginBundle-Author-LESPEA>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Dist-Zilla-PluginBundle-Author-LESPEA>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-PluginBundle-Author-LESPEA>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Dist-Zilla-PluginBundle-Author-LESPEA>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Dist-Zilla-PluginBundle-Author-LESPEA>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Dist-Zilla-PluginBundle-Author-LESPEA>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/Dist-Zilla-PluginBundle-Author-LESPEA>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Dist-Zilla-PluginBundle-Author-LESPEA>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Dist-Zilla-PluginBundle-Author-LESPEA>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Dist::Zilla::PluginBundle::Author::LESPEA>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-dist-zilla-pluginbundle-author-lespea at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-PluginBundle-Author-LESPEA>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/lespea/dist-zilla-pluginbundle-author-lespea>

  git clone git://github.com/lespea/dist-zilla-pluginbundle-author-lespea.git

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Lesperance.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut
