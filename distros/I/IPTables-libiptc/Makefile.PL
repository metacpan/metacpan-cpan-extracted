use 5.008004;
use ExtUtils::MakeMaker;

# TODO: Create some test which detect if xtables.h is installed on the
# target system.  Under Debian this file is located in software
# package: "iptables-dev".

{
        package MY;
        use File::Basename; #for dirname

	sub exec_iptables($) {
	    my $cmd = shift;
	    my $exitcode;
	    print "Detect iptables version via command: \"$cmd\"\n";

	    my $output = `$cmd 2>&1`;
	    if ($? == -1) {
		# Cannot execute the command
		print(" WARN: Cannot execute the command:$cmd (err:$!)\n");
		$exitcode=-1;
	    } else {
		# The exit code is in the high byte of the 16-bit status word
		$exitcode = $? >> 8;
	    }
	    return ($exitcode, $output);
	}

	sub which_xtables_libdir($) {
	    # Find the xtables libdir based upon path of iptables binary
	    my $cmd = shift;
	    my $exitcode;
	    print "Detect the xtables libdir path of: \"$cmd\"\n";

	    my $output = `which $cmd 2>&1`;
	    my $xtables_libdir = "/lib/xtables";

	    if ($? == -1) {
		# Cannot execute the command
		print(" WARN: Cannot execute the command:$cmd (err:$!)\n");
		$exitcode=-1;
	    } else {
		# The exit code is in the high byte of the 16-bit status word
		$exitcode = $? >> 8;
		print(" WARN: error occured to run: which $cmd (err:$!)\n")
		    if ($exitcode > 0);
	    }
	    $output = dirname($output); # remove "iptables"
	    $output = dirname($output); # remove "sbin/"
	    if ($output =~ m/^\/$/ ) {
		# Only contains "/" means this was /sbin/iptables
		# and it has a special load path
		$xtables_libdir = "/lib/xtables";
	    } else {
		$xtables_libdir = "${output}/libexec/xtables"
	    }
	    print " - detected xtables libdir: \"$xtables_libdir\"\n";
	    return $xtables_libdir;
	}

	sub xtables_api_version($$$) {
	    #define XTABLES_API_VERSION(x,y,z)    (0x10000*(x) + 0x100*(y) + z)
	    my $major    = shift;
	    my $minor    = shift;
	    my $revision = shift;
	    my $version_code = 0x10000*($major) + 0x100*($minor) + $revision;
	    return $version_code;
	}

	sub detect_iptables_version($) {
	    my $default_version = shift;
	    my $ver = $default_version;
	    my $vercode;
	    my $cmd = "iptables -V";
	    my $xtables_libdir = "/lib/xtables";
	    my $exitcode;

	    ($exitcode, $output) = exec_iptables("iptables -V");
	    if ($exitcode == -1) {
		($exitcode, $output) = exec_iptables("/usr/local/sbin/iptables -V");
		if ($exitcode != -1) {
		    $xtables_libdir = "/usr/local/libexec/xtables";
		}
	    } else {
		# iptables found in the path, but where?  We need to
		# know which is the correct $xtables_libdir to use.
		$xtables_libdir = which_xtables_libdir("iptables");
	    }
	    ($exitcode, $output) = exec_iptables("/sbin/iptables -V")
		if ($exitcode == -1);

	    if ($exitcode>0) {
		print STDERR ("WARN: Err running command:\"$cmd\" (err:$!)\n");
		print STDERR ("WARN: Cannot auto-detect iptables version\n");
	    } else {
		chomp $output;
		#print "Matching on output:[$output]\n";
		if ($output =~ /iptables v(\d+)\.(\d+)\.(\d+)\.?(\d?)/) {
		    my $major    = $1;
		    my $minor    = $2;
		    my $revision = $3;
		    my $extra    = $4;
		    $ver="$major.$minor.$revision";
		    if ( $extra =~ m/\d+/ ) {
			$ver = $ver . "." . ${extra};
		    }
		    $vercode=xtables_api_version($major,$minor,$revision);
		    print "Detected iptables version: $ver (vercode:$vercode)\n";
		    if ($major > 1) {
			print "Too high major version, fallback\n";
			$ver = $default_version;
		    }

		    if ($minor > 4) {
			print "Module only supports version 1.4.x, fallback\n";
			$ver = $default_version
		    }

		    if ($minor < 4) {
			print "Version below 1.4.x, good luck\n";
			print "We recommend that you instead use version 0.15 of IPTables::libiptc\n";
			print "\n";
		    }

		    if ($minor == 4 && $revision < 3) {
			print "\n";
			print "-=-=-=- WARNING: Incompatible iptables version -=-=-=-";
			print "\n";
			print " This perl module release only supports iptables versions:\n";
			print "   v1.4.3.2 and above \n";
			print "\n";
			print "We recommend that you instead use version 0.18 of IPTables::libiptc\n";
			print "on your system, for supporting v1.4.1 and v1.4.2 \n";
			print "\n";
			print " Significant API changes when into 1.4.3, and thus older versions cannot\n";
			print " be kept backward binary compatible with this release.\n";
			print "\n";
			print " YOU HAVE BEEN WARNED!!!\n";
			print "\n";
		    }

		}
	    }
	    print("Using iptables version: $ver\n");
	    return ($ver, $vercode, $xtables_libdir);
	}

	sub check_header($$) {
	    # Check that a C header file can be included, e.g. xtables.h
	    my $header_file    = shift;
	    my $xtables_libdir = shift;

	    print "Checking for header files\n";

	    # Find the include path, based on the detected $xtables_libdir
	    my $inc_path = dirname($xtables_libdir); # remove "xtables"
	    $inc_path    = dirname($inc_path);       # remove "libexec" or "lib"

	    if ($inc_path =~ m/^\/$/ ) {
		# Only contains "/" means this was /lib/xtables
		# and it has a special load path
		$inc_path = "/usr/include";
	    } else {
		$inc_path .= "/include";
	    }
	    print " - detected include path: \"$inc_path\"\n";

	    my $cmd = "./check-header";
	    my $exitcode;

	    # Call shell-script which calls GCC to perform a compile test
	    print " - check-header: $header_file\n";
	    my $output = `$cmd $header_file "-I${inc_path}" 2>&1`;
	    #print "OUTPUT: $output\n";
	    if ($? == -1) {
		# Cannot execute the command
		print(" WARN: Cannot execute the command:$cmd (err:$!)\n");
		$exitcode=-1;
	    } else {
		# The exit code is in the high byte of the 16-bit status word
		$exitcode = $? >> 8;
	    }

	    if ($exitcode > 0) {
		print "\n";
		print "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n";
		print "-=-=-=-        *** ERROR: Missing header file ***       -=-=-=-\n";
		print "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n";
		print "\n";
		print "   Cannot find required header file: \"$header_file\"\n";
		print "\n";
		print "   You must install the systems software package \n";
		print "   containing the header file, usually a \"dev\" package.\n";
		print "\n";
		print "   Hint, under Debian/Ubuntu install \"iptables-dev\" package\n";
		print "     apt-get install iptables-dev\n";
		print "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\n";
	    }

	    return $exitcode;
	}


	sub post_initialize {
	    my $default_version = "1.4.4";
	    my ($ver, $vercode, $xtables_libdir) = detect_iptables_version($default_version);
	    #print "vercode: $vercode\n";
	    # Check that the xtables.h header is available on the system
	    check_header("xtables.h", $xtables_libdir);
"
IPTABLES_VERSION:=$ver
IPTABLES_VERSION_CODE:=$vercode
XTABLES_LIBDIR:=$xtables_libdir
LOCAL_LIB_IPTC:=-Llibrary_iptc/
"
        }

        sub postamble {
"

# Not needed anymore
#library_iptc/libiptc.a: library_iptc/*.c
#	make -C library_iptc/ all IPTABLES_VERSION=\"\$(IPTABLES_VERSION)\" IPTABLES_VERSION_CODE=\"\$(IPTABLES_VERSION_CODE)\"

#iptables/iptables.o iptables/xtables.o: iptables/*.c library_iptc/libiptc.a
iptables/iptables.o iptables/xshared.o: iptables/*.c
	make -C iptables/ all PREFIX=\"\$(PREFIX)\" IPTABLES_VERSION=\"\$(IPTABLES_VERSION)\" XTABLES_LIBDIR=\"\$(XTABLES_LIBDIR)\" IPTABLES_VERSION_CODE=\"\$(IPTABLES_VERSION_CODE)\" EXTRALIBS=\"\$(EXTRALIBS)\"


install::
	make -C iptables/ install

clean::
	make -C iptables/ clean
#	make -C library_iptc/ clean
";
        }
}


# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'IPTables::libiptc',
    VERSION_FROM      => 'lib/IPTables/libiptc.pm', # finds $VERSION
    PREREQ_PM         => {
	'File::Basename'   => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/IPTables/libiptc.pm', # retrieve abstract from module
       AUTHOR         => 'Jesper Dangaard Brouer <hawk@comx.dk>') : ()),
##  LIBS              => ['-ldl -lnsl -liptc'], # e.g., '-lm'
    # Notice, perl Makefile.PL will detect if ip4tc is available
    LIBS              => ['-ldl -lnsl -liptc -lip4tc -lxtables'], # e.g., '-lm'
##  LIBS              => ['-ldl -lnsl'], # e.g., '-lm'
    LDDLFLAGS         => '-shared -L$(PREFIX)/lib',
##  LDDLFLAGS         => '-shared $(LOCAL_LIB_IPTC) -L$(PREFIX)/lib',
    LDFLAGS           => '-L$(PREFIX)/lib',
    DEFINE            => '-g -DIPTABLES_VERSION=\"$(IPTABLES_VERSION)\" -DXTABLES_LIBDIR=\"\$(XTABLES_LIBDIR)\" -DIPTABLES_VERSION_CODE=\$(IPTABLES_VERSION_CODE)',
                         # e.g., '-DHAVE_SOMETHING'
    INC               => '-I/usr/local/include -I./include -I.',
                         # e.g., '-I. -I/usr/include/other'
    # Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
    OBJECT            => '$(O_FILES) iptables/iptables.o iptables/xshared.o',
##  OBJECT            => '$(O_FILES) iptables/iptables.o iptables/xtables.o library_iptc/libiptc.a',
                      # link all the C files too
    PREFIX            => '/usr/local',
    TYPEMAPS          => ['libiptc.typemap'],
#   depend             => { 'iptables/iptables.o' => 'library_iptc/libiptc.a'}
#   depend             => { 'iptables/iptables.o' => 'library_iptc/libiptc.a'}
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(IPT_MIN_ALIGN));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'IPTables::libiptc',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
