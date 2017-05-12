#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use utf8;
use Encode qw/is_utf8/;

sub enc($); *enc=\&Encode::encode_utf8;

sub note; *note=sub {
  print '# '.join('', @_)."\n";
} unless defined &note;

plan tests=>3;
#plan 'no_plan';
#use Data::Dumper; $Data::Dumper::Useqq=1;

{
  package MMapDB::XX;
  use MMapDB;
  our @ISA=('MMapDB');
  our @attributes;
  BEGIN {
    @attributes=(@MMapDB::attributes, qw/filename other/);
    for( my $i=@MMapDB::attributes; $i<@attributes; $i++ ) {
      my $method_num=$i;
      ## no critic
      no strict 'refs';
      *{__PACKAGE__.'::'.$attributes[$method_num]}=
	sub : lvalue {$_[0]->[$method_num]};
      ## use critic
    }
  }
}

my $d=MMapDB::XX->new(filename=>'hugo');

bless $d, 'MMapDB';
isnt $d->filename, 'hugo', 'MMapDB->filename is not hugo';

$d->filename='klaus';

bless $d, 'MMapDB::XX';
is $d->filename, 'hugo', 'MMapDB::XX->filename is hugo';
is $d->MMapDB::filename, 'klaus', 'MMapDB::XX->MMapDB::filename is klaus';
