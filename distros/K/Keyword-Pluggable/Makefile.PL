use strict;
use warnings;
use ExtUtils::MakeMaker;

sub MY::postamble
{
return <<'POST'
pure_all :: README.md

README.md : lib/$(subst ::,/,$(NAME)).pm
	pod2markdown < $< > $@.tmp && $(MV) -- $@.tmp $@
POST
}

WriteMakefile(
	NAME	          => 'Keyword::Pluggable',
	AUTHOR	          => q{Dmitry Karasik <dmitry@karasik.eu.org>},
	VERSION_FROM	  => 'lib/Keyword/Pluggable.pm',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'artistic_2',
	PREREQ_PM         => {
		'Pod::Markdown' => 3.101,
	},
	META_MERGE        => {
		resources => {
			repository => 'http://github.com/dk/Keyword-Pluggable',
		},
		no_index  => {
			directory  => [qw(t)],
			file	   => [qw(Makefile.PL)],
		},
	},
);
