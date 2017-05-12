#
# This file is part of Dist-Zilla-PluginBundle-Apocalyptic
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package Dist::Zilla::PluginBundle::Apocalyptic;
# git description: release-0.004-3-g7f6133e
$Dist::Zilla::PluginBundle::Apocalyptic::VERSION = '0.005';
our $AUTHORITY = 'cpan:APOCAL';

# ABSTRACT: Let the apocalypse build your dist!

use Moose 1.21;

# The plugins we use ( excluding ones bundled in dzil )
with 'Dist::Zilla::Role::PluginBundle::Easy' => { -version => '5.011' };	# basically sets the dzil version
use Pod::Weaver::PluginBundle::Apocalyptic 0.002;
use Dist::Zilla::Plugin::Test::Compile 1.112820;
use Dist::Zilla::Plugin::ApocalypseTests 0.01;
use Dist::Zilla::Plugin::Prepender 1.101590;
use Dist::Zilla::Plugin::Authority 1.001;
use Dist::Zilla::Plugin::PodWeaver 3.101641;
use Dist::Zilla::Plugin::ChangelogFromGit 0.002;
use Dist::Zilla::Plugin::MinimumPerl 1.001;
use Dist::Zilla::Plugin::MetaProvides::Package 1.12044908;
use Dist::Zilla::Plugin::Bugtracker 1.102670;
use Dist::Zilla::Plugin::Homepage 1.101420;
use Dist::Zilla::Plugin::Repository 0.16;
use Dist::Zilla::Plugin::InstallGuide 1.101461;
use Dist::Zilla::Plugin::Signature 1.100930;
use Dist::Zilla::Plugin::CheckChangesHasContent 0.003;
use Dist::Zilla::Plugin::Git 1.110500;
use Dist::Zilla::Plugin::ArchiveRelease 3.01;
use Dist::Zilla::Plugin::ReportVersions::Tiny 1.02;
use Dist::Zilla::Plugin::MetaData::BuiltWith 0.01018204;
use Dist::Zilla::Plugin::Clean 0.002;
use Dist::Zilla::Plugin::LocaleMsgfmt 1.203;
use Dist::Zilla::Plugin::CheckPrereqsIndexed 0.007;
use Dist::Zilla::Plugin::DOAP 0.002;
use Dist::Zilla::Plugin::Covenant 0.1.0;
use Dist::Zilla::Plugin::CheckIssues 0.002;
use Dist::Zilla::Plugin::SchwartzRatio 0.2.0;
use Dist::Zilla::Plugin::CheckSelfDependency 0.007;
use Dist::Zilla::Plugin::Git::Describe 0.003;
use Dist::Zilla::Plugin::ReportPhase; # TODO we wanted to specify 0.03 but it's weird version stanza blows up! RT#99769
use Dist::Zilla::Plugin::ReadmeAnyFromPod 0.142470;
use Dist::Zilla::Plugin::Git::CheckFor::CorrectBranch 0.011;
use Dist::Zilla::Plugin::Git::Remote::Check 0.1.2;
use Dist::Zilla::Plugin::PromptIfStale 0.028;
use Dist::Zilla::Plugin::ModuleBuildTiny 0.007;
use Dist::Zilla::Plugin::MakeMaker::Fallback 0.013;
use Dist::Zilla::Plugin::Git::Contributors 0.008;

# Allow easier config manipulation
with qw(
	Dist::Zilla::Role::PluginBundle::Config::Slicer
	Dist::Zilla::Role::PluginBundle::PluginRemover
);

sub configure {
	my $self = shift;

#	; -- Report the phases as a debugging aid
	# TODO should this module automatically figure it out? if so, go make a pull req!
	if ( join( ' ', @ARGV ) =~ /--verbose/i ) {
		$self->add_plugins( [ 'ReportPhase' => 'ENTER' ] );
	}

#	; -- start off by bumping the version
	$self->add_plugins(
	[
		'Git::NextVersion' => {
			'version_regexp' => '^release-(.+)$',
		}
	],

#	; -- import our files from the git root
	[
		'Git::GatherDir' => {
			'exclude_filename' => 'README.pod',
		},
	],

#	; -- start the basic dist skeleton
	qw(
		PruneCruft
		AutoPrereqs
	),
	[
		'GenerateFile', 'MANIFEST.SKIP', {
			'filename'	=> 'MANIFEST.SKIP',
			'is_template'	=> 1,
			'content'	=> <<'EOC',
# Added by Dist::Zilla::PluginBundle::Apocalyptic v{{$Dist::Zilla::PluginBundle::Apocalyptic::VERSION}}

# skip Eclipse IDE stuff
\.includepath$
\.project$
\.settings/

# Avoid version control files.
\bRCS\b
\bCVS\b
,v$
\B\.svn\b
\B\.git\b
^\.gitignore$

# Ignore Dist::Zilla's build dir
^\.build/

# Avoid configuration metadata file
^MYMETA\.

# Avoid Makemaker generated and utility files.
^Makefile$
^blib/
^MakeMaker-\d
\bpm_to_blib$
^blibdirs$

# Avoid Module::Build generated and utility files.
\bBuild$
\bBuild.bat$
\b_build
\bBuild.COM$
\bBUILD.COM$
\bbuild.com$

# Avoid temp and backup files.
~$
\.old$
\#$
^\.#
\.bak$

# our tarballs
\.tar\.gz$
^releases/
EOC
		}
	],
	[
		'ManifestSkip' => {
			'skipfile' => 'MANIFEST.SKIP',
		}
	],

#	; -- Generate our tests
	[
		'Test::Compile' => {
			# fake the $ENV{HOME} in case smokers don't like us
			'fake_home' => 1,
		}
	],
	qw(
		ApocalypseTests
		ReportVersions::Tiny
	),

#	; -- munge files
	[
		'Prepender' => {
			'copyright'	=> 1,
			'line'		=> 'use strict; use warnings;',
		}
	],
	qw(
		Authority
		Git::Describe
		PkgVersion
	),
	[
		'PodWeaver' => {
			'config_plugin'		=> '@Apocalyptic',
			'replacer'		=> 'replace_with_comment',
			'post_code_replacer'	=> 'replace_with_nothing',
		}
	],
	[
		'LocaleMsgfmt' => {
			'locale' => 'share/locale',
		},
	],

#	; -- update the Changelog
	[
		'NextRelease' => {
			'time_zone'	=> 'UTC',
			'filename'	=> 'Changes',
			'format'	=> '%v%t%{yyyy-MM-dd HH:mm:ss VVVV}d',
		}
	],
	[
		'ChangelogFromGit' => {
			'tag_regexp'	=> '^release-(.+)$',
			'file_name'	=> 'CommitLog',
		}
	],
	);

#	; -- generate/process meta-information
	if ( -d 'bin' ) {
		$self->add_plugins( [ 'ExecDir' => {
			'dir'	=> 'bin',
		} ] );
	}
	if ( -d 'share' ) {
		$self->add_plugins( [ 'ShareDir' => {
			'dir'	=> 'bin',
		} ] );
	}
	$self->add_plugins(
	qw(
		MinimumPerl
		Bugtracker
		Homepage
		MetaConfig
		Git::Contributors
	),
	[
		'MetaData::BuiltWith' => {
			'show_uname' => 1,
			'uname_args' => '-s -r -m',
		}
	],
	[
		'Repository' => {
			# TODO convert "origin" to "github"
			# TODO actually use gitorious!
			'git_remote' => 'origin',
		}
	],
	[
		'MetaResources' => {
			# TODO add the usual list of stuff found in my POD? ( cpants, bla bla )
			'license'	=> 'http://dev.perl.org/licenses/',
		}
	],
	);

#	; -- generate meta files
	my @dirs;
	foreach my $d ( qw( inc t xt examples share eg mylib ) ) {
		push( @dirs, $d ) if -d $d;
	}
	$self->add_plugins(
	[
		'MetaNoIndex' => {
			'directory' => \@dirs,
		}
	],
	[
		'MetaProvides::Package' => { # needs to be added after MetaNoIndex
			# don't report the noindex directories
			'meta_noindex' => 1,
		}
	],
	qw(
		License
		ModuleBuildTiny
		MakeMaker::Fallback
	),
	qw(
		MetaYAML
		MetaJSON
		InstallGuide
		DOAP
		Covenant
		CPANFile
	),
	);

#	; -- special stuff for README files
#		we want README and README.pod but only include README in the built tarball and use README.pod in the root of the project!
	$self->add_plugins(
		'ReadmeAnyFromPod',
	[
		'ReadmeAnyFromPod', 'pod for github' => {
			'type'	=> 'pod',
			'location'	=> 'root',
			'phase'	=> 'release',
		},
	],
	[
		'Signature' => {
			'sign' => 'always',
		}
	],
	qw(
		Manifest
	),

#	; -- pre-release
	[
		'CheckChangesHasContent' => {
			'changelog'	=> 'Changes',
		}
	],
	[
		'Git::Check' => {
			'changelog'	=> 'Changes',
			'allow_dirty'	=> [ 'README.pod', 'Changes' ], # TODO Changes shouldn't be in here but if I don't add it as allow_dirty it doesn't get committed!
		}
	],

#	; -- sanity-check our git stuff
#	TODO we need to fix Git::CheckFor::Fixups so it uses the version_regexp!
	qw(
		Git::CheckFor::CorrectBranch
	) );
	$self->add_plugins( [ 'Git::CheckFor::MergeConflicts' => {
		'ignore' => 'CommitLog',
	} ],
	qw(
		Git::Remote::Check
	),

#	; -- more sanity tests before confirming
	[
		'PromptIfStale' => {
			'check_authordeps'	=> 1,
			'check_all_plugins'	=> 1,
			'check_all_prereqs'	=> 1,
			'phase'			=> 'release',
			'fatal'			=> 1,
		},
	],
	qw(
		TestRelease
		CheckPrereqsIndexed
		CheckSelfDependency
		CheckIssues
		ConfirmRelease
	),

#	; -- release
	qw(
		UploadToCPAN
	),

#	; -- post-release
	[
		'ArchiveRelease' => {
			'directory' => 'releases',
		}
	],
	[
		'Git::Commit' => {
			'changelog'	=> 'Changes',
			'commit_msg'	=> 'New CPAN release of %N - v%v%n%n%c',
			'time_zone'	=> 'UTC',
			'add_files_in'	=> 'releases',
			'allow_dirty'	=> [ 'README.pod', 'Changes' ], # TODO Changes shouldn't be in here but if I don't add it as allow_dirty it doesn't get committed!
		}
	],
	[
		'Git::Tag' => {
			'tag_format'	=> 'release-%v',
			'tag_message'	=> 'Tagged release-%v',
		}
	],
	[
		'Git::Push' => {
			# TODO add "github", "gitorious" support somehow... introspect the Git config?
			'push_to'	=> 'origin',
		}
	],
	qw(
		Clean
		SchwartzRatio
	),
	);

	if ( join( ' ', @ARGV ) =~ /--verbose/i ) {
		$self->add_plugins( [ 'ReportPhase' => 'LEAVE' ] );
	}
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee
diff irc mailto metadata placeholders metacpan

=for Pod::Coverage configure

=head1 NAME

Dist::Zilla::PluginBundle::Apocalyptic - Let the apocalypse build your dist!

=head1 VERSION

  This document describes v0.005 of Dist::Zilla::PluginBundle::Apocalyptic - released October 28, 2014 as part of Dist-Zilla-PluginBundle-Apocalyptic.

=head1 DESCRIPTION

This plugin bundle attempts to automate as much as sanely possible the job of building your dist. It builds upon
L<Dist::Zilla> and utilizes numerous plugins to reduce the burden on the programmer.

	# In your dist.ini:
	name = My-Super-Cool-Dist
	[@Apocalyptic]

Don't forget the new global config.ini file added in L<Dist::Zilla> v4!

	apoc@blackhole:~$ cat .dzil/config.ini
	[%User]
	name  = Apocalypse
	email = APOCAL@cpan.org

	[%Rights]
	license_class    = Perl_5
	copyright_holder = Apocalypse

	[%PAUSE]
	username = APOCAL
	password = myawesomepassword

=head2 dist.ini

This is equivalent to setting this in your dist.ini:

	# Skipping the usual name/author/license/copyright stuff

	[ReportPhase / ENTER]	; reports the dzil build phases

	; -- start off by bumping the version
	[Git::NextVersion]		; find the last tag, and bump to next version via Version::Next
	version_regexp = ^release-(.+)$

	; -- start the basic dist skeleton
	[Git::GatherDir]			; we start with everything in the root dir, ignoring our auto-generated README.pod
	exclude_filename = README.pod
	[PruneCruft]			; automatically prune cruft defined by RJBS :)
	[AutoPrereqs]			; automatically find our prereqs
	[GenerateFile / MANIFEST.SKIP]	; make our default MANIFEST.SKIP
	[ManifestSkip]			; skip files that matches MANIFEST.SKIP
	skipfile = MANIFEST.SKIP

	; -- Generate our tests
	[Test::Compile]			; Create a t/00-compile.t file that auto-compiles every module in the dist
	fake_home = 1			; fakes $ENV{HOME} just in case
	[ApocalypseTests]		; Create a t/apocalypse.t file that runs Test::Apocalypse
	[ReportVersions::Tiny]		; Report the versions of our prereqs

	; -- munge files
	[Prepender]			; automatically add lines following the shebang in modules
	copyright = 1
	line = use strict; use warnings;
	[Authority]			; put the $AUTHORITY line in modules and the metadata
	[Git::Describe]		 ; make a note of the git commit description used in building this release
	[PkgVersion]			; put the "our $VERSION = ...;" line in modules
	[PodWeaver]			; weave our POD and add useful boilerplate
	config_plugin = @Apocalyptic
	replacer = replace_with_comment
	post_code_replacer = replace_with_nothing
	[LocaleMsgfmt]			; compile .po files to .mo files in share/locale
	locale = share/locale

	; -- update the Changelog
	[NextRelease]
	time_zone = UTC
	filename = Changes
	format = %v%n%tReleased: %{yyyy-MM-dd HH:mm:ss VVVV}d
	[ChangelogFromGit]		; generate CommitLog from git history
	tag_regexp = ^release-(.+)$
	file_name = CommitLog

	; -- generate/process meta-information
	[ExecDir]			; automatically install files from bin/ directory as executables ( if it exists )
	dir = bin
	[ShareDir]			; automatically install File::ShareDir files from share/ ( if it exists )
	dir = share
	[MinimumPerl]			; automatically find the minimum perl version required and add it to prereqs
	[Bugtracker]			; set bugtracker to http://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-PluginBundle-Apocalyptic
	[Homepage]			; set homepage to http://search.cpan.org/dist/Dist-Zilla-PluginBundle-Apocalyptic/
	[MetaConfig]			; dump dzil config into metadata
	[Git::Contributors]   	; generate our CONTRIBUTORS section by looking at the git history
	[MetaData::BuiltWith]		; dump entire perl modules we used to build into metadata
	[Repository]			; set git repository path by looking at git configs
	git_remote = origin
	[MetaResources]			; add arbitrary resources to metadata
	license = http://dev.perl.org/licenses/

	; -- generate meta files
	[MetaNoIndex]			; tell PAUSE to not index those directories
	directory = inc t xt examples share eg mylib
	[MetaProvides::Package]		; get provides from package definitions in files
	meta_noindex = 1
	[License]			; create LICENSE file
	[ModuleBuildTiny]		; create Build.PL file
	[MakeMaker::Fallback]	; create Makefile.PL file for older Perls
	[MetaYAML]			; create META.yml file
	[MetaJSON]			; create META.json file
	[ReadmeAnyFromPod]			; create README file
	[ReadmeAnyFromPod / PodRoot]	; create README.pod file in repository root ( useful for github! )
	[InstallGuide]			; create INSTALL file
	[DOAP]				; create doap.xml describing the module
	[Covenant]			; create AUTHOR_PLEDGE describing how PAUSE admins can grant co-maint
	[CPANFile]			; create a 'cpanfile' file describing prereqs
	[Signature]			; create SIGNATURE file when we are releasing ( annoying to enter password during test builds... )
	sign = archive
	[Manifest]			; finally, create the MANIFEST file

	; -- pre-release
	[CheckChangesHasContent]	; make sure you explained your changes :)
	changelog = Changes
	[Git::Check]			; check working path for any uncommitted stuff ( exempt Changes because it will be committed after release )
	changelog = Changes
	allow_dirty = README.pod
	[PromptIfStale]		; check our installed dependencies to make sure that we don't have stale modules and prevent release if so
	check_authordeps = 1
	check_all_plugins = 1
	check_all_prereqs = 1
	phase = release
	fatal = 1
	[TestRelease]                   ; make sure that we won't release a FAIL distro :)
	[@Git::CheckFor]		; prevent common git errors ( wrong branch, forgotten squash/fixups! )
	[CheckPrereqsIndexed]		; make sure that our prereqs actually exist on CPAN
	[CheckSelfDependency]           ; make sure we didn't create a recursive dependency situation!
	[CheckIssues]		; Looks on RT and github for issues that we can review
	[ConfirmRelease]		; double-check that we ACTUALLY want a release, ha!

	; -- release
	[UploadToCPAN]			; upload your dist to CPAN using CPAN::Uploader

	; -- post-release
	[ArchiveRelease]		; archive our tarballs under releases/
	directory = releases
	[Git::Commit]			; commit the dzil-generated stuff
	changelog = Changes
	commit_msg = New CPAN release of %N - v%v%n%n%c
	time_zone = UTC
	add_files_in = releases		; add our release tarballs to the repo
	allow_dirty = README.pod
	[Git::Tag]			; tag our new release
	tag_format = release-%v
	tag_message = Tagged release-%v
	[Git::Push]			; automatically push to the "origin" defined in .git/config
	push_to = origin
	[Clean]				; run dzil clean so we have no cruft :)
	[SchwartzRatio]		; informs us of old distributions lingering on CPAN

	[ReportPhase / LEAVE]	; reports the dzil build phases

=head1 Setting options

However, this plugin bundle does A LOT of things, so you would need to read the config carefully to see if it does
anything you don't want to do. You can override the options simply by removing the offending plugin from the bundle
by using the L<Dist::Zilla::PluginBundle::Filter> package. By doing that you are free to specify alternate plugins,
or the desired plugin configuration manually.

	# In your dist.ini:
	name			= My-Super-Cool-Dist
	author			= A. U. Thor
	license			= Perl_5
	copyright_holder	= A. U. Thor

	; we don't want to archive our releases
	; we want to push to gitorious instead
	[@Filter]
	bundle = @Apocalyptic
	remove = ArchiveRelease
	remove = Git::Push
	[Git::Push]
	push_to = gitorious

=head2 Newer method to manipulate this bundle

This PluginBundle now supports L<Dist::Zilla::PluginBundle::ConfigSlicer>, so you can pass in options to the plugins used like this:

	[@Apocalyptic]
	Git::Push.push_to = gitorious

This PluginBundle also supports L<Dist::Zilla::Role::PluginBundle::PluginRemover>, so dropping a plugin is as easy as this:

	[@Apocalyptic]
	-remove = ArchiveRelease

=head1 Future Plans

=head2 use XDG's Twitter plugin

I want to tweet and be a web2.0 dude! :)

=head2 use GETTY's cool Dist::Zilla::Plugin::Run::AfterRelease

I want to use that to automatically install the generated tarball

	sudo cpanp i --force file:///home/apoc/mygit/perl-dist-zilla-pluginbundle-apocalyptic/Dist-Zilla-PluginBundle-Apocalyptic-0.001.tar.gz

However, how do I get the full tarball path?

=head2 Work with Task::* dists

From Dist::Zilla::PluginBundle::FLORA

	; Not sure if it supports config_plugin = @Bundle like PodWeaver does...
	[TaskWeaver]	; weave our POD for a Task::* module ( enabled only if it's a Task-* dist )

	has is_task => (
	    is      => 'ro',
	    isa     => Bool,
	    lazy    => 1,
	    builder => '_build_is_task',
	);

	method _build_is_task {
	    return $self->dist =~ /^Task-/ ? 1 : 0;
	}

	...

	$self->is_task
        ? $self->add_plugins('TaskWeaver')
        : $self->add_plugins([ 'PodWeaver' => { config_plugin => '@FLORA' } ]);

=head2 I would like to start digging into the C<dzil new> command and see how to automate stuff in it.

=head3 Changes creation

create a Changes file with the boilerplate text in it

	Revision history for Dist::Zilla::PluginBundle::Apocalyptic

	{{$NEXT}}

		initial release

=head3 github integration

automatically create github repo + set description/homepage via L<Dist::Zilla::Plugin::UpdateGitHub> and L<App::GitHub::create> or L<App::GitHub>

=head3 gitorious integration

unfortunately there's no perl API for gitorious? L<http://www.mail-archive.com/gitorious@googlegroups.com/msg01016.html>

=head3 .gitignore creation

it should contain only one line - the damned dist build dir "/Foo-Dist-*"
also, it needs the "/.build/" line?

=head3 Eclipse files creation

create the .project/.includepath/.settings stuff

=head3 submit project to ohloh

we need more perl projects on ohloh! there's L<WWW::Ohloh::API>

=head2 DZP::PkgDist

Do we need the $DIST variable? What software uses it? I already provide that info in the POD of the file...

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla|Dist::Zilla>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dist::Zilla::PluginBundle::Apocalyptic

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Dist-Zilla-PluginBundle-Apocalyptic>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Dist-Zilla-PluginBundle-Apocalyptic>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-PluginBundle-Apocalyptic>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Dist-Zilla-PluginBundle-Apocalyptic>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Dist-Zilla-PluginBundle-Apocalyptic>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Dist-Zilla-PluginBundle-Apocalyptic>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/overview/Dist-Zilla-PluginBundle-Apocalyptic>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Dist-Zilla-PluginBundle-Apocalyptic>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Dist-Zilla-PluginBundle-Apocalyptic>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Dist::Zilla::PluginBundle::Apocalyptic>

=back

=head2 Email

You can email the author of this module at C<APOCAL at cpan.org> asking for help with any problems you have.

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and join this channel: #perl-help then talk to this person for help: Apocalypse.

=item *

irc.freenode.net

You can connect to the server at 'irc.freenode.net' and join this channel: #perl then talk to this person for help: Apocal.

=item *

irc.efnet.org

You can connect to the server at 'irc.efnet.org' and join this channel: #perl then talk to this person for help: Ap0cal.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-dist-zilla-pluginbundle-apocalyptic at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-PluginBundle-Apocalyptic>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/apocalypse/perl-dist-zilla-pluginbundle-apocalyptic>

  git clone git://github.com/apocalypse/perl-dist-zilla-pluginbundle-apocalyptic.git

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Apocalypse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=head1 DISCLAIMER OF WARRANTY

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
