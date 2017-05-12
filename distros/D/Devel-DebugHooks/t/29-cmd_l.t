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

	s/x0:/ 0:/; #WORKAROUND: old perl shows zero line as breakable

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
		2;
	}

	1;    
	t();
PERL

is
	n( `$^X $lib -d:DbInteract='list.conf;b 2;a 2 1;s 2;l .;q' -e '$script'` )
	,$files->{ 'list' }
	,"List the source code at current position";



($script =  <<'PERL') =~ s#^\t##gm;
	sub t0 {
		1;
	}
	sub t1 {
		t0();
	}
	sub t2 {
		t1();
	}
	t2();






	# Perl implicitly adds one new line after this one
PERL

is
	n( `$^X $lib -d:DbInteract='list.conf;l 0;q' -e '$script'` )
	,$files->{ 'list from first' }
	,"List the source from first line";

is
	n( `$^X $lib -d:DbInteract='list.conf;l 0;l;l;l;q' -e '$script'` )
	,$files->{ 'list next' }
	,"List next winidow of sources";

is
	n( `$^X $lib -d:DbInteract='list.conf2;l 0;l;l;l;q' -e '$script'` )
	,$files->{ 'list next2' }
	,"List next winidow of sources #2";

is
	n( `$^X $lib -d:DbInteract='list.conf;l 8;q' -e '$script'` )
	,$files->{ 'list middle' }
	,"List the source at a middle";

is
	n( `$^X $lib -d:DbInteract='list.conf;l 17;q' -e '$script'` )
	,$files->{ 'list from last' }
	,"List the source from last line";

is
	n( `$^X $lib -d:DbInteract='list.conf;l 5-9;q' -e '$script'` )
	,$files->{ 'list range' }
	,"List range of the source";

is
	n( `$^X $lib -d:DbInteract='list.conf;l 9-5;q' -e '$script'` )
	,$files->{ 'list wrong range' }
	,"Try to list wrong range";

is
	n( `$^X $lib -d:DbInteract='list.conf;l 100;q' -e '$script'` )
	,$files->{ 'list unexisting' }
	,"List not existing line";


is
	n( `$^X $lib -d:DbInteract='list.conf;s 3;l -0;q' -e '$script'` )
	,$files->{ 'list at level 0' }
	,"List source from -0 stack frame";

is
	n( `$^X $lib -d:DbInteract='list.conf;s 3;l -1;q' -e '$script'` )
	,$files->{ 'list at level 1' }
	,"List source from -1 stack frame";

is
	n( `$^X $lib -d:DbInteract='list.conf;s 3;l -2;q' -e '$script'` )
	,$files->{ 'list at level 2' }
	,"List source from -2 stack frame";

is
	n( `$^X $lib -d:DbInteract='list.conf;s 3;l -3;q' -e '$script'` )
	,$files->{ 'list at level 3' }
	,"List source from -3 stack frame";

is
	n( `$^X $lib -d:DbInteract='list.conf;s 3;l -4;q' -e '$script'` )
	,$files->{ 'list unexisting level' }
	,"List source from unexisting stack frame";

is
	n( `$^X $lib -d:DbInteract='list.conf;l t1;q' -e '$script'` )
	,$files->{ 'list by name' }
	,"List subroutine by name";

is
	n( `$^X $lib -d:DbInteract='list.conf;l t7;q' -e '$script'` )
	,$files->{ 'list unexisting by name' }
	,"List unexisting subroutine by name";


is
	n( `$^X $lib -d:DbInteract='list.conf;s 3;l &0;q' -e '$script'` )
	,$files->{ 'deparse at level 0' }
	,"Deparse subroutine at level 0";

is
	n( `$^X $lib -d:DbInteract='list.conf;s 3;l &1;q' -e '$script'` )
	,$files->{ 'deparse at level 1' }
	,"Deparse subroutine at level 1";

is
	n( `$^X $lib -d:DbInteract='list.conf;s 3;l &2;q' -e '$script'` )
	,$files->{ 'deparse at level 2' }
	,"Deparse subroutine at level 2";

is
	n( `$^X $lib -d:DbInteract='list.conf;s 3;l &3;q' -e '$script'` )
	,$files->{ 'deparse unexisting level' }
	,"Deparse subroutine from unexisting level";


#TODO: IT for frame -10. We expect to see '*>'
($script =  <<'PERL') =~ s#^\t##gm;
	my $level = 0;
	sub recursive {
		recursive()   if $level++ < 3;
		1;
	}
	recursive();
PERL

is
	n( `$^X $lib -d:DbInteract='go 4;l .;q' -e '$script'` )
	,$files->{ 'recursive level' }
	,"Display recent frame level for line if sub called recursively";


($script =  <<'PERL') =~ s#^\t##gm;
	my $x = sub { 1+$y };
	my $z;
	1;
PERL

is
	n( `$^X $lib -d:DbInteract='list.conf;s;l \$x;q' -e '$script'` )
	,$files->{ 'deparse by reference' }
	,"Deparse subroutine by reference";

is
	n( `$^X $lib -d:DbInteract='list.conf;s 2;l \$z;q' -e '$script'` )
	,$files->{ 'deparse by broken reference' }
	,"Deparse subroutine by broken reference";



__DATA__
@@ list
-e:0005  1;    
-e:0002    2;
-e
    0: use Devel::DbInteract split(/,/,q{list.conf;b 2;a 2 1;s 2;l .;q});;
    1: sub t {
ab>>2:     2;
    3: }
    4:
   x5: 1;
@@ list from first
-e:0010  t2();
-e
    0: use Devel::DbInteract split(/,/,q{list.conf;l 0;q});;
    1: sub t0 {
   x2:     1;
    3: }
@@ list from last
-e:0010  t2();
-e
    14:
    15:
    16:
    17: # Perl implicitly adds one new line after this one
    18:
@@ list middle
-e:0010  t2();
-e
   x5:     t0();
    6: }
    7: sub t2 {
   x8:     t1();
    9: }
  >>10: t2();
    11:
@@ list range
-e:0010  t2();
-e
   x5:     t0();
    6: }
    7: sub t2 {
   x8:     t1();
    9: }
@@ list wrong range
-e:0010  t2();
-e
@@ list unexisting
-e:0010  t2();
-e
@@ list next
-e:0010  t2();
-e
    0: use Devel::DbInteract split(/,/,q{list.conf;l 0;l;l;l;q});;
    1: sub t0 {
   x2:     1;
    3: }
-e
    4: sub t1 {
   x5:     t0();
    6: }
    7: sub t2 {
   x8:     t1();
    9: }
  >>10: t2();
-e
    11:
    12:
    13:
    14:
    15:
    16:
    17: # Perl implicitly adds one new line after this one
-e
    18:
@@ list next2
-e:0010  t2();
-e
    0: use Devel::DbInteract split(/,/,q{list.conf2;l 0;l;l;l;q});;
    1: sub t0 {
   x2:     1;
-e
    3: }
    4: sub t1 {
   x5:     t0();
    6: }
    7: sub t2 {
   x8:     t1();
-e
    9: }
  >>10: t2();
    11:
    12:
    13:
    14:
-e
    15:
    16:
    17: # Perl implicitly adds one new line after this one
    18:
@@ list at level 0
-e:0010  t2();
-e:0002    1;
-e
    0: use Devel::DbInteract split(/,/,q{list.conf;s 3;l -0;q});;
    1: sub t0 {
  >>2:     1;
    3: }
    4: sub t1 {
  1>5:     t0();
@@ list at level 1
-e:0010  t2();
-e:0002    1;
-e
  >>2:     1;
    3: }
    4: sub t1 {
  1>5:     t0();
    6: }
    7: sub t2 {
  2>8:     t1();
@@ list at level 2
-e:0010  t2();
-e:0002    1;
-e
  1>5:     t0();
    6: }
    7: sub t2 {
  2>8:     t1();
    9: }
  3>10: t2();
    11:
@@ list at level 3
-e:0010  t2();
-e:0002    1;
-e
    7: sub t2 {
  2>8:     t1();
    9: }
  3>10: t2();
    11:
    12:
    13:
@@ list unexisting level
-e:0010  t2();
-e:0002    1;
@@ list by name
-e:0010  t2();
-e
    4: sub t1 {
   x5:     t0();
    6: }
@@ list unexisting by name
-e:0010  t2();
@@ deparse at level 0
-e:0010  t2();
-e:0002    1;
sub main::t0 {
    1;
}
@@ deparse at level 1
-e:0010  t2();
-e:0002    1;
sub main::t1 {
    t0();
}
@@ deparse at level 2
-e:0010  t2();
-e:0002    1;
sub main::t2 {
    t1();
}
@@ deparse unexisting level
-e:0010  t2();
-e:0002    1;
@@ recursive level
-e:0001  my $level = 0;
-e:0004    1;
-e
    0: use Devel::DbInteract split(/,/,q{go 4;l .;q});;
   x1: my $level = 0;
    2: sub recursive {
  1>3:     recursive()   if $level++ < 3;
  >>4:     1;
    5: }
  4>6: recursive();
    7:
@@ deparse by reference
-e:0001  my $x = sub { 1+$y };
-e:0002  my $z;
{
    (1 + $y);
}
@@ deparse by broken reference
-e:0001  my $x = sub { 1+$y };
-e:0003  1;
