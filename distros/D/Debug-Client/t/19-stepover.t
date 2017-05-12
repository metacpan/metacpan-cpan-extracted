#!/usr/bin/perl

use 5.010;
use strict;
use warnings FATAL => 'all';

# Turn on $OUTPUT_AUTOFLUSH
local $| = 1;

use Test::More;
use Test::Deep;
plan( tests => 3 );


#Top
use t::lib::Debugger;

start_script('t/eg/02-sub.pl');
my $debugger;
$debugger = start_debugger();
my $out = $debugger->get;
$out =~ m/(?<=[version])\s*(?<ver>1.\d{2})/m;
my $perl5db_ver = $+{ver};

#Body
$debugger->run(8);

my @out = $debugger->step_over;

SKIP: {
	skip( "perl5db $] dose not support c [line|sub]", 1 ) if $] =~ m/5.01500(3|4|5)/;
	SKIP: {
		skip( "perl5db v$perl5db_ver dose not support list context", 1 ) if $perl5db_ver == 1.35;
		cmp_deeply( \@out, [ 'main::', 't/eg/02-sub.pl', 9, 'my $z = $x + $y;' ], 'stepover line 9' );
	}
}

$debugger->get_lineinfo;
SKIP: {
	skip( "perl5db $] dose not support c [line|sub]", 1 ) if $] =~ m/5.01500(3|4|5)/;
	ok( $debugger->get_row == 9, 'row = 9' );
}

ok( $debugger->get_filename =~ m/02-sub/, 'filename = 02-sub.pl' );



#Tail
$debugger->quit;
done_testing();

1;

__END__
