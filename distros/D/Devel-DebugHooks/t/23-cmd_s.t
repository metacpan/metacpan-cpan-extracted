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
	n( `$^X $lib -d:DbInteract='s;q' -e '$script'` )
	,$files->{ 'sbs' }
	,"Step-by-step debugging. Step into";

is
	n( `$^X $lib -d:DbInteract='s 1;q' -e '$script'` )
	,$files->{ 'sbs' }
	,"'s 1' and 's' should do same";



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
	n( `$^X $lib -d:DbInteract='s;s;q' -e '$script'` )
	,$files->{ 'step into sub' }
	,"Step into sub";

is
	n( `$^X $lib -d:DbInteract='go 2;s;q' -e '$script'` )
	,$files->{ 'step from sub' }
	,"Step from sub";

is
	n( `$^X $lib -d:DbInteract='s 4;q' -e '$script'` )
	,$files->{ 'do n steps' }
	,"Do N steps at once";

#IT: do not skip actions when `s N`


$script =~  s/t1\(\)/goto &t1/;
is
	n( `$^X $lib -d:DbInteract='s;s;q' -e '$script'` )
	,$files->{ 'step into goto' }
	,"Step into goto";



($script =  <<'PERL') =~ s#^\t##gm;
	sub t1 {
		1;
	}
	sub t2 {
		t1();
	}
	t2();
	3;
PERL

is
	n( `$^X $lib -d:DbInteract='go 2;s;q' -e '$script'` )
	,$files->{ 'double step from sub' }
	,"Double step from sub";



($script =  <<'PERL') =~ s#^\t##gm;
	sub c3 {
		1;
	}
	sub c2 {
		\&c3;
	}
	sub c1 {
		c2();
	}
	sub c4 {
		c1->();
	}
	c4();
	2;
PERL

is
	n( `$^X $lib -d:DbInteract='s 2;s;s;s' -e '$script'` )
	,$files->{ 'chained steps' }
	,"Steps through chained call";



__DATA__
@@ sbs
-e:0001  1;
-e:0002  2;
@@ step into sub
-e:0008  t2();
-e:0005    t1();
-e:0002    1;
@@ step from sub
-e:0008  t2();
-e:0002    1;
-e:0006    2;
@@ do n steps
-e:0008  t2();
-e:0009  3;
@@ step into goto
-e:0008  t2();
-e:0005    goto &t1;
-e:0002    1;
@@ double step from sub
-e:0007  t2();
-e:0002    1;
-e:0008  3;
@@ chained steps
-e:0013  c4();
-e:0008    c2();
-e:0005    \&c3;
-e:0002    1;
-e:0014  2;
