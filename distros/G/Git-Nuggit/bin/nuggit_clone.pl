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
use FindBin;
use Getopt::Long;
use Pod::Usage;
use Term::ANSIColor;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;
use Git::Nuggit::Log;

=head1 SYNOPSIS

nuggit clone [-b BRANCH_NAME] CLONE_URL_TO_ROOT_REPO


The clone operation will automatically attempt to resolve any detached
HEADs after checkout. By default, nuggit will automatically create
branches matching that of the root repository if one does not already
exist.  This can be bypassed by specifying "--no-auto-create".

=cut

my ($branch, $help, $man, $autocreate);
Getopt::Long::GetOptions(
                         "help"            => \$help,
                         "man"             => \$man,
                         "branch|b=s"      => \$branch,
                         "auto-create!"    => \$autocreate,
                        );
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;



# (1) quit unless we have the correct number of command-line args
my $num_args = $#ARGV + 1;
if ($num_args != 1 && $num_args != 2) {
    pod2usage(1);
    exit 1;
}

my $url=$ARGV[0];  # URL or Path to Clone From
my $repo=$ARGV[1]; # Name of Target Directory (implied from URL/Path otherwise)

#isolate the text between the slash and the .git
#i.e.
#nuggit_clone ssh://git@sd-bitbucket.jhuapl.edu:7999/fswsys/mission.git

if (!$repo) {
    $repo = $url;
    
    # now remove beginning / and ending .git
    $url =~ m/([\w\-\_]+)(\.git)?$/;
    
    $repo = $1;
}

say colored("Cloning $url into $repo", 'success');

my $opts = "";
$opts .= "-b $branch " if defined($branch);


# clone the repository
print `git clone $opts $url --recursive -j8 $repo`;

if ($?) { # Clone exited with an error
    if (-e $repo) {
        say colored("Clone completed with errors.", 'error');
        say colored("Submodules may not be fully initialized.  Please resolve any errors listed above, then run a 'ngt checkout' to attempt to complete submodule initialization (if applicable).", 'warn');
    } else {
        say colored("Clone failed.  See above for details", 'error');
    }
} else { # No error
    # initialize the nuggit meta data directory structure
    chdir($repo) || die "Can't enter cloned repo ($repo)";
    nuggit_init();
    my $log = Git::Nuggit::Log->new(root => '.')->start(1);

    # Resolve any detached HEADs (will automatically print status)
    my $cmd = File::Spec->catfile($FindBin::Bin,"ngt");
    $cmd .= " checkout --safe";
    $cmd .= " --no-auto-create" if defined($autocreate) && !$autocreate;
    system($cmd);
    say "\nClone of $url completed. See above for status.";
}
