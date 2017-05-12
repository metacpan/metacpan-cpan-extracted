#!/usr/bin/env perl


use strict;
use warnings;

use Test::More 'no_plan';
use Test::Output;
use FindBin qw/ $Bin /;  my $lib =  "-I$Bin/lib -I$Bin/../lib";
use Data::Section::Simple qw/ get_data_section /;

use Test::Differences;
unified_diff();
{
	no warnings qw/ redefine prototype /;
	*is =  \&eq_or_diff;
}



sub n {
	$_ =  join '', @_;

	s#\t#  #gm;
	s#(?:[^\s]*?)?([^/]+\.p(?:m|l))#xxx/$1#gm;

	$_;
}



sub nl {
	$_ =  n( @_ );

	s#(xxx/.*?pm:)\d+#$1XXXX#gm;

	$_;
}



my $cmds;
my $script;
my $files =  get_data_section();


($script =  <<'PERL') =~ s#^\t##gm;
	my $x =  { a => 7 };
	for( 1..3 ) {
		$x->{ a }++;                     #DBG:iter e $_ #
	}
	#DBG: e $x; #
PERL

is
	n( `$^X $lib -d:DebugHooks::KillPrint -e '$script'` )
	,$files->{ 'all' }
	,"Run debugger commands for all profiles";

is
	n( `$^X $lib -d:DebugHooks::KillPrint=iter -e '$script'` )
	,$files->{ 'iter' }
	,"Run debugger commands only for 'iter' profile";

is
	n( `$^X $lib -d:DebugHooks::KillPrint=default -e '$script'` )
	,$files->{ 'default' }
	,"Run debugger commands only for 'default' profile";

#TODO: IT for two profiles
#TODO: IT to pass usual arguments


__DATA__
@@ all
1
2
3
{ a => 10 }
@@ iter
1
2
3
@@ default
{ a => 10 }
