#!/usr/bin/perl -w
use 5.005;
use ExtUtils::MakeMaker;
use strict;

use Config;
(unpack "B*", pack "N", $Config{ptrsize}) =~ /^0+1(0+)$/
    or die "Your pointer size of $Config{ptrsize} is very confusing";
my $ptr_bits = length $1;

WriteMakefile(
	      NAME => 'Devel::Size',
	      VERSION_FROM => 'lib/Devel/Size.pm',
	      DEFINE => "-DALIGN_BITS=$ptr_bits",
	      PREREQ_PM => { 'Test::More' => 0, XSLoader => 0, },
	      (eval $ExtUtils::MakeMaker::VERSION >= 6.47 ? (MIN_PERL_VERSION => '5.005') : ()),
	      (eval $ExtUtils::MakeMaker::VERSION >= 6.31 ? (LICENSE => 'perl') : ()),
);
