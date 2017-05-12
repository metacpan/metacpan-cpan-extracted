use strict;
use utf8;
use Config;

use FindBin;
use ExtUtils::MakeMaker;

my $myhtml_source_dir = $FindBin::Bin ."/source";

WriteMakefile(
    AUTHOR         => 'Alexander Borisov <lex.borisov@gmail.com>',
    ABSTRACT       => 'Fast HTML Parser using Threads with no outside dependencies',
    VERSION_FROM   => 'MyHTML.pm',
    NAME           => 'HTML::MyHTML',
    LICENSE        => 'Apache 2.0',
    LINKTYPE       => 'dynamic',
    LIBS           => ["-lpthread"],
	CCFLAGS        => " --std=c99 ". $Config{ccflags},
	INC            => "-I$myhtml_source_dir",
);
