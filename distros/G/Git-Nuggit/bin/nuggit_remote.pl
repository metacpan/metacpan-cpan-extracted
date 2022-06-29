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
use Cwd qw(getcwd);
use File::Spec;
use Git::Nuggit;

=head1 SYNOPSIS

nuggit remote set-url [-v | --verbose] <remote name> <new url>
nuggit remote get-url <remote name>

Set-url: Nuggit command to change the URL for the given remote in the root
         nuggit repository and its submodules.  Based on git set-url.
         If the remote is not given, origin is changed by default.

Get-url: Nuggit command to get the URL of each submodule and check if it matches
         the beginning of the root URL.
=cut

sub set_url();
sub get_url();

# quit if the incorrect number of arguments is given
my $numArgs = $#ARGV + 1;
if ($numArgs < 2 || $numArgs > 4) {
	pod2usage(1);
	exit 1;
}

my $get;
my $verbose = 0;
my $name;
my $newurl;

# determine if command is set-url or get-url
if ($ARGV[0] eq 'set-url') {
	$get = 0;
} elsif ($ARGV[0] eq 'get-url') {
	$get = 1;
} else {
	pod2usage(1);
        exit 1;
}

# check for verbose flag
if ($ARGV[1] eq '-v' || $ARGV[1] eq '--verbose') {
	$verbose = 1;	
}

# remote is origin unless two arguments are given (not counting the flag)
if ($numArgs == 3 + $verbose) {
	$name = $ARGV[1 + $verbose];
	$newurl = $ARGV[2 + $verbose];
} else {
	if ($get) {
		$name = $ARGV[1 + $verbose];
		#newurl not used
	} else {
		$name = 'origin';
		$newurl = $ARGV[1 + $verbose];
	}
}

# go to nuggit root
my ($root_dir, $relative_path_to_root) = find_root_dir();
if (!$root_dir) {
	die 'Nuggit root directory not found';
}
chdir $relative_path_to_root || die "Cannot enter directory $relative_path_to_root: $!";

if ($get) {
	get_url();
} else {
	set_url();
}


sub set_url() {
	
	# get root repo name
	my $rootUrl = `git remote get-url $name`;
	$rootUrl =~ m/\/([a-z\-\_A-Z0-9]*)(\.git)?$/;
	my $rootName = $2 ? "$1$2" : "$1";

	# remove repo name from newurl
	# url is invalid if it does not match the pattern
	die 'Url invalid' if $newurl !~ m/\/([a-z\-\_A-Z0-9]*)(\.git)?$/;
	$newurl =~ s/$rootName//;

	# change root url
	print `git remote set-url $name $newurl$rootName`;

	# show change
	if ($verbose) {
		say "$rootName old url: $rootUrl";
		my $newUrl = `git remote get-url $name`;
		say "$rootName new url: $newUrl";
	}

	# change submodule urls
	submodule_foreach(sub {
        		my $submodUrl = `git remote get-url $name`;
			$submodUrl =~  m/\/([a-z\-\_A-Z0-9]*)(\.git)?$/;
			my $submodName = $2 ? "$1$2" : "$1";
			print `git remote set-url $name $newurl$submodName`;

			if ($verbose) {
        			say "$submodName old url: $submodUrl";
        			my $newUrl = `git remote get-url $name`;
        			say "$submodName new url: $newUrl";
			}

      		}
	);
}


sub get_url() {

	# get root url and repo name
	my $rootUrl = `git remote get-url $name`;
	$rootUrl =~ m/\/([a-z\-\_A-Z0-9]*)(\.git)?$/;
	my $rootName = $2 ? "$1$2" : "$1";	

	say "Root: $rootName";
	say "URL: $rootUrl";
	
	# remove root name from url to compare with submodules
	$rootUrl =~ s/$rootName//;

	my $allUrlsMatch = 1;

	# check submodule urls
	submodule_foreach(sub {
			my $submodUrl = `git remote get-url $name`;
                        $submodUrl =~  m/\/([a-z\-\_A-Z0-9]*)(\.git)?$/;
                        my $submodName = $2 ? "$1$2" : "$1";
			$submodUrl =~ s/$submodName//;

			if ($submodUrl ne $rootUrl) {
				$allUrlsMatch = 0;
				say "$submodName does not match root";
				say "$submodUrl";
			}
		}
	);

	if ($allUrlsMatch) {
		say 'All submodule URLs match the root';
	}
}
