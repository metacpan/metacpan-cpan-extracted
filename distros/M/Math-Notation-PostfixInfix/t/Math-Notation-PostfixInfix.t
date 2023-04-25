#!/usr/bin/perl
#
## Copyright (c) 2022 - by Carlos Celso
#

use strict;
use warnings;

use Test::More tests => 21;

our $VERSION = "2023.111.1";

BEGIN { use_ok('Math::Notation::PostfixInfix') };

my $ix=0;
while (my $data = <DATA>)
{
	$data =~ s/[\n\r]//g;
	&test($1,$2,$3) if ($data =~ /^<(.*)><(.*)><(.*)>/);
}
close(DATA);
done_testing();
exit(0);

sub test()
{
	$ix++;
	my $s = shift;
	my $p = shift;
	my $o = shift;

	$o = $s if ($o eq "");

	my @_p = Math::Notation::PostfixInfix->Infix_to_Postfix($s);
	my $_s = Math::Notation::PostfixInfix->Postfix_to_Infix(\@_p);

	ok($o eq $_s,"line$ix - p2i in=".$o." out=".$_s);
	ok($p eq join(",",@_p),"line$ix - i2p in=".$p." out=".join(",",@_p));
}

__DATA__
<aaaa and bbbb><aaaa,bbbb,&><>
<aaaa or bbbb><aaaa,bbbb,|><>
<aaaa && bbbb><aaaa,bbbb,&><aaaa and bbbb>
<aaaa || bbbb><aaaa,bbbb,|><aaaa or bbbb>
<aaaa and bbbb or cccc><aaaa,bbbb,&,cccc,|><>
<aaaa or bbbb and cccc><aaaa,bbbb,cccc,&,|><>
<aaaa and bbbb or cccc and dddd><aaaa,bbbb,&,cccc,dddd,&,|><>
<aaaa and (bbbb or cccc) and dddd><aaaa,bbbb,cccc,|,&,dddd,&><>
<aaaa bbbb and cccc dddd><aaaa bbbb,cccc dddd,&><>
<aaaa bbbb or cccc dddd><aaaa bbbb,cccc dddd,|><>
<aaaa and (bbbb or cccc or (dddd and eeee or ffff and gggg))><>
