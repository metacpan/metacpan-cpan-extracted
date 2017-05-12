#
# $Id: Makefile.PL,v 38.2 2012/09/26 16:10:08 jettisu Exp $
#
# (c) 1999-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

use ExtUtils::MakeMaker;
use Config;
use English;
use Cwd;
use File::Basename;

require "../util/parse_config";
require "../util/parse_headers";
require "../util/fake_mm";

#
# Are we building the client, or server?
#
if ( cwd =~ m:/MQClient/?: ) {
    $apitype = "MQClient";
} else {
    $apitype = "MQServer";
    # Override this for the server test (use the default queuemgr)
    $myconfig{QUEUEMGR} = "" if $myconfig{USE_DEFAULT_QMGR};
}

#
# Here's the logic for determining whether or not we can support the
# server API or not.  These %myconfig entries may be overridden in the
# CONFIG file.
#
if ( $Config{osname} =~ /(irix|sunos)/ ) {
    # NOTE: On IRIX and SunOS 4.x, we can *only* build the client.
    warn("No support for MQServer compiles on platform '$Config{osname}'\n")
      if $apitype eq 'MQServer'; # Whine once...
    $myconfig{NOSERVER}++;
}

#
# Probably a reasonable default....
#
# XXX -- what other library names are valid?
# Note that on OS/390 perl's -f stat() tests do not work with PDSes.
#
unless (
        -f "$mqmtop/lib/libmqm.so" ||
        -f "$mqmtop/lib/libmqm.sl" ||
        -f "$mqmtop/lib/libmqm.a" ||
        -f "$mqmtop/lib/mqm.lib"
       ) {
    warn("No libmqm server library found, MQServer disabled\n")
      if $apitype eq 'MQServer'; # Whine once...
    $myconfig{NOSERVER}++;
}

#
# This is bad -- if you don't have either one, there's no point in
# building this code.
#
if ( $myconfig{NOCLIENT} && $myconfig{NOSERVER} ) {
    die "Both the MQClient and MQServer API's have been disabled!!\n";
}

if (
    ( $apitype eq "MQClient" && $myconfig{NOCLIENT} )
    ||
    ( $apitype eq "MQServer" && $myconfig{NOSERVER} )
   ) {
    warn("Support for $apitype is disabled on this platform.\n");
    myWriteEmptyMakefile();
    return;
}

#
# Now we have to specify the list of libraries needed on each platform
#

#
# XXX -- this hack handles the white space in pathnames prevalent on
# Win32.  At least on Solaris, quoting the -L path doesn't work.
#
if ( $mqmtop =~ /\s/ ) {
    $libdir = "-L'$mqmtop/lib'";
} elsif ( $Config{use64bitall} ) {
    $libdir = "-L$mqmtop/lib64";
} else {
    $libdir = "-L$mqmtop/lib";
}

#
# On Linux, HP-UX, and AIX, the name of the shared library is
# different for single- and multi-threaded apps.  NB: other platforms
# includes windows.
#
$libs = "$libdir " .
    [
     # MQServer / MQClient
     ["-lmqm",    "-lmqic -lmqic32"],  # non linux/hpux/aix or non-threaded
     ["-lmqm_r",  "-lmqic_r"],         # threaded perl on linux/hpux/aix
    ]
    ->[($Config{osname} =~ /linux|hpux|aix/) &&
       ($Config{usethread} || $Config{usethreads} || $Config{useithreads})]
    ->[$apitype eq "MQClient"];
if ($libs =~ /_r$/) {
    $extra_args{DEFINE} .= " -DRLIBS";
}

#
# There may very well be other platforms on which we need -lthread.
#
if ( $Config{osname} =~ /solaris/ ) {
    $libs .= " -lthread";
}

#
# On SCO (at least on OpenServer 5.0.6), we need link link libc
#
if ( $Config{osname} =~ /sco/ ) {
    $libs .= " -lc";
}

#
# Autoconstruct the test files, MQSeries.pm and MQSeries.xs
#
unless ( -d "t" ) {
    mkdir("t",0755) || die "Unable to mkdir t: $ERRNO\n";
}

%filemap = (
            "MQSeries.xs.in"            => "MQSeries.xs",
            "MQSeries.pm.in"            => "MQSeries.pm",
           );

opendir(TEST, "../t.in") || die "Unable to opendir ../t.in: $ERRNO\n";
foreach $file ( readdir(TEST) ) {
    next unless $file =~ /\.t$/;
    $filemap{"../t.in/$file"} = "t/$file";
}
closedir(TEST);

foreach $file ( sort keys %filemap ) {

    my @files = ();

    if ( -d $file ) {
        #
        # We concatenate a bunch of files based on the two-digit
        # number in front of the file.  A long, long time ago we had
        # some files in multiple versions (-v2 and -v5) and picked the
        # matching version.  The -2 files have long gone, and now we
        # have added -v7 specific files.
        #
        # We don't want to rename the existing -v5 files (rewriting
        # history), so basically we accept anything that's at our MQ
        # release or below.  If at some point we need to introduce
        # multiple versions of an API again, we'll stick the files in
        # a hash by prefix and pick the highest version matching our
        # MQ release.
        #
        opendir(INDIR, $file) || die "Unable to opendir $file: $ERRNO\n";
        foreach ( readdir(INDIR) ) {
            next if /^\.\.?$/;
            next unless /^\d{2}/;
            next if /~$/;       # skip emacs backup files

            if ( /-v(\d+)$/ ) {
                next unless $mqversion >= $1;  # Accept -v7 only on MQ v7
            }
            push(@files,"$file/$_");
        }
        closedir(INDIR);
    } else {
        @files = ($file);
    }

    open(OUT, '>', $filemap{$file}) ||
      die "Unable to write to $filemap{$file}: $ERRNO\n";

    foreach my $subfile ( sort @files ) {

        open(IN, '<', $subfile) || die "Unable to open $subfile: $ERRNO\n";

        while ( <IN> ) {

            #
            # Special case: include the header files in the right order,
            # based on what's available.
            #
            if ( /__INCLUDES__/ ) {

                foreach my $header ( grep(/cmqc\.h$/,@headers),
                                     grep(!/cmqc\.h$/,@headers) ) {
                    my $filename = basename($header);
                    print OUT "#include <$filename>\n";
                }

                next;

            }

            #
            # Another special case: include the macros found in the header
            # files dynamically.
            #
            if ( /__CONSTANTS__/ ) {

                foreach my $constant (
                                      sort (
                                            keys %constant_hex,
                                            keys %constant_numeric,
                                            keys %constant_string,
                                            keys %constant_null,
                                            keys %constant_char
                                           )
                                     ) {
                    #
                    # NOTE: 13 is the indentation of the qw() construct
                    # being assigned to @EXPORT in MQSeries.pm.in.  This
                    # is the author being incredibly anal about the
                    # style....
                    #
                    print OUT " " x 13 . "$constant\n";
                }

                next;

            }

            if ( /__CONSTANT_NULL__/ ) {

                foreach my $constant ( sort keys %constant_null ) {
                    # More anal retentive indentation (the 3 and 20, that is)
                    print OUT (" " x 3 . $constant .
                               " " x (20 - length($constant)) .
                               "=> $constant_null{$constant},\n");
                }

                next;

            }

            s/__APITYPE__/$apitype/g;
            s/__LOCALE__/$mqmlocale/g;
            s/__MQ_VERSION__/$mqversion/g;
            s/__TEST_QUEUE__/$myconfig{QUEUE}/g;
            s/__TEST_QUEUE_MANAGER__/$myconfig{QUEUEMGR}/g;
            print OUT $_;

        }

        close(IN) || die "Unable to close $subfile: $ERRNO\n";

    }

    close(OUT) || die "Unable to close $filemap{$file}: $ERRNO\n";

}

#
# Cheap hack to convince WriteMakefile that we have a local typemap,
# even though it will be generated by typemap.PL.  W/o this hack,
# xsubpp is not called with a -typemap ./typemap argument.
#
open(TYPEMAP, '>>', "typemap") || die "Unable to touch typemap: $ERRNO\n";
close(TYPEMAP);

#
# Collect optional WriteMakefile args in here...
#
my %extra_args;
if ($Config{archname} =~ /-object\b/i) {
    #
    # On Win32, we need to force the use of the CAPI with
    # ActiveState's PERL_OBJECT build
    #
    $extra_args{CAPI} => 'TRUE';
}
if ($Config{osname} =~ /win32/i) {
    #
    # On Win32, MakeMaker ain't picking up the constants.c.PL
    # file for free.  Probably a bug...
    #
    $extra_args{PL_FILES} = {
                             'constants.c.PL'   => 'constants.c',
                             'typemap.PL'       => 'typemap',
                            };
}

#
# Force RPATH to pick up mq libs
#
my $rpath = $libdir;
$rpath =~ s!-L!!;

if ( $Config{archname} =~ /linux/ ) {
    #
    # gcc and icc use same flags
    #
    # are there others in common use that don't
    # use these flags?
    #
    my $lddlflags = " -shared -Wl,-rpath -Wl,$rpath";

    if ( $Config{use64bitall} ) {
        unless ( $lddlflags =~ /64$/ ) {
            $lddlflags .= '64';
        }
        $extra_args{LDDLFLAGS} .= $lddlflags;
    } elsif( $Config{archname} =~ /^x86_64-linux/ ) {
        unless ( $lddlflags =~ /64$/ ) {
            $lddlflags .= '64';
        }
        $extra_args{LDDLFLAGS} .= $lddlflags;
    } elsif ( $Config{archname} =~ /^i[3456]86-linux/ ) {
        $extra_args{LDDLFLAGS} .= $lddlflags;
    } else {
        #
        # non-x86 Linux?
        #
        # try anyway and warn
        #
        print STDERR "Recognized linux [$Config{archname}], trying default flags and rpath";
        $lddlflags = " -shared -Wl,-rpath -Wl,$rpath";
        $extra_args{LDDLFLAGS} .= $lddlflags;
    }
} elsif ($Config{archname} =~ /-solaris-/) {
    if ($Config{cc} =~ /^gcc/) {
        #
        # See if the Sun linker is used (the default) or the GNU
        # linker.  The Sun linker uses -R for the RPATH and the NU
        # linker used -rpath.
        #
        my $lddlflags;
        if ($Config{lddlflags} =~ /-[GR]/) { # -G or -R: Definitely Sun CC
            $lddlflags = " -shared -Wl,-R -Wl,$rpath";
        } else {                # Assume GNU linker
            $lddlflags = " -shared -Wl,-rpath -Wl,$rpath";
        }
        $extra_args{LDDLFLAGS} .= $lddlflags;
    } elsif (
           $Config{cc}        =~ /^cc$/
        || $Config{cc}        =~ /^sun/
        || $Config{ccname}    =~ /sun/i
        || $Config{ccname}    =~ /workshop/i
        || $Config{ccversion} =~ /workshop/i
    ) {
        #
        # Do we have the case where you compile with GCC
        # but link using the Sun linker? Try handling with
        #   -Wl,-R,$rpath
        #
        my $lddlflags .= " -G -R$rpath";
        $extra_args{LDDLFLAGS} .= $lddlflags;
        if ( $Config{archname} =~ /^sun.*-64$/ ){
            $extra_args{LDDLFLAGS} .= " -xarch=v9 ";
        } elsif  ( $Config{archname} =~ /^i86pc.*-64$/ ){
            $extra_args{LDDLFLAGS} .= " -xarch=amd64 ";
        }
    } else {
        #
        # Some other compiler on Sun...
        #
        goto NO_RPATH;
    }
} elsif ( $Config{archname} =~ /aix/ ) {
    #
    # One or both of these might work for AIX
    #
    $ENV{LIBPATH} = join(':', $ENV{LIBPATH}, $rpath);
    my $lddflags = " -blibpath:$rpath";
    $extra_args{LDDLFLAGS} .= $lddlflags;
} else {
    #
    # FIXME
    #
    # Do nothing and hope.
    #
    # Patches for your archname/compiler/linker welcome!
    #
  NO_RPATH:
    print STDERR "Unrecognized architecture [", $Config{archname},
        "] and compiler [", $Config{cc},"]. Not setting rpath.\n";
}

eval {
    my $save;
    open($save, ">&", \*STDERR);
    my $null = $Config{osname} =~ /win32/i ? "nul" : "/dev/null";
    open(STDERR, ">>", $null);
    my $dspmqver = qx{dspmqver};
    my @v;
    if ($dspmqver =~ m{^(Version):\s+(\S+)}m) {
	push(@v, "v$2");
    }
    if ($dspmqver =~ m{^(CMVC level|Level):\s+(\S+)}m) {
	push(@v, $2);
    }
    if (@v) {
	@v = join("/", @v);
	$extra_args{DEFINE} .= " -DMQ_CMVC_LVALUE=\\\"@v\\\""; 
    }
    open(STDERR, ">&", $save);
};

WriteMakefile(
              NAME              => "${apitype}::MQSeries",
              VERSION_FROM      => "MQSeries.pm",
              LIBS              => [ $libs ],
              INC               => qq{-I"$include" -I../include},
              EXE_FILES         => [],
              OBJECT            => q[MQSeries$(OBJ_EXT) constants$(OBJ_EXT)],
              %extra_args,
             );

# now we remove it again so that it will be out-of-date
# with respect to typemap.PL.
unlink("typemap");

#
# Unlink this to be force it to be regenerated.
#
unlink("constants.c");

