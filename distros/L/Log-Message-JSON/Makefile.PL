#!/usr/bin/perl

use warnings;
use strict;
use ExtUtils::MakeMaker;

# ExtUtils::MakeMaker on Debian is a developer release (?!?)
no warnings qw{numeric};

WriteMakefile(
  NAME          => 'Log::Message::JSON',
  AUTHOR        => q{Stanislaw Klekot <cpan@jarowit.net>},
  VERSION_FROM  => 'lib/Log/Message/JSON.pm',
  #ABSTRACT_FROM => 'lib/Log/Message/JSON.pm',
  ($ExtUtils::MakeMaker::VERSION >= 6.3002
    ? ('LICENSE'=> 'perl')
    : ()),
  PREREQ_PM => {
    base          => 0,
    overload      => 0,
    Exporter      => 0,
    Carp          => 0,
    'Tie::IxHash' => 0,
  },
  dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

sub MY::postamble {
  return <<'EOF'
.PHONY: reltest
reltest: export RELEASE_TESTING=1
reltest: test

.PHONY: tarball
tarball: make reltest
	git archive --format=tar --prefix=$(DISTVNAME)/ v$(VERSION) | gzip -9 > $(DISTVNAME).tar.gz

.PHONY: make
make: Makefile

Makefile: lib/Log/Message/JSON.pm
EOF
}
