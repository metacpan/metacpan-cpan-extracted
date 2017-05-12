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
	s#(?:.*?)?([^/]+\.p(?:m|l))#xxx/$1#gm;

	$_;
}



my $script;
my $files =  get_data_section();


($script =  <<'PERL') =~ s#^\t##gm;
	1;
	2;
	3;
PERL

is
	n( `$^X $lib -d:DbInteract='go' -e '$script'` )
	,$files->{ go }
	,"Run script until the end";

is
	n( `$^X $lib -d:DbInteract='go 3' -e '$script'` )
	,$files->{ 'go to line' }
	,"Run script to the line";



($script =  <<'PERL') =~ s#^\t##gm;
	sub t1 {
		1;
	}
	sub t2 {
		t1();
		2;
	}
	t2();
	3;
PERL

is
	n( `$^X $lib -d:DbInteract='go t2;q' -e '$script'` )
	,$files->{ 'go to sub' }
	,"Run script to the sub";

is
	n( `$^X $lib -d:DbInteract='go 2;go' -e '$script'` )
	,$files->{ 'go from sub' }
	,"Run script from sub until the end";

is
	n( `$^X $lib -d:DbInteract='s;s;go' -e '$script'` )
	,$files->{ 'go from sub #2' }
	,"Run script from sub until the end. #2";



__DATA__
@@ go
-e:0001  1;
@@ go to line
-e:0001  1;
-e:0003  3;
@@ go to sub
-e:0008  t2();
-e:0005    t1();
@@ go from sub
-e:0008  t2();
-e:0002    1;
@@ go from sub #2
-e:0008  t2();
-e:0005    t1();
-e:0002    1;
