#!/usr/bin/perl -w

use Fcntl;
use MLDBM qw(DB_File Storable);
use Data::Dumper;
use strict;
use Test::More;

plan skip_all => "Optional module (DB_File,Storable) not installed"
  unless eval {
               require Storable;
               require DB_File;
              };
plan tests => 9;

tie my %o, 'MLDBM', 'testmldbm', O_CREAT|O_RDWR, 0640 or die $!;

my $c_scalar = 'c';
my $c = [\$c_scalar];
my $b = {};
my $a = [1, $b, $c];
$b->{a} = $a;
$b->{b} = $a->[1];
$b->{c} = $a->[2];
@o{qw(a b c)} = ($a, $b, $c);
$o{d} = "{once upon a time}";
$o{e} = 1024;
$o{f} = 1024.1024;

my $compare_ok = &MLDBM::_compare([ @o{qw(a b c)} ], [ $a, $b, $c ]);
ok($compare_ok);

is($o{d},"{once upon a time}");
is($o{e},1024);
is($o{f},1024.1024);
#print ( ? "ok 2\n" : "# |$o{d}|\nnot ok 2\n");
#print ($o{e} == 1024 ? "ok 3\n" : "# |$o{e}|\nnot ok 3\n");
#print ($o{f} eq 1024.1024 ? "ok 4\n" : "# |$o{f}|\nnot ok 4\n");

# NEW TEST SEQUENCE
untie %o;
my $obj = tie %o, 'MLDBM', 'testmldbm', O_CREAT|O_RDWR, 0640 or die $!;
$obj->DumpMeth('portable');

$c = [\$c_scalar];
$b = {};
$a = [1, $b, $c];
$b->{a} = $a;
$b->{b} = $a->[1];
$b->{c} = $a->[2];
@o{qw(a b c)} = ($a, $b, $c);
$o{d} = "{once upon a time}";
$o{e} = 1024;
$o{f} = 1024.1024;

$compare_ok = &MLDBM::_compare([ @o{qw(a b c)} ], [ $a, $b, $c]);
ok($compare_ok);

is($o{d},"{once upon a time}");
is($o{e},1024);
is($o{f},1024.1024);
#print ($o{d} eq "{once upon a time}" ? "ok 6\n" : "# |$o{d}|\nnot ok 6\n");
#print ($o{e} == 1024 ? "ok 7\n" : "# |$o{e}|\nnot ok 7\n");
#print ($o{f} eq 1024.1024 ? "ok 8\n" : "# |$o{f}|\nnot ok 8\n");

my $d=[17];
$o{g}=$d;
$d='';
is($o{g}->[0],17);
