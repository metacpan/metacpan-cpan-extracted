package inc::MakeMaker;

use Moose;
use Config;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_MakeFile_PL_template => sub {
	my ($self) = @_;

	my $template = <<'TEMPLATE';
use strict;
use warnings;
use Config;
use Getopt::Long;
use File::Basename qw(basename dirname);

use Devel::CheckLib;

# compiler detection
my $is_gcc = length($Config{gccversion});
my $is_msvc = $Config{cc} eq 'cl' ? 1 : 0;
my $is_sunpro = (length($Config{ccversion}) && !$is_msvc) ? 1 : 0;

# os detection
my $is_solaris = ($^O =~ /(sun|solaris)/i) ? 1 : 0;
my $is_windows = ($^O =~ /MSWin32/i) ? 1 : 0;
my $is_linux = ($^O =~ /linux/i) ? 1 : 0;
my $is_osx = ($^O =~ /darwin/i) ? 1 : 0;
my $is_freebsd = ($^O =~ /freebsd/i) ? 1 : 0;
my $is_openbsd = ($^O =~ /openbsd/i) ? 1 : 0;
my $is_gkfreebsd = ($^O =~ /gnukfreebsd/i) ? 1 : 0;
my $is_netbsd = ($^O =~ /netbsd/i) ? 1 : 0;
my $is_bsd = ($^O =~ /bsd/i || $^O =~ /dragonfly/i) ? 1 : 0;

my $freebsd_version;
if ($is_freebsd)
{
	$freebsd_version = int ((split (/\./, $Config{osvers}))[0]);
}

# allow the user to override/specify the locations of OpenSSL, libssh2
our $opt = {};

Getopt::Long::GetOptions(
	"help" => \&usage,
	'with-openssl-include=s' => \$opt->{'ssl'}->{'incdir'},
	'with-openssl-libs=s@'   => \$opt->{'ssl'}->{'libs'},
) || die &usage();

my $def = '';
my $lib = '';
my $lddlfags = '';
my $inc = '';
my $ccflags = '';

my %os_specific = (
	'darwin' =>
	{
		'ssl' =>
		{
			'inc' => ['/usr/local/opt/openssl/include', '/usr/local/include', '/usr/include'],
			'lib' => ['/usr/local/opt/openssl/lib', '/usr/local/lib', '/usr/lib']
		}
	},
	'MSWin32' =>
	{
		'ssl' =>
		{
			#'inc' => ['C:\Strawberry\c\include'],
			#'lib' => ['C:\Strawberry\c\lib']
		}
	},
);

my ($ssl_libpath, $ssl_incpath);
if (my $os_params = $os_specific{$^O})
{
	if (my $ssl = $os_params -> {'ssl'})
	{
		$ssl_libpath = $ssl -> {'lib'};
		$ssl_incpath = $ssl -> {'inc'};
	}
}


my @library_tests =
(
	{
		'lib'     => 'ssl',
		'libpath' => $ssl_libpath,
		'incpath' => $ssl_incpath,
		'header'  => 'openssl/opensslconf.h',
	},
);

if ($is_linux)
{
	push @library_tests,
	{
		'lib'     => 'udev',
		'header'  => 'libudev.h',
	},
	{
		'lib'     => 'usb',
		'header'  => 'libusb.h',
	};
}

my %library_opts =
(
	'ssl' =>
	{
		'defines' => '',
		'libs'    => ' -lcrypto',
	},
	'udev' =>
	{
		'defines' => '',
		'libs'    => ' -ludev',
	},
	'usb' =>
	{
		'defines' => '',
		'libs'    => ' -lusb',
	},
);

# check for optional libraries
foreach my $test (@library_tests)
{
	my $library = $test->{lib};
	my $user_library_opt = $opt->{$library};
	my $user_incpath = $user_library_opt->{'incdir'};
	my $user_libs = $user_library_opt->{'libs'};

	if ($user_incpath && $user_libs)
	{
		$inc .= " -I\"$user_incpath\"";

		# perform some magic
		foreach my $user_lib (@$user_libs)
		{
			my ($link_dir, $link_lib) = (dirname ($user_lib), basename ($user_lib));

			if (!$is_msvc)
			{
				my @tokens = grep { $_ } split(/(lib|\.)/, $link_lib);
				shift @tokens if ($tokens[0] eq 'lib');
				$link_lib = shift @tokens;
			}
			$lddlfags .= " -L\"$link_dir\"";
			$lib .= " -L\"$link_dir\" -l$link_lib";
		}

		my $opts = $library_opts{$library};
		$opts->{'use'} = 1;

		$def .= $opts->{'defines'};

		print uc ($library), " support enabled (user provided)", "\n";
	}
	elsif (check_lib (%$test))
	{
		if (exists ($test->{'incpath'}))
		{
			if (my $incpath = $test->{'incpath'})
			{
				$inc .= ' -I'.join (' -I', map { "\"$_\"" } @$incpath);
			}
		}

		if (exists ($test->{'libpath'}))
		{
			if (my $libpath = $test->{'libpath'})
			{
				$lib .= ' -L'.join (' -L', map { "\"$_\"" } @$libpath);
				$lddlfags .= ' -L'.join (' -L', map { "\"$_\"" } @$libpath);
			}
		}

		my $opts = $library_opts{$library};
		$opts->{'use'} = 1;

		$def .= $opts->{'defines'};
		$lib .= $opts->{'libs'};

		print uc ($library), " support enabled", "\n";
	}
	else
	{
		print uc ($library), " support disabled", "\n";
	}
}

# cbor options
if ($Config{sizetype} ne 'size_t')
{
	die "Perl's sizetype is not a 'size_t' but a '$Config{sizetype}'!";
}

if ($Config{sizesize} != 8)
{
	die "Your size_t is less than 8 bytes. Long items with 64b length specifiers might not work as expected!";
}

$def .= ' -DEIGHT_BYTE_SIZE_T';


# fido2 options
$def .= ' -D_FIDO_INTERNAL -D_FIDO_MAJOR=1 -D_FIDO_MINOR=4 -D_FIDO_PATCH=0';
$def .= ' -DHAVE_GETLINE';

if (!$is_windows)
{
	$def .= ' -DHAVE_SIGNAL_H -DHAVE_UNISTD_H -DHAVE_DEV_URANDOM';
}

if ($is_linux)
{
	$def .= ' -DHAVE_ENDIAN_H';
}

if ($is_linux && $is_bsd)
{
	$def .= ' -DHAVE_RECALLOCARRAY';
}

if ($is_linux)
{
	$def .= ' -DHAVE_SYS_RANDOM_H -DHAVE_CLOCK_GETTIME';
}

if ($is_osx)
{
	$def .= ' -DHAVE_ARC4RANDOM_BUF -DHAVE_CLOCK_GETTIME -DTLS=__thread';
	$lddlfags .= ' -framework CoreFoundation -framework Security';
}

if ($is_osx || ($is_freebsd && $freebsd_version >= 12))
{
	$def .= ' -D__STDC_WANT_LIB_EXT1__=1 -DHAVE_MEMSET_S';
}

if ($is_bsd || $is_osx)
{
	$def .= ' -DHAVE_STRLCAT -DHAVE_STRLCPY';
}

if ($is_bsd || $is_osx || $is_linux)
{
	$def .= ' -DHAVE_GETPAGESIZE -DHAVE_SYSCONF';
}

if ($is_osx || $is_linux)
{
	$def .= ' -DHAVE_GETRANDOM';
}

if ($is_msvc)
{
	$def .= ' -DTLS=__declspec(thread)'
}


# compiler/OS specific options
if ($is_solaris)
{
	$def .= ' -D_POSIX_C_SOURCE=200112L -D__EXTENSIONS__ -D_POSIX_PTHREAD_SEMANTICS';
}

if (!$is_windows)
{
	$def .= ' -D_FILE_OFFSET_BITS=64 -D_GNU_SOURCE';
}

if ($is_gcc)
{
	# gcc-like compiler
	$ccflags .= ' -std=c99 -Wall -Wno-unused-variable -Wno-pedantic -Wno-deprecated-declarations';

	# clang compiler is pedantic!
	if ($is_osx)
	{
		# clang masquerading as gcc
		if ($Config{gccversion} =~ /LLVM/)
		{
			$ccflags .= ' -Wno-unused-const-variable -Wno-unused-function';
		}
	}
}
elsif ($is_sunpro)
{
	# probably the SunPro compiler, (try to) enable C99 support
	$ccflags .= ' -xc99=all,no_lib';
	$def .= ' -D_STDC_C99';

	$ccflags .= ' -errtags=yes -erroff=E_EMPTY_TRANSLATION_UNIT -erroff=E_ZERO_OR_NEGATIVE_SUBSCRIPT';
	$ccflags .= ' -erroff=E_EMPTY_DECLARATION -erroff=E_STATEMENT_NOT_REACHED';
}

if ($is_windows)
{
	$def .= ' -DWIN32 -DSTRSAFE_NO_DEPRECATE';
	$lib .= ' -lwinhttp -lrpcrt4 -lcrypt32 -lbcrypt -lhid -lsetupapi';

	if ($is_msvc)
	{
		# visual studio compiler
		$def .= ' -DWIN32_LEAN_AND_MEAN -D_CRT_SECURE_NO_WARNINGS';
	}
	else
	{
		# mingw/cygwin
		$def .= ' -D_WIN32_WINNT=0x0600 -D__USE_MINGW_ANSI_STDIO=1';
	}
}


my @cborsrcs = glob 'deps/libcbor/src/{cbor.c,cbor/*.c,cbor/internal/*.c}';

my @fido2compat = (qw/
	bsd-getline.c
	bsd-getpagesize.c
	getopt_long.c
	recallocarray.c
	strlcat.c
	strlcpy.c
	timingsafe_bcmp.c
/);

push @fido2compat, (qw/
	explicit_bzero_win32.c
	posix_win.c
	readpassphrase_win32.c
/) if ($is_windows);

push @fido2compat, (qw/
	explicit_bzero.c
	readpassphrase.c
/) if (!$is_windows);


my @fido2srcs = (qw/
	aes256.c
	assert.c
	authkey.c
	bio.c
	blob.c
	buf.c
	cbor.c
	cred.c
	credman.c
	dev.c
	ecdh.c
	eddsa.c
	err.c
	es256.c
	info.c
	io.c
	iso7816.c
	log.c
	pin.c
	reset.c
	rs256.c
	u2f.c
	hid.c
/);

push @fido2srcs, 'hid_linux.c' if ($is_linux && $library_opts{udev}{use});
push @fido2srcs, 'hid_openbsd.c' if ($is_openbsd);
push @fido2srcs, 'hid_osx.c' if ($is_osx);
push @fido2srcs, 'hid_win.c' if ($is_windows);


my @hidapisrcs;
if ($is_bsd && !$is_openbsd && !$is_windows && !$is_osx || ($is_linux && !$library_opts{udev}{use} && $library_opts{usb}{use}))
{
	push @fido2srcs, 'hid_hidapi.c';
	push @hidapisrcs, 'deps/hidapi/libusb/hid.c';

	$def .= ' -DUSE_HIDAPI';
	$lib .= ' -lusb -liconv';
}

my @srcs = ((map { "deps/libfido2/openbsd-compat/$_" } @fido2compat), (map { "deps/libfido2/src/$_" } @fido2srcs));
my @objs = map { substr ($_, 0, -1) . 'o' } (@cborsrcs, @srcs, @hidapisrcs);

sub MY::c_o {
	my $out_switch = '-o ';

	if ($is_msvc) {
		$out_switch = '/Fo';
	}

	my $line = qq{
.c\$(OBJ_EXT):
	\$(CCCMD) \$(CCCDLFLAGS) "-I\$(PERL_INC)" \$(PASTHRU_DEFINE) \$(DEFINE) \$*.c $out_switch\$@
};

	if ($is_gcc)
	{
		# disable parallel builds
		$line .= qq{

.NOTPARALLEL:
};
	}
	return $line;
}

# This Makefile.PL for {{ $distname }} was generated by Dist::Zilla.
# Don't edit it but the dist.ini used to construct it.
{{ $perl_prereq ? qq[BEGIN { require $perl_prereq; }] : ''; }}
use strict;
use warnings;
use ExtUtils::MakeMaker {{ $eumm_version }};
use ExtUtils::Constant qw (WriteConstants);

{{ $share_dir_block[0] }}
my {{ $WriteMakefileArgs }}

$WriteMakefileArgs{MIN_PERL_VERSION}  = '5.8.8';
$WriteMakefileArgs{DEFINE}  .= $def;
$WriteMakefileArgs{LIBS}    .= $lib;
$WriteMakefileArgs{INC}     .= $inc;
$WriteMakefileArgs{CCFLAGS} .= $Config{ccflags} . ' '. $ccflags;
$WriteMakefileArgs{LDDLFLAGS} .= $Config{lddlflags} . ' '. $lddlfags;
$WriteMakefileArgs{OBJECT}  .= ' ' . join ' ', @objs;
$WriteMakefileArgs{clean} = {
	FILES => "*.inc"
};

my @constants = (qw(
	OPT_OMIT
	OPT_FALSE
	OPT_TRUE

	COSE_ES256
	COSE_EDDSA
	COSE_ECDH_ES256
	COSE_RS256

	COSE_KTY_OKP
	COSE_KTY_EC2
	COSE_KTY_RSA

	COSE_P256
	COSE_ED25519

	EXT_HMAC_SECRET
	EXT_CRED_PROTECT

	CRED_PROT_UV_OPTIONAL
	CRED_PROT_UV_OPTIONAL_WITH_ID
	CRED_PROT_UV_REQUIRED

	ERR_SUCCESS
	ERR_INVALID_COMMAND
	ERR_INVALID_PARAMETER
	ERR_INVALID_LENGTH
	ERR_INVALID_SEQ
	ERR_TIMEOUT
	ERR_CHANNEL_BUSY
	ERR_LOCK_REQUIRED
	ERR_INVALID_CHANNEL
	ERR_CBOR_UNEXPECTED_TYPE
	ERR_INVALID_CBOR
	ERR_MISSING_PARAMETER
	ERR_LIMIT_EXCEEDED
	ERR_UNSUPPORTED_EXTENSION
	ERR_CREDENTIAL_EXCLUDED
	ERR_PROCESSING
	ERR_INVALID_CREDENTIAL
	ERR_USER_ACTION_PENDING
	ERR_OPERATION_PENDING
	ERR_NO_OPERATIONS
	ERR_UNSUPPORTED_ALGORITHM
	ERR_OPERATION_DENIED
	ERR_KEY_STORE_FULL
	ERR_NOT_BUSY
	ERR_NO_OPERATION_PENDING
	ERR_UNSUPPORTED_OPTION
	ERR_INVALID_OPTION
	ERR_KEEPALIVE_CANCEL
	ERR_NO_CREDENTIALS
	ERR_USER_ACTION_TIMEOUT
	ERR_NOT_ALLOWED
	ERR_PIN_INVALID
	ERR_PIN_BLOCKED
	ERR_PIN_AUTH_INVALID
	ERR_PIN_AUTH_BLOCKED
	ERR_PIN_NOT_SET
	ERR_PIN_REQUIRED
	ERR_PIN_POLICY_VIOLATION
	ERR_PIN_TOKEN_EXPIRED
	ERR_REQUEST_TOO_LARGE
	ERR_ACTION_TIMEOUT
	ERR_UP_REQUIRED
	ERR_UV_BLOCKED
	ERR_ERR_OTHER
	ERR_SPEC_LAST

	OK
	ERR_TX
	ERR_RX
	ERR_RX_NOT_CBOR
	ERR_RX_INVALID_CBOR
	ERR_INVALID_PARAM
	ERR_INVALID_SIG
	ERR_INVALID_ARGUMENT
	ERR_USER_PRESENCE_REQUIRED
	ERR_INTERNAL
));

ExtUtils::Constant::WriteConstants
(
	NAME         => 'FIDO::Raw',
	NAMES        => [@constants],
	DEFAULT_TYPE => 'IV',
	C_FILE       => 'const-c-constant.inc',
	XS_FILE      => 'const-xs-constant.inc',
	XS_SUBNAME   => '_constant',
	C_SUBNAME    => '_c_constant',
);

if (!eval { ExtUtils::MakeMaker->VERSION (6.56) })
{
	my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
	my $pp = $WriteMakefileArgs{PREREQ_PM};

	for my $mod (keys %$br)
	{
		if (exists $pp->{$mod})
		{
			$pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
		}
		else
		{
			$pp->{$mod} = $br->{$mod};
		}
	}
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
	unless eval { ExtUtils::MakeMaker->VERSION (6.52) };

WriteMakefile (%WriteMakefileArgs);
exit (0);

sub usage {
	print STDERR << "USAGE";
Usage: perl $0 [options]

Possible options are:
  --with-openssl-include=<path>    Specify <path> for the root of the OpenSSL installation.
  --with-openssl-libs=<libs>       Specify <libs> for the OpenSSL libraries.
USAGE

	exit(1);
}

{{ $share_dir_block[1] }}
TEMPLATE

	return $template;
};

override _build_WriteMakefile_args => sub {
	return +{
		%{ super() },
		INC	    => ' -Ideps/config -Ideps/libcbor/src -Ideps/libfido2 -Ideps/libfido2/src -Ideps/hidapi -Ideps/hidapi/hidapi',
		OBJECT	=> '$(O_FILES)',
	}
};

__PACKAGE__->meta->make_immutable;
