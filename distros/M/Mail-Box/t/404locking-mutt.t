#!/usr/bin/env perl
#### test run untainted!  Otherwise we will not find a relative
#### mutt_dotlock program.
#
# Test the locking methods.
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Mbox;
use Mail::Box::Locker::Mutt;

use Test::More;

BEGIN {
  eval qq{use POSIX 'sys_wait_h';
          close STDERR;
          system('mutt_dotlock', '-u', '$0');
          die "OK!" if WIFEXITED(\$?);
         };

  if($@ =~ m/OK!/)
  {    plan tests => 7;
  }
  else
  {    plan skip_all => "mutt_dotlock cannot be used";
       exit 0;
  }
}

my $foldername = $0;

my $fakefolder = bless {MB_foldername=> $foldername}, 'Mail::Box::Mbox';
my $lockfile = "$foldername.lock";
unlink $lockfile;

my $locker = Mail::Box::Locker->new
 ( method  => 'MUTT'
 , timeout => 1
 , wait    => 1
 , folder  => $fakefolder
 );

ok($locker);
is($locker->name, 'MUTT', 'locker name');

ok($locker->lock,    'can lock');
ok(-f $lockfile,     'lockfile found');
ok($locker->hasLock, 'locked status');

# Already got lock, so should return immediately.
my $warn = '';
{  $SIG{__WARN__} = sub {$warn = "@_"};
   $locker->lock;
}
ok($warn =~ m/already mutt-locked/, 'second attempt');

$locker->unlock;
ok(! $locker->hasLock, 'released lock');
