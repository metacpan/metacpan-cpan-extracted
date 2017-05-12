#!/usr/bin/perl

use warnings;
use strict;
use ExtUtils::MakeMaker;

# ExtUtils::MakeMaker on Debian is a developer release (?!?)
no warnings qw{numeric};

WriteMakefile(
  NAME          => 'Log::Log4perl::Appender::Fluent',
  AUTHOR        => q{Stanislaw Klekot <cpan@jarowit.net>},
  VERSION_FROM  => 'lib/Log/Log4perl/Appender/Fluent.pm',
  #ABSTRACT_FROM => 'lib/Log/Log4perl/Appender/Fluent.pm',
  ($ExtUtils::MakeMaker::VERSION >= 6.3002
    ? ('LICENSE'=> 'perl')
    : ()),
  PREREQ_PM => {
    base => 0,
    'Sys::Hostname'  => 0,
    'Fluent::Logger' => 0,
    'Log::Log4perl::Appender' => 0,
  },
  dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

sub MY::postamble {
  return <<'EOF'
.PHONY: tarball
tarball: export RELEASE_TESTING=1
tarball: test
	git archive --format=tar --prefix=$(DISTVNAME)/ v$(VERSION) | gzip -9 > $(DISTVNAME).tar.gz
EOF
}
