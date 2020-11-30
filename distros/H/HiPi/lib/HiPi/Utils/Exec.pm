#########################################################################################
# Package        HiPi::Utils::Exec
# Description  : Executable Wrappers
# Copyright    : Copyright (c) 2013-2017 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Utils::Exec;

#########################################################################################

use strict;
use warnings;
use parent qw( HiPi::Class );
use XSLoader;
use Config;
use Carp;
use File::Slurp;
use Cwd;
use Try::Tiny;
use HiPi;

__PACKAGE__->create_accessors( qw( workingdir sourceperl outputexec ) );

our $VERSION ='0.81';

XSLoader::load('HiPi::Utils::Exec', $VERSION) if HiPi::is_raspberry_pi();

sub new {
    my ($class, %params) = @_;
    unless(defined($params{workingdir} && -d $params{workingdir})) {
        croak('you must provide a working directory');
    }
    unless(defined($params{sourceperl} && -f $params{sourceperl})) {
        croak('you must provide a source perl script');
    }
    unless(defined($params{outputexec} && $params{outputexec})) {
        croak('you must provide an output executable');
    }
    my $self = $class->SUPER::new(%params);
    return $self;
}

sub build {
    my $self = shift;
    
    my $wdir = $self->workingdir;
    my $makefile = 'makefile.gcc';
    my $mainc = 'main.c';
    my $hipicname = $self->outputexec . '.c';
    my $execname = $self->outputexec;
    
    my $restoredir = getcwd();
    
    try {
        # create makefile
        File::Slurp::write_file( qq($wdir/$makefile), $self->makefile_template )
            or croak qq(failed to create $makefile : $!);
    
        # create main.c
        File::Slurp::write_file( qq($wdir/$mainc), $self->main_template )
            or croak qq(failed to create $mainc : $!);
        
        # create hipi.c
        $self->create_perl_c( $self->sourceperl, qq($wdir/$hipicname) );
    
        # run make
        chdir($wdir) or croak qq(failed to enter directory $wdir);
        # clean existing
        {
            system(qq(make -f $makefile)) and croak qq(failed to make $execname);
            system(qq(make -f $makefile clean));
            unlink( $makefile );
        }
    } catch {
        chdir($restoredir);
        croak qq(failed to build $execname : $_);
    };
    chdir($restoredir);
}

sub create_perl_c {
    my($self, $source, $outfile) = @_;
    
    my $rawcontent = File::Slurp::read_file($source);
    
    open my $fh, '>', $outfile or die "open '$outfile': $!";
    binmode $fh;
    
    my ($output, $rawlen) = $self->compress_buffer( $rawcontent );
    
    my $compressedlen = length($output);
    my $rawchars = $rawlen + 1;
    
    my $progbootsizename = 'size_hipi_prog';
    my $progcompsizename = 'size_hipi_prog_comp';
    my $progcompname     = 'hipi_prog_comp';
    
    print $fh qq(\n);
    print $fh qq(unsigned long $progbootsizename = $rawchars;\n);
    print $fh qq(unsigned long $progcompsizename = $compressedlen;\n);
    my $buffer = reverse( $output );
    print $fh qq(const unsigned char $progcompname\[) . (length($buffer) + 1) . qq(] = {);
    
    my $i;
    for (1 .. length($buffer)) {
        print $fh sprintf "'\\%03o',", ord(chop($buffer));
        print $fh "\n" unless $i++ % 16; # line break every 16 
    }
    
    print $fh qq(0\n};\n);
    
    close($fh);
}

sub compress_buffer {
    my ($self, $buffer) = @_;
    my( $compressed, $clen ) = _compress_buffer($buffer);
    return( $compressed, $clen );
}

sub decompress_buffer {
    my ($self, $compressed, $length) = @_;
    _decompress_buffer($compressed, $length);
}

sub makefile_template {
    my $self = shift;
    my $template = <<'PEPIMAKEFILETEMPLATE'

MV=mv -f
RM=rm -f

LD=REPLACELDEXEC
CC=REPLACECCEXEC

PERL=REPLACEPERL

CFLAGS=REPLACECFLAGS
LDFLAGS=REPLACELDFLAGS
LDLIBS=REPLACELDLIBS

NOOP=$(PERL) -e1

OBJECTS=main.o REPLACEOBJNAME.o

all:: exec

REPLACEOBJNAME.o:
	$(CC) -c $(CFLAGS) REPLACEOBJNAME.c -o REPLACEOBJNAME.o

main.o:
	$(CC) -c $(CFLAGS) main.c -o main.o
    
clean:
	-$(RM) $(OBJECTS) main.c REPLACEOBJNAME.c

realclean: clean
	-$(RM) REPLACEOBJNAME

exec: $(OBJECTS)
	-$(LD) $(LDFLAGS) $(OBJECTS) $(LDLIBS) -o REPLACEOBJNAME
	strip REPLACEOBJNAME

PEPIMAKEFILETEMPLATE
;
    my $perl = $^X;
    $template =~ s/REPLACEPERL/$perl/g;
    
    my $gcc = $Config{cc};
    $template =~ s/REPLACECCEXEC/$gcc/g;
    
    my $ld = $Config{ld};
    $template =~ s/REPLACELDEXEC/$ld/g;
    
    my $oname = $self->outputexec;
    $template =~ s/REPLACEOBJNAME/$oname/g;
    
    my $optimise = $Config{optimize};
    
    my $cflags = $optimise . ' ' . $Config{ccflags} . ' ' . $Config{cccdlflags} . ' -I' . $Config{archlibexp} . '/CORE';
    $template =~ s/REPLACECFLAGS/$cflags/g;
    
    #my $libpaths = $Config{libpth};
    #$libpaths =~ s/\s+/ -L/g;
    my $ldflags = $optimise . ' ' . $Config{ldflags} ;
    $template =~ s/REPLACELDFLAGS/$ldflags/g;
    my $ldlibs = $Config{perllibs} . ' -lz -lperl';
    $template =~ s/REPLACELDLIBS/$ldlibs/g;
    
    return $template;
}

sub main_template {
    my $self = shift;
    my $template = <<'PEPIMAINTEMPLATE'
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <zlib.h>

extern char **environ;
#define envhipi environ
#include <stdlib.h>
#include <string.h>

extern char hipi_prog_comp[];
extern unsigned long size_hipi_prog;
extern unsigned long size_hipi_prog_comp;
static char **dynamicargv;
static char *hipi_prog; 

/* The __findenv  and hipi_unsetenv functions are subject to the following
 * notice:
 * 
 * Copyright (c) 1987, 1993
 *      The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */


static char *__findenv(register const char *name, int *offset)
{

	register int len;
	register const char *np;
	register char **p, *c;
	
	if (name == NULL || envhipi == NULL)
		exit (101);
	
	for (np = name; *np && *np != '='; ++np)
		continue;
	
	len = np - name;
	
	for (p = envhipi; (c = *p) != NULL; ++p)
	{
		if (strncmp(c, name, len) == 0 && c[len] == '=') {
			*offset = p - envhipi;
			return (c + len + 1);
		}
	}
	return (NULL);
}

static void hipi_unsetenv(const char *name)
{
	register char **p;
	int offset;

	while (__findenv(name, &offset))	/* if set multiple times */
		for (p = &envhipi[offset];; ++p)
			if (!(*p = *(p + 1)))
				break;
}

int error_message( char *message, int marker )
{
    int result;
#ifdef WIN32
    result = GetLastError();
#else
    result = 0;
#endif
    printf("Error at executable startup %d: (%d)\n%s", marker, result, message );
    return marker;
}

void decompress_prog()
{
    Newx(hipi_prog, size_hipi_prog, char);
	uLongf uncompressedsize = (uLongf)size_hipi_prog;
	uncompress((Bytef*)hipi_prog, &uncompressedsize, (const Bytef*)hipi_prog_comp, (uLongf)size_hipi_prog_comp);
}

#define NUMENVKEYS 20

void clear_environment()
{
    int i;
    const char *env_keys[NUMENVKEYS] = {
       "PERL5OPT", "PERL5LIB", "PERLIO",
       "PERLIO_DEBUG", "PERLLIB", "PERL5DB",
       "PERL5DB_THREADED", "PERL5SHELL", "PERL_ALLOW_NON_IFS_LSP",
       "PERL_DEBUG_MSTATS", "PERL_DESTRUCT_LEVEL", "PERL_DL_NONLAZY",
       "PERL_ENCODING", "PERL_HASH_SEED", "PERL_HASH_SEED_DEBUG",
       "PERL_SIGNALS", "PERL_UNICODE", "PERL_ROOT", "HARNESS_ACTIVE", "HARNESS_VERSION"
    };

    for ( i = 0 ; i < NUMENVKEYS ; i++ ) {
	    hipi_unsetenv(env_keys[i]);
    }
}

EXTERN_C void boot_DynaLoader (pTHX_ CV* cv);

EXTERN_C void xs_init(pTHX)
{
    const char* file = __FILE__;
    dXSUB_SYS;
    /* DynaLoader is a special case */
    newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
}

int main ( int argc, char **argv )
{
    int exitstatus;
    int i;
    int numopts;
    int extraopts;
    PerlInterpreter *my_perl ;
    /* environment */
    clear_environment();

	/* be specific about safe putenv */
	PL_use_safe_putenv = TRUE;

    /* if user wants control of gprof profiling off by default */
    /* noop unless Configure is given -Accflags=-DPERL_GPROF_CONTROL */
    PERL_GPROF_MONCONTROL(0);
    
    PERL_SYS_INIT3(&argc,&argv,&envhipi);

#if defined(USE_ITHREADS) && defined(HAS_PTHREAD_ATFORK)
    PTHREAD_ATFORK(Perl_atfork_lock, Perl_atfork_unlock, Perl_atfork_unlock);
#endif

    if (!(my_perl = perl_alloc()))
		return (1);
	
    perl_construct(my_perl);
    
    PL_perl_destruct_level = 1;
    PL_origalen = 1;
	
    PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
    PL_exit_flags |= PERL_EXIT_EXPECTED;
	
	/* prepare prog */
	decompress_prog();

	/* Mung & Allocate Arguments   */
	extraopts = 3;
	numopts = argc + extraopts;
	
	Newx(dynamicargv, numopts, char *);

	dynamicargv[0] = argv[0];
	dynamicargv[1] = "-f\0";
	dynamicargv[2] = "-e\0";
	dynamicargv[3] = hipi_prog;

	for (i = 1; i < argc; i++)
	    dynamicargv[i + extraopts] = argv[i];

	/* parse perl */	
	exitstatus = perl_parse(my_perl, xs_init, numopts, dynamicargv, envhipi);

	/* run perl */
	if (!exitstatus ) {
	    perl_run( my_perl );
	    exitstatus = perl_destruct( my_perl );
	} else {
	    perl_destruct( my_perl );
	}
	
	/* cleanup */

    perl_free(my_perl);

    PERL_SYS_TERM();

    return exitstatus;
}

PEPIMAINTEMPLATE
;
    
    return $template;
}

1;
