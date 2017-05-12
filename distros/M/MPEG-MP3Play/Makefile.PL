use strict;
use ExtUtils::MakeMaker;
use Config;
use File::Copy;

# $Id: Makefile.PL,v 1.12 2008/03/30 10:30:30 joern Exp $

my $SDK_DIR = '/usr/local/xaudiosdk';

$| = 1;

main: {
	# determine X-Audio SDK directory

	my $sdk_dir = get_sdk_directory(@ARGV);
	my @sdk_version = get_sdk_version($sdk_dir);

	my $xaudio_version;
	if ( $sdk_version[0] == 2 ) {
		$xaudio_version = "mp3play_xaudio_version_2_2";
	} else {
		$xaudio_version = "mp3play_xaudio_version_0_0";
	}	

	configure_xaudio_version (@sdk_version);	
	write_runsample();

	# determine additional libs for this platform
	my $add_libs = get_add_libs();

	# See lib/ExtUtils/MakeMaker.pm for details of how to influence
	# the contents of the Makefile that is written.

	WriteMakefile(
	    'NAME'	=> 'MPEG::MP3Play',
	    'ABSTRACT'  => 'Module for playing MPEG audio files, needs Xaudio',
	    'VERSION_FROM' => 'MP3Play.pm',
	    'LIBS'	=> ["-L$sdk_dir/lib -lxaudio $add_libs"],
	    'DEFINE'	=> "-D$xaudio_version",
	    'INC'	=> "-I$sdk_dir/include",
	    'MYEXTLIB'	=> 'conv_msg.o',
	    'depend'	=> { 'src/MP3Play.xs' => 'src/constants.h' },
	    'dist'	=> {
	    	'PREOP' => 'perl tools/genreadme > README'
	    }
	);
}

sub write_runsample {
	my $perlpath = $Config{perlpath};
	open (OUT, "> runsample");
	print OUT <<__EOF;
#!/bin/sh
$perlpath -w -Iblib/arch -Iblib/lib samples/\$1
__EOF
	close OUT;
	chmod 0755, "runsample";
}

sub configure_xaudio_version {
	my ($major, $minor, $revision) = @_;
	
	my $version_dir = "./version/$major.$minor";
	
	print "Copying $version_dir/constants.h to ./constants.h ...\n";
	copy ("$version_dir/constants.h", ".")
		or die "can't copy $version_dir/constants.h: $!";

	print "Copying $version_dir/conv_msg.c to ./conv_msg.c ...\n";
	copy ("$version_dir/conv_msg.c", ".")
		or die "can't copy $version_dir/conv_msg.c: $!";
	
	open (FH, "> lib/MPEG/MP3Play/XA_Version.pm")
		or die "can't write lib/MPEG/MP3Play/XA_Version.pm";
	print FH <<__EOF;
package MPEG::MP3Play::XA_Version;
\$VERSION = "$major.$minor.$revision";
\@VERSION = ($major,$minor,$revision);
1;
__EOF
	close FH;

	1;
}

sub get_sdk_directory {
	my @ARGV = @_;
	
	my $sdk_dir = shift @ARGV;
	$sdk_dir =~ s!/$!!;
	return $sdk_dir if $sdk_dir;

	my $ok;
	$sdk_dir = $SDK_DIR;

	my $input = prompt("Xaudio SDK directory [$sdk_dir] :");
	$sdk_dir = $input if $input;
	$ok = -d "$sdk_dir/include" and -d "$sdk_dir/lib";
	exit 0 if !$input && !$ok;
        if ( not $ok ) {
          print "\nThe directory must contain include and lib subdirectories.\n";
          print "Restart Makefile.PL and correct this.\n\n";
          exit 0;
        }

	return $sdk_dir;
}

sub get_sdk_version {
	my ($sdk_dir) = @_;
	
	my ($major, $minor, $revision);
	open (FH, "$sdk_dir/include/xaudio.h")
		or die "can't read $sdk_dir/include/xaudio.h";
	while (<FH>) {
		next if not /#define XA_IMPLEMENTATION_([^\s]+)/;
		my $what = $1;
		/(\d+)/;
		$major    = $1 if $what eq 'MAJOR';
		$minor    = $1 if $what eq 'MINOR';
		$revision = $1 if $what eq 'REVISION';
	}
	
	close (FH);
	
	$major    ||= '0';
	$minor    ||= '0';
	$revision ||= '0';

	print "Detected Xaudio SDK Implementation [$sdk_dir/include/xaudio.h]: $major.$minor.$revision\n";

	return ($major, $minor, $revision);
}

sub get_add_libs {
	# on Irix -laudio is needed due to a bug in the Xaudio SDK
	if ( $Config{osname} =~ /irix/i ) {
		print "Irix detected! Adding '-laudio'.\n";
		return '-laudio';
	}
}
