#!/usr/bin/perl -w

use strict;
use Test::More;

use Devel::SizeMe qw(size total_size perl_size heap_size);
use Config;

can_ok ('Devel::SizeMe', qw/
  size
  total_size
  perl_size
  heap_size
/);

die ("Uhoh, test uses an outdated version of Devel::SizeMe")
    unless is ($Devel::SizeMe::VERSION, '0.19', 'VERSION MATCHES');

my $this_perl = $^X;
$this_perl .= $Config{_exe} if $^O ne 'VMS' and $this_perl !~ m/$Config{_exe}$/i;
my @perl_command = ($this_perl);

is system(@perl_command, '-cw', 'bin/sizeme_store.pl'), 0,
    'sizeme_store compiled ok';

done_testing;
