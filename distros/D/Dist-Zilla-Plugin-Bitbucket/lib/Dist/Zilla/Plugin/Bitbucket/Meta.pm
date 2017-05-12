#
# This file is part of Dist-Zilla-Plugin-Bitbucket
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package Dist::Zilla::Plugin::Bitbucket::Meta;
$Dist::Zilla::Plugin::Bitbucket::Meta::VERSION = '0.001';
our $AUTHORITY = 'cpan:APOCAL';

# ABSTRACT: Add a Bitbucket repo's info to META.{yml,json}

use Moose;

extends 'Dist::Zilla::Plugin::Bitbucket';
with 'Dist::Zilla::Role::MetaProvider';

#pod =attr homepage
#pod
#pod The META homepage field will be set to the Bitbucket repository's
#pod root if this option is set to true (default).
#pod
#pod =cut

has 'homepage' => (
	is      => 'ro',
	isa     => 'Bool',
	default => 1,
);

#pod =attr bugs
#pod
#pod The META bugtracker web field will be set to the issue's page of the repository
#pod on Bitbucket, if this options is set to true (default).
#pod
#pod NOTE: Be sure to enable the issues section in the repository's
#pod Bitbucket admin page!
#pod
#pod =cut

has 'bugs' => (
	is      => 'ro',
	isa     => 'Bool',
	default => 1,
);

#pod =attr wiki
#pod
#pod The META homepage field will be set to the URL of the wiki of the Bitbucket
#pod repository, if this option is set to true (default is false).
#pod
#pod NOTE: Be sure to enable the wiki section in the repository's
#pod Bitbucket admin page!
#pod
#pod =cut

has 'wiki' => (
	is      => 'ro',
	isa     => 'Bool',
	default => 0,
);

sub metadata {
	my $self = shift;

	my $repo_name = $self->_get_repo_name;
	return {} if (!$repo_name);
	if($repo_name =~ /\/(.*)$/) {
		$repo_name = $1;
	} else {
		die "unknown repo name";
	}

	my ($login, undef) = $self->_get_credentials(1);
	return if (!$login);

	# Build the meta structure
	my $html_url = 'https://bitbucket.org/' . $login . '/' . $repo_name;
	my $meta = {
		'resources' => {
			'repository' => {
				'web' => $html_url,
				'url' => ( $self->scm eq 'git' ? 'git://git@bitbucket.org:' . $login . '/' . $repo_name . '.git' : $html_url ),
				'type' => $self->scm,
			},
		},
	};
	if ( $self->homepage and ! $self->wiki ) {
		# TODO we should use the API and fetch the current
		$meta->{'resources'}->{'homepage'} = $html_url;
	}
	if ( ! $self->homepage and $self->wiki ) {
		$meta->{'resources'}->{'homepage'} = $html_url . '/wiki/Home';
	}
	if ( $self->bugs ) {
		$meta->{'resources'}->{'bugtracker'} = {
			'web' => $html_url . '/issues'
		};
	}

	return $meta;
}

no Moose;
__PACKAGE__ -> meta -> make_immutable;
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse

=for Pod::Coverage metadata

=head1 NAME

Dist::Zilla::Plugin::Bitbucket::Meta - Add a Bitbucket repo's info to META.{yml,json}

=head1 VERSION

  This document describes v0.001 of Dist::Zilla::Plugin::Bitbucket::Meta - released November 03, 2014 as part of Dist-Zilla-Plugin-Bitbucket.

=head1 DESCRIPTION

	# in dist.ini
	[Bitbucket::Meta]

This L<Dist::Zilla> plugin adds some information about the distribution's Bitbucket
repository to the META.{yml,json} files, using the official L<CPAN::Meta>
specification.

This module currently sets the following fields:

=over 4

=item C<homepage>

The official home of this project on the web, taken from the Bitbucket repository
info. If the C<homepage> option is set to false this will be skipped (default is
true).

=item C<repository>

=over 4

=item C<web>

URL pointing to the Bitbucket page of the project.

=item C<url>

URL pointing to the Bitbucket repository (C<hg://...>).

=item C<type>

Either C<hg> or C<git> will be auto-detected and used.

=back

=item C<bugtracker>

=over 4

=item C<web>

URL pointing to the Bitbucket issues page of the project. If the C<bugs> option is
set to false (default is true) this will be skipped.

=back

=back

=head1 ATTRIBUTES

=head2 homepage

The META homepage field will be set to the Bitbucket repository's
root if this option is set to true (default).

=head2 bugs

The META bugtracker web field will be set to the issue's page of the repository
on Bitbucket, if this options is set to true (default).

NOTE: Be sure to enable the issues section in the repository's
Bitbucket admin page!

=head2 wiki

The META homepage field will be set to the URL of the wiki of the Bitbucket
repository, if this option is set to true (default is false).

NOTE: Be sure to enable the wiki section in the repository's
Bitbucket admin page!

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla::Plugin::Bitbucket|Dist::Zilla::Plugin::Bitbucket>

=back

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
