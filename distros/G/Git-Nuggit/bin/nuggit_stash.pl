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

use strict;
use warnings;
use v5.10;
use Pod::Usage;
use Getopt::Long;
use Data::Dumper; # DEBUG - TODO delete later
use Term::ANSIColor;
use Cwd; # Also Debug
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;
use Git::Nuggit::Status;

=head1 SYNOPSIS

ngt stash [options] <cmd>

Nuggit stash performs a submodule-aware 'stash' operation across all submodules. If there are any changes to be stashed, it will create a new entry in .nuggit/stashes and generate a uniquely named stash in each submodule.  This ensures consistent ngt stash save/pop behavior.

Usgae is largely equivalent to git stash.  Note that, to avoid conflicts with any stash operations performed outside of this tool, Nuggit will mark all messaaes with "NGT-STASH{idx}" which can be seen if running "git stash list". 

Common usage is:
- ngt stash push        Save all current changes in the stash
- ngt stash pop         Pop the last stash created with nuggit
- ngt stash list        List all stashes previously saved with nuggit. 
- ngt stash apply $idx  Apply the specified stash index. Note: Unlike git stash, only the number needs to be specified.
- ngt stash --man       Show the full documentation


=head2 General Options

The following optins are valid for all stash subcommands;

=over

=item --help

Display an abbreviated help menu

=item --man

Display detailed documentation.

=item --verbose

Display additional details.

=back

=head2 Stash Commands

Note: The majority of the commands below are verbatim copies of the underlying git commands, with the descriptions para-phrased from the official Git man pages.

=head3 push

ngt stash save [<pathspec>]

This command saves all uncommitted changes to the stash.  If pathspec is specified, it will be used to filter which files and/or submodules are stashed.  The following options are supported.

=over

=item --patch | -p

Prompt the user to interactively select hunks from the diff between HEAD and the working tree to be stashed.

=item --keep-index | -k

If specified, do not stage any changes already in the index (staged).

=item --include-untracked | u

All untracked files are also stashed and then cleaned up with git clean .

=item --all | -a

All ignored and untracked files are also stashed and then cleaned up with git clean.

=item -m | --message  <message>

Specify a description for this stash.

=back

=head3 list

Display a listing of all stashes known to nuggit.

NOTE: Nuggit maintains it's own listing of nuggits and will not display any stashes created manually with git, nor will it detect if stashes have been cleared outside of nuggit.

=head3 pop

Apply the last stash entry in the list.  If the operation completes without error, it will automatically be dropped.

=head3 apply

Equivalent to pop, except that the entry will not be dropped from the stash listing (internally to Nuggit, or to git).

=head3 drop

=head1 Internal Configuration Format

Nuggit stash configuration is saved to .nuggit/stash in a JSON file containing an object as described below.

Note: This is NOT considered a user configuration file and the format may change in future releases.

- Version.  An integer version number for the nuggt stash configuration version intended to facilitate future updates.
- list - An array of known stashes.  Each entry is an object containing
  - name (optional)
  - idx - Internal index number for automatic naming. Index numbers will never be reused.
  - timestamp - Timestamp stash was created
  - root_commit - SHA of root module commit at time of creation
  - root_timestamp - Timestamp of root module commit at time of creation (included here for reference)
  - branch - The branch checked out in the root module at the time of creation

=head1 TODO

- stash show command (with optional patches)
- stash delete command
- Retrive stash by custom name?
- branch command
- Verify editor prompts will pass through in patch mode, even when using ngt->run
- For disambiguation, support for '--' to seperate arguments, in this case paths
- Stash naming convention
- Stash behvior if run in a folder without any changes to stash (return code, stdout/stderr output)
- Option for specifying a specific set of files or submodules to stash (or to exclude), and/or to add submodule to existing stash set

- Future: Ability to stash changes to submodule references (ie: perform checkout of original reference commit for submodules, when content of submodule is otherwise unmodified)

=cut

my ($help, $man, $verbose, $patch_flag, $force_flag, $keep_index_flag, $all_flag, $stash_msg);

my $ngt = Git::Nuggit->new("run_die_on_error" => 0, "echo_always" => 0) || die ("Not a nuggit"); # Initialize Nuggit & Logger prior to altering @ARGV
my $root_dir = $ngt->root_dir();

GetOptions(
    "help|h"            => \$help,
    "man"             => \$man,
    'verbose|v!' => \$verbose,

    "force|f!"   => \$force_flag,
    # Push specific flags
    "patch|p!"  => \$patch_flag,
    "keep-index|k!" => \$keep_index_flag,
    "all|a!" => \$all_flag,
    "message|m!" => \$stash_msg,
   );
my $mode = shift @ARGV;
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;
$ngt->start(verbose => $verbose, level => 1);
chdir($ngt->root_dir()) || die("Can't enter root_dir\n");

# chdir($ngt->root_dir()) unless ?
# TODO: If we don't chdir root, we can't recurse into submodules for some reason

my $cfg = $ngt->load_config("stash", {
            "version" => 0,
            "list" => [],
            "nextIdx" => 0
           });

if ($mode eq "list" || !$mode) {
    stash_list();
} elsif ($mode eq "save" || $mode eq "push") {
    $stash_msg = shift @ARGV if (scalar(@ARGV) && !$stash_msg);
    stash_push();
} elsif ($mode eq "pop") {
    stash_pop(0, shift(@ARGV) );
} elsif ($mode eq "apply") {
    stash_pop(1, shift(@ARGV) );
} elsif ($mode eq "dbglist") {
    say Dumper(git_stash_list()); # Debug output of stashes in current repo
} elsif ($mode eq "show") {
    stash_show();
} else {
    pod2usage("'$mode' is not a currently supported command of ngt stash.");
}

sub save_config {
    $ngt->save_config($cfg, "stash");
}
sub stash_list {
    # Show listing of Nuggit stashes
    # For each Stash we will store:
    # - index
    # - name [optional]
    # - timestamp   - Timestamp stash was created
    # - root_commit - SHA of root module at time of creation
    # - root_timestamp - Timestamp of root module commit at time of creation (included here for easy reference)
    # - branch - The branch checked out in the root module (and everywhere if using ngt branching scheme) at time of creation
    if (scalar(@{$cfg->{list}})) {
    
        printf colored("%s \t %-25s \t %-40s \t %s \n","info"), "Index", "Date Created", "Origin Branch", "Message";

        for my $entry (@{$cfg->{list}}) {
            #say Dumper($entry); # TODO; user-friendly output
            printf "%d   \t %-25s \t %-40s \t %s \n",
                $entry->{idx},
                $entry->{timestamp},
                $entry->{branch},
                $entry->{msg} // ""
                ;
        }
    } else {
        say "No stashes currently known to nuggit.";
    }
}

# Internal command to get raw listing of stashes known to Git in the current repository
sub git_stash_list
{
    # Syntax for stashes saved without a message:  stash@{$idx}: WIP on $branch: $sha $last_commit_msg
    # Syntax for stashes saved with a message:     stash@{$idx}: On $branch: $msg
    # Nuggit will always save stahes with form:    stash@{$idx}: On $branch: NGT-STASH{$ngtIdx}[ $msg]
    #    where ": $msg" is optional [denoted by brackets above]
    #    and $ngtIdx is a unique nuggit ID saved to $stash_config_file and incremented for each stash. IDs are never reused

    my ($err, $stdout, $stderr) = $ngt->run("git stash list");

    if ($err) {
        return undef;
    }
    my @lines = split('\n', $stdout);
    my $rtv = {};
    for my $line (@lines) {
        my ($stashIdx, $branch, $ngtIdx, $msg) =
        ($line =~ /^stash\@\{(\d+)\}\: On ((?:\(no\ branch\))|(?:[\w\/\_\-]+?))\: NGT\-STASH\{(\d+)\}\s*(.+)?$/);

        if (defined($ngtIdx)) {
            $rtv->{$ngtIdx} = {
                "gitIdx" => $stashIdx,
                "branch" => $branch,
                "ngtIdx" => $ngtIdx,
                "msg"    => $msg
            };
        }
    }
    return $rtv;
}

sub stash_pop
{
    my $apply_only = shift; # If defined, use apply instead of pop
    my $idx = shift; # TODO: Get from commandline @ARGS to allow restoration of stash by name or idx
    
    if (scalar($cfg->{list}) == 0) {
        say "Error: No known Nuggit stashes to pop";
        return;
    }
    my $obj;
    if (defined($idx)) {
        if ($idx > $cfg->{nextIdx} && !$force_flag) {
            die("$idx is not a known Nuggit stash entry\n");
        }
        # Find entry in list with matching idx or give error
        for(my $i = 0; $i < @{$cfg->{list}}; $i++) {
            my $entry=$cfg->{list}[$i];
            if ($entry->{idx} == $idx) {
                $obj = $entry;
                splice(@{$cfg->{list}}, $i, 1);
                last;
            }
        }
        if (!$obj) {
            stash_list();
            die "$idx is not a known Nuggit stash entry idx.\n";
        }
    } else {
        $obj = pop(@{$cfg->{list}});
    }
    my $ngtIdx = $obj->{idx};

    my $cnt = 0;
    my $errs = 0;
    my $cmd = "git stash ";
    $cmd .= ($apply_only ? "apply " : "pop ");
    $ngt->foreach({breadth_first => sub {
                      my $stashes = git_stash_list();
                      if (defined($stashes->{$ngtIdx})) {
                          $cnt++;
                          my ($err, $stdout, $stderr) = $ngt->run($cmd.$stashes->{$ngtIdx}->{'gitIdx'});
                          if ($err) { # TODO/VERIFY that this catches cases of conflict
                              say $stdout if $stdout;
                              say $stderr if $stderr;
                              $errs++;
                          }
                      }
                  },
                  run_root => 1
                 });
    if ($cnt > 0 && $errs == 0) {
        say "Nuggit Stash successfully restored across $cnt submodules";
        save_config() if !$apply_only;
    } elsif ($cnt > 0) {
        say "Nuggit Stash restored with $errs warnings/conflicts across $cnt submodules.  See above for details.";
    } else {
        say "WARNING: No matching stash entries found";
    }
}

sub stash_push
{
    # If no pathspec defined, run on the entire workspace

    # Otherwise (TODO: perhaps make this an option to foreach):
    # - Get a listing of all submodules with full paths relative to root (or absolute paths)
    # - Convert each pathspec into a path relative to root (or an absolute path)
    # - Split said paths into submodule, file.  Latter can be undef if spec applies to the entire submodule/folder
    # - If a directory is specified, mark any submodules beneath it to be stashed in their entirety. Warn if there are conflicts
    # - Sort pathspec by submodule and apply to each submodule, grouping pathspec together into a single command per repo

    chdir($root_dir); # TODO: This step will be skipped if pathspec deefined

    my $ngtIdx = $cfg->{nextIdx}++;
    my $obj = {
        "idx" => $ngtIdx,
        "branch" => get_selected_branch_here(),
        #"root_commit" => $root_commit, # TODO: and associated timestamp (or omit both)
        "timestamp" => scalar localtime(), # VERIFY desired format
    };
    $obj->{msg} = $stash_msg if $stash_msg;

    my $cmd = "git stash push ";
    if ($stash_msg) {
        $cmd .= "-m \"NGT-STASH{".$ngtIdx."} $stash_msg\"";
    } else {
        $cmd .= "-m \"NGT-STASH{".$ngtIdx."}\"";
    }
    # TODO: Flags for patch, [no]keep-index, all, and untracked
    my $cnt = 0; my $errs = 0;
    $ngt->foreach({breadth_first => sub {
                      my ($err, $stdout, $stderr) = $ngt->run($cmd);
                      if ($err) {
                          $errs++;
                          say $stdout if $stdout;
                          say $stderr if $stderr;
                      } elsif ($stdout =~ /No local changes to save/) {
                          # Nothing to save
                      } else {
                          # Assume this was a successful stash
                          $cnt++;
                      }
                  }, "run_root" => 1
                 });

    if ($cnt > 0) {
        push(@{$cfg->{list}}, $obj);
        save_config();
        say "Changes saved with Nuggit Stash Idx $ngtIdx.  Use 'ngt stash pop' or 'ngt stash apply $ngtIdx' to restore.";
    } else {
        say "Nothing to stash";
    }
}

sub stash_show
{
    my $idx = shift @ARGV;
    die "Ngt stash Index must be specified for show command\n" unless defined($idx);
    

    $ngt->foreach({breadth_first => sub {
                       my $in = shift;
                       my $stashes = git_stash_list();
                       if (defined($stashes->{$idx})) {
                           say colored("Stash in ".(defined($in->{subname}) ? $in->{subname} : "root"), 'info');
                           my $cmd = "git stash show ";
                           $cmd .= "-p " if $patch_flag;
                           $cmd .= $stashes->{$idx}->{'gitIdx'};
                           my ($err, $stdout, $stderr) = $ngt->run($cmd);

                           if ($patch_flag && $in->{subname} ) {
                               # Normalize stashed paths
                               my $rel_path = $in->{subname};
                               $rel_path .= '/' unless $rel_path =~ /\/$/;
                               # We are in a sub-module, prepend dir, ie: replace "--- a/FILE" with "--- a/$rel_path/FILE"
                               #  Note; Regex allows for optional ANSI escape sequences when diff includes colorization
                               $stdout =~ s/^((\e\[\d+m)*((\+\+\+)|(\-\-\-))\s[ab]\/)/$1$rel_path/mg;

                           }
                           say $stdout if $stdout;
                           say $stderr if $stderr;
                       }
                  },
                  run_root => 1
                 });

}
