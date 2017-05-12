use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'IO::Handle::Record',
    VERSION_FROM      => 'lib/IO/Handle/Record.pm', # finds $VERSION
    PREREQ_PM         => {
			  'Test::Deep' => 0,
			  'Class::Member' => 1.3,
			  'Storable' => 2.05,
			 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/IO/Handle/Record.pm', # retrieve abstract from module
       AUTHOR         => 'Torsten Foertsch <torsten.foertsch@gmx.net>') : ()),
    dist              => {
			  COMPRESS => 'gzip -9f',
			  PREOP => './mk_README.sh',
			 },
);

sub MY::postamble {
  return <<'EOF';
rpm: dist
	$(PERL) -i -pe 's/^(Version:\s*).*/$${1}$(VERSION)/' perl-IO-Handle-Record.spec
	rpmbuild -ba perl-IO-Handle-Record.spec
EOF
}
