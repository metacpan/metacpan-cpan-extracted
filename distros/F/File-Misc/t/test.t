#!/usr/bin/perl -w
use strict;
BEGIN { if($ENV{'IDOCSDEV'}){system '/usr/bin/clear'} }
use File::Misc ':all';
use Test::Toolbox;

# debug tools
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;
# use Test::Toolbox::Idocs;

# plan tests
rtplan 1, autodie=>$ENV{'IDOCSDEV'}, xverbose=>$ENV{'IDOCSDEV'};
my $n0 = 'File::Misc';


# OK, I'm kluding out on the testing for now. This module is entirely developed
# for Unix and I don't have any tests for other operating systems. For now,
# this script just tests if File::Misc has loaded.
rtok $n0, 1;


#------------------------------------------------------------------------------
# done
# The following code is purely for a home grown testing system. It has no
# purpose outside of my own system. -Miko
#
if ($ENV{'IDOCSDEV'}) {
	require FileHandle;
	FileHandle->new('> /tmp/test-done.txt') or
		die "unable to open check file: $!";
	print "[done]\n";
}
#
# done
#------------------------------------------------------------------------------

