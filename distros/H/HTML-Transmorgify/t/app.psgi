#!/usr/bin/perl -I.

use strict;
use warnings;
use Plack::Builder;
use Data::Dumper;
use HTML::Transmorgify;
use HTML::Transmorgify::FormChecksum;

my $app = sub {
	my $env = shift;
	if ($env->{QUERY_STRING}) {
		my $x = "\n$env->{QUERY_STRING}\n\n";
		$x =~ s/&/\n/g;
		return [ 200, [ 'Content-Type' => 'text/plain' ], [ $x . Dumper($env) ] ];
	} else {
		my $magic = HTML::Transmorgify->new(xml_quoting => 1);
		$magic->mixin('HTML::Transmorgify::FormChecksum');
		my $i = '';
		while (<DATA>) {
			$i .= $_;
		}
		print STDERR "i=$i\n";
		my $res = $magic->process($i, input_file => $0, input_line => dln());
		print STDERR "RES=$res\n";
		return [ 200, [ 'Content-Type' => 'text/html' ], [  $res ] ];
	}
};

builder {
	$app;
};

sub dln { __LINE__+2 };
__DATA__
<html>
<body>
<form method=GET url="http://127.0.0.1:5000">
<input type=hidden id=cban1 value=hban1>
<input type=hidden id=h1 value=h1v>
<input type=hidden id=hnoval>
<input type=checkbox name=cban1 value=cb1a> cban1
<input type=checkbox name=cb1n2 value=cb1b> cb1n
<input type=checkbox name=cb0> cb0
<input type=radio name=r0> r0
<input type=text name=t0 value=t0> t0
<input type=text name=t0 value=t0too> t0too
<input type=text name=t0 > t0three
<input type=text name=t1 > t1
<input type=submit id=foobar value=uxy>
</form>
</body>
</html>

