use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $mod = my $pm = "IP::Unique";
$pm =~ s/::/\//g;
$pm = "lib/$pm.pm";
                                                                                
unless(-e "CHANGES")
{
        open CHANGES,">>CHANGES";
        print CHANGES "Temp CHANGES file\n";
        close CHANGES;
}

my $CC = "g++";

WriteMakefile(
	NAME              => $mod,
	VERSION_FROM      => $pm, # finds $VERSION
	PREREQ_PM         => {}, # e.g., Module::Name => 1.1
	($] >= 5.005 ?     ## Add these new keywords supported since 5.005
		(ABSTRACT_FROM  => $pm, # retrieve abstract from module
		AUTHOR         => 'Jay Bonci <jaybonci@cpan.org>') : ()),
	CC		      => $CC,
	CCFLAGS	      => "-Wall",
	LD		      => '$(CC)',
	LIBS              => [''], # e.g., '-lm'
	DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
	INC               => '-I.',
	XSOPT	      => '-C++',
	OBJECT            => '$(O_FILES)', # link all the C files too

	'dist'          =>
	{
		#Auto-generate the CHANGES file
		PREOP => "podselect $pm -section CHANGES | pod2text -w 1000 -i 5 | perl -pe \"s/^\s+(Version.*)/\$1/g;\" > CHANGES",
	},
);
