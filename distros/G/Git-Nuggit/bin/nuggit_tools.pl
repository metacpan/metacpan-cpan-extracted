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

use Getopt::Long;
use strict;
use warnings;
use v5.10;
use Pod::Usage;
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;
use Term::ANSIColor;

=head1 SYNOPSIS

  Invoke a diff or merge tool as appropriate for all repositories.

  nuggit_tools.pl diff
  nuggit_tools.pl merge

  ngt mergetool --tool meld
  ngt difftool --tool kdiff3

Note: The specified tool will be invoked discretely for each repository/submodule.

WARNING: Ensure that the specified tool can run from your current shell. Git may automatically revert to command-line tools if, for example, X11 forwarding is not enabled ona n SSH connection.  For maximum reliability, this command should be executed from a local shell or VNC instance.

WARNING: While diff and merge tool commands will pass through commit and file paths to git, at this time that functionality is NOT submodule aware and may fail for arguments not valid for all submodules.

The following options are supported for all modes:

=over

=item --tool | -t

Use the specified diff/merge tool.  If not specified, git will invokve the default diff.tool.

see "git difftool --tool-help" for details.

=item --prompt | --no-prompt

Determine if a prompt should be generated between each tool invocation.

Note: This flag is used by both the nuggit wrapper per-repository, and for git for each invocation of the tool within a repository.

The default behavior is for no-prompt for merge, and prompts enabled for diffs.

=item --breadth_first

The default behavior is to process submodules in a depth-first manner.  If this flag is specified, processing will start at the top level down instead.

=item --gui | g

This is a pass-through for 'git mergetool -g' or 'git difftool -g' which causes Git to look for the configured tool in the 'guitool' setting instead of the 'tool' setting. 

=back

=cut

use Data::Dumper; # DEBUG

my $ngt = Git::Nuggit->new("echo_always" => 0, "run_die_on_error" => 0) || die("Not a nuggit");
$ngt->start(level => 0);

# TODO: Verify first arg is diff or merge, else show help.

## Process Arguments
my $mode = shift;
my $opts = {"tool" => ''};
$opts->{prompt} = ($mode && $mode eq "merge") ? 0 : 1; # Set default based on mode

Getopt::Long::GetOptions( $opts,
                          "help", "man", "verbose!",
                          "prompt!",
                          "tool|t=s",
                          "breadth_first!",
                          "gui|g!",
                         );
pod2usage(1) if $opts->{help} || !$mode || ($mode ne "merge" && $mode ne "diff");
pod2usage(-exitval => 0, -verbose => 2) if $opts->{man};


my $order = $opts->{'breadth_first'} ? 'breadth_first' : 'depth_first';
$ngt->foreach({'run_root' => 1, $order => sub {
                   my $in = shift;
                   my $name = $in->{subname} // '/';
                   my $cmd = "git ${mode}tool ";
                   $cmd .= "--".($opts->{prompt} ? "prompt" : "no-prompt")." ";
                   $cmd .= "-g " if $opts->{gui};
                   $cmd .= "--tool $opts->{tool}" if $opts->{tool};
                   $cmd .= join(' ',@ARGV) if @ARGV; # Append any trailing arguments

                   if ($opts->{prompt}) {

                       say "About to perform $mode tool operation on ". colored($name,'info');
                       say "\t :> $cmd";
                       say "Press 'q' to abort operation, 's' to skip this repository only, or any other key to continue.";
                       my $ans = <STDIN>; chomp($ans);
                       if ($ans eq 'q') {
                           die "Aborted by user request\n";
                       } elsif ($ans eq "s") {
                           say colored("\t Skipping $name",'warn');
                           return;
                       }
                   }


                   my ($err, $stdout, $stderr) = $ngt->run({'echo_always' => 1}, $cmd);

               }});

