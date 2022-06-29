# TODO: Update Makefile.PL to include new Test2::V0 framework
# TODO: die_on_fail (or restructure tests so this isn't needed)
# 

package TestDriver;
our $VERSION = 0.02;

use Test2::V0;
use v5.10;

use Cwd qw(getcwd);
use IPC::Run3;
use Getopt::Long;
use File::pushd;
use File::Slurp qw(read_file write_file edit_file append_file);
use Term::ANSIColor;
use Data::Dumper; # DEBUG
use FindBin;
use lib $FindBin::Bin; # Add local test lib to path
use lib "$FindBin::Bin/../lib"; # Add local test lib to path
use Git::Nuggit;
use Git::Nuggit::Status;
my $cmd_color = 'green on_grey4';
my $stderr_color = 'red';

#######################
# Test Administration #
#######################
sub new
{
    my ($class, $tests) = @_;

    # TODO: Ensure Bin and lib are appropriately added to env variables

    # TODO: Verify args is an array ref (set of test)s, or die

    my $opts = {

        # Defaults
        "verbose" => 0, # TODO: Is there a more test-frameworky way of doing this?
        "setup-verbose" => 0,
        "root" => "tmptests",
        "skip-setup" => 1, # Skip full setup unless explicitly requested
        "cmd" => "runall", # runall, list, or an index of test number to run
    };
    Getopt::Long::GetOptions($opts,
                             'verbose!',
                             'setup-verbose!',
                             'root',
                             'skip-setup!',
                             'test=i',
                             'list!',
                             'do_cmdlog!',
                             'do_fulllog!',
                             );
    $opts->{tests} = $tests;

    # Convert root path to absolute for easier usage
    $opts->{root} = File::Spec->rel2abs($opts->{root});
    if (defined($opts->{'test-work'})) {
        $opts->{'test-work'} = File::Spec->rel2abs($opts->{'test-work'});
    } else {
        # TODO: Use FileSpec to add to path
        $opts->{'test-work'} = $opts->{root}."/test";
    }
    
    my $self = bless $opts;

    # TODO: Flag to force reset of test folders

    return $self;
}
# Run Test Suite
sub run
{
    my $self = shift;
    
    if ($self->{list}) {
        return $self->list_tests();
    }

    $self->setup() if (!$self->{'skip-setup'});


    if (defined($self->{test})) {
        my $cmd = $self->{test};
        if ($cmd < scalar(@{$self->{tests}})) {
            $self->before_each();
            subtest(@{$self->{tests}[$cmd]});
        } else {
            $self->list_tests();
            die "ERROR: Invalid test index specified\n";
        }
    } else {
        foreach my $test (@{$self->{tests}}) {
            $self->before_each();
            subtest(@$test);
        }
    }
    done_testing;
}
# Execute a command
sub cmd {
    my $self = shift;
    my $cmd = shift;
    my $dir = shift;
    my $rtv;
    my $err;
    my $temp = pushd($dir) if $dir;

    $self->log($cmd);

    # Allow for 'ngt' not being in path during test
    if ($cmd =~ /^((ngt)|(nuggit))\s/) {
        $cmd = "$FindBin::Bin/../bin/$cmd";
    }
    
    #say "\tcwd=".getcwd() if $verbose > 1;

    # NOTE: This only works if underlying command returns error code to bash -- Git does not always do so
    # Git will also output nominal status to stderr
    eval { run3($cmd, undef, \$rtv, \$err); };

    if ($@) {
        my ($package, $filename, $line) = caller;
        die "Error: Cmd ($cmd) at $filename:$line from ".getcwd()." failed with: \n\t$@\n";
    } elsif ($?) {
        # TODO: unless flag to disable
        my ($package, $filename, $line) = caller;
        die "Error: Cmd ($cmd) at $filename:$line from ".getcwd()." failed with: $rtv $err\n";
    }
    if ($self->{fulllog_fh}) { # TODO: Do we need this logging?
        my $fh = $self->{'fulllog_fh'};
        say $fh $rtv;
        say $fh colored($err,$stderr_color);
    }
#    if    ( $@        ) { die "Error: $@\n";                       } # Internal Error
#    elsif ( $? & 0x7F ) { die "Killed by signal \n".( $? & 0x7F ); }
#    elsif ( $? >> 8   ) { die "$cmd Exited with error \n".( $? >> 8 )."\n $rtv \n $err";  }

    say $rtv if $self->{verbose} > 3;
    say colored($err,'red') if $self->{verbose} > 3; # Note: Git routinely writes to stderr

    return 1; #($?, $rtv, $err);

}
sub list_tests
{
    my $self = shift;
    my $test_cnt = 0;
    say "#\tDescription";
    say "--\t-----------";
    foreach my $test (@{$self->{tests}}) {
        my $key = @$test[0];
        my $fn = @$test[1];

        # TODO: Filter options?
        
        say "$test_cnt\t$key";
        $test_cnt++;
    }
    say "\n $test_cnt total tests defined";
#    done_testing();
#    exit();
}
sub setup
{
    my $self = shift;
    my $test_root = $self->{root};
    #my $tmp_verbose = $verbose; $verbose = $verbose_setup;

    if (-d $test_root) {
        # Delete to start with a fresh directory
        $self->log("setup() removing old test directory $test_root");
        system("rm", "-rf", $test_root);
    }

    # Create Root Test Directory
    mkdir($test_root);

    # Create several test repos
    $self->create_repo($test_root,"root");
    $self->create_repo($test_root,"sub1");
    $self->create_repo($test_root,"sub2");
    $self->create_repo($test_root,"sub3");

    # Add Demo Submodules
    $self->add_submodule($test_root,"root","sub1");
    $self->add_submodule($test_root,"root","sub2");
    $self->add_submodule($test_root,"root/sub1","sub3"); # only commits in sub1

    # Nested submodule requires an extra commit
    chdir("$test_root/root");
    $self->cmd('git commit -am "Added Nested Submodule"');
    $self->cmd("git push");
    #$verbose = $tmp_verbose;
    $self->log("setup() restored $test_root to known state");

}
sub begin {
    my $self = shift;
    if (!-d $self->{root}) {
        say "Running first-time test setup";
        $self->setup(); # Run First-Time Setup
    }
    chdir($self->{root});

    if (!$self->{'cmdlog_fh'} && $self->{'do_cmdlog'}) {
        open( $self->{cmdlog_fh}, ">", "$FindBin::Script.cmd.log");
    }
    if (!$self->{fulllog_fh} && $self->{do_fulllog}) {
        open( $self->{fulllog_fh}, ">", "$FindBin::Script.full.log");
    }

}
sub before_each {
    my $self = shift;

    chdir($self->{root});
    
    # If existing, delete it
    if (-d $self->{'test-work'}) {
        system("rm -rf ".$self->{'test-work'});
    }

    # Restore it
    mkdir("test");
    $self->cmd("cp -r *.git test/");
    chdir("test");

}

sub dotest {
    my $self = shift;
    $self->begin();
    subtest_buffered(@_);
}

############
## Logging #
############
sub log
{
    my $self = shift;
    my $msg = shift;
    say colored($msg,$cmd_color) if $self->{verbose};

    my $fh = $self->{'cmdlog_fh'};
    say $fh $msg if $fh;

    $fh = $self->{'fulllog_fh'};
    say $fh colored($msg,$cmd_color) if $fh;

}

##########################
# Common Test Components #
##########################
# Create a new Nuggit 'user' work area and object
sub create_user {
    my $self = shift;
    my $name = shift || "root";
    my $opts = shift // {};
    my $dir = $self->{'test-work'}."/root.git";

    my $branch = ($opts->{branch}) ? "-b $opts->{branch}" : "";
    
    ok(chdir($self->{'test-work'}));
    $self->cmd("ngt clone $dir $branch $name");
    ok(-d $name);
    ok(chdir($name));
    ok(-e ".nuggit", "Verify .nuggit exists after clone") or skip "Aborting test1, nuggit failed";
    ok(-d ".git");
    ok(-d "sub1");
    ok(-d "sub2");
    ok(-e "sub1/README.md", "sub1 README.md exists");
    ok(-d "sub1/sub3", "sub3 nested submodule");
    ok(-e "sub1/sub3/README.md");

    # Create Nuggit Object
    my $ngt = Git::Nuggit->new("run_die_on_error" => 0);
    my $tmp = $ngt->root_dir();
    ok(-d $tmp);
    #say "***TODO: $tmp eq ".getcwd(); # TODO: Verify $tmp is as expected
    
    # Verify State is Pristine (no untracked, unstaged, or mismatched branches)
    # Use '-a' flag to ensure we check all submodules

    my $status = get_status({'all' => 1});
    ok( $status->{status} == STATE('CLEAN'), "Status is clean after clone" );
    ok( $status->{unstaged_files_cnt} == 0 && $status->{staged_files_cnt}==0, "No untracked files or refs" );
    ok( !$status->{detached_heads_flag}, "No detached heads");
    ok( $status->{branch_status_flag} == 0, "No detached heads or submodules on wrong branch" ) unless $opts->{skip_branch_check};
    return $ngt;
}

sub cd_user {
    my $self = shift;
    my $name = shift;
    
    my $dir = File::Spec->catdir($self->{'test-work'}, $name);
    ok(-d $dir, "user $name exists");
    ok(chdir($dir), "cd $name");
}

# Create a new repository at given path with some sample content
sub create_repo {
    my $self = shift;
    my $root_path = shift;
    my $repo_name = shift;
    my $path = $self->{root}."/".$repo_name;

    mkdir($path) unless (-d $path);
    chdir($path);

    $self->cmd("git init");

    write_file("README.md", "This is an initial test file.\nOriginal Repo at $path\n");

    $self->cmd("git add README.md");
    $self->cmd("git commit -am 'README.md'");

    # Create a 'bare' clone to serve as reference
    chdir($root_path);
    $self->cmd("git clone --bare $path");

    # Set Remote (which will be created next)
    chdir($path);
    $self->cmd("git remote add origin $path.git");
    $self->cmd("git fetch");
    $self->cmd("git branch -u origin/master master");
    
}
sub create_file {
    my $self = shift;
    my $fn = shift;
    my $text = shift;

    write_file($fn, $text);
    ok($self->cmd("ngt add $fn"));
    ok($self->cmd("ngt commit -m \"Created file $fn\""));

    return 1;
    
}
# Add a Submodule Reference to Sample Repo
sub add_submodule {
    my $self = shift;
    my $root_path = shift;
    my $repo_name = shift;
    my $sub_name = shift;
    my $path = $root_path."/".$repo_name;
    my $sub_path = $root_path."/".$sub_name.".git";

    chdir($path);
    $self->cmd("git submodule add $sub_path");
    edit_file { s/$root_path/\.\./g } "$path/.gitmodules";
    $self->cmd("git commit -am 'Added submodule $sub_name'");
    $self->cmd("git push"); 
}
# Appends content to specified file, commits, and pushes (at all levels) with appropriate verifications
sub test_write {
    my $self = shift;
    my $opts = shift || {title => "Test Write"};
    my $title = $opts->{'title'} // $opts->{msg};
    my $rtv;
    subtest $title => sub { $rtv = $self->_test_write($opts); };
    return $rtv;
}
sub _test_write {
    my $self = shift;
    my $opts = shift;
    
    my $msg = $opts->{msg} || "test_write(".++$self->{num_writes}.")";
    my $fn = $opts->{fn} || "sub1/sub3/README.md";

    my $num_tests = 8;
    if ($opts && defined($opts->{'check_modified'})) {
        $num_tests += scalar(@{$opts->{'check_modified'}});
    }
    #$num_tests += scalar(@{$opts->{'check_modified'}}) if ($opts && defined($opts->{'check_modified'}));
    plan($num_tests);

    # Update a file in nested sub3
    ok(lives {append_file($fn, ($msg."\n"))}, "Write to file $fn");
    $self->log("# Write \"$msg\" to $fn");

    # Verify Status
    my $status = get_status();
    ok( $status->{status} == STATE('MODIFIED'), "Check repo Modified (".show_status($status->{status}).")" );
    
    my $obj = file_status($status, $fn);
    ok( $obj && $obj->{status} == STATE('MODIFIED'), "Check file $fn Modified" ); # TODO

    if ($opts && $opts->{check_modified}) {
        # Assume a list of parent submodules given that should be modified at this point
        foreach my $dir (@{$opts->{check_modified}}) {
            $obj = file_status($status, $dir);
            ok(  $obj && $obj->{status} == STATE('MODIFIED'), "Check $dir Modified");
        }
    }
    
    # Stage sub3 Change
    ok($self->cmd("ngt add $fn"), "Stage submodule reference");
    $status = get_status(); $obj = file_status($status, $fn);
    ok( $obj && $obj->{staged_status} == STATE('MODIFIED'), "Verify $fn is staged");

    # Commit
    my $copts = ($opts && $opts->{no_branch_check}) ? "--no-branch-check" : "";
    ok($self->cmd("ngt commit $copts -m \"Update $fn file\""), "Commit $fn change");

    # Verify Status
    $status = get_status();
    ok( status_check($status) );

    # Push Changes
    if ($opts && $opts->{push_fail}) {
        dies_ok{$self->cmd("ngt push")} "Push all changes, expect conflict";
    } elsif (!$opts || !$opts->{skip_push}) {
        ok($self->cmd("ngt push"), "Push all changes");
    } else {
        pass();
    }
   

    say ">>> test_write($msg,$fn) Complete" if $self->{verbose};

    return $msg;
}
