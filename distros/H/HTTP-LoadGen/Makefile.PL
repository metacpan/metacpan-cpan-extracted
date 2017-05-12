use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile
  (
   NAME           => 'HTTP::LoadGen',
   VERSION_FROM   => 'lib/HTTP/LoadGen.pm',
   PREREQ_PM      => {
		      'IPC::ScoreBoard' => 0.03,
		      'Coro' => '5.23',
		      'AnyEvent' => '5.261',
		      'Async::Interrupt' => '1.05', # to get reliable SIGCHLD
		      'Net::SSLeay' => '1.35',
		     },
   ABSTRACT_FROM  => 'lib/HTTP/LoadGen.pod',
   AUTHOR         => 'Torsten Förtsch <torsten.foertsch@gmx.net>',
   dist           => {
		      COMPRESS => 'gzip -9f',
		      PREOP => './mk_README.sh',
		     },
   EXE_FILES      => [qw!bin/loadgen!],
  );

sub MY::postamble {
  return <<'EOF';
rpm: dist
	$(PERL) -i -pe 's/^(Version:\s*).*/$${1}$(VERSION)/' perl-HTTP-LoadGen.spec
	rpmbuild -ba perl-HTTP-LoadGen.spec
EOF
}
