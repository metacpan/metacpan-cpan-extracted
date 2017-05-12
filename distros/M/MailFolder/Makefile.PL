#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME     => 'Mail',
	      VERSION  => '0.07',
	      DISTNAME => 'MailFolder',
	      PREREQ_PM => { Mail::Internet => 1.30,
			     Date::Format => 2.09,
			     File::Sync => 0.06,
			     MIME::Tools => 4.116,
			     },
	      'dist'   => { COMPRESS => 'gzip', SUFFIX => '.gz' },
);

sub MY::test {
  q(
TEST_VERBOSE=0

test:
	$(FULLPERL) t/TEST $(TEST_VERBOSE)
);
}
