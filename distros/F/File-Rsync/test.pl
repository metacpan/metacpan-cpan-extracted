#!/usr/local/bin/perl -w

END { print("not ok 1\n"), exit 1 unless $loaded }

use File::Rsync;
use File::Path 'rmtree';
use Test::More;
use strict;
use vars qw($loaded $fail);
$loaded = 1;
note "NOTE: expect 'badoption' message for test 7";
note "NOTE: expect 'deprecated' message for test 8";
ok($loaded, 'module loaded');

ok(whence('rsync'), 'rsync executable found');

rmtree('destdir');
# simple exec
{
   my $rs = File::Rsync->new(
      archive => 1,
      src     => 'blib',
      dest    => 'destdir'
   );
   my $ret;
   if ($rs) {
      my $cmd = $rs->getcmd;
      diag "Running [@$cmd]";
      $ret = $rs->exec;
   }
   ok($rs && $ret == 1 && $rs->status == 0 && !$rs->err, 'simple exec');

}

rmtree('destdir');
# exec with args
{
   my $rs = File::Rsync->new(archive => 1);
   my $ret;
   if ($rs) {
      my $cmd = $rs->getcmd(src => 'blib', dest => 'destdir');
      diag "Running [@$cmd]";
      $ret = $rs->exec(src => 'blib', dest => 'destdir');
   }
   ok($rs && $ret == 1 && $rs->status == 0 && !$rs->err, 'exec with args');
}

rmtree('destdir');
# non-existant source
{
   my $rs = File::Rsync->new(archive => 1);
   my $ret;
   if ($rs) {
      my $cmd = $rs->getcmd(
         src  => 'some-non-existant-path-name',
         dest => 'destdir'
      );
      diag "Running [@$cmd]";
      $ret
         = $rs->exec(src => 'some-non-existant-path-name', dest => 'destdir');
   }
   ok($rs
         && @{$rs->err} >= 1
         && $rs->err->[0] =~ /\bNo such file or directory\b/i,
      'non-existant source'
   );
}

rmtree('destdir');
# non-existant destination
{
   my $rs = File::Rsync->new(archive => 1);
   my $ret;
   if ($rs) {
      my $cmd = $rs->getcmd(src => 'blib', dest => 'destdir/subdir');
      diag "Running [@$cmd]";
      $ret = $rs->exec(src => 'blib', dest => 'destdir/subdir');
   }
   ok($rs
         && $ret == 0
         && $rs->status != 0
         && @{$rs->err} > 0
         && ${$rs->err}[0] =~ /\bNo such file or directory\b/i,
      'non-existant destination'
   );
}

rmtree('destdir');
# invalid option
{
   my $rs = File::Rsync->new(archive => 1, badoption => 1);
   ok(!defined($rs), 'invalid option');
}

# deprecated hash ref
{
   local $^W = 1;    # belt and suspenders (-w on #! too)
   my $rs
      = File::Rsync->new({archive => 1, src => 'blib', dest => 'destdir'});
   ok($rs, 'deprecated hash ref');
}

# mixed hash ref and non
{
   my $ok;
   my $rs = File::Rsync->new({archive => 1});
   if ($rs) {
      my $cmd = $rs->getcmd(src => 'blib', dest => 'destdir');
      diag "checking [@$cmd]";
      $ok = "@$cmd" eq 'rsync --archive blib destdir';
   }
   ok($rs && $ok, 'mixed hash ref and non');
}

SKIP: {
   skip "old rsync, no --files-from option", 2
      unless have_files_from('rsync');
   my @files = qw(lib/File/Rsync.pm);

   rmtree('destdir');
   # files-from array ref
   {
      my $rs = File::Rsync->new(
         archive    => 1,
         files_from => \@files,
      );
      my $ok;
      my $missing;
      if ($rs) {
         my $cmd = $rs->getcmd(src => 'blib', dest => 'destdir');
         diag "Running [@$cmd]";
         $ok = $rs->exec(src => 'blib', dest => 'destdir');
         if (not $ok) {
            diag "Ret: $ok";
            diag "Return \$?: $rs->{realstatus}";
            diag "Return exit code: $rs->{status}";
            if ($rs->err) {
               diag $_ for @{$rs->err};
            }
         } else {
            for my $entry (@files) {
               if (!$missing and !-f "destdir/$entry") {
                  diag "Target file 'destdir/$entry' not found";
                  $missing++;
               }
            }
         }
      }
      ok($rs && $ok && !$missing, 'files-from array ref');
   }

   rmtree('destdir');
   # files-from infun
   my @copy_list = @files;
   my $rs        = File::Rsync->new(
      archive    => 1,
      files_from => '-',
      infun      => sub { print join "\n", @copy_list },
   );
   my $ok;
   my $missing;
   if ($rs) {
      my $cmd = $rs->getcmd(src => 'blib', dest => 'destdir');
      diag "Running [@$cmd]";
      $ok = $rs->exec(src => 'blib', dest => 'destdir');
      if (not $ok) {
         diag "Ret: $ok";
         diag "Return \$?: $rs->{realstatus}";
         diag "Return exit code: $rs->{status}";
         if ($rs->err) {
            diag $_ for @{$rs->err};
         }
      } else {
         for my $entry (@files) {
            if (!$missing and !-f "destdir/$entry") {
               diag "Target file 'destdir/$entry' not found";
               $missing++;
            }
         }
      }
   }
   ok($rs && $ok && !$missing, 'files-from infun');
}
rmtree('destdir');

# arg order tests
{
   my $ok;
   my $rs = File::Rsync->new(
      archive         => 1,
      itemize_changes => 1,
      omit_dir_times  => 1,
      src             => 'blib',
      dest            => 'destdir'
   );
   if ($rs) {
      my $cmd = $rs->getcmd;
      diag "Checking [@$cmd]";
      $ok = "@$cmd" eq
         'rsync --archive --itemize-changes --omit-dir-times blib destdir';
   }
   ok($rs && $ok, 'ordered args');

}

# arg order tests
{
   my $ok;
   my $rs = File::Rsync->new(
      archive         => 1,
      omit_dir_times  => 1,
      itemize_changes => 1,
      no_perms        => 1,
      exclude         => ['.*.swp'],
      filter          => [':- .gitignore'],
      'delete'        => 1,
      src             => 'blib',
      dest            => 'destdir'
   );
   if ($rs) {
      my $cmd = $rs->getcmd;
      diag "Checking [@$cmd]";
      $ok = "@$cmd" eq
         'rsync --archive --omit-dir-times --itemize-changes --no-perms --exclude=.*.swp --filter=:- .gitignore --delete blib destdir';
   }
   ok($rs && $ok, 'more ordered args');

}


rmtree('destdir');    # one last time to be sure
done_testing();

sub whence {
   my $cmd = shift;
   qx($cmd --version);    # throw away output
   return if $?;
   return $cmd;
}

sub have_files_from {
   my $cmd           = shift;
   my $rsync_version = `$cmd --version`;
   # We only care about major.minor, not the exact release here:
   $rsync_version =~ /version\s+(\d+\.\d+)\.\d+\s+/
      or return;
   $rsync_version = $1;

   return $rsync_version > 2.6;
}
