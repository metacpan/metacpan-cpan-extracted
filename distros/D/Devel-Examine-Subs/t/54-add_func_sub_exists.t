#!/usr/bin/perl
use warnings;
use strict;

use Data::Dumper;
use Devel::Examine::Subs;
use File::Copy;
use Test::More tests => 2;

my $file = 't/sample.data';
my $copy = 't/add_func_engine.data';

my %params = (
    file            => $file,
    copy            => $copy,
);

#<des>
sub _test {
    return 1;
}
#</des>

my $install = 1; # set this to true to install

my $des = Devel::Examine::Subs->new(file => $file, copy => $copy);

if ($install) {

    eval { $des->add_functionality(add_functionality => 'engine'); 1; }
      or ok (1 == 1, "if the sub being added already exists, we croak");
}

eval { unlink $copy or die $!; };
is ($@, '', "temp file unlinked ok");
