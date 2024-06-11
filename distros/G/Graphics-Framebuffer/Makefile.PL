#!/usr/bin/env perl

use 5.020;
use strict;
use warnings FATAL => 'all';
use constant {
    TRUE  => 1,
    FALSE => 0,
};
use Config;
# These should be in Perl's installation already
use Inline::MakeMaker; # Layers on top of ExtUtils::MakeMaker
use Term::ReadKey;
use Term::ANSIColor;

my ($COLS,$ROWS,$w,$h) = GetTerminalSize(*STDOUT);
my $pmt = 'Y';
my $line = '-' x 28 . ' Graphics::Framebuffer ' . '-' x 28;
if (-e 'Makefile') {
	`make veryclean;reset`;
}
# Graphics::Framebuffer
my $banner = slurp_file('examples/banner.vt');
print $banner;
if ($^O =~ /MSWin/i) { # Some people will still try
    print colored(['white on_red']," This module does not work natively on MS Windows.  It will only function in emulation mode, and you will not be able to see the output.  Please read the documentation on emulation mode. \n\n");
    $pmt = ExtUtils::MakeMaker::prompt('Do you really wish to install anyway?  ','N');
} elsif (defined($ENV{'DISPLAY'})) {
    print
      colored(['white on_red'],' ' x 79),"\n",
      colored(['white on_red'],' Graphics::Framebuffer should not be installed from within X-Windows!  You     '),"\n",
      colored(['white on_red'],' should install it from the console itself, and not a console window.          '),"\n",
      colored(['white on_red'],' ' x 79),"\n",
      colored(['black on_yellow'],' ' x 79),"\n",
      colored(['black on_yellow'],' If you insist on installing from within X-Windows, please keep in mind that   '),"\n",
      colored(['black on_yellow'],' the tests will show nothing, as they will be unable to draw to the screen,    '),"\n",
      colored(['black on_yellow'],' since X-Windows is using it.  Thus the tests will run in emulation mode only. '),"\n",
      colored(['black on_yellow'],' ' x 79), "\n\n";
    $pmt = ExtUtils::MakeMaker::prompt('Do you wish to install anyway?  ','Y');
} elsif (no_framebuffer()) {
    print 
      colored(['white on_red'],' Your system does not appear to have a framebuffer device!  This is required '),"\n",
      colored(['white on_red'],' for this library to function.                                               '),"\n\n";
    $pmt = ExtUtils::MakeMaker::prompt('Do you wish to install anyway?  ','Y');
}
unless($pmt =~ /^Y/i) {
    print "\n\nInstall Aborted.\n\n";
    exit(1);
}
# This portion of the code actually merges the C and Perl portions in the "src"
# directory and writes the "lib/Graphics/Framebuffer.pm" file.  The one that is
# there before this operation is merely a placeholder for CPAN, and was created
# when I did a "make dist" for CPAN upload.  Please use the one this file
# creates.

# Why did I do this?  Simple, managing the version and the C code is a lot
# easier this way, and eliminates the Inline::C quirks.


# Process the src files
my $ccode    = slurp_file('src/Framebuffer.c');
my $template = slurp_file('src/Framebuffer.pm.template');
my $Eml;

print colored(['bright_yellow'],' Adding C to Framebuffer.pm') . ' ...';
$template =~ s/\#\# C CODE \#\#/$ccode/s;
print colored(['bright_green']," Added\n");

if ($template =~ /^\# (.*?)\n/s) {
    print colored(['bright_yellow'],'         Inserting versions'), ' ... ';
    my ($version, $date, $email) = split(/\:/, $1 );
    my ($month, $day, $year) = split(/ |, /,$date);
    $template =~ s/^.*?\n//s;
    $template =~ s/\#\# VERSION \#\#/$version/sg;
    $template =~ s/\#\# VERSION DATE \#\#/$date/sg;
    $template =~ s/\#\# YEAR \#\#/$year/sg;
    $email    =~ s/-at-/\@/gi;
    print colored(['bright_green'],"Version: $version, $date"),"\n";
    print colored(['bright_yellow'],'  Finalizing Copyright Year'), ' ... ';
    $template =~ s/\#\# TEMP COPYRIGHT \#\#.*?\#\# TEMPCOPYRIGHT \#\#//sg;
    print colored(['bright_green'],"Copyright 2017-$year Richard Kelsch"),"\n";
    $template =~ s/\#\# EMAIL \#\#/$email/sg;
    $Eml = $email;
    print colored(['bright_yellow'],'                     Author') . ' ... ', colored(['bright_green'],"$email") . "\n";
}

print colored(['cyan'],'Framebuffer.pm Modification'), ' ... ';
open(my $FILE,'>','lib/Graphics/Framebuffer.pm');
print $FILE $template;
close($FILE);
print colored(['bright_green'],'Complete'),"\n";

WriteMakefile(
    NAME               => 'Graphics::Framebuffer',
    AUTHOR             => $Eml,
    VERSION_FROM       => 'lib/Graphics/Framebuffer.pm',
    ABSTRACT_FROM      => 'lib/Graphics/Framebuffer.pm',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.020, # 5.6 (5.006) is considered slow and unstable.  Upgrade
    CONFIGURE_REQUIRES => {
        'Inline::MakeMaker'   => '0.45',
        'ExtUtils::MakeMaker' => '6.52',
        'Term::ANSIColor'     => '0',
        'Term::ReadKey'       => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '1.00',
        'List::Util' => '1.20',
    },
    PREREQ_PRINT   => TRUE,
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
    clean => {FILES    => 'Graphics-Framebuffer* _Inline* examples/_Inline* *log lib/Graphics/Framebuffer.pm *bak *old'},
);
print colored(['cyan on_cyan'],$line),"\n";

my $message;
if ($COLS <= 185) {
    print "The ",'"', colored(['bold green'],'examples'), qq{" directory has some handy scripts to help get you started, and\nshow you how to use the module.  Just "} . colored(['bold green'],'perldoc') . qq{" on each to see how to use\nthem:};
    $message = qq{
------------------------------------------------------------------------------
primitives.pl          - This script will pretty much demonstrate all of
                         the capabilities of this module.
slideshow.pl           - This script shows all of the images in a specific
                         path (full screen, if asked).
viewpic.pl             - This script shows one specific image (or animation).
dump.pl                - This script does a diagnostic variable dump to the
                         file 'dump.log', for the author to help you with
                         troubleshooting.
fonts.pl               - This script prints installed font names.
text_mode.pl           - A rescue script to force the tty into text mode.
template.pl            - A skeleton single-tasking script shell for you to use
                         as as template.  Do not edit this, but instead copy
                         it.
----------------------------- MULTIPROCESSING --------------------------------
threaded_primitives.pl - A threaded version of the above.  It can make a mess
                         of the screen.  Requires Sys::CPU.
threaded_slideshow.pl  - This script shows all of the images in a specific
                         path.  It divides your screen by how many threads,
                         and dedicates each to show an image.  Requires
                         Sys::CPU.
threaded_template.pl   - Like the above, but for threading.  Requires
                         Sys::CPU
get-mce-demos          - Go and grab MCE multiprocessing demos (an alternate
                         threading method using only one instance of GFB)
};
} else {
    my $pad = int(($COLS - 21)/2);
    my $mult = '-' x $pad . '-- MULTIPROCESSING --' . '-' x $pad;
    print "The ",'"', colored(['bold green'],'examples'), qq{" directory has some handy scripts to help get you started, and show you how to use the module.  Just "} . colored(['bold green'],'perldoc') . qq{" on each to see how to use them:\n};
    $message = '-' x $COLS . qq{
primitives.pl          - This script will pretty much demonstrate all of the capabilities of this module.
slideshow.pl           - This script shows all of the images in a specific path (full screen, if asked).
viewpic.pl             - This script shows one specific image (or animation).
dump.pl                - This script does a diagnostic variable dump to the file 'dump.log', for the author to help you with troubleshooting.
fonts.pl               - This script prints installed font names.
text_mode.pl           - A rescue script to force the tty into text mode.
template.pl            - A skeleton single-tasking script shell for you to use as as template.  Do not edit this, but instead copy it.
$mult
threaded_primitives.pl - A threaded version of the above.  It can make a mess of the screen.  Requires "Sys::CPU".
threaded_slideshow.pl  - This script shows all of the images in a specific path.  It divides your screen by how many threads, and dedicates each to show an image.  Requires "Sys::CPU".
threaded_template.pl   - Like the above, but for threading.  Requires "Sys::CPU"
get-mce-demos          - Go and grab MCE multiprocessing demos (an alternate threading method using only one instance of a GFB object)
};
}

foreach my $l (split(/\n/,$message)) {
    if ($l =~ /^(\S+pl|get-mce-demos)/) {
        my $old = $1;
        my $new = colored(['bold green'],$old);
        $l =~ s/$old/$new/;
    } elsif ($l =~ /^-------/) {
        $l = colored(['bold cyan'],$l);
    }
    print "$l\n";
}
print colored(['blue on_blue'],$line),"\n";

print colored(['bright_white on_magenta'],' Building    -> '),colored(['bright_green'],'       make'),"\n";
print colored(['bright_white on_magenta'],' Testing     -> '),colored(['bright_green'],'       make')," test\n";
print colored(['bright_white on_magenta'],' Installing  -> '),colored(['red'],'  sudo '),colored(['bright_green'],'make')," install\n";
print colored(['bright_white on_magenta'],' Cleaning Up -> '),colored(['bright_green'],'       make')," veryclean\n";

exit(0);

sub slurp_file {
    my $file = shift;
    return( do { local (@ARGV, $/) = $file; <> } );
}

sub no_framebuffer {
    my $fb_absent = TRUE;
    foreach my $device (0 .. 31) {
        foreach my $prefix (qw( /dev/fb /dev/fb/ /dev/graphics/fb/ )) {
            if (-e "$prefix$device") {
                $fb_absent = FALSE;
                print colored(['bright_yellow'],'                FRAMEBUFFER'), ' ... ', colored(['bright_green'],'FOUND'), ' - ', colored(['cyan'],"$prefix$device"),"\n";
            }
        }
    }
    if ($fb_absent) {
        print colored(['bright_yellow'],'                FRAMEBUFFER'), ' ... ', colored(['bright_red'],'NOT FOUND'),"\n";
    }
    return($fb_absent);
}

__END__
  
=pod

Copyright (C) 2013-2023 Richard Kelsch
All Rights Reserved

=cut
