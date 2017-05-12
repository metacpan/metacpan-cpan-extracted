#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Locale::Maketext::Simple',
    'AUTHOR'        => 'Audrey Tang <cpan AT audreyt DOT org>',
    'VERSION_FROM'  => 'lib/Locale/Maketext/Simple.pm',
    'ABSTRACT_FROM' => 'lib/Locale/Maketext/Simple.pm',
    'LICENSE'       => 'MIT',
    'INSTALLDIRS'   => ($] >= 5.010 ? 'perl' : 'site'),
    ((ExtUtils::MakeMaker->VERSION() lt '6.25')
                              ? ('PL_FILES' => { })    : ()),
    ((ExtUtils::MakeMaker->VERSION() gt '6.30')
                              ? ('LICENSE'  => 'perl') : ()),
    (MM->can('signature_target') ? (SIGN => 1) : ()),

);
