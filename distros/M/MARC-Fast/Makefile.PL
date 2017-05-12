use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'MARC::Fast',
    VERSION_FROM => 'lib/MARC/Fast.pm', # finds $VERSION
    AUTHOR       => 'Dobrica Pavlinusic (dpavlin@rot13.org)',
    ABSTRACT     => '',
    PREREQ_PM    => {
	'Test::Simple' => 0.44,
	'Data::Dump' => 0,
	'Carp' => 0,
    },
    META_MERGE => {
        resources => {
            license => 'http://www.gnu.org/licenses/gpl-2.0.html',
            bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=MARC-Fast',
            repository => 'http://github.com/dpavlin/MARC-Fast'
        },
    },
);

sub MY::postamble {
	return <<'MAKE_MORE';

changelog:
	git log > Changes

cpan:
	make clean
	rm -f MARC-Fast-*.tar.gz
	perl Makefile.PL
	make changelog
	make dist
	make disttest
	@echo
	@echo -n "Upload" MARC-Fast-*.tar.gz "to CPAN? [y/N]:"
	@read upload && test "$$upload" == "y" && cpan-upload -verbose MARC-Fast-*.tar.gz

MAKE_MORE
}
