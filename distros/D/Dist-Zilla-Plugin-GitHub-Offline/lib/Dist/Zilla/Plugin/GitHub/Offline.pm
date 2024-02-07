package Dist::Zilla::Plugin::GitHub::Offline;
$Dist::Zilla::Plugin::GitHub::Offline::VERSION = '0.002';
use strict;
use warnings;

use Moose;

with 'Dist::Zilla::Role::MetaProvider';

use Carp;
use Git::Wrapper;

has remote => (
	is      => 'ro',
	isa     => 'Str',
	default => 'origin'
);

has repo => (
	is	  => 'ro',
	isa	 => 'Str',
	builder => '_build_repo',
	lazy => 1,
);

has mode => (
	is      => 'ro',
	isa     => 'Str',
	default => 'https'
);

sub _build_repo {
	my ($self, $login) = @_;

	my ($url) = do {
		local $ENV{LANG}='C';
		my $git = Git::Wrapper->new('./');
		map /Fetch URL: (.*)/, $git->remote('show', '-n', $self->remote);
	};

	my ($repo) = $url =~ /github\.com.*?[:\/](.*)\.git$/ or croak 'Could not figure out repository';

	return $repo;
}

sub metadata {
	my $self = shift;

	my $repo = $self->repo;
	my $html_url = "https://github.com/$repo";
	my $issues_url = "$html_url/issues";
	my $git_url = $self->mode eq 'https' ?  "$html_url.git" : "git\@github.com:$repo.git";

	return {
		resources => {
			bugtracker => {
				web => $issues_url,
			},
			repository => {
				web  => $html_url,
				url  => $git_url,
				type => 'git',
			},
		}
	};
}

1;

# ABSTRACT: Add a GitHub repo's info to META.{yml,json}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::GitHub::Offline - Add a GitHub repo's info to META.{yml,json}

=head1 VERSION

version 0.002

=head1 DESCRIPTION

This Dist::Zilla plugin adds some information about the distribution's GitHub
repository to the META.{yml,json} files, using the official L<CPAN::Meta>
specification. It's similar to the C<[GitHub::Meta]> plugin in offline mode, but
will always set the bugtracker field.

L<GitHub::Meta::Offline> currently sets the following fields:

=over 4

=item C<repository>

=over 4

=item C<web>

URL pointing to the GitHub page of the project.

=item C<url>

URL pointing to the GitHub repository (C<git://...>).

=item C<type>

This is set to C<git> by automatically.

=back

=item C<bugtracker>

=over 4

=item C<web>

URL pointing to the GitHub issues page of the project.

=back

=back

=head1 ATTRIBUTES

=over

=item C<repo>

The name of the GitHub repository. By default the name will be extracted from
the URL of the remote specified in the C<remote> option, it can also be in the
form C<user/repo> when it belongs to another GitHub user/organization.

=item C<remote>

The name of the Git remote pointing to the GitHub repository (C<"origin"> by
default). This is used when trying to guess the repository name.

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
