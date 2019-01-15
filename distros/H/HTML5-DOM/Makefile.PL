use strict;
use utf8;
use Config;

use FindBin;
use ExtUtils::MakeMaker;

my $source_dir = $FindBin::Bin ."/third_party/modest/include";
my $port = "posix";
my $modest_source = "third_party/modest/source";

my $libs = [];

if ($^O =~ /MSWin/i) {
	$port = 'windows_nt';
} else {
	$libs = ["-lpthread", "-lm"];
}

my $defines = "";

if ($^O =~ /openbsd|netbsd|freebsd/i) {
	# Simulates mutex using semaphore
	# Because MyHTML call phtread_mutex_unlock without before call phtread_mutex_lock
	# And it crashes on OpenBSD
	warn("Detected *BSD - switch from mutex to semaphore\n");
	$defines = " -DMyCORE_USE_SEMAPHORE_INSTEAD_OF_MUTEX ";
}

my $sources = [
	"DOM.o", 
	"utils.o", 
	"modest_modest.o", 
	"modest_mycore.o", 
	"modest_mycss.o", 
	"modest_myencoding.o", 
	"modest_myfont.o", 
	"modest_myhtml.o", 
	"modest_myport.o", 
	"modest_myurl.o"
];

WriteMakefile(
	dist	=> {
		PREOP		=> 'pod2text lib/HTML5/DOM.pod > README',
		COMPRESS	=> 'gzip -9v',
		SUFFIX		=> '.gz',
	},
	AUTHOR			=> 'Kirill Zhumarin <kirill.zhumarin@gmail.com>',
	ABSTRACT		=> 'Super fast html5 DOM library with css selectors (based on Modest/MyHTML)',
	VERSION_FROM	=> 'lib/HTML5/DOM.pm',
	NAME			=> 'HTML5::DOM',
	LICENSE			=> 'MIT',
	LINKTYPE		=> 'dynamic',
	LIBS			=> $libs,
	DEFINE			=> $defines, 
	CCFLAGS			=> " -std=c99 ".$Config{ccflags},
	INC				=> "-I$source_dir",
	OBJECT			=> join(" ", @$sources), 
	test			=> {TESTS => 't/*.t t/*/*.t'}, 
	
	(eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type	=> 'git',
				url		=> 'https://github.com/Azq2/perl-html5-dom.git',
				web		=> 'https://github.com/Azq2/perl-html5-dom',
			},
		}}) : ()
	),
);
