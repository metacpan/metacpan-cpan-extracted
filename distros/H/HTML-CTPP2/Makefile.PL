use 5.008001;
use strict;
use ExtUtils::MakeMaker;

my @IncludeDirs = ($ENV{'CTPP2_INCLUDE'},
                   "/usr/local/include/ctpp2",
                   "/usr/include/ctpp2",
                   "/opt/include/ctpp2",
		   "/opt/REKIctpp2/include/ctpp2",
                   "/usr/local/ctpp2/include");

my @LibDirs     = ($ENV{'CTPP2_LIB'},
                   "/usr/local/lib",
                   "/usr/lib",
                   "/opt/lib",
		   "/opt/REKIctpp2/lib",
                   "/usr/local/ctpp2/lib");

sub NeedToInstallCTPP
{
	my $Error = shift;
	warn $Error .
	"\nYou should install CTPP2 library first!\n" .
	"Sources of CTPP2 available here: http://ctpp.havoc.ru/download/\n".
	"You may also define the CTPP2_INCLUDE and CTPP2_LIB environment variables.";
	exit;
}

sub SearchDir
{
	my $File = shift;
	foreach (@_)
	{
		return $_ if (-e "$_/$File");
	}
return undef;
}

print "perl thinks the current OS is '$^O'\n";

my $CXX = 'g++';
my $CC  = 'gcc';
my $STDCPP = '-lstdc++';

my $inc_dirs = "";
my $lib_dirs = "";

if    ($^O eq 'solaris') { $CXX = 'CC'; $CC = 'CC'; $STDCPP = '-lCstd'; }
elsif ($^O eq 'MSWin32')
{
	$CXX = 'cl'; $CC = 'link'; $STDCPP = '';
	my @s_incdir = {};
	my @s_libdir = {};
	if(defined $ENV{'INCLUDE'})
	{
		@s_incdir = split(/;/, $ENV{'INCLUDE'});
		foreach my $v (@s_incdir)
		{
			if($v)
			{
				$inc_dirs.= ' /I "'.$v.'" ';
				push(@IncludeDirs, $v);
			}
		}
	}
	if(defined $ENV{'LIB'})
	{
		@s_libdir = split(/;/, $ENV{'LIB'});
		foreach my $v (@s_libdir)
		{
			$lib_dirs .= ' /LIBPATH:"'.$v.'" ';
			push(@LibDirs, $v);
		}
	}
	if(defined $ENV{'PATH'})
	{
		@s_libdir = split(/;/, $ENV{'PATH'});
		foreach my $v (@s_libdir)
		{
			push(@LibDirs, $v);
		}
	}
}

my $CTPP2IncludeDir = SearchDir("CDT.hpp", @IncludeDirs);
unless ($CTPP2IncludeDir)
{
	NeedToInstallCTPP("Cannot find header file CDT.hpp");
	exit;
}

if ($^O eq 'MSWin32')
{
	my $libfile = 'ctpp2l.lib';
	my $CTPP2LibDir     = SearchDir("ctpp2l.lib", @LibDirs);
	unless ($CTPP2LibDir)
	{
		$libfile = 'ctpp2.lib';
		$CTPP2LibDir     = SearchDir("ctpp2.lib", @LibDirs);
		unless ($CTPP2LibDir)
		{
			NeedToInstallCTPP("Cannot find shared library file ctpp2.lib");
			exit;
		}
	}

	WriteMakefile(
		'NAME'			=> 'HTML::CTPP2',
		'VERSION_FROM' 	=> 'lib/HTML/CTPP2.pm',
		'LIBS'			=> $CTPP2LibDir.'\\'.$libfile,
		'DEFINE'		=> ' /D "WIN32" /D "_WINDOWS" /D "_WINDLL" /D"_MBCS" /D "NDEBUG" /D "_USRDLL" /D "CTPPPERL_EXPORTS"',
		'INC'			=> ' /I "'.$CTPP2IncludeDir.'" '.$inc_dirs.' /I "."',
		'OPTIMIZE'		=> ' /O2 /Oi /GL',
		'LDDLFLAGS'		=> ' '.$lib_dirs.' /IMPLIB:'.$libfile.' /SUBSYSTEM:WINDOWS /OPT:REF /OPT:ICF /LTCG /DYNAMICBASE /DLL /NXCOMPAT /MACHINE:X86 /ERRORREPORT:PROMPT',
		'CCFLAGS'		=> ' /FD /EHsc /MD /Gy /W3 /nologo /c /Zi /TP /errorReport:prompt',
		'CC'			=> $CXX,
		'LD'			=> $CC,
		'XSOPT'			=> '-C++',
		'clean'			=> { 'FILES' => '*.ct2' },
		'TYPEMAPS'		=> ['perlobject.map'],
		'AUTHOR'		=> 'Andrei V. Shetuhin <reki@reki.ru>'
	);
}
else
{
	my $CTPP2LibDir     = SearchDir("libctpp2.so.2", @LibDirs);
	unless ($CTPP2LibDir) { NeedToInstallCTPP("Cannot find shared library file libctpp2.so"); exit; }

	WriteMakefile(
		'NAME'		=> 'HTML::CTPP2',
		'VERSION_FROM' 	=> 'lib/HTML/CTPP2.pm',
		'LIBS'		=> "-L$CTPP2LibDir -L/usr/lib -lm -lctpp2 $STDCPP",
		'DEFINE'		=> '-fexceptions -O2 -Wno-deprecated ',
		'INC'		=> "-I$CTPP2IncludeDir -I/usr/include -I/usr/local/include -I. ",
		'CC'		=> $CXX,
		'LD'		=> $CC,
		'XSOPT'		=> '-C++',
		'clean'		=> { 'FILES' => '*.ct2' },
		'TYPEMAPS'		=> ['perlobject.map'],
		'AUTHOR'            => 'Andrei V. Shetuhin <reki@reki.ru>'
	);
}
