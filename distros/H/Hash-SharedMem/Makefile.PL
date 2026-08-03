{ use 5.006; }
use warnings;
use strict;

use ExtUtils::CBuilder;
use ExtUtils::MakeMaker 7.12;

my $cbuilder = ExtUtils::CBuilder->new;

my $testnum = 0;
my $compile_ok = sub {
	my($hdrs, $code, $link_extra) = @_;
	my $conftest_c = "conftest".$testnum++.".c";
	open my $src_fh, ">", $conftest_c
		or die "can't write $conftest_c: $!";
	print $src_fh
			"#include \"EXTERN.h\"\n".
			"#include \"perl.h\"\n".
			"#include \"XSUB.h\"\n".
			join("", map { "#include <$_>\n" } @$hdrs).
			"int main(void) {$code}\n"
		or die "can't write $conftest_c: $!";
	close $src_fh or die "can't write $conftest_c: $!";
	my($obj_file, $exe_file);
	my $ok = eval {
		$obj_file = $cbuilder->compile(source => $conftest_c);
		$exe_file = $cbuilder->link_executable(
			objects => $obj_file,
			extra_linker_flags => $link_extra || [],
		);
		1;
	};
  unlink grep { defined } $conftest_c, $obj_file, $exe_file;
	return $ok ? 1 : 0;
};

my %defs;
my @libs;
$compile_ok->(["stdio.h"], q{
	char buf[5];
	return sprintf(buf, "%d", 0) + 1;
}) or die "probe system failed: can't compile innocuous program";
$compile_ok->([], q{
	extern int HLBNzorFAJMYbPEjiEKkMFBaKqZMkqq(void);
	return HLBNzorFAJMYbPEjiEKkMFBaKqZMkqq() + 1;
}) and die "probe system failed: non-existent function usable";
$compile_ok->(["sys/mman.h"], q{
	int res;
	res = mmap(NULL, 4096, PROT_READ, MAP_SHARED, 3, 0)
		== (void*)-1;
	return res;
}) or die "OS unsupported: mmap(2) not available";
$defs{QHAVE_GETPAGESIZE} = $compile_ok->([], q{
	int res;
	res = getpagesize();
	return res;
});
$defs{QHAVE_SYSCONF} = $compile_ok->([], q{
	int res;
	res = sysconf(0);
	return res;
});
$defs{QHAVE_PATHCONF} = $compile_ok->([], q{
	int res;
	res = pathconf("/", 0);
	return res;
});
$defs{QHAVE_CLOCK_GETTIME} = $compile_ok->([], q{
	struct timespec ts;
	int res;
	res = clock_gettime(CLOCK_REALTIME, &ts);
	return res;
});
if(!$defs{QHAVE_CLOCK_GETTIME} &&
		$compile_ok->([], q{
			struct timespec ts;
			int res;
			res = clock_gettime(CLOCK_REALTIME, &ts);
			return res;
		}, ["-lrt"])) {
	push @libs, "-lrt";
	$defs{QHAVE_CLOCK_GETTIME} = 1;
}
$defs{QHAVE_GETTIMEOFDAY} = $compile_ok->([], q{
	struct timeval tv;
	int res;
	res = gettimeofday(&tv, NULL);
	return res;
});
# Cygwin declares openat(2) et al functions, and they
# superficially appear to work, but they're frauds.  They don't
# actually use a reference to the directory, as a fd would appear
# to supply.  Instead the directory fd encapsulates the absolute
# pathname under which the directory was opened, and openat(2)
# et al use the saved pathname.  They therefore fail if the
# directory is renamed.
# <http://www.cygwin.com/ml/cygwin-developers/2008-04/msg00108.html>
# We therefore reject Cygwin's versions of these functions,
# in favour of our own fakery that we don't mistake for the
# real thing.
$defs{QHAVE_OPENAT} = $^O eq "cygwin" ? 0 :
	$compile_ok->([], q{
		int res;
		res = openat(0, ".", 0, 0);
		return res;
	});
$defs{QHAVE_FSTATAT} = $^O eq "cygwin" ? 0 :
	$compile_ok->([], q{
		struct stat st;
		int res;
		res = fstatat(0, ".", &st, 0);
		return res;
	});
$defs{QHAVE_LINKAT} = $^O eq "cygwin" ? 0 :
	$compile_ok->([], q{
		int res;
		res = linkat(0, ".", 0, ".", 0);
		return res;
	});
$defs{QHAVE_UNLINKAT} = $^O eq "cygwin" ? 0 :
	$compile_ok->([], q{
		int res;
		res = unlinkat(0, ".", 0);
		return res;
	});
$defs{QHAVE_FDOPENDIR} = $compile_ok->([], q{
	DIR *dirh;
	dirh = fdopendir(0);
	return !dirh;
});
$defs{QHAVE_REALPATH} = $compile_ok->([], q{
	char *res, buf[4096];
	res = realpath(".", buf);
	return !res;
});
$defs{QHAVE_GETCWD} = $compile_ok->([], q{
	char *res, buf[4096];
	res = getcwd(buf, sizeof(buf));
	return !res;
});

$defs{QWITH_TALLY} = 1;

my $cc0_h = "lib/Hash/callchecker0.h";
unless(-f $cc0_h) {
	my $content = eval {
		local $SIG{__DIE__};
		require Devel::CallChecker;
		Devel::CallChecker->VERSION(0.003);
		&Devel::CallChecker::callchecker0_h();
	} || "";
	open my $fh, ">", $cc0_h or die "can't write $cc0_h: $!";
	print $fh $content or die "can't write $cc0_h: $!";
	close $fh or die "can't write $cc0_h: $!";
}

my @cc_linkables = eval {
	local $SIG{__DIE__};
	require Devel::CallChecker;
	Devel::CallChecker->VERSION(0.003);
	Devel::CallChecker::callchecker_linkable();
};

WriteMakefile(
	NAME => "Hash::SharedMem",
	VERSION_FROM => "lib/Hash/SharedMem.pm",
	ABSTRACT_FROM => "lib/Hash/SharedMem.pm",
	AUTHOR => 'Kurt Starsinic <cpan@kstar.fastmail.fm>',
	LICENSE => "perl",
	MIN_PERL_VERSION => "5.006",
  XSMULTI => 1,
	CONFIGURE_REQUIRES => {
		"ExtUtils::CBuilder" => "0.15",
		"ExtUtils::MakeMaker" => 0,
		"perl" => "5.006",
		"strict" => 0,
		"warnings" => 0,
	},
	BUILD_REQUIRES => {
		"ExtUtils::ParseXS" => "3.30",
	},
	TEST_REQUIRES => {
		"Data::Dumper" => 0,
		"Errno" => "1.00",
		"File::Temp" => "0.22",
		"IO::File" => 0,
		"POSIX" => 0,
		"Scalar::String" => 0,
		"Test::Builder" => "0.03",
		"Test::More" => "0.40",
		"if" => 0,
		"utf8" => 0,
	},
	PREREQ_PM => {
		"Exporter" => 0,
		"XSLoader" => 0,
		"parent" => 0,
		"strict" => 0,
		"warnings" => 0,
	},
	DEFINE => join(" ", map { "-D$_=".$defs{$_} } sort keys %defs),
	LIBS => [ join(" ", @libs) ],
	OBJECT => join(" ", "\$(BASEEXT)\$(OBJ_EXT)", @cc_linkables),
	dist => { COMPRESS => "gzip -9f", SUFFIX => "gz" },
	clean => { FILES => "$cc0_h conftest*" },
	META_MERGE => {
		"meta-spec" => { version => 2 },
		prereqs => {
			configure => {
				suggests => {
					"Devel::CallChecker" => "0.003",
				},
			},
			runtime => {
				suggests => {
					"Devel::CallChecker" => "0.003",
				},
			},
		},
		resources => {
			bugtracker => {
				mailto => "bug-Hash-SharedMem\@rt.cpan.org",
				web => "https://rt.cpan.org/Public/Dist/".
					"Display.html?Name=Hash-SharedMem",
			},
		},
	},
);

1;
