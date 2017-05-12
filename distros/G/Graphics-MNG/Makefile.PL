use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use strict;
use English;
my $namespace = 'Graphics::MNG';
my $author    = 'dpmott@sep.com';
my $modname   = 'MNG.pm';

# this references header files in the package.  You may want to change these...
my ( $incs, $defs, @libs );

if ( $OSNAME =~ /win32/i )
{
   # I like you, so I'm going to link with a precompiled library that I've provided just for you!
   @libs = ( '-Llib -llibmng.lib' );
   $incs = ' -I. -Iinclude ';
   $defs = ' -DMNG_SUPPORT_FULL -DMNG_FULL_CMS -DMNG_USE_SO -DMNG_INTERNAL_MEMMNGMT -DMNG_SUPPORT_TRACE -DNON_WINDOWS ';

   # I'm doing that because I can't seem to link to the official Win32 libmng.dll!
   # I have been unable to generate a suitable implib for use with the DLL.
   # Help is welcome!
   # @libs = ( '-Llib -llibmng.lib' );
   # $incs = ' -I. -I../../../Gd/jpeg-6b -I../../../Gd/zlib-1.1.3 -I../../../libmng/libmng -I../../../libmng/lcms/src ';
   # $defs = ' -DMNG_SUPPORT_FULL -DMNG_FULL_CMS -DMNG_USE_DLL -DMNG_INTERNAL_MEMMNGMT -DMNG_SUPPORT_TRACE ';
}
elsif ( $OSNAME =~ /cygwin/i )
{
   @libs = ( '-L/usr/lib -lmng -ljpeg -lz -lLcms' );
   $incs = '-I. -I/usr/include';
   $defs = ' -DMNG_SUPPORT_FULL -DMNG_FULL_CMS -DMNG_USE_SO -DMNG_INTERNAL_MEMMNGMT -DMNG_SUPPORT_TRACE ';
}
else
{
   # warn the user
   warn((" -=WARNING=- ") x 5, "\n");
   warn("I couldn't figure out what OS you're using, or I don't support it.\n".
        "You should edit your Makefile.PL and change the include and lib paths!\n");

   # this is where I build it on my machine...
   @libs = ( '-L../../../libmng/Release -llibmng.lib' );
   $incs = ' -I. -I../../../Gd/jpeg-6b -I../../../Gd/zlib-1.1.3 -I../../../libmng/libmng -I../../../libmng/lcms/src ';
   $defs = ' -DMNG_FULL_CMS -DMNG_USE_SO -DNON_WINDOWS -DMNG_INTERNAL_MEMMNGMT -DMNG_SUPPORT_TRACE ';
}


# fix pathnames for the OS
if ( $OSNAME =~ /win32/i )
{
   $incs =~ s,\\,/,g;
   grep { s,\\,/,g } @libs;
}



WriteMakefile(
    'NAME'           => $namespace,
    'VERSION_FROM'   => $modname,          # finds $VERSION
    'PREREQ_PM'      => {},                # e.g., Module::Name => 1.1
    ($] >= 5.005 ?                         ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => $modname,          # retrieve abstract from module
       AUTHOR        => $author) : ()),
    'LIBS'           => [@libs],           # e.g., '-lm'
    'DEFINE'         => $defs,             # e.g., '-DHAVE_SOMETHING'
    'INC'            => $incs,             # e.g., '-I. -I/usr/include/other'

	 # Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
);


if ( open(PM,$modname) )
{
   undef $/;
   my $content = <PM>;
   close PM;

   $content =~ s/^.*?__END__//os;
   $content =~ s/^=head[\d]*\s*//gomsi;
   $content =~ s/=cut.*$//os;
   if ( open(README,">README") )
   {
      my $version = MM->parse_version($modname);
      my $header  = "$namespace version $version\n"; 
      print README $header, '=' x (length($header)-1), "\n";
      print README $content;
      close README;
   }
}

