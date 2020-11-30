#   ____ _               _       __              _ _ _                       
#  / ___| |__   ___  ___| | __  / _| ___  _ __  | (_) |__  _ __  _ __   __ _ 
# | |   | '_ \ / _ \/ __| |/ / | |_ / _ \| '__| | | | '_ \| '_ \| '_ \ / _` |
# | |___| | | |  __/ (__|   <  |  _| (_) | |    | | | |_) | |_) | | | | (_| |
#  \____|_| |_|\___|\___|_|\_\ |_|  \___/|_|    |_|_|_.__/| .__/|_| |_|\__, |
#                                                         |_|          |___/ 
#
# This file lives in ~/projects/check4libpng/lib and should be copied
# from there.
#
# 0.03 2018-09-16
#
# - Use $Config{cc} to get the C compiler
#
# 0.02 2017-07-01
#
# - Remove "Template" stuff
# - Change file to edit
# - Debugging messages all go through "msg".
#
# 0.01 2017-06-28
#
# Old method of checking for libpng recovered from Image::PNG::Libpng
# git commit 50c6032e3f61624736159930026f2b2a306fcd35.

package CheckForLibPng;
use parent Exporter;
our @EXPORT = qw/check_for_libpng/;
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Carp;

our $VERSION = '0.03';

# This uses $Config{cc}, $Config{ldflags} and $Config{ccflags} to try
# to compile a small program which links against libpng.

use Config qw/%Config/;

# If the test compilation doesn't work, edit the following two lines
# to point to your libpng library's location and the location of the
# directory containing the file "png.h".

my $png_lib_dir; # = /usr/local/lib , etc.
my $png_include_dir; # = /usr/local/include, etc.

# The following variable switches on printing of non-error messages

#my $verbose = 1;
my $verbose;

# Debugging messages

sub msg
{
    my (undef, $file, $line) = caller (0);
    if ($verbose) {
	printf ("%s:%d: @_.\n", $file, $line);
    }
}

# Find an executable program called $program in $ENV{PATH}.

sub find_program
{
    my ($program) = @_;
    msg ("looking for $program in \$PATH");
    my $found;
    if ($ENV{PATH}) {
        my @path = split /:/, $ENV{PATH};
        for my $dir (@path) {
	    msg ("Looking in '$dir' for '$program'");
            my $dprogram = "$dir/$program";
            if (-f $dprogram && -x $dprogram) {
		msg ("Found");
                $found = $dprogram;
                last;
            }
	    msg ("Not found");
        }
    }
    else {
	msg ("There is no PATH environment variable");
    }
    return $found;
}

# Look for libpng. If found, return value is a hash ref containing
# keys "libs" and "inc" for the library directory and the include file
# directory of libpng. If not found, return value is the undefined
# value.

sub check_for_libpng
{
    if ($_[0]) {
	$verbose = 1;
    }

    msg ("Debugging messages in 'check_for_libpng' are switched on");

    # $inc is a flag for the C compiler to tell it where to find header
    # files.

    my $inc = '';
    if ($png_include_dir) {
	$inc = "-I $png_include_dir";
    }
    if ($inc) {
	msg ("\$inc is '$inc'");
    }

    # $libs is a flag for the C compiler to tell it where to find library
    # files.

    my $libs = '-lpng -lz -lm';
    if ($png_lib_dir) {
	$libs = "-L $png_lib_dir $libs";
    }
    my $has_pkg_config = find_program ('pkg-config', $verbose);
    if ($has_pkg_config) {
	msg ('I found "pkg-config" in your PATH so I am going to use that to help with the compilation of the C part of this module.');
	my $pkg_config_cflags = `pkg-config --cflags libpng`;
	$pkg_config_cflags =~ s/\s+$//;
	my $pkg_config_ldflags = `pkg-config --libs libpng`;
	$pkg_config_ldflags =~ s/\s+$//;
	if ($pkg_config_cflags) {
	    msg ("Adding '$pkg_config_cflags' to C compiler flags from pkg-config");
	    $inc = "$pkg_config_cflags";
	}
	if ($pkg_config_ldflags) {
	    msg ("Adding '$pkg_config_ldflags' to linker flags from pkg-config");
	    $libs = "$pkg_config_ldflags";
	}
    }

    # A minimal C program to test compilation and running.

    my $test_c = <<'EOF';
#include <stdlib.h>
#include <stdio.h>
#include "png.h"
void fatal_error (const char * message)
{
    fprintf (stderr, "%s.\n", message);
    exit (1);
}

int main ()
{
   png_structp png_ptr;
   png_infop info_ptr;
   FILE * file;
   png_uint_32 libpng_vn = png_access_version_number();
   printf ("%s:%d: IMAGE-PNG LIBPNG VERSION: <<%s>>\n",
	   __FILE__, __LINE__, png_get_libpng_ver (0));
   /* Create a file because there are some CPAN testers who seem to have bogus libpngs. */
/*   file = fopen ("temporary.png", "wb");
   if (! file) {
       fatal_error ("cannot open file");
   }*/
   png_ptr = png_create_write_struct (PNG_LIBPNG_VER_STRING, 0, 0, 0);
   if (! png_ptr) {
       fatal_error ("cannot create write struct");
   }
   info_ptr = png_create_info_struct (png_ptr);
   if (! png_ptr) {
       fatal_error ("cannot create info struct");
   }
//   png_init_io (png_ptr, file);
   return 0;
}
EOF

    # The name of our test program.

    my $exe_file_name = 'png-compile-test';
    my $c_file_name = "$exe_file_name.c";

    # Booleans which record whether our test program could be compiled and
    # run. The default is false.

    my $compile_ok;
    my $run_ok;

    if (! -f $c_file_name && ! -f $exe_file_name) {
	msg ("compiling and running a test program called '$c_file_name'");
	# Get $ldflags and $ccflags from Config.pm.
	my $ldflags = $Config{ldflags};
	#    my $ccflags;
	my $ccflags = $Config{ccflags};
	# The C compiler to use
	my $cc = $Config{cc};
	if (! $cc) {
	    die "I cannot find a C compiler in your \%Config";
	}
	open my $output, ">", $c_file_name
            or die "Error opening file '$c_file_name' for writing: $!";
	print $output $test_c;
	close $output
            or die "Error closing file '$c_file_name': $!";
	my $compile = "$cc $ccflags $inc -o $exe_file_name $c_file_name $ldflags $libs";
	msg ("The compile command is '$compile'");
	$compile_ok = (system ($compile) == 0);
	if ($compile_ok) {
	    $run_ok = (system ("./$exe_file_name") == 0);
	}
	for my $file ($exe_file_name, $c_file_name) {
	    if (-f $file) {
		unlink $file
                or print STDERR <<EOF;
Sorry, but I could not delete a temporary file '$file' 
which I made. Please delete it yourself.
EOF
	    }
	}
    }
    else {
	print STDERR <<'EOF';
 _____ _ _                                   
|  ___(_) | ___   _ __   __ _ _ __ ___   ___ 
| |_  | | |/ _ \ | '_ \ / _` | '_ ` _ \ / _ \
|  _| | | |  __/ | | | | (_| | | | | | |  __/
|_|   |_|_|\___| |_| |_|\__,_|_| |_| |_|\___|
                                           
           _ _ _     _             
  ___ ___ | | (_)___(_) ___  _ __  
 / __/ _ \| | | / __| |/ _ \| '_ \ 
| (_| (_) | | | \__ \ | (_) | | | |
 \___\___/|_|_|_|___/_|\___/|_| |_|
                                   
EOF
	print STDERR <<"EOF";
My compilation test failed due to existing files called one or the
other of '$c_file_name' or '$exe_file_name'. I want to use these
names. Please edit Makefile.PL to make me use different names, or
rename the existing files.
EOF
	return undef;
    }

    if (! $compile_ok || ! $run_ok) {
	print STDERR <<'EOF';
 _ _ _                                     _      __                       _ 
| (_) |__  _ __  _ __   __ _   _ __   ___ | |_   / _| ___  _   _ _ __   __| |
| | | '_ \| '_ \| '_ \ / _` | | '_ \ / _ \| __| | |_ / _ \| | | | '_ \ / _` |
| | | |_) | |_) | | | | (_| | | | | | (_) | |_  |  _| (_) | |_| | | | | (_| |
|_|_|_.__/| .__/|_| |_|\__, | |_| |_|\___/ \__| |_|  \___/ \__,_|_| |_|\__,_|
          |_|          |___/                                                 

I tried to compile and run a small test program in C to see if I could
#include the libpng header file "png.h" and link to the library
"libpng". Somehow or other this didn't work out. If you don't have
libpng on your system, sorry but you need to install this module. 

If you are on Ubuntu Linux, you probably need to do something like

    sudo aptitude install libpng-dev

to install the header file "png.h" for libpng into your system.

If you think you have libpng on your system, please edit the file
"inc/CheckForLibPng.pm" and run "perl Makefile.PL" again. The relevant
lines are right at the top of the file,

my $png_lib_dir;
my $png_include_dir;

Edit these lines to wherever your libpng and png.h files
respectively are to be found, for example

my $png_lib_dir = '/some/strange/directory';
my $png_include_dir = '/somewhere/nobody/knows';

Then run "perl Makefile.PL" again. If you don't see this message, the
process has succeeded.
EOF
	return undef;
    }
    else {
	msg ("The program compiled and ran successfully, so it looks like you have libpng installed in a place where I can find it");
    }

    my %vals;
    $vals{libs} = $libs;
    $vals{inc} = $inc;
    return \%vals;
}

1;
