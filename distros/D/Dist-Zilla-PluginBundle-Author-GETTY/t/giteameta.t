use strict;
use warnings;

use Test::More;
use Dist::Zilla::Plugin::Author::GETTY::GiteaMeta;

# Pins how Author::GETTY::GiteaMeta turns a git remote URL into repository
# metadata. _parse_remote_url and _build_resources are pure (no zilla/git), so
# they are exercised here as class methods. The URL parser is generic; the
# codeberg.org restriction lives in _slug/metadata, which skip (add nothing)
# when the remote points elsewhere.

my $C = 'Dist::Zilla::Plugin::Author::GETTY::GiteaMeta';

# --- URL parsing: all the remote forms map to the same host/slug ---
my @urls = (
  'git@codeberg.org:getty/p5-www-gitea.git',
  'https://codeberg.org/getty/p5-www-gitea.git',
  'https://codeberg.org/getty/p5-www-gitea',
  'ssh://git@codeberg.org/getty/p5-www-gitea.git',
  'git@codeberg.org:getty/p5-www-gitea',
);
for my $url (@urls) {
  is_deeply $C->_parse_remote_url($url),
    { host => 'codeberg.org', slug => 'getty/p5-www-gitea' },
    "parsed: $url";
}

# parser reports whatever host it sees; a non-codeberg host is later skipped
is_deeply $C->_parse_remote_url('git@github.com:getty/p5-www-gitea.git'),
  { host => 'github.com', slug => 'getty/p5-www-gitea' },
  'non-codeberg remote still parses (host enforcement happens in _slug)';

is $C->_parse_remote_url('not a url'), undef, 'garbage remote -> undef';

# --- resource assembly ---
my %base = (host => 'codeberg.org', slug => 'getty/p5-www-gitea', dist_name => 'WWW-Gitea');

{
  my $res = $C->_build_resources(%base, issues => 1, homepage => 'repo');
  is $res->{repository}{web},  'https://codeberg.org/getty/p5-www-gitea',        'repository.web';
  is $res->{repository}{url},  'https://codeberg.org/getty/p5-www-gitea.git',    'repository.url';
  is $res->{repository}{type}, 'git',                                           'repository.type';
  is $res->{bugtracker}{web},  'https://codeberg.org/getty/p5-www-gitea/issues', 'bugtracker.web';
  is $res->{homepage},         'https://codeberg.org/getty/p5-www-gitea',        'homepage = repo';
}

{
  my $res = $C->_build_resources(%base, issues => 0, homepage => 'repo');
  ok ! exists $res->{bugtracker}, 'issues = 0 -> no bugtracker';
}

{
  my $res = $C->_build_resources(%base, issues => 1, homepage => 'metacpan');
  is $res->{homepage}, 'https://metacpan.org/release/WWW-Gitea', 'homepage = metacpan';
}

{
  my $res = $C->_build_resources(%base, issues => 1, homepage => 'none');
  ok ! exists $res->{homepage}, 'homepage = none -> no homepage';
}

done_testing;
