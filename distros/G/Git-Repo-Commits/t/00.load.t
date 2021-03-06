use Test::More tests => 10; # -*- mode: cperl -*-
use Git;

use lib qw(../lib lib );

BEGIN {
  use_ok( 'Git::Repo::Commits' );
}

# Create test repo
mkdir "test-repo";
chdir "test-repo";
Git::command_oneline( 'init' );
Git::command_oneline( 'config','user.email','jj@merelo.net' );
Git::command_oneline( 'config','user.name','JJ' );
my $repo = Git->repository (Directory => '.');
write_file("one","one");
$repo->command_oneline( 'add', 'one' );
$repo->command_oneline( 'commit', '-am', "First" );
write_file("two","two");
$repo->command_oneline( 'add', 'two' );
write_file("one","one\none");
my $commit_author =  'N. O. T. Mine <not@mi.ne>';
$repo->command_oneline( 'commit', '-am', "Second", "--author", $commit_author );

# Now the real thing
my $commits = new Git::Repo::Commits ".";
ok ($commits, "Object created");
my @commit_array = @{$commits->commits()};
is( $#commit_array, 1, "Correct number of commits");
is ( @{$commit_array[1]->{'files'}}, 2, "Commit info correct");
is ( @{$commits->hashes()}, 2, "Commit hashes correct");
is ( $commit_array[1]->{'author'}, $commit_author, "Author changed");

write_file("one","one\none two three");
my @files = qw( one );
$commits = new Git::Repo::Commits ".", \@files ;
ok ($commits, "File object created");
my @commit_array = @{$commits->commits()};
is( $#commit_array, 1, "Correct number of commits");
is ( @{$commit_array[1]->{'files'}}, 2, "Commit info correct");
is ( @{$commits->hashes()}, 2, "Commit hashes correct");

diag( "Testing Git::Repo::Commits $Git::Repo::Commits::VERSION" );

sub write_file {
  my ($file_name, $file_content) = @_;
  open my $fh, ">", $file_name;
  print $fh $file_content;
  close $fh;
}
