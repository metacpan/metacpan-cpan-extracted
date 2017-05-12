#!/usr/bin/perl
use strict;
use warnings;

use Logging::Simple;
use Test::More;

my $mod = 'Logging::Simple';

{ # verify only levels run
   my $log = $mod->new(print => 0);

   my %calls;

   for (0 .. 7) {
      my $sub = "_$_";
      my $msg = $log->$sub("blah");
      $calls{$_} = 1 if defined $msg;
   }

   is (keys %calls, 5, "default lvl 4, proper count of subs run");

   for (0..4){
      is (defined $calls{$_}, 1, "$_ sub ran with default level");
   }

   for (5..7){
      is ($calls{$_}, undef, "$_ sub wasn't called at default level");
   }
}
{ # different run level in constructor
   my $log = $mod->new(print => 0, level => 2);

   my %calls;

   for (0 .. 7) {
      my $sub = "_$_";
      my $msg = $log->$sub("blah");
      $calls{$_} = 1 if defined $msg;
   }

   is (keys %calls, 3, "lvl 2, proper count of subs run");

   for (0..2){
      is (defined $calls{$_}, 1, "$_ sub ran with level 2");
   }

   for (3..7){
      is ($calls{$_}, undef, "$_ sub wasn't called at level 2");
   }
}
{ # different run level in level()
   my $log = $mod->new(print => 0);

   $log->level(6);

   my %calls;

   for (0 .. 7) {
      my $sub = "_$_";
      my $msg = $log->$sub("blah");
      $calls{$_} = 1 if defined $msg;
   }

   is (keys %calls, 7, "lvl 6, proper count of subs run with level()");

   for (0..6){
      is (defined $calls{$_}, 1, "$_ sub ran with level 6 with level()");
   }

   for (7){
      is ($calls{$_}, undef, "$_ sub wasn't called at level 6 with level()");
   }
}
{ # child

   my $plog = $mod->new(print => 0);

   $plog->level(6);

   my $log = $plog->child('child');

   my %calls;

   for (0 .. 7) {
      my $sub = "_$_";
      my $msg = $log->$sub("blah");
      $calls{$_} = 1 if defined $msg;
   }

   is (keys %calls, 7, "lvl 6, proper count of subs run with level()");

   for (0..6){
      is (defined $calls{$_}, 1, "$_ sub ran with level 6 with level()");
   }

   for (7){
      is ($calls{$_}, undef, "$_ sub wasn't called at level 6 with level()");
   }
}

done_testing();

