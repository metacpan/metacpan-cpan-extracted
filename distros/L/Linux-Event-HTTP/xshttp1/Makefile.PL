use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Linux::Event::HTTP::_HTTP1',
    VERSION_FROM     => '../lib/Linux/Event/HTTP.pm',
    ABSTRACT         => 'Private native HTTP/1 wire primitives for Linux::Event::HTTP',
    AUTHOR           => 'Joshua S. Day <hax@cpan.org>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.036000',
    PM               => {},
    XS               => { 'HTTP1.xs' => 'HTTP1.c' },
    OBJECT           => 'HTTP1$(OBJ_EXT)',
    clean            => { FILES => 'HTTP1.c' },
);
