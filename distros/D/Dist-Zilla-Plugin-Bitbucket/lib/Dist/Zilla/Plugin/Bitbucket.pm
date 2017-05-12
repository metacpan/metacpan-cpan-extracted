#
# This file is part of Dist-Zilla-Plugin-Bitbucket
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package Dist::Zilla::Plugin::Bitbucket;
# git description: e7c5bde
$Dist::Zilla::Plugin::Bitbucket::VERSION = '0.001';
our $AUTHORITY = 'cpan:APOCAL';

# ABSTRACT: Plugins to integrate Dist::Zilla with Bitbucket

use Moose 2.1400;
use Moose::Util::TypeConstraints 1.01;
use Config::Identity::Bitbucket;

#pod =attr remote
#pod
#pod Specifies the git/hg remote name to use (default 'origin').
#pod
#pod =cut

has 'remote' => (
	is => 'ro',
	isa => 'Maybe[Str]',
	default => 'origin',
);

#pod =attr repo
#pod
#pod Specifies the name of the Bitbucket repository to be created (by default the name
#pod of the dist is used). This can be a template, so something like the following
#pod will work:
#pod
#pod 	repo = {{ lc $dist -> name }}
#pod
#pod =cut

has 'repo' => (
	is => 'ro',
	isa => 'Maybe[Str]',
);

#pod =attr scm
#pod
#pod Specifies the source code management system to use.
#pod
#pod The possible choices are hg and git. It will be autodetected from the
#pod distribution root directory if not provided.
#pod
#pod =cut

has 'scm' => (
	is => 'ro',
	isa => enum( [ qw( hg git ) ] ),
	lazy => 1,
	default => sub {
		my $self = shift;

		# Does git exist?
		if ( -d '.git' ) {
			return 'git';
		} elsif ( -d '.hg' ) {
			return 'hg';
		} else {
			die "Unknown local repository type!";
		}
	},
);

sub _get_credentials {
	my ($self, $nopass) = @_;

	# TODO I'm so lazy...
	## no critic (InputOutput::ProhibitBacktickOperators)

	my %identity = Config::Identity::Bitbucket->load;
	my ($login, $pass);

	if (%identity) {
		$login = $identity{'login'};
	} else {
		if ( $self->scm eq 'git' ) {
			$login = `git config bitbucket.user`;
		} else {
			$login = `hg showconfig bitbucket.user`;
		}
		chomp $login;
	}

	if (!$login) {
		my $error = %identity ?
			"Err: missing value 'user' in ~/.bitbucket" :
			"Err: Missing value 'bitbucket.user' in git/hg config";

		$self->log($error);
		return;
	}

	if (!$nopass) {
		if (%identity) {
			$pass  = $identity{'password'};
		} else {
			if ( $self->scm eq 'git' ) {
				$pass  = `git config bitbucket.password`;
			} else {
				$pass  = `hg showconfig bitbucket.password`;
			}
			chomp $pass;
		}

		if (!$pass) {
			$pass = $self->zilla->chrome->prompt_str( "Bitbucket password for '$login'", { noecho => 1 } );
		}
	}

	return ($login, $pass);
}

sub _get_repo_name {
	my ($self, $login) = @_;

	my $repo;
	if ( $self->scm eq 'git' ) {
		if ($self->repo) {
			$repo = $self->repo;
		} else {
			require Git::Wrapper;
			my $git = Git::Wrapper->new('./');
			my ($url) = map { /Fetch URL: (.*)/ } $git->remote('show', '-n', $self->remote);

			if ($url =~ /bitbucket\.org.*?[:\/](.*)\.git$/) {
				$repo = $1;
			} else {
				$repo = $self->zilla->name;
			}
		}

		# Make sure we return full path including user
		if ($repo !~ /.*\/.*/) {
			($login, undef) = $self->_get_credentials(1);
			$repo = "$login/$repo";
		}
	} else {
		# Get it from .hgrc
		if ( -f '.hg/hgrc' ) {
			require File::Slurp::Tiny;
			my $hgrc = File::Slurp::Tiny::read_file( '.hg/hgrc' );

			# TODO this regex sucks.
			# apoc@box:~/test-hg$ cat .hg/hgrc
			#[paths]
			#default = ssh://hg@bitbucket.org/Apocal/test-hg
			if ( $hgrc =~ /default\s*=\s*(\S+)/ ) {
				$repo = $1;
				if ( $repo =~ /bitbucket\.org\/(.+)$/ ) {
					$repo = $1;
				} else {
					die "Unable to extract Bitbucket repo from hg: $repo";
				}
			} else {
				die "Unable to parse repo from hg: $hgrc";
			}
		} else {
			die "Unable to determine repository name as .hg/hgrc is nonexistent";
		}
	}
	$self->log_debug([ "Determined the repo name for Bitbucket is %s", $repo ]);
	return $repo;
}

no Moose;
__PACKAGE__ -> meta -> make_immutable;
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee
diff irc mailto metadata placeholders metacpan

=head1 NAME

Dist::Zilla::Plugin::Bitbucket - Plugins to integrate Dist::Zilla with Bitbucket

=head1 VERSION

  This document describes v0.001 of Dist::Zilla::Plugin::Bitbucket - released November 03, 2014 as part of Dist-Zilla-Plugin-Bitbucket.

=head1 DESCRIPTION

This is a set of plugins for L<Dist::Zilla> intended
to more easily integrate L<Bitbucket|https://bitbucket.org> in the C<dzil> workflow.

The following is the list of the plugins shipped in this distribution:

=over 4

=item *

L<Dist::Zilla::Plugin::Bitbucket::Create>

Create Bitbucket repo on dzil new

=item *

L<Dist::Zilla::Plugin::Bitbucket::Update>

Update Bitbucket repo info on release

=item *

L<Dist::Zilla::Plugin::Bitbucket::Meta>

Add Bitbucket repo info to META.{yml,json}

=back

=head2 Configuration

Configure git with your Bitbucket credentials:

	$ git config --global bitbucket.user LoginName
	$ git config --global bitbucket.password MySecretPassword

Alternatively you can install L<Config::Identity> and write your credentials
in the (optionally GPG-encrypted) C<~/.bitbucket> file as follows:

	login LoginName
	password MySecretPassword

(if only the login name is set, the password will be asked interactively)

=head1 ATTRIBUTES

=head2 remote

Specifies the git/hg remote name to use (default 'origin').

=head2 repo

Specifies the name of the Bitbucket repository to be created (by default the name
of the dist is used). This can be a template, so something like the following
will work:

	repo = {{ lc $dist -> name }}

=head2 scm

Specifies the source code management system to use.

The possible choices are hg and git. It will be autodetected from the
distribution root directory if not provided.

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dist::Zilla::Plugin::Bitbucket

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Dist-Zilla-Plugin-Bitbucket>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Dist-Zilla-Plugin-Bitbucket>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-Plugin-Bitbucket>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Dist-Zilla-Plugin-Bitbucket>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-Bitbucket>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Dist-Zilla-Plugin-Bitbucket>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/overview/Dist-Zilla-Plugin-Bitbucket>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Dist-Zilla-Plugin-Bitbucket>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-Bitbucket>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Dist::Zilla::Plugin::Bitbucket>

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

Please report any bugs or feature requests by email to C<bug-dist-zilla-plugin-bitbucket at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-Plugin-Bitbucket>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/apocalypse/perl-dist-zilla-plugin-bitbucket>

  git clone https://github.com/apocalypse/perl-dist-zilla-plugin-bitbucket.git

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head1 ACKNOWLEDGEMENTS

This dist was shamelessly copied from ALEXBIO's excellent L<Dist::Zilla::Plugin::GitHub> :)

I didn't implement the PluginBundle nor the Command::gh modules as I didn't have a need for them. Please
let me know if you want them!

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
