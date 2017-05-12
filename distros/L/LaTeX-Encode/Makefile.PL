# $Id: Makefile.PL 30 2012-09-25 20:24:40Z andrew $

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'LaTeX::Encode',
    AUTHOR              => 'Chris Travers <chris@efficito.com>',
    VERSION_FROM        => 'lib/LaTeX/Encode.pm',
    ABSTRACT_FROM       => 'lib/LaTeX/Encode.pm',
    PL_FILES            => {},
    EXE_FILES           => [ 'scripts/latex-encode' ],
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PREREQ_PM => {
        'Getopt::Long'      => 0,
        'HTML::Entities'    => 0,
        'Pod::LaTeX'        => 0,
        'Pod::Usage'        => 0,
        'Readonly'          => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'        => 0,
	'Carp::Always'      => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'LaTeX-Encode-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/einhverfr/LaTeX-Encode.git',
                 web  => 'https://github.com/einhverfr/LaTeX-Encode',
             },
         },
    },
);

no warnings 'redefine';

sub MY::postamble {
    return q{
lib/LaTeX/Encode/EncodingTable.pm: scripts/build-encoding-table
	 scripts/build-encoding-table >lib/LaTeX/Encode/EncodingTable.pm
};
}
