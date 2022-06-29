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

=head1 SYNOPSIS

Recursively push changes in root repository and all submodules.

Use "--help" or "--man" to display this help dialog.

Specify "--all" to push all branches, not just the currently checked out one.


The default behavior of this script is to abort after the first error.  Submodules are pushed in a depth-first fashion such that this ensures we do not push a parent submodule after it's parent.  

To ignore errors and attempt to push all repositories anyway, specify "--ignore-errors".  This option should be used with care to avoid avoid leaving the repository in a potentially inconsistent state for other Nuggit users.

=cut

# TODO: Support for explicitly specifying remote and/or branch

use v5.10;
use strict;
use warnings;
use Getopt::Long;
use Cwd qw(getcwd);
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Pod::Usage;
use Getopt::Long;
use Term::ANSIColor;
use Git::Nuggit;

my $ngt = Git::Nuggit->new("run_die_on_error" => 0, "echo_always" => 0) || die("Not a nuggit!");
my $root_dir = do_upcurse();
my $ignore_errors = 0;
my $recurse_submodules = "on-demand";

my ($help, $man, $all_flag);
GetOptions(
           "help"            => \$help,
           "man"             => \$man,
           "all!"            => \$all_flag,
           "ignore-errors!"  => \$ignore_errors, # Pass-through for Git flag, which we force default to be on-demand
          );
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;
$ngt->start(level=> 1);

my $verbose = 0;
my $cwd = getcwd();

chdir $root_dir;

my @errors;

# Note: We explicitly call 'git push' due to ongoing inconsistencies with git's native '--recurse-submodules' flag with nested submodules.
# TODO: This function can be optimized with async/parallel execution, requiring tweaks to error reporting and buffering outputs
$ngt->foreach({'depth_first' => sub {
                   my $in = shift;
                   my $subname = $in->{'subname'} // 'root';
                   my $opts = "";

                   my $branch = get_selected_branch_here();
                   if ($branch =~ /HEAD detached/) {
                       push(@errors, $subname);
                       say colored("Error: $subname is in a DETACHED HEAD. Please resolve before pushing", 'warn');
                       return;
                   }
                   
                   if ($all_flag) {
                       $opts .= "--all ";
                   } else {
                       # TODO: Support for alternate remotes
                       $opts .= "--set-upstream origin $branch";
                   }
                   my ($err, $stdout, $stderr) = $ngt->run("git push $opts");
                   if ($err) {
                       push(@errors, $subname);
                       say colored("Error pushing $subname", 'yellow');
                       say $stdout;
                       say $stderr;

                   } elsif ($stderr !~ /up-to-date/) {
                       say colored("Pushed $subname", 'cyan');
                       say $stdout;
                       say $stderr;
                   }
               },
               'run_root' => 1
               });
if (scalar(@errors) > 0) {
    say colored('Push failed for '.scalar(@errors).' repositories/submodules', 'red');
    say "\t".join(',',@errors);
    die colored('See above for details', 'yellow')."\n";
} else {
    say colored("Push completed succssfully", 'green');
}
    
