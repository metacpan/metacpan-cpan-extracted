use 5.008003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Math::EMA',
    VERSION_FROM      => 'lib/Math/EMA.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Math/EMA.pm', # retrieve abstract from module
    AUTHOR            => 'Torsten Foertsch <torsten.foertsch@gmx.net>',
    dist              => {
			  COMPRESS => 'gzip -9f',
			  PREOP => './mk_README.sh',
			 },
);

sub MY::postamble {
  return <<'EOF';
rpm: dist
	$(PERL) -i -pe 's/^(Version:\s*).*/$${1}$(VERSION)/' perl-Math-EMA.spec
	rpmbuild -ba perl-Math-EMA.spec
EOF
}
