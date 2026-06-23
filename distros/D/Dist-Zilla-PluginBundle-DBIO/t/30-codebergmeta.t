use strict;
use warnings;

use Test::More;
use Dist::Zilla::Plugin::DBIO::CodebergMeta;

# Pins how DBIO::CodebergMeta turns a git remote URL into repository metadata.
# _parse_remote_url and _build_resources are pure (no zilla/git), so they are
# exercised here as class methods. The URL parser is generic; the codeberg.org
# restriction lives in _slug/metadata, which skip (add nothing) when the remote
# points elsewhere.

my $C = 'Dist::Zilla::Plugin::DBIO::CodebergMeta';

# --- URL parsing: all the remote forms map to the same host/slug ---
my @urls = (
  'git@codeberg.org:getty/DBIO.git',
  'https://codeberg.org/getty/DBIO.git',
  'https://codeberg.org/getty/DBIO',
  'ssh://git@codeberg.org/getty/DBIO.git',
  'git@codeberg.org:getty/DBIO',
);
for my $url (@urls) {
  is_deeply $C->_parse_remote_url($url),
    { host => 'codeberg.org', slug => 'getty/DBIO' },
    "parsed: $url";
}

# parser reports whatever host it sees; a non-codeberg host is later skipped
is_deeply $C->_parse_remote_url('git@github.com:p5-dbio/dbio-dzil.git'),
  { host => 'github.com', slug => 'p5-dbio/dbio-dzil' },
  'non-codeberg remote still parses (host enforcement happens in _slug)';

is $C->_parse_remote_url('not a url'), undef, 'garbage remote -> undef';

# --- resource assembly ---
my %base = (host => 'codeberg.org', slug => 'getty/DBIO', dist_name => 'DBIO');

{
  my $res = $C->_build_resources(%base, issues => 1, homepage => 'repo');
  is $res->{repository}{web},  'https://codeberg.org/getty/DBIO',        'repository.web';
  is $res->{repository}{url},  'https://codeberg.org/getty/DBIO.git',    'repository.url';
  is $res->{repository}{type}, 'git',                                    'repository.type';
  is $res->{bugtracker}{web},  'https://codeberg.org/getty/DBIO/issues', 'bugtracker.web';
  is $res->{homepage},         'https://codeberg.org/getty/DBIO',        'homepage = repo';
}

{
  my $res = $C->_build_resources(%base, issues => 0, homepage => 'repo');
  ok ! exists $res->{bugtracker}, 'issues = 0 -> no bugtracker';
}

{
  my $res = $C->_build_resources(%base, issues => 1, homepage => 'metacpan');
  is $res->{homepage}, 'https://metacpan.org/release/DBIO', 'homepage = metacpan';
}

{
  my $res = $C->_build_resources(%base, issues => 1, homepage => 'none');
  ok ! exists $res->{homepage}, 'homepage = none -> no homepage';
}

done_testing;
