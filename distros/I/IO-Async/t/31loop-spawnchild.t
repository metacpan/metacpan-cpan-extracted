#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;
use Test::Fatal;

use POSIX qw( ENOENT EBADF );

use IO::Async::OS;

plan skip_all => "POSIX fork() is not available" unless IO::Async::OS->HAVE_POSIX_FORK;

use IO::Async::Loop;

# Need to look this up, so we don't hardcode the message in the test script
# This might cause locale issues
use constant ENOENT_MESSAGE => do { local $! = ENOENT; "$!" };

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

ok( exception { $loop->spawn_child( badoption => 1 ); }, 'Bad option to spawn fails' );

ok( exception { $loop->spawn_child( code => sub { 1 }, command => "hello" ); },
    'Both code and command options to spawn fails' );

ok( exception { $loop->spawn_child( on_exit => sub { 1 } ); }, 'Bad option to spawn fails' );

{
   my ( $exited_pid, $exitcode, $dollarbang, $dollarat );
   my $spawned_pid = $loop->spawn_child(
      code => sub { return 42; },
      on_exit => sub { ( $exited_pid, $exitcode, $dollarbang, $dollarat ) = @_; }
   );

   wait_for { defined $exited_pid };

   is( $exited_pid, $spawned_pid,  '$exited_pid == $spawned_pid after spawn CODE' );
   ok( ($exitcode & 0x7f) == 0,    'WIFEXITED($exitcode) after spawn CODE' );
   is( ($exitcode >> 8), 42,       'WEXITSTATUS($exitcode) after spawn CODE' );
   # dollarbang isn't interesting here
   is( $dollarat,              '', '$dollarat after spawn CODE' );
}

my $ENDEXIT = 10;
END { exit $ENDEXIT if defined $ENDEXIT; }

{
   my ( $exited_pid, $exitcode, $dollarbang, $dollarat );
   my $spawned_pid = $loop->spawn_child(
      code => sub { return 0; },
      on_exit => sub { ( $exited_pid, $exitcode, $dollarbang, $dollarat ) = @_; }
   );

   wait_for { defined $exited_pid };

   is( $exited_pid, $spawned_pid, '$exited_pid == $spawned_pid after spawn CODE with END' );
   ok( ($exitcode & 0x7f) == 0,   'WIFEXITED($exitcode) after spawn CODE with END' );
   # If this comes out as 10 then the END block ran and we fail.
   is( ($exitcode >> 8), 0,       'WEXITSTATUS($exitcode) after spawn CODE with END' );
   # dollarbang isn't interesting here
   is( $dollarat,             '', '$dollarat after spawn CODE with END' );
}

{
   my ( $exited_pid, $exitcode, $dollarbang, $dollarat );
   my $spawned_pid = $loop->spawn_child(
      code => sub { die "An exception here\n"; },
      on_exit => sub { ( $exited_pid, $exitcode, $dollarbang, $dollarat ) = @_; }
   );

   wait_for { defined $exited_pid };

   is( $exited_pid, $spawned_pid,   '$exited_pid == $spawned_pid after spawn CODE with die with END' );
   ok( ($exitcode & 0x7f) == 0,     'WIFEXITED($exitcode) after spawn CODE with die with END' );
   is( ($exitcode >> 8), 255,       'WEXITSTATUS($exitcode) after spawn CODE with die with END' );
   # dollarbang isn't interesting here
   is( $dollarat, "An exception here\n", '$dollarat after spawn CODE with die with END' );
}

undef $ENDEXIT;

# We need a command that just exits immediately with 0
my $true;
foreach (qw( /bin/true /usr/bin/true )) {
   $true = $_, last if -x $_;
}

# Didn't find a likely-looking candidate. We'll fake one using perl itself
$true = "$^X -e 1" if !defined $true;

{
   my ( $exited_pid, $exitcode, $dollarbang, $dollarat );
   my $spawned_pid = $loop->spawn_child(
      command => $true,
      on_exit => sub { ( $exited_pid, $exitcode, $dollarbang, $dollarat ) = @_; }
   );

   wait_for { defined $exited_pid };

   is( $exited_pid, $spawned_pid, '$exited_pid == $spawned_pid after spawn '.$true );
   ok( ($exitcode & 0x7f) == 0,   'WIFEXITED($exitcode) after spawn '.$true );
   is( ($exitcode >> 8), 0,       'WEXITSTATUS($exitcode) after spawn '.$true );
   is( $dollarbang+0,          0, '$dollarbang after spawn '.$true );
   is( $dollarat,             '', '$dollarat after spawn '.$true );
}

# Just be paranoid in case anyone actually has this
my $donotexist = "/bin/donotexist";
$donotexist .= "X" while -e $donotexist;

{
   my ( $exited_pid, $exitcode, $dollarbang, $dollarat );
   my $spawned_pid = $loop->spawn_child(
      command => $donotexist,
      on_exit => sub { ( $exited_pid, $exitcode, $dollarbang, $dollarat ) = @_; }
   );

   wait_for { defined $exited_pid };

   is( $exited_pid, $spawned_pid,   '$exited_pid == $spawned_pid after spawn donotexist' );
   ok( ($exitcode & 0x7f) == 0,     'WIFEXITED($exitcode) after spawn donotexist' );
   is( ($exitcode >> 8), 255,       'WEXITSTATUS($exitcode) after spawn donotexist' );
   is( $dollarbang+0, ENOENT,         '$dollarbang numerically after spawn donotexist' ); 
   is( "$dollarbang", ENOENT_MESSAGE, '$dollarbang string after spawn donotexist' );
   is( $dollarat,             '', '$dollarat after spawn donotexist' );
}

{
   my ( $exited_pid, $exitcode, $dollarbang, $dollarat );
   my $spawned_pid = $loop->spawn_child(
      command => [ $^X, "-e", "exit 14" ],
      on_exit => sub { ( $exited_pid, $exitcode, $dollarbang, $dollarat ) = @_; }
   );

   wait_for { defined $exited_pid };

   is( $exited_pid, $spawned_pid,  '$exited_pid == $spawned_pid after spawn ARRAY' );
   ok( ($exitcode & 0x7f) == 0,    'WIFEXITED($exitcode) after spawn ARRAY' );
   is( ($exitcode >> 8), 14,       'WEXITSTATUS($exitcode) after spawn ARRAY' );
   is( $dollarbang+0,           0, '$dollarbang after spawn ARRAY' );
   is( $dollarat,              '', '$dollarat after spawn ARRAY' );
}

{
   my( $pipe_r, $pipe_w ) = IO::Async::OS->pipepair or die "Cannot pipepair - $!";

   my ( $exited_pid, $exitcode, $dollarbang, $dollarat );
   my $spawned_pid = $loop->spawn_child(
      code => sub { return $pipe_w->syswrite( "test" ); },
      on_exit => sub { ( $exited_pid, $exitcode, $dollarbang, $dollarat ) = @_; }
   );

   wait_for { defined $exited_pid };

   is( $exited_pid, $spawned_pid,   '$exited_pid == $spawned_pid after pipe close test' );
   ok( ($exitcode & 0x7f) == 0,     'WIFEXITED($exitcode) after pipe close test' );
   is( ($exitcode >> 8), 255,       'WEXITSTATUS($exitcode) after pipe close test' );
   is( $dollarbang+0,        EBADF, '$dollarbang numerically after pipe close test' );
   is( $dollarat,               '', '$dollarat after pipe close test' );
}

done_testing;
