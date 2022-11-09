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
use Term::ANSIColor;
use Cwd qw(getcwd);
use FindBin;
use lib $FindBin::Bin.'/../lib'; # Add local lib to path
use Git::Nuggit;
use Getopt::Long;
use Pod::Usage;

# Initialize Nuggit & Logger prior to altering @ARGV
my $ngt = Git::Nuggit->new("run_die_on_error" => 1, "echo_always" => 1); 
chdir($ngt->root_dir()) || die("Can't enter root_dir\n");

my $opts = {
    "all"      => 0,
    "prune"    => 0,
    "recurse-submodules" => "on-demand",
    "ngtstrategy" => "ref",
};

ParseArgs();

my $cmd_opts = "";
$cmd_opts .= "--prune " if $opts->{prune};
$cmd_opts .= "--all " if $opts->{all};

$cmd_opts .= "--recurse-submodules=".$opts->{'recurse-submodules'}." ";

my $cmd = "git fetch -j8 $cmd_opts";
my ($err, $stdout, $stderr) = $ngt->run($cmd);
if ($err) {
    die colored("Fetch failed. See above for details",'error')."\n";
} else {
    say colored("Note: Fetch executed on-demand only, which is optimal for most cases and is the default behavior. Use 'ngt fetch --branch-first' to force a fetch for all submodules if, for example, fetch/pull commands have been performed outside of ngt, or if paired with other branch-first commands.", 'info') if $opts->{'recurse-submodules'} eq "on-demand";
    say colored("Fetch completed without error", "success");
}


# Parse Input Arguments
sub ParseArgs
{
    Getopt::Long::GetOptions( $opts, 
                              "help",
                              "man",
                              "prune!",
                              "all",
                              "recurse-submodules=s",
                              "ngtstrategy|s=s",
                              "branch-first!",
                              "ref-first!",
        );
    pod2usage(1) if $opts->{help};
    pod2usage(-exitval => 0, -verbose => 2) if $opts->{man};

    if (defined($opts->{'branch-first'})) {
        $opts->{'ngtstrategy'} = 'branch';
    } elsif (defined($opts->{'ref-first'})) {
        $opts->{'ngtstrategy'} = 'ref';
    } elsif (defined($opts->{'ngtstrategy'}) && $opts->{'ngtstrategy'} ne "branch" && $opts->{'ngtstrategy'} ne 'ref') {
        die "Invalid strategy specified.  --ngtstrategy must be 'branch' or 'ref'.  See --man for details.";
    }
    $opts->{'recurse-submodules'} = 'yes' if $opts->{'ngtstrategy'} eq 'branch';


    die("Not a nuggit!\n") unless $ngt;
    $ngt->start(level => 1, verbose => $opts->{verbose}); # Open Logger for loggable-command mode
}



=head1 NAME

nuggit fetch

=head1 SYNOPSIS

nuggit fetch

Fetch commits, branches, and tags.  The parallel flag is automatically utiliazed (-j8) to speed up results when recursing into submodules.

This will fetch all commits and recurse into submodules on-demand when their references have been updated.  Specify "--branch-first" to unconditionally fetch in all submodules.

=head1 OPTIONS

=over 4

=item B<--help>

Display abbreviated usage information.

=item B<--man>

Display the manual page.

=item B<--recurse-submodules> -I<yes|no|on-demand>, B<--ngtstrategy>, B<--branch-first>

The default behavior of 'ngt fetch' is to recurse into submodules on-demand when a commit is retrieved with an updated submodule reference in the parent repository.  This can be overridden to always recurse with "--recurse-submodules=yes" as a pass-through to the native git command, or using the standard Nuggit Strategy argument for '--branch-first' or '--ngtstrategy=branch'.  

=item B<--all>

Fetch is performed against the default remote by default. If multiple remotes have been defined, specify '--all' to fetch from all remotes.

=item B<--prune>

Specify "--prune" to enable detection and removal of branches that have been removed on the remote.  Note this only affects remotes/* entries, and will never prune branches that have been checked out locally.

=back

=cut
