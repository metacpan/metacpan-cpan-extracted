use ExtUtils::MakeMaker ;

use strict ;
use File::Spec ;
use Cwd ;
use Config ;

require "Java/Portable.pm" ;

print "\nWelcome to the Inline::Java installation procedure.\n\n" ;

# Hide PerlNatives by default...
$main::build_perl_natives = 0 ;

# Grab the J2SDK argument
my $jdk_dir = '' ;
for (my $i = 0 ; $i < scalar(@ARGV) ; $i++){
	my $remove = 0 ;
	if ($ARGV[$i] =~ /^J2SDK=(.+)$/){
		$jdk_dir = $1 ;
		$remove = 1 ;
	}
	elsif ($ARGV[$i] =~ /^BUILD_JNI=(.+)$/){
		$main::build_jni = $1 ;
		$remove = 1 ;
	}
	elsif ($ARGV[$i] =~ /^BUILD_PERL_NATIVES=(.+)$/){
		$main::build_perl_natives = $1 ;
		$remove = 1 ;
	}
	elsif ($ARGV[$i] =~ /^BUILD_PERL_INTERPRETER=(.+)$/){
		$main::build_perl_interpreter = $1 ;
		$remove = 1 ;
	}
	elsif ($ARGV[$i] =~ /^JVM_LIB_TYPE=(.+)$/){
		$main::jvm_lib_type = $1 ;
		$remove = 1 ;
	}
	if ($remove){
		splice(@ARGV, $i, 1) ;
		$i-- ;
	}
}

if (! $jdk_dir){
	my $try = $ENV{PERL_INLINE_JAVA_J2SDK} || $ENV{JAVA_HOME} 
		|| Inline::Java::Portable::portable('DEFAULT_J2SDK_DIR') ;
	print "Using $try as J2SDK directory.\n\n" if $try ;
	$jdk_dir = $try ;
}

if (! $jdk_dir){
	my $def_pl = File::Spec->catfile('Java', 'default_j2sdk.pl') ;
	if (-e $def_pl){
		require File::Spec->catfile('Java', 'default_j2sdk.pl') ;
		$jdk_dir = Inline::Java::get_default_j2sdk() ;
	}
	else {
		print <<NO_J2SDK;
A Java 2 SDK is required to install and use Inline::Java. Please 
specify your Java 2 SDK installation directory using the J2SDK 
option to Makefile.PL as such:

    perl Makefile.PL J2SDK=/path/to/your/j2sdk/installation

You can set the JAVA_HOME environment variable to specify your
Java 2 SDK installation directory. For example, if you are using
the CPAN installer you can do:

    JAVA_HOME=/path/to/your/j2sdk/installation cpan Inline::Java
NO_J2SDK
		exit(1) ;
	}
}
elsif (! -d $jdk_dir){
	print <<BAD_J2SDK;
Java 2 SDK installation directory '$jdk_dir' does not exist.
BAD_J2SDK
	exit(1) ;
}
my $perl_jdk_dir = $jdk_dir ;
$perl_jdk_dir =~ s/'/\'/g ;

# Check directory
my $jdk_bin = Inline::Java::Portable::portable("J2SDK_BIN") ;
my $ext = Inline::Java::Portable::portable('EXE_EXTENSION') ;
foreach my $f ('javac', 'jar', 'java'){
	if (! -f File::Spec->catfile($jdk_dir, $jdk_bin, $f . $ext)){
		my $bf = File::Spec->catfile($jdk_bin, $f . $ext) ;
		print "Can't locate file '$bf' anywhere under '$jdk_dir'\n" ;
	}
}


# Now we have the J2SDK directory and it exists.
# We will create the default_j2sdk.pl file that
# will contain that value for future use.
my $def_jdk = File::Spec->catfile('Java', 'default_j2sdk.pl') ;
open(J2SDK, ">$def_jdk") or
	die("Can't open '$def_jdk' for writing: $!") ;
print J2SDK <<J2SDK_PL;
# This file is created by the Makefile.PL for Inline::Java
# You can modify it if you wish
use strict ;

# The default J2SDK to use for Inline::Java. You can change
# it if this value becomes invalid.
sub Inline::Java::get_default_j2sdk {
	return '$perl_jdk_dir' ;
}
1 ;


J2SDK_PL
close(J2SDK) ;

print <<SAVE_J2SDK;
Default J2SDK for Inline::Java will be '$jdk_dir'.
See module documentation for information on how to use a different J2SDK
or change this default value.

SAVE_J2SDK


# We will now add the building of our Java files to the Makefile.
my $javac = File::Spec->catfile($jdk_dir, $jdk_bin, 'javac' . $ext) ;
my $jar = File::Spec->catfile($jdk_dir, $jdk_bin, 'jar' . $ext) ;                      
my $src_dir = File::Spec->catdir('Java', 'sources', 'org', 'perl', 'inline', 'java') ;
my $src = File::Spec->catfile($src_dir, '*.java') ;
my $obj_dir = File::Spec->catdir('Java', 'classes') ;
my $server_arch = File::Spec->catfile('Java', 'InlineJavaServer.jar') ;
my $user_arch = File::Spec->catfile('Java', 'InlineJavaUser.jar') ;

# Create the object diretory because later we need to put the properties
# file inside it.
if (! -e $obj_dir){
	mkdir($obj_dir) or
		die("Can't create object directory '$obj_dir': $!") ;
}

sub MY::top_targets {
	my $this = shift ;

	my $make = <<MAKE ;
# Added by Inline::Java installation
pure_all :: java
MAKE

	return $make . $this->MM::top_targets() ;
}


my $INSTALLSITEARCH = '' ;
my $INST_ARCHLIB = '' ;
sub MY::postamble {
	my $this = shift ;

	my $java_src = join(' ', glob($src), File::Spec->catfile($obj_dir, 'InlineJava.properties')) ;

	my $make = <<MAKE ;
# Added by Inline::Java installation
JAVA_SRC=$java_src 

java.ts: \$(JAVA_SRC)
	\@\$(MKPATH) $obj_dir
	"$javac" -deprecation -g -d $obj_dir $src
	"$jar" cf $server_arch -C $obj_dir org -C $obj_dir InlineJava.properties
	"$jar" cf $user_arch -C $obj_dir InlineJavaUserClassLink.class
	\@\$(TOUCH) java.ts

java :: java.ts
MAKE

	# Used for PerlNatives
	$INSTALLSITEARCH = expand_macros($this, 'INSTALLSITEARCH') ;
	$INST_ARCHLIB = expand_macros($this, 'INST_ARCHLIB') ;

	return $make ;
}


sub expand_macros { 
	my $mm = shift ;
	my $var = shift ;

	my $val = $mm->{$var} ;
	while ($val =~ s/\$\((.*?)\)/$mm->{$1}/){}
	$val =~ s/\\/\\\\/g ;

	return $val ;
}


# Write the Makefile
my $natives_test = File::Spec->catdir('Java', 'Natives', '_Inline_test') ;
my $perlinterp_test = File::Spec->catdir('Java', 'PerlInterpreter', '_Inline_test') ;
WriteMakefile(
	NAME => 'Inline::Java',
	VERSION_FROM => 'Java.pm',
	DIR => ['Java'],
	PREREQ_PM => {
		Inline	=> 0.44,
		Test => 1.13,
		'MIME::Base64' => 0,
	},
	PM => {
		'Java.pm' => File::Spec->catfile('$(INST_LIBDIR)', 'Java.pm'),
		'Java.pod'=> File::Spec->catfile('$(INST_LIBDIR)', 'Java.pod'),
		$server_arch => File::Spec->catfile('$(INST_LIBDIR)', $server_arch),
		$user_arch => File::Spec->catfile('$(INST_LIBDIR)', $user_arch),
	},
	clean => {FILES => "$def_jdk _Inline_test $natives_test $perlinterp_test $obj_dir $server_arch $user_arch java.ts"},
	($] >= 5.005 ?     ## Add these new keywords supported since 5.005
		(ABSTRACT_FROM  => 'Java.pod', # retrieve abstract from module
		AUTHOR         => 'Patrick LeBoutillier <patl@cpan.org>') : ()),
) ;


# Add the so_dirs to the default_j2sdk.pl file.
open(J2SDK, ">>$def_jdk") or
	die("Can't open '$def_jdk' for appending: $!") ;
print J2SDK <<J2SDK_PL;
sub Inline::Java::get_default_j2sdk_so_dirs {
	return (
J2SDK_PL
foreach my $d (@main::SO_DIRS){
	$d =~ s/'/\'/g ;
	print J2SDK "\t\t'$d',\n" ;
}
print J2SDK <<J2SDK_PL;
	) ;
}


1 ;
J2SDK_PL
close(J2SDK) ;



# Create the properties that will be included in the jar.
my @perlnatives_so_parts = ("auto", "Inline", "Java", "PerlNatives", 
	"PerlNatives." . Inline::Java::Portable::portable('SO_EXT')) ;
my $install_perlnatives_so = File::Spec->catfile($INSTALLSITEARCH, @perlnatives_so_parts) ;
$install_perlnatives_so = Inline::Java::Portable::portable("SUB_FIX_JAVA_PATH", $install_perlnatives_so) ;
$install_perlnatives_so =~ s/\\/\\\\/g ;
my $test_perlnatives_so = File::Spec->rel2abs(File::Spec->catfile($INST_ARCHLIB, @perlnatives_so_parts)) ;
$test_perlnatives_so = Inline::Java::Portable::portable("SUB_FIX_JAVA_PATH", $test_perlnatives_so) ;
$test_perlnatives_so =~ s/\\/\\\\/g ;

my @perlinterpreter_so_parts = ("auto", "Inline", "Java", "PerlInterpreter",
    "PerlInterpreter." . Inline::Java::Portable::portable('SO_EXT')) ;
my $install_perlinterpreter_so = File::Spec->catfile($INSTALLSITEARCH, @perlinterpreter_so_parts) ;
$install_perlinterpreter_so = Inline::Java::Portable::portable("SUB_FIX_JAVA_PATH", $install_perlinterpreter_so) ;
$install_perlinterpreter_so =~ s/\\/\\\\/g ;
my $test_perlinterpreter_so = File::Spec->rel2abs(File::Spec->catfile($INST_ARCHLIB, @perlinterpreter_so_parts)) ;
$test_perlinterpreter_so = Inline::Java::Portable::portable("SUB_FIX_JAVA_PATH", $test_perlinterpreter_so) ;
$test_perlinterpreter_so =~ s/\\/\\\\/g ;

my $libperl = $Config{libperl} ;
my $dlext = $Config{dlext} ;
my $libperl_so = '' ;
if ($libperl =~ /\.$dlext$/){
	$libperl_so = File::Spec->catfile($Config{installarchlib}, 'CORE', $libperl) ;
}

my $prop = File::Spec->catfile($obj_dir, 'InlineJava.properties') ;
open(PROP, ">$prop") or
	die("Can't open '$prop' for writing: $!") ;
print PROP <<PROP;
# This file is created by the Makefile.PL for Inline::Java
inline_java_perlnatives_so_install = $install_perlnatives_so
inline_java_perlnatives_so_test    = $test_perlnatives_so
inline_java_perlinterpreter_so_install = $install_perlinterpreter_so
inline_java_perlinterpreter_so_test    = $test_perlinterpreter_so
inline_java_libperl_so	= $libperl_so
PROP
close(PROP) ;

# Clean up the Makefile for Win95/98/Me
if (Inline::Java::Portable::portable('COMMAND_COM')){
	print "\nFixing Makefile for Win95/98/Me...\n" ;
	open(MAKEFILE, "<Makefile") or die "Can't open Makefile for reading" ;
	my @lines = <MAKEFILE> ;
	close(MAKEFILE) ;
	open(MAKEFILE, ">Makefile") or die "Can't open Makefile for writing" ;
	foreach my $line (@lines){
		if ($line !~ /^\s*((\@\[)|(\]))\s*$/){
			print MAKEFILE $line ;
		}
	}
	close(MAKEFILE) ;
}

my $make = Inline::Java::Portable::portable('MAKE') ;
print "\nYou can continue the installation with the following commands:\n" ;
print "  % $make\n" ;
print "  % $make test\n" ;
print "  % $make install\n" ; 
