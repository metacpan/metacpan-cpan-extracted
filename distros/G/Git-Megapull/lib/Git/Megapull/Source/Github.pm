use strict;
use warnings;
package Git::Megapull::Source::Github;
{
  $Git::Megapull::Source::Github::VERSION = '0.101752';
}
use base 'Git::Megapull::Source';
# ABSTRACT: clone/update all your repositories from github.com

use LWP::UserAgent;
use Config::GitLike;
use JSON 2 ();


sub repo_uris {
  my $config_file = "$ENV{HOME}/.gitconfig";
  my $config = Config::GitLike->new(confname => $config_file);
  my $login       = $config->get(key => "github.login") || die "No github.login found in `$config_file'\n";
  my $token       = $config->get(key => "github.token") || die "No github.token found in `$config_file'\n";

  my $json = _get_json("http://github.com/api/v1/json/$login?login=$login&token=$token");

  my $data = eval { JSON->new->decode($json) };

  die "BAD JSON\n$@\n$json\n" unless $data;

  my @repos = @{ $data->{user}{repositories} };

  my %repo_uri;
  for my $repo (@repos) {
    # next if $repo->{private} and not $opt->{private};

    $repo_uri{ $repo->{name} } = sprintf 'git@github.com:%s/%s.git',
      $login,
      $repo->{name};
  }

  return \%repo_uri;
}

sub _get_json {
  my $url = shift;

  my $ua = LWP::UserAgent->new;
  $ua->env_proxy;

  my $response = $ua->get($url);
  if ($response->is_success) {
    return $response->content;
  } else {
    die $response->status_line;
  }
}

1;

__END__

=pod

=head1 NAME

Git::Megapull::Source::Github - clone/update all your repositories from github.com

=head1 VERSION

version 0.101752

=head1 OVERVIEW

This source for C<git-megapull> will look for a C<github> section in the file
F<~/.gitconfig>, and will use the login and token entries to auth with the
GitHub API, and get a list of your repositories.

=head1 METHODS

=head2 repo_uris

This routine does all the work and returns what Git::Megapull expects: a
hashref with repo names as keys and repo URIs as values.

=head1 WARNING

This source will probably be broken out into its own dist in the future.

=head1 TODO

  * add means to include/exclude private repos
  * add means to use alternate credentials
  * investigate using Github::API

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
