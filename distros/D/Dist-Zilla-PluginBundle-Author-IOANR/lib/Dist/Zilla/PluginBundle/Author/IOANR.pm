package Dist::Zilla::PluginBundle::Author::IOANR;
$Dist::Zilla::PluginBundle::Author::IOANR::VERSION = '1.162691';
# ABSTRACT: Build dists the way IOANR likes
use v5.12;
use Moose;
use List::Util 1.33 'any';
use Dist::Zilla::Plugin::AssertOS;
use Dist::Zilla::Plugin::ChangelogFromGit::CPAN::Changes 0.107;
use Dist::Zilla::Plugin::ContributorsFile;
use Dist::Zilla::Plugin::CopyFilesFromBuild;
use Dist::Zilla::Plugin::Git;
use Dist::Zilla::Plugin::Git::Contributors;
use Dist::Zilla::Plugin::GitHub;
use Dist::Zilla::Plugin::Meta::Contributors;
use Dist::Zilla::Plugin::MetaData::BuiltWith;
use Dist::Zilla::Plugin::ModuleBuildTiny;
use Dist::Zilla::Plugin::MojibakeTests;
use Dist::Zilla::Plugin::PodWeaver 4.000;
use Dist::Zilla::Plugin::ReadmeFromPod;
use Dist::Zilla::Plugin::RunExtraTests;
use Dist::Zilla::Plugin::Signature;
use Dist::Zilla::Plugin::Test::CheckDeps;
use Dist::Zilla::Plugin::Test::Compile;
use Dist::Zilla::Plugin::Test::CPAN::Meta::JSON;
use Dist::Zilla::Plugin::Test::DistManifest;
use Dist::Zilla::Plugin::Test::EOL;
use Dist::Zilla::Plugin::Test::Kwalitee;
use Dist::Zilla::Plugin::Test::MinimumVersion;
use Dist::Zilla::Plugin::Test::NoTabs;
use Dist::Zilla::Plugin::Test::Pod::LinkCheck;
use Dist::Zilla::Plugin::Test::Pod::No404s;
use Dist::Zilla::Plugin::Test::Pod::No404s;
use Dist::Zilla::Plugin::Test::Portability;
use Dist::Zilla::Plugin::Test::ReportPrereqs;
use Dist::Zilla::Plugin::Test::Synopsis;
use Dist::Zilla::Plugin::Test::UnusedVars;
use Dist::Zilla::Plugin::Test::Version;

with 'Dist::Zilla::Role::PluginBundle::Easy';

# TODO optionally add OSPreqs

has release_plugins => ( is => 'ro', lazy_build => 1);

sub _build_release_plugins {
    my $self = shift;

    if ($self->payload->{fake_release} || $ENV{DZIL_FAKE_RELEASE}) {
        return ['FakeRelease'];
    }

    return [
        'ConfirmRelease',
        ['Git::Commit' => {allow_dirty => [qw/README.md dist.ini Changes LICENSE/]}],
        [
            'Git::CommitBuild' => {
                branch               => '',
                release_branch       => 'release',
                release_message      => 'Release %v',
                multiple_inheritance => 1,
            }
        ],
        ['Git::Tag' => {signed => 1, branch => 'release'}],
        'Git::Push',
        'GitHub::Update',
        'UploadToCPAN',
    ];
}

has build_plugin => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        if ($_[0]->payload->{custom_builder}) {
            return [ModuleBuild => {mb_class => 'My::Builder'}];
        } else {
            return 'ModuleBuildTiny';
        }
    });

sub mvp_multivalue_args {qw/disable assert_os/}

sub configure {
    my ($self) = @_;
    my $arg = $self->payload;

    my $change_opts = {
        exclude_message => '^(dist.ini|v(\d+\.?)+)',
        edit_changelog  => 1,
    };

    if ($arg->{semantic_version}) {
        $change_opts->{tag_regexp} = 'semantic';
    }

    my @plugins = (
        'AutoPrereqs',
        'AutoVersion',
        ['ChangelogFromGit::CPAN::Changes' => $change_opts],
        'ContributorsFile',
        ['Git::Contributors' => {order_by => 'commits'}],
        ['CopyFilesFromBuild' => {copy => [qw/README.md LICENSE/]}],
        'ExecDir',
        [
            'Git::Check' => {
                allow_dirty     => [qw/README.md dist.ini Changes LICENSE/],
                build_warnings  => 1,
                untracked_files => 'warn',
            }
        ],
        [
            'Git::GatherDir' => {
                include_dotfiles => 1,
                exclude_match    => '(Changes|README.md|LICENSE)$',
            }
        ],
        ['GitHub::Meta' => {metacpan => 1 }],
        'License',
        'Manifest',
        'Meta::Contributors',
        ['MetaData::BuiltWith' => {show_config => 1}],
        'MetaJSON',
        ['PodWeaver' => {config_plugin => '@Author::IOANR'}],
        'PkgVersion',
        'PruneCruft',
        'ShareDir',
        'Signature',
        ['ReadmeFromPod' => {type => 'markdown'}],
        'MojibakeTests',
        'Test::CheckDeps',
        'Test::Compile',
        'Test::CPAN::Meta::JSON',
        'Test::DistManifest',
        'Test::EOL',
        ['Test::Kwalitee' => { skiptest => [qw/has_readme/]}],
        'Test::MinimumVersion', # TODO only checks META.yml, which we don't have
        'Test::NoTabs',
        'Test::Pod::LinkCheck',
        'Test::Pod::No404s',
        'Test::Portability',
        'Test::ReportPrereqs',
        'Test::UnusedVars',
        'Test::Synopsis',
        'Test::Version',
        'TestRelease',
    );

    # Test::Perl::Critic
    # PodCoverageTests
    # PodSyntaxTests

    push @plugins, @{$self->release_plugins};

    my @add;
    while (my $p = shift @plugins) {
        next if any { $_ eq $p } @{$arg->{disable}};
        push @add, $p;
    }

    push @add, $self->build_plugin;

    # these have to come after the builder
    push @add, 'RunExtraTests';

    if (exists $arg->{assert_os}) {
        push @add, [AssertOS => $self->config_slice({assert_os => 'os'})];
    }

    $self->add_plugins(@add);

    return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Ioan Rogers

=head1 NAME

Dist::Zilla::PluginBundle::Author::IOANR - Build dists the way IOANR likes

=head1 VERSION

version 1.162691

=head1 OPTIONS

=head2 C<fake_release>

Doesn't commit or release anything

  fake_release = 1

=head2 C<disable>

Specify plugins to disable. Can be specified multiple times.

  disable = Some::Plugin
  disable = Another::Plugin

=head2 C<assert_os>

Use L<Devel::AssertOS> to control which platforms this dist will build on.
Can be specified multiple times.

  assert_os = Linux

=head2 C<custom_builder>

If C<custom_builder> is set, L<Module::Build> will be used instead of
L<Module::Build::Tiny> with a custom build class set to C<My::Builder>

=head2 C<semantic_version>

If C<semantic_version> is true (the default), git tags will be in the form
C<^v(\d+\.\d+\.\d+)$>. Otherwise they will be C<^v(\d+\.\d+)$>.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/ioanrogers/Dist-Zilla-PluginBundle-Author-IOANR/issues>.

=head1 AVAILABILITY

The project homepage is L<http://search.cpan.org/dist/Dist-Zilla-PluginBundle-Author-IOANR/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::PluginBundle::Author::IOANR/>.

=head1 SOURCE

The development version is on github at L<http://github.com/ioanrogers/Dist-Zilla-PluginBundle-Author-IOANR>
and may be cloned from L<git://github.com/ioanrogers/Dist-Zilla-PluginBundle-Author-IOANR.git>

=head1 AUTHOR

Ioan Rogers <ioanr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Ioan Rogers.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

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
