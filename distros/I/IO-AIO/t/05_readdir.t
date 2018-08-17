#!/usr/bin/perl

use Test;
use IO::AIO;

# this is a lame test, but....

BEGIN { plan tests => 12 }

my %f;
ok ((opendir my $dir, "."), 1, "$!");
$f{$_}++ for readdir $dir;

my %x = %f;

aio_readdir ".", sub {
   delete $x{"."};
   delete $x{".."};
   if ($_[0]) {
      ok (1);
      my $ok = 1;
      $ok &&= delete $x{$_} for @{$_[0]};
      ok ($ok);
      ok (!scalar keys %x);
   } else {
      ok (0,1,"$!");
   }
};

IO::AIO::poll;

%x = %f;

aio_scandir ".", 0, sub {
   delete $x{"."};
   delete $x{".."};
   if (@_) {
      ok (1);
      my $ok = 1;
      $ok &&= delete $x{$_} for (@{$_[0]}, @{$_[1]});
      ok ($ok);
      ok (!keys %x);
   } else {
      ok (0,1,"$!");
   }
};

IO::AIO::poll while IO::AIO::nreqs;

my $entries1;

aio_readdirx ".", IO::AIO::READDIR_STAT_ORDER, sub {
   $entries1 = shift;
   ok (! ! $entries1);
};

IO::AIO::poll while IO::AIO::nreqs;

aio_readdirx ".", IO::AIO::READDIR_STAT_ORDER | IO::AIO::READDIR_DENTS, sub {
   my $entries2 = shift;
   ok (! ! $entries2);

   ok (!grep $entries2->[$_ - 1][2] > $entries2->[$_][2], 1 .. $#$entries2);

   if ($^O eq "cygwin") {
      # sigh...
      $entries1 = [ sort                         @$entries1 ];
      $entries2 = [ sort { $a->[0] cmp $b->[0] } @$entries2 ];
   }

   ok ((join "\x00", @$entries1) eq (join "\x00", map $_->[0], @$entries2));
};

IO::AIO::poll while IO::AIO::nreqs;

ok (1);

