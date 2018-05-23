use strict;
use utf8;
use Config;

use FindBin;
use ExtUtils::MakeMaker;

my $source_dir = $FindBin::Bin ."/third_party/modest/include";
my $port = "posix";
my $modest_source = "third_party/modest/source";

$port = 'windows_nt' if ($^O =~ /MSWin/i);

my $sources = [
	"modest.o", 
	"DOM.o"
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
	LIBS			=> ["-lpthread", "-lm"],
	CCFLAGS			=> " -std=c99 ". $Config{ccflags},
	INC				=> "-I$source_dir",
	OBJECT			=> join(" ", @$sources), 
	test			=> {TESTS => 't/*.t t/*/*.t'}
);
