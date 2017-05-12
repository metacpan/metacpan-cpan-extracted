
######################################################################
#
#   Directory Digest -- Scripts.PL
#   Matthew Gream (MGREAM) <matthew.gream@pobox.com>
#   Copyright 2002 Matthew Gream. All Rights Reserved.
#   $Id: Scripts.PL,v 0.90 2002/10/21 20:24:06 matt Exp matt $
#    
######################################################################

my $CODE_DIRECTORY = "code";
use Config;
use File::Basename qw(basename dirname);
chdir(dirname($0));
my $file = join(' ', @ARGV);
my $code = "$CODE_DIRECTORY/$file";
open IN, "<$code" or die "Can't read $code: $!";
open OUT,">$file" or die "Can't create $file: $!";
chmod(0755, $file);
print "Extracting $file (with variable substitutions)\n";
print OUT <<"!GROK!THIS!";
$Config{'startperl'} -w
!GROK!THIS!
$/ = "\n";
my @as = <IN>;
close IN;
shift @as;
$" = "\n";
print OUT @as;
close OUT;

