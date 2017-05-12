#!/usr/bin/perl -w
use 5.006001;
use strict;
use vars qw($VERSION $opt_n $opt_y);
$VERSION = "0.05";

use ExtUtils::MakeMaker;
BEGIN {
    @Heap::Simple::implementors = qw(CGI) unless @Heap::Simple::implementors;
}

# Allows to suppress all questions with -n or -y
use Getopt::Std;
getopts("ny") || die "Usage: $0 [-n] [-y]\n";

my $benchmark = 0;
my $benchmark_others = 0;

if (!$opt_n || $opt_y) {
    print <<EOT

   Note that you can avoid these questions by passing
   the '-n' or '-y' option to 'Makefile.PL'.

EOT
;
    $benchmark =
        $opt_y || 
        prompt("Run Heap::Simple benchmarks during 'make test' ?", "n") =~ /^y/i;
    if ($benchmark) {
        $benchmark_others =
            $opt_y || 
            prompt("Benchmarks against other heap modules that happen to be installed on this machine during 'make test' ?", "n") =~ /^y/i;
    }
}
my $option_file = "t/options";
my $new = "$option_file.new.$$";
open(my $fh, ">", $new) || die "Could not open '$new': $!";
printf($fh "BENCHMARK=%d\nBENCHMARK_OTHERS=%d\n",
       $benchmark ? 1 : 0,
       $benchmark_others ? 1 : 0) || die "Error writing to '$new': $!";
eval {
    close($fh) || die "Could not close '$new': $!";
    rename($new, $option_file) ||
        die "Could not rename '$new' to '$option_file': $!";
};
if ($@) {
    $fh = undef;	# close file if open
    unlink($new) || die "Could not unlink '$new': $! after $@";
    die $@;
}

WriteMakefile
    (NAME		=> 'Heap::Simple::XS',
     VERSION_FROM	=> "lib/Heap/Simple/XS/Package.pm",
     PERL_MALLOC_OK	=> 1,
     'PREREQ_PM'	=> {
         "Heap::Simple"	=> 0.09,	# implementor switch
         "Test::More"	=> 0.11,	# For the tests only
     },
     AUTHOR	=> 'Ton Hospel <Heap-Simple-XS@ton.iguana.be>',
     # OPTIMIZE		=> "-g",
     LIBS	=> [''], # e.g., '-lm'
     DEFINE	=> '', # e.g., '-DHAVE_SOMETHING'
     INC	=> '-I.', # e.g., '-I. -I/usr/include/other'
     $^O eq "MSWin32" ? (
         PM_FILTER	=> '$(PERL) -p -e1',
     ) : (),
     clean		=> {
         FILES => '$(DISTNAME).ppd ppm',
     },
);

package MY;
sub postamble {
    return shift->SUPER::postamble() . <<"EOF";
ppm: \$(DISTNAME).ppd

\$(DISTNAME).ppd: all ppd
	makeppd.pl --perl=\$(PERL) --min_version=1.011 --binary --zip=\$(ZIP) --tar=\$(TAR) --compress="\$(COMPRESS)" --leave=ppm \$(DISTNAME).ppd \$(VERSION)

ppm_install: \$(DISTNAME).ppd
	ppm install ppm/\$(DISTNAME).ppd

ppm_upgrade: \$(DISTNAME).ppd
	ppm upgrade -install ppm/\$(DISTNAME).ppd
EOF
}
