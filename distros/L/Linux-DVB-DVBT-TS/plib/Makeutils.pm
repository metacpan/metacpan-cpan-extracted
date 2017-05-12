package Makeutils ;

=head1 NAME

Makeutils - MakeMaker utilities 

=head1 SYNOPSIS

	use Makeutils ;
  

=head1 DESCRIPTION

Module provides a set of useful utility routines for creating Maefiles and config.h files. 


=cut


#============================================================================================
# USES
#============================================================================================
use strict ;
use ExtUtils::MakeMaker ;
use Env ;
use Config;
use Cwd 'cwd';
use File::Basename ;
use File::Path ;


#============================================================================================
# EXPORTER
#============================================================================================
require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw/
	init
	add_install_progs
	add_defines
	get_makeopts
	process_makeopts
	update_manifest
	add_objects
	add_clibs
	c_try
	c_try_keywords
	c_inline
	have_builtin_expect
	have_lrintf
	c_always_inline
	c_restrict
	c_has_header
	c_has_function
	c_struct_timeval
	check_new_version
	have_h
	have_d
	havent_d
	have_func
	arch_name
	get_config
	get_makemakerdflt
/ ;


#============================================================================================
# GLOBALS
#============================================================================================
our $VERSION = '1.07' ;
our $DEBUG = 0 ;
our $UPDATE_MANIFEST = 0 ;

our %ModuleInfo ;


#============================================================================================

#============================================================================================

##-------------------------------------------------------------------------------------------
sub init 
{
	my ($modname) = @_ ;
	
	print "(Using Makeutils.pm version $VERSION)\n" ;
	
	my $name = $modname ;
	unless ($name)
	{
	    $name = basename(cwd());
	    $name =~ s|[\-_][\d\.\-]+\z||; 
	}
	
	# eg Linux::DVB::DVBT::TS
	my $mod = $name ;
	$mod =~ s%\-%::%g ;
	
	# eg Linux/DVB/DVBT/TS
	my $modpath = $name ;
	$modpath =~ s%\-%/%g ;
	
	# eg TS
	my $root = $name ;
	$root =~ s%.*\-([^-]+)$%$1% ;

	my $version = ExtUtils::MM->parse_version("lib/$modpath.pm");
	
	%ModuleInfo = (
		# eg Linux-DVB-DVBT-TS
		'name'		=> $name,
		
		# eg Linux::DVB::DVBT::TS
		'mod'		=> $mod,
		
		# eg Linux/DVB/DVBT/TS
		'modpath'	=> $modpath,
		
		# eg TS
		'root'		=> $root,
		
		'version'	=> $version,
		
		'programs'	=> [],
		
		'mod_defines'	=> "",
		'make_defines'	=> "",
		
		## Flags
		'CCFLAGS'		=> '-o $@',
		'OPTIMIZE'		=> '-O3',
		
		# included c-libraries
		'clibs'			=> {},
		'includes'		=> "",
		
		# String "list" of objects
		'objects'		=> "$root.o ",
		
		# additional objects
		'obj_list' 		=> [],
		
		'config'		=> {},
		
		'COMMENTS'		=> {},
		'C_TRY'			=> {},
		
	) ;
	
	return \%ModuleInfo ;
}

##-------------------------------------------------------------------------------------------
sub add_install_progs
{
	my ($basedir, $progs_aref) = @_ ;

	if ( (ref($progs_aref) eq 'ARRAY') && @$progs_aref)
	{	
		if ( 
			grep $_ eq '-n', @main::ARGV
			or grep /^LIB=/, @main::ARGV and not grep /^INSTALLSCRIPT=/, @main::ARGV 
		) 
		{
			@main::ARGV = grep $_ ne '-n', @main::ARGV;
			warn "Skipping installation of scripts...\n";
			
			while (@$progs_aref) 
			{
				pop @$progs_aref ;	
			}
		} 
		else 
		{
			warn <<EOW;

This Perl module comes with several scripts which I would try to install in
directory $Config{installscript}.

To skip install, rerun with option -n given to Makefile.PL.

EOW
		}
	}
	
	$progs_aref ||= [] ;
	$ModuleInfo{'programs'} = [ map "$basedir$_", @$progs_aref ] ;
	
	return @$progs_aref ;
}

##-------------------------------------------------------------------------------------------
sub add_defines
{
	my ($defines_href) = @_ ;

	if ( (ref($defines_href) eq 'HASH') && keys %$defines_href)
	{	
		foreach my $key (keys %$defines_href)
		{
			if (defined($defines_href->{$key}) && length($defines_href->{$key}))
			{
				$ModuleInfo{'mod_defines'} .= "-D$key=$defines_href->{$key} " ;
				$ModuleInfo{'make_defines'} .= "$key=$defines_href->{$key} " ;
			}
			else
			{
				$ModuleInfo{'mod_defines'} .= "-D$key " ;
				$ModuleInfo{'make_defines'} .= "$key=1 " ;
			}
		}
	}
}

##-------------------------------------------------------------------------------------------
sub get_makeopts
{
	## -D = debug 
	$Makeutils::DEBUG = 0 ;
	if ( 
		grep $_ eq '-D', @main::ARGV
	) 
	{
		$Makeutils::DEBUG = 1 ;
	} 
	
	## -d = debug 
	if ( 
		grep $_ eq '-d', @main::ARGV
	) 
	{
		@main::ARGV = grep $_ ne '-d', @main::ARGV;
		warn "Buidling version with extra debugging enabled...\n";
		add_defines({
			'DEBUG'		=> 1,
		}) ;
		
		# compile for debug
		$ModuleInfo{'OPTIMIZE'} = '-ggdb -O0' ;
	} 
	
	## -M = udpate MANIFEST 
	$Makeutils::UPDATE_MANIFEST = 0 ;
	if ( 
		grep $_ eq '-M', @main::ARGV
	) 
	{
		$Makeutils::UPDATE_MANIFEST = 1 ;
	} 
	
}


##-------------------------------------------------------------------------------------------
sub process_makeopts
{
	if ($Makeutils::UPDATE_MANIFEST)
	{
		update_manifest() ;
	}	
}

##-------------------------------------------------------------------------------------------
sub update_manifest
{
	## Read file
	my %manifest ;
	my $line ;
	open my $fh, "<MANIFEST" or die "Error: Unable to read MANIFEST file" ;
	while(defined($line = <$fh>))
	{
		chomp $line ;
		$line =~ s/[^[:ascii:]]/ /g;
		$line =~ s/^\s+// ;
		$line =~ s/\s+$// ;
		$line =~ s/^#.*// ;
		next unless $line ;

		$manifest{$line} = 1 ;		
	}
	close $fh ;
	
	## Build expected list
	my @expected = qw(
		MANIFEST
		README
		COPYING
		Changes
		Makefile.PL
		plib/Makeutils.pm
		ppport.h
		typemap
	) ;
	
	# xs
	push @expected, "$ModuleInfo{'root'}.xs" ;
	push @expected, find_recurse("xs", "*.xs") ;
	
	# t
	push @expected, find_recurse("t", "*.t") ;
	
	# scripts
	push @expected, @{$ModuleInfo{'programs'}} ;
	
	# Perl
	push @expected, find_recurse("lib", "*.pm") ;
	
	# C
	push @expected, find_recurse("clib", "*.c") ;
	push @expected, find_recurse("clib", "*.h") ;
	
	
	## Find any missing
	my @missing ;
	foreach my $file (@expected)
	{
		if (!exists($manifest{$file}))
		{
			push @missing, $file ;
		}
	}

	print "\nUpdating MANIFEST\n" ;
	print   "=================\n" ;
	if (@missing)
	{
		## Append
		open my $fh, ">>MANIFEST" or die "Error: Unable to write to MANIFEST file" ;
		print $fh "\n\n## Missing files:\n" ;
		foreach my $file (@missing)
		{
			print $fh "$file\n" ;
		}
		close $fh ;
		
		print "Appended ", scalar(@missing), " files:\n" ;
		foreach my $file (@missing)
		{
			print "  $file\n" ;
		}
	}
	else
	{
		print "No files missing\n" ;
	}
	
	
	print "\nAll Files:\n" ;
	foreach my $file (@expected)
	{
		print "  $file\n" ;
	}
	
	exit 0 ;
}

##-------------------------------------------------------------------------------------------
sub find_recurse
{
	my ($dir, $spec) = @_ ;
	my @files = () ;
	
	# depth last
	foreach my $f (glob("$dir/$spec"))
	{
		if (-f $f)
		{
			push @files, $f ;
		}
	}
	foreach my $d (glob("$dir/*"))
	{
		if (-d $d)
		{
			push @files, find_recurse($d, $spec) ;
		}
	}
	
	return @files ;
}

##-------------------------------------------------------------------------------------------
sub add_objects
{
	my ($basedir, $objs_aref) = @_ ;

	foreach my $obj (@$objs_aref)
	{
		push @{$ModuleInfo{'obj_list'}}, "$basedir/$obj" ;
	}

	## Recreate list of all objects
	_create_objects_list() ;

	## Create list of includes
	_create_includes_list() ;
}
	
##-------------------------------------------------------------------------------------------
#		'dvb_lib'		=> {'mkf' => 'Subdir-min.mk'},
#		'dvb_ts_lib'	=> 1,
#		'libmpeg2'		=> { 
#			'config'		=> {
#				'file'			=> 'include/config.h',
#				'func'			=> \&create_libmpeg2_config_h,
#			},
#		},
#		'mpeg2audio'	=> {
#			'config'		=> {
#				'file'			=> 'config.h',
#				'func'			=> \&create_mpeg2audio_config_h,
#			},
#		},
#
sub add_clibs
{
	my ($basedir, $clibs_href) = @_ ;

	print "add_clibs($basedir)\n" if $DEBUG ;
	
	## Include makefiles & get objects
	print "Including makefiles from sub libraries:\n" ;
	foreach my $lib (keys %$clibs_href)
	{
		my $libdir = "$basedir/$lib/" ;
		
		$ModuleInfo{'clibs'}{$lib} = {
			'file'		=> "",
			'objects'	=> [],
			'includes'	=> [ $libdir ],
		} ;
		
		print " * $lib ... " ;
		my $mkf = "$libdir/" ;
		my $specified_mkf = 0 ;
		if ( ref($clibs_href->{$lib}) eq 'HASH')
		{
			if ( exists($clibs_href->{$lib}{'mkf'})) 
			{
				++$specified_mkf ;
				$mkf .= $clibs_href->{$lib}{'mkf'} ;
			}
			else
			{
				$mkf .= 'Subdir.mk' ;
			}
		}
		else
		{
			$mkf .= 'Subdir.mk' ;
		}

	print "\n * * mkf = $mkf\n" if $DEBUG ;
		
		## read file
		if (-f $mkf)
		{
			open my $fh, "<$mkf" ;
			if ($fh)
			{
				$ModuleInfo{'clibs'}{$lib}{'file'} = do { local $/; <$fh> } ;
				close $fh ;	
				print "ok" ;
			}
			else
			{
				print "Unable to read $mkf : $!\n" ;
				exit(1) if $specified_mkf ;
			}
		}
		else
		{
			print "$mkf not found\n" ;
			exit(1) if $specified_mkf ;
		}
		print "\n" ;
		
		## Process file
		my @lines = split /\n/, $ModuleInfo{'clibs'}{$lib}{'file'} ;
		foreach my $line (@lines)
		{
			chomp $line ;
			$line =~ s/#.*// ;
			$line =~ s/^\s+// ;
			$line =~ s/\s+$// ;
			next unless $line ;
			
			# look for something like:
			#	OBJS-libdvb_ts_lib := \
			#		$(libdvb_ts_lib)/ts_parse.o \
			#		$(libdvb_ts_lib)/ts_skip.o \
			#		$(libdvb_ts_lib)/ts_split.o \
			#		$(libdvb_ts_lib)/ts_cut.o
			#
			# Get just the *.o
			#
			if ($line =~ m/(\S+\.o)/)
			{
				my $obj = $1 ;
				
				# replace $(...) with the dir
				$obj =~ s%\$\([^)]+\)%$basedir/$lib% ;
				push @{$ModuleInfo{'clibs'}{$lib}{'objects'}}, $obj ;
			}
		}
		
		## check for any include subdirs
		for my $incdir (qw/include inc h shared/)
		{
			if (-d "$libdir$incdir")
			{
				push @{$ModuleInfo{'clibs'}{$lib}{'includes'}}, "$libdir$incdir" ;
			}
		}
	}
	
	## Create config files
	foreach my $lib (keys %$clibs_href)
	{
		if ( (ref($clibs_href->{$lib}) eq 'HASH') && (exists($clibs_href->{$lib}{'config'})) )
		{
			if ( (ref($clibs_href->{$lib}{'config'}{'func'}) eq 'CODE') && (exists($clibs_href->{$lib}{'config'}{'file'})) )
			{
				my $func = $clibs_href->{$lib}{'config'}{'func'} ;
				my $config_h = "$basedir/$lib/$clibs_href->{$lib}{'config'}{'file'}" ;

				print "creating config file $config_h ... " ;
				&$func($config_h, %{$ModuleInfo{'config'}}) ;
				print "ok\n" ;
			}
		}
	}

	## Recreate list of all objects
	_create_objects_list() ;
	
	## Create list of includes
	_create_includes_list() ;
}
	

##-------------------------------------------------------------------------------------------
sub _create_objects_list
{
	## root
	$ModuleInfo{'objects'} = "$ModuleInfo{'root'}.o " ;
	
	## include makefiles
	foreach my $lib (sort keys %{$ModuleInfo{'clibs'}})
	{
		$ModuleInfo{'objects'} .= join(' ', @{$ModuleInfo{'clibs'}{$lib}{'objects'}}) . " " ;
	}
	
	## additional objects
	$ModuleInfo{'objects'} .= join(' ', @{$ModuleInfo{'obj_list'}}) . " " ;
}

##-------------------------------------------------------------------------------------------
sub _create_includes_list
{
	## include makefiles
	$ModuleInfo{'includes'} = "" ;
	foreach my $lib (sort keys %{$ModuleInfo{'clibs'}})
	{
		foreach my $inc ( @{$ModuleInfo{'clibs'}{$lib}{'includes'}} )
		{
			$ModuleInfo{'includes'} .= "-I$inc " ;
		}
	}
	
}

##-------------------------------------------------------------------------------------------
sub _c_try
{
	my ($info_tag, $cc, $target, $msg, $code, $ok_val, $cflags, $exec_out_ref) = @_ ;

if ($DEBUG && $msg)
{
print "\n-------------------------\n" ;
}		
	if ($info_tag)
	{
		$ModuleInfo{'C_TRY'}{$info_tag} ||= [] ;
	}
	
	print "$msg... " if $msg ;

	$ok_val=1 unless defined $ok_val ;
	
	$cflags ||= "" ;
	my $ok = "" ;
	my $conftest = "conftest.c" ;
	my $conferr = "conftest.err" ;
	
	open my $fh, ">$conftest" or die "Error: unable to create test file $conftest : $!";
	print $fh $code ;
	close $fh ;
	
	unlink $target ;
	
	my $cmd = "$cc $conftest $cflags 2> $conferr" ;
	my $rc = system($cmd) ;
	my $errstr ;
	open $fh, "<$conferr" ;
	if ($fh)
	{
		$errstr = do { local $/; <$fh> } ;
		close $fh ;	
		$errstr =~ s/^\s+.//gm ;
	}

if ($DEBUG)
{
print "\n- - - - - - - - - - - - -\n" ;
print "- RC: $rc\n" ;
print "- - - - - - - - - - - - -\n" ;
print "- Code:\n" ;
print "- - - - - - - - - - - - -\n" ;
print "$code\n" ;
print "- - - - - - - - - - - - -\n" ;
print "- Cmd: $cmd\n" ;
print "- - - - - - - - - - - - -\n" ;
print "- Target: $target [size=", -s $target, "]\n" ;
print "- - - - - - - - - - - - -\n" ;
print "- Compile errors:\n" ;
print "- - - - - - - - - - - - -\n" ;
print "$errstr" ;
}		

	if ($info_tag)
	{
		my $size = -s $target || 0 ;
		push @{$ModuleInfo{'C_TRY'}{$info_tag}}, (
"- - - - - - - - - - - - -",
"- RC: $rc",
"- - - - - - - - - - - - -",
"- Code:",
"- - - - - - - - - - - - -",
"$code",
"- - - - - - - - - - - - -",
"- Cmd: $cmd",
"- - - - - - - - - - - - -",
"- Target: $target [size=$size]",
"- - - - - - - - - - - - -",
"- Compile errors:",
"- - - - - - - - - - - - -",
"$errstr" 
		) ;
	}

	# check for errors
	if ( ($rc==0) && (!$errstr) && (-s $target) )
	{
		# stop here because this worked
		$ok = $ok_val ;
		
#		## See if we want to run the code
#		if ($exec_out_ref && ref($exec_out_ref))
#		{
#			my @out = `./$conftest` ;
#		}
	}
	
	unlink $conftest ;
	unlink $conferr ;

	if ($msg)
	{
		if ($DEBUG)
		{
			print "- - - - - - - - - - - - -\n" ;
			print "- Return: [ok=$ok] " ;
		}
#		print $ok ? "$ok\n" : "no\n" ;		
		print $ok ? "yes\n" : "no\n" ;		
	}

	if ($info_tag)
	{
		push @{$ModuleInfo{'C_TRY'}{$info_tag}}, (
"- - - - - - - - - - - - -",
"- Return: [ok=$ok]" 
		) ;
	}

if ($DEBUG && $msg)
{
print "-------------------------\n\n" ;
}		


	return $ok ;
}


##-------------------------------------------------------------------------------------------
sub c_try
{
	my ($info_tag, $msg, $code, $ok_val, $cflags, $exec_out_ref) = @_ ;

	my $confobj = "conftest.o" ;
	my $cc = "$Config{'cc'}  -o $confobj -c" ;

	my $ok = _c_try($info_tag, $cc, $confobj, $msg, $code, $ok_val, $cflags, $exec_out_ref) ;

	unlink $confobj ;

	return $ok ;
}

##-------------------------------------------------------------------------------------------
sub c_try_link
{
	my ($info_tag, $msg, $code, $ok_val, $cflags, $exec_out_ref, $ld_flags) = @_ ;

	$ld_flags ||= "" ;
	
	my $target = "conftest$Config{_exe}" ;
	my $cc = "$Config{'cc'} -o $target $ld_flags" ;

	my $ok = _c_try($info_tag, $cc, $target, $msg, $code, $ok_val, $cflags, $exec_out_ref) ;

	unlink $target ;

	return $ok ;
}

##-------------------------------------------------------------------------------------------
sub c_try_keywords
{
	my ($info_tag, $msg, $code, $keywords_aref, $cflags) = @_ ;
	

if ($DEBUG)
{
print "\n-------------------------\n" ;
}		

	print "$msg... " if $msg ;
	
	my $ok = "" ;
	
	foreach my $ac_kw (@$keywords_aref)
	{
		if ($DEBUG)
		{
			print "\n- - - - - - - - - - - - -\n" ;
			print "- Keyword: $ac_kw" ;
		}

		my $code_str = $code ;
		$code_str =~ s/\$ac_kw/$ac_kw/g ;
		$ok = c_try($info_tag, "", $code_str, $ac_kw, $cflags) ;
		
		if ($ok)
		{
			last ;
		}
	}

	if ($msg)
	{
		if ($DEBUG)
		{
			print "- - - - - - - - - - - - -\n" ;
			print "- Return: " ;
		}
		print $ok ? "$ok\n" : "no\n" ;		
	}

if ($DEBUG)
{
print "-------------------------\n\n" ;
}		

	return $ok ;
}


##-------------------------------------------------------------------------------------------
sub c_inline
{
	my $code = <<'_ACEOF' ;
#ifndef __cplusplus
typedef int foo_t;
static $ac_kw foo_t static_foo () {return 0; }
$ac_kw foo_t foo () {return 0; }
#endif

_ACEOF
	
	my $ac_c_inline = c_try_keywords('inline', 'checking for inline', $code, [qw/inline __inline__ __inline/]) ;
	return $ac_c_inline ;
}


##-------------------------------------------------------------------------------------------
sub have_builtin_expect
{
	my $code = <<_ACEOF ;
int foo (int a)
{
    a = __builtin_expect (a, 10);
    return a == 10 ? 0 : 1;
}
_ACEOF
	
	my $ok = c_try('expect', 'checking for builtin expect', $code, 1) ;
	
	return $ok ? "#define HAVE_BUILTIN_EXPECT 1" : "" ;
}

##-------------------------------------------------------------------------------------------
sub have_lrintf
{
	my $code = <<_ACEOF ;
#include <math.h>
int foo (double a)
{
long int b ;

    b = lrintf(a);
    return b == 10 ? 0 : 1;
}
_ACEOF
	
	my $ok = c_try('lrintf', 'checking for lrintf', $code, 1) ;
	
	return $ok ? "#define HAVE_LRINTF 1" : "" ;
}

##-------------------------------------------------------------------------------------------
sub c_always_inline
{
	my ($ac_c_inline) = @_ ;
	
	my $ac_c_always_inline = "" ;
	
	if ( ($Config{'cc'} =~ /gcc$/) && ($ac_c_inline eq 'inline') )
	{
		my $code = <<_ACEOF ;

#ifndef __cplusplus
#define inline $ac_c_inline
#endif

int
main ()
{
__attribute__ ((__always_inline__)) void f (void);
            #ifdef __cplusplus
            42 = 42;    // obviously illegal - we want c++ to fail here
            #endif
  ;
  return 0;
}
_ACEOF

		$ac_c_always_inline = c_try('always_inline', 'checking for always_inline', $code, '__attribute__ ((__always_inline__))') ;
	}
	
	return $ac_c_always_inline ;
}

##-------------------------------------------------------------------------------------------
sub c_restrict
{
	
	## protect $ac_kw for expansion in c_try_keywords()
	my $code = <<'_ACEOF' ;
int
main ()
{
char * $ac_kw p;
  ;
  return 0;
}

_ACEOF
	
	my $ac_c_restrict = c_try_keywords('restrict', 'checking for restrict', $code, [qw/restrict __restrict__ __restrict/]) ;
	return $ac_c_restrict ;
}

##-------------------------------------------------------------------------------------------
sub c_has_header
{
	my ($header) = @_ ;

	my $code = <<_ACEOF ;
#include <$header>

typedef int foo_t;
static foo_t static_foo () {return 0; }

int
main ()
{
  return static_foo() ;
}
_ACEOF
	
	my $ac_has_header = c_try($header, "checking for $header", $code, $header, '-Wall -Werror') ;
	return $ac_has_header ;
}

##-------------------------------------------------------------------------------------------
sub c_has_function
{
	my ($ac_func) = @_ ;

	my $code = <<_ACEOF ;
/* Define $ac_func to an innocuous variant, in case <limits.h> declares $ac_func.
   For example, HP-UX 11i <limits.h> declares gettimeofday.  */
#define $ac_func innocuous_$ac_func

/* System header to define __stub macros and hopefully few prototypes,
    which can conflict with char $ac_func (); below.
    Prefer <limits.h> to <assert.h> if __STDC__ is defined, since
    <limits.h> exists even on freestanding compilers.  */

#ifdef __STDC__
# include <limits.h>
#else
# include <assert.h>
#endif

#undef $ac_func

/* Override any GCC internal prototype to avoid an error.
   Use char because int might match the return type of a GCC
   builtin and then its argument prototype would still apply.  */
#ifdef __cplusplus
extern "C"
#endif
char $ac_func ();
/* The GNU C library defines this for functions which it implements
    to always fail with ENOSYS.  Some functions are actually named
    something starting with __ and the normal name is an alias.  */
#if defined __stub_$ac_func || defined __stub___$ac_func
choke me
#endif

int
main ()
{
return $ac_func ();
  ;
  return 0;
}
_ACEOF
	
#	c_try_link($msg, $code, $ok_val, $cflags, $exec_out_ref, $ld_flags) ;
	my $ac_has_function = c_try_link($ac_func, "checking for $ac_func", $code, $ac_func, '-Wall -Werror') ;
	return $ac_has_function ;
}


##-------------------------------------------------------------------------------------------
sub c_has_math_function
{
	my ($ac_func) = @_ ;

	my $code = <<_ACEOF ;
#include <math.h>
float foo(float f) { return $ac_func (f); }
int main (void) { return 0; }
_ACEOF
	
#	c_try_link($msg, $code, $ok_val, $cflags, $exec_out_ref, $ld_flags) ;
	my $ac_has_function = c_try_link($ac_func, "checking for $ac_func", $code, $ac_func, '-Wall -Werror', undef, '-lm') ;
	return $ac_has_function ;
}

##-------------------------------------------------------------------------------------------
sub c_replace_math_function
{
	my ($ac_func) = @_ ;

	my $code = <<_ACEOF ;
#include <math.h>

static inline long int $ac_func(float x)
{
    return (int)(x);
}

float foo(float f) { return $ac_func (f); }
int main (void) { return 0; }
_ACEOF
	
#	c_try_link($msg, $code, $ok_val, $cflags, $exec_out_ref, $ld_flags) ;
	my $ac_hasnt_function = c_try_link($ac_func, "", $code, $ac_func, '-Wall -Werror', undef, '-lm') ;
	return $ac_hasnt_function ;
}


##-------------------------------------------------------------------------------------------
sub c_struct_timeval
{
	my $code = <<_ACEOF ;
#include <sys/time.h>
#include <time.h>

typedef struct timeval ac__type_new_;
int
main ()
{
if ((ac__type_new_ *) 0)
  return 0;
if (sizeof (ac__type_new_))
  return 0;
  ;
  return 0;
}
_ACEOF
	
	my $ac_struct_timeval = c_try('struct tmeval', "checking for struct timeval", $code, 1) ;
	return $ac_struct_timeval ;
}





##-------------------------------------------------------------------------------------------
sub check_new_version
{
#	my $version = ExtUtils::MM_Unix->parse_version("lib/$ModuleInfo{modpath}.pm");

	print "Installing Version: $ModuleInfo{version}\n" ;
	
	## Check for newer version
	eval {
		require LWP::UserAgent;
	} ;
	if (!$@)
	{
		print "Checking for later version...\n" ;
		
		## specify user name so that I can filter out my builds
		my $user = $ENV{USER} || $ENV{USERNAME} || 'nobody' ;

		# CPAN testers
		my $cpan = $ENV{'PERL5_CPAN_IS_RUNNING'}||0 ;
		
		## check for OS-specific versions
		my $os = $^O ;
		my $url = "http://quartz.homelinux.com/CPAN/index.php?ver=$ModuleInfo{version}&mod=$ModuleInfo{name}&user=$user&os=$os&cpan=$cpan" ;
		 
		my $ua = LWP::UserAgent->new;
		$ua->agent("CPAN-$ModuleInfo{name}/$ModuleInfo{version}") ;
		$ua->timeout(10);
		$ua->env_proxy;
		 
		my $response = $ua->get($url);
		if ($response->is_success) 
		{
			my $content = $response->content ;
			if ($content =~ m/Current version : ([\d\.]+)/m)
			{
				print "Latest CPAN version is $1\n" ;
			}
			if ($content =~ m/Newer version/m)
			{
				print "** NOTE: A newer version than this is available. Please downloaded latest version **\n" ;
			}
			else
			{
				print "Got latest version\n" ;
			}
		}
		else
		{
			print "Unable to connect, assuming latest\n" ;
			#print $response->status_line;
		}
	}
	
}


##-------------------------------------------------------------------------------------------
sub check_largefile
{
	my $code = <<_ACEOF ;
#include <unistd.h>

int
main ()
{
off64_t i = 0 ;

  return 0;
}
_ACEOF
	
	$ModuleInfo{'config'}{'off64_t'} = "" ;
	my $ac_off64_t = c_try('off64_t', "checking for off64_t support", $code, 1) ;
	if (!$ac_off64_t)
	{
		$ModuleInfo{'config'}{'off64_t'} = "#define off64_t off_t" ;
	}
	

	$code = <<_ACEOF ;
#include <unistd.h>
#include <stdio.h>
#include <fcntl.h>

$ModuleInfo{'config'}{'off64_t'}

int
main ()
{
int fd = open("tmp.txt", O_RDONLY) ;
off64_t size ;

	size = lseek64(fd, -1, SEEK_END);
	printf("size=%lld", (long long int)size) ;

  return 0;
}
_ACEOF
	
	$ModuleInfo{'config'}{'lseek64'} = "" ;

#	c_try_link($msg, $code, $ok_val, $cflags, $exec_out_ref, $ld_flags) ;
	my $ac_lseek64 = c_try_link('lseek64', "checking for lseek64", $code, 1) ;
	if (!$ac_lseek64)
	{
		$ModuleInfo{'config'}{'lseek64'} = "#define lseek64 lseek" ;
	}

}


##-------------------------------------------------------------------------------------------
sub have_h
{
	my ($key, $header, $name, $val, $notval) = @_ ;
	
	$val = "1" unless defined($val) ;
	$notval = "" unless defined($notval) ;

	my $def ;
#	if ($key && exists($Config{$key}))
#	{
#		$def = $Config{$key} ;	
#	}
	
	if (!$def)
	{
		my $has = c_has_header($header) ;
		if ($has)
		{
			$def = 'define' ;
		}
	}
	if (!$def)
	{
		$def = 'undef' ;
	}
	
	my $str = "#$def $name " . ($def eq 'define' ? $val : $notval) ;
	$ModuleInfo{'config'}{$name} = $str ;

	return $str ;
}



##-------------------------------------------------------------------------------------------
sub have_d
{
	my ($key, $name, $val, $notval) = @_ ;
	
	$val = "1" unless defined($val) ;
	$notval = "" unless defined($notval) ;

	my $def = $Config{$key} || 'undef' ;
	my $str = "#$def $name " . ($def eq 'define' ? $val : $notval) ;
	$ModuleInfo{'config'}{$name} = $str ;

	return $str ;
}

##-------------------------------------------------------------------------------------------
# Define if not available - otherwise don't define
sub havent_d
{
	my ($key, $name, $val) = @_ ;
	
	$val = "" unless defined($val) ;

	my $str ;
	if ($Config{$key} eq 'define')
	{
		$str = "/* #define $name $val */"
	}
	else
	{
		$str = "#define $name $val"
	}
	$ModuleInfo{'config'}{$name} = $str ;

	return $str ;
}




##-------------------------------------------------------------------------------------------
sub have_func
{
	my ($key, $func, $name, $val, $notval) = @_ ;
	
	$val = "1" unless defined($val) ;
	$notval = "" unless defined($notval) ;

	my $def ;
#	if ($key && exists($Config{$key}))
#	{
#		$def = $Config{$key} ;	
#	}
	
	if (!$def)
	{
		my $has = c_has_function($func) ;
		if ($has)
		{
			$def = 'define' ;
		}
	}
	if (!$def)
	{
		$def = 'undef' ;
	}
	
	my $str = "#$def $name " . ($def eq 'define' ? $val : $notval) ;
	$ModuleInfo{'config'}{$name} = $str ;

	return $str ;
}

##-------------------------------------------------------------------------------------------
sub have_mathfunc
{
	my ($key, $func, $name, $val, $notval) = @_ ;
	
	$val = "1" unless defined($val) ;
	$notval = "" unless defined($notval) ;

	my $def ;
	if (!$def)
	{
		my $has = c_has_math_function($func) ;
		if ($has)
		{
			$def = 'define' ;
		}
		else
		{
			# extra check to ensure it's not a false negative(?)
			my $hasnt = c_replace_math_function($func) ;
			if (!$hasnt)
			{
				# Failed, so we have really got it?
				$def = 'define' ;
				$ModuleInfo{'COMMENTS'}{$name} = 'failed check of replacement' ;
			}
		}
	}
	if (!$def)
	{
		$def = 'undef' ;
	}
	
	my $str = "#$def $name " . ($def eq 'define' ? $val : $notval) ;
	$ModuleInfo{'config'}{$name} = $str ;

	return $str ;
}


##-------------------------------------------------------------------------------------------
sub _chk_arch_name
{
	my ($arch_name) = @_ ;

	my $arch = "" ;

	if ($arch_name =~ /ppc\-.*|powerpc\-.*/i)
	{
		$arch = "ARCH_PPC" ;
		
		# altivec?
	}
	elsif ($arch_name =~ /sparc\-*|sparc64\-.*/i)
	{
		$arch = "ARCH_SPARC" ;
	}
	elsif ($arch_name =~ /alpha.*/i)
	{
		$arch = "ARCH_ALPHA" ;
	}
	elsif ($arch_name =~ /arm.*/i)
	{
		$arch = "ARCH_ARM" ;
	}
	elsif ($arch_name =~ /i.86\-.*|k.\-.*|x86_64\-.*|x86\-.*|amd64\-.*|x86/i)
	{
		$arch = "ARCH_X86" ;
	}

	# keep trying with slightly relaxed regexps
	elsif ($arch_name =~ /ppc.*|powerpc.*/i)
	{
		$arch = "ARCH_PPC" ;
		
		# altivec?
	}
	elsif ($arch_name =~ /sparc*|sparc64.*/i)
	{
		$arch = "ARCH_SPARC" ;
	}
	elsif ($arch_name =~ /i.86.*|x86_64.*|x86.*|amd64.*|x86/i)
	{
		$arch = "ARCH_X86" ;
	}
	
	return $arch ;
}

##-------------------------------------------------------------------------------------------
sub arch_name
{
	my $arch = "" ;
	$ModuleInfo{'COMMENTS'}{'ARCH'} = "" ;

	## use %Config first
	my $arch_name = $Config{'archname'} ;
	$arch = _chk_arch_name($arch_name) ;
	$ModuleInfo{'COMMENTS'}{'ARCH'} = "archname = $arch_name" ;
	
	if (!$arch)
	{
		## Failed, so attempt to run uname
		if ($^O ne 'MSWin32')
		{
			$arch_name = `uname -a` ;
			chomp $arch_name ;
			$arch = _chk_arch_name($arch_name) ;
			$ModuleInfo{'COMMENTS'}{'ARCH'} = "uname = $arch_name" ;
		}
	}

	## Catch-all if everything else has failed...
	if (!$arch)
	{
		$arch = "ARCH_X86" ;
		$ModuleInfo{'COMMENTS'}{'ARCH'} ||= "Unable to determine" ;
	}

	$ModuleInfo{'config'}{'ARCH'} = $arch ;
	
	return $arch ;
}

##-------------------------------------------------------------------------------------------
sub get_align
{
	$ModuleInfo{'config'}{'ALIGN_BYTES'} = $Config{'alignbytes'} * 8 ;
}

##-------------------------------------------------------------------------------------------
sub get_size_t
{
	$ModuleInfo{'config'}{'size_t'} = $Config{'sizetype'} eq 'size_t' ? "" : "#define size_t unsigned int" ;
}

##-------------------------------------------------------------------------------------------
sub get_endian
{
	my $ENDIAN = "
#undef WORDS_BIGENDIAN
#undef SHORT_BIGENDIAN
#undef WORDS_LITTLEENDIAN
#undef SHORT_LITTLEENDIAN
" ;
	if ($Config{'byteorder'} =~ /^1/)
	{
		# little
		if ($Config{'byteorder'} eq '12345678')
		{
			# words
			$ENDIAN = "
#undef WORDS_BIGENDIAN
#undef SHORT_BIGENDIAN
#define WORDS_LITTLEENDIAN	1
#undef SHORT_LITTLEENDIAN
" ;
		}
		else
		{
			$ENDIAN = "
#undef WORDS_BIGENDIAN
#undef SHORT_BIGENDIAN
#undef WORDS_LITTLEENDIAN
#define SHORT_LITTLEENDIAN	1
" ;
		}
	}
	else
	{
		# big
		if ($Config{'byteorder'} eq '87654321')
		{
			# words
			$ENDIAN = "
#define WORDS_BIGENDIAN	1
#undef SHORT_BIGENDIAN
#undef WORDS_LITTLEENDIAN
#undef SHORT_LITTLEENDIAN
" ;
		}
		else
		{
			$ENDIAN = "
#undef WORDS_BIGENDIAN
#define SHORT_BIGENDIAN	1
#undef WORDS_LITTLEENDIAN
#undef SHORT_LITTLEENDIAN
" ;
		}
	}
	$ModuleInfo{'config'}{'ENDIAN'} = $ENDIAN ;
}


##-------------------------------------------------------------------------------------------
sub get_config
{
	$ModuleInfo{'config'} = {} ;
	
	# Arch
	arch_name() ;

	# OS
	$ModuleInfo{'config'}{'OS'} = uc("OS_" . $^O) ;

	# Alignment
	get_align() ;
	
	# Have ...
	have_func('d_ftime', 'ftime', 'HAVE_FTIME') ;
	have_func('d_gettimeod', 'gettimeofday', 'HAVE_GETTIMEOFDAY') ;
	have_mathfunc('', 'lrintf', 'HAVE_LRINTF') ;

	have_h('i_inttypes', 'inttypes.h', 'HAVE_INTTYPES_H') ;
	have_h('', 'io.h', 'HAVE_IO_H') ;
	have_h('i_memory', 'memory.h', 'HAVE_MEMORY_H') ;
	have_h('', 'stdint.h', 'HAVE_STDINT_H') ;
	have_h('i_stdlib', 'stdlib.h', 'HAVE_STDLIB_H') ;
	have_h('', 'strings.h', 'HAVE_STRINGS_H') ; 
	have_h('i_string', 'string.h', 'HAVE_STRING_H') ;
	have_h('i_sysstat', 'sys/stat.h', 'HAVE_SYS_STAT_H') ;
	have_h('', 'sys/timeb.h', 'HAVE_SYS_TIMEB_H') ; 
	have_h('i_systime', 'sys/time.h', 'HAVE_SYS_TIME_H') ;
	have_h('i_systypes', 'sys/types.h', 'HAVE_SYS_TYPES_H') ;
	have_h('i_time', 'time.h', 'HAVE_TIME_H') ;
	have_h('i_unistd', 'unistd.h', 'HAVE_UNISTD_H') ;
	have_h('', 'getopt.h', 'HAVE_GETOPT_H') ;
	
	
	# TODO: convert to live checks....
	have_d('uselargefiles', '_LARGE_FILES') ;
	havent_d('d_const', 'const') ;
	get_size_t() ;
	havent_d('d_volatile', 'volatile') ;
	
	# Endian 
	get_endian() ;
	
	# inline ?
	my $ac_c_inline = c_inline() ;
	my $ac_c_always_inline = c_always_inline($ac_c_inline) ;
	my $inline = $ac_c_always_inline || $ac_c_inline || "" ;
	if ($inline eq 'inline')
	{
		$ModuleInfo{'config'}{'inline'} = "" ;
	}
	else
	{
		$ModuleInfo{'config'}{'inline'} = "#define inline $inline" ;
	}
	
	# restrict ?
	$ModuleInfo{'config'}{'restrict'} = c_restrict() ;
	

	# timeval
	my $ac_struct_timeval = c_struct_timeval() ;
	$ModuleInfo{'config'}{'HAVE_STRUCT_TIMEVAL'} = $ac_struct_timeval ? "#define HAVE_STRUCT_TIMEVAL 1" : "#undef HAVE_STRUCT_TIMEVAL" ;
	
	# signal_t
	$ModuleInfo{'config'}{'RETSIGTYPE'} = $Config{'signal_t'} ? "#define RETSIGTYPE $Config{'signal_t'}" : "#define RETSIGTYPE void" ;

	# Builtin...
	$ModuleInfo{'config'}{'HAVE_BUILTIN_EXPECT'} = have_builtin_expect() ; 

	# Large file support
	check_largefile() ;

	return %{$ModuleInfo{'config'}} ;
}

#-----------------------------------------------------------------------------------------------------------------------
sub get_makemakerdflt 
{
	my $make =<<MAKEMAKERDFLT;

## Show config
makemakerdflt : showconfig all
	\$(NOECHO) \$(NOOP)

showconfig : FORCE 
	\$(NOECHO) \$(ECHO) "=================================================================="
	\$(NOECHO) \$(ECHO) "== CONFIG                                                       =="
	\$(NOECHO) \$(ECHO) "=================================================================="
	\$(NOECHO) \$(ECHO) "(Makeutils.pm version $VERSION)"
MAKEMAKERDFLT

	foreach my $var (sort keys %{$ModuleInfo{'config'}})
	{
		my $padded = sprintf "%-24s", "$var:" ;
		my $val = $ModuleInfo{'config'}{$var} ;
		
		## Special cases
		
		# ENDIAN is multi-line
		if ($var eq 'ENDIAN')
		{
			if ($val =~ m/#define (\w+)/)
			{
				$val = "#define $1 1" ;
			}
			else
			{
				$val = "" ;
			}
		}
		
		# Check for comment
#		if (exists($ModuleInfo{'COMMENTS'}{$var}))
#		{
#			$val .= "  ($ModuleInfo{'COMMENTS'}{$var})" ;
#		}
		$make .= "\t\$(NOECHO) \$(ECHO) \"$padded $val\"\n" ;
	}
	$make .= "\t\$(NOECHO) \$(ECHO) \"==================================================================\"\n" ;
	$make .= "\t\$(NOECHO) \$(ECHO) \"==\" \n" ;

	return $make ;
}




# ============================================================================================
# END OF PACKAGE


1;

__END__


  { echo "$as_me:$LINENO: checking for special C compiler options needed for large files" >&5
echo $ECHO_N "checking for special C compiler options needed for large files... $ECHO_C" >&6; }
if test "${ac_cv_sys_largefile_CC+set}" = set; then
  echo $ECHO_N "(cached) $ECHO_C" >&6
else
  ac_cv_sys_largefile_CC=no
     if test "$GCC" != yes; then
       ac_save_CC=$CC
       while :; do
	 # IRIX 6.2 and later do not support large files by default,
	 # so use the C compiler's -n32 option if that helps.
	 cat >conftest.$ac_ext <<_ACEOF
/* confdefs.h.  */
_ACEOF
cat confdefs.h >>conftest.$ac_ext
cat >>conftest.$ac_ext <<_ACEOF
/* end confdefs.h.  */
#include <sys/types.h>
 /* Check that off_t can represent 2**63 - 1 correctly.
    We can't simply define LARGE_OFF_T to be 9223372036854775807,
    since some C++ compilers masquerading as C compilers
    incorrectly reject 9223372036854775807.  */
#define LARGE_OFF_T (((off_t) 1 << 62) - 1 + ((off_t) 1 << 62))
  int off_t_is_large[(LARGE_OFF_T % 2147483629 == 721
		       && LARGE_OFF_T % 2147483647 == 1)
		      ? 1 : -1];
int
main ()
{

  ;
  return 0;
}
_ACEOF
	 rm -f conftest.$ac_objext
if { (ac_try="$ac_compile"
case "(($ac_try" in
  *\"* | *\`* | *\\*) ac_try_echo=\$ac_try;;
  *) ac_try_echo=$ac_try;;
esac
eval "echo \"\$as_me:$LINENO: $ac_try_echo\"") >&5
  (eval "$ac_compile") 2>conftest.er1
  ac_status=$?
  grep -v '^ *+' conftest.er1 >conftest.err
  rm -f conftest.er1
  cat conftest.err >&5
  echo "$as_me:$LINENO: \$? = $ac_status" >&5
  (exit $ac_status); } && {
	 test -z "$ac_c_werror_flag" ||
	 test ! -s conftest.err
       } && test -s conftest.$ac_objext; then
  break
else
  echo "$as_me: failed program was:" >&5
sed 's/^/| /' conftest.$ac_ext >&5


fi

rm -f core conftest.err conftest.$ac_objext
	 CC="$CC -n32"
	 rm -f conftest.$ac_objext
if { (ac_try="$ac_compile"
case "(($ac_try" in
  *\"* | *\`* | *\\*) ac_try_echo=\$ac_try;;
  *) ac_try_echo=$ac_try;;
esac
eval "echo \"\$as_me:$LINENO: $ac_try_echo\"") >&5
  (eval "$ac_compile") 2>conftest.er1
  ac_status=$?
  grep -v '^ *+' conftest.er1 >conftest.err
  rm -f conftest.er1
  cat conftest.err >&5
  echo "$as_me:$LINENO: \$? = $ac_status" >&5
  (exit $ac_status); } && {
	 test -z "$ac_c_werror_flag" ||
	 test ! -s conftest.err
       } && test -s conftest.$ac_objext; then
  ac_cv_sys_largefile_CC=' -n32'; break
else
  echo "$as_me: failed program was:" >&5
sed 's/^/| /' conftest.$ac_ext >&5


fi

rm -f core conftest.err conftest.$ac_objext
	 break
       done
       CC=$ac_save_CC
       rm -f conftest.$ac_ext
    fi
fi
{ echo "$as_me:$LINENO: result: $ac_cv_sys_largefile_CC" >&5
echo "${ECHO_T}$ac_cv_sys_largefile_CC" >&6; }
  if test "$ac_cv_sys_largefile_CC" != no; then
    CC=$CC$ac_cv_sys_largefile_CC
  fi





  { echo "$as_me:$LINENO: checking for _FILE_OFFSET_BITS value needed for large files" >&5
echo $ECHO_N "checking for _FILE_OFFSET_BITS value needed for large files... $ECHO_C" >&6; }
if test "${ac_cv_sys_file_offset_bits+set}" = set; then
  echo $ECHO_N "(cached) $ECHO_C" >&6
else
  while :; do
  cat >conftest.$ac_ext <<_ACEOF
/* confdefs.h.  */
_ACEOF
cat confdefs.h >>conftest.$ac_ext
cat >>conftest.$ac_ext <<_ACEOF
/* end confdefs.h.  */
#include <sys/types.h>
 /* Check that off_t can represent 2**63 - 1 correctly.
    We can't simply define LARGE_OFF_T to be 9223372036854775807,
    since some C++ compilers masquerading as C compilers
    incorrectly reject 9223372036854775807.  */
#define LARGE_OFF_T (((off_t) 1 << 62) - 1 + ((off_t) 1 << 62))
  int off_t_is_large[(LARGE_OFF_T % 2147483629 == 721
		       && LARGE_OFF_T % 2147483647 == 1)
		      ? 1 : -1];
int
main ()
{

  ;
  return 0;
}
_ACEOF
rm -f conftest.$ac_objext
if { (ac_try="$ac_compile"
case "(($ac_try" in
  *\"* | *\`* | *\\*) ac_try_echo=\$ac_try;;
  *) ac_try_echo=$ac_try;;
esac
eval "echo \"\$as_me:$LINENO: $ac_try_echo\"") >&5
  (eval "$ac_compile") 2>conftest.er1
  ac_status=$?
  grep -v '^ *+' conftest.er1 >conftest.err
  rm -f conftest.er1
  cat conftest.err >&5
  echo "$as_me:$LINENO: \$? = $ac_status" >&5
  (exit $ac_status); } && {
	 test -z "$ac_c_werror_flag" ||
	 test ! -s conftest.err
       } && test -s conftest.$ac_objext; then
  ac_cv_sys_file_offset_bits=no; break
else
  echo "$as_me: failed program was:" >&5
sed 's/^/| /' conftest.$ac_ext >&5


fi

rm -f core conftest.err conftest.$ac_objext conftest.$ac_ext
  cat >conftest.$ac_ext <<_ACEOF
/* confdefs.h.  */
_ACEOF
cat confdefs.h >>conftest.$ac_ext
cat >>conftest.$ac_ext <<_ACEOF
/* end confdefs.h.  */
#define _FILE_OFFSET_BITS 64
#include <sys/types.h>
 /* Check that off_t can represent 2**63 - 1 correctly.
    We can't simply define LARGE_OFF_T to be 9223372036854775807,
    since some C++ compilers masquerading as C compilers
    incorrectly reject 9223372036854775807.  */
#define LARGE_OFF_T (((off_t) 1 << 62) - 1 + ((off_t) 1 << 62))
  int off_t_is_large[(LARGE_OFF_T % 2147483629 == 721
		       && LARGE_OFF_T % 2147483647 == 1)
		      ? 1 : -1];
int
main ()
{

  ;
  return 0;
}
_ACEOF
rm -f conftest.$ac_objext
if { (ac_try="$ac_compile"
case "(($ac_try" in
  *\"* | *\`* | *\\*) ac_try_echo=\$ac_try;;
  *) ac_try_echo=$ac_try;;
esac
eval "echo \"\$as_me:$LINENO: $ac_try_echo\"") >&5
  (eval "$ac_compile") 2>conftest.er1
  ac_status=$?
  grep -v '^ *+' conftest.er1 >conftest.err
  rm -f conftest.er1
  cat conftest.err >&5
  echo "$as_me:$LINENO: \$? = $ac_status" >&5
  (exit $ac_status); } && {
	 test -z "$ac_c_werror_flag" ||
	 test ! -s conftest.err
       } && test -s conftest.$ac_objext; then
  ac_cv_sys_file_offset_bits=64; break
else
  echo "$as_me: failed program was:" >&5
sed 's/^/| /' conftest.$ac_ext >&5


fi

rm -f core conftest.err conftest.$ac_objext conftest.$ac_ext
  ac_cv_sys_file_offset_bits=unknown
  break
done
fi
{ echo "$as_me:$LINENO: result: $ac_cv_sys_file_offset_bits" >&5
echo "${ECHO_T}$ac_cv_sys_file_offset_bits" >&6; }
case $ac_cv_sys_file_offset_bits in #(
  no | unknown) ;;
  *)
cat >>confdefs.h <<_ACEOF
#define _FILE_OFFSET_BITS $ac_cv_sys_file_offset_bits
_ACEOF
;;
esac
rm -f conftest*
  if test $ac_cv_sys_file_offset_bits = unknown; then
    { echo "$as_me:$LINENO: checking for _LARGE_FILES value needed for large files" >&5
echo $ECHO_N "checking for _LARGE_FILES value needed for large files... $ECHO_C" >&6; }
if test "${ac_cv_sys_large_files+set}" = set; then
  echo $ECHO_N "(cached) $ECHO_C" >&6
else
  while :; do
  cat >conftest.$ac_ext <<_ACEOF
/* confdefs.h.  */
_ACEOF
cat confdefs.h >>conftest.$ac_ext
cat >>conftest.$ac_ext <<_ACEOF
/* end confdefs.h.  */
#include <sys/types.h>
 /* Check that off_t can represent 2**63 - 1 correctly.
    We can't simply define LARGE_OFF_T to be 9223372036854775807,
    since some C++ compilers masquerading as C compilers
    incorrectly reject 9223372036854775807.  */
#define LARGE_OFF_T (((off_t) 1 << 62) - 1 + ((off_t) 1 << 62))
  int off_t_is_large[(LARGE_OFF_T % 2147483629 == 721
		       && LARGE_OFF_T % 2147483647 == 1)
		      ? 1 : -1];
int
main ()
{

  ;
  return 0;
}
_ACEOF
rm -f conftest.$ac_objext
if { (ac_try="$ac_compile"
case "(($ac_try" in
  *\"* | *\`* | *\\*) ac_try_echo=\$ac_try;;
  *) ac_try_echo=$ac_try;;
esac
eval "echo \"\$as_me:$LINENO: $ac_try_echo\"") >&5
  (eval "$ac_compile") 2>conftest.er1
  ac_status=$?
  grep -v '^ *+' conftest.er1 >conftest.err
  rm -f conftest.er1
  cat conftest.err >&5
  echo "$as_me:$LINENO: \$? = $ac_status" >&5
  (exit $ac_status); } && {
	 test -z "$ac_c_werror_flag" ||
	 test ! -s conftest.err
       } && test -s conftest.$ac_objext; then
  ac_cv_sys_large_files=no; break
else
  echo "$as_me: failed program was:" >&5
sed 's/^/| /' conftest.$ac_ext >&5


fi

rm -f core conftest.err conftest.$ac_objext conftest.$ac_ext
  cat >conftest.$ac_ext <<_ACEOF
/* confdefs.h.  */
_ACEOF
cat confdefs.h >>conftest.$ac_ext
cat >>conftest.$ac_ext <<_ACEOF
/* end confdefs.h.  */
#define _LARGE_FILES 1
#include <sys/types.h>
 /* Check that off_t can represent 2**63 - 1 correctly.
    We can't simply define LARGE_OFF_T to be 9223372036854775807,
    since some C++ compilers masquerading as C compilers
    incorrectly reject 9223372036854775807.  */
#define LARGE_OFF_T (((off_t) 1 << 62) - 1 + ((off_t) 1 << 62))
  int off_t_is_large[(LARGE_OFF_T % 2147483629 == 721
		       && LARGE_OFF_T % 2147483647 == 1)
		      ? 1 : -1];
int
main ()
{

  ;
  return 0;
}
_ACEOF
rm -f conftest.$ac_objext
if { (ac_try="$ac_compile"
case "(($ac_try" in
  *\"* | *\`* | *\\*) ac_try_echo=\$ac_try;;
  *) ac_try_echo=$ac_try;;
esac
eval "echo \"\$as_me:$LINENO: $ac_try_echo\"") >&5
  (eval "$ac_compile") 2>conftest.er1
  ac_status=$?
  grep -v '^ *+' conftest.er1 >conftest.err
  rm -f conftest.er1
  cat conftest.err >&5
  echo "$as_me:$LINENO: \$? = $ac_status" >&5
  (exit $ac_status); } && {
	 test -z "$ac_c_werror_flag" ||
	 test ! -s conftest.err
       } && test -s conftest.$ac_objext; then
  ac_cv_sys_large_files=1; break
else
  echo "$as_me: failed program was:" >&5
sed 's/^/| /' conftest.$ac_ext >&5


fi

rm -f core conftest.err conftest.$ac_objext conftest.$ac_ext
  ac_cv_sys_large_files=unknown
  break
done
fi
{ echo "$as_me:$LINENO: result: $ac_cv_sys_large_files" >&5
echo "${ECHO_T}$ac_cv_sys_large_files" >&6; }
case $ac_cv_sys_large_files in #(
  no | unknown) ;;
  *)
cat >>confdefs.h <<_ACEOF
#define _LARGE_FILES $ac_cv_sys_large_files
_ACEOF
;;
esac
rm -f conftest*
  fi
fi

