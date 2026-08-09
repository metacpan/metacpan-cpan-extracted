use strict;
use warnings;
use Test::More;

use_ok('Dist::Zilla::Plugin::GitHub::CreateRelease');

my $class = 'Dist::Zilla::Plugin::GitHub::CreateRelease';

# _repo_owner_from_url only parses a string; it does not touch instance
# state, so we can exercise it as a class method.
my %cases = (
  'git@github.com:Getty/p5-git-libgit2.git'      => 'Getty',
  'https://github.com/Getty/p5-git-libgit2.git'  => 'Getty',
  # a repository whose owner differs from the releasing account's
  # github-identity login -- this is the case that used to be silently
  # discarded and made the release fail against the wrong owner.
  'git@github.com:pplu/kubernetes-rest.git'      => 'pplu',
  'https://github.com/pplu/kubernetes-rest.git'  => 'pplu',
  'git@github.com:owner/repo-without-suffix'     => 'owner',
);

for my $url (sort keys %cases) {
  is($class->_repo_owner_from_url($url), $cases{$url},
    "repo owner parsed from $url");
}

is($class->_repo_owner_from_url('not-a-remote-url'), undef,
  'no owner segment returns undef so callers can fall back');

done_testing;
