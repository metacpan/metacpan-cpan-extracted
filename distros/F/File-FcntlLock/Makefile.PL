#!/usr/bin/perl

# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# Copyright (C) 2002-2014 Jens Thoms Toerring <jt@toerring.de>


use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;


# We need a compiler and, of course, a system that has a fcntl(2) system
# call. Check for both. Then set up things to also create the Pure and
# Inline sub-modules if possible.

check_for_compiler( );
check_for_fcntl( );
link 'lib/File/FcntlLock.pod', 'lib/File/FcntlLock/XS.pod';
assemble_inline( ) if assemble_pure( );


# Finally create the Makefile

WriteMakefile(
    NAME          => 'File::FcntlLock',
    VERSION_FROM  => 'lib/File/FcntlLock.pm',
    ABSTRACT_FROM => 'lib/File/FcntlLock.pod',
    LICENSE       => 'perl',
    AUTHOR        => 'Jens Thoms Toerring jt@toerring.de',
    PREREQ_PM     => { POSIX      => 0,
                       Errno      => 0,
                       Carp       => 0,
                       Exporter   => 0,
                       DynaLoader => 0,
                       Config     => 0 },
    test          => { TESTS => 't/*.t' },
	clean         => { FILES => join ' ', qw{ lib/File/FcntlLock/XS.pod
											  lib/File/FcntlLock/Pure.pm
											  lib/File/FcntlLock/Inline.pm
											  lib/File/FcntlLock/Pure.pod
											  lib/File/FcntlLock/Inline.pod } }
			 );


###########################################################
# Function for testing if the C compiler used for buildimg Perl is
# available on the system, otherwise there's no chance of building
# the module

sub check_for_compiler {
	print "Checking if there's a C compiler\n";

    open my $fh, '>', 'cc_test.c'
        or die "Failed to open a file for writing: $!\n";
    print $fh "int main(void)\n{\nreturn 0;\n}\n";
    close $fh;

    if ( system "$Config{cc} $Config{ccflags} -o cc_test cc_test.c" ) {
        unlink 'cc_test.c';
        die "Can't run C compiler '$Config{cc}'\n";
    }
    unlink 'cc_test';
    unlink 'cc_test.c';
}


###########################################################
# Function for testing if the system has a fcntl(2) function,
# without it this module makes no sense at all.

sub check_for_fcntl {
	print "Checking if there's a fcntl(2) system call\n";

    open my $fh, '>', 'fcntl_test.c'
        or die "Failed to open a file for writing: $!\n";
    print $fh <<EOF;
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
int main( void ) {
    int fd = fileno( fopen( "fcntl_test.c", "r" ) );
    struct flock f;
    f.l_type   = F_RDLCK;
    f.l_whence = SEEK_SET;
    f.l_start  = 0;
    f.l_len    = 0;
    return fcntl( fd, F_SETLK, &f ) != -1 ? EXIT_SUCCESS : EXIT_FAILURE;
}
EOF
    close $fh;

    if ( system "$Config{cc} $Config{ccflags} -o fcntl_test fcntl_test.c" ) {
        unlink 'fcntl_test.c';
        die "OS unsupported\n";
    }
    unlink 'fcntl_test';
    unlink 'fcntl_test.c';
}


###########################################################
# Function for assembling a "pure Perl" version of the module.
# For that we need to determine the layout of the C flock struct
# used by fcntl(2) and create some Perl code that can fill in such
# a structure via pack() and retrieve its values using unpack().
# This code then is combined with the template file 'Pure/Pure.tmpl'
# to make up the required module. (Failure is not a big issue,
# there are two other ways of attempting to use fcntl(2), one via
# an XS based module and one that attempts to obtain the same kind
# of information in its BEGIN block.)
# Note: there seem to be some 32-bit systems, where the flock struct
#       contails 64-bit off_t members, but there's no 'q' format for
#       Perl's pack() and unpack() function. For these systems I do
#       not know of any proper way of setting up the flock structure
#       using pure Perl...

sub assemble_pure {
    use File::Copy;

	my $success = 0;

    return 0 unless chdir 'Pure_build';

	# Compile with the 'NO_Q_FORMAT' macro defined unless Perl supports
	# the 'q' format for pack() and unpack(). If the system uses a 64-bit
	# off_t type in its flock struct this will make the program for con-
    # structing the code for assembling and disassembling the flock struct
	# output nothing and we abandon trying to  build the "pure Perl" modules.

	my $qflag = eval { pack 'q', 1; };
	$qflag = $@ ? '-DNO_Q_FORMAT' : '';

    goto FAIL
        if system "$Config{cc} $Config{ccflags} $qflag -o builder builder.c";
    goto FAIL unless copy 'Pure.tmpl', 'Pure.pm';
    goto FAIL unless open my $out, '>>', 'Pure.pm';
    goto FAIL unless open my $in, "-|", './builder';
	unless ( my $line = <$in> ) {
		close $in;
		close $out;
		goto FAIL;
	} else {
		print $out $line;
	}

    print $out $_ for <$in>;
    close $in;

    print $out "\n\n1;\n";
    close $out;

    goto FAIL unless move 'Pure.pm', '../lib/File/FcntlLock';

	link '../lib/File/FcntlLock.pod', '../lib/File/FcntlLock/Pure.pod';

	$success = 1;

  FAIL:
	print   "Warning: Support for modules `File::FcntlLock::Pure' and "
		  . "`File::FcntlLock::Inline' had to be disabled\n"
		unless $success;
    unlink 'builder';
    chdir '..';

	return $success;
}


###########################################################
# Function for setting up the Inline package - this only happens
# when we can use pure Perl to setup the flock struct (i.e., if
# the assemble_pure() function was successful).

sub assemble_inline {
    use File::Copy;

	return unless copy 'Inline_build/Inline.pm.in',
		               'lib/File/FcntlLock/Inline.pm';
	link 'lib/File/FcntlLock.pod', 'lib/File/FcntlLock/Inline.pod';
}


# Local variables:
# tab-width: 4
# indent-tabs-mode: nil
# End:
