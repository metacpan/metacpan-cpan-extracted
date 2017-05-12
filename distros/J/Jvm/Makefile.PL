#!/usr/bin/perl -w
#Ident = $Id: Makefile.PL,v 1.13 2000/09/24 05:06:15 yw Exp $

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use strict;
use File::Find;
use File::Basename;

use vars qw(%JAVA_LIB %JAVA_SO %JAVA_INC);

my $JAVA_HOME=$ENV{JAVA_HOME};

if(! $JAVA_HOME) {
    print "Please input your JDK HOME path (e.g. /usr/local/jdk1.3) : ";
    $JAVA_HOME=<STDIN>;
    chomp($JAVA_HOME);
}

if(! -d $JAVA_HOME) {
    die "JAVA_HOME: '$JAVA_HOME' doesn't exist!";
}

if($JAVA_HOME !~/1\.3/) {
    print <<"EOF";
WARNING: This package *ONLY* works with JDK1.3 beta or above!
         If the JDK version on your box is below than 1.3, it may NOT work!
EOF
}

print "Searching files under '$JAVA_HOME' ...\n";
find(\&search, $JAVA_HOME);

if(scalar keys(%JAVA_LIB) == 0) {
    die "Sorry, 'libjava.*' lib not found under '$JAVA_HOME'.";
}
if(scalar keys(%JAVA_SO) == 0) {
    die "Sorry, '*.so' not found under '$JAVA_HOME'.";
}
if(scalar keys(%JAVA_INC) == 0) {
    die "Sorry, '*.h' not found under '$JAVA_HOME'.";
}

takeOutExtraSoPath(\%JAVA_SO);

print "1. Found 'libjava.so':\n" . join("\n", getSortedPath(%JAVA_LIB)) . "\n";
print "2. Found '*.so':\n"       . join("\n", getSortedPath(%JAVA_SO))  . "\n";
print "3. Found '*.h':\n"        . join("\n", getSortedPath(%JAVA_INC)) . "\n";

my $lib_1 = join(":",   getSortedPath(%JAVA_SO));
my $lib_2 = join("\n#", getSortedPath(%JAVA_SO));
print << "EOF";
#############################################################
# To work with 'Jvm' package, you need add your Java
# shared library path to either LD_LIBRARY_PATH shell 
# environment or in /etc/ld.so.conf, so that Java shared 
# library can be loaded when nessary.
# You need do eithe A or B beforen next step:
# A) set LD_LIBRARY_PATH environment variable
#    Add Java shared library paths in your LD_LIBRARY_PATH, e.g.
#    csh, tcsh:
#     setenv LD_LIBRARY_PATH $lib_1
#    sh, bash, ksh:
#     export LD_LIBRARY_PATH=$lib_1
# B) edit /etc/ld.so.conf file
#    Add the following lines in your /etc/ld.so.conf 
#    then run "ldconfig".
#$lib_2
#
# Following steps are:
#  make
#  make test
#  make install
#############################################################
EOF


WriteMakefile(
    'NAME'	=> 'Jvm',
    'VERSION_FROM' => 'Jvm.pm', # finds $VERSION
    'LIBS'	=> join(" ", map { "-L$_" } getSortedPath(%JAVA_LIB)) . " -ljava",   # e.g., '-lm' 
    'DEFINE'	=> "",     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> join(" ", map { "-I$_" } getSortedPath(%JAVA_INC)),     # e.g., '-I/usr/include/other' 
	'OBJECT' => "Jvm\$(OBJ_EXT)",
	"AUTHOR"    => "Ye, Wei",
	"clean"     => {FILES=> "*.class"},
);

sub getSortedPath {
    my(%path) = @_;
    return sort keys %path;
}

sub search {
    my $basename = basename($File::Find::name);
    my $dirname  = dirname($File::Find::name);

    if($basename=~/^libjava\./) {
	$JAVA_LIB{$dirname} = 1;
    }
    if($basename=~/\.so$/) {
	$JAVA_SO{$dirname} = 1;
    }
    if($basename=~/\.h$/) {
	$JAVA_INC{$dirname} = 1;
    }

}

sub takeOutExtraSoPath {
    my($so_path) = @_;

    if(mymatch('hotspot$', $so_path)) {
        # if 'hostspot' found, take out others
	mydel('classic$',        $so_path);
        mydel('green_threads$',  $so_path);
        mydel('native_threads$', $so_path);
        mydel('server$',         $so_path);
    } elsif (mymatch('green_threads$', $so_path)) {
	# if 'green_threads' found, take out others
	mydel('classic$',        $so_path);
        mydel('native_threads$', $so_path);
        mydel('server$',         $so_path);
    }
}

# to check if the hash match a regualar express
sub mymatch {
    my($patt, $dir) = @_;
    foreach (keys %{$dir}) {
	if($_=~/$patt/) {
	    return 1;
	}
    }
    return 0;
}

# undefine key out of hash if it matches RE $patt
sub mydel {
    my($patt, $dir) = @_;
    foreach (keys %{$dir}) {
	if($_=~/$patt/) {
	    delete $dir->{$_};
	}
    }
}
