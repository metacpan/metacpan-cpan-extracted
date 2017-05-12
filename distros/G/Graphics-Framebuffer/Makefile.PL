#!/usr/bin/perl

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

if (WriteMakefile(
    NAME               => 'Graphics::Framebuffer',
    AUTHOR             => q{Richard Kelsch <rich@rk-internet.com>},
    VERSION_FROM       => 'lib/Graphics/Framebuffer.pm',
    ABSTRACT_FROM      => 'lib/Graphics/Framebuffer.pm',
    LICENSE            => 'Artistic_2_0',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.008,
    CONFIGURE_REQUIRES => {
        'Inline::MakeMaker'   => 0.45,
        'ExtUtils::MakeMaker' => 6.52,
    },
    BUILD_REQUIRES => {
        'Test::Most' => '0.30',
        'List::Util' => '1.20',
    },
    PREREQ_PM      => {
        'Math::Bezier'   => '0.01',
        'Math::Trig'     => '1.10',
        'Math::Gradient' => '0.03',
        'List::Util'     => '1.20',
        'Sys::Mmap'      => '0.16',
        'Imager'         => '0.91',
        'Inline'         => '0.53',
        'Inline::C'      => '0.53',
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
    clean => {FILES    => 'Graphics-Framebuffer* _Inline* examples/_Inline*'},
)) {

    print "\nNow run:\n\n\t",colored(['bold green'],'make'),"\n";
    print "\nUse to test:\n\n\t",colored(['bold green'],'make test'),"\n\nUse to install (you may need to do it as root with sudo):\n\n\tsudo ",colored(['bold green'],'make install'),"\n\n";
    print qq{The "examples" directory (in this package) has some handy scripts to help get\nyou started, and show you how to use the module.  Just 'perldoc' each to see\nhow to use them:\n\n};

    print "\t",colored(['bold green'],'primitives.pl'),"\t- This script will pretty much demonstrate all of the\n\t\t\t  capabilities of this module.\n\n";
    print "\t",colored(['bold green'],'threadstest.pl'),"\t- This script demonstrates how to use the module in a\n\t\t\t  threading environment.\n\n";
    print "\t",colored(['bold green'],'slideshow.pl'),"\t- This script shows all of the images in a specific path.\n\t\t\t  It automatically detects all of your framebuffer\n\t\t\t  devices, and dedicates a thread to each.\n\n";
    print "\t",colored(['bold green'],'viewpic.pl'),"\t- This script shows one specific image (or animation).\n\n";
    print "\t",colored(['bold green'],'dump.pl'),"\t\t- This script does a diagnostic variable dump to STDERR\n\t\t\t  for the author to help you with troubleshooting.\n\n";
    print "\t",colored(['bold green'],'fonts.pl'),"\t- This script prints installed font names.\n\n";
}
