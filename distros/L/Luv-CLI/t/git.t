use v5.38;
use Test::More;
use File::Temp qw(tempdir);

use Luv::CLI::Git;

plan skip_all => 'requires network access and git binary'
    unless `git --version` && !$@;

my $dir = tempdir( CLEANUP => 1 );
my $git = Luv::CLI::Git->new;

subtest 'clone a small public repo' => sub {
    my $dest = "$dir/test-clone";
    ok $git->clone( 'https://github.com/octocat/Hello-World', $dest ),
        'clone succeeds';
    ok -d "$dest/.git", '.git directory present';
};

subtest 'current_ref returns a commit sha' => sub {
    my $dest = "$dir/test-clone";
    my $sha  = $git->current_ref($dest);
    like $sha, qr/^[0-9a-f]{40}$/, 'looks like a git sha';
};

done_testing;
