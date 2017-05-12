use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  (
   NAME           => 'MMapDB',
   VERSION_FROM   => 'lib/MMapDB.pm', # finds $VERSION
   PREREQ_PM      => {
		      'File::Map' => 0.21,
		     }, # e.g., Module::Name => 1.1
   ABSTRACT_FROM  => 'lib/MMapDB.pm', # retrieve abstract from module
   AUTHOR         => 'Torsten Foertsch <torsten.foertsch@gmx.net>',
   dist           => {
		      COMPRESS => 'gzip -9f',
		      PREOP => './mk_README.sh',
		     },
   LIBS           => [''], # e.g., '-lm'
   DEFINE         => '', # e.g., '-DHAVE_SOMETHING'
   INC            => '-I.', # e.g., '-I. -I/usr/include/other'
   # Un-comment this if you add C files to link with later:
   # OBJECT       => '$(O_FILES)', # link all the C files too
   EXE_FILES      => [map "bin/$_", qw!MMDB-backup MMDB-restore MMDB-lookup!],
);

sub MY::postamble {
  return <<'EOF';
rpm: dist
	$(PERL) -i -pe 's/^(Version:\s*).*/$${1}$(VERSION)/' perl-MMapDB.spec
	rpmbuild -ba perl-MMapDB.spec
EOF
}
