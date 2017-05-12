#
# $Id: Build.PL,v 1.2 2008/07/09 22:14:17 mprewitt Exp mprewitt $
#
use strict;
use warnings;

use Module::Build;
#use Getopt::Long;
use File::Copy;

my $build = Module::Build->new(
    module_name       => 'File::SmartTail',
    license           => 'perl',
    dist_author       => 'DMJA, Inc <smarttail@dmja.com>',
    dist_abstract     => 'Local and Remote Tail Library',
    dist_version_from => 'lib/File/SmartTail/Version.pm',
    script_files      => ['rtail.pl'],
    auto_features     => {
        log4perl_support => {
            description => "Log4perl logging",
            requires    => { 'Log::Log4perl' => 0 },
        },
    },
);
print STDERR "Setting up default logger...\n";
unlink('lib/File/SmartTail/Logger.pm') if -f 'lib/File/SmartTail/Logger.pm';
if ($build->feature('log4perl_support') || $build->args('log4perl')) {
    copy("lib/File/SmartTail/Log4perlLogger.pm","lib/File/SmartTail/Logger.pm");
    print STDERR "  Using log4perl logger\n";
} else {
    copy("lib/File/SmartTail/NullLogger.pm","lib/File/SmartTail/Logger.pm");
    print STDERR "  Using null logger, run perl Build.PL --log4perl=1 to use log4perl...\n";
}

$build->create_build_script;
