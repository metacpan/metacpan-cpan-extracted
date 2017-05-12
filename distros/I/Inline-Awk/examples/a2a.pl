#!/usr/bin/perl -w

###############################################################################
#
# a2a : a utility to convert an awk program to an Inline::Awk program.
#
# Usage: a2a awkfile [perlfile]
#                     perlfile is optional. The default is awkfile.pl
#
# reverse('©'), November 2001, John McNamara, jmcnamara@cpan.org
#

use strict;
use Config;

my    $awk_file = shift       || die "Usage: a2a awkfile [perlfile]\n";
my    $perlfile = shift       ||     "$awk_file.pl";

open  AWK_FILE, $awk_file     or die "Couldn't open $awk_file. $!\n";
open  PERLFILE, ">$perlfile"  or die "Couldn't open $perlfile.pl. $!\n";

my    $awk_code = do {local $/; <AWK_FILE>};


print PERLFILE  "$Config{startperl} -w\n\n" .
                "use Inline AWK;\n"       .
                "use strict;\n\n"       .
                "awk();\n\n\n"        .
                "__END__\n"         .
                "__AWK__\n\n"      ;

print PERLFILE  $awk_code;

close AWK_FILE;
close PERLFILE;

