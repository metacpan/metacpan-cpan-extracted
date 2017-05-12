use 5.008;
use ExtUtils::MakeMaker;

unless ($^O eq 'linux') {
    warn "This is Linux only software\n";
    exit 0;
}

exit 0 if $ENV{AUTOMATED_TESTING} and !open my $f, '<', '/proc/self/smaps';

warn <<"EOF" unless( -f "/proc/$$/smaps" );
WARNING: /proc/$$/smaps not found. Maybe your kernel lacks the feature.
Maybe the proc filesystem is mounted on another location. A few tests
will be ommitted during "make test".
EOF

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Linux::Smaps',
    VERSION_FROM      => 'lib/Linux/Smaps.pm', # finds $VERSION
    PREREQ_PM         => {},
    ABSTRACT_FROM     => 'lib/Linux/Smaps.pm',
    AUTHOR            => 'Torsten Förtsch <torsten.foertsch@gmx.net>',
    dist              => {
			  COMPRESS => 'gzip -9f',
			  PREOP => './mk_README.sh',
			 },
);

sub MY::postamble {
  return <<'EOF';
README: lib/Linux/Smaps.pm mk_README.sh
	./mk_README.sh

rpm: dist
	rpmbuild -ba perl-Linux-Smaps.spec
EOF
}
