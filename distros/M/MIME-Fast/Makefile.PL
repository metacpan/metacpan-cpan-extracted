use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

require 5.8.0; # require perl v5.8.0 or higher

# my $libs = `pkg-config --libs gmime-2.0`;
my $libs = `gmime-config --libs`;
my $vers = `gmime-config --version`;

if ($libs eq '') {
	die<<'END';
ERROR: I could not find gmime-config file (and gmime libraries) on your system.
You should have gmime (and glib) library installed.
The homepage of gmime C library is at http://spruce.sourceforge.net/gmime/
The homepage of glib C library is at http://www.gtk.org/
END
}

chomp ($vers);
print "Version of gmime: $vers\n";
if ($vers eq "2.0.8") {
	open(VERSIONFILE,"> gmime-version.h") || die "Can not open gmime-version.h to write";
	print VERSIONFILE "#define GMIME_CHECK_VERSION_UNSUPPORTED 0\n";
	# print VERSIONFILE "#define GMIME_CHECK_VERSION_2_0_8 1\n";
	# print VERSIONFILE "#define GMIME_CHECK_VERSION_2_0_9 0\n";
	close(VERSIONFILE);
} elsif ($vers =~ /^2\.[1-9]/ or $vers =~ /^[3-9]/) {
	open(VERSIONFILE,"> gmime-version.h") || die "Can not open gmime-version.h to write";
	print VERSIONFILE "#define GMIME_CHECK_VERSION_UNSUPPORTED 0\n";
	print VERSIONFILE "#define GMIME_CHECK_VERSION_2_1_0 1\n";
	close(VERSIONFILE);
} else {
	# die "This version of MIME::Fast module can only run with gmime v2.0.8 (not $vers)\n";
	open(VERSIONFILE,"> gmime-version.h") || die "Can not open gmime-version.h to write";
	print VERSIONFILE "#define GMIME_CHECK_VERSION_UNSUPPORTED 0\n";
	# print VERSIONFILE "#define GMIME_CHECK_VERSION_2_0_8 0\n";
	# print VERSIONFILE "#define GMIME_CHECK_VERSION_2_0_9 1\n";
	close(VERSIONFILE);
}

WriteMakefile(
    'NAME'		=> 'MIME::Fast',
    'AUTHOR'		=> 'Piotr Klaban <post@klaban.torun.pl>',
    'VERSION_FROM'	=> 'Fast.pm', # finds $VERSION
    'PREREQ_PM'		=> {},
    'LIBS'		=> [$libs], # e.g., '-lm'
    'OPTIMIZE'          => '-O2',
    'CCFLAGS'           => '-g',
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'XS'		=> { 'Fast.xs'  => 'Fast.c' },
    'OBJECT'		=> 'Fast.o gmime-stream-perlio.o',
    'PM'		=> { 'Fast.pod' => '$(INST_LIBDIR)/Fast.pod',
     	                     'Fast.pm' => '$(INST_LIBDIR)/Fast.pm'},
    'depend'		=> {
	    'Fast.so'  => 'Fast.o gmime-stream-perlio.o',
	    'Fast.o'   => 'Fast.c',
	    'Fast.c'   => qw{
cinclude/gmime-newfunc.c cinclude/gmime-newfuncheader.c
cinclude/perl-constants.c
gmime-stream-perlio.c gmime-stream-perlio.h
Fast/Charset.xs                Fast/Filter/Best.xs
Fast/Filter/Md5.xs             Fast/MessageMDN.xs             Fast/Parser.xs
Fast/ContentType.xs            Fast/Filter/CRLF.xs
Fast/Filter/Strip.xs           Fast/MessageMDNDisposition.xs  Fast/Part.xs
Fast/DataWrapper.xs            Fast/Filter/Charset.xs
Fast/Filter/Yenc.xs            Fast/MessagePart.xs            Fast/Stream.xs
Fast/Disposition.xs            Fast/Filter/Enriched.xs        Fast/Hash.xs
Fast/MessagePartial.xs         Fast/StreamFilter.xs
Fast/Filter                    Fast/Filter/From.xs
Fast/InternetAddress.xs        Fast/MultiPart.xs              Fast/Utils.xs
Fast/Filter.xs                 Fast/Filter/Func.xs            Fast/Message.xs
Fast/Object.xs
Fast/Filter/Basic.xs           Fast/Filter/HTML.xs
Fast/MessageDelivery.xs        Fast/Param.xs
},
# 'Fast.so' => qw{cinclude/gmime-stream-perlio.o}
	},
    'clean'             => { FILES => "gmime-version.h" },
    #    'INC'		=> `pkg-config --cflags gmime-2.0` # e.g., '-I/usr/include/other'
    'INC'		=> "-I. -Icinclude " . `gmime-config --cflags`,
);
