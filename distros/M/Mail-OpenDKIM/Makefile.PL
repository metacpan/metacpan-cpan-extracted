use 5.010000;
use ExtUtils::MakeMaker;
use Config;

use ExtUtils::Liblist;

# Check that OpenDKIM has been installed

my $libpath = ExtUtils::Liblist->ext('-lopendkim');

unless($libpath) {
	my $found = 0;

	foreach(split(/\s+/, $Config{libpth})) {
		my $filename = "$_/libopendkim.$Config{so}";
		if((-r $filename) && (-f $filename)) {
			$found = 1;
			last;
		}
	}

	# TODO: Windows, etc
	unless($found) {
		die 'Please install libopendkim >= 2.10 from http://www.opendkim.org/';
	}
	# TODO: Check the installed version is >= 2.10
}

WriteMakefile(
    NAME => 'Mail::OpenDKIM',
    PREREQ_PM => {
   	 'Error' => 0,
	 'Test::More' => 0.82,	# Needs new_ok
	 'Carp' => 0,
	 },
    VERSION_FROM => 'lib/Mail/OpenDKIM.pm',
    AUTHOR => 'Vivek Khera <vivek@khera.org>',
    ABSTRACT => 'Provides an interface to OpenDKIM C library',
    LIBS => ['-lopendkim'],
    INC => '-I/usr/local/include',
    OBJECT => '$(O_FILES)', # link all the C files too
    LICENSE => 'perl',
    OPTIMIZE => '-O0',          # -O2 errors with perl 5.16, gcc 4.2.1, FreeBSD 9.1
    META_MERGE => {
	'meta-spec' => { version => 2 },
	resources => {
	    repository => {
		type => 'git',
		url  => 'https://github.com/infracaninophile/Mail-OpenDKIM.git',
		web  => 'https://github.com/infracaninophile/Mail-OpenDKIM',
	    },
	},
    },
);

sub MY::postamble {
  return <<'MAKE_FRAG';
all :: README

README: lib/Mail/OpenDKIM.pm
	pod2text $> > README
MAKE_FRAG
}
