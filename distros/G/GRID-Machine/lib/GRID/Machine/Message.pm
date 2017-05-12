#########################################################################
## Communication Support
package GRID::Machine;

use strict;
use Data::Dumper;

sub read_operation {
   my $self = shift;

   my  $readfunc = $self->{readfunc};

   local $/ = "\n";

   $readfunc->( my $operation, undef );
   defined $operation or die "Expected operation\n";
   
   chomp $operation;

   $readfunc->( my $numargs, undef );
   defined $numargs or die "Expected number of arguments\n";
   chomp $numargs;

   my @args;
   while( $numargs ) {
      $readfunc->( my $arglen, undef );
      die "Expected length of argument\n" unless (defined($arglen) && $arglen =~ /^\d+/);
      chomp $arglen;

      my $arg = "";
      while( $arglen ) {
         my $buffer;
         my $n = $readfunc->( $buffer, $arglen );
         die "read() returned $!\n" unless( defined $n );
         $arg .= $buffer;
         $arglen -= $n;
      }

      $arg .= '$VAR1';
      my $val = eval "no strict; $arg";
      die "Error evaluating argument $arg\n" if $@;
      push @args, $val;
      $numargs--;
   }

   return ( $operation, @args );
}

sub send_operation
{
   my ( $self, $operation, @args ) = @_;

   my $writefunc = $self->{writefunc};


   local $Data::Dumper::Indent = 0;
   local $Data::Dumper::Deparse = 1;
   local $Data::Dumper::Purity = 1;
   local $Data::Dumper::Terse = 0;

   # Buffer this for speed - this makes a big difference
   my $buffer = "";

   $buffer .= "$operation\n";
   $buffer .= scalar( @args ) . "\n";

   foreach my $arg ( @args ) {
      $arg = Dumper($arg);
      $buffer .= length( $arg ) . "\n" . "$arg";
   }

   $writefunc->( $buffer );
}

1;

