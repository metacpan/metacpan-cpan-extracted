# 
# Building Makefile for HTTP::Webdav
#
# (C) 2001 G.Richter / ECOS
#
# $Id: Makefile.PL,v 1.10 2001/10/19 04:36:30 richter Exp $
#
 

use ExtUtils::MakeMaker;

$win32 = ($^O eq 'MSWin32') ;

sub error
    {
    print STDERR $_[0], "\n" ;
    exit (1) ;
    }

$pversion = 'neon 0.17.1' ;

if (!$win32)
    {
    open (C, "neon-config --version|") or error ("Cannot execute neon-config ($!). Is neon already installed on your system?") ;
    chomp ($version = <C>)  or error ("Cannot execute neon-config to get version. Is neon already installed on your system?") ;
    close C ;

    open C, "neon-config --prefix --libs --cflags|" or error ("Cannot execute neon-config ($!). Is neon already installed on your system?") ;
    chomp ($prefix = <C>) ;
    chomp ($libs = <C>) ;
    chomp ($cflags = <C>) ;
    close C ;

    print "Found $version installed under $prefix\n" ;
    print STDERR "This module was made for $pversion and may not run correctly with $version\n" if ($pversion ne $version) ;
    }
else
    {
    do 'config.pl' if (-e 'config.pl') ;

    
    $neonsrc ||= $ARGV[0] || $ENV{NEON_SRC} ;

    if (!$neonsrc || !-d $neonsrc)
        {
        error ("Please specify the location of the neon source files, either as\nfirst argument to Makefile.PL or by setting the environment variables NEON_SRC") ;
        }

    foreach ('neons.lib', 'neonsd.lib', 'Release/neons.lib', 'Debug/neonsd.lib')
        {
        if (-f "$neonsrc/$_")
            {
            $neonlib = "$neonsrc/$_" ;
            last ;
            }
        }

    error ("neons.lib not found under source tree $neonsrc") if (!$neonlib) ;



    $expatsrc ||= $ARGV[1] || $ENV{EXPAT_SRC} ;

    if (!$expatsrc || !-d $expatsrc)
        {
        error ("Please specify the location of the expat source files, either as\nsecond argument to Makefile.PL or by setting the environment variables EXPAT_SRC") ;
        }

    foreach ('xmlparse.lib', 'Release/xmlparse.lib', 'Debug/xmlparse.lib')
        {
        if (-f "$expatsrc/$_")
            {
            $expatlib = "$expatsrc/$_" ;
            last ;
            }
        }

    error ("xmlparse.lib not found under source tree $expatsrc") if (!$expatlib) ;

    $exlibs = " \"$neonlib\" \"$expatlib\" " ;
    $exlibs =~ s#/#\\#g ;
    $cflags = "-I \"$neonsrc/src\"" ;
    $cflags =~ s#/#\\#g ;
    $define = ' -DHAVE_CONFIG_H' ;
    
    open FH, ">config.pl" ;
    print FH q{$neonsrc='}, $neonsrc, "' ;\n",  q{$expatsrc='}, $expatsrc, "' ;\n" ;
    close FH ;  

    print "Found neon source at $neonsrc\n" ;
    print "Found expat source at $expatsrc\n" ;
    }

WriteMakefile
    (
    'NAME'	    => 'HTTP::Webdav',
    'VERSION_FROM'  => 'Webdav.pm', # finds $VERSION
    $libs?  ('LIBS'          => [$libs]):(), 
    $exlibs?('MYEXTLIB'      => $exlibs):(),
    'INC'           => $cflags,
    $define?('DEFINE'        => $define):(),
    'realclean'     => { FILES => 'config.pl' },
    'ABSTRACT'      => 'HTTP::Webdav - Perl interface to Neon HTTP and WebDAV client library',
    'AUTHOR'        => 'Gerald Richter <richter@dev.ecos.de>',
    );
