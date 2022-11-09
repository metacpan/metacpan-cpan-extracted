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

use strict;
use warnings;
use v5.10;
use Getopt::Long;
use Pod::Usage;
use Cwd qw(getcwd);
use Term::ANSIColor;
use File::Spec;
use Git::Nuggit;
use JSON;
use Data::Dumper;

=head1 SYNOPSIS

List or create branches.

To create a branch, "ngt branch BRANCH_NAME"

To list branches, "ngt branch".  Note the output of "ngt status" with optional "-a" and "-d" flags will also display the currently checked out branches along with additional details.

To list all branches, "ngt branch -a"

To delete a branch, "ngt branch -d BRANCH_NAME".  See below for additional options.

NOTE: The "-r" syntax for deleting remote repositories in Nuggit differs from native git. In git this command requires specifying a branch in the form 'origin/branch' and only removes them locally.  Nuggit does not require the prefix, and removes them locally and remotely.

=over

=item --help

Display an abbreviated help menu

=item --man

Display detailed documentation.

=item -d | --delete

Delete specified branch from the root repository, and all submodules, providing that said branch has been merged. 

Equivalent to "git branch -d", deleting the specified branch name only if it has been merged into HEAD.  This version will apply said change to all submodules.

=item -D | --delete-force

This flag forces deletion of the branch regardless of merged state. Usage is otherwise the same as -d above and mirrors "git branch -D"

=item -r | remote

Apply operation to the remote (server) branch.  

This flag currently applies only branch deletion operations, and is explicitly documented below as '-rd' and '-rD'.

Typical usage is: "ngt branch -rd branch" or "ngt branch -rD branch".

Note: Unlike the native git branch command, no 'origin' prefix is required here.

=item -rd

This will delete the specified branch from the remote origin for the root repository, and all submodules, providing that said branch has been merged into HEAD [as known to local system].  Precede this commmand with a "ngt fetch" to ensure local knowledge is up to date with the current state of the origin to improve accuracy of this check.

This check is meant to supplement server-side hooks/settings to help minimize user errors, but does not replace the utility of additional server-side checks.

=item -rD

Delete specified branch from the remote origin for the root repository, and all submodules, unconditionally.

=item --all | -a

List all known branches, not just those that exist locally.  Remote branches are typically prefixed with "remotes/origin/".  This is equivalent to the same option to "git branch".

=item --merged | --no-merged

Filter branch listing by merged or not merged state.  If neither option is specified, then all matching branches will be displayed.  This may be combined with the "-a" option, and is equivalent to the same option in "git branch".

NOTE: If the '--no-merged' option is specified, checks for submodule branches matching root will be skipped.

=item --recursive 

Recurse through all the submodules.  When used with no other options, or --merged, or --no-merged, or --all, this will display matching branches across all repositories/submodules

=item --orphans

List all orphaned branches.  An orphaned branch is one that exists in a submodule but not in the root repository.  This will also accept the following flags:  --json, --all. 

=item --orphan

This argument must specify a branch name and an additional flag.  If no other flags are provided indicating specific information about the orphan, this will show full details about the orphan branch.  Full details include, the count of repos where the specified branch exists, count of repos where specified branch is missing, gives a list of repos where specified branch is missing, gives a list of repos where specified branch exists.  When this flag is provided, the following specifics can be requested --missing-from or --exists-in, where information about which repos do not have this branch, or which repos do have this branch respectively.

=item --exists-in-all

The --exists-in-all flag may be provided an optional branch name.  If a branch name is provided, this will check if the specified branch exists in all submodules.  If no branch name is provided, this will output a list of branches that do exist in all submodules that are visibile from the currently checked out workspace/branch.

=back

=cut


# usage: 
#
# to view all branches just use:
# nuggit_branch.pl
#     This will also check to see if all submodules are on the same branch and warn you if there are any that are not.
#
# to create a branch
# nuggit_branch.pl <branch_name>
#
# to delete fully merged branch across all submodules
# nuggit_branch.pl -d <branch_name> 
#     TO DO - DO YOU NEED TO CHECK THAT ALL BRANCHES ARE MERGED ACROSS ALL SUBMODULES BEFORE DELETING ANY OF THE BRANCHES IN ANY SUBMODULES???????
#

sub ParseArgs();
sub is_branch_selected_throughout($);
sub create_new_branch($);
sub get_selected_branch_here();


sub display_branches_recursive_flag();
sub get_orphan_branch_info($$);
sub get_full_branch_list($);
sub is_item_in_array($$);
sub get_branch_info();
sub orphan_info();
sub list_nuggit_branches();
sub list_unmerged_recursive();

my $ngt = Git::Nuggit->new() || die("Not a nuggit!");

my $cwd = getcwd();
my $root_repo_branches;
my $show_all_flag             = 0; # IF set, show all branches
my $create_branch             = 0;
my $delete_branch_flag        = 0;
my $delete_merged_flag        = 0;
my $delete_remote_flag        = 0;
my $delete_merged_remote_flag = 0;
my $show_merged_bool          = undef; # undef = default (no filter), true=merged-only, false=unmerged-only
my $recurse_flag              = 0;
my $orphans_flag              = 0;
my $exists_in_all_flag        = 0;
my $orphan_branch             = "";
my $exists_in_flag            = 0;
my $missing_from_flag         = 0;
my $verbose = 0;
my $show_json = 0;
my $selected_branch = undef;
my $do_branch_list = 0;

# print "nuggit_branch.pl\n";

ParseArgs();
my $root_dir = $ngt->root_dir();

chdir $root_dir;

if($delete_branch_flag)
{
  $ngt->start(level=> 1, verbose => $verbose);
  say "Deleting branch across all submodules regardless of merge status: " . $selected_branch;
  delete_branch($selected_branch, "-D");
} 
elsif ($delete_merged_flag) 
{
    $ngt->start(level=> 1, verbose => $verbose);
    say "Deleting (merged) branch across all submodules: " . $selected_branch;
    delete_merged_branch($selected_branch);
}
elsif ($delete_remote_flag) 
{
    $ngt->start(level=> 1, verbose => $verbose);
    say "Deleting branch from origin across all submodules: " . $selected_branch;
    delete_remote_branch($selected_branch);
}
elsif ($delete_merged_remote_flag) 
{
    $ngt->start(level=> 1, verbose => $verbose);
    say "Deleting merged branch from origin across all submodules: " . $selected_branch;
    delete_merged_remote_branch($selected_branch);
}
elsif( ($orphans_flag) or 
       ($exists_in_all_flag) or
       ($orphan_branch ne "")
     )
{
    $ngt->start(level=> 0, verbose => $verbose);
    orphan_info();   # print the orphans (or the nuggit branches that exist in all repos)
}
elsif (defined($selected_branch) && $do_branch_list == 0) 
{
    # only want to create a flag if we do not believe we were requested to do a branch listing
    $ngt->start(level=> 1, verbose => $verbose);
    create_new_branch($selected_branch);
}
else
{
    $ngt->start(level=> 0, verbose => $verbose);
    if(defined($selected_branch) && $do_branch_list == 1)
    {
    
#      print "Selected branch: $selected_branch \n";
#      print "--all:           $show_all_flag\n";
#      print "--recursive:     $recurse_flag\n";
#      print "--[no-]merged:        $show_merged_bool\n";

      my $checked_out_branch_head_commit = "";
      my $branch_head_commit = "";
      my $checked_out_branch_here = "FOOO";
      
      $ngt->foreach({'run_root' => 1, 'breadth_first' => sub {
                          my $info = shift;
                          my $parent = $info->{'parent'};
                          my $name   = $info->{'name'};
                          if($name eq "")
                          {
                             $name = "Nuggit Root";
                          }


                          $checked_out_branch_here = get_selected_branch_here();
                          $checked_out_branch_head_commit = `git rev-parse --short $checked_out_branch_here`;
                          
                          # to do - check if the selected branch exists, if it does not exist then ????
                          my $exit_code = system("git show-ref --verify --quiet refs/heads/$selected_branch");
                          if($exit_code == 0)
                          {
                            #print "branch $selected_branch exists in repo $name\n";
                          }
                          else
                          {
                            print "branch $selected_branch does not exist in repo $name\n";
                            return;
                          }
                          
                          $branch_head_commit = `git rev-parse --short $selected_branch`;           ### TO DO - FOR CORRECTNESS YOU WILL WANT TO ELIMINATE THE --short WHICH WILL INSTEAD GET THE FULL SHA
                          chomp($branch_head_commit);
                          
#                         print "Check if branch $selected_branch is merged into checked out branch in repo: $name\n";
#                         print "   Does branch $selected_branch exist? TODO\n";
#                         print "   Checked out branch in repo $name is $checked_out_branch_here\n";
#                         print "   Head commit of branch $selected_branch is: $branch_head_commit\n";
#                         print "   check if head commit $branch_head_commit is merged into checked out branch $checked_out_branch_here\n";
                          $exit_code = system("git merge-base --is-ancestor $branch_head_commit $checked_out_branch_head_commit");
                          
                          if(defined($show_merged_bool))
                          {
                              if($show_merged_bool && $exit_code == 0)
                              {
                                  print "branch $selected_branch is merged into branch $checked_out_branch_here in repo $name\n";
                              }
                              elsif(!$show_merged_bool && $exit_code != 0)
                              {
                                  print "branch $selected_branch is NOT merged into branch $checked_out_branch_here in repo $name\n";
                              }
                          }
                          else
                          {
                             if($exit_code == 0)
                             {
                                print "branch $selected_branch is merged into branch $checked_out_branch_here in repo $name\n";
                             }
                             else
                             {
                                print "branch $selected_branch is NOT merged into branch $checked_out_branch_here in repo $name\n";
                             }
                          }

                       }
                    });
      
    }
    else
    {
      if ($show_json) {
          verbose_display_branches();
      } else {
        if($recurse_flag)
        {
          display_branches_recursive_flag();
        }
        else
        {
          display_branches();
        }
      }
    }
}

sub verbose_display_branches
{
    # TODO: This may will eventually replace display_branches below, with a new text-output added here
    # TODO: If user requests to check all submodules, call get_branches on all submodules
    #        and verify branch is consistent throughout (similar to below, but saving output for more display options)
    # Output would then be either:
    # - Text listing similar to current, but extend by noting branches for any submodule that differs
    # - JSON output
    #   - is_consistent: bool
    #   - branches: Root branches object
    #   - submodules: Object where key is submodule path and value is branch listing
    
    my $branches = get_branches({
        all => $show_all_flag,
        merged => $show_merged_bool,
       });
    say encode_json($branches);
    
}

sub display_branches
{

    $root_repo_branches = `git branch`;
    $selected_branch    = get_selected_branch($root_repo_branches);

    my $flag = ($show_all_flag ? "-a" : "");
    if (defined($show_merged_bool)) 
    {
        if ($show_merged_bool) 
        {
            $flag .= " --merged";
        }
        else
        {
            $flag .= " --no-merged";
        }
    }

    # get the list of root repo branches that match the flaga
    $root_repo_branches = `git branch $flag`;

    
    # Note: If showing merged/no-merged, selected branch may be unknown
    say "Root repo is on branch: ".colored($selected_branch, 'bold') if $selected_branch;

    print color('bold');
    print "All " if $show_all_flag;

    if (defined($show_merged_bool)) {
        if ($show_merged_bool) 
        {
           print "Merged ";
        }
        else # show_merged_bool == 0
        {
           print "Unmerged ";
        }
    }
        
    say "Branches:";
    print color('reset');
    
    if($root_repo_branches)
    {
        say $root_repo_branches;
    }
    else
    {
        print "  none found\n";
    }


  # --------------------------------------------------------------------------------------
  # now check each submodule to see if it is on the selected branch
  # for any submodules that are not on the selected branch, display them
  # show the command to set each submodule to the same branch as root repo
  # --------------------------------------------------------------------------------------
  is_branch_selected_throughout($selected_branch) if $selected_branch;

}


sub ParseArgs()
{
    my ($help, $man, $remote_flag);
    Getopt::Long::Configure("no_ignore_case", "bundling");
    Getopt::Long::GetOptions(
        "delete|d!"         => \$delete_merged_flag,
        "delete-force|D!"   => \$delete_branch_flag,
        "remote|r"          => \$remote_flag,
        "merged!"           => \$show_merged_bool,
        "all|a!"            => \$show_all_flag,
        "verbose|v!"        => \$verbose,
        "json!"             => \$show_json, # For branch listing command only
        "help"              => \$help,
        "recursive"         => \$recurse_flag,
        "orphans"           => \$orphans_flag,        # list orphan branches
        "exists-in-all"     => \$exists_in_all_flag,  # get list of branches that exist in all submodules (that we have access to from the currently checked out branch)
        "orphan=s"          => \$orphan_branch,       # specifies the specific orphan branch name. 
                                                      # If this is provided, then additional flags may be provided
        "exists-in"         => \$exists_in_flag,      # when this and the orphan branch are passed in, this will list all the submodule repos where the branch exists
        "missing-from"      => \$missing_from_flag,   # when this and the orphan branch are passed in, this will list all the submodule repos where the branch does not exist.
        "man"               => \$man,
      ) || pod2usage(1);
    pod2usage(1) if $help;
    pod2usage(-exitval => 0, -verbose => 2) if $man;

    if ($remote_flag) {
        if ($delete_branch_flag) { $delete_branch_flag = 0; $delete_remote_flag = 1; }
        if ($delete_merged_flag) { $delete_merged_flag = 0; $delete_merged_remote_flag = 1; }
    }
    die "Error: Please specify only one of '-d' or '-D' flags." if ($delete_branch_flag+$delete_remote_flag+$delete_merged_flag+$delete_merged_remote_flag) > 1;

    if ( ($delete_branch_flag + $delete_merged_flag + $delete_remote_flag + $delete_merged_remote_flag) > 1) {
        die "ERROR: Please specify only one version of delete flags (-d -D -rd -rD) at a time.";
    }

    # try to differentiate between commands to list or show something and a command to create a branch.  We dont want to create a branch
    # if the user executes 'nuggit branch foo --all'
    if($recurse_flag or defined($show_merged_bool) or $show_json or $recurse_flag or $orphans_flag or $orphan_branch or $exists_in_flag or $missing_from_flag)
    {
      $do_branch_list = 1;
    }

    # If a single argument is specified, then it is a branch name. Otherwise user is requesting a listing.
    if (@ARGV == 1) {
        $selected_branch = $ARGV[0];
    }
}

sub create_new_branch($)
{
    my $new_branch = shift;
    $ngt->run_die_on_error(0);
 
  # create a new branch everywhere but do not switch to it.
  say "Creating new branch $new_branch";
  $ngt->run("git branch $new_branch");
  submodule_foreach(sub {
      $ngt->run("git branch $new_branch");
                    });
}



# check all submodules to see if the branch exists
sub is_branch_selected_throughout($)
{
  my $root_dir = getcwd();
  my $branch = $_[0];
  my $branch_consistent_throughout = 1;
  my $cnt = 0;
  print "Checking submodule status . . . \n";

  submodule_foreach(sub {
      my $subname = File::Spec->catdir(shift, shift);
      
      my $active_branch = get_selected_branch_here();
      if(!defined($active_branch))
      {
          say colored("$subname is not on selected branch", 'bold red');
          say "\t Current branch unknown.";
          $cnt++;
                    
          $branch_consistent_throughout = 0;
      }  
      elsif ($active_branch ne $branch) {
          say colored("$subname is not on selected branch", 'bold red');
          say "\t Currently on branch $active_branch";
          $cnt++;
                    
          $branch_consistent_throughout = 0;
      }
                    });

  if($branch_consistent_throughout == 1)
  {
      say "All submodules are are the same branch";
  } else {
      say "$cnt submodules are not on the same branch.";
      say "If this is not desired, and no commits have been made to erroneous branches, please resolve with 'ngt checkout $branch'.";
      say "If changes have been erroneously made to the wrong branch, manual resolution may be required in the indicated submodules to merge branches to preserve the desired state.";
  }
  
  return $branch_consistent_throughout;
}

# Delete a branch only if it is merged at all levels
sub delete_merged_branch
{
    my $branch = shift;
    if (check_branch_merged_all($branch)) {
        delete_branch($branch, "-d");
    } else {
        die "This branch is not known, or has not been merged into HEAD.  Use '-D' to force deletion anyway.\n";
    }
}

# Base function to (unconditionally) delete a local branch, failing on first error
sub delete_branch
{
  my $branch = shift;
  my $flag = shift || "-d";

  my $cmd = "git branch $flag $branch";

  $ngt->run_die_on_error(0);
  $ngt->foreach({
      'depth_first' => sub {
          my $in = shift;

          my ($err, $stdout, $stderr) = $ngt->run($cmd);
            if ($err) {
                say colored("Deletion of $branch failed for ".($in->{'subname'} ? $in->{'subname'} : "/"), 'warn');
            }
      },
      'run_root' => 1
     });
}

# Delete a remote branch (unconditionally)
sub delete_remote_branch
{
    my $branch = shift;
    my $cmd = "git push origin --delete $branch";
    
    $ngt->run_die_on_error(0);
    $ngt->foreach({
        'depth_first' => sub {
            my $in = shift;
            my ($err, $stdout, $stderr) = $ngt->run($cmd);
            if ($err) {
                say colored("Deletion of branch $branch on remote failed for ".($in->{'subname'} ? $in->{'subname'} : "/"), 'warn');
            }
        },
        'run_root' => 1
       });
}

# Delete Remote branch, only if it is merged at all levels
sub delete_merged_remote_branch
{
    my $branch = shift;

    if (check_branch_merged_all($branch, "origin")) {
        delete_remote_branch($branch); 
    } else {
        say "This branch is not known locally, or has not been merged into HEAD.  Use '-rD' to force deletion any<way.  It may not be possible to recover branches that have been deleted remotely.";
    }
}

# TODO: Make this an option to call directly, ie: ngt branch -a --merged ? Or ngt branch --check-merged $branch
# TODO: TEST
sub check_branch_merged_all
{
    my $branch = shift;
    my $remote = shift;
    my $status = 1; # Consider it successful, unless we find a branch that is not merged

    # TODO: Replace remotes with origin for local detection?
    my $check_cmd = "git branch -a --merged";
    my $check_branch_known_cmd = "git branch | grep $branch";
    
    $ngt->foreach( {'depth_first' => sub {
              # is the branch unknown
              my $branch_known = `$check_branch_known_cmd`;
              if( $branch_known eq "")
              {
                #branch is not found in this repository... consider this merged and deleted... not an error.
              }
              else  
              {
                # branch does exist in this repo, check if it is merged
                my $state = `$check_cmd`;
                if (!$state) {
                    $status = 0;
                    say "Branch ($branch) not merged/found at ".getcwd() if $verbose;
                } else {
                    #print $state . "\n";
                    my @lines = split('\n', $state);
                    my $linefound = 0;
                    foreach my $line (@lines) {
                        $line =~ /(remotes\/(?<remote>\w+)\/)?(?<branch>[\w\d\-\_\/]+)/;
                        if ($remote && $+{remote} && $+{remote} eq $remote && $+{branch} eq $branch) {
                            $linefound = 1; # Match for remote branch
                            last;
                        } elsif (!$remote && !$+{remote} && $branch eq $+{branch}) {
                            $linefound = 1; # Match for local branch
                            last;
                        }
                    }
                    if (!$linefound) {
                        $status = 0;
                        say "Branch (line not found) not merged/found at ".getcwd() if $verbose;
                    }
                }
             }
          },
       'run_root' => 1
      }
     );
    return $status;
}



# build and return an array data structure
# that contains the union of all branches across all submodules that match the provided
# flags. 
#
# The list returned may contain duplicates
#
# Not all flags passed into the script are used by the git commands executed.
#
# The format of the array returned is:
#
#   array [ 
#            { name = string
#              branch array = { 
#                    branch, 
#                    branch, 
#                    branch },
#              },
#            ...
#        ]
sub get_branch_info()
{
  my @nuggit_branch_info;

  my $git_cmd_flags = "";
  if( $show_all_flag )
  {
    $git_cmd_flags = $git_cmd_flags . " --all ";
  }

#  print "git cmd flags: $git_cmd_flags\n";

  $ngt->foreach({'run_root' => 1, 'breadth_first' => sub {
                   my %branch_info;
                   my $info = shift;
                   my $parent = $info->{'parent'};
                   my $name = $info->{'name'};
                   if($name eq "")
                   {
                     $name = "Nuggit Root";
                   }
                   my $branches_string = `git branch $git_cmd_flags`;
                   
                   $branch_info{'name'} = $name;
           
                   # convert the branches string into a branches array
                   my @branch_array = split("\n", $branches_string,);
                   
                   # remove the "*" for the selected branch
                   foreach(@branch_array)
                   {
                     $_ =~ s/\*//;
                     $_ =~ s/^\s+//; 
                   }
                   
                   $branch_info{'branches_array'} = \@branch_array;
                   
                   push(@nuggit_branch_info, \%branch_info);

                }});
                   

  return @nuggit_branch_info;

}


# This function is passed an array and an item. 
# This will determine if the item is already in the array and return 
# that result
sub is_item_in_array($$)
{
  my @array_arg = @{$_[0]};
  my $item_arg  = $_[1];

  foreach my $item ( @array_arg )
  {
  
#    print $item . " =? " . $item_arg . " \n";
  
    if($item eq $item_arg)
    {
#      print "item ($item_arg) already in array\n";
      return 1;
    }
    
  }
  
#  print "Item ($item_arg) not in array\n";
  return 0;
}


#
# Return a list of just the unique branches from the provided
# array that may contain duplicates
#
sub get_full_branch_list($)
{
  my @nuggit_branch_info = @{$_[0]};
  my @full_branch_list;
  foreach my $tmp_branch_info (@nuggit_branch_info)
  {
     my @branches_array = @{ $tmp_branch_info->{'branches_array'} };
  
     foreach my $tmp_branch (@branches_array)
     {
       #print "About to check if $tmp_branch is in the array\n";
       if(!is_item_in_array(\@full_branch_list, $tmp_branch))
       {
         #print "branch $tmp_branch is new to the list\n";
         push(@full_branch_list, $tmp_branch);
       }
     
     }
  }
  return @full_branch_list;
}


# return an array with one entry for each branch, each entry contains a hash
# with the branch name, its orphan status
# number of repos where the branch was found
# number of repos where the branch was not found
# an array containing a list of repos where the branch
# was found, and an array containing a list of repos where
# the branch was not found.

sub get_orphan_branch_info($$)
{

  my @nuggit_branch_info;
  my @full_branch_list;
   
  @nuggit_branch_info = @{$_[0]};
  @full_branch_list   = @{$_[1]};

  my @orphan_branch_info;   # build and return this

  # Algorithm 
  # for each unique branch, go through all the repos and check if the branch is in the repo
  foreach my $branch_name (@full_branch_list)
  {
    my @missing_from_array;
    my @exists_in_array;
  
    foreach my $repo_info (@nuggit_branch_info)
    {
      my $repo_A_name    = $repo_info->{'name'};
      my @branches_array = @{ $repo_info->{'branches_array'} };

      if(!is_item_in_array(\@branches_array, $branch_name))
      {
#        print "    X branch $branch_name is not in this repo\n";
        push(@missing_from_array, $repo_A_name);
      }
      else
      {
#        print "    branch $branch_name is in this repo\n";
        push(@exists_in_array, $repo_A_name);
      }
    }

#  define a data structure for this particular branch
#{
#    name: branch name
#    exists_in_array:     [ @branch list ]
#    missing_from_array:  [ @branch list ]
#}
    my %branch_info;
    $branch_info{'branch_name'}  = $branch_name;
    
#    print "Branch: $branch_name \n";
    
    if(@missing_from_array == 0)
    {
      #print "    Branch ($branch_name) exists in all repos\n";
      $branch_info{'orphan_status'} = "nuggit";
    }
    else
    {
       $branch_info{'orphan_status'} = "orphan";

       #print "Missing from array for branch $branch_name: \n";
       #foreach my $repo (@missing_from_array)  { print "    $repo\n"; }
       #print "Exists in array: \n";
       #foreach my $repo (@exists_in_array)     { print "    $repo\n"; }
    }
    
    
    $branch_info{'missing_count'}      = @missing_from_array;
    $branch_info{'missing_from_array'} = \@missing_from_array;
    $branch_info{'exist_count'}        = @exists_in_array;
    $branch_info{'exists_in_array'}    = \@exists_in_array;
    
    push(@orphan_branch_info, \%branch_info );
    
  }
  
  return @orphan_branch_info;
  
}



sub display_branches_recursive_flag()
{

  my @nuggit_branch_info = get_branch_info();  # this returns a basic data structure (array) that contains an entry 
                                               # for each repo/submodule and an array for that repo containing a list 
                                               # of all the branches
  
  # create an empty list/array of unique branches.  This will be the super set of all branches in all repos  
  my @full_branch_list = get_full_branch_list(\@nuggit_branch_info);
  
  # a few options exists
  #    (1) --merged or --no-merged flag was provided
  #            In this case, we want to find:
  #               (a) --merged: the branches that are fully merged into the HEAD commit or
  #               (b) --no-merged: the branches that have at least one repo/submodule where 
  #                    the branch is not merged into the HEAD commi.t
  #    (2) neither --merged or --no-merged flags were provided
  #            In this case, we want to list a superset of all the unique branches
  #             that fit the description across all submodules
  
  if(defined($show_merged_bool))
  {
    # print "CASE 1: show merged or unmerged branches\n";
     
    # at this point we have 
    #      "@nuggit_branch_info" which is an array of each repository and a list of all the branches in that repository
    #      and
    #      "@full_branch_list" which is an array of the unique branches that exist across all submodules along with some additional information about the branch

    if($show_merged_bool)
    {

      print "  all flag:            $show_all_flag\n";
      print "  recurse flag:        $recurse_flag\n";
      print "  show merged bool:    true\n";
      print "\n";

      print "Superset of unique branches: \n";
      print Dumper(@full_branch_list);    # this is the superset list of all branches

      print "TO DO - make an array of FULLY merged branches (into HEAD) of each respective repo\n";

      # ======================================================
      # to do - you are here
      # ====================================================== 
      
    }
    else
    {
      print "Branches that are not fully merged into checked out branch\n";
     
      list_unmerged_recursive();
    }

  }
  else
  {
#    print "CASE 2: show superset of unique branches recursively across all submodules\n";

    # at this point we have 
    #      "@nuggit_branch_info" which is an array of each repository and a list of all the branches in that repository
    #      and
    #      "@full_branch_list" which is an array of the unique branches that exist across all submodules along with some additional information about the branch    

    # Sort the array for convenience
    my @sorted_full_branch_list = sort @full_branch_list;

    print "Superset of unique branches across all submodules: \n";
   
    foreach my $branch_info (@sorted_full_branch_list)
    {
    
       print "  " . $branch_info . "\n";
    }

  }

}


#
# This is one of the top level functions that maps to a user request to get the list of orphan branches. 
# NOTE: This function also maps to the user request to get the list of branches that exist in all repos (no orphans)
# An orphan branch is one where a branch exists in at least one repo/submodule but not in all repos/submodules 

# Note: the presence of the flag: $exists_in_all_flag will invert the functionality.  Instead of listing the orphans
# this will list the branches that exist in all repos

sub orphan_info()
{

  #print "Value of exists in all flag: " .  $exists_in_all_flag . "\n";

  # this should list all branches in any repo where the particular branch does not also exist in the root repo.

  # get the list of root repo branches
  
  # for each submodule, get the list of all branches and only display the branches that do not exist in the parent. 

  # get a list of all branches in each repo... (repo by repo)
  my @nuggit_branch_info = get_branch_info();  # this returns a basic data structure (array) that contains an entry 
                                               # for each repo/submodule and an array for that repo containing a list 
                                               # of all the branches
  
  # create an empty list/array of unique branches.  This will be the super set of all branches in all repos  
  my @full_branch_list = get_full_branch_list(\@nuggit_branch_info);

  my @orphan_branch_info;
  @orphan_branch_info  = get_orphan_branch_info(\@nuggit_branch_info, \@full_branch_list);    # this is an array
                                                                # one entry for each branch, it contains a hash
                                                                # with the branch name, its orphan status
                                                                # number of repos where the branch was found
                                                                # number of repos where the branch was not found
                                                                # an array containing a list of repos where the branch
                                                                # was found, and an array containing a list of repos where
                                                                # the branch was not found.

# figure out what the output.  A few possibilties exist
#  $orphans_flag 
#       or compliment: $exists_in_all_flag
#  $orphan_branch
#      Either
#         $exists_in_flag    = 1
#         or
#         $missing_from_flag = 1
#      or 
#         $exists_in_flag    = 0
#         and
#         $missing_from_flag = 0
#      
  
  if($show_json)
  {
     # for JSON output, output the full json.  let the receiver grab what they want
     # output for machine
      say to_json(\@orphan_branch_info, {utf8 => 1, pretty => 1});
  }
  elsif($exists_in_all_flag)
  {
    print "List of branches that exist in all repos\n";
    foreach my $branch_info (@orphan_branch_info)
    {
      my $branch_name        = $branch_info->{'branch_name'};
      my $status             = $branch_info->{'orphan_status'};
      my $exists_count       = $branch_info->{'exist_count'};
      my $missing_count      = $branch_info->{'missing_count'};
      my @missing_from_array = $branch_info->{'missing_from_array'};
      
      my $total_repos = $exists_count + $missing_count;
      
      if($missing_count == 0)
      {
        my $pad_str_20 = "                    ";      # temporary string to pad the end of a string we want to print
        my $tmp_str = sprintf("%s%s%s%s%s", $branch_name, 
                         $pad_str_20, $pad_str_20, 
                         $pad_str_20, $pad_str_20);   # create the first column we want to print that is padded out a lot at the end
        my $col1    = substr($tmp_str, 0, 80);        # now just take the first 80 chars, so we can print the next column at a constant location
        print "   $col1";
        print "Missing from $missing_count of $total_repos repos\n";
      }
    }
  }
  elsif($orphans_flag) # output for human
  {
    print "List of orphan branches (that do not exist in all repos)\n";
    foreach my $branch_info (@orphan_branch_info)
    {
      my $branch_name        = $branch_info->{'branch_name'};
      my $status             = $branch_info->{'orphan_status'};
      my $exists_count       = $branch_info->{'exist_count'};
      my $missing_count      = $branch_info->{'missing_count'};
      my @missing_from_array = $branch_info->{'missing_from_array'};
      
      my $total_repos = $exists_count + $missing_count;
      
      if($missing_count != 0)
      {
        my $pad_str_20 = "                    ";      # temporary string to pad the end of a string we want to print
        my $tmp_str = sprintf("%s%s%s%s%s", $branch_name, 
                         $pad_str_20, $pad_str_20, 
                         $pad_str_20, $pad_str_20);   # create the first column we want to print that is padded out a lot at the end
        my $col1    = substr($tmp_str, 0, 80);        # now just take the first 80 chars, so we can print the next column at a constant location
        print "   $col1";
        print "Missing from $missing_count of $total_repos repos\n";
      }
    }
  }
  elsif($orphan_branch)
  {
    print "A branch was specified - to do get details\n";

    if($exists_in_flag)
    {
       # show which repos the $orphan_branch exists in
       print "to do show the repos where $orphan_branch exists\n";
    }
    elsif($missing_from_flag)
    {
       # show which repos the $orphan_branch is missing from
       print "to do show the repos where $orphan_branch does not exist\n";       
    }
    else
    {
      # show full details of the specified branch... which repos does the branch exist in, which repos is the branch missing from
      #   $exists_in_flag    = 0
      #         and
      #   $missing_from_flag = 0
      print "to do show the details of branch $orphan_branch\n";
    }
    
  }
  else
  {
    print "Not sure what to do\n";
  }
}




sub list_unmerged_recursive()
{

   my $flags = "";
   
   if($show_all_flag)
   {
     $flags = $flags . " --all ";
   }
   $flags = $flags . " --no-merged ";   

#   print "FLAGS: $flags\n";

   # root repo
   my $root_repo_branches  = `git branch $flags`;

   # split this on new lines and add items to array
   my @root_repo_lines = split('\n', $root_repo_branches);

   my @full_branch_list;
   foreach my $branch (@root_repo_lines)
   {
     if(!is_item_in_array(\@full_branch_list, $branch) )
     {
       push(@full_branch_list, $branch);
     }
   }

   my $sub_module_branches = `git submodule foreach --recursive git branch $flags`;
   my @submodule_repo_lines = split('\n', $sub_module_branches);
   # for each entry if the entry does not start with "Entering" check if it is in the array, if not, add it

   foreach my $branch (@submodule_repo_lines)
   {
     if($branch =~ /^Entering/ )  # make sure line does not start with "Entering <directory/submodule>"
     {
       #print "  Going into  $branch \n";
     }
     else
     {
       # print "$branch\n";
       if(!is_item_in_array(\@full_branch_list, $branch))
       {
         push(@full_branch_list, $branch);
       }
     }
   }

   my @sorted_branch_array = sort( @full_branch_list );
   print "Branches:\n";
   foreach my $branch (@sorted_branch_array)
   {
     print "  $branch\n";
   }

}
