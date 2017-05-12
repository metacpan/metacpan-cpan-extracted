use 5.006001;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config qw(%Config);

# Allows to suppress all program installation with -n (library only)
use Getopt::Std;
our $opt_n;
getopts("n") || die "Usage: $0 [-n]\n";

my @programs_to_install;

unless ($opt_n) {
    print <<EOT

This package comes with a sample program that I can try
to install in $Config{installscript}.

   Note that you can avoid this question by passing
   the '-n' option to 'Makefile.PL'.

EOT
;
    push @programs_to_install, "bin/gloss.pl" if
        prompt("Install gloss.pl, a commandline graph layouter ?", "y") =~ /^y/i;
}

for (qw(Graph::Directed Graph::Undirected)) {
    next if eval "require $_";
    print "You don't seem to have the optional '$_' package. Not fatal.\n";
}

my $MIN_VERSION = 3.7;
my $program = $^O eq "MSWin32" ? "pgnuplot" : "gnuplot";
seek(DATA,0,1);	# Old perls needs this
open(STDIN, "<&DATA") || die "Could not dup DATA to STDIN: $!";
my $out = `$program 2>&1`;
if ($? || $out eq "") {
    print "You don't seem to have the optional '$program' program. Not fatal\n";
} elsif ($out =~ /\bVersion\s+(\d+\.\d+)\b/i) {
    my $version = $1;
    print "You have $program version $version, but I wanted at least $MIN_VERSION. Not fatal\n" if $version < $MIN_VERSION;
}

WriteMakefile
    (NAME		=> 'Graph::Layout::Aesthetic',
     VERSION_FROM	=> 'lib/Graph/Layout/Aesthetic.pm',
     PERL_MALLOC_OK	=> 1,
     PREREQ_PM		=> {
         "Test::More"	=> 0.11,	# For the tests only
         # "Graph"	=> 0.50,	# Optional
     },
     ($] >= 5.005 ?
      (AUTHOR		=> 'Ton Hospel <Graph-Layout-Aesthetic@ton.iguana.be>') : ()),
     depend => {
         # Evil hack, probably unportable
         'lib/Graph/Layout/Aesthetic/Include.pm' => 'Makefile.PL gen_include $(H_FILES) typemap
	$(FULLPERL) gen_include lib/Graph/Layout/Aesthetic/Include.pm $(H_FILES) typemap'
     },
     # OPTIMIZE		=> "-g",
     LIBS		=> [''], # e.g., '-lm'
     DEFINE		=> '',   # e.g., '-DHAVE_SOMETHING'
     INC		=> '-I include',
     H			=> [qw(include/aesth.h include/aglo.h
                               include/at_centroid.h include/at_node_level.h
                               include/at_sample.h include/defines.h
                               include/point.h)],
     OBJECT		=> q/$(O_FILES)/,
     EXE_FILES		=> \@programs_to_install,
     );

# For gnuplot
__DATA__
show version
