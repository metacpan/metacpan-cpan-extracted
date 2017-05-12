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
	sub t1 {
		1;
		2;
	}
	sub t2 {
		t1();
		3;
	}
	t2();
	4;
PERL

is
	n( `$^X $lib -d:DbInteract='s;s;r;r' -e '$script'` )
	,$files->{ 'return' }
	,"Returning from subroutine";

is
	n( `$^X $lib -d:DbInteract='s;r;q' -e '$script'` )
	,$files->{ 'return #2' }
	,"Returning from subroutine. Do not stop at sub calls";

is
	n( `$^X $lib -d:DbInteract='go 2;r;r' -e '$script'` )
	,$files->{ 'return and stop' }
	,'Returning from subroutine. Stop at upper frame';

is
	n( `$^X $lib -d:DbInteract='r;s;q' -e '$script'` )
	,$files->{ 'return from main' }
	,'Return from main:: should finish script';



($script =  <<'PERL') =~ s#^\t##gm;
	sub t0 {
		1;
	}
	sub t1 {
		t0();
		2;
	}
	sub t2 {
		t1();
		3;
	}
	t2();
	4;
PERL

is
	n( `$^X $lib -d:DbInteract='s;s;s;r 1;q' -e '$script'` )
	,$files->{ 'return 1' }
	,'Returning from 1 subroutine';

is
	n( `$^X $lib -d:DbInteract='s;s;s;r 2;q' -e '$script'` )
	,$files->{ 'return 2' }
	,'Returning from 2 subroutines';

is
	n( `$^X $lib -d:DbInteract='s;s;s;r 3;q' -e '$script'` )
	,$files->{ 'return 3' }
	,'Returning from 3 subroutines';

is
	n( `$^X $lib -d:DbInteract='go 2;r 1;q' -e '$script'` )
	,$files->{ 'return 1 and stop' }
	,'Returning from 1 subroutines. Stop at upper frame';

is
	n( `$^X $lib -d:DbInteract='go 2;r 2;q' -e '$script'` )
	,$files->{ 'return 2 and stop' }
	,'Returning from 2 subroutines. Stop at upper frame';

is
	n( `$^X $lib -d:DbInteract='go 2;r 3;q' -e '$script'` )
	,$files->{ 'return 3 and stop' }
	,'Returning from 3 subroutines. Stop at upper frame';

is
	n( `$^X $lib -d:DbInteract='go 2;r 20;q' -e '$script'` )
	,$files->{ 'return all and stop' }
	,'Returning from all subroutines. Stop when no frames left';

is
	n( `$^X $lib -d:DbInteract='go 2;r 0^;q' -e '$script'` )
	,$files->{ 'return all and stop' }
	,'Return to first frame';

is
	n( `$^X $lib -d:DbInteract='go 2;r 1^;q' -e '$script'` )
	,$files->{ 'return to first' }
	,'Return to second frame';

is
	n( `$^X $lib -d:DbInteract='go 2;r 2^;q' -e '$script'` )
	,$files->{ 'return to second' }
	,'Return to second frame';

is
	n( `$^X $lib -d:DbInteract='go 2;r 5^;s;q' -e '$script'` )
	,$files->{ 'return to unexisting' }
	,'Return to unexisting frame do noting';



($script =  <<'PERL') =~ s#^\t##gm;
	sub t0 {
		1;
	}
	sub t1 {
		t0();
		2;
	}
	sub t2 {
		t1();
	}
	t2();
	4;
PERL

is
	n( `$^X $lib -d:DbInteract='go 2;r 2;q' -e '$script'` )
	,$files->{ 'another additional return' }
	,'Return from sub which were last OP. Stop at some upper frame';

# IT: @DB::stack -> 0 2 1 0
# my $cmds =  '@DB::stack;go 2;@DB::stack;r;@DB::stack;r;@DB::stack';



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
	n( `$^X $lib -d:DbInteract='s 2;r;r' -e '$script'` )
	,$files->{ 'stop at chain' }
	,'Stop at next chained sub when returning from the last';

is
	n( `$^X $lib -d:DbInteract='s 2;r 1' -e '$script'` )
	,$files->{ 'return from chain' }
	,'Stop at next OP after chain';



__DATA__
@@ return
-e:0009  t2();
-e:0006    t1();
-e:0002    1;
-e:0007    3;
-e:0010  4;
@@ return #2
-e:0009  t2();
-e:0006    t1();
-e:0010  4;
@@ return and stop
-e:0009  t2();
-e:0002    1;
-e:0007    3;
-e:0010  4;
@@ return from main
-e:0009  t2();
@@ return 1
-e:0012  t2();
-e:0009    t1();
-e:0005    t0();
-e:0002    1;
-e:0006    2;
@@ return 2
-e:0012  t2();
-e:0009    t1();
-e:0005    t0();
-e:0002    1;
-e:0010    3;
@@ return 3
-e:0012  t2();
-e:0009    t1();
-e:0005    t0();
-e:0002    1;
-e:0013  4;
@@ return 1 and stop
-e:0012  t2();
-e:0002    1;
-e:0006    2;
@@ return 2 and stop
-e:0012  t2();
-e:0002    1;
-e:0010    3;
@@ return 3 and stop
-e:0012  t2();
-e:0002    1;
-e:0013  4;
@@ return all and stop
-e:0012  t2();
-e:0002    1;
@@ return to first
-e:0012  t2();
-e:0002    1;
-e:0013  4;
@@ return to second
-e:0012  t2();
-e:0002    1;
-e:0010    3;
@@ return to unexisting
-e:0012  t2();
-e:0002    1;
-e:0006    2;
@@ another additional return
-e:0011  t2();
-e:0002    1;
-e:0012  4;
@@ stop at chain
-e:0013  c4();
-e:0008    c2();
-e:0002    1;
-e:0014  2;
@@ return from chain
-e:0013  c4();
-e:0008    c2();
-e:0014  2;
