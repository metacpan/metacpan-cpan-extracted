#!/usr/bin/perl

use v5.14;
use warnings;

use IO::Async::Test;

use Test2::V0;

use IO::Async::Process;

use IO::Async::Loop;
use IO::Async::OS;

plan skip_all => "POSIX fork() is not available" unless IO::Async::OS->HAVE_POSIX_FORK;

use Socket qw( PF_INET sockaddr_family );

my $loop = IO::Async::Loop->new_builtin;

testing_loop( $loop );

{
   my $process = IO::Async::Process->new(
      code => sub { print "hello\n"; return 0 },
      stdout => { via => "pipe_read" },
      on_finish => sub { },
   );

   isa_ok( $process->stdout, [ "IO::Async::Stream" ], '$process->stdout isa IO::Async::Stream' );

   is( $process->stdout->notifier_name, "stdout", '$process->stdout->notifier_name' );
   
   my @stdout_lines;

   $process->stdout->configure(
      on_read => sub {
         my ( undef, $buffref ) = @_;
         push @stdout_lines, $1 while $$buffref =~ s/^(.*\n)//;
         return 0;
      },
   );

   $loop->add( $process );

   ok( defined $process->stdout->read_handle, '$process->stdout has read_handle for sub { print }' );

   wait_for { !$process->is_running };

   ok( $process->is_exited,     '$process->is_exited after sub { print }' );
   is( $process->exitstatus, 0, '$process->exitstatus after sub { print }' );

   is( \@stdout_lines, [ "hello\n" ], '@stdout_lines after sub { print }' );
}

{
   my @stdout_lines;

   my $process = IO::Async::Process->new(
      code => sub { print "hello\n"; return 0 },
      stdout => {
         on_read => sub {
            my ( undef, $buffref ) = @_;
            push @stdout_lines, $1 while $$buffref =~ s/^(.*\n)//;
            return 0;
         },
      },
      on_finish => sub { },
   );

   isa_ok( $process->stdout, [ "IO::Async::Stream" ], '$process->stdout isa IO::Async::Stream' );

   $loop->add( $process );

   ok( defined $process->stdout->read_handle, '$process->stdout has read_handle for sub { print } inline' );

   wait_for { !$process->is_running };

   ok( $process->is_exited,     '$process->is_exited after sub { print } inline' );
   is( $process->exitstatus, 0, '$process->exitstatus after sub { print } inline' );

   is( \@stdout_lines, [ "hello\n" ], '@stdout_lines after sub { print } inline' );
}

{
   my $stdout;

   my $process = IO::Async::Process->new(
      code => sub { print "hello\n"; return 0 },
      stdout => { into => \$stdout },
      on_finish => sub { },
   );

   isa_ok( $process->stdout, [ "IO::Async::Stream" ], '$process->stdout isa IO::Async::Stream' );

   $loop->add( $process );

   ok( defined $process->stdout->read_handle, '$process->stdout has read_handle for sub { print } into' );

   wait_for { !$process->is_running };

   ok( $process->is_exited,     '$process->is_exited after sub { print } into' );
   is( $process->exitstatus, 0, '$process->exitstatus after sub { print } into' );

   is( $stdout, "hello\n", '$stdout after sub { print } into' )
}

{
   my $stdout;

   my $process = IO::Async::Process->new(
      command => [ $^X, "-e", 'print "hello\n"' ],
      stdout => { into => \$stdout },
      on_finish => sub { },
   );

   $loop->add( $process );

   wait_for { !$process->is_running };

   ok( $process->is_exited,     '$process->is_exited after perl STDOUT' );
   is( $process->exitstatus, 0, '$process->exitstatus after perl STDOUT' );

   is( $stdout, "hello\n", '$stdout after perl STDOUT' );
}

{
   my $stdout;
   my $stderr;

   my $process = IO::Async::Process->new(
      command => [ $^X, "-e", 'print STDOUT "output\n"; print STDERR "error\n";' ],
      stdout => { into => \$stdout },
      stderr => { into => \$stderr },
      on_finish => sub { },
   );

   isa_ok( $process->stderr, [ "IO::Async::Stream" ], '$process->stderr isa IO::Async::Stream' );

   is( $process->stderr->notifier_name, "stderr", '$process->stderr->notifier_name' );

   $loop->add( $process );

   ok( defined $process->stderr->read_handle, '$process->stderr has read_handle' );

   wait_for { !$process->is_running };

   ok( $process->is_exited,     '$process->is_exited after perl STDOUT/STDERR' );
   is( $process->exitstatus, 0, '$process->exitstatus after perl STDOUT/STDERR' );

   is( $stdout, "output\n", '$stdout after perl STDOUT/STDERR' );
   is( $stderr, "error\n",  '$stderr after perl STDOUT/STDERR' );
}

{
   my $stdout;

   my $process = IO::Async::Process->new(
      command => [ $^X, "-pe", '$_ = uc' ],
      stdin   => { via => "pipe_write" },
      stdout  => { into => \$stdout },
      on_finish => sub { },
   );

   isa_ok( $process->stdin, [ "IO::Async::Stream" ], '$process->stdin isa IO::Async::Stream' );

   is( $process->stdin->notifier_name, "stdin", '$process->stdin->notifier_name' );

   $process->stdin->write( "some data\n", on_flush => sub { $_[0]->close } );

   $loop->add( $process );

   ok( defined $process->stdin->write_handle, '$process->stdin has write_handle for perl STDIN->STDOUT' );

   wait_for { !$process->is_running };

   ok( $process->is_exited,     '$process->is_exited after perl STDIN->STDOUT' );
   is( $process->exitstatus, 0, '$process->exitstatus after perl STDIN->STDOUT' );

   is( $stdout, "SOME DATA\n", '$stdout after perl STDIN->STDOUT' );
}

{
   my $process = IO::Async::Process->new(
      command => [ $^X, "-e", 'exit 4' ],
      stdin   => { via => "pipe_write" },
      on_finish => sub { },
   );

   isa_ok( $process->stdin, [ "IO::Async::Stream" ], '$process->stdin isa IO::Async::Stream' );

   $loop->add( $process );

   ok( defined $process->stdin->write_handle, '$process->stdin has write_handle for perl STDIN no-wait close' );

   wait_for { !$process->is_running };

   ok( $process->is_exited,     '$process->is_exited after perl STDIN no-wait close' );
   is( $process->exitstatus, 4, '$process->exitstatus after perl STDIN no-wait close' );
}

{
   my $stdout;

   my $process = IO::Async::Process->new(
      command => [ $^X, "-pe", '$_ = uc' ],
      stdin   => { from => "some data\n" },
      stdout  => { into => \$stdout },
      on_finish => sub { },
   );

   isa_ok( $process->stdin, [ "IO::Async::Stream" ], '$process->stdin isa IO::Async::Stream' );

   $loop->add( $process );

   ok( defined $process->stdin->write_handle, '$process->stdin has write_handle for perl STDIN->STDOUT from' );

   wait_for { !$process->is_running };

   ok( $process->is_exited,     '$process->is_exited after perl STDIN->STDOUT from' );
   is( $process->exitstatus, 0, '$process->exitstatus after perl STDIN->STDOUT from' );

   is( $stdout, "SOME DATA\n", '$stdout after perl STDIN->STDOUT from' );
}

{
   my $stdout;

   my $process = IO::Async::Process->new(
      command => [ $^X, "-pe", '$_ = "line"' ],
      stdin   => { from => "" },
      stdout  => { into => \$stdout },
      on_finish => sub { },
   );

   isa_ok( $process->stdin, [ "IO::Async::Stream" ], '$process->stdin isa IO::Async::Stream' );

   $loop->add( $process );

   ok( defined $process->stdin->write_handle, '$process->stdin has write_handle for perl STDIN->STDOUT from empty string' );

   wait_for { !$process->is_running };

   ok( $process->is_exited,     '$process->is_exited after perl STDIN->STDOUT from empty string' );
   is( $process->exitstatus, 0, '$process->exitstatus after perl STDIN->STDOUT from empty string' );

   is( $stdout, "", '$stdout after perl STDIN->STDOUT from empty string' );
}

{
   my $stdout;

   my $process = IO::Async::Process->new(
      command => [ $^X, "-pe", '$_ = uc' ],
      fd0 => { from => "some data\n" },
      fd1 => { into => \$stdout },
      on_finish => sub { },
   );

   $loop->add( $process );

   wait_for { !$process->is_running };

   ok( $process->is_exited,     '$process->is_exited after perl STDIN->STDOUT using fd[n]' );
   is( $process->exitstatus, 0, '$process->exitstatus after perl STDIN->STDOUT using fd[n]' );

   is( $stdout, "SOME DATA\n", '$stdout after perl STDIN->STDOUT using fd[n]' );
}

{
   my $output;

   my $process = IO::Async::Process->new(
      command => [ $^X, "-pe", '$_ = uc' ],
      stdio => { via => "pipe_rdwr" },
      on_finish => sub { },
   );

   isa_ok( $process->stdio, [ "IO::Async::Stream" ], '$process->stdio isa IO::Async::Stream' );

   is( $process->stdio->notifier_name, "stdio", '$process->stdio->notifier_name' );

   my @output_lines;

   $process->stdio->write( "some data\n", on_flush => sub { $_[0]->close_write } );
   $process->stdio->configure(
      on_read => sub {
         my ( undef, $buffref ) = @_;
         push @output_lines, $1 while $$buffref =~ s/^(.*\n)//;
         return 0;
      },
   );

   $loop->add( $process );

   ok( defined $process->stdio->read_handle,  '$process->stdio has read_handle for perl STDIO' );
   ok( defined $process->stdio->write_handle, '$process->stdio has write_handle for perl STDIO' );

   wait_for { !$process->is_running };

   ok( $process->is_exited,     '$process->is_exited after perl STDIO' );
   is( $process->exitstatus, 0, '$process->exitstatus after perl STDIO' );

   is( \@output_lines, [ "SOME DATA\n" ], '@output_lines after perl STDIO' );
}

{
   my $output;

   my $process = IO::Async::Process->new(
      command => [ $^X, "-pe", '$_ = uc' ],
      stdio => {
         from => "some data\n",
         into => \$output,
      },
      on_finish => sub { },
   );

   $loop->add( $process );

   wait_for { !$process->is_running };

   ok( $process->is_exited,     '$process->is_exited after perl STDIN->STDOUT using stdio' );
   is( $process->exitstatus, 0, '$process->exitstatus after perl STDIN->STDOUT using stdio' );

   is( $output, "SOME DATA\n", '$stdout after perl STDIN->STDOUT using stdio' );
}

{
   my $process = IO::Async::Process->new(
      code => sub {
         defined( recv STDIN, my $pkt, 8192, 0 ) or die "Cannot recv - $!";
         send STDOUT, $pkt, 0 or die "Cannot send - $!";
         return 0;
      },
      stdio => { via => "socketpair" },
      on_finish => sub { },
   );

   isa_ok( $process->stdio, [ "IO::Async::Stream" ], '$process->stdio isa IO::Async::Stream' );

   $process->stdio->write( "A packet to be echoed" );

   my $output_packet = "";
   $process->stdio->configure(
      on_read => sub {
         my ( undef, $buffref ) = @_;
         $output_packet .= $$buffref;
         $$buffref = "";
         return 0;
      },
   );

   $loop->add( $process );

   isa_ok( $process->stdio->read_handle, [ "IO::Socket" ], '$process->stdio handle isa IO::Socket' );

   wait_for { defined $output_packet and !$process->is_running };

   ok( $process->is_exited,     '$process->is_exited after perl STDIO via socketpair' );
   is( $process->exitstatus, 0, '$process->exitstatus after perl STDIO via socketpair' );

   is( $output_packet, "A packet to be echoed", '$output_packet after perl STDIO via socketpair' );
}

{
   my $process = IO::Async::Process->new(
      code => sub {
         defined STDIN->sysread( my $pkt, 8192 ) or die "Cannot recv - $!";
         STDOUT->syswrite( $pkt ) or die "Cannot send - $!";
         return 0;
      },
      stdio => {
        via => "socketpair",
        prefork => sub {
          my ( $myfd, $childfd ) = @_;

          $myfd->write( "Data from the prefork" );
        },
      },
      on_finish => sub { },
   );

   isa_ok( $process->stdio, [ "IO::Async::Stream" ], '$process->stdio isa IO::Async::Stream' );

   my $output_packet = "";
   $process->stdio->configure(
      on_read => sub {
         my ( undef, $buffref ) = @_;
         $output_packet .= $$buffref;
         $$buffref = "";
         return 0;
      },
   );

   $loop->add( $process );

   isa_ok( $process->stdio->read_handle, [ "IO::Socket" ], '$process->stdio handle isa IO::Socket' );

   wait_for { defined $output_packet and !$process->is_running };

   ok( $process->is_exited,     '$process->is_exited after perl STDIO via socketpair' );
   is( $process->exitstatus, 0, '$process->exitstatus after perl STDIO via socketpair' );

   is( $output_packet, "Data from the prefork", '$output_packet from prefork via socketpair' );
}

{
   my $process = IO::Async::Process->new(
      code => sub { return 0 },
      stdio => { via => "socketpair", family => "inet" },
      on_finish => sub { },
   );

   isa_ok( $process->stdio, [ "IO::Async::Stream" ], '$process->stdio isa IO::Async::Stream' );

   $process->stdio->configure( on_read => sub { } );

   $loop->add( $process );

   isa_ok( $process->stdio->read_handle, [ "IO::Socket" ], '$process->stdio handle isa IO::Socket' );
   is( sockaddr_family( $process->stdio->read_handle->sockname ), PF_INET, '$process->stdio handle sockdomain is PF_INET' );

   wait_for { !$process->is_running };
}

{
   my $process = IO::Async::Process->new(
      code => sub {
         for( 1, 2 ) {
            defined( recv STDIN, my $pkt, 8192, 0 ) or die "Cannot recv - $!";
            send STDOUT, $pkt, 0 or die "Cannot send - $!";
         }
         return 0;
      },
      stdio => { via => "socketpair", socktype => "dgram", family => "inet" },
      on_finish => sub { },
   );

   isa_ok( $process->stdio, [ "IO::Async::Socket" ], '$process->stdio isa IO::Async::Socket' );

   my @output_packets;
   $process->stdio->configure(
      on_recv => sub {
         my ( $self, $packet ) = @_;
         push @output_packets, $packet;

         $self->close if @output_packets == 2;

         return 0;
      },
   );

   $loop->add( $process );

   isa_ok( $process->stdio->read_handle, [ "IO::Socket" ], '$process->stdio handle isa IO::Socket' );
   ok( defined sockaddr_family( $process->stdio->read_handle->sockname ), '$process->stdio handle sockdomain is defined' );

   $process->stdio->send( $_ ) for "First packet", "Second packet";

   wait_for { @output_packets == 2 and !$process->is_running };

   ok( $process->is_exited,     '$process->is_exited after perl STDIO via dgram socketpair' );
   is( $process->exitstatus, 0, '$process->exitstatus after perl STDIO via dgram socketpair' );

   is( \@output_packets,
              [ "First packet", "Second packet" ],
              '@output_packets after perl STDIO via dgram socketpair' );
}

done_testing;
