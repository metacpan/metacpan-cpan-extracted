use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

use File::ShareDir::Install;
use File::Spec;
use File::Copy;
use FindBin;
use File::Temp qw/tempdir/;
use Cwd qw/abs_path/;
use Data::Roundtrip qw/perl2dump/;
use IPC::Run;
# FFI::CheckLib can check_lib with specified symbol which is handy, so use that
# it does not depend on FFI!
use FFI::CheckLib;
# but we also need this to compile a piece of C code (not really)
use Devel::CheckLib;

my $VERBOSE = exists($ENV{VERBOSE}) && defined($ENV{VERBOSE}) ? $ENV{VERBOSE} : 1;

# returns an arrayref of [$cflags, $ldflags]
# NOTE: 'cflags' contains the includes (as -I... -I...)
#       'ldflags' contains the libs (as -L.. -L.. -l.. -l..)
# returns undef on failure
# when it fails, your only chance to have this run is to specify
# ENV vars: OPENCV_CFLAGS and OPENCV_LDFLAGS
# to contain -I and -L -l 
# Unix/Linux usually contains pkg-config which outputs this params
# given that OpenCV was properly installed.
# On M$ all goes, it's just a mess and should not be even supported.
sub find_opencv_settings {
	my ($out, $err, $ret);
	# 1. check if env vars OPENCV_CFLAGS and OPENCV_LDFLAGS were specified
	if( $VERBOSE > 0 ){ print STDOUT "find_opencv_settings() : checking ENV for 'OPENCV_LDFLAGS' and 'OPENCV_CFLAGS' ...\n" }
	my $ldflags = exists($ENV{OPENCV_LDFLAGS}) && defined($ENV{OPENCV_LDFLAGS}) ? $ENV{OPENCV_LDFLAGS} : undef;
	my $cflags = exists($ENV{OPENCV_CFLAGS}) && defined($ENV{OPENCV_CFLAGS}) ? $ENV{OPENCV_CFLAGS} : undef;
	if( $ldflags and $cflags ){
		if( $VERBOSE > 0 ){ print STDOUT "find_opencv_settings() : found ldflags='$ldflags', cflags='$cflags' (using supplied ENV vars).\n" }
		return [$cflags, $ldflags]
	}

	# 2. check if there's a pkg-config
	if( $VERBOSE > 0 ){ print STDOUT "find_opencv_settings() : checking with pkg-config ...\n" }
	for my $opv (qw/opencv4 opencv/){
		my @cmd = ('pkg-config', $opv, '--libs');
		eval {
			IPC::Run::run \@cmd, \undef, \$out, \$err, IPC::Run::timeout(30)
		};
		if( $@ ){
			if( $VERBOSE > 0 ){ print STDERR "find_opencv_settings() : failed to run command '@cmd': $@\n"; }
			next
		}
		chomp($out);
		$ldflags = $out;
		   @cmd = ('pkg-config', $opv, '--cflags');
		IPC::Run::run \@cmd, \undef, \$out, \$err, IPC::Run::timeout(30) or next;
		chomp($out);
		$cflags = $out;
		last;
	}
	if( $ldflags and $cflags ){
		if( $VERBOSE > 0 ){ print STDOUT "find_opencv_settings() : found ldflags='$ldflags', cflags='$cflags' (using pkg-config).\n" }
		return [$cflags, $ldflags]
	}

	# 3. check with cmake script, provided cmake is installed
	if( $VERBOSE > 0 ){ print STDOUT "find_opencv_settings() : checking with cmake ...\n" }
	my $tmpdir = tempdir(CLEANUP => 1);
	my $curdir = Cwd::abs_path(Cwd::cwd);
	die "find_opencv_settings() : failed to chdir to tempdir '$tmpdir'."
		unless chdir $tmpdir;
	if( $VERBOSE > 0 ){ print STDOUT "find_opencv_settings() : writing CMakeLists.txt and test.cpp into tempdir '$tmpdir' ...\n"; }
	# write the CMakeLists.txt for cmake
	open my $fh, '>', 'CMakeLists.txt' or die "find_opencv_settings() : failed to open file 'CMakeLists.txt' for writing: $!";
	print $fh <<'EOCM';
cmake_minimum_required(VERSION 2.9)
project(RUBBISH_CMAKE_PROJECT)
find_package( OpenCV REQUIRED )
include_directories( ${OpenCV_INCLUDE_DIRS} )
add_executable( _cmake_opencv_testme test.cpp )
target_link_libraries( _cmake_opencv_testme ${OpenCV_LIBS} )
message(STATUS "RUBBISH_CMAKE_PROJECT::INCLUDE_DIRS: ${OpenCV_INCLUDE_DIRS}")
message(STATUS "RUBBISH_CMAKE_PROJECT::LIB_PATH: ${OpenCV_LIB_PATH}")
message(STATUS "RUBBISH_CMAKE_PROJECT::INSTALL_PREFIX: ${OpenCV_INSTALL_PREFIX}")
message(STATUS "RUBBISH_CMAKE_PROJECT::LIBS: ${OpenCV_LIBS}")
EOCM
	close $fh;
	# now write a basic test C++ program
	open $fh, '>', 'test.cpp' or die "find_opencv_settings() : failed to open file 'test.cpp' for writing: $!";
	print $fh <<'EOCM';
#include <opencv2/opencv.hpp>
int main(void){ return(0); }
EOCM
	close $fh;
	my @cmd = ('cmake', '.'); # does cmake even exist?
	if( $VERBOSE > 0 ){ print STDOUT "find_opencv_settings() : attempting to run '@cmd' into tempdir '$tmpdir' ...\n"; }
	eval { IPC::Run::run \@cmd, \undef, \$out, \$err };
	if( $@ ){
		if( $VERBOSE > 0 ){ print STDERR "find_opencv_settings() : running command has failed: '@cmd': $@\n"; }
	} else {
		my %buildparams;
		for my $l (split /\R/, $out){
			if( $l =~ /^\-\- RUBBISH_CMAKE_PROJECT::([A-Z_]+): (.+?)$/ ){ $buildparams{$1} = $2 }
		}
		print "Build Params: \n".perl2dump(\%buildparams);
		if( exists($buildparams{INCLUDE_DIRS}) ){ $cflags .= ' -I'.$_ for split /\s*;\s*/, $buildparams{INCLUDE_DIRS} }
		if( exists($buildparams{LIB_PATH}) ){ $ldflags .= ' -L'.$_ for split /\s*;\s*/, $buildparams{LIB_PATH} }
		if( exists($buildparams{LIBS}) ){ $ldflags .= ' -l'.$_ for split /\s*;\s*/, $buildparams{LIBS} }
	}
	die "find_opencv_settings() : failed to chdir to previous current dir '$curdir'."
		unless chdir $curdir;
	if( $ldflags and $cflags ){
		if( $VERBOSE > 0 ){ print STDOUT "find_opencv_settings() : found ldflags='$ldflags', cflags='$cflags' (using cmake).\n" }
		return [$cflags, $ldflags]
	}

	# 4. check with FFI::CheckLib, but this only gives us libraries!
	if( $VERBOSE > 0 ){ print STDOUT "find_opencv_settings() : finding ldflags (only!) with FFI::CheckLib, this is just for extra info but it is useless because it does not find the INCLUDE dir ...\n" }
	$cflags = ' '; # still make cflags empty and hope for the best (it must have 1 space there)
	$ldflags = undef;
	for my $wanted ('opencv_wechat_qrcode', 'opencv_world'){
		# this will fail because symbol names are mangled, e.g. _ZN2cv13wechat_qrcode12WeChatQRCode15detectAndDecodeB5cxx11ERKNS_11_InputArrayERKNS_12_OutputArrayE
		my ($lib) = FFI::CheckLib::find_lib(
			lib => $wanted,
			symbol => 'wechat_qrcode::WeChatQRCode'
		);
		# example output: /usr/local/lib64/libopencv_world.so.4.5.5
		# this needs fine-tuning perhaps. easily done for linux but windows? ouch can't be bothered
		if( $lib ){ $ldflags .= ' -l'.$lib; last }
	}
	if( $ldflags and $cflags ){
		if( $VERBOSE > 0 ){ print STDOUT "find_opencv_settings() : found ldflags='$ldflags', cflags='$cflags' (using ".'FFI::CheckLib::find_lib()'.").\n" }
		return [$cflags, $ldflags]
	}

	print STDERR
 "find_opencv_settings() : error, failed to find OpenCV compilation flags (library location and include-dir) using several methods."
."\nThe best way to proceed from here is to find where OpenCV library and include dir are located "
."and set ENVironment variables before re-running this script. "
."FOR EXAMPLE if library is located at '/usr/lib64/libopencv_world.so' "
."and include dir at '/usr/local/include/opencv4/include/', "
."then set these ENV vars (FOR EXAMPLE):"
."\n  OPENCV_LDFLAGS='-L/usr/lib64/ -lopencv_world'"
."\n   OPENCV_CFLAGS='-I/usr/local/include/opencv4/include/'"
."and re-run this script."
."The only complication then is if you don't thave the libopencv_world.so which includes all OpenCV symbols "
."but instead you have hundreds of smaller OpenCV component libraries. In which case set this:"
."\n  OPENCV_LDFLAGS='-L/usr/lib64/ "
# add here all libs:
."-lopencv_core "
."-lopencv_dnn "
."-lopencv_imgproc "
."-lopencv_features2d "
."-lopencv_flann "
."-lopencv_imgcodecs "
."-lopencv_wechat_qrcode "
."-lopencv_highgui "
."'" # ending the libs here
."\n\nIf running this script was successful but 'make' fails, then Perhaps you may also "
."need to add '-lpng -ltiff -ljpeg' in the same way as described above. Also -ltbb etc. In general add all libraries via ENV vars when all else fails."
."\nGood luck unless you have Unix/Linux which is a solid dev env.\n"
."\n"
	;
	return  undef # failed
}

# find whether opencv highgui library exists
# this is an optional OpenCV component and may or may not be installed.
# we can't use FFI::CheckLib which uses DynaLoader to interrogate libs for symbols
# because these are likely symbols whose names are C++-mangled
# e.g. we have _ZN2cv3viz6imshowERKNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEERKNS_11_InputArrayERKNS_5Size_IiEE
# instead of imshow.
# so, what we need to do is use Devel::CheckLib this time to compile some code
# Alas, this also does not work because it does not allow for a C++ compiler
sub find_if_opencv_highgui_is_supported {
	my ($cflags, $ldflags) = @_;

	my $num_votes = 0;

	my $method1 = 0;
	for my $wanted ('opencv_highgui'){
		my ($lib) = FFI::CheckLib::find_lib(
			lib => $wanted,
		);
		# example output: /usr/local/lib64/libopencv_world.so.4.5.5
		$method1 = defined($lib);
	}
	$num_votes += $method1;

	my $method2 = 0;
	my @incs;
	push @incs, $1 while $cflags =~ /\-I\s*['](.+?)[']/g;
	push @incs, $1 while $cflags =~ /\-I\s*["](.+?)["]/g;
	push @incs, $1 while $cflags =~ /\-I\s*(.+?)($|\s)/g;
	for my $aninc (@incs){
		my $f = File::Spec->catdir($aninc, 'opencv2', 'highgui.hpp');
		if( $VERBOSE > 0 ){ print STDOUT "find_if_opencv_highgui_is_supported() : checking if file '$f' exists in '$aninc' ...\n" }
		if( -f $f ){ $method2 = 1 ; last }
	}
	$num_votes += $method2;

	my $method3 = 0;
	for my $wanted ('opencv_highgui'){
		$method3 = Devel::CheckLib::check_lib(
			lib => $wanted,
		);
	}
	$num_votes += $method3;


	if( $num_votes == 3 ){ return 1 }
	elsif( $num_votes == 2 ){
		print STDERR "WARNING: finding OpenCV's highgui library has yielded contradictory results:\nMethod 1 : does library exist? ".($method1==1?"YES":"NO")."\nMethod 2 : does OpenCV's highgui include file exist? ".($method2==1?"YES":"NO")."\nMethod 3 : is linking to this library successful? ".($method3==1?"YES":"NO")."\nI assume the answer is YES but we need a more robust method to detect this. You may want to raise this as an issue detailing your current OS and OpenCV installation.\n";
		return 1
	}
	return 0 # not found (or just 1 method was successful)
}

my $ret = find_opencv_settings();
die "Error, failed to find OpenCV compilation flags (libs+includes), call to find_opencv_settings() has failed. Is OpenCV installed (version 4+)? If yes, then your best option is to manually find the INCLUDE dir and LIB dir for OpenCV in your system and set OPENCV_LDFLAGS and OPENCV_CFLAGS ENVironment variables and re-run this Makefile.PL again."
	unless $ret;
my ($cflags, $ldflags) = @$ret;
if( $VERBOSE > 0 ){ print "Found compilation flags:\n   CFLAGS: ${cflags}\n  LDFLAGS: ${ldflags}\n" }

my $has_highgui = find_if_opencv_highgui_is_supported($cflags, $ldflags);
$cflags .= ' -DHAS_HIGHGUI='.$has_highgui;
if( $VERBOSE > 0 ){ print "Found support for OpenCV's highgui: ".($has_highgui==0?"no":"yes").".\n" }

link("lib/Image/DecodeQR/WeChat.xs", "WeChat.xs");
mkdir("t/tmp");
mkdir("xt/tmp");

my %WriteMakefileArgs = (
    NAME             => 'Image::DecodeQR::WeChat',
    AUTHOR           => q{Andreas Hadjiprocopis <bliako@cpan.org>},
    VERSION_FROM     => 'lib/Image/DecodeQR/WeChat.pm',
    ABSTRACT_FROM    => 'lib/Image/DecodeQR/WeChat.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.016',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
	'File::ShareDir::Install' => '0',
	'File::Spec' => '0',
	'File::Copy' => '0',
	'FindBin' => '0',
	'File::Temp' => '0',
	'Cwd' => '0',
	'Data::Roundtrip' => '0',
	'IPC::Run' => '0',
	'FFI::CheckLib' => '0',
	'Devel::CheckLib' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
	'Test2::Plugin::UTF8' => '0',
	'Encode' => '0',
	'FindBin' => '0',
	'File::Spec' => '0',
	'File::Temp' => '0',
	'File::Copy' => '0',
	'Time::HiRes' => '0',
	'File::ShareDir' => '0',
	'Data::Roundtrip' => '0',
    },
    PREREQ_PM => {
	'File::ShareDir' => '0',
	'Time::HiRes' => '0',
	'Data::Roundtrip' => '0',
	'Getopt::Long' => '0',
    },
    EXE_FILES	=> [glob('script/*.pl')],

    META_MERGE => {
		'meta-spec' => { version => 2 },
		requires	=> { perl => '5.6.0' },
		resources   => {
			license	=> 'artistic_2',
			homepage   => 'https://metacpan.org/module/Image::DecodeQR::WeChat',
			repository => {
				url  => 'https://github.com/hadjiprocopis/perl-image-decodeqr-wechat',
				web  => 'https://github.com/hadjiprocopis/perl-image-decodeqr-wechat',
				type => 'git',
			},
			# no i prefer cpan's
			#bugtracker => {
			#	web => 'https://github.com/hadjiprocopis/perl-image-decodeqr-wechat/issues',
			#}
		},
    },

    OBJECT => '$(O_FILES)',
    LIBS    => $ldflags,
    CCFLAGS => $cflags,
#    LDFLAGS => '/usr/local/lib64/libopencv_world.a',
    CC      => 'g++',
    LD      => 'g++',
    XSOPT   => '-C++',

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Image-DecodeQR-WeChat-* WeChat.bs WeChat.c WeChat.xs *.o' },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

##### AHP additions
my $models_dir = File::Spec->catdir($FindBin::Bin, 'models');
if( ! -d $models_dir ){ die "Makefile.PL : error, models dir '$models_dir' is missing, this is not right, re-download the package." }

# this also needs a postable, see below
# additionally we need to substitute some variables in .pm and .xs files
# all done in the Makefile
File::ShareDir::Install::install_share dist => $models_dir;
# all you get here is Makefile vars
my $installed_models_dir = File::ShareDir::Install::_dist_dir();

WriteMakefile(%WriteMakefileArgs);

if(0){
my @args = ("make", "patch_files_with_models_dir");
system(@args) == 0
	or die "system @args failed: $?";
}

{
package MY;
use File::ShareDir::Install;

# this will override what dirs are search by Makefile.PL
# remove that push_to_GIT dir etc.
sub libscan {
    my( $mm, $file ) = @_;
    return if $file =~ /(push_to_GIT)|(\.lock)/;
    #warn "@_\n";
    return $file;
}

sub postamble {
	my ($self, %h) = @_;
	my @ret = File::ShareDir::Install::postamble( $self );
	# ... add more things to @ret;
	my $retstr = join "\n", @ret;
	# WARNING: USE REAL TABS in the Here-doc below, it goes into Makefile!!!
if(0){
	$retstr .= <<POSTAMBLE;

# we need to patch *.pi files 

patch_files_with_models_dir:
	\@echo "patching files with modelsdir = $installed_models_dir ..."
	\@sed 's!<: modelsdir :>!$installed_models_dir!g' lib/Image/DecodeQR/WeChat.pm.source > lib/Image/DecodeQR/WeChat.pm
	\@sed 's!<: modelsdir :>!$installed_models_dir!g' lib/Image/DecodeQR/WeChat.xs.source > lib/Image/DecodeQR/WeChat.xs
	\@sed 's!<: modelsdir :>!$installed_models_dir!g' ./WeChat.xs.source > ./WeChat.xs
	\@\$(RM) -f ./WeChat.xs.source
POSTAMBLE
}
	$retstr;
}
}
1;
