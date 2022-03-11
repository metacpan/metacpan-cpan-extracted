use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

use File::ShareDir::Install;
use File::Spec;
use File::Copy;
use FindBin;

#use Devel::CheckLib;

copy("lib/Image/DecodeQR/WeChat.xs.source", "lib/Image/DecodeQR/WeChat.xs");
link("lib/Image/DecodeQR/WeChat.xs.source", "WeChat.xs.source");
link("lib/Image/DecodeQR/WeChat.xs", "WeChat.xs");
copy("lib/Image/DecodeQR/WeChat.pm.source", "lib/Image/DecodeQR/WeChat.pm");
mkdir("t/tmp");

chomp(my $libs    = `pkg-config opencv --libs`);
chomp(my $ccflags = `pkg-config opencv --cflags`);
#if( ! $libs or ! $ccflags ){
#	my $cv4 = check_lib(lib => 'opencv_world', ldflags => '-ltbb');     # OpenCV-4.x
#	die "Error, 'opencv_world' library can not be found." unless $cv4;
#	# ok it found something, check the headers
die "Error, either you do not have pkg-config installed or it can not find opencv.pc - have you install OpenCV?"
	unless $libs and $ccflags
;
# add extra libs here:
#$libs .= ' -ltbb';

my %WriteMakefileArgs = (
    NAME             => 'Image::DecodeQR::WeChat',
    AUTHOR           => q{Andreas Hadjiprocopis <bliako@cpan.org>},
    VERSION_FROM     => 'lib/Image/DecodeQR/WeChat.pm',
    ABSTRACT_FROM    => 'lib/Image/DecodeQR/WeChat.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
	'Devel::CheckLib' => '0',
	'FindBin' => '0',
	'File::Spec' => '0',
	'File::Copy' => '0',
	'File::ShareDir::Install' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
	'Encode' => '0',
	'FindBin' => '0',
	'File::Spec' => '0',
	'File::Copy' => '0',
	'File::ShareDir::Install' => '0',
	'Data::Roundtrip' => '0.11',
    },
    PREREQ_PM => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
	'Data::Roundtrip' => '0.11',
	'Getopt::Long' => '0',
    },
    EXE_FILES	=> [glob('script/*.pl')],

    META_MERGE => {
		'meta-spec' => { version => 2 },
		requires	=> { perl	=> '5.10.0' },
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
    LIBS    => $libs,
    CCFLAGS => $ccflags,
#    LDFLAGS => '/usr/local/lib64/libopencv_world.a',
    CC      => 'g++',
    LD      => 'g++',
    XSOPT   => '-C++',

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Image-DecodeQR-WeChat-* t/tmp/*' },
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
