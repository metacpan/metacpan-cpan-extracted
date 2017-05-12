#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Test;

use Test::More;

use IO::Async::Loop;
use IO::Async::OS;

plan skip_all => "POSIX fork() is not available" unless IO::Async::OS->HAVE_POSIX_FORK;

use POSIX qw( WEXITSTATUS );

# These tests check the parts of Loop->spawn_child that need to be root to
# work. Since we're unlikely to be root, skip the lot if we're not.

unless( $< == 0 ) {
   plan skip_all => "not root";
}

is( $>, 0, 'am root');

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

my ( $exitcode, $dollarbang, $dollarat );

$loop->spawn_child(
   code => sub { return $> },
   setup => [ setuid => 10 ],
   on_exit => sub { ( undef, $exitcode, $dollarbang, $dollarat ) = @_ },
);

wait_for { defined $exitcode };

is( WEXITSTATUS($exitcode), 10, 'setuid' );

$loop->spawn_child(
   code => sub { return $) },
   setup => [ setgid => 10 ],
   on_exit => sub { ( undef, $exitcode, $dollarbang, $dollarat ) = @_ },
);

undef $exitcode;
wait_for { defined $exitcode };

is( WEXITSTATUS($exitcode), 10, 'setgid' );

$loop->spawn_child(
   code => sub { return $) =~ m/ 5 / },
   setup => [ setgroups => [ 4, 5, 6 ] ],
   on_exit => sub { ( undef, $exitcode, $dollarbang, $dollarat ) = @_ },
);

undef $exitcode;
wait_for { defined $exitcode };

is( WEXITSTATUS($exitcode), 1, 'setgroups' );

my $child_out;

$loop->run_child(
   code => sub {
      print "EUID: $>\n";
      my ( $gid, @groups ) = split( m/ /, $) );
      print "EGID: $gid\n";
      print "Groups: " . join( " ", sort { $a <=> $b } @groups ) . "\n";
      return 0;
   },
   setup => [
      setgid    => 10,
      setgroups => [ 4, 5, 6, 10 ],
      setuid    => 20,
   ],
   on_finish => sub { ( undef, $exitcode, $child_out ) = @_; },
);

undef $exitcode;
wait_for { defined $exitcode };

is( $child_out,
    "EUID: 20\nEGID: 10\nGroups: 4 5 6 10\n",
    'combined setuid/gid/groups' );

done_testing;
