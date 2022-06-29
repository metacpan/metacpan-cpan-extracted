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

Display submodule-aware status of project.

   nuggit status

=over

=item --help

Display an abbreviated help menu

=item --man

Display detailed documentation.
--
=item --uno | -u

Ignore untracked files

=item --ignored

Show ignored files

=item --json

Show raw status structure in JSON format.

=back

=head2 Output Details

=head3 Submodule State

If a submodule's checked out commit does not match the committed reference, the status will show as "Delta-Commits".  If the "--details" or "-d" flag is specified, then details will be shown on both the currently checked out commit in this submodule, and the commit that the parent repository references.

If a submodule's checked out commit is out of sync with the upstream branch, it will show as "Upstream-Delta( +x -y )" where x is the number of commits that the local copy is ahead of the remote, and y is the number of commits the upstream branch is ahead of the local version.  Note: Users should run "ngt fetch" prior to status to ensure an accurate reflection of the current Upstream state. 

=head2

=cut

use strict;
use warnings;
use v5.10;
use Getopt::Long;
Getopt::Long::Configure ("bundling"); # ie: to allow "status -ad"
use Pod::Usage;
use Cwd qw(getcwd);
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Data::Dumper; # Debug and --dump option
use Git::Nuggit;
use Git::Nuggit::Status;

# The following flags are currently DEPRECATED, but may be re-added in the future
my $cached_bool = 0; # If set, show only staged changes
my $unstaged_bool = 0; # If set, and cached not set, show only unstaged changes

my $verbose = 0;
my $do_dump = 0; # Output Dumper() of raw status (debug-only)
my $do_json = 0; # Output in JSON format
my $flags = {
             "uno" => 0, # If set, ignore untracked objects (git -uno command). This has no effect on cached or unstaged modes (which always ignore untracked files)
             "ignored" => 0, # If set, show ignored files
             "all" => 0, # If set, show all submodules (even if status is clean)
            };
my $color_submodule = 'yellow';

my ($help, $man);
my $rtv = Getopt::Long::GetOptions(
    "help|h"            => \$help,
    "man"             => \$man,
    "cached|staged"  => \$cached_bool, # Allow --cached or --staged
    "unstaged"=> \$unstaged_bool,
    "verbose|v!" => \$verbose,
    "uno|u!" => \$flags->{uno},
    "ignored!" => \$flags->{ignored},
    'dump' => \$do_dump,
    'json' => \$do_json,
    'all|a!' => \$flags->{all},
    'details|d!' => \$flags->{details},
   );
if (!$rtv) { pod2usage(1); die("Unrecognized options specified"); }

$flags->{verbose} = $verbose;
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;


my $root_repo_branch;

my ($root_dir, $relative_path_to_root, $user_dir) = find_root_dir();
die("Not a nuggit!\n") unless $root_dir;
$flags->{'user_dir'} = $user_dir; # For pretty-printing relative paths

print "nuggit root dir is: $root_dir\n" if $verbose;
print "nuggit cwd is ".getcwd()."\n" if $verbose;
print "nuggit relative_path_to_root is ".$relative_path_to_root . "\n" if $verbose;

# Optional: Query status only for specified path
my $argc = @ARGV;
if ($argc == 1) {
    $relative_path_to_root = $ARGV[0];
    say "Changing directory to specified $relative_path_to_root" if $verbose;
    chdir $relative_path_to_root || die "Can't enter directory $relative_path_to_root: $!";
} elsif ($argc == 0) {
    #print "changing directory to root: $root_dir\n" if $verbose;
    chdir $root_dir || die "Can't enter $root_dir";
} else {
    pod2usage( {
                -message => "Error: Only zero or one unnamed arguments supported. You provided $argc",
                -exitval => "1", # Return non-zero to indicate an error
               });
}

# Get Status with specified options
my $status = get_status($flags); # TODO: Flags for untracked? show all?

die("Unable to retrieve Nuggit repository status") unless defined($status);

say Dumper($status) if $do_dump;

if ($do_json) {
    require JSON;
    JSON->import();
    say encode_json($status);
}
else
{
    if (-e "$root_dir/.nuggit/merge_conflict_state") {
        say colored("Nuggit Merge in Progress.  Complete with \"ngt merge --continue\" or \"ngt merge --abort\"",'red');
    }
    pretty_print_status($status, $relative_path_to_root, $flags);
}






