use strict;
use warnings;
use Config;

unless(-e 'inc/Math-Int64/Makefile.PL')
{
  system 'git', 'submodule', 'init';
  die if $?;
  system 'git', 'submodule', 'update';
  die if $?;
}

system 'git', 'submodule', 'sync';
die if $?;

require Module::CAPIMaker;
require File::Copy;

require Path::Class::Dir;
require Path::Class::File;

my $dst_dir = Path::Class::Dir->new->absolute->subdir('share');
print "dst = $dst_dir\n";

chdir 'inc/Math-Int64';
system $^X, 'Makefile.PL';
die if $?;
system $Config{make}, 'c_api.h';
die if $?;

foreach my $src (map { Path::Class::File->new( 'c_api_client', $_ ) } qw( perl_math_int64.c perl_math_int64.h ))
{
  my $dst = $dst_dir->file($src->basename);
  print "% cp $src $dst\n";
  File::Copy::copy($src, $dst) || die "unable to copy: $!";
}

unlink 'c_api.h';
unlink 'c_api_client/perl_math_int64.c';
unlink 'c_api_client/perl_math_int64.h';
unlink 'c_api_client/sample.xs';

system $Config{make}, 'distclean';
die if $?;
