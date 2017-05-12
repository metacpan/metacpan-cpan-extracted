#!perl 
use File::Glob::Windows qw( glob getCodePage );
use strict;
use warnings;
use utf8;
use Encode;
use Test::More  qw(no_plan);

if( not $^O =~ /Win/ ){
	warn "this test for windows environment.\n";
	ok(1);
	exit;
}

for(qw( getCodePage_A getCodePage_B getCodePage_POSIX )){
	my $cp = eval "File::Glob::Windows::$_();";
	$@ and warn "$@\n";
	ok(1);
}
