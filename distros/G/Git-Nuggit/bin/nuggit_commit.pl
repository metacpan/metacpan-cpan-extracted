#!/usr/bin/env perl

#*******************************************************************************
##                           COPYRIGHT NOTICE
##      (c) 2019 The Johns Hopkins University Applied Physics Laboratory
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

# TODO: Support for amend? May be better to skip this one (advanced users can use git directly).
# TODO: Option to prompt user before commit if unstaged changes exist?
# TODO: If a submodule is not on the root branch, attempt a safe checkout (unless configured otherwise)
use strict;
use warnings;
use v5.10;
use Pod::Usage;
use Getopt::Long;
use Cwd qw(getcwd);
use Term::ANSIColor;
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;
use Git::Nuggit::Status;
use Git::Nuggit::Log;
use IPC::Run3; # Utility to execute application and capture both stdout and stderr

# usage: 
#
# nuggit_commit.pl -m "commit message"
#

sub ParseArgs();
sub recursive_commit( $ );
sub staged_changes_exist_here();
sub nuggit_commit($);

my $verbose;

my $commit_message_string;
my $need_to_commit_at_root = 0;
my $branch_check = 1; # Check that all modified submodules are on the correct branch
my $root_repo_branch = "(Branch Unknown)";
my $commit_all_files = 0; # Results in "git commit -a"
my $use_force = 0;
my $auto_push = 0; # If set, automatically push any updated submodules

# Initialize Nuggit & Logger prior to altering @ARGV
my $ngt = Git::Nuggit->new("run_die_on_error" => 0, "echo_always" => 0); 
my $root_dir = $ngt->root_dir();

ParseArgs();

die("Not a nuggit!\n") unless $ngt;
$ngt->start(level => 1, verbose => $verbose);

chdir $root_dir || die("Can't enter root dir\n");

check_merge_conflict_state(); # Do not proceed if merge in process; require user to commit via ngt merge --continue

my $status = get_status({uno => 1}); # Get status, ignoring untracked files

die "No changes to commit.\n" if status_check($status);


if (!$use_force && $status->{'detached_heads_flag'}) {
    pretty_print_status($status, $ngt->{relative_path_to_root}, {user_dir => $ngt->{user_dir}});
    say colored("\nERROR: A detached HEAD state exists in one or more places.", 'error');
    die colored("Please resolve (ie: 'ngt checkout --safe'), or (not recommended) re-run with '--force' to bypass this check.", 'info')."\n";
}

if ($branch_check && !$use_force) {
    if ($status->{'branch_status_flag'}) {
        pretty_print_status($status, $ngt->{relative_path_to_root}, {'user_dir' => $ngt->{user_dir}});
        die "One or more submodules are not on branch $root_repo_branch.  Please resolve, or (with caution) rerun with --no-branch-check to ignore.\n";
    }
}

if ($status->{'branch.head'}) {
    $root_repo_branch = $status->{'branch.head'};
}

my $total_commits = 0; # Number of commits made (root+submodules)
my $autostaged_refs = 0; # Number of submodule references automagically staged
my $prestaged_objs = 0; # Number of objects user has previously staged
my $untracked_objs = 0; # Reference count of untracked files not committed
my $unstaged_objs = 0; # Reference count of modified objects not staged/committed.
my $push_errors = 0;
my $repos_pushed = 0;
recursive_commit($status);

say colored("Commit complete", 'info');
say "$autostaged_refs submodule references automatically committed." if $autostaged_refs > 0;
say "$untracked_objs untracked files exist in your work tree." if $untracked_objs > 0;
say "Successfully pushed $repos_pushed repositories/submodules" if $repos_pushed > 0;
say colored("Warning: Failed to push one or more submodules. See above for details", 'error') if $push_errors > 0;

if (!$commit_all_files) {
    say "$prestaged_objs previously staged changes committed" if $prestaged_objs > 0;
    say "$unstaged_objs unstaged changes remaining in your work tree." if $unstaged_objs > 0;
}




sub recursive_commit( $ )
{
    my $status = shift;
    my $need_to_commit_here = 0;
    my $dir = getcwd();

    foreach my $child (keys %{$status->{objects}}) {
        my $sub = $status->{objects}->{$child};
        
        if ($sub->{is_submodule}) {
            chdir($sub->{path}) || die "Error: Unable to enter submodule $child";
            if (recursive_commit($sub)) {
                chdir($dir);
                # A commit was triggered in this submodule, so it will be auto-staged
                my ($err, $stdout, $errmsg) = $ngt->run("git add $child");
                die "Error ($?): Unable to autostage $child in $dir:\n\n $stdout \n $errmsg\n" if $err;
                
                $need_to_commit_here = 1;
                $autostaged_refs++;
            } else {
                # else user must stage manually, for example if a commit was made outside of nuggit
                chdir($dir); # pop dir for next iteration
            }

            # Handle manually staged submodule references
            if ($sub->{staged_status} > STATE('UNTRACKED')) {
                $need_to_commit_here = 1;
            }
        } elsif ($sub->{staged_status} > STATE('UNTRACKED')) {
            $need_to_commit_here = 1;
            $prestaged_objs++;
        } elsif ($sub->{status} == STATE('UNTRACKED')) {
            $untracked_objs++;
        } elsif ($sub->{status} > STATE('UNTRACKED')) {
            $unstaged_objs++;
            $need_to_commit_here = 1 if $commit_all_files;
        }
    }
    # If commit is required, make it
    if ($need_to_commit_here) {
        nuggit_commit($status->{path});
        $total_commits++;
        return 1;
    } else {
        return 0;
    }
}


sub ParseArgs()
{
    my ($help, $man);
    Getopt::Long::Configure("bundling"); # ie: enables -am
    Getopt::Long::GetOptions(
                           "message|m=s"  => \$commit_message_string,
                           "all|a!"           => \$commit_all_files,
                           "verbose!" => \$verbose,
                           "branch-check!" => \$branch_check,
                           "help"            => \$help,
                           "man"             => \$man,
                           "force!"          => \$use_force,
                           "push|P!"         => \$auto_push,
                          );
    pod2usage(1) if $help;
    pod2usage(-exitval => 0, -verbose => 2) if $man;

    if (!defined($commit_message_string) ) {
        my $editor = `git config --get core.editor`;
        chomp($editor);
        if (!$editor) {
            if ($ENV{GIT_EDITOR}) {
                $editor = $ENV{GIT_EDITOR};
            } elsif ($ENV{VISUAL}) {
                $editor = $ENV{VISUAL};
            } elsif ($ENV{EDITOR}) {
                $editor = $ENV{EDITOR};
            } else {
                $editor = 'vi'; # Because sadly vi is more commonly available than emacs
            }
        }
        my $file = "$root_dir/.nuggit/TMP_COMMIT_MSG";
        my $cmd = "$editor $file";
        system($cmd);

        die("Commit message is required") unless -e $file;

        open(my $fh, "<", $file) or die "Commit message is required";
        read $fh, $commit_message_string, -s $fh;
        close($fh);
        unlink($file); # And delete temporary file
    }

    my $size = length $commit_message_string;
    my $min_len = 4; # TODO: Make this configurable?
    if ($size < $min_len) {
        die("A useful commit message of at least $min_len characters is required: You specified \"$commit_message_string\"");
    }
}


sub nuggit_commit($)
{
   my $commit_status;
   my $repo = $_[0];
   
   my $args = "";
   $args .= "-a " if $commit_all_files;
   my ($err, $stdout, $errmsg) = $ngt->run("git commit $args -m \"N:$root_repo_branch; $commit_message_string\"");

   say colored("Commit in repo $repo:", 'success');
   say $stdout if $stdout;
   say $errmsg if $errmsg;
   
   if ($err) {
       die("Error detected ($err), aborting nuggit commit\n");
   }

   if ($auto_push) {
       my $branch = get_selected_branch_here();
       if ($branch =~ /HEAD detached/) {
           say colored("Error: $repo is in a DETACHED HEAD, will not attempt to push. Manual resolution is recommended by creating a new branch.  If you did not run this command with the '--force' flag to bypass safety checks, please report this as a probable Nuggit bug.", 'error').'\n';
           return;
       }

       my $cmd = "git push --recurse-submodules=on-demand -u origin $branch";
       
       ($err, $stdout, $errmsg) = $ngt->run($cmd);
       say colored("Automatically pushing $repo", ($err) ? 'error':'info' );
       say $stdout if $stdout;
       say $errmsg if $errmsg;
       if ($err) {
           $push_errors++;
           say colored("Warning: Failed to push changes in $repo. Please correct any issues and run 'ngt push' to retry. No additional repos will be pushed to avoid dangling references.",'error');
           $auto_push = 0;
       } else {
           $repos_pushed++;
       }
   }
}


=head1 Nuggit commit

Commit files to the repository, using nuggit to automatically handle submodule boundaries and references.

=head1 SYNOPSIS

=over

=item --help

Display an abbreviated help menu

=item --man

Display detailed documentation.

=item --message|m

Commit message.  Nuggit will automatically prepend the branch name.

=item --all|a

If set, commit all modified files.  

=item --no-branch-check

Bypass verification that all submodules are on the same branch.

=item --force

If specified, bypass all sanity checks, including detached HEAD and matching branch anmes

=item --push|P

If specified, automatically push changes to origin for any updated submodule.

=back

=cut

