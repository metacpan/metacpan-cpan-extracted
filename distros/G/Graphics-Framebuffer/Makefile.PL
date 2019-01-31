#!/usr/bin/env perl

use 5.008;
use strict;
use warnings FATAL => 'all';
use Config;
use Inline::MakeMaker;

use Term::ANSIColor;

if (defined($ENV{'DISPLAY'})) {
    print "\n\n",colored(['red'],qq(****************************************************************************
        * Graphics::Framebuffer should not be installed from within X-Windows!     *
        *                                                                          *
        * You should install it from the console itself, and not a console window. *
        ****************************************************************************
    )),colored(['yellow'],qq(
        If you insist on installing from within X-Windows, please keep in mind that
        the tests will show nothing, as they will be unable to draw to the screen,
        since X-Windows is using it.  Thus the tests will run in emulation mode only.
    ));
    sleep 1;
}

# This portion of the code actually merges the C and Perl portions in the "src"
# directory and writes the "lib/Graphics/Framebuffer.pm" file.  The one that is
# there before this operation is merely a placeholder for CPAN, and was created
# when I did a "make dist" for CPAN upload.  Please use the one this file
# creates.

# Why did I do this?  Simple, managing the version and the C code is a lot
# easier this way, and eliminates the Inline::C quirks.

my $t = '  ';
my $name = '========================== Graphics::Framebuffer =============================';
my $line = '------------------------------------------------------------------------------';
print "\n",colored(['bright_yellow on_blue'],$name),"\n";

print colored(['bright_yellow'],'Adding C to Module...');
my $ccode = slurp_file('src/Framebuffer.c');
my $template = slurp_file('src/Framebuffer.template.pm');
if ($template =~ /^(.*?)\n/s) {
    my ($version, $month, $day, $year) = split(/\s/, $1 );
    $template =~ s/^.*?\n//s;
    $template =~ s/\#\# VERSION \#\#/$version/sg;
    $template =~ s/\#\# VERSION DATE \#\#/$month $day $year/sg;
    $template =~ s/\#\# YEAR \#\#/$year/sg;
}
$template =~ s/\#\# C CODE \#\#/$ccode/s;

open(my $FILE,'>','lib/Graphics/Framebuffer.pm');
print $FILE $template;
close($FILE);

print colored(['bright_green'],' Added'),"\n";

if (WriteMakefile(
    NAME               => 'Graphics::Framebuffer',
    AUTHOR             => q{Richard Kelsch <rich@rk-internet.com>},
    VERSION_FROM       => 'lib/Graphics/Framebuffer.pm',
    ABSTRACT_FROM      => 'lib/Graphics/Framebuffer.pm',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.008, # 5.6 (5.006) is considered slow and unstable.  Upgrade
    CONFIGURE_REQUIRES => {
        'Inline::MakeMaker'   => 0.45,
        'ExtUtils::MakeMaker' => 4.52,
    },
    BUILD_REQUIRES => {
        'Test::Most' => '0.30',
        'List::Util' => '1.20',
    },
    PREREQ_PRINT   => 1,
    PREREQ_PM      => {
        'Math::Bezier'   => '0.01',
        'Math::Trig'     => '1.10',
        'Math::Gradient' => '0.03',
        'List::Util'     => '1.20',
        'File::Map'      => '0.64',
        'Imager'         => '0.91',
        'Inline'         => '0.53',
        'Inline::C'      => '0.53',
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
    clean => {FILES    => 'Graphics-Framebuffer* _Inline* examples/_Inline* *log'},
)) {
    print colored(['blue on_blue'],$line),"\n";
    print "The ",'"', colored(['bold cyan'],'examples'), qq{" directory (in this package) has some handy scripts to help get\nyou started, and show you how to use the module.  Just 'perldoc' on each to\nsee how to use them:\n\n};

    print $t,colored(['bold green'],'primitives.pl'),"         - This script will pretty much demonstrate all of\n                          the capabilities of this module.\n\n";
    print $t,colored(['bold green'],'threaded_slideshow.pl')," - This script shows all of the images in a specific\n                          path.  It divides your screen by how many threads,\n                          and dedicates a thread to each portion to show an\n                          image.\n\n";
    print $t,colored(['bold green'],'slideshow.pl'),"          - This script shows all of the images in a specific\n                          path (full screen, if asked).\n\n";
    print $t,colored(['bold green'],'viewpic.pl'),"            - This script shows one specific image (or\n                          animation).\n\n";
    print $t,colored(['bold green'],'dump.pl'),"               - This script does a diagnostic variable dump to the\n                          file 'dump.log', for the author to help you with\n                          troubleshooting.\n\n";
    print $t,colored(['bold green'],'fonts.pl'),"              - This script prints installed font names.\n";
    print colored(['blue on_blue'],$line),"\n";

    print colored(['bright_white on_magenta'],' Building   -> '),colored(['bright_green'],'  make'),"\n";
    print colored(['bright_white on_magenta'],' Testing    -> '),colored(['bright_green'],'  make test'),"\n";
    print colored(['bright_white on_magenta'],' Installing -> '),colored(['red'],'  sudo '),colored(['bright_green'],'make install'),"\n";
}

sub slurp_file {
    my $file = shift;
    return( do { local (@ARGV, $/) = $file; <> } );
}
