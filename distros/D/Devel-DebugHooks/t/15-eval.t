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
	sub t {
		return ( 1, undef, undef, 2 );
	}
	sub a {
		my @list =  ( 1, undef, undef, 2 );
		return @list;
	}
	1;
PERL

is
	n( `$^X $lib -d:DbInteract='t();q' -e '$script'` )
	,$files->{ 'list' }
	,"Do eval at list context by default";

is
	n( `$^X $lib -d:DbInteract='scalar t();q' -e '$script'` )
	,$files->{ 'scalar for list' }
	,"Force scalar contex for list when eval";

is
	n( `$^X $lib -d:DbInteract='scalar a();q' -e '$script'` )
	,$files->{ 'scalar for array' }
	,"Force scalar contex for array when eval";

is
	n( `$^X $lib -d:DbInteract=' \$DB::options{ undef } =  "undef";t();q' -e '$script'` )
	,$files->{ 'undef' }
	,"Replace 'undef' values at results";

is
	n( `$^X $lib -d:DbInteract=' \$DB::options{ "\\"" } =  "-";t();q' -e '$script'` )
	,$files->{ 'separator' }
	,"Set list separator";

is
	nl( `$^X $lib -d:DbInteract='die "test";q' -e '$script'` )
	,$files->{ 'die' }
	,"Catch error when EXPR evaluation dies";

is
	nl( `$^X $lib -d:DbInteract='2+2;DB::state( "db.last_eval" );q' -e '$script'` )
	,$files->{ 'last eval' }
	,"Remember last evaluated expression";



is
	nl( `$^X $lib -d:DbInteract='2+3;DB::state("file");q' -e '$script'` )
	,$files->{ 'eval expr' }
	,"EXPR evaluation should not chagne debugger state";

TODO: {
	local $TODO =  'Create its own frame for evaluation';
	is
		nl( `$^X $lib -d:DbInteract='t();DB::state("file");q' -e '$script'` )
		,$files->{ 'eval sub' }
		,"Subroutine evaluation should not chagne debugger state";
}



__DATA__
@@ list
-e:0008  1;
1   2
@@ scalar for list
-e:0008  1;
2
@@ scalar for array
-e:0008  1;
4
@@ undef
-e:0008  1;
undef
1 undef undef 2
@@ separator
-e:0008  1;
-
1---2
@@ die
-e:0008  1;
ERROR: test at (eval xxx/DebugHooks.pm:XXXX] line 1.
@@ last eval
-e:0008  1;
4
2+2
@@ eval expr
-e:0008  1;
5
-e
@@ eval sub
-e:0008  1;
1   2
-e
