package Test::Fuse::PDF;

use warnings;
use strict;
use base 'Test::Class';
use Test::More;

use Fuse::PDF;

sub startup : Test(startup) {
   my ($self) = @_;
   return;
}

sub shutdown : Test(shutdown) {
   my ($self) = @_;
   return;
}

sub foo : Test(1) {
   my ($self) = @_;

   is(1, 1, 'foo');

   return;
}


1;
