use strict;
use Test::More;
use Git::Archive;
use File::Path qw/remove_tree make_path/;
use Data::Dumper;
use IPC::Cmd qw[can_run];

unless ( can_run('git') ) {
     ok(1,'No git, no dice');
     done_testing;
     exit 0;
     }

my ($ld, $rd) = ('t/local', 't/remote');
remove_tree($ld, $rd,'t/nongit');
# These should JFW and go without saying, or something went horribly wrong
like(`git --version`, qr/git version/, 'Git is installed');
use_ok('Git::Repository');

# Right. We need a repo with a remote, so we'll need to create a bare repo and clone it
mkdir($rd);
ok(!system("git init --bare $rd"), 'Bare git dir setup');
my $origin = Git::Repository->new( git_dir => $rd );
Git::Repository->run( clone => $rd, $ld );
ok(-e "$ld/.git", 'Successful git clone');
my $repo = Git::Repository->new( work_tree => $ld );

## Populate name & email if not already done
unless ( $repo->run( 'config', 'user.email' ) ) {
    system( $repo->run( 'config', 'user.email', '"git.user@example.com"' ) );
    }
unless ( $repo->run( 'config', 'user.name' ) ) {
    system( $repo->run( 'config', 'user.name', '"Automated Commit"' ) );
    }

# Right.. initial commit time
{
    open(my $foo, '>', "$ld/foo");
    print $foo "First line\n";
    close $foo;
    $repo->run( add => 'foo' );
    $repo->run( commit => '-m "First post!"' );
    $repo->run( push => '--set-upstream', 'origin', 'master');
    my @logs = $repo->run( log => '--pretty=oneline');
    is(scalar @logs, 1, 'Initial commit successful');
    my @o_logs = $repo->run( log => '--pretty=oneline', 'origin/master');
    is(scalar @o_logs, 1, 'Initial commit push successful');
    }

# And a second commit, for luck
{
    open(my $foo, '>>', "$ld/foo");
    print $foo "Second line\n";
    close $foo;
    $repo->run( add => 'foo' );
    $repo->run( commit => '-m "Second post!"' );
    $repo->run( 'push' );
    $repo->run( 'pull' );
    my @logs = $repo->run( log => '--pretty=oneline');
    is(scalar @logs, 2, 'Second commit successful');
    my @o_logs = $repo->run( log => '--pretty=oneline', 'origin/master');
    is(@o_logs, 2, 'Second commit push successful');
    }

# And on to testing the actual code...
sub update_foo {
    my $str = shift;
    open(my $foo, '>>', "$ld/foo");
    if ($str) {
        print $foo "$str\n";
        }
    else {
        print $foo "Another line\n";
        }
    close $foo;
    }

sub basic_data {
    return (
        msg => 'an update',
        files => 'foo',
        error => sub { shift; return shift },
        );
    }

{   # Test the param-testing code
    update_foo();
    my %no_msg = basic_data();
    delete $no_msg{msg};
    like(Git::Archive->commit(\%no_msg), qr/No commit message/, 'Correct msg error');
    my %no_files = basic_data();
    delete $no_files{files};
    like(Git::Archive->commit(\%no_files), qr/No files specified/, 'Correct files error');
    }

{   # Test the environment-checking
    ## Non-existent directory
    my %bad_dir = basic_data();
    $bad_dir{git_dir} = 'flibble';
    like(Git::Archive->commit(\%bad_dir), qr/No such directory/, 'Correct git error');
    ## Non-git directory
    %bad_dir = basic_data();
    mkdir('t/nongit');
    $bad_dir{git_dir} = 't/nongit';
    like(Git::Archive->commit(\%bad_dir), qr/No \.git found/, 'Correct git error');
    ## File already staged
    open(my $bar, '>>', "$ld/bar");
    print $bar "A line\n";
    close $bar;
    my %data = basic_data();
    $data{git_dir} = $ld;
    my $repo = Git::Repository->new( work_tree => $ld );
    $repo->run( add => 'bar' );
    like(Git::Archive->commit(\%data), qr/Repo already has staged files/, 'Staged files');
    $repo->run( commit => '-m "Commit bar"' );
    }

# Seems all the right error checking works. Can we commit?
{   # Commit named file
    update_foo();
    my %data = basic_data();
    $data{git_dir} = $ld;
    is(Git::Archive->commit(\%data), 0, 'Committed file');
    my @logs = $repo->run( log => '--pretty=oneline');
    is(scalar @logs, 4, 'Commit successful');
    }

{   # Commit known files
    update_foo();
    my %data = basic_data();
    $data{git_dir} = $ld;
    delete $data{files};
    $data{all_tracked} = 1;
    is(Git::Archive->commit(\%data), 0, 'Committed known file');
    my @logs = $repo->run( log => '--pretty=oneline');
    is(scalar @logs, 5, 'Commit successful');
    }

{   # Commit unknown files
    open(my $baz, '>>', "$ld/baz");
    print $baz "A line\n";
    close $baz;
    my %data = basic_data();
    $data{git_dir} = $ld;
    delete $data{files};
    $data{all_dirty} = 1;
    is(Git::Archive->commit(\%data), 0, 'Committed unknown file');
    my @logs = $repo->run( log => '--pretty=oneline');
    is(scalar @logs, 6, 'Commit successful');
    }

{   # Commit files in arrayref
    update_foo();
    open(my $bar, '>>', "$ld/bar");
    print $bar "A line\n";
    close $bar;
    my %data = basic_data();
    $data{git_dir} = $ld;
    $data{files} = [qw/foo bar/];
    is(Git::Archive->commit(\%data), 0, 'Committed file');
    my @logs = $repo->run( log => '--pretty=oneline');
    is(scalar @logs, 7, 'Commit successful');
    }

{   # Commit file with spaces in name
    update_foo();
    open(my $space, '>>', "$ld/spaced\ file");
    print $space "A line\n";
    close $space;
    my %data = basic_data();
    $data{git_dir} = $ld;
    $data{files} = ['spaced file', 'foo'];
    $data{check_all_staged} = 1;
    is(Git::Archive->commit(\%data), 0, 'Committed spaced file');
    my @logs = $repo->run( log => '--pretty=oneline');
    is(scalar @logs, 8, 'Commit successful');
    }

{   # Fail to commit when check_all_staged specified and not all files updated
    update_foo();
    my %data = basic_data();
    $data{git_dir} = $ld;
    $data{check_all_staged} = 1;
    $data{files} = [qw/foo bar/];
    like(Git::Archive->commit(\%data), qr/Some files not staged/, 'Did not commit files');
    $repo->run( checkout => 'foo' );
    }

{   # Commit & push
    update_foo();
    my %data = basic_data();
    $data{git_dir} = $ld;
    $data{use_remote} = 'origin';
    is(Git::Archive->commit(\%data), 0, 'Committed known file');
    my @logs = $repo->run( log => '--pretty=oneline');
    is(scalar @logs, 9, 'Commit successful');
    my @o_logs = $repo->run( log => '--pretty=oneline', 'origin/master');
    is(@o_logs, 9, 'Push successful');
    }

{   # Commit file in subdir
    update_foo();
    make_path( "$ld/dir" );
    open(my $bar, '>>', "$ld/dir/foo");
    print $bar "A line\n";
    close $bar;
    my %data = basic_data();
    $data{git_dir} = $ld;
    $data{files} = [qw#foo dir/foo#];
    is(Git::Archive->commit(\%data), 0, 'Committed file');
    my @logs = $repo->run( log => '--pretty=oneline');
    is(scalar @logs, 10, 'Commit successful');
    }

{   # Commit files in string
    update_foo();
    open(my $bar, '>>', "$ld/bar");
    print $bar "A line\n";
    close $bar;
    my %data = basic_data();
    $data{git_dir} = $ld;
    $data{files} = 'foo bar';
    is(Git::Archive->commit(\%data), 0, 'Committed file');
    my @logs = $repo->run( log => '--pretty=oneline');
    is(scalar @logs, 11, 'Commit successful');
    }

{   # Commit file when only subdir supplied
    open(my $bar, '>>', "$ld/dir/foo");
    print $bar "A line\n";
    close $bar;
    my %data = basic_data();
    $data{git_dir} = $ld;
    $data{files} = 'dir';
    is(Git::Archive->commit(\%data), 0, 'Committed file');
    my @logs = $repo->run( log => '--pretty=oneline');
    is(scalar @logs, 12, 'Commit successful');
    my $stat = $repo->run( show => '--stat');
    like($stat, qr#dir/foo#, 'Committed file in subdir');
    }

{   # Commit & fail to pull
    update_foo('one');
    $repo->run( commit => 'foo', '-m', 'one' );
    $repo->run( 'push' );
    $repo->run( qw/reset --hard HEAD^/ );
    update_foo('two');
    $repo->run( commit => 'foo', '-m', 'two' );
    my %data = basic_data();
    $data{git_dir} = $ld;
    $data{use_remote} = 'origin';
    like(Git::Archive->commit(\%data), qr/Cannot pull/, 'Failed to pull');
    my $st = $repo->run( 'status' );
    like($st, qr/1 and 1 different.*working directory clean/s, 'Correctly reverted');
    }

remove_tree($ld, $rd,'t/nongit');
done_testing;
