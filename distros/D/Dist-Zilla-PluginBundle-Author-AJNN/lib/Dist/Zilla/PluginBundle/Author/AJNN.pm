use 5.026;
use warnings;

package Dist::Zilla::PluginBundle::Author::AJNN;
# ABSTRACT: Dist::Zilla configuration the way AJNN does it
$Dist::Zilla::PluginBundle::Author::AJNN::VERSION = '0.03';

use Dist::Zilla;
use Moose;
use namespace::autoclean;

with 'Dist::Zilla::Role::PluginBundle::Easy';

use Dist::Zilla::PluginBundle::Author::AJNN::PruneAliases;
use Dist::Zilla::PluginBundle::Author::AJNN::Readme;
use Pod::Weaver::PluginBundle::Author::AJNN;

use List::Util 1.33 'any';


my @mvp_multivalue_args;
sub mvp_multivalue_args { @mvp_multivalue_args }

has cpan_release => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub { $_[0]->payload->{'cpan_release'} // '1' },
);

has gatherdir_exclude_match => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	lazy => 1,
	default => sub { $_[0]->payload->{'GatherDir.exclude_match'} || [] },
);
push @mvp_multivalue_args, 'GatherDir.exclude_match';

has max_target_perl => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub { $_[0]->payload->{'Test::MinimumVersion.max_target_perl'} || '' },
);

has podweaver_skip => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	lazy => 1,
	default => sub { $_[0]->payload->{'PodWeaver.skip'} || [] },
);
push @mvp_multivalue_args, 'PodWeaver.skip';

has filter_remove => (
	is => 'ro',
	isa => 'ArrayRef[Str]',
	lazy => 1,
	default => sub { $_[0]->payload->{'-remove'} || [] },
);
push @mvp_multivalue_args, '-remove';


sub configure {
	my ($self) = @_;
	
	my $AJNN = '=' . __PACKAGE__;
	
	my @gatherdir_exclude_match = $self->gatherdir_exclude_match->@*;
	$self->add_plugins(
		[ 'GatherDir' => {
			exclude_filename => [qw(
				README.md
				cpanfile
				dist.ini
			)],
			exclude_match => [ @gatherdir_exclude_match, qw(
				~
				\.webloc$
			)],
			prune_directory => [qw(
				^cover_db$
				^Stuff$
				\.bbprojectd$
			)],
		}],
		[ 'PruneCruft' ],
		[ 'PruneAliases' ],
	);
	
	$self->add_plugins(
		[ 'CPANFile' ],
		[ 'MetaJSON' ],
		[ 'MetaYAML' ],
		[ 'MetaProvides::Package' ],
		[ 'PkgVersion' => {
			die_on_existing_version => 1,
			die_on_line_insertion => 1,
		}],
		[ 'GithubMeta' => {
			issues => 1,
			homepage => "''",
		}],
	);
	
	$self->add_plugins(
		[ 'Git::Check' => {
			allow_dirty => '',
		}],
		[ 'CheckChangeLog' ],
		[ 'TestRelease' ],
		[ 'ConfirmRelease' ],
		[ $self->cpan_release ? 'UploadToCPAN' : 'FakeRelease' ],
		[ 'Git::Tag' => {
			tag_format => '%V',
			tag_message => '%V%t  %{yyyy-MM-dd}d%n%c',
		}],
	);
	
	$self->add_plugins(
		[ 'MakeMaker' ],
		#[ 'StaticInstall' => { mode => 'on' } ],
		[ $AJNN . '::Readme' => 'Readme', {
			cpan_release => $self->cpan_release,
		}],
		[ 'Manifest' ],
	);
	
	my @podweaver_skip = $self->podweaver_skip->@*;
	if (@podweaver_skip) {
		$self->add_plugins([ 'FileFinder::Filter' => 'PodWeaverFiles' => {
			finder => [':InstallModules', ':ExecFiles'],
			skip => [@podweaver_skip],
		}]);
		@podweaver_skip = ( finder => '@Author::AJNN/PodWeaverFiles' );
	}
	$self->add_plugins(
		#[ 'PodWeaverIfPod' => {
		[ 'PodWeaver' => {
			config_plugin => '@Author::AJNN',
			@podweaver_skip,
		}],
	);
	
	my @test_min_version;
	@test_min_version = (
		[ 'Test::MinimumVersion' => {
			max_target_perl => $self->max_target_perl,
		}],
	) if $self->max_target_perl;
	$self->add_plugins(
		@test_min_version,
		[ 'PodSyntaxTests' ],
		[ 'RunExtraTests' ],
	);
}


around add_plugins => sub {
    my ($orig, $self, @plugins) = @_;
	
	my @remove = $self->filter_remove->@*;
	$self->$orig( grep {
		my $plugin = $_;
		my $moniker = ref $_ ? $_->[1] // $_->[0] : $_;
		(any { $_ eq $moniker } @remove) ? () : ($plugin)
	} @plugins );
};


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::AJNN - Dist::Zilla configuration the way AJNN does it

=head1 VERSION

version 0.03

=head1 SYNOPSIS

in F<dist.ini>:

 name = Example-Dist-Name
 main_module = lib/Local/Example.pm
 
 author  = Jane Doe <doe@example.org>
 license = Artistic_2_0
 copyright_holder = Jane Doe
 copyright_year   = 2020
 
 version = 0.123
 release_status = unstable
 
 [@Author::AJNN]
 
 [AutoPrereqs]

skip some parts if required:

 [@Author::AJNN]
 -remove = CheckChangeLog
 -remove = Git::Check

=head1 DESCRIPTION

This is the configuration I use for L<Dist::Zilla>.

(Most likely you don't want or need to read this.)

=head1 OVERVIEW

This plugin bundle is nearly equivalent to the following C<dist.ini> config:

 [GatherDir]
 exclude_filename = README.md
 exclude_filename = cpanfile
 exclude_filename = dist.ini
 exclude_match = ~|\.webloc$
 prune_directory = ^cover_db$|^Stuff$|\.bbprojectd$
 [PruneCruft]
 [PruneAliases]
 
 [CPANFile]
 [MetaJSON]
 [MetaYAML]
 [MetaProvides::Package]
 [PkgVersion]
 die_on_existing_version = 1
 die_on_line_insertion = 1
 [GithubMeta]
 issues = 1
 homepage = ''
 
 [Git::Check]
 allow_dirty =
 [CheckChangeLog]
 [TestRelease]
 [ConfirmRelease]
 [UploadToCPAN]
 [Git::Tag]
 tag_format = '%V'
 tag_message = '%V%t  %{yyyy-MM-dd}d%n%c'
 
 [MakeMaker]
 [@Author::AJNN::Readme]
 [Manifest]
 
 [FileFinder::Filter / PodWeaverFiles]
 finder = :InstallModules
 finder = :ExecFiles
 [PodWeaver]
 finder = PodWeaverFiles
 config_plugin = @Author::AJNN
 
 [Test::MinimumVersion]
 [PodSyntaxTests]
 [RunExtraTests]

=head1 ATTRIBUTES

=head2 -remove

Moniker of a plugin that is to be removed from this bundle. May
be given multiple times. See L<Dist::Zilla::PluginBundle::Filter>.
Offered here as a workaround for
L<RT 81958|https://github.com/rjbs/Dist-Zilla/issues/695>.

 -remove = Git::Check

=head2 cpan_release

Whether or not this distribution is meant to be released to
L<https://www.cpan.org/ CPAN>. The default is yes, but for software
of low quality or little interest to others, it can be set to no.

 cpan_release = 0

=head2 GatherDir.exclude_match

Files or directories that match any of these regular expressions
will not be included in the build. May be given multiple times.
See L<Dist::Zilla::Plugin::GatherDir/"exclude_match">.

 GatherDir.exclude_match = private_dir
 GatherDir.exclude_match = \.data$

=head2 PodWeaver.skip

L<PodWeaver> will not be applied to a file that matches any of these
regular expressions. May be given multiple times.
See L<Dist::Zilla::Plugin::FileFinder::Filter/"skip">.

 PodWeaver.skip = \.pod$
 PodWeaver.skip = Net/(?:SSL|TLS)

=head2 Test::MinimumVersion.max_target_perl

A syntax test for the specified target version will be generated.
If omitted or set to C<0>, the test will not be generated.
See L<Dist::Zilla::Plugin::Test::MinimumVersion>.

 Test::MinimumVersion.max_target_perl = v5.26

=head1 BUGS

This configuration is hacked together specifically for AJNN's needs.
It has not been designed with extensibility or reusability in mind.
No forward or backward compatibility should be expected.

=head1 SEE ALSO

L<Dist::Zilla::PluginBundle::Author::AJNN::Readme>

L<Pod::Weaver::PluginBundle::Author::AJNN>

L<Dist::Zilla::Role::PluginBundle::Easy>

L<Dist::Zilla::PluginBundle::Filter>

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

If you contact me by email, please make sure you include the word
"Perl" in your subject header to help beat the spam filters.

=head1 COPYRIGHT AND LICENSE

Arne Johannessen has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
