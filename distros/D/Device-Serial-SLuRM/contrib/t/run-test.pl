#!/usr/bin/perl

use v5.36;
use Digest::CRC qw( crc8 );
use IPC::Open2 qw( open2 );
use POSIX qw( WIFEXITED WEXITSTATUS WIFSIGNALED WTERMSIG );

my $HARNESS = "t/harness-slurm";

my ( $hin, $hout, $hpid );

sub open_harness ( $harness )
{
   my @command = $harness;
   $hpid = open2 $hout, $hin, @command or die "Cannot open2 harness - $!";
}

open my $test, "<", my $file = $ARGV[0] or die "Cannot open test script $ARGV[0] - $!";

my $exitcode = 0;

my $command;
my @expect;

my $linenum = 0;
my $testnum = 0;

sub fail ( $msg ) { die "$msg on $file line $linenum.\n"; }

sub decode ( $line )
{
   my $data = "";
   while( length $line ) {
      if( $line =~ s/^0x([[:xdigit:]]+)// ) {
         $data .= pack "H*", $1;
      }
      elsif( $line =~ s/^\"([^"]*)\"// ) {
         # TODO: escapes like \n etc?
         $data .= $1;
      }
      elsif( $line =~ s/^\+C// ) {
         $data .= pack "C", crc8( $data );
      }
      else {
         fail "Unrecognised RECV data chunk '$line'";
      }
      $line =~ s/^ +//;
   }

   return $data;
}

sub do_onetest ()
{
   $hin or open_harness( $HARNESS );

   $hin->print( "$command\n" );
   undef $command;

   my $fail_printed;

   while( my $outline = <$hout> ) {
      last if $outline eq "DONE\n" or $outline eq "?\n";

      chomp $outline;

      if( $outline =~ m/^send / ) {
         my $gotbytes = $outline =~ s/^send //r;

         while( length $gotbytes and @expect and $expect[0] =~ m/^send / ) {
            my $wantbytes = $expect[0] =~ s/^send //r;

            last if length $wantbytes > length $gotbytes;
            last if substr( $gotbytes, 0, length $wantbytes ) ne $wantbytes;

            # Chunk matched
            substr( $gotbytes, 0, length $wantbytes ) = "";
            shift @expect;
         }

         next if !length $gotbytes;

         $outline = "send $gotbytes";
      }

      if( !@expect ) {
         print STDERR "# line $linenum: Test failed\n" unless $fail_printed++;
         print STDERR "#    expected nothing more\n" .
                      "#   Actual:   $outline\n";
         next;
      }

      my $expectation = shift @expect;

      next if $expectation eq $outline;

      print STDERR "# line $linenum: Test failed\n" unless $fail_printed++;
      print STDERR "#   Expected: $expectation\n" .
                   "#   Actual:   $outline\n";
   }

   if( @expect ) {
      print STDERR "# line $linenum: Test failed\n" unless $fail_printed++;
      print STDERR "#   Expected: $_\n" .
                   "#    didn't happen\n" for @expect;
   }

   $exitcode = 1 if $fail_printed;

   $testnum++;
   print "    ";
   print "not " if $fail_printed;
   print "ok $testnum\n";
}

my $title;

my $subtest_count;

sub finish_subtest ()
{
   print "    1..$testnum\n";
   print "ok $title\n";
   $subtest_count++;
   undef $title;
}

sub do_line ( $line )
{
   if( $line =~ s/^!// ) {
      do_onetest if defined $command;
      finish_subtest if $title;

      print "# Subtest\n";
      $testnum = 0;
      $title = $line;
      return;
   }

   if( $line =~ s/^\*SELECT // ) {
      $HARNESS = "t/harness-$line";
      -f $HARNESS or
         fail "Unrecognised harness selection $line\n";

      undef $hin;
      undef $hout;

      return;
   }

   # Commands are all in capitals
   if( $line =~ m/^[A-Z]+/ ) {
      if( $line =~ s/^(RECV|NOTIFY|RESPOND +\d+|ERR +\d+) +// ) {
         # push data in various encodings
         my $cmd = $1;
         $line = "$cmd " . uc unpack "H*", decode( $line );
      }

      do_onetest if defined $command;
      $command = $line;
      undef @expect;
   }
   # Expectations are all lowercase
   elsif( $line =~ m/^[a-z]+/ ) {
      if( $line =~ s/^(notify|request +\d+|send) +// ) {
         my $cmd = $1;
         $line = "$cmd " . uc unpack "H*", decode( $line );
      }

      push @expect, $line;
   }
   else {
      fail "Unrecognised test line $line";
   }
}

while( my $line = <$test> ) {
   $linenum++;
   $line =~ s/^\s+//;
   chomp $line;

   next if $line =~ m/^(?:#|$)/;
   last if $line eq "__END__";

   do_line( $line );
}

do_onetest if defined $command;
finish_subtest if $title;

print "1..$subtest_count\n";

close $hin;
close $hout;

waitpid $hpid, 0;
if( $? ) {
   printf STDERR "Harness exited %d\n", WEXITSTATUS($?)   if WIFEXITED($?);
   printf STDERR "Harness exit signal %d\n", WTERMSIG($?) if WIFSIGNALED($?);
   $exitcode = WIFEXITED($?) ? WEXITSTATUS($?) : 125;
}

exit $exitcode;
