use Test::More tests => 13; # -*- mode: cperl -*-
use File::Temp qw(tempdir);
use File::Basename qw(basename);
use Cwd qw(getcwd);
use Test::Exception;
use Git;

use lib qw(../lib lib );

BEGIN {
  use_ok( 'Git::Repo::Commits' );
}

# Create test repo
my $cwd = getcwd;
my $dirname = tempdir(CLEANUP => 1);
my $basename = basename $dirname;
diag $dirname;
mkdir $dirname;
chdir $dirname;
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
is $commits->name, undef;
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

subtest lack_of_dir => sub {
    throws_ok { new Git::Repo::Commits } qr/Need a repo directory/, 'Exception when no repo was provided';
};

subtest distant => sub {
    chdir $cwd;
    my $commits = new Git::Repo::Commits $dirname;
    is $commits->name, $basename;
};

diag( "Testing Git::Repo::Commits $Git::Repo::Commits::VERSION" );

sub write_file {
  my ($file_name, $file_content) = @_;
  open my $fh, ">", $file_name;
  print $fh $file_content;
  close $fh;
}
