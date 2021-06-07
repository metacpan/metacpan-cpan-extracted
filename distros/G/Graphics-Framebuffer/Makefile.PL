#!/usr/bin/env perl

use 5.008;
use strict;
use warnings FATAL => 'all';
use Config;
use Inline::MakeMaker;
use Term::ANSIColor;

if (defined($ENV{'DISPLAY'})) {
    print "\n\n",
      colored(['white on_red'],'******************************************************************************'),"\n",
      colored(['white on_red'],'* Graphics::Framebuffer should not be installed from within X-Windows!  You  *'),"\n",
      colored(['white on_red'],'* should install it from the console itself, and not a console window.       *'),"\n",
      colored(['white on_red'],'******************************************************************************'),"\n",
      colored(['black on_yellow'],'If you insist on installing from within X-Windows, please keep in mind that   '),"\n",
      colored(['black on_yellow'],'the tests will show nothing, as they will be unable to draw to the screen,    '),"\n",
      colored(['black on_yellow'],'since X-Windows is using it.  Thus the tests will run in emulation mode only. '),"\n";
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
my $top  = '  ' . colored(['bright_green'],'/                       /');
my $mid  = ' ' . colored(['bright_green'],'/ ') . colored(['bright_yellow'],'Graphics::Framebuffer') . colored(['bright_green'],' /');
my $btm  = colored(['bright_green'],'/                       /');
my $logo = colored(['on_red'],'   ') . colored(['on_green'],'   ') . colored(['on_blue'],'   ') . "$top\n";
$logo   .= colored(['bold white on_red'],' G ') . colored(['bold white on_green'],' F ') . colored(['bold white on_blue'],' B ') . "$mid\n";
$logo   .= colored(['on_red'],'   ') . colored(['on_green'],'   ') . colored(['on_blue'],'   ') . "$btm\n";
my $line = '------------------------------------------------------------------------------';
print $logo,colored(['cyan on_cyan'],$line),"\n";

# Process the src files
my $ccode = slurp_file('src/Framebuffer.c');
my $template = slurp_file('src/Framebuffer.pm.template');
if ($template =~ /^(.*?)\n/s) {
    print colored(['bright_yellow'],'Inserting versions'), ' ... ';
    my ($version, $month, $day, $year) = split(/\s/, $1 );
    $template =~ s/^.*?\n//s;
    $template =~ s/\#\# VERSION \#\#/$version/sg;
    $template =~ s/\#\# VERSION DATE \#\#/$month $day $year/sg;
    $template =~ s/\#\# YEAR \#\#/$year/sg;
    $template =~ s/\#\# TEMP COPYRIGHT \#\#.*?\#\# TEMPCOPYRIGHT \#\#//sg;
    print colored(['bright_green'],"Version: $version, $month $day $year"),"\n";
}
print colored(['bright_yellow'],'Adding C to Module') . ' ...';
$template =~ s/\#\# C CODE \#\#/$ccode/s;

open(my $FILE,'>','lib/Graphics/Framebuffer.pm');
print $FILE $template;
close($FILE);

print colored(['bright_green'],' Added'),"\n";

WriteMakefile(
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
        'Test::More' => '1.00',
        'List::Util' => '1.20',
    },
#    PREREQ_FATAL   => 1,
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
    clean => {FILES    => 'Graphics-Framebuffer* _Inline* examples/_Inline* *log lib/Graphics/Framebuffer.pm'},
);
print colored(['cyan on_cyan'],$line),"\n";
print "The ",'"', colored(['bold green'],'examples'), qq{" directory has some handy scripts to help get you started, and\nshow you how to use the module.  Just "} . colored(['bold green'],'perldoc') . qq{" on each to see how to use\nthem:\n};

my $message = qq{
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
=========================== MULTIPROCESSING ==================================
threaded_primitives.pl - A threaded version of the above.  It can make a mess
                         of the screen.  Requires Sys::CPU.

threaded_slideshow.pl  - This script shows all of the images in a specific
                         path.  It divides your screen by how many threads,
                         and dedicates each to show an image.  Requires
                         Sys::CPU.

threaded_template.pl   - Like the above, but for threading.  Requires Sys::CPU

get-mce-demos          - Go and grab MCE multiprocessing demos
};

foreach my $l (split(/\n/,$message)) {
    if ($l =~ /^(\S+pl|get-mce-demos)/) {
        my $old = $1;
        my $new = colored(['bold green'],$old);
        $l =~ s/$old/$new/;
    } elsif ($l =~ /^\=/) {
        $l = colored(['bold black on_cyan'],$l);
    }
    print "$l\n";
}
print colored(['blue on_blue'],$line),"\n";

print colored(['bright_white on_magenta'],' Building    -> '),colored(['bright_green'],'  make'),"\n";
print colored(['bright_white on_magenta'],' Testing     -> '),colored(['bright_green'],'  make')," test\n";
print colored(['bright_white on_magenta'],' Installing  -> '),colored(['red'],'  sudo '),colored(['bright_green'],'make')," install\n";
print colored(['bright_white on_magenta'],' Cleaning Up -> '),colored(['bright_green'],'  make')," realclean\n";

exit(0);

sub slurp_file {
    my $file = shift;
    return( do { local (@ARGV, $/) = $file; <> } );
}
