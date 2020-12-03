#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'HEAT::Crypto::X25519',
    VERSION_FROM   => 'lib/HEAT/Crypto/X25519.pm',
    AUTHOR         => 'Toma Mazilu',
    LIBS           => [''],
    DEFINE         => '',
    INC            => '-I.',
    OBJECT         => 'X25519.o curve25519_i64.o',
);
