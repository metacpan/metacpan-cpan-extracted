# ABSTRACT: ASDAGO's Dist::Zilla plugin bundle

######################################################################
# Copyright (C) 2021 Asher Gordon <AsDaGo@posteo.net>                #
#                                                                    #
# This program is free software: you can redistribute it and/or      #
# modify it under the terms of the GNU General Public License as     #
# published by the Free Software Foundation, either version 3 of     #
# the License, or (at your option) any later version.                #
#                                                                    #
# This program is distributed in the hope that it will be useful,    #
# but WITHOUT ANY WARRANTY; without even the implied warranty of     #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU   #
# General Public License for more details.                           #
#                                                                    #
# You should have received a copy of the GNU General Public License  #
# along with this program. If not, see                               #
# <http://www.gnu.org/licenses/>.                                    #
######################################################################

package Dist::Zilla::PluginBundle::Author::ASDAGO;
$Dist::Zilla::PluginBundle::Author::ASDAGO::VERSION = '0.001';
#pod =head1 DESCRIPTION
#pod
#pod This is ASDAGO's plugin bundle for Dist::Zilla.
#pod
#pod =cut

use v5.18.0;
use strict;
use warnings;
use feature 'lexical_subs';
no warnings 'experimental::lexical_subs';
use namespace::autoclean;
use Moose;
use Dist::Zilla;
use Text::Wrap ();

with
    'Dist::Zilla::Role::PluginBundle::Easy',
    'Dist::Zilla::Role::PluginBundle::PluginRemover',
    'Dist::Zilla::Role::PluginBundle::Config::Slicer';

# Log a message.
my $log = sub {
    my $self = shift;
    my $name = $self->name;
    warn "[$name] @_\n";
};

# Create an attribute (or attributes) that default to the payload
# parameter of the same name. If default_takes_precedence is set in
# %spec, then the given default, if defined, will be used instead of
# the payload parameter.
my sub parameter {
    my ($names, %spec) = @_;

    my ($default, $default_takes_precedence) =
	delete @spec{qw(default default_takes_precedence)};
    %spec = (is => 'ro', lazy => 1, %spec);

    foreach my $name (ref $names eq 'ARRAY' ? @$names : $names) {
	has $name => (
	    %spec,
	    default => sub {
		my ($self) = @_;
		my $payload = $self->payload;
		return $payload->{$name}
		    if ! $default_takes_precedence &&
		    exists $payload->{$name};
		my $default = ref $default eq 'CODE' ?
		    $default->(@_) : $default;
		$default // $payload->{$name};
	    },
	);
    }
}

#pod =attr sysname
#pod
#pod This is the system name used for the git repository on
#pod L<Savannah|https://savannah.nongnu.org>. It defaults to the
#pod distribution name. You can use formatting codes as for
#pod Dist::Zilla::Plugin::MetaResourcesFromGit.
#pod
#pod =cut

parameter sysname => (
    isa		=> 'Str',
    default	=> '%N',
);

#pod =attr fast_build
#pod
#pod If this is true, then some things will be skipped in order to generate
#pod the build faster. B<Do not use this in releases.> The environment
#pod variable C<FAST_BUILD> can also be used to set this attribute.
#pod
#pod Things that are skipped are things that should be present in releases,
#pod but are not necessary for testing and may slow down the build
#pod significantly. For example, auto-generated prerequisites.
#pod
#pod =attr fake_release
#pod
#pod If this is true, then use the
#pod L<FakeRelease|Dist::Zilla::Plugin::FakeRelease> plugin instead of
#pod L<UploadToCPAN|Dist::Zilla::Plugin::UploadToCPAN>. The environment
#pod variable C<FAKE_RELEASE> can also be used to set this attribute.
#pod
#pod =attr skip_push
#pod
#pod If this is true, then pushing to the git repository will be skipped
#pod during release. The environment variable C<SKIP_PUSH> can also be used
#pod to set this attribute.
#pod
#pod =cut

parameter $_ => (
    isa		=> 'Bool',
    default	=> !!$ENV{+uc},
    default_takes_precedence => 1,
) foreach qw(fast_build fake_release skip_push);

sub configure {
    my ($self) = @_;

    foreach (
	[fast_build =>
	 'Running in fast build mode. DO NOT USE THIS TO RELEASE!'],
	[fake_release => 'Running in fake release mode'],
	[skip_push => 'Skipping git push during release'],
    ) {
	my ($attr, $msg) = @$_;
	$self->$log($msg) if $self->$attr;
    }

    my $sysname = $self->sysname;
    my ($repo_url, $repo_web) = (
	"https://git.savannah.nongnu.org/git/$sysname.git",
	"https://git.savannah.nongnu.org/cgit/$sysname.git",
    );

    # Make the README wrap to 70 columns.
    $Text::Wrap::columns = 70;

    $self->add_bundle(
	'@Filter' => {
	    -bundle	=> '@Basic',
	    -remove	=> do {
		my @remove = qw(GatherDir Readme);
		push @remove, 'UploadToCPAN' if $self->fake_release;
		\@remove;
	    },
	},
    );
    $self->add_plugins('FakeRelease') if $self->fake_release;

    # Use separate variables for these rather than a hash, because we
    # need to use literal strings or barewords in add_bundle() to make
    # Perl::PrereqScanner::Scanner::DistZilla::PluginBundle happy.
    my $tag_message = 'Release version %V.';
    my $signed = 1;

    if ($self->skip_push) {
	$self->add_bundle(
	    '@Filter' => {
		-bundle		=> '@Git',
		-remove		=> [qw(Git::Push)],
		tag_message	=> $tag_message,
		signed		=> $signed,
	    },
	);
    }
    else {
	$self->add_bundle(
	    '@Git' => {
		tag_message	=> $tag_message,
		signed		=> $signed,
	    },
	);
    }

    $self->add_plugins(
	qw(
	    Git::NextVersion Git::Contributors MetaConfig MetaJSON
	    NextRelease Test::ChangesHasContent PodSyntaxTests
	),

	['Git::GatherDir' => {
	    # We don't want to include this, because it will be
	    # generated in the dist.
	    exclude_filename	=> 'LICENSE',
	}],

	[Bugtracker => {
	    # We want the https version, not http.
	    web			=>
	    'https://rt.cpan.org/Public/Dist/Display.html?Name=%s',
	    # We want the real email address, not
	    # "bug-%l at rt.cpan.org". We ain't afraid of no spammers!
	    mailto		=> 'bug-%s@rt.cpan.org',
	}],

	[MetaResourcesFromGit => {
	    homepage		=> undef,

	    # These are set by Bugtracker, because
	    # MetaResourcesFromGit doesn't allow setting
	    # bugtracker.mailto (we unset that here just in case it's
	    # later added as a feature to MetaResourcesFromGit).
	    'bugtracker.web'	=> undef,
	    'bugtracker.mailto'	=> undef,

	    'repository.url'	=> $repo_url,
	    'repository.web'	=> $repo_web,
	}],

	# This is significantly slow, but it may be necessary to
	# define $VERSION, and it's not worth it to not use this
	# plugin in fast build mode.
	[PkgVersion => {
	    die_on_existing_version	=> 1,
	    die_on_line_insertion	=> 1,
	}],

	# This is also significantly slow, but unfortunately
	# necessary, even in fast build mode, because otherwise the
	# file may not compile.
	[PodWeaver => {
	    config_plugin	=> '@Author::ASDAGO',
	    replacer		=> 'replace_with_comment',
	}],
    );

    # These can significantly slow down the build, and are not
    # necessary for local testing.
    $self->add_plugins(qw(AutoPrereqs ReadmeAnyFromPod))
	unless $self->fast_build;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::ASDAGO - ASDAGO's Dist::Zilla plugin bundle

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This is ASDAGO's plugin bundle for Dist::Zilla.

=head1 ATTRIBUTES

=head2 sysname

This is the system name used for the git repository on
L<Savannah|https://savannah.nongnu.org>. It defaults to the
distribution name. You can use formatting codes as for
Dist::Zilla::Plugin::MetaResourcesFromGit.

=head2 fast_build

If this is true, then some things will be skipped in order to generate
the build faster. B<Do not use this in releases.> The environment
variable C<FAST_BUILD> can also be used to set this attribute.

Things that are skipped are things that should be present in releases,
but are not necessary for testing and may slow down the build
significantly. For example, auto-generated prerequisites.

=head2 fake_release

If this is true, then use the
L<FakeRelease|Dist::Zilla::Plugin::FakeRelease> plugin instead of
L<UploadToCPAN|Dist::Zilla::Plugin::UploadToCPAN>. The environment
variable C<FAKE_RELEASE> can also be used to set this attribute.

=head2 skip_push

If this is true, then pushing to the git repository will be skipped
during release. The environment variable C<SKIP_PUSH> can also be used
to set this attribute.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-PluginBundle-Author-ASDAGO>
or by email to
L<bug-Dist-Zilla-PluginBundle-Author-ASDAGO@rt.cpan.org|mailto:bug-Dist-Zilla-PluginBundle-Author-ASDAGO@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Asher Gordon <AsDaGo@posteo.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 Asher Gordon <AsDaGo@posteo.net>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

=cut
