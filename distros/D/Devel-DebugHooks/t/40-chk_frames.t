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



my $cmds;
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

$cmds =  'e DB::state( "stack" );s;'x3 .'s;e DB::state( "stack" );'x2;
is
	n( `$^X $lib -d:DbInteract='$cmds' -e '$script'` )
	,$files->{ 'subroutine frames' }
	,"Check subroutine frames";

$cmds =  'e DB::state( "goto_frames" );s;'x3 .'s;e DB::state( "goto_frames" );'x2;
is
	n( `$^X $lib -d:DbInteract='$cmds' -e '$script'` )
	,$files->{ 'goto frames' }
	,"Check goto frames";



($script =  <<'PERL') =~ s#^\t##gm;
	sub t1 {
		1;
	}
	sub t2 {
		goto &t1;
	}
	t2();
	4;
PERL

$cmds =  'e DB::state( "stack" );s;'x4;
is
	n( `$^X $lib -d:DbInteract='$cmds' -e '$script'` )
	,$files->{ 'subroutine frames with goto' }
	,"Check subroutine frames with goto";

$cmds =  'e DB::state( "goto_frames" );s;'x4;
is
	n( `$^X $lib -d:DbInteract='$cmds' -e '$script'` )
	,$files->{ 'goto frames with goto' }
	,"Check goto frames with goto";



($script =  <<'PERL') =~ s#^\t##gm;
	sub t0 {
		1;
	}
	sub t1 {
		goto &t0;
	}
	sub t2 {
		goto &t2 if $x++ < 2;
		t1();
		2;
	}
	t2();
	3;
PERL

$cmds =  'e DB::state( "stack" );s;'x3 .'s;e DB::state( "stack" );'x5;
is
	n( `$^X $lib -d:DbInteract='$cmds' -e '$script'` )
	,$files->{ 'subroutine frames with nested goto' }
	,"Check subroutine frames with nested goto";

$cmds =  'e DB::state( "goto_frames" );s;'x3 .'s;e DB::state( "goto_frames" );'x5;
is
	n( `$^X $lib -d:DbInteract='$cmds' -e '$script'` )
	,$files->{ 'goto frames with nested goto' }
	,"Check goto frames with nested goto";

$cmds =  's 6;e DB::state( "goto_frames" );q';
is
	n( `$^X $lib -d:DbInteract='$cmds' -e '$script'` )
	,$files->{ 'trace file:line' }
	,"package:file:line should be updated as often as possible";

# When we run script in NonStop mode the $DB::package/file/line are not updated
# because of &DB::DB is not called. If we update them at &DB::sub the GOTO
# frames will get more accurate info about that from which place the GOTO was
# called. To be 100% accurate we may enable $DB::trace

# TODO: it will be good if perl in -d mode will supply for &DB::goto info
# about file:line where goto is occured like $DB::sub is supplyed for &DB::sub
$cmds =  'go 2;e DB::state( "goto_frames" );q';
is
	n( `$^X $lib -d:DbInteract='$cmds' -e '$script'` )
	,$files->{ 'trace file:line #2' }
	,"package:file:line should be updated as often as possible. #2";



__DATA__
@@ subroutine frames
-e:0009  t2();
[
  { file => "-e", goto_frames => [], line => 9, package => "main", single => 1 },
]
-e:0006    t1();
[
  { file => "-e", goto_frames => [], line => 9, package => "main", single => 1 },
  {
    file => "-e",
    goto_frames => [],
    line => 6,
    package => "main",
    single => 1,
    sub => "main::t2",
    type => "C",
  },
]
-e:0002    1;
[
  { file => "-e", goto_frames => [], line => 9, package => "main", single => 1 },
  {
    file => "-e",
    goto_frames => [],
    line => 6,
    package => "main",
    single => 1,
    sub => "main::t2",
    type => "C",
  },
  {
    file => "-e",
    goto_frames => [],
    line => 2,
    package => "main",
    single => 1,
    sub => "main::t1",
    type => "C",
  },
]
-e:0003    2;
-e:0007    3;
[
  { file => "-e", goto_frames => [], line => 9, package => "main", single => 1 },
  {
    file => "-e",
    goto_frames => [],
    line => 7,
    package => "main",
    single => 1,
    sub => "main::t2",
    type => "C",
  },
]
-e:0010  4;
[
  { file => "-e", goto_frames => [], line => 10, package => "main", single => 1 },
]
@@ goto frames
-e:0009  t2();
[]
-e:0006    t1();
[]
-e:0002    1;
[]
-e:0003    2;
-e:0007    3;
[]
-e:0010  4;
[]
@@ subroutine frames with goto
-e:0007  t2();
[
  { file => "-e", goto_frames => [], line => 7, package => "main", single => 1 },
]
-e:0005    goto &t1;
[
  { file => "-e", goto_frames => [], line => 7, package => "main", single => 1 },
  {
    file => "-e",
    goto_frames => [],
    line => 5,
    package => "main",
    single => 1,
    sub => "main::t2",
    type => "C",
  },
]
-e:0002    1;
[
  { file => "-e", goto_frames => [], line => 7, package => "main", single => 1 },
  {
    file => "-e",
    goto_frames => [["main", "-e", 5, "main::t1", "G"]],
    line => 2,
    package => "main",
    single => 1,
    sub => "main::t2",
    type => "C",
  },
]
-e:0008  4;
[
  { file => "-e", goto_frames => [], line => 8, package => "main", single => 1 },
]
@@ goto frames with goto
-e:0007  t2();
[]
-e:0005    goto &t1;
[]
-e:0002    1;
[["main", "-e", 5, "main::t1", "G"]]
-e:0008  4;
[]
@@ subroutine frames with nested goto
-e:0012  t2();
[
  { file => "-e", goto_frames => [], line => 12, package => "main", single => 1 },
]
-e:0008    goto &t2 if $x++ < 2;
[
  { file => "-e", goto_frames => [], line => 12, package => "main", single => 1 },
  {
    file => "-e",
    goto_frames => [],
    line => 8,
    package => "main",
    single => 1,
    sub => "main::t2",
    type => "C",
  },
]
-e:0008    goto &t2 if $x++ < 2;
[
  { file => "-e", goto_frames => [], line => 12, package => "main", single => 1 },
  {
    file => "-e",
    goto_frames => [["main", "-e", 8, "main::t2", "G"]],
    line => 8,
    package => "main",
    single => 1,
    sub => "main::t2",
    type => "C",
  },
]
-e:0008    goto &t2 if $x++ < 2;
-e:0009    t1();
[
  { file => "-e", goto_frames => [], line => 12, package => "main", single => 1 },
  {
    file => "-e",
    goto_frames => [
      ["main", "-e", 8, "main::t2", "G"],
      ["main", "-e", 8, "main::t2", "G"],
    ],
    line => 9,
    package => "main",
    single => 1,
    sub => "main::t2",
    type => "C",
  },
]
-e:0005    goto &t0;
[
  { file => "-e", goto_frames => [], line => 12, package => "main", single => 1 },
  {
    file => "-e",
    goto_frames => [
      ["main", "-e", 8, "main::t2", "G"],
      ["main", "-e", 8, "main::t2", "G"],
    ],
    line => 9,
    package => "main",
    single => 1,
    sub => "main::t2",
    type => "C",
  },
  {
    file => "-e",
    goto_frames => [],
    line => 5,
    package => "main",
    single => 1,
    sub => "main::t1",
    type => "C",
  },
]
-e:0002    1;
[
  { file => "-e", goto_frames => [], line => 12, package => "main", single => 1 },
  {
    file => "-e",
    goto_frames => [
      ["main", "-e", 8, "main::t2", "G"],
      ["main", "-e", 8, "main::t2", "G"],
    ],
    line => 9,
    package => "main",
    single => 1,
    sub => "main::t2",
    type => "C",
  },
  {
    file => "-e",
    goto_frames => [["main", "-e", 5, "main::t0", "G"]],
    line => 2,
    package => "main",
    single => 1,
    sub => "main::t1",
    type => "C",
  },
]
-e:0010    2;
[
  { file => "-e", goto_frames => [], line => 12, package => "main", single => 1 },
  {
    file => "-e",
    goto_frames => [
      ["main", "-e", 8, "main::t2", "G"],
      ["main", "-e", 8, "main::t2", "G"],
    ],
    line => 10,
    package => "main",
    single => 1,
    sub => "main::t2",
    type => "C",
  },
]
-e:0013  3;
[
  { file => "-e", goto_frames => [], line => 13, package => "main", single => 1 },
]
@@ goto frames with nested goto
-e:0012  t2();
[]
-e:0008    goto &t2 if $x++ < 2;
[]
-e:0008    goto &t2 if $x++ < 2;
[["main", "-e", 8, "main::t2", "G"]]
-e:0008    goto &t2 if $x++ < 2;
-e:0009    t1();
[
  ["main", "-e", 8, "main::t2", "G"],
  ["main", "-e", 8, "main::t2", "G"],
]
-e:0005    goto &t0;
[]
-e:0002    1;
[["main", "-e", 5, "main::t0", "G"]]
-e:0010    2;
[
  ["main", "-e", 8, "main::t2", "G"],
  ["main", "-e", 8, "main::t2", "G"],
]
-e:0013  3;
[]
@@ trace file:line
-e:0012  t2();
-e:0002    1;
[["main", "-e", 5, "main::t0", "G"]]
@@ trace file:line #2
-e:0012  t2();
-e:0002    1;
[["main", "-e", 9, "main::t0", "G"]]
