#!/usr/bin/env perl
#*******************************************************************************
##                           COPYRIGHT NOTICE
##      (c) 2020 The Johns Hopkins University Applied Physics Laboratory
##                         All rights reserved.
##
##  Permission is hereby granted, free of charge, to any person obtaining a 
##  copy of this software and associated documentation files (the "Software"), 
##  to deal in the Software without restriction, including without limitation 
##  the rights to use, copy, modify, merge, publish, distribute, sublicense, 
##  and/or sell copies of the Software, and to permit persons to whom the 
##  Software is furnished to do so, subject to the following conditions:
## 
##     The above copyright notice and this permission notice shall be included 
##     in all copies or substantial portions of the Software.
##
##  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
##  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
##  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
##  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
##  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
##  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
##  DEALINGS IN THE SOFTWARE.
##
#*******************************************************************************/

=head1 SYNOPSIS

Nuggit ops includes common nuggit checkout, rebase, merge, and pull operations. See man pages for those commands for details.


=head1 Sample Commands

Commands can be executed as "ngt ,,,", "nuggit ...", or "nuggit_ops.pl ..."

=over

=item checkout -b $branchName

Create a new branch with the given name in the root repository and all submodules.

=item checkout --safe [$branch]

Checkout the given $branch at the root repository and all submodules, providing that doing so does not affect the currently checked out revision.  If $branch is omitted, or no action will be taken unless a given submodule is currently in a detached HEAD state.  This command will resolve any detached HEADs that it detects if a branch exists that matches the current revision.

Note: The safe operation is not valid in conjunction with a filename, Tag or SHA commit reference.  Behavior in these conditions is undefined and error detection is not guaranteed.

=item checkout $branch_SHA_or_tag

Checkout the given branch, SHA commit, or tag at the root repository.  Nuggit will follow the committed references for all nested submodules.  At the conclusion of the operation, Nuggit will attempt to resolve any detached HEADs and will warn if it unable to do so.  Detached HEADs can occur if a submodule reference was not committed, or if the requested input is a SHA or tag that does not correspond to the HEAD of any known branches.  

=item checkout $file_or_directory

Perform a git checkout of a given file or directory. This command is used to revert changes to the workspace.

Note: If a directory is specified and contains submodules, the submodules will not be affected by this command.

=item merge $branch

Merge given branch into current checkout.

TIP: To merge a remote branch, run "ngt fetch && ngt merge origin/$branch"

=item pull

Pull changes from remote into current working branch.

=item rebase $branch

WARNING: Rebase support is considered experimental and has not been fully tested at this time.

=back

=cut

# TODO: Expand man page documentation.  Incorporate documentation from original checkout/pull/merge scripts as appropriate

use strict;
use warnings;
use v5.10;
use Getopt::Long;
use Cwd qw(getcwd);
use Pod::Usage;
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;
use Git::Nuggit::Status; # To verify post-op state
use Term::ANSIColor;
use Data::Dumper; # DEBUG Only. Delete before release

# List of supported operation modes for this script.  
my %modes = (
    "checkout"   => 1,
    "pull"       => 0,
    "merge"      => 0,
    "rebase"     => 0,
    "view"       => 0, # View current conflict state (debug option)
    # TODO: Add "switch" and "restore" support -- equivalent to checkout for specific purposes in git 2.23+. For our purposes, the primary difference is more stringent checks for file vs commit
   );
my $opts = {
    "verbose" => 0,
    "safe"    => 0,
    "ngtstrategy" => 'ref', # Original Nuggit behavior was branch-first, we now default to a ref-first strategy.
    "edit"    => 0, # If disabled and no message is defined for merge/rebase, pass --no-edit flag to use automatic commit message during conflict resolutions. 
};

# Initialize Nuggit & Logger prior to altering @ARGV
my $ngt = Git::Nuggit->new("run_die_on_error" => 0, "echo_always" => 0); 

ParseArgs();
die("Not a nuggit!\n") unless $ngt;
$ngt->start(level => 1, verbose => $opts->{verbose}); # Open Logger for loggable-command mode
my $root_dir = $ngt->root_dir();
chdir($root_dir) || die("Can't enter root_dir\n");

my $conflicts_state = $ngt->load_config("merge_conflict");

if ($opts->{continue}) {
    die "No known nuggit merge in progress, unable to continue.\n" if !$conflicts_state;
    do_operation_post();
    exit(0); # If we reached this point, success
} elsif ($opts->{abort}) {
    die "No known nuggit merge in progress, nothing to abort.\n" if !$conflicts_state;
    abort_merge_state();
} elsif ($opts->{mode} eq "view") {
    # View current conflicts state.  This option is primarily intended for debug purposes.
    if ($conflicts_state) {
        show_conflicts_state();
        exit(0);
    } else {
        die "Nuggit is not aware of any conflict resolution activities in progress.";
    }
} elsif ($conflicts_state) {
    die "ERROR: Cannot proceed when a merge is in progress. Run 'nuggit merge --continue' to complete the merge after resolving any conflicts, or 'ngt merge --abort' to abandon it.";
}

# Pre-operation status check applies to all.
# NOTE: While git can handle uncommitted changes in many cases, doing so is likely to confuse Nuggit and may result in unexpected commits or other undefined behavior.
# Specific cases where we can (and may automatically) skip this check include:
# - checkout --safe operations
# - checkout -b   branch creation options.
# - checkout of a known file (a file that exists on disk).  Checkout of an unknown (ie: deleted) file should be done via manual git commands for simplicity
$opts->{'skip-status-check'} = 1 if $opts->{mode} eq "checkout" && ($opts->{safe} || $opts->{create} || ($opts->{branch} && $opts->{file}) || ($opts->{branch} && -f $opts->{branch}));
if (!$opts->{'skip-status-check'}) {
    my $status = get_status({uno => 1});

    my $state = status_check($status);
    
    # For checkout-only, we can safely ignore unstaged refs-only status
    if (!$state && $opts->{mode} eq "checkout") {
        if ($status->{unstaged_files_cnt} == 0 && $status->{staged_files_cnt} == 0) {
            $state = 1;
            say colored('WARNING: Ignoring unstaged refs-only changes in workspace','warn');
        }
    }
    
    if (!$state)
    {
        say colored("Local changes detected.  Please commit or stash all changes before proceeding.", 'error');

        pretty_print_status($status, $ngt->{relative_path_to_root}, {user_dir => $ngt->{user_dir}});
        
        die colored("\n\u$opts->{mode} aborted due to dirty working directory.  Please stash (ie: 'ngt stash save') or commit and then re-run. This check can be bypassed with --skip-status-check, however doing so may result in undefined behavior should there be conflicts in these files.", 'warn')."\n";
    }
}

if ($opts->{mode} eq "checkout") {
    if (defined($opts->{branch}) && -e $opts->{branch}) { # TODO: Or user flag given to indicate file (ie; to checkout a deleted file)
        # User requested checkout of a file or diectory
        if ($opts->{safe} || $opts->{create}) {
            die "ERROR: --safe and -b options are not valid in conjunction with a file or directory name.\n";
        }
        if (-f $opts->{branch} || $opts->{file}) {
            # Request to checkout a file
            root_checkout_file($opts->{branch});
        } elsif (-d $opts->{branch}) {
            # Request to checkout a directory, with submodule checks
            # If directory is a submodule, then checkout the committed reference, and recurse appropriately
            # Otherwise, perform git-checkout only
            #root_checkout_file($opts->{branch});
            die "TODO: Directory checkout not yet implemented";
        } else { # Symlink?
            die "ERROR: $opts->{branch} exists but is neither a file nor directory?";
        }
    } elsif ($opts->{safe}) {
        root_checkout_safe($opts->{branch});
    } elsif ($opts->{create}) {
        root_checkout_create_branch($opts->{branch});
    } else {
        root_checkout_branch($opts->{branch});
    }
} elsif ($opts->{mode} eq "rebase" || ($opts->{mode} eq "pull" && $opts->{rebase})) {
    say colored("WARNING: Rebase support is currently an experimental/untested Ngt feature. Proceed at your own risk. Do you wish to proceed? (y/n)", 'error');
    my $input = <STDIN>;
    chomp($input);
    die "Aborting by user request.\n" if ($input ne "y");

    say colored('Proceeding. Please report any issues you may encounter, including steps to reproduce and resolve (manually) if applicable.', 'warn');
    root_operation();
} elsif ( ($opts->{mode} eq "merge" || $opts->{mode} eq "rebase") && $opts->{preview}) {
    # TODO: For future portability/packaging purposes, this should change to a require
    my $cmd = "nuggit_merge_tree.pl ";
    $cmd .= $opts->{base} if $opts->{base};
    $cmd .= " ".$opts->{branch} if $opts->{branch};
    $cmd .= " ".$opts->{branch2} if $opts->{Branch2};
    exec($cmd);
} elsif ($opts->{mode} eq "merge" || $opts->{mode} eq "pull") {
    root_operation();
} else {
    die "Invalid operation";
}

sub ParseArgs
{
    Getopt::Long::GetOptions( $opts,
                              "verbose|v!",
                              "help!",
                              "man!",
                              "safe!",
                              "create|b!",
                              "ngtstrategy|s=s",
                              "branch-first!",
                              "ref-first!",
                              "continue!",
                              "preview|p!",
                              "abort!",
                              "edit!",
                              "squash!",
                              "skip-status-check!",
                              "auto-create!",
                              "file!", # Tell Nuggit that specified argument is a file, even if it doesn't currently exist
                              "rebase!",
                              "default!", # Only valid in conjunection with branch-first strategy
                              "branch=s", # Optional explicit alternative to namesless spec
                              "remote=s", # Optional explicit alternative to namesless spec
                              'message|m', # Specify message to use for any commits upon merge (optional; primarily for purposes of automated testing). If omitted, user will be prompted for commit message.  An automated message will be used if a conflict has been automatically resolved.
                              
                # TODO: remote flag.  For pull operation, this will cause a pull in the root, and a submodule update --remote in all submodules.  This is a more git-like version of the previous '--default' concept.
                # TODO: Default flag.  For branch-first operations only.
               );
    
    # First unparsed argument indicates operation (ie: pull, merge, or checkout)
    if (@ARGV > 0) {
        $opts->{mode} = shift @ARGV;
        if ($opts->{preview} ) {
            $opts->{base} = shift @ARGV if @ARGV > 2;
            $opts->{branch} = (@ARGV > 1) ? shift @ARGV : "HEAD";
            $opts->{branch2} = shift @ARGV if @ARGV > 0;
        } else {
            $opts->{remote} = shift @ARGV if @ARGV > 0 && $opts->{mode} eq "pull"; # Special case for pull
            $opts->{branch} = shift @ARGV if @ARGV > 0;
        }
    }

    if ($opts->{help} || $opts->{man}) {
        my $pv = ($opts->{help} ? 1 : 2);
        my $input = $0; # This is the default value. If this fails, we can switch to FindBin
        my $msg = undef;
        
        if ($opts->{mode} && defined($modes{$opts->{mode}})) {
            $input = $FindBin::Bin.'/../docs/'.$opts->{mode}.".pod";

            if (!-e $input) {
                $input = $0;
                $msg = colored("Error: Unable to locate documentation. Try running \"man ngt-$opts->{mode}\" for additonal information",'warn');
            }
        } # else we display embedded POD from this file

        pod2usage(-exitval => 0,
                  -verbose => $pv,
                  -input => $input,
                  -msg => $msg
                  );
            
    }
    
    if(!defined($opts->{mode}) || !defined($modes{$opts->{mode}})) {
        my $err = ($opts->{mode}) ? "Please specify" : $opts->{mode}." is not";
        pod2usage(-exitval => 2, -verbose => 0, -output => \*STDERR,
                  -message => "$err a valid operation"
                  );
    }
    if (defined($opts->{'branch-first'})) {
        $opts->{'ngtstrategy'} = 'branch';
    } elsif (defined($opts->{'ref-first'})) {
        $opts->{'ngtstrategy'} = 'ref';
    } elsif ($opts->{'ngtstrategy'} ne "branch" && $opts->{'ngtstrategy'} ne 'ref') {
        die "Invalid strategy specified.  --ngtstrategy must be 'branch' or 'ref'.  See --man for details.";
    }

    # Sanity checks
    die "--default flag is only valid in conjunection with --branch-first strategy\n" if $opts->{default} && $opts->{'ngtstrategy'} ne 'branch';

}

=head2 checkout_create_branch

Nuggit equivalent to "git checkout -b $branch".

This function should be called from the root repository.

=cut
sub root_checkout_create_branch
{
    my $branch = shift || die "A branch name must be specified to create a new branch.\n";

    # Attempt to create branch
    my ($err, $stdout, $stderr) = $ngt->run("git checkout -b $branch");

    if ($err) {
        if ($stderr =~ /already exists/) {
            # Branch already exists
            say $stdout;
            say colored("Unable to checkout '$branch' as it already exists.  Re-run without the '-b' option to check it out.", 'error');
            exit 1;
        } else {
            say $stdout if $stdout;
            say $stderr if $stderr;
            die "Error: Unrecognized error checking out '$branch' at root repository. See above for details\n";
        }
    }

    # Run safe checkout on all submodules with the autocreate flag set
    my $warnings = {};
    $ngt->foreach({'load_tracking' => 1,
                  'breadth_first' => sub {
                      my $in = shift;
                      my $result = checkout_safe(branch => $branch, autocreate => 1, subname => $in->{'subname'});
                      if (!defined($result) || $result ne $branch) {
                          $warnings->{$in->{'subname'}} = {branch => $result, tracking => $in->{'tracking_branch'}};
                      }
                  }
                 });
                  
    my @keys = keys %$warnings;
    if (scalar @keys > 0) {
        say colored("Failed to safely create or checkout $branch in one or more submodules:\n", 'warn');
        printf "\t %-60s \t %-40s\n", "Submodule", "Current Branch";
        printf "\t %-60s \t %-40s\n", "---------", "--------------";
        foreach my $key (@keys) {
            my $kbranch = $warnings->{$key}->{branch};
            if ($kbranch && $warnings->{$key}->{tracking} && $kbranch eq $warnings->{$key}->{tracking}) {
                $kbranch = colored($kbranch, 'green');
            } elsif (!$kbranch) {
                $kbranch = colored("Detached HEAD", 'error');
            }

            printf( "\t %-60s \t %-40s\n",
                    $key,
                    $kbranch
                    );
        }
        say colored("Tip: A failure above generally indicates the desired branch already exists in the submodule at a different commit.  You may wish to resolve manually (git checkout and update submodule reference), or use a different branch name.  A",'info')
        .colored('green','green')
        .colored(" highlight indicates a match to the submodule's default tracking branch (if set).  To retrieve this information later, run 'ngt status -a'", 'info');
    } elsif (defined($branch)) {
        say colored("$branch has been successfully checked out.", 'success');
    } else {
        say colored("Automatic Detached HEAD resolution complete.", "success");
    }
}

sub root_checkout_safe
{
    my $branch = shift // get_selected_branch_here();

    # Run checkout at root level.
    my $root_result = checkout_safe(branch => $branch,
                               # Auto-create branch names in all submodules when safe to do so, unless user requested otherwise
                               autocreate => (defined($opts->{'auto-create'}) ? $opts->{'auto-create'} : 1)
                               );

    # If that doesn't work (and we aren't simply fitching detached heads), do not proceed (must fetch or create at root first).
    if ($branch && (!defined($root_result) || $root_result ne $branch)) {
        die ("$branch does not exist, or is not safe to checkout (--safe flag specified) in root repository.\n  If this is unexpected, you may need to perform a 'ngt fetch'.\n If the branch does not exist, you should create it with 'ngt checkout -b $branch'\n");
    }

    my $warnings = {};
    $ngt->foreach({
        'load_tracking' => 1,
        'breadth_first' => sub {
                      my $in = shift;

                      my $result = checkout_safe(branch => $branch,
                                              # Auto-create branch names in all submodules when safe to do so, unless user requested otherwise
                                              autocreate => (defined($opts->{'auto-create'}) ? $opts->{'auto-create'} : 1),
                                              subname => $in->{'subname'},
                                              hint_branch => $in->{'tracking_branch'},
                                             );
                      if (!defined($result) || !defined($branch) || (defined($branch) && $result ne $branch) ) {
                          $warnings->{$in->{'subname'}} = {branch => $result, tracking => $in->{'tracking_branch'}};
                      }
                  }
                  });
    my @keys = keys %$warnings;
    if (scalar @keys > 0) {
        my $dbranch = ($branch) ? "checkout $branch" : "resolve detached HEADs";
        say colored("Failed to safely $dbranch in one or more submodules:\n", 'warn');
        printf "\t %-40s \t %-40s\n", "Submodule", "Current Branch";
        printf "\t %-40s \t %-40s\n", "---------", "--------------";
        foreach my $key (@keys) {
            my $kbranch = $warnings->{$key}->{branch};
            if ($kbranch && $warnings->{$key}->{tracking} && $kbranch eq $warnings->{$key}->{tracking}) {
                $kbranch = colored($kbranch, 'green');
            } elsif (!$kbranch) {
                $kbranch = colored("Detached HEAD", 'error');
            }
            printf( "\t %-40s \t %-40s\n",
                    $key,
                    $kbranch
                    );
        }
        printf "\t %-40s \t %-40s\n", "/", colored("Detached HEAD",'error') if !$root_result;
        say colored("Tip: You may wish to create a new branch (ngt checkout -b <branch>) or update submodules manually if the above state was not expected.  A ",'info')
        .colored('green','green')
        .colored(" highlight indicates a match to the submodule's default tracking branch.  To retrieve this information later, run 'ngt status -a'", 'info');
    } elsif (defined($branch)) {
        say colored("$branch has been successfully checked out.", 'success');
    } else {
        say colored("Automatic Detached HEAD resolution complete.", "success");
    }
}

# Checkout a single file. This fn does not handle cases where parent directory does not exist, does not validate that argument is a file.  This function will work as expected if input is a deleted file, or a directory that is not a submodule and does not contain submodules.  It will not explicitly hande any submodules, unless 'git checkout' would.
sub root_checkout_file
{
    my $fn = shift;
    my $branch = shift;
    my $cwd = getcwd();
    
    # Split directory into components
    my ($vol, $dir, $file) = File::Spec->splitpath( $fn );
    
    # Enter parent folder
    chdir($dir) or die "Failed to cd $dir: $!";
    
    # Checkout file
    my $cmd;
    if ($branch) {
        $cmd = "git checkout $branch -- $file";
    } else {
        $cmd = "git checkout $file"
    }
    my ($err, $stdout, $stderr) = $ngt->run({echo_always=>1},$cmd);
    
    chdir($cwd);
    return !$err;
}

# Generic function that works for non-specialty push, pull, and checkout cases.  Initial version uses ref-first strategy, but future revisions will allow an option to use the original branch-first strategy.
# Specialty operations not handled by this function include "checkout -b" and "checkout --safe" options.
# NOTE: checkout behavior for branch-first strategy if given a SHA is undefined.
sub root_checkout_branch
{
    my $branch = $opts->{branch};

    if (!$branch && $opts->{default}) {
        # Default flag specified in place of branch, determine what default is for root
        my ($err, $stdout, $stderr) = $ngt->run('git symbolic-ref refs/remotes/origin/HEAD');
        ($branch) = $stdout =~ qr{^refs/remotes/origin/(.+)$ }x;
    }

    # TODO: Alternatively, use no-arguments as option to revert to matching commit (ie: non-safe?)
    die "checkout operation requires a branch, tag or SHA reference to proceed. Specify the '--safe' flag if you only want to resolve detached HEADs where possible" unless $branch;
    my $cmd = "git checkout --no-recurse-submodules $branch";
    
    # Perform operation on root
    my ($err, $stdout, $stderr) = $ngt->run($cmd);
    if ($err) {
        # An error likely indicates branch doesn't exist
        say $stdout if $stdout;
        say $stderr if $stderr;
        die colored("Failed to checkout $branch in root repository.",'error')
        ."\n"
        .colored("See above for details. If you wish to create a new branch, specify '-b' and try again. If this branch exists remotely, you may need to run a 'ngt fetch' before proceeding.", 'info')
        ."\n";
    }

    # Check root status
    my $real_branch = get_selected_branch_here();
    if (!$real_branch) {
        if ($opts->{'ngtstrategy'} eq 'branch') {
            say colored("Warning: Checkout of $branch at root resulted in DETACHED HEAD. Attempting to recurse, but be advised that results for this branch-first operation may be unpredictable unless '$branch' is a tag that exists in all submodules.  Usage of the default ref-first strategy is recommended in most cases.","warn");
        } else {
            $opts->{branch} = undef; # Ensure safe-checkout is not biased to an illegal branch name for submodules
        }
    }
    
    # Foreach submodule, non-recursive (to ensure we can recurse into new submodules as added, top-down
    $ngt->foreach({
        'load_tracking' => 1, # Load submodule tracking branch information when available
        'breadth_first' => \&do_root_checkout_breadth_first,
        'parallel'      => 1, # Use parallel execution (per-level) if available (Future enhancement) for checkout (cannot be used for merge/pull due to added complexities of conflict resolution).
        'recursive'     => 1, # Recuse into submodules. Breadth-first ensures we update a given submodule before recursing into it
        'run_root'      => 0,
        
    });

    my @keys = sort keys %{$opts->{results}};
    $branch = "default branch ($branch)" if $opts->{default};
    if (scalar @keys > 0) {
        say colored("Checkout of $branch completed with one or more potential warnings:", 'warn');
        printf "\t %-40s \t %-40s\n", "Submodule", "Status or Current Branch";
        printf "\t %-40s \t %-40s\n", "---------", "------------------------";
        foreach my $key (@keys) {
            my $val = $opts->{results}->{$key}->{branch};
            if ($opts->{results}->{$key}->{tracking} && $opts->{results}->{$key}->{tracking} eq $val) {
                $val = colored($val, 'green');
            } elsif (!$val) {
                $val = colored("Detached HEAD", 'error');
            }
            printf( "\t %-40s \t %-40s\n",
                    $key,
                    $val
                    );
        }
        printf "\t %-40s \t %-40s\n", "/", colored("Detached HEAD",'error') if !$real_branch;
        printf "\t %-40s \t %-40s\n", "---------", "--------------";
        say colored("Tip: You may wish to create a new branch (ngt checkout -b <branch>) or update submodules manually if the above state was not expected.  A ",'info')
        .colored('green','green')
        .colored(" highlight indicates a match to the submodule's default tracking branch.  To retrieve this information later, run 'ngt status -a'", 'info');

    } else {
        say colored("Checkout of $branch completed successfully", 'success');
    }
    
}

sub do_root_checkout_breadth_first {
    my $in = shift;
    
    my $op = $opts->{mode};
    my $branch = $opts->{branch};
    my $subname = $in->{'subname'};

    # If submodule is in a subdirectory, we just want the last directory.
    my @tmp = File::Spec->splitdir($subname);
    my $shortname = pop @tmp;

    # NOTE: This line is to provide a sense of progress.
    # TODO: Can we do this in a less verbose manner and/or speedup the process?
    say colored("Processing $in->{'subname'}", 'info');

    chdir("..") or die "Failed to cd to parent of $subname: $!"; 

    if ($opts->{'ngtstrategy'} eq 'branch' ) { # branch-first strategy
        if ($in->{status} eq '-') {
            my ($err, $stdout, $stderr) = $ngt->run("git submodule update --init $shortname");
            if ($err) {
                say $stdout if $stdout;
                say $stderr if $stderr;
                say colored("Error: Unable to initialize $subname", 'error');
                $opts->{results}->{$subname} = {branch => "ERROR - Unable to initialize", tracking => $in->{'tracking_branch'}};

                if (!$opts->{ignore_errors}) {
                    say colored("Do you wish to abort (q), ignore once (press enter), or ignore all subsequent errors (i)?", 'warn');
                    my $input = <STDIN>; chomp($input);
                    if ($input eq "i") {
                        $opts->{ignore_errors} = 1;
                    } elsif ($input eq "") {
                        return;
                    } else {
                        die "Aborting operation. Checkout operation may not have completed for all submodules.\n";
                    }
                }

                return;
            }
        }
        
        chdir($shortname) or die "Failed to cd $shortname: $!";

        # Default flag handling
        if (!$branch) {
            # This should only happen if --default was specified
            
            if ($in->{tracking_branch}) {
                $branch = $in->{tracking_branch};
            } else { # No tracking branch, revert to server default branch
                my ($err, $stdout, $stderr) = $ngt->run('git symbolic-ref refs/remotes/origin/HEAD');
                ($branch) = $stdout =~ qr{^refs/remotes/origin/(.+)$ }x;
            }
            if (!$branch) {
                say colored("Error: Unable to branch for $subname", 'error');
                $opts->{results}->{$subname} = {branch => "ERROR - Unable to checkout", tracking => $in->{'tracking_branch'}};
                return;
            } else {
                $opts->{results}->{$subname} = {branch => $branch, tracking => $in->{'tracking_branch'}};
            }
        }
        
        my ($err, $stdout, $stderr) = $ngt->run("git checkout --no-recurse-submodules $branch");
        if ($err) {
            say $stdout if $stdout;
            say $stderr if $stderr;
            say colored("Error: Unable to checkout $subname", 'error');
            $opts->{results}->{$subname} = {branch => "ERROR - Unable to checkout", tracking => $in->{'tracking_branch'}};
        }
    } else { # ref-first strategy
        my ($err, $stdout, $stderr) = $ngt->run("git submodule update --init --checkout $shortname");
        if ($err) {
            say $stdout if $stdout;
            say $stderr if $stderr;
            say colored("Error: Unable to follow reference for $subname", 'error');
            $opts->{results}->{$subname} = {branch => "ERROR - Unable to checkout", tracking => $in->{'tracking_branch'}};
        } else {
            chdir($shortname) or die "Failed to cd $shortname: $!";
            # Run a safe checkout to resolve any detached heads
            my $result = checkout_safe(branch => $branch,
                                       # Auto-create branch names in all submodules when safe to do so, unless user requested otherwise
                                       autocreate => (defined($opts->{'auto-create'}) ? $opts->{'auto-create'} : 1),
                                       subname => $subname,
                                       hint_branch => $in->{'tracking_branch'}
                                      );
            if (!defined($result) || !defined($branch) || $result ne $branch) {
                $opts->{results}->{$subname} = {branch => $result, tracking => $in->{'tracking_branch'}};
            }
        }
    }
}


# Note: This function assumes that input is a valid branch.  Behavior for Tags and SHAs may be undefined.  Error checking TODO
# Returns undef if in a detached HEAD state that cannot be resolved, or the name of the current branch otherwise.  If a branch has been requested, user should check if return value matches request to determine if it was successfully checked out.
# TODO: Should checkout_safe be migrated into Nuggit.pm?
sub checkout_safe
{
    my %args = @_;
    my $tgt_branch = $args{branch};
    my $autocreate = defined($args{autocreate}) ? $args{autocreate} : 1; # Autocreate is used by default
    if ($autocreate && $args{subname}) {
        # Note: If subname was not defined in call, we won't check config for autocreate overrides (aka ignore list)
        # TODO: This may be supplemented with support for wildcards
        my $subcfgs = $ngt->cfg("submodules");
        my $subcfg = $subcfgs->{$args{subname}};
        $autocreate = 0 if defined($subcfg) && $subcfg->{exclude};
    }

    say "Checkout Branch Safe at ".getcwd()." ".(defined($tgt_branch) ? $tgt_branch : "Fix Detached Heads Only") if $opts->{verbose};
    
    # Get current workspace state
    #  Expected output from shell:  $sha (HEAD -> branch[, branch2, ..]) $msg
    #  NOTE: Git output is different from a script:  $sha $msg
    my ($err, $info, $stderr) = $ngt->run('git show -s --no-abbrev-commit --no-color --format="format:%H%n%D"');

    my ($current_commit, $branches_raw) = split('\n', $info);    
    # Use chomp to remove any trailing whitespace -- aka \r for Windows users
    chomp($current_commit);
    chomp($branches_raw);

    # Split input at comma and trim whitespace
    my @branches = split('\s*,\s*', $branches_raw);
    my $head = shift @branches;
    my ($cur_branch) = ($head =~ /^HEAD\s\-\>\s([\/\-\.\w]+)$/);

    # Are we already on the desired branch (if given)
    if ($tgt_branch && $cur_branch && ($cur_branch eq $tgt_branch)) {
        # We are already on the branch. While it is safe to checkout, theree is no need to do so
        say "\t Already on $tgt_branch" if $opts->{verbose};
        return $tgt_branch;
    }

    # Tags don't help us here, so filter them out from the branches list
    @branches = grep { $_ !~ /^tag/ } @branches;

    # If we have a target branch
    if ($tgt_branch) {
        # There are several cases to handle here
        # - Branch does not exist locally or remotely.  Create branch if $autocreate (matches will be 0)
        # - Branch exists and matches locally - checkout_local
        # - Branch exists remotely with match and not locally.  checkout_safe_remote() to try updating        
        # - Branch exists remotely, but does not match and does not exist locally.  FUTURE: Consider creating new branch and setting upstream appropriately iff current SHA is an ancestor of remote SHA
        # - Branch exists locally, but does not match local or remote.  Do nothing


        
        # Get list of potentially matching branches (expect 0-2 matches)
        my @matches = grep( /^(origin\/)?$tgt_branch$/, @branches );
        if (scalar(@matches) == 2) { # origin and local branches both match, we are safe
            return checkout_local($tgt_branch);
        } elsif (scalar(@matches) == 0) { # No match in list at this commit, local or (previously fetched) remote
            
            if ($autocreate) {

                # Does branch already exist locally? If so, nothing to be done here (not safe to checkout)
                my $exists_local = `git branch --list $tgt_branch`;
                if (!$exists_local) {
                    # We can proceed to create only if branch does NOT exist remotely.
                    my $exists_remote = `git branch -r | grep $tgt_branch`;

                    # FUTURE: We can, optionally, proceed with autocreate locally if current commit is an ancestor of remote commit (ie: a candidate for a ff-only pull).  Any other condition would not be guaranteed 'safe'

                    if (!$exists_remote) {
                                        
                        my ($err, $stdout, $stderr) = $ngt->run("git checkout -b $tgt_branch");
                        if (!$err) {
                            return $tgt_branch;
                        } else { # else continue on to detached-head check, though this shouldn't fail
                            warn colored("WARNING: Ngt Safe Checkout unexpectedly failed to create $tgt_branch at ".getcwd(), 'warn');
                        }
                    }
                }

            } # else use default behavior (detached HEAD handling only)
        } elsif (scalar(@matches) == 1 && $matches[0] eq $tgt_branch) {
            # It exists locally and is safe to checkout
            return checkout_local($tgt_branch);
        } elsif (scalar(@matches) == 1 && $matches[0] eq "origin/".$tgt_branch) {
            # Branch exists remotely.  Does branch also exist locally at a different commit?
            return $tgt_branch if checkout_safe_remote($tgt_branch, $current_commit);
        }

    }

    # Check if caller has provided a preferred default (ie: tracking branch from parent .gitmodules)
    #  If so, we will try this alt branch, even if not in a detached HEAD state
    if ($args{hint_branch}) {
        if (grep( /^$args{hint_branch}$/, @branches)) {
            return checkout_local($args{hint_branch});
        } elsif (grep( /^origin\/$args{hint_branch}$/, @branches )) {
            return $args{hint_branch} if (checkout_safe_remote($args{hint_branch}, $current_commit));
        }
    }

    
    if ($cur_branch) {
        # We are already on some branch (matching or not), so return it
        return $cur_branch;
    } elsif (scalar(@branches) > 0) {
        # We are in a detached head, but other branches exist matching this commit

        # If local master is in list, use that [default default]
        if (grep( /^master$/, @branches )) {
            return checkout_local("master");
        } elsif (grep( /^origin\/master$/, @branches )) {
            return "master" if (checkout_safe_remote("master", $current_commit));
            # else continue searching
        }
        # Otherwise use last (non-tag) match found
        #  Note; Assume Remaining List is ordered remote branches, local branches
        my $rtv = pop(@branches);

        if ($rtv =~ /^origin\/(.+)$/) {
            # Sanity check remote branch
            $rtv = $1;
            return checkout_safe_remote($rtv, $current_commit);
        } else {
            return checkout_local($rtv);
        }

    } else {
        # Otherwise return invalid
        return undef;
    }

    }
sub checkout_safe_remote {
    my $tgt_branch = shift;
    my $current_commit = shift;
    die "Internal error; current commit not set" unless $current_commit; # TODO: Get if not defined, if we have a use-case

    # Check if $tgt_branch exists locally
    my ($err, $stdout, $stderr) = $ngt->run("git rev-parse --verify $tgt_branch");
    my $tgt_commit = chomp($stdout);
    if ($err || $tgt_commit ne $current_commit) {
        # Branch exists locally but is on a different commit.  Let's see if we can advance it before checking it out (to avoid any unnecessary conflicts).  This will be rejected if it's not a fast-forward operation
        ($err, $stdout, $stderr) = $ngt->run("git fetch origin $tgt_branch:$tgt_branch");
        if ($err) {
            # Leave logging to caller
            #say colored("Error: $tgt_branch remote is safe to checkout, but the local version requires a merge.", 'error');
            return;
        }
    }

    # Safe to checkout existing
    $ngt->run("git checkout --no-recurse-submodules $tgt_branch"); # TODO: Error handling
    return $tgt_branch;
}
sub checkout_local {
    my $branch = shift;
    my ($err, $stdout, $stderr) = $ngt->run("git checkout --no-recurse-submodules $branch");
    if ($err) {
        # TODO: Error logging?
        return undef;
    } else {
        return $branch;
    }
}

# Supports pull, merge, and rebase operations
# NOTE: rebase support is experimental and untessted and may not function if multiple conflicts in a single repo during rebase
#
# TODO: For improved handling of conflicts and merge --abort, we need to add additional status information to struct
# - For repo operation log status
#   - 'retry'    - If operation was aborted due to error without executing (ie: conflict with previously modified or untracked file)
#                   Note: This should allow safe usage when files have been previously modified prior to operation.
#                  VERIFY: If a submodule reference was modified prior to operation, existing logic should handle it correctly.
#   - 'nop'      - Operation was successful, but merge did not result in any new commits
#   - 'conflict' - Conflict detected requiring user intervention.  abort with 'merge --abort', continue with 'commit'
#   - 'success'  - Operation was successful.  If we abort merge, we must checkout HEAD~1 to undo.
sub root_operation {
    my $op = $opts->{mode};

    $opts->{states}->{totals} = { file_conflicts => 0,
                                  submodule_conflicts => 0,
                                  autoresolve_subs => 0,
                                  errors => 0, # For count of unexpected errors
                              };
    $opts->{states}->{repos} = {};
    
    # Perform operation on root, and pre-operation validation
    my $root_results = do_operation_pre();
    $opts->{states}->{repos}->{'/'} = $root_results;

        
    # Foreach submodule; run operations traversing tree in both directions
    $ngt->foreach({
        'load_tracking' => $opts->{default}, # We only need this information for --branch-first --default operations
        'breadth_first' => \&do_root_operation_breadth_first,
        'parallel'      => 0, # Parallel operations are not practical in context of (interactive) conflict handling
        'recursive'     => 1, # Recuse into submodules. Breadth-first ensures we update a given submodule before recursing into it.
        'run_root'      => 0,
        'modified_only' => ($opts->{ngtstrategy} eq "ref") ? 1 : 0, # For ref-first strategy, we don't need to check unmodified submodules here.  This check is run after breadth_first for a module, so it will pick up new changes
    });

    if ($opts->{states}->{totals}->{file_conflicts} == 0) {
        # We should have no outstanding conflicts; verify and complete
        do_operation_post();
    } else {
        # One or moree conflicts found requiring user handling

        # Print Summary
        show_conflicts_state();

        # Save config and exit with error
        exit_save_merge_state("One or more conflicts detected.");
    }

    
}

sub show_conflicts_state
{
    my $out;
    if ($conflicts_state) {
        $out = $conflicts_state;
    } else { # Use current state
        $out = $opts;
    }

    #say Dumper($out) if $opts->{verbose};

    say colored($out->{mode}." of ".$out->{branch}." in progress.", 'info');

    say "\tFile Conflicts: ".$out->{states}->{totals}->{file_conflicts} if $out->{states}->{totals}->{file_conflicts} > 0;
    say "\tSubmodule Conflicts: ".$out->{states}->{totals}->{submodule_conflicts} if $out->{states}->{totals}->{submodule_conflicts} > 0;
    say "\tAuto-staged submodule references: ".$out->{states}->{totals}->{autoresolve_subs} if $out->{states}->{totals}->{autoresolve_subs} > 0;
    say "\tErrors Encountered: ".$out->{states}->{totals}->{errors} if $out->{states}->{totals}->{errors} > 0;

    say "\nThe following require manual resolution:";
    foreach my $repo (keys %{$out->{states}->{repos}}) {
        my $def = $out->{states}->{repos}->{$repo};

        $repo = '' if $repo eq '/'; # Ensure clearer output
        
        if ($def->{file_conflicts} && scalar(@{$def->{file_conflicts}}) > 0) {
            foreach my $file (@{$def->{file_conflicts}}) {
                say "  "
                    .colored($repo, 'warn')
                    ,(($repo) ? '/' : '')
                    .colored($file, 'error');
            }
        }
        # Only show submodule conflicts if verbose is set ... TODO: Are there any cases where submodule conflicts won't be auto-resolved? Can we better track resolved vs unresolved submodule conflicts?
        if ($opts->{verbose} && $def->{submodule_conflicts} && scalar(@{$def->{submodule_conflicts}}) > 0) {
            foreach my $submodule (@{$def->{submodule_conflicts}}) {
                say "  ".colored($repo, 'warn').'/'.colored($submodule, 'error');
            }
        }

    }
}

sub do_root_operation_breadth_first {
    my $in = shift;

    my $op = $opts->{mode};
    my $branch = $opts->{branch};
    my $rtv = { repo => $in };
    delete $rtv->{repo}->{opts}; # Opts includes fn refs which we don't want to cache when saving conflict state

    my @dir_parts = File::Spec->splitdir($in->{name});
    my $shortname = pop @dir_parts; # If submodule is in a subdirectory, we just want the last directory.

    # op mode for submodule update (differs from $op for pull, or future switch and restore commands)
    my $myop = $op;
    if ($op eq "pull") { # TODO/VERIFY: This fetch may no longer be necessary
        $myop = ($opts->{'rebase'} ? "rebase" : "merge");
        
        # We must explicitly fetch the submodule being updated (VERIFY: Can we rely on parent pull to always recurse instead?)
        say colored("Fetching changes for $in->{name}", 'info');
        my ($err, $stdout, $stderr) = $ngt->run("git fetch");
        if ($err) {
            say $stdout;
            say $stderr;
            say colored("WARNING: Failed to fetch $in->{name} (see above for details). This may cause additional errors", "warn");
        }
    }
    say colored("Executing $op for $in->{name}", 'info'); # TODO: Less verbose method of outputting progress

    if ($in->{status} eq '-') {
        # This submodule is uninitialized.
        chdir("..") or die "Failed to cd to parent: $!";
        my ($err, $stdout, $stderr) = $ngt->run("git submodule update --init --$myop $shortname");
        if ($err) {
            $opts->{states}->{totals}->{'errors'}++;
            die "TODO: Error handling";
        } else {
            chdir($shortname) or die "Failed to cd $shortname: $!";
            checkout_safe(branch => $branch,
                          autocreate => (defined($opts->{'auto-create'}) ? $opts->{'auto-create'} : 1)
                          );
        }
        $rtv->{'is_new'} = 1; # TODO: Or state='new' (vs 'deleted' or 'updated'?)
        
    } elsif ($opts->{'ngtstrategy'} eq 'branch' ) {
        # Perform actual operation (same logic as for root repo)
        $rtv = do_operation_pre($in);

    } else {
        # Start in parent folder
        chdir("..") or die "Failed to cd to parent: $!";

        # Let git update single submodule with merge or rebase strategy as appropriate
        # Force no-edit by using nop shell command (valid for UNIX+Windows) since submodule update doesn't support flag
        $ENV{'GIT_EDITOR'} = ":";
        # Alternative is to specify custom script
        my ($err, $stdout, $stderr) = $ngt->run("git submodule update --$myop $shortname");
        
        if ($err) {
            # Git should always return non-zero error code on conflicts, or other errors
            if ($stdout =~ /Automatic merge failed/) { # TODO: phrasing for rebase
                # Conflict found, now handle all conflicts listed
                chdir($shortname) or die "Failed to cd $shortname: $!";
                $rtv = handle_submodule_conflicts($stdout, $in);
            } else {
                # Non-conflict error. This may include server hangup or unpushed commits and requires user intervention
                $opts->{states}->{totals}->{'errors'}++;
                say colored("Unhandled error during $op of ".$in->{name}, 'error');
                say $stdout if $stdout;
                say $stderr if $stderr;
            }
        }
        # else update completed without errors/conflicts
    }

    $opts->{states}->{repos}->{$in->{subname}} = $rtv;

}


sub exit_save_merge_state
{
    my $obj = $opts; # Save configuration object, which includes states variable defining conflict state
    my $err = shift;
    my $details = shift;
    if ($err) {
        $obj->{'err'} = $err;
        say colored($err,'error');
    }
    if ($details) {
        $obj->{'details'} = $details;
        say $details
    }

    $ngt->save_config($obj, "merge_conflict");

    # And exit; we 'die' since we want to exit with an error state
    say(colored("Currently in ".getcwd(), 'warn')) if $opts->{verbose};

    # TODO: Do we need to tweak this message for rebase?
    say(colored($opts->{mode}." failed. See above for details. Please resolve and continue with 'ngt $opts->{mode} --continue' or abort with 'ngt $opts->{mode} --abort' to cancel.", 'error'));
    exit(1);
}

sub abort_merge_state
{
    if ($conflicts_state) {
        # NOTE: This makes no guarantees that repo is in a usable state
        $ngt->clear_config("merge_conflict");
        $ngt->run('git merge --abort');
        say "WARNING/TODO: Abort not fully implemented. This command clears ngt status, but user may need to manually abort submodule conflicts in progress, or already completed";
        say "Aborted merge in progress. No guarantees are made as to the current state of the repository.  Reversion of changes, including any git merges in progress are TODO";


        # TOOD: Abort
        # - Cache SHAs of all submodules (and root) parsed prior to merge
        #   - Note SHA from foreach is of reference object, not the useful commit
        # - If current SHA does not match originaly, and not in a conflict state, 'git reset HEAD~1'
        # - If currently in a conflict state, then 'git merge --abort'
        # - Otherwise, nothing to be done
        
        exit(0);
    } else {
        die "ERROR: No Merge in progress to abort\n";
    }
}

# Execute pull/merge/rebase operation in current directory (pre-recursion step) and return results
# Note: This function performs the actual operation (ie: merge/pull/rebase) and parses results, but does not handle submodules
# Note: This functiion only operates with the 'branch-first' strategy, which is also used for root level for ref-first mode.
sub do_operation_pre {
    my $in = shift; # For logging when called for submodules
    my $op = $opts->{mode};
    my $branch = $opts->{branch}; # SHAs and Tags also supported for merge/rebase
    my $cmd;
    my $rtv = {'file_conflicts' => [], 'submodule_conflicts' => [], 'dir' => getcwd() };

    # Handle --default case
    if ($opts->{default} && !$branch) {
        if ($in->{tracking_branch}) {
            $branch = $in->{tracking_branch};
        } else { # No tracking branch, revert to server default branch
            my ($err, $stdout, $stderr) = $ngt->run('git symbolic-ref refs/remotes/origin/HEAD');
            ($branch) = $stdout =~ qr{^refs/remotes/origin/(.+)$ }x;
        }
    }

    # Validate Parameters
    if ($op ne "pull" && !$branch) {
        # Reference; Pull may optionally specify a remote, repo, or refspec. Support for these arguments in Ngt may not be fully supported (TODO).
        die "$op requires a branch, tag, or commit.\n";
    } elsif ($op eq "checkout") {
        die "Internal Error: checkout handling routed to wrong function\n";
    }

    # Build Command
    if ($op eq "merge") {
        $cmd = "git merge $branch";

        # Set message (does not apply to pull or rebase)
        if ($opts->{'message'}) {
            $cmd .= " -m \"$opts->{'message'}\"";
        } elsif (defined($opts->{edit}) && !$opts->{edit}) {
            $cmd .= " --no-edit";
        } else {
            $cmd .= " -m \"Nuggit Merged $branch into ".get_selected_branch_here()."\"";
        }

    } elsif ($op eq "pull") {        
        $cmd = "git pull --no-recurse-submodules";

        $opts->{remote} = "origin" if $opts->{default} && !$opts->{remote};
        if ($opts->{remote}) {
            $cmd .= " $opts->{remote}";
            $cmd .= " $branch" if $branch; # pull can only specify branch if remote is also specified
        }
        if (!$opts->{edit}) {
            $cmd .= " --no-edit";
        }
        $cmd .= " --rebase" if $opts->{rebase};
        
        # Workaround for lack of no-edit flag for pull
        $ENV{'GIT_EDITOR'} = ":";

    } elsif ($op eq "rebase") {
        $cmd = "git rebase $branch";
        # TODO: Support for interactive flag? May require alt submodule handling
    } else {
        die "Internal Error: $op is not supported for this function.";
    }

    $cmd .= " --squash" if $opts->{squash}; # May not be valid for rebase. Must be followed with ngt commit for pull


    my ($err, $stdout, $stderr) = $ngt->run($cmd);

    if ($stdout =~ /Automatic merge failed/) {
        $rtv = handle_submodule_conflicts($stdout, $in);
    } elsif ($err) {
        if ($in) {
            exit_save_merge_state("Unhandled error detected in $in->{name}", $stdout.$stderr);
        } else {
            # If this is an unexpected error at root, we abort, but do not save state as a conflict in porgress (we likely didn't get that far)
            say colored("Unable to perform $op due to error in the root repository", 'error');
            say $stdout if $stdout;
            say $stderr if $stderr;
            die colored("Please resolve the above error(s) and try again", 'warn')."\n";
        }
    }

    return $rtv;

}

sub handle_submodule_conflict {
    my $conflicted = shift;
    my $cmd;
    
    if ($opts->{'ngtstrategy'} eq 'branch' ) {
        $cmd = "git add $conflicted";
    } else {
        # Resolve conflict in a manner that we can subsequently run submodule update --$op on
        $cmd = "git checkout --no-recurse-submodules MERGE_HEAD $conflicted";
    }
    
    my ($err, $stdout, $stderr) = $ngt->run("$cmd");
    if ($err) {
        say colored("Failed to automatically resolve conflict for submodule reference $conflicted");
        $opts->{states}->{totals}->{'errors'}++;
    } else {
        $opts->{states}->{totals}->{'autoresolve_subs'}++;
    }
    
}

# TODO: Consider renaming to just "handle_conflicts"
sub handle_submodule_conflicts {
    my $stdout = shift;
    my $repo = shift; # submodule foreach arguments providing repo details
    my $rtv = {'file_conflicts' => [], 'submodule_conflicts' => [], 'dir' => getcwd(), 'repo' => $repo };

    # Split stdout into lines
    my @lines = split("\n",$stdout);

    # Parse Output
    foreach my $line (@lines) {
        # Is this a conflict?
        my ($conflict_type, $conflicted) = $line =~ m{CONFLICT \(([\w\\/]+)\)\: Merge conflict in (.+)$};

        if ($conflict_type) {
            # Is this a submodule conflict?
            if ($conflict_type eq "submodule") {
                # Sanity check & Record conflict, but leave handling for caller
                
                # Verify we havce identified an actual submodule (or at least a valid directory)
                if (!-d $conflicted) {
                    # If it's not a 0directory, this is likely a conflict in a newly added submodule. Handling TODO
                    die "Internal Error: submodule $conflicted is not a directory. This may a bug or unhandled condition.\n Currently in ".getcwd();
                }
                
                # Log it
                push( @{$rtv->{'submodule_conflicts'}}, $conflicted );
                
                # Automatic Handling
                handle_submodule_conflict($conflicted);
            } elsif ($conflict_type eq "content") {
                say $line; # VERIFY: Do we want to output here, or just log for summary output at end?
                push(@{$rtv->{'file_conflicts'}}, $conflicted);
            } elsif ($conflict_type) {
                # There may be other types that we need to handle (or explicitly ignore), such as file mode
                warn "Conflict detected of unhandled type $conflict_type";
            }
        }
    }
    
    # Note: conflict resolution left for calling function
    $opts->{states}->{totals}->{file_conflicts} += scalar(@{$rtv->{file_conflicts}});
    $opts->{states}->{totals}->{submodule_conflicts} += scalar(@{$rtv->{submodule_conflicts}});
    
    return $rtv;
}

# This function is called post merge/pull/rebase operations, or on '--continue'
sub do_operation_post {
    $ngt->foreach({
        'depth_first' => sub {
            # Get status -uno for current repo only
            my $status = get_status({uno => 1, no_recurse => 1});
            my $staged_cnt = 0;

            # If any files are modified/unstaged, abort
            if ($status->{'unstaged_files_cnt'} > 0) {
                exit_save_merge_state("Unable to complete merge.", "You have $status->{'unstaged_files_cnt'} unresolved/unstaged files remaining under ".getcwd() );
            }

            # If any submodules are modified, auto-stage
            foreach my $file (keys %{$status->{'objects'}}) {
                my $obj = $status->{objects}{$file};
                if ($obj->{'status_flag'} eq ' ') {
                    # No action needed, file should already be staged
                } elsif (-d $file) {
                    exit_save_merge_state("Internal error: $file is a modified directory but not a submodule") unless $obj->{'is_submodule'};
                    if ($obj->{'sub_commit_delta'}) {
                        # This is a directory, auto-stage it; this should be a submodule that's already been merged
                        my ($err, $stdout, $stderr) = $ngt->run("git add $file");
                        if ($err) {
                            say $stdout if $stdout;
                            say $stderr if $stderr;
                            exit_save_merge_state("Error staging $file", $stdout);
                        } else {
                            say "Automatically staging $file";
                            $opts->{states}->{totals}->{'autostage_subs'}++;
                            $staged_cnt++;
                            # TODO: Log in opts->{states}->{repos} for summmary output
                        }
                    } else {
                        say colored("Submodule $file has modified or untracked files", 'warn');
                    }
                } else {
                    # This case indicates a bug in the merge algorithm or status check
                    exit_save_merge_state("Error completing merge. Expected $file to be a submodule but it is not a directory. Did submodule initialization fail?");
                }
            }

            # If there are staged changes, commit them (if there isn't, then we shouldn't have reached this point)
            if ($staged_cnt > 0 || $status->{'staged_files_cnt'} > 0) {
                my $cmd = "git commit";
                if ($opts->{'message'}) {
                    $cmd .= " -m \"".$opts->{'message'}."\"";
                } elsif (!$opts->{'edit'}) {
                    if (!-e ".git/MERGE_HEAD") {
                        # If no merge is in progress at this level (ie: we are only updating submodules), we must specify message
                        my $branch = $opts->{branch} // "";
                        my $mybranch = get_selected_branch_here();
                        $cmd .= " -m \"N: Merge $branch into $mybranch\"";
                    } else { # Use Git's auto-generated merge message
                        $cmd .= " --no-edit";
                    }
                }
                my ($err, $stdout, $stderr) = $ngt->run($cmd);
                if ($err && ($stdout !~ /nothing to commit/i) ) {
                    # VERIFY: Will this fail if there are no changes to commit? If so, we may need additional checks above.
                    my $errmsg = "";
                    $errmsg .= $stdout if $stdout;
                    $errmsg .= "\n".$stderr if $stderr;
                    exit_save_merge_state("Failed to commit conflict resolution at ".getcwd(), $errmsg);
                }
            }
            
        },
        'run_root' => 1,
        'modified_only' => 0 # Note: If this flag is set, it may not recurse in certain cases of modifications in nested submodules, particularly in the context of --branch-first flag.
       });

    # Clear merge state
    $ngt->clear_config("merge_conflict");
    
    # And print success
    say colored("$opts->{mode} completed successsfully.", 'success');
}

