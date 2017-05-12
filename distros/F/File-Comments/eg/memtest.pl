#!/usr/bin/perl -w
###########################################
# check-type
# Mike Schilli, 2005 (m@perlmeister.com)
###########################################
use strict;

use File::Comments;
use Log::Log4perl qw(:easy);
use Getopt::Std;

Log::Log4perl->easy_init($ERROR);

my $snoop = File::Comments->new();

for(1..10000) { 
my $chunks = $snoop->comments($0);
#print "Comments", join ('', @$chunks), "\n";
}

__END__
Some comments following here.
