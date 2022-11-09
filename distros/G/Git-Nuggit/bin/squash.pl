#!/usr/bin/env perl
#
#
#  This is the squash version (not the squash-merge version)
#  This version will squash all the commits on your branch into one commit so you can 
#    merge that one commit into the master branch that contains the aggregation of you changes (but in a single commit).
#
#  The way this works:
#     (1) Find the merge base between your feature branch and the other branch (typically master)
#     (2) Create a branch at the merge base
#     (3) Do a merge with a squash from your feature branch into the temporary branch at the merge base.
#         - the result of this is that a temporary branch exists with a single commit relative to the merge base
#     (4) Rename the branches so that the temporary branch replaces your feature branch and the original feature branch is deleted.
#        - this step does comparison checks to ensure that there are no differences between the temporary branch and your feature branch
#
#  SIDE EFFECT... this will replace your branch with an equivalent branch with the same final content but with a single commit.
#      So... you will need to do a force push to the server
#
#  This script / process would typically be done in preparation of a merge (or a Pull Request)
#  
#  This script does not do any rebasing.  There is a similar process / script that effectively does a rebase (without doing a rebase).
#
#
# TO DO - add ability to take in arguments for
#    Add option for -m "<commit messaage to use in squash commit>"
#
#    Maybe... maybe not???:  VVV
#    ability to squash relative to a commit... 
#       so instead of the -b argument, supply a -c ?... 
#       and then you need to make the -b argument not required
#
#
# perl squash.pl -help
# perl squash.pl -b=master
# perl squash.pl -b master
# perl squash.pl -b master -m "<commit msg>"             <----  Commit message is required.
# perl squash.pl -b master --verbose -m "<commit msg>"
# perl squash.pl -b master -v -m "<commit msg>"
# perl squash.pl -c <commit-sha> -m "<commit msg>"       <---- -c specifies a commit hash of an ancestor.  this will squash all commits on the current branch, down to 
#                                                          but excluding ancestor commit

# perl squash.pl -relative-branch=master
# perl squash.pl -relative-branch master
# perl squash.pl -merge-base-commit=42dfec83
# perl squash.pl -merge-base-commit 42dfec83
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

my $base_branch;
my $feature_branch          ;
my $squashed_branch_tmp_name;
my $original_branch_deleteme;         # TO DO - consider using a time-stamp in the original deleteme branch
                                      #       this may be useful for the packrats, but will cause the 
                                      #       accumulation of clutter

my $delete_original_branch_after_squash = 1;
my $halt_if_temp_branches_already_exist = 0;   # not implemented

my $ahead;
#my $behind;

my $tmp;
my $merge_base;
my $commit_msg;
my $meld_commit_msg;

my $help = 0;
my $verbose = 0;


main();







sub main()
{
  my $active_branch;
  
  # Argument handling

  ParseArgs();

  if($help == 1)
  {
    PrintHelp();
    exit(0);
  }

  if(defined($base_branch_arg))
  {
    if($verbose==1)  
    {
      print "VERBOSE: base branch provided: $base_branch_arg\n";
    }
    $base_branch = $base_branch_arg;  
  }

  #
  # One of these two arguments (relative branch or merge base commit) is required  
  #
  if(!defined($base_commit_arg))
  {
    if(!defined($base_branch_arg))
    {
      say "no base branch OR merge base commit specified";
      PrintHelp();
      exit(0);
    }
  }
  else
  {
    if($verbose == 1)
    {
      say "VERBOSE: merge base commit specified as $base_commit_arg";
    }
  }

  if(defined($retain_original_arg))
  {
    $delete_original_branch_after_squash = 0;
  }
  else
  {
    $delete_original_branch_after_squash = 1;
  }

  if(defined($base_branch) && defined($base_commit_arg))
  {
    say colored("Cannot squash relative to a base branch AND a base commit... pick one", 'bold red');
    exit(1);
  }

  if(defined($base_commit_arg))
  {
    #
    ### Make sure this commit is an ancestor of HEAD
    #
    #  $tmp = `git rev-parse --verify $base_commit_arg`;   # either one of these should work... this should return the full sha of the merge base, which shold be equal to $base_commit_arg
    $tmp = `git merge-base HEAD $base_commit_arg`;
    chomp($tmp);
    if($tmp =~ /^($base_commit_arg)/)
    {
      if($verbose==1)
      {
        print "VERBOSE: The commit provided ($base_commit_arg) is an ancestor of HEAD\n";
        print "VERBOSE: The verify operation match returned $1\n ";
      }
    }
    else
    {
      say colored("The commit sha you provided $base_commit_arg, is not a direct ancestor of HEAD", 'bold red');
      say colored(" You must provide a commit sha that is a direct ancestor in order to squash to a commit.", 'bold red');
      exit(1);    
    }

    
    $merge_base = $base_commit_arg;
    
#    print "EXITING\n  you specified a base commit arg... not yet implemented... getting there\n";
#    exit(0);
  }

  $active_branch = get_selected_branch_here();
  $feature_branch = $active_branch;
  $squashed_branch_tmp_name = "$feature_branch-tmp-squashed";
  $original_branch_deleteme = "$feature_branch-deleteme";

  if(!defined($active_branch))
  {
    say colored("Repo branch detection error", 'bold red');
    say "\t Current branch unknown.";
    exit(1);
  }

  if(defined($base_branch))
  {
    #
    #  Make sure that the relative base branch is NOT the currently checked out branch
    #
    if($verbose==1)
    {
      print "VERBOSE: Make sure the relative (base) branch (as supplied by argument b) is not the checked out branch\n";
    }
    if ($active_branch eq $base_branch)
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
        say "\t Currently on branch: $active_branch. Attempting to squash $active_branch relative to $base_branch";
      }
    }

    if($verbose==1)
    {
      print "VERBOSE: Find the commit that is the merge base between $active_branch and $base_branch\n";
    }

    #find the merge base... This is the common ancestor commit from which the two branches diverged.
    $merge_base = `git merge-base $active_branch $base_branch`;
    chomp($merge_base);

    if($verbose==1)
    {
      print "VERBOSE: Merge base is $merge_base\n";
      print "VERBOSE: Make sure temporary squashed branch name ($squashed_branch_tmp_name) does not already exist from prior operation\n";
    }
    
    if($verbose==1)
    {
      print "VERBOSE: Make sure the relative branch exists\n";
    }
    $tmp = `git show-ref $base_branch`;
    if($tmp ne "")
    {
      print "";
    }
    else
    {
      say colored("ERROR: $base_branch does not exist in this repo.", 'bold red');
      say colored("       Cannot squash relative to a non-existent branch", 'bold red');
      exit(1);
    }

  }

  # =======================================================================================================
  # check that there is more than one commit on the feature branch relative to the merge base.
  # if there are 0 or 1 commits on the feature branch relative to the merge base THEN do not do the squash.
  # =======================================================================================================
  if($verbose==1)
  {
     print "VERBOSE: Check that there is more than one commit on the feature branch.\n";
     print "VERBOSE:     - do not squash if there is only one commit (or 0) to start with.\n";
  }

#  $tmp = `git rev-list --left-right --count $base_branch...$active_branch`;
  $tmp = `git rev-list --left-right --count $merge_base...$active_branch`;
  chomp($tmp);
  
  #parse $tmp for behind and ahead here
  
  $tmp =~ /([0-9]*)\s+([0-9]*)/;
#  $behind = int($1);
  $ahead  = int($2);
  
  if($ahead == 0)
  {
    print "Your branch has no additional commits on it.  Ahead = $ahead\n";
    print "Nothing to squash. Nothing else to do in this repo. Exiting\n";
    exit(0);
  }
  if($ahead == 1)
  {
    print "Your branch has only one commit.  Ahead = $ahead\n";
    print "No need to squash. Nothing else to do in this repo. Exiting\n";
    exit(0);
  }

  if($verbose==1)
  {
     print "VERBOSE: This branch is ahead by more than one commit.  Start the squash operation\n";
  }

  if($verbose == 1)
  {
    if(defined($base_commit_arg))
    {
      say "VERBOSE: Squashing $active_branch down to (but excluding) $base_commit_arg commit";
    }
    if(defined($base_branch))
    {
      say "VERBOSE: Squashing $active_branch relative to $base_branch";
    }

    say "VERBOSE: Delete original: $delete_original_branch_after_squash";
  }



  #
  #
  # Do the squash operation
  #
  #

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
    print "VERBOSE: Create temporary squashed branch ($squashed_branch_tmp_name) at $merge_base\n";
  }
  # create a branch off of merge base.  We will squash all the commits since this commit on 
  # our feature branch and then commit this one squashed commit onto the merge-base branch 
  $tmp = `git branch $squashed_branch_tmp_name $merge_base`;    # <---- the squash-merge version will just use the master branch name rather than the merge base here

  if($verbose==1)
  {
    print "VERBOSE: Checkout the temporary squashed branch ($squashed_branch_tmp_name) at $merge_base\n";
  }
  #nuggit_squash
  # -q indicates to suppress the output message
  $tmp = `git checkout -q $squashed_branch_tmp_name`;
  #print $tmp;

  if($verbose==1)
  {
    print "VERBOSE: merge $feature_branch (onto $squashed_branch_tmp_name) with squash option\n";
  }
  $tmp =  `git merge $feature_branch --squash`;
  #print $tmp;


  if($verbose==1)
  {
    print "VERBOSE: Get the concatenated commit log using the git log command.  this could be cleaned up a bit\n";
  }
    
  # the following command will get all the (non-merge) commits that are on feature branch but not on $merge_base argument
  # the $merge base argument may be a branch name or a commit sha.  In this case I use the commit sha because that is 
  # the bound of the squash.
  $meld_commit_msg = `git log --no-merges $feature_branch ^$merge_base`;

  my $tmp_str = "";
  if(defined($base_branch))
  {
    $tmp_str = " relative to $base_branch and"
  }
  $commit_msg = "N:$feature_branch: $user_commit_msg_arg.\nNuggit Squash: ($feature_branch)$tmp_str merge base of $merge_base\n$meld_commit_msg";

  if($verbose==1)
  {
    print "VERBOSE: Commit the squash merge of $feature_branch --> $squashed_branch_tmp_name\n";
  }
  $tmp =  `git commit -m "$commit_msg"`;

  if($verbose==1)
  {
    print "VERBOSE: compare the original $feature_branch to $squashed_branch_tmp_name.  These should have exact same contents\n";
  }
  # NOW we have a squashed branch
  # the squashed branch is the checked out branch
  #COMPARE the two branches... if they are OK, then rename
  $tmp = `git diff $feature_branch $squashed_branch_tmp_name`;    
  if($tmp eq "")
  {
    if($verbose==1)
    {
      print "VERBOSE: No diffs between the original $feature_branch and $squashed_branch_tmp_name\n";
    }
  }
  else
  {
    say colored("ERROR: Differences detected between the squashed branch and the original feature branch.", 'bold red');
    say colored("       Check $feature_branch and $squashed_branch_tmp_name", 'bold red');
    say colored("Bailing out", 'bold red');
    
    print "\n\n\n";
    print "Differences detected here:\n";
    print $tmp;
    print "\n";
    exit(1);
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

  $tmp = `git checkout -q $feature_branch`;            # go back to feature branch
  $tmp = `git branch $original_branch_deleteme`;       # create a save branch before doing the following
  $tmp = `git reset --hard $squashed_branch_tmp_name`; # point the current branch at the squashed branch HEAD
  $tmp = `git branch -D $squashed_branch_tmp_name`;    # now that we have a branch with the original name pointing 
                                                       #   to the squased branch HEAD, we can delete the squashed 
                                                       #   branch temporary name

  if($verbose==1)
  {
    print "VERBOSE: Comparing newly squashed branch $feature_branch to the original $original_branch_deleteme\n";
  }
  # Now the original branch name contains the squashed branch and we have renamed the original branch into a temporary branch
  #COMPARE the two branches... if they are OK.  If all is good, then delete the temporary branch (original branch under new name)
  $tmp = `git diff $feature_branch $original_branch_deleteme`;    
  if($tmp eq "")
  {
    if($verbose==1)
    {
      print "VERBOSE: No differences between: $feature_branch and the original $original_branch_deleteme\n";
    }
  }
  else
  {
    say colored("ERROR: Differences detected between the squashed branch and the original feature branch.", 'bold red');
    say colored("       Check $feature_branch and $original_branch_deleteme", 'bold red');
    say colored("Bailing out", 'bold red');    
    
    print "\n\n\n";
    print "Differences detected here:\n";
    print $tmp;
    print "\n";
    exit(1);    
  }

  if ($delete_original_branch_after_squash == 1)
  {
    if($verbose==1)
    {
      print "VERBOSE: Deleting original branch (now called $original_branch_deleteme)\n";
    }
    $tmp = `git branch -D $original_branch_deleteme`;
  }  

  print "------\n";
  print "You will need to force push this to your remote server.\n";
  print "The final contents of your branch have not changed however\n";
  print "The commit history is completely different\n";
  print "\n";
  print "    git push --force-with-lease       \n";
  print "\n";
  print "------\n";
  
} # end of main program





#
#
# Functions
#
#

sub ParseArgs()
{
    Getopt::Long::GetOptions(
                           "message|m=s"            => \$user_commit_msg_arg,        # required argument
                           "verbose|v"              => \$verbose,
			   "help"                   => \$help,
			   "relative-branch|b=s"    => \$base_branch_arg,
			   "merge-base-commit|c=s"  => \$base_commit_arg,
			   "retain-original"        => \$retain_original_arg
                          );


    # check for unparsed arguments
    if( (@ARGV > 0) || ($help==1))
    {
      $help = 1;
      return;
    }

    if(defined($user_commit_msg_arg))
    {
      my $size = length $user_commit_msg_arg;
      my $min_len = 4; # TODO: Make this configurable?
      if ($size < $min_len) {
          die("A useful commit message of at least $min_len characters is required: You specified \"$user_commit_msg_arg\"");
      }
    }
    else
    {
      die("A useful commit message is required. use -m to specify a commit message\n");
    }
    


}

sub PrintHelp()
{
  print "Nuggit Squash\n\n";
  
  print "  This command will squash the commits on the current feature branch into a single commit\n";
  print "  relative to the merge base.  This operation is intended to be performed in preparation\n";
  print "  of merging the feature branch into master.  This operation allows the final state of your\n";
  print "  feature branch to exist in a branch with a single end-state commit without all of the\n";
  print "  intermediate commits.\n";
  print " \n";
  print "  This operation will replace your feature branch with an equivalent squashed feature branch\n";
  print "  with the same name.  An implication of this is that you will have to do a force push to the\n";
  print "  server.\n\n";
    
  print "  Usage:\n";
  print "     nuggit squash --help\n";
  print "                    -m \"<commit message>\"\n";
  print "                   --relative-branch <base-branch-name>\n";
  print "                    -b <base-branch-name>\n";
  print "                   --merge-base-commit <sha>\n";
  print "                    -c <sha>                \n";
  print "                   -m \"<commit message>\"\n";
  print "                   --retain-original\n";
  print "                   --verbose -v\n";
  print " \n";
  print "Options\n\n";

  print "      --help\n";
  print "            * Show this help information\n";
  print "       -m \"<commit message>\"\n";
  print "            * Required argument\n";
  print "      --relative-branch=<branch-name>\n";
  print "      -b=<branch-name>\n";
  print "            * This argument allows you to specify the other branch that\n";
  print "              that will be used to determine the 'merge base'\n";
  print "      --merge-base-commit=<commit-sha>\n";
  print "      -c=<commit-sha>\n";
  print "            * This argument specifies the commit sha to use as the merge base.\n";
  print "              This commit must be an ancestor of current branch HEAD.  This\n";
  print "              command will result in creating a branch from this point, squashing\n";
  print "              the commits on the feature branch and placing the new commit onto\n";
  print "              the specified merge base commit.\n";
  print "      --retain-original\n";
  print "            * Do not delete the original branch (for those of us who are packrats).\n";
  print "              This will cause the original branch to be renamed as <feature-branch>-deleteme\n";
  print "\n\n";


print "  Before squashing feature branch:\n\n";
print "  * master         \n";
print "  |                \n";
print "  *                \n";
print "  |    * Z    HEAD of Feature Branch\n";
print "  |    |           \n";
print "  |    * Y         \n";
print "  *    |           \n";
print "  |    * X         \n";
print "  |   /            \n";
print "  *  /             \n";
print "  | /              \n";
print "  |/               \n";
print "  *   <--- merge base of Feature Branch and master\n";
print "  |                \n";
print "  *                \n";
print "\n";

print "nuggit squash -b=master\n";
print "  After nuggit squash relative to master:\n\n";
print "  * master         \n";
print "  |                \n";
print "  *                \n";
print "  |    * Q    HEAD of Feature Branch\n";
print "  *   /            \n";
print "  |  /             \n";
print "  * /              \n";
print "  |/               \n";
print "  *                \n";
print "  |                \n";
print "  *                \n";
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


