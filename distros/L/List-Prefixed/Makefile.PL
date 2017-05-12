use 5.004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME              => 'List::Prefixed',
	VERSION_FROM      => 'lib/List/Prefixed.pm', # finds $VERSION
	ABSTRACT_FROM     => 'lib/List/Prefixed.pm', # retrieve abstract from module
	PREREQ_PM         => {}, # e.g., Module::Name => 1.1
	TEST_REQUIRES     => {
		'Test::More' => '0.98',
		'File::Basename' => '2.77',
		'IO::Zlib' => '1.10',
	},
	AUTHOR            => 'Sebastian Böthinr <boethin@xn--domain.net>',
	
	(eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'https://github.com/boethin/List-Prefixed.git',
				web => 'https://github.com/boethin/List-Prefixed',
			},
		}
	}) : ()
	),
	
);

sub MY::postamble {
	return <<'EOF';
# 'make readme'
# generate README.* from pod section
.PHONY: readme
readme: README README.pod README.md
README README.pod README.md: $(VERSION_FROM)

README:
	pod2text $< >$@

README.pod:
	podselect $< >$@

README.md:
	pod2markdown $< >$@
	
EOF
}


