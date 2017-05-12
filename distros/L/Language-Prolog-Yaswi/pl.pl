#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
    require Language::Prolog::Yaswi::Low;
    @Language::Prolog::Yaswi::Low::args =
	($Language::Prolog::Yaswi::Low::args[0],
	 @ARGV)
}

use Language::Prolog::Yaswi ':query';

$Language::Prolog::Yaswi::swi_converter->pass_as_opaque('UNIVERSAL');

Language::Prolog::Yaswi::swi_toplevel;




=head1 NAME

pl.pl - wrapper to call SWI-Prolog with perl embeded

=head1 SYNOPSIS

  $ pl.pl -q


=head1 ABSTRACT

Wrapper to run SWI-Prolog with support for calling perl


=head1 DESCRIPTION

Use this script in the same way that the pl executable from the SWI-Prolog
distribution.

Predicates perl5_call/3, perl5_eval/2 and perl5_method/4 will be
available from prolog.

=cut
