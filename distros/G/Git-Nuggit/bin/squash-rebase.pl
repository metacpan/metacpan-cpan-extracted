#!/usr/bin/env perl
#
#
#  This is the squash-rebase version (not the plain squash version)
#  This version will squash all the commits on your branch into one commit but will place that commit onto
#    a new branch off of the HEAD of the specified base branch.  This is effectively a rebase of your (squashed) commits
#    onto the base branch. 
#
#  The way this works:
#     (1) Create a branch at the base branch.  This will have a temporary branch name at first but will be 
#           ultimately renamed with your original branch name
#     (2) Do a merge with a squash from your feature branch into the temporary branch off the base branch.
#         - the result of this is that a temporary branch exists with a single commit relative to the base branch
#         - this step may result in conflicts that need to be resolved.
#     (4) Rename the branches so that the temporary branch replaces your feature branch and the original feature branch is deleted.
#
#  SIDE EFFECT... this will replace your branch with an equivalent branch with the same final content (but rebased ontop of the 
#      specified base branch) but with a single commit.
#      So... you will need to do a force push to the server
#
#  This script / process would typically be done in preparation of a merge (or a Pull Request).
#  
#  This script does not do any rebasing.  This script effectively does a rebase without using the git command to rebase.  
#  There is a similar process / script that will squash your commits to a single commit but apply the new command relative 
#  to the merge base, rather than the HEAD of the base branch
#
#
# TO DO - add ability to take in arguments for
#    Add option for -m "<commit messaage to use in squash commit>"
#
#
#
# perl squash-rebase.pl -help
# perl squash-rebase.pl -b=master
# perl squash-rebase.pl -b master
# perl squash-rebase.pl -b master -m "Commit Message"         <---- if no user supplied commit, we use the aggregate squashed commit messages
# perl squash-rebase.pl -b master --verbose
# perl squash-rebase.pl -b master -v
# perl squash-rebase.pl -relative-branch=master
# perl squash-rebase.pl -relative-branch master
#

use strict;
use warnings;
use v5.10;
use Getopt::Long;
use Cwd qw(getcwd);
use Term::ANSIColor;

sub main();
sub ParseArgs();
sub PrintHelp();
sub get_selected_branch_here();


my $base_branch_arg;
my $user_commit_msg_arg;   # If the user supplied a commit message, with -m, this will be the commit message for the squash.
                           # if no commit message was supplied, then we will get the concatenation of all of the commit messages.
my $base_commit_arg;
my $retain_original_arg;

my $merge_conflict_detected = 0;
my $base_branch;
my $feature_branch          ;
my $squashed_branch_tmp_name;
my $original_branch_deleteme;         # TO DO - consider using a time-stamp in the original deleteme branch
                                      #       this may be useful for the packrats, but will cause the 
                                      #       accumulation of clutter

my $delete_original_branch_after_squash = 1;
my $concatenate_commit_messages         = 1;   # not implemented
my $halt_if_temp_branches_already_exist = 0;   # not implemented

my $ahead;
my $behind;

my $date;
my $tmp;
my $merge_base;
my $commit_msg;


my $help = 0;
my $verbose = 0;


main();







sub main()
{

  # Argument handling

  ParseArgs();

  if($help == 1)
  {
    PrintHelp();
    exit(0);
  }

  if(defined($base_branch_arg))
  {
    $base_branch = $base_branch_arg;  
  }

  #
  # Relative branch arg is required  
  #
  if(!defined($base_branch_arg))
  {
    say "no base branch OR merge base commit specified";
    PrintHelp();
    exit(0);
  }

  if (defined($retain_original_arg))
  {
    $delete_original_branch_after_squash = 0;
  }
  else
  {
    $delete_original_branch_after_squash = 1;
  }



  #
  #  Make sure that the relative base branch is NOT the currently checked out branch
  #
  if($verbose==1)
  {
    print "VERBOSE: Make sure the relative (base) branch (as supplied by argument b) is not the checked out branch\n";
  }

  my $active_branch = get_selected_branch_here();
  if(!defined($active_branch))
  {
    say colored("Repo branch detection error", 'bold red');
    say "\t Current branch unknown.";
    exit(1);
  }
  elsif ($active_branch eq $base_branch)
  {
    say colored("Repo is on base branch.  Cannot squash the base branch.  Need to squash relative to some OTHER branch.", 'bold red');
    say "\t Currently on branch $active_branch, and you asked to squash this branch (not relative to some other branch)";
    say "Note: It is not typical to be on the master branch and reference some feature branch with this command.";
    say "      Instead, you should probably be on your feature branch and reference your master branch with this command";
    say "See help menu using --help";
    exit(1);
  }
  elsif ($active_branch ne $base_branch) 
  {
    if($verbose==1)
    {
       say colored("Repo is not on base branch... good", 'bold green');
       say "\t Currently on branch: $active_branch. Attempting to squash-rebase $active_branch relative to $base_branch";
    }
  }

  # =======================================================================================================
  # Check that there is more than one commit on the feature branch relative to the merge base.
  # if there are 0 or 1 commits on the feature branch relative to the merge base THEN do not do the squash.
  # =======================================================================================================
  if($verbose==1)
  {
     print "VERBOSE: Check that there is more than one commit on the feature branch.\n";
     print "VERBOSE:     - do not squash if there is only one commit (or 0) to start with.\n";
  }

  $tmp = `git rev-list --left-right --count $base_branch...$active_branch`;
  chomp($tmp);
  
  #parse $tmp for behind and ahead here
  
  $tmp =~ /([0-9]*)\s+([0-9]*)/;
  $behind = int($1);
  $ahead  = int($2);
  
  if($ahead == 0)
  {
    print "Your branch has no additional commits on it.  Ahead = $ahead\n";
    print "Nothing to squash. But we may still need to rebase\n";
    
    if($behind == 0)
    {
      print "ahead = 0 and behind = 0, nothing to do in this repo. exiting\n";
      exit(0);
    }
    
    #
    # If we are behind, then we will fast forward and exit
    #
     print "Check if we are behind... if so, then we fast forward merge and exit\n";
    if($behind != 0)
    {
       print "We are behind and need to (can) do a fast forward merge.  This should always succeed\n";
       $tmp = `git merge --ff-only $base_branch`;
       
       print "Performed fast forward merge, exiting\n";
       exit(0);
    }

  }
  
  # if we get here, we cold not do a fast forward merge... so all we know is .... ahead not equal to 0
  
  if($behind == 0)
  {
    print "the base branch has no additional commits that your branch does not already have.  Behind = $behind\n";
    print "we dont need to rebase... may still need to squash\n";
    
    if($ahead <= 1)
    {
      print "Zero or one commits on feature branch, no need to squash.  Nothing else to do.  exiting\n";
      exit(0);
    }
    
    #
    # behind is zero and ahead is > 1
    # my branch is strictly ahead by more than one commit.  I want to squash.... continue on to let the squash happen.
    # nothing else to do inside this if-block
    #
  }

  if($verbose ==1)
  {
     print "VERBOSE: If we get here, we know we may have something to squash (ahead = $ahead)\n";
     print "VERBOSE:   and we may have commits we need to rebase (behind = $behind)\n";
  }

  $feature_branch = $active_branch;
  $squashed_branch_tmp_name = "$feature_branch-tmp-squashed";
  $original_branch_deleteme = "$feature_branch-deleteme";

  if($verbose == 1)
  {
    say "VERBOSE: Squashing $active_branch relative $base_branch and placing ontop of HEAD of $base_branch";
    say "VERBOSE: Delete original: $delete_original_branch_after_squash";
  }

  #
  #
  # Do the squash with rebase operation
  #
  #

  if($verbose==1)
  {
    print "VERBOSE: Need to create a temporary branch off the HEAD of the base branch ($base_branch)\n";
    print "VERBOSE: Make sure that the temporary branch name $squashed_branch_tmp_name is not in use\n";
  }

  $tmp = `git show-ref refs/heads/$squashed_branch_tmp_name`;
  chomp($tmp);
  if($tmp ne "")
  { 
    if($verbose==1)
    {
      print "VERBOSE: The temporary branch name was found, need to delete it\n";
    }
    # the temporary branch already exists, need to delete it before we continue
    $tmp = `git branch -D $squashed_branch_tmp_name`;
  }
  else
  {
    if($verbose==1)
    {
      print "VERBOSE: Did not find temporary branch $squashed_branch_tmp_name\n";
    }
  }

  if($verbose==1)
  {
    print "VERBOSE: Make sure the relative branch exists\n";
  }

#  $tmp = `git show-ref refs/heads/$base_branch`;
  $tmp = `git show-ref $base_branch`;                # this will show BOTH the local and remote branch... may need to refine this
  if($tmp ne "")
  {
    if($verbose==1)
    {
      print "VERBOSE: relative branch ($base_branch) exists.\n";
    }
  }
  else
  {
    say colored("ERROR: $base_branch does not exist in this repo.", 'bold red');
    say colored("       Cannot squash-rebase onto a non-existent branch", 'bold red');
    exit(1);
  }
  

  if($verbose==1)
  {
    print "VERBOSE: Create temporary squashed branch ($squashed_branch_tmp_name) at $base_branch\n";
  }
  # create a branch off of merge base.  We will squash all the commits since this commit on 
  # our feature branch and then commit this one squashed commit onto the merge-base branch 
  $tmp = `git branch $squashed_branch_tmp_name $base_branch`; 


  if($verbose==1)
  {
    print "VERBOSE: Checkout the temporary squashed branch ($squashed_branch_tmp_name) at $base_branch\n";
  }
  #nuggit_squash
  # -q indicates to suppress the output message
  $tmp = `git checkout -q $squashed_branch_tmp_name`;
  #print $tmp;

  if($verbose==1)
  {
    print "VERBOSE: prepare a melded commit message from the commits that are on the feature branch and NOT the base branch\n";
  }
  if(!defined($user_commit_msg_arg))
  {
    # Get the commit log for all the (non-merge) commits that are on the feature branch and are NOT on the base branch
    $commit_msg = `git log --no-merges $feature_branch ^$base_branch`;
  }

  if($verbose==1)
  {
    print "VERBOSE: merge $feature_branch (onto $squashed_branch_tmp_name) with squash option\n";
  }
  $tmp =  `git merge $feature_branch --squash`;
  #print $tmp;


  #
  # Need to check for conflicts here.  The subsquent commit attempt with fail if there are any conflcts
  #
  if($verbose==1)
  {
    print "VERBOSE: Checking for conflicts in the previous merge operation\n";
  }

  $tmp = `git diff --name-only --diff-filter=U`;
  chomp($tmp);
  if($tmp ne "")
  {
    say colored("Conflict detected in merge operation.", 'bold red');
    say colored("   Performed a merge with squash option of your branch $feature_branch onto a temporary branch $squashed_branch_tmp_name", 'bold red');
    say colored("   This is similar to a rebase operation onto a temporary branch", 'bold red');
    say colored("   You must resolve the conflicts", 'bold red');
    say colored("   TO DO - need to figure out how to resolve the temporary branches", 'bold red');
    say colored("   TO DO -    maybe I need to rename the temporary branch to be the feature branch??? (but first move the original feature branch?", 'bold red');
    $merge_conflict_detected = 1;

    $delete_original_branch_after_squash = 0;    # Maybe force this to 0 if there is a merge conflict???
  }

  if($merge_conflict_detected == 0)
  {
#    $date = `date +%Y-%m-%d:%H:%M:%S:%N`;
#    chomp($date);
    if($verbose==1)
    {
      print "VERBOSE: Commit the squash merge of $feature_branch --> $squashed_branch_tmp_name\n";
    }
    $tmp =  `git commit -m "N:Squash - ($feature_branch) -> ($squashed_branch_tmp_name): \n$commit_msg"`;
    #print $tmp;
  }
  else
  {
    say colored("   Skipping the commit operation because of merge conflict", 'bold red');
  }

  if($verbose==1)
  {
    print "VERBOSE: Rename the branches so the squashed branch has the original name... multiple steps to follow:\n";
  }

  # we want to save the original branch into a temporary branch name, rename the squashed branch to
  # use the original branch name.  then consider deleting the original branch.  

  if($verbose==1)
  {
    print "VERBOSE: Make sure there is no branch named: $original_branch_deleteme\n";
  }


  # First, need to make sure we dont have a temporary branch hanging out with our temporary name

  $tmp = `git show-ref refs/heads/$original_branch_deleteme`;
  chomp($tmp);
  if($tmp ne "")
  { 
    if($verbose==1)
    {
      print "VERBOSE: The temporary branch name was found, need to delete it\n";
    }
    # the temporary branch already exists, need to delete it before we continue
    $tmp = `git branch -D $original_branch_deleteme`;
  }
  else
  {
    if($verbose==1)
    {
      print "VERBOSE: Did not find temporary branch $original_branch_deleteme\n";
    }
  }

  if($verbose==1)
  {
    print "VERBOSE: Renaming original branch to: $original_branch_deleteme\n";
  }
  # rename the original dev branch to a temp name
  $tmp = `git branch -m $feature_branch $original_branch_deleteme`;

  if($verbose==1)
  {
    print "VERBOSE: Renaming squashed branch ($squashed_branch_tmp_name) to have original branch name: $feature_branch\n";
  }
  # rename the squashed branch to have the original feature branch dev name
  $tmp = `git branch -m $squashed_branch_tmp_name $feature_branch`;


  if ($delete_original_branch_after_squash == 1)
  {
    if($verbose==1)
    {
      print "VERBOSE: Deleting original branch (now called $original_branch_deleteme)\n";
    }
    $tmp = `git branch -D $original_branch_deleteme`;
  }

  if($merge_conflict_detected == 1)
  {
    say colored("A conflict was detected, you will need to:", 'bold red');
    say colored(" (1) resolve this confict ", 'bold red');
    say colored(" (2) git branch -u origin/$feature_branch", 'bold red');
    say colored(" (3) git push --force-with-lease", 'bold red');
    say colored(" (4) if this is a submodule you add, commit push at the parent", 'bold red');
  }
  else
  {
    say colored("------", 'green');
    say colored("You will need to force push this to your remote server.", 'green');
    say colored("The final contents of your branch have not changed however", 'green');
    say colored("The commit history is completely different", 'green');
    say colored("", 'green');
    say colored("    git branch -u origin/$feature_branch", 'green');
    say colored("    git push --force-with-lease       ", 'green');
    say colored("------", 'green');
  }
  
} # end of main program





#
#
# Functions
#
#

sub ParseArgs()
{
    Getopt::Long::GetOptions(
                           "message|m=s"            => \$user_commit_msg_arg,
                           "verbose|v"              => \$verbose,
			   "help"                   => \$help,
			   "relative-branch|b=s"    => \$base_branch_arg,
			   "retain-original"        => \$retain_original_arg
			   
                          );


#    my $size = length $user_commit_msg_arg;
#    my $min_len = 4; # TODO: Make this configurable?
#    if ($size < $min_len) {
#        die("A useful commit message of at least $min_len characters is required: You specified \"$user_commit_msg_arg\"");
#    }
    
    # check for unparsed arguments
    if (@ARGV > 0) 
    {
      $help = 1;
    }

}

sub PrintHelp()
{
  print "Nuggit Squash-rebase\n\n";
  
  print "  This command will squash the commits on the current feature branch into a single commit\n";
  print "  relative to the merge base but on-top of the base branch.  \n";
  print "  This operation is intended to be performed in preparation\n";
  print "  of merging the feature branch into master.  This operation allows the final state of your\n";
  print "  feature branch to exist in a branch with a single end-state commit applied on top of the HEAD\n";
  print "  of the base branch and without all of the intermediate commits.\n\n";
  
  print "  This operation will replace your feature branch with an equivalent squashed feature branch\n";
  print "  with the same name but applied to the HEAD of the base branch.  An implication of this is\n";
  print "  that you will have to do a force push to the server.\n\n";
    
  print "  Usage:\n";
  print "     nuggit squash-rebase --help\n";  
  print "                          --relative-branch <base-branch-name>\n";
  print "                           -b <base-branch-name>\n";
  print "                           -m \"<commit message>\n";
  print "                          --retain-original\n";
  print "                          --verbose -v\n";
  print " \n";
  print "Options\n\n";

  print "      --help\n";
  print "            * Show this help information\n";
  print "       -m \"<commit message>\"\n";
  print "            * if you do not provide a commit message from the command line, the\n";
  print "              squash operation will concatenate all the relevant squashed commit messages\n";  
  print "      --relative-branch=<branch-name>\n";
  print "      -b=<branch-name>\n";
  print "            * This argument allows you to specify the other branch on top of which\n";
  print "              the squashed commit will be applied.\n";
  print "      --retain-original\n";
  print "            * Do not delete the original branch (for those of us who are packrats).\n";
  print "              This will cause the original branch to be renamed as <feature-branch>-deleteme\n";
  print "\n\n";


print "  Before squashing feature branch:\n\n";
print "  * master         \n";
print "  |                \n";
print "  *                \n";
print "  |    * Z    HEAD of Feature Branch\n";
print "  *    |           \n";
print "  |    * Y         \n";
print "  *    |           \n";
print "  |    * X         \n";
print "  *   /            \n";
print "  |  /             \n";
print "  * /              \n";
print "  |/               \n";
print "  *                \n";
print "  |                \n";
print "  *                \n";
print "\n";

print "nuggit squash-rebase -b=master\n";
print "  After nuggit squash-rebase relative to master:\n\n";

print "     * Q      HEAD of (squashed) Feature Branch applied on top of base branch\n";
print "    /             Q contains the aggregate contents of X,Y and Z merged ontop of \n";
print "   /              master. \n";
print "  * master         \n";
print "  |                \n";
print "  *                \n";
print "  |                \n";
print "  * previous commits hidden    \n";
print "  |                \n";
print "  .                \n";
print "\n";

}





# RREMOVE THIS CODE, instead leverage the nuggit.pm version.  This was a copy and paste to get it working

sub get_selected_branch($)
{
  my $root_repo_branches = $_[0];
  my $selected_branch;

  $selected_branch = $root_repo_branches;
  $selected_branch =~ m/\*.*/;
  $selected_branch = $&;
  $selected_branch =~ s/\* // if $selected_branch;

  if ($selected_branch =~ /^\(HEAD detached/) {
      # If in a detached HEAD state, return undef
      return undef;
  } else {  
      return $selected_branch;
  }
}


sub get_selected_branch_here()
{
  my $branches;
  my $selected_branch;
  
#  print "Is branch selected here?\n";
  
  # execute git branch
  $branches = `git branch`;

  $selected_branch = get_selected_branch($branches);
}


