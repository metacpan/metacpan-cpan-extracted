#!/usr/bin/perl

use 5.010;
use strict;
use warnings FATAL => 'all';

# Turn on $OUTPUT_AUTOFLUSH
local $| = 1;

use Test::More;
use Test::Deep;
plan( tests => 4 );


#Top
use t::lib::Debugger;

start_script('t/eg/02-sub.pl');
my $debugger;
$debugger = start_debugger();
my $out = $debugger->get;
$out =~ m/(?<=[version])\s*(?<ver>1.\d{2})/m;
my $perl5db_ver = $+{ver};

#Body
$out = $debugger->step_in;
like( $out, qr{sub.pl:6}, 'step to line 6' );

my @out = $debugger->step_in;

SKIP: {
	skip( "perl5db v$perl5db_ver dose not support list context", 1 ) unless $perl5db_ver < 1.35;
	cmp_deeply( \@out, [ 'main::', 't/eg/02-sub.pl', 7, 'my $y = 22;' ], 'step to line 7' );
}

ok( $debugger->get_row == 7, 'row = 7' );
ok( $debugger->get_filename =~ m/02-sub/, 'filename = 02-sub.pl' );


#Tail
$debugger->quit;
done_testing();

1;

__END__
