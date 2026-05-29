use strict;
use warnings;
use Test::More;

use_ok('Dist::Zilla::Plugin::GitHub::CreateRelease');

my $class = 'Dist::Zilla::Plugin::GitHub::CreateRelease';

# _repo_name_from_url only parses a string; it does not touch instance
# state, so we can exercise it as a class method.
my %cases = (
  'git@github.com:Getty/p5-git-libgit2.git' => 'p5-git-libgit2',
  'https://github.com/Getty/p5-git-libgit2.git' => 'p5-git-libgit2',
  'git@github.com:timlegge/perl-Foo.git' => 'perl-Foo',
  'https://github.com/timlegge/perl-Foo.git' => 'perl-Foo',
  'git@github.com:owner/repo-without-suffix' => 'repo-without-suffix',
  # a name that simply ends in "git" must keep its final character
  'https://github.com/owner/digit.git' => 'digit',
);

for my $url (sort keys %cases) {
  is($class->_repo_name_from_url($url), $cases{$url},
    "repo name parsed from $url");
}

done_testing;
