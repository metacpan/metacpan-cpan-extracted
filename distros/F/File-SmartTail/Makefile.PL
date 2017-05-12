#  $Id: Makefile.PL,v 1.8 2008/07/09 22:14:35 mprewitt Exp mprewitt $
#

use ExtUtils::MakeMaker;
use Getopt::Long;
use File::Copy;

my $opt_log4perl;

GetOptions(
    "log4perl"=>\$opt_log4perl,
);

print STDERR "Setting up default logger...\n";
unlink('lib/File/SmartTail/Logger.pm') if -f 'lib/File/SmartTail/Logger.pm';
if ($opt_log4perl) {
    copy("lib/File/SmartTail/Log4perlLogger.pm","lib/File/SmartTail/Logger.pm");
    print STDERR "  Using log4perl logger\n";
} else {
    copy("lib/File/SmartTail/NullLogger.pm","lib/File/SmartTail/Logger.pm");
    print STDERR "  Using null logger, run perl Makefile.PL --log4perl to use log4perl...\n";
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile (
    ABSTRACT    => 'Local and Remote Tail Library',
    AUTHOR      => 'DMJA, Inc <smarttail@dmja.com>',
    NAME	=> 'File::SmartTail',
    DISTNAME	=> 'File-SmartTail',
    VERSION_FROM => 'lib/File/SmartTail/Version.pm',
    EXE_FILES	=> [ 'rtail.pl' ],
    PL_FILES    => {},
    DEFINE      => '-DMAKEFILE_PL_VER=' . (qw$Revision: 1.8 $)[1],
    dist        => { COMPRESS=>'gzip -9f', SUFFIX => 'gz',
                     ZIP=>'/usr/bin/zip',ZIPFLAGS=>'-rl'},
);
