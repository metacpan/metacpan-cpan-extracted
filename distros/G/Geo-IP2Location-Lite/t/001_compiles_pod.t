#!perl

use strict;
use warnings;

use Test::More;
use File::Find;

if(($ENV{HARNESS_PERL_SWITCHES} || '') =~ /Devel::Cover/) {
  plan skip_all => 'HARNESS_PERL_SWITCHES =~ /Devel::Cover/';
}
if(!eval 'use Test::Pod; 1') {
  *Test::Pod::pod_file_ok = sub { SKIP: { skip "pod_file_ok(@_) (Test::Pod is required)", 1 } };
}

my @files;

find(
  {
    wanted => sub { /\.pm$/ and push @files, $File::Find::name },
    no_chdir => 1
  },
  -e 'blib' ? 'blib' : 'lib',
);

plan tests => @files * 2;

for my $file (@files) {
  my $module = $file; $module =~ s,\.pm$,,; $module =~ s,.*/?lib/,,; $module =~ s,/,::,g;
  ok eval "use $module; 1", "use $module" or diag $@;
  Test::Pod::pod_file_ok($file);
}
