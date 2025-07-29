use strict;
use warnings;
use Test::More tests => 11;

use_ok('Git::RemoteURL::Parse',
       qw(parse_git_remote_url)) or BAIL_OUT("Could not load module");

my @tests = (
             # GitHub HTTPS
             ['https://github.com/user1/repo1.git',
              {service => 'github', user => 'user1', repo => 'repo1'}
             ],
             ['https://user@github.com/user2/repo2',
              {service => 'github', user => 'user2', repo => 'repo2'}
             ],

             # GitHub SSH
             ['git@github.com:user3/repo3.git',
              {service => 'github', user => 'user3', repo => 'repo3'}
             ],
             ['git@gh-alias:user4/repo4',
              {service => 'github', user => 'user4', repo => 'repo4'}
             ],

             # GitLab HTTPS
             ['https://gitlab.com/group/sub/repo5.git',
              {service => 'gitlab', group_path => 'group/sub', repo => 'repo5'}
             ],
             ['https://gitlab.com/a/b/repo6',
              {service => 'gitlab', group_path => 'a/b', repo => 'repo6'}
             ],

             # GitLab SSH
             ['git@gitlab.com:group1/subgroup/repo7.git',
              {service => 'gitlab', group_path => 'group1/subgroup', repo => 'repo7'}
             ],
             ['git@gl-work:foo/bar/baz.git',
              {service => 'gitlab', group_path => 'foo/bar', repo => 'baz'}
             ],

             # Ungültige URLs
             ['https://example.com/foo/bar.git',   undef ],
             ['git@unknownhost.com:user/repo.git', undef ],
            );

foreach my $i (0 .. $#tests) {
    my ($url, $expected) = @{$tests[$i]};
    my $result = parse_git_remote_url($url);
    is_deeply($result, $expected, "Test $i: $url");
  }


