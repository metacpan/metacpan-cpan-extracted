use ExtUtils::MakeMaker;

print "\n\n\nWelcome to the Db::Documentum installation process.\n";
print "***************************************************\n";

unless ($OS = $^O) {
	   require Config;
	   $OS = $Config::Config{'osname'};
}
print "\tConfiguring Db::Documentum for $OS...\n";

##################################################################
# *** Windows NT/2000/XP users should look here ***
##################################################################
if ($OS =~ /Win/i) {
    $DMCL = 'dmcl40.lib';

	# Path to Documentum installation directory.
	$DM_HOME = "c:\\program files\\documentum";

    print "\n\nDocumentum install directory:\n";
    print "-----------------------------\n";
    print "Enter the path to the Documentum installation directory:\n";
    print "\t[$DM_HOME] ==>";
    chomp($ans = <STDIN>);
    if ($ans =~ /\w+/) {
        $DM_HOME = $ans;
    }

	# Path to Documentum library (dmcl40.lib).
	$DM_LIB = "$DM_HOME\\shared";

    print "\n\n$DMCL library file:\n";
    print "------------------------\n";
    print "*** NOTE *** The $DMCL library file is located in the\n";
    print "Documentum\\share\\clients\\win\\32 directory on the \n";
    print "Content Server. I recommend copying it to the \n";
    print "$DM_LIB directory for simplicity.\n";
    print "\nEnter the path to the $DMCL library file:\n";
    print "\t[$DM_LIB] ==>";
    chomp($ans = <STDIN>);
    if ($ans =~ /\w+/) {
        $DM_LIB = $ans;
    }

    # check for DMCL library file
    if (! -e "$DM_LIB\\$DMCL") {
        warn "\n*** WARNING *** Could not find $DM_LIB\\$DMCL.\nThe module will not make without " .
             "$DMCL.\nPlease copy $DMCL to the $DM_LIB directory.\n";
    }

	# Path to dmapp.h.
	$DM_INCLUDE = "$DM_HOME\\shared";

    print "\n\ndmapp.h header file:\n";
    print "--------------------\n";
    print "*** NOTE *** The dmapp.h header file is located in the\n";
    print "Documentum\\share\\sdk\\include directory on the Content\n";
    print "Server. I recommend copying it to the \n";
    print "$DM_INCLUDE directory for simplicity.\n";
    print "\nEnter the path to the dmapp.h header file:\n";
    print "\t[$DM_INCLUDE] ==>";
    chomp($ans = <STDIN>);
    if ($ans =~ /\w+/) {
        $DM_INCLUDE = $ans;
    }

    # check for api header file
    if (! -e "$DM_INCLUDE\\dmapp.h") {
        warn "\n*** WARNING *** Could not find $DM_INCLUDE\\dmapp.h.\nThe module will not make without " .
             "dmapp.h.\nPlease copy dmapp.h to the $DM_INCLUDE directory.\n";
    }

    # get the CPP include and lib paths from the environment
    my $inc = $ENV{INCLUDE};
    warn "\n*** WARNING *** No INCLUDE environment variable found.  You may need to run VCVARS32.BAT" .
         " before running nmake.\n" unless $inc;
    $inc = "-I\"" . join("\" -I\"",split(";",$inc)) . "\"";

    my $lib = $ENV{LIB};
    warn "\n*** WARNING *** No LIB environment variable found.  You may need to run VCVARS32.BAT" .
         " before running nmake.\n" unless $lib;
    $lib = "-L\"" . join("\" -L\"",split(";",$lib)) . "\"";

    # build all nmake parameters
    $CPP_INCS = $inc;
    $DM_INCLUDE = "-I\"$DM_INCLUDE\"";
	$CPP_LIBS = $lib;
	$DM_CLIENT_LIBS = "-L\"$DM_LIB\" -l$DMCL";
    # Not used for Win32 nmake
	$LD_LIBS = "";
	$DM_RPC_LIBS = "";
	$OS_LIBS = "";
	$CCFLAGS = "";
}

##################################################################
# *** Unix users (Solaris, AIX) should look here ***
##################################################################
elsif ( ($OS =~ /solaris/i) or ($OS =~ /aix/i) ) {

	# The path to your Documentum client installation.
	$DM_HOME = '/usr/local/documentum';

	# If you've organized your Documentum libraries in the standard unix-y
	# bin, lib, include fashion, then you should be all set.  Otherwise you
	# may have to tweak these.

	# Path to documentum client libraries.
	$DM_LIB = "$DM_HOME/lib";

	# Path to directory where dmapp.h lives.
	$DM_INCLUDE = "-I$DM_HOME/include";

	$DM_CLIENT_LIBS = "-L$DM_LIB -ldmapi -ldmupper -ldmlower -ldmcommon -ldmupper -lcompat";
	$DM_RPC_LIBS = "-L$DM_LIB -lnwrpc -lnwstcp";
	$OS_LIBS = "-lsocket -lnsl -lintl";
	$CPP_LIBS = "-lC";
	$LD_LIBS = "-ldl";
	$CPP_INC = "";
	$CCFLAGS = "";
}

##################################################################
# *** HP Unix (HP-UX) users should look here ***
##################################################################

elsif ($OS =~ /hpux/i) {

	# The path to your Documentum client installation.
	$DM_HOME = '/usr/local/documentum';

	# If you've organized your Documentum libraries in the standard unix-y
	# bin, lib, include fashion, then you should be all set.  Otherwise you
	# may have to tweak these.

	# Path to documentum client libraries.
	$DM_LIB = "$DM_HOME/lib";

	# Path to directory where dmapp.h lives.
	$DM_INCLUDE = "-I$DM_HOME/include";

	$DM_CLIENT_LIBS = "-L$DM_LIB -lDMCL40 -lc";
	$DM_RPC_LIBS = "-L$DM_LIB -lnwrpc -lnwstcp";
	$OS_LIBS = "-lsocket -lnsl -lintl";
	$CPP_LIBS = "-lC";
	$LD_LIBS = "-ldl";
	$CPP_INC = "";
	$CCFLAGS = '+DA1.1 +DS2.0 -ext -D_REENTRANT -D_PTHREAD_DRAFT4 -DSYSV -Dhpux -Dunix=unix -DOS_UNIX -DTHREADED_UNIX -DVDK_CE_ANSI -DEBHPUX +Z -Wl,+s,-E -D_POSIX_C_SOURCE=199506L -w +W829 -D_HPUX_SOURCE'
}

##########################################################################
# *** Linux - Tested using Redhat Enterprise 3 with Documentum 5.3 SP1 ***
# *** Note: Returned warning on missing -lC during perl Makefile.PL    ***
# ***       but it worked nonetheless...                               ***
#########################################################################
elsif ( $OS =~ /linux/i ) {

	# The path to your Documentum client installation.
	$DM_HOME = '/documentum/product/5.3';

    # dmcl.so file
    if (! -e "$DM_HOME\\dmcl.so") {
        warn "\n*** WARNING *** Could not find $DM_HOME\\dmcl.so.\nThe module will not make without " .
             "dmcl.so.\n";
    }

	# This is kinda a gottcha, the Linux stuff is in unix/linux
	# You may have to tweak these.

	# Path to documentum client libraries.
	$DM_LIB = "$DM_HOME/unix/linux";

	# Path to directory where dmapp.h lives.
	$DM_INCLUDE = "-I/documentum/share/sdk/include/";

	$DM_CLIENT_LIBS = "-L$DM_LIB -ldmapi -ldmupper -ldmlower -ldmcommon -ldmupper -lcompat";
	$DM_RPC_LIBS = "-L$DM_LIB -lnwrpc -lnwstcp";
	$OS_LIBS = "-lsocket -lnsl -lintl";
	$CPP_LIBS = "-lC";
	$LD_LIBS = "-ldl";
	$CPP_INC = "";
	$CCFLAGS = "";
}

##################################################################
# Otherwise you're out of luck.  If you have an environment you
# would like included in the install process, email me your changes
# or better yet, your makefile.pl.
##################################################################
else {
	die "$OS is not a supported platform for Db::Documentum (or for Documentum in general).\n";
}

# print config summary
print "\n\nConfig summary:\n";
print "---------------\n";
print "DM_HOME = $DM_HOME\n";
print "DM_LIB = $DM_LIB\n";
print "DM_INCLUDE = $DM_INCLUDE\n";
print "CPP_INCS = $CPP_INCS\n";
print "DM_CLIENT_LIBS = $DM_CLIENT_LIBS\n";
print "CPP_LIBS = $CPP_LIBS\n";
print "LD_LIBS = $LD_LIBS\n";
print "DM_RPC_LIBS = $DM_RPC_LIBS\n";
print "OS_LIBS = $OS_LIBS\n";
print "CCFLAGS = $CCFLAGS\n\n";

if ($OS =~ /Win/i) {
    warn "\n*** WARNING *** The Microsoft C++ compiler does not properly interpret quoted\n" .
         " paths, paths with spaces, or directory names longer than 8 characters.  Please\n" .
         " double-check your environment variables to ensure all paths comply.\n\n";
}

print "Press ENTER to continue.";
chomp($ans = <STDIN>);

# write makefile

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'	=> 'Db::Documentum',
	'VERSION_FROM' => 'Documentum.pm',
	'LIBS'	=> ["$LD_LIBS $DM_CLIENT_LIBS $DM_RPC_LIBS $CPP_LIBS $OS_LIBS"],

# UNIX:
# You can also link against the shared client library if you want.  You'll need
# to have libC.so, libDMCL.so, and libc.so in your LD_LIBRARY_PATH.  This
# slows things down a little bit, but drastically decreases the size of the
# Documentum.so library.  Uncomment the LIBS expression below and comment out
# the one above if you want to use the shared libraries.
#    'LIBS'	=> ["-L$DM_LIB -lC -ldmcl40 -lc"],

	'DEFINE'  => '-DSQLNETV2 -DSYSV -D$OS -DOS_UNIX',
	'INC'	  => "$DM_INCLUDE $CPP_INCS",
	'CCFLAGS' => $CCFLAGS,

	# This makes 'make ppd' happy
	($] ge '5.005')
	? (
	    'AUTHOR'   => 'M. Scott Roth (scott@dm-book.com)',
	    'ABSTRACT_FROM' => 'Documentum.pm',
	  )
	: (),

	# This is just here to make 'make dist' easier to run.
	'dist' => { COMPRESS=>"gzip -9f", SUFFIX=>"gz" }
);

# __EOF__