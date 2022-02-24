#!/usr/bin/env perl

use strict;
use warnings;
use Test::Moose;
use Test::More;
use Test::Warn;
use Test::Dir;
use Path::Tiny;
use Test::Fatal qw(lives_ok);
use HackaMol;                # v0.001;#To test for version availability
use Cwd;

my $cwd = getcwd;

my @attributes = qw(
data
scratch
homedir
dirs
);
my @methods = qw(
);

map has_attribute_ok( 'HackaMol', $_ ), @attributes;
map can_ok( 'HackaMol', $_ ), @methods;
my $obj;
lives_ok {
    $obj = HackaMol->new();
}
'Test creation of an obj with nothing';

lives_ok {
    $obj = HackaMol->new(homedir=>"t", 
                        scratch => path("t/tmp"), #add path cmd for windows... 
                        data=> path("t/lib"),
                        dirs => [qw/lib examples/ ]);
}
'Test creation of an obj with directories';

is($obj->scratch, "$cwd/t/tmp", "abspath scratch set ok");
is($obj->data   , "$cwd/t/lib", "abspath data    set ok");
is($obj->homedir, "$cwd/t",     "abspath homedir set ok");
dir_exists_ok($obj->data,        'data directory exists');
dir_exists_ok($obj->homedir,     'homedir directory exists');
dir_not_exists_ok($obj->scratch, 'scratch directory does not exist');
$obj->scratch->mkpath;
dir_exists_ok($obj->scratch, 'scratch directory does exist after mkpath');
$obj->scratch->remove_tree;
dir_not_exists_ok($obj->scratch, 'scratch directory deleted!');
$obj->scratch->mkpath;
dir_exists_ok($obj->scratch, 'scratch directory recreated');
my @storeit;
foreach (0 .. 2){
  my $fh = $obj->scratch->tempfile("customXXXXXXX")->filehandle("+<");
  print $fh $_ ;
  seek($fh, 0,0);
  while (my $line = <$fh>){
    is ($line, $_, "tempfile print/read")
  }
}


is (scalar($obj->scratch->children), 0,     "tempfiles were destroyed");

$obj->scratch->remove_tree;
dir_not_exists_ok($obj->scratch, 'scratch directory deleted!');

done_testing();


