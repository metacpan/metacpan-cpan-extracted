#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;
use Test::Fatal;

use File::Temp qw( tmpnam );
use POSIX qw( ENOENT EBADF getcwd );

use IO::Async::Loop;
use IO::Async::OS;

plan skip_all => "POSIX fork() is not available" unless IO::Async::OS->HAVE_POSIX_FORK;

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

ok( exception { $loop->spawn_child( code => sub { 1 }, setup => "hello" ); },
    'Bad setup type fails' );

ok( exception { $loop->spawn_child( code => sub { 1 }, setup => [ 'somerandomthing' => 1 ] ); },
    'Setup with bad key fails' );

# These tests are all very similar looking, with slightly different start and
# code values. Easiest to wrap them up in a common testing wrapper.

sub TEST
{
   my ( $name, %attr ) = @_;

   my $exitcode;
   my $dollarbang;
   my $dollarat;

   my ( undef, $callerfile, $callerline ) = caller;

   $loop->spawn_child(
      code => $attr{code},
      exists $attr{setup} ? ( setup => $attr{setup} ) : (),
      on_exit => sub { ( undef, $exitcode, $dollarbang, $dollarat ) = @_; },
   );

   wait_for { defined $exitcode };

   if( exists $attr{exitstatus} ) {
      ok( ($exitcode & 0x7f) == 0, "WIFEXITED(\$exitcode) after $name" );
      is( ($exitcode >> 8), $attr{exitstatus}, "WEXITSTATUS(\$exitcode) after $name" );
   }

   if( exists $attr{dollarbang} ) {
      is( $dollarbang+0, $attr{dollarbang}, "\$dollarbang numerically after $name" );
   }

   if( exists $attr{dollarat} ) {
      is( $dollarat, $attr{dollarat}, "\$dollarat after $name" );
   }
}

# A useful utility function like blocking read with a timeout
sub read_timeout
{
   my ( $fh, undef, $len, $timeout ) = @_;

   my $rvec = '';
   vec( $rvec, fileno $fh, 1 ) = 1;

   select( $rvec, undef, undef, $timeout );

   return undef if !vec( $rvec, fileno $fh, 1 );

   return $fh->read( $_[1], $len );
}

my $buffer;
my $ret;

{
   my( $pipe_r, $pipe_w ) = IO::Async::OS->pipepair or die "Cannot pipepair - $!";

   TEST "pipe dup to fd1",
      setup => [ fd1 => [ 'dup', $pipe_w ] ],
      code => sub { print "test"; },

      exitstatus => 1,
      dollarat   => '';

   undef $buffer;
   $ret = read_timeout( $pipe_r, $buffer, 4, 0.1 );

   is( $ret, 4,         '$pipe_r->read after pipe dup to fd1' );
   is( $buffer, 'test', '$buffer after pipe dup to fd1' );

   my $pipe_w_fileno = fileno $pipe_w;

   TEST "pipe dup to fd1 closes pipe",
      setup => [ fd1 => [ 'dup', $pipe_w ] ],
      code => sub {
         my $f = IO::Handle->new_from_fd( $pipe_w_fileno, "w" );
         defined $f and return 1;
         $! == EBADF or return 1;
         return 0;
      },

      exitstatus => 0,
      dollarat   => '';

   TEST "pipe dup to stdout shortcut",
      setup => [ stdout => $pipe_w ],
      code => sub { print "test"; },

      exitstatus => 1,
      dollarat   => '';

   undef $buffer;
   $ret = read_timeout( $pipe_r, $buffer, 4, 0.1 );

   is( $ret, 4,         '$pipe_r->read after pipe dup to stdout shortcut' );
   is( $buffer, 'test', '$buffer after pipe dup to stdout shortcut' );

   TEST "pipe dup to \\*STDOUT IO reference",
      setup => [ \*STDOUT => $pipe_w ],
      code => sub { print "test2"; },

      exitstatus => 1,
      dollarat   => '';

   undef $buffer;
   $ret = read_timeout( $pipe_r, $buffer, 5, 0.1 );

   is( $ret, 5,          '$pipe_r->read after pipe dup to \\*STDOUT IO reference' );
   is( $buffer, 'test2', '$buffer after pipe dup to \\*STDOUT IO reference' );

   TEST "pipe keep open",
      setup => [ "fd$pipe_w_fileno" => [ 'keep' ] ],
      code  => sub { $pipe_w->autoflush(1); $pipe_w->print( "test" ) },

      exitstatus => 1,
      dollarat   => '';

   undef $buffer;
   $ret = read_timeout( $pipe_r, $buffer, 4, 0.1 );

   is( $ret, 4,         '$pipe_r->read after keep pipe open' );
   is( $buffer, 'test', '$buffer after keep pipe open' );

   TEST "pipe keep shortcut",
      setup => [ "fd$pipe_w_fileno" => 'keep' ],
      code  => sub { $pipe_w->autoflush(1); $pipe_w->print( "test" ) },

      exitstatus => 1,
      dollarat   => '';

   undef $buffer;
   $ret = read_timeout( $pipe_r, $buffer, 4, 0.1 );

   is( $ret, 4,         '$pipe_r->read after keep pipe open' );
   is( $buffer, 'test', '$buffer after keep pipe open' );


   TEST "pipe dup to stdout",
      setup => [ stdout => [ 'dup', $pipe_w ] ],
      code => sub { print "test"; },

      exitstatus => 1,
      dollarat   => '';

   undef $buffer;
   $ret = read_timeout( $pipe_r, $buffer, 4, 0.1 );

   is( $ret, 4,         '$pipe_r->read after pipe dup to stdout' );
   is( $buffer, 'test', '$buffer after pipe dup to stdout' );

   TEST "pipe dup to fd2",
      setup => [ fd2 => [ 'dup', $pipe_w ] ],
      code => sub { print STDERR "test"; },

      exitstatus => 1,
      dollarat   => '';

   undef $buffer;
   $ret = read_timeout( $pipe_r, $buffer, 4, 0.1 );

   is( $ret, 4,         '$pipe_r->read after pipe dup to fd2' );
   is( $buffer, 'test', '$buffer after pipe dup to fd2' );

   TEST "pipe dup to stderr",
      setup => [ stderr => [ 'dup', $pipe_w ] ],
      code => sub { print STDERR "test"; },

      exitstatus => 1,
      dollarat   => '';

   undef $buffer;
   $ret = read_timeout( $pipe_r, $buffer, 4, 0.1 );

   is( $ret, 4,         '$pipe_r->read after pipe dup to stderr' );
   is( $buffer, 'test', '$buffer after pipe dup to stderr' );

   TEST "pipe dup to other FD",
      setup => [ fd4 => [ 'dup', $pipe_w ] ],
      code => sub { 
         close STDOUT;
         open( STDOUT, ">&=4" ) or die "Cannot open fd4 as stdout - $!";
         print "test";
      },

      exitstatus => 1,
      dollarat   => '';

   undef $buffer;
   $ret = read_timeout( $pipe_r, $buffer, 4, 0.1 );

   is( $ret, 4,         '$pipe_r->read after pipe dup to other FD' );
   is( $buffer, 'test', '$buffer after pipe dup to other FD' );

   TEST "pipe dup to its own FD",
      setup => [ "fd$pipe_w_fileno" => $pipe_w ],
      code => sub {
         close STDOUT;
         open( STDOUT, ">&=$pipe_w_fileno" ) or die "Cannot open fd$pipe_w_fileno as stdout - $!";
         print "test";
      },

      exitstatus => 1,
      dollarat   => '';

   undef $buffer;
   $ret = read_timeout( $pipe_r, $buffer, 4, 0.1 );

   is( $ret, 4,         '$pipe_r->read after pipe dup to its own FD' );
   is( $buffer, 'test', '$buffer after pipe dup to its own FD' );

   TEST "other FD close",
      code => sub { return $pipe_w->syswrite( "test" ); },

      exitstatus => 255,
      dollarbang => EBADF,
      dollarat   => '';

   # Try to force a writepipe clash by asking to dup the pipe to lots of FDs
   TEST "writepipe clash",
      code => sub { print "test"; },
      setup => [ map { +"fd$_" => $pipe_w } ( 1 .. 19 ) ],

      exitstatus => 1,
      dollarat   => '';

   undef $buffer;
   $ret = read_timeout( $pipe_r, $buffer, 4, 0.1 );

   is( $ret, 4,         '$pipe_r->read after writepipe clash' );
   is( $buffer, 'test', '$buffer after writepipe clash' );

   my( $pipe2_r, $pipe2_w ) = IO::Async::OS->pipepair or die "Cannot pipepair - $!";
   $pipe2_r->blocking( 0 );

   TEST "pipe dup to stdout and stderr",
      setup => [ stdout => $pipe_w, stderr => $pipe2_w ],
      code => sub { print "output"; print STDERR "error"; },

      exitstatus => 1,
      dollarat   => '';

   undef $buffer;
   $ret = read_timeout( $pipe_r, $buffer, 6, 0.1 );

   is( $ret, 6,           '$pipe_r->read after pipe dup to stdout and stderr' );
   is( $buffer, 'output', '$buffer after pipe dup to stdout and stderr' );

   undef $buffer;
   $ret = read_timeout( $pipe2_r, $buffer, 5, 0.1 );

   is( $ret, 5,          '$pipe2_r->read after pipe dup to stdout and stderr' );
   is( $buffer, 'error', '$buffer after pipe dup to stdout and stderr' );

   TEST "pipe dup to stdout and stderr same pipe",
      setup => [ stdout => $pipe_w, stderr => $pipe_w ],
      code => sub { print "output"; print STDERR "error"; },

      exitstatus => 1,
      dollarat   => '';

   undef $buffer;
   $ret = read_timeout( $pipe_r, $buffer, 11, 0.1 );

   is( $ret, 11,               '$pipe_r->read after pipe dup to stdout and stderr same pipe' );
   is( $buffer, 'outputerror', '$buffer after pipe dup to stdout and stderr same pipe' );
}

{
   my ( $child_r, $my_w, $my_r, $child_w ) = IO::Async::OS->pipequad or die "Cannot pipequad - $!";

   $my_w->syswrite( "hello\n" );

   TEST "pipe quad to fd0/fd1",
      setup => [ stdin  => $child_r,
                 stdout => $child_w, ],
      code => sub { print uc scalar <STDIN>; return 0 },

      exitstatus => 0,
      dollarat   => '';

   my $buffer;
   $ret = read_timeout( $my_r, $buffer, 6, 0.1 );

   is( $ret, 6,            '$my_r->read after pipe quad to fd0/fd1' );
   is( $buffer, "HELLO\n", '$buffer after pipe quad to fd0/fd1' );
}

{
   # Try to swap two filehandles and cause a dup2() collision
   my @fhA = IO::Async::OS->pipepair or die "Cannot pipepair - $!";
   my @fhB = IO::Async::OS->pipepair or die "Cannot pipepair - $!";

   my $filenoA = $fhA[1]->fileno;
   my $filenoB = $fhB[1]->fileno;

   TEST "fd swap",
      setup => [
         "fd$filenoA" => $fhB[1],
         "fd$filenoB" => $fhA[1],
      ],
      code => sub {
         $fhA[1]->print( "FHA" ); $fhA[1]->autoflush(1);
         $fhB[1]->print( "FHB" ); $fhB[1]->autoflush(1);
         return 0;
      },

      exitstatus => 0;

   my $buffer;

   read_timeout( $fhA[0], $buffer, 3, 0.1 );
   is( $buffer, "FHB", '$buffer [A] after dup2() swap' );

   read_timeout( $fhB[0], $buffer, 3, 0.1 );
   is( $buffer, "FHA", '$buffer [B] after dup2() swap' );
}

TEST "stdout close",
   setup => [ stdout => [ 'close' ] ],
   code => sub { print "test"; },

   exitstatus => 255,
   dollarbang => EBADF,
   dollarat   => '';

TEST "stdout close shortcut",
   setup => [ stdout => 'close' ],
   code => sub { print "test"; },

   exitstatus => 255,
   dollarbang => EBADF,
   dollarat   => '';

{
   my $name = tmpnam;
   END { unlink $name if defined $name and -f $name }

   TEST "stdout open",
      setup => [ stdout => [ 'open', '>', $name ] ],
      code => sub { print "test"; },

      exitstatus => 1,
      dollarat   => '';

   ok( -f $name, 'tmpnam file exists after stdout open' );

   open( my $tmpfh, "<", $name ) or die "Cannot open '$name' for reading - $!";

   undef $buffer;
   $ret = read_timeout( $tmpfh, $buffer, 4, 0.1 );

   is( $ret, 4,         '$tmpfh->read after stdout open' );
   is( $buffer, 'test', '$buffer after stdout open' );

   TEST "stdout open append",
      setup => [ stdout => [ 'open', '>>', $name ] ],
      code => sub { print "value"; },

      exitstatus => 1,
      dollarat   => '';

   seek( $tmpfh, 0, 0 );

   undef $buffer;
   $ret = read_timeout( $tmpfh, $buffer, 9, 0.1 );

   is( $ret, 9,              '$tmpfh->read after stdout open append' );
   is( $buffer, 'testvalue', '$buffer after stdout open append' );
}

$ENV{TESTKEY} = "parent value";

TEST "environment is preserved",
   setup => [],
   code => sub { return $ENV{TESTKEY} eq "parent value" ? 0 : 1 },

   exitstatus => 0,
   dollarat   => '';

TEST "environment is overwritten",
   setup => [ env => { TESTKEY => "child value" } ],
   code => sub { return $ENV{TESTKEY} eq "child value" ? 0 : 1 },

   exitstatus => 0,
   dollarat   => '';

SKIP: {
   # Some of the CPAN smoke testers might run test scripts under modified nice
   # anyway. We'd better get our starting value to check for difference, not 
   # absolute
   my $prio_now = getpriority(0,0);

   # If it's already quite high, we don't want to hit the limit and be
   # clamped. Just skip the tests if it's too high before we start.
   skip "getpriority is already above 15, so I won't try renicing upwards", 3 if $prio_now > 15;

   TEST "nice works",
      setup => [ nice => 3 ],
      code  => sub { return getpriority(0,0) == $prio_now + 3 ? 0 : 1 },

      exitstatus => 0,
      dollarat   => '';
}

TEST "chdir works",
   setup => [ chdir => "/" ],
   code  => sub { return getcwd eq "/" ? 0 : 1 },

   exitstatus => 0,
   dollarat   => '';

done_testing;
