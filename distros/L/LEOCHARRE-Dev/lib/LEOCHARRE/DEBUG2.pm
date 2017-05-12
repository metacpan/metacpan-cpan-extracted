package LEOCHARRE::DEBUG2;
use strict;
#use Exporter;
#use vars qw(@ISA @EXPORT $VERSION @EXPORT_OK %EXPORT_TAGS);

#@ISA = qw(Exporter);

#@EXPORT_OK = qw( &DEBUG $DEBUG &debug &_debug_test );
#@EXPORT = qw($DEBUG);

#$VERSION = sprintf "%d.%02d", q$Revision: 1.1 $ =~ /(\d+)/g;




$LEOCHARRE::DEBUG2::DEBUG_LEVEL = 1;
$LEOCHARRE::DEBUG2::DEBUG = 0;
$LEOCHARRE::DEBUG2::_LAST_DEBUG_HAD_NEWLINE=1;

sub DEBUG {
   my $val = ref $_[0] ? $_[1] : $_[0];
   $LEOCHARRE::DEBUG2::DEBUG = $val if defined $val;
=for TOO FANCY
   my $val = shift;
   if (ref $val){
      $val = shift;
   }
   if (defined $val){
      $LEOCHARRE::DEBUG2::DEBUG = $val;
      printf STDERR"    set $val, %s\n", ref $val;
      
   }
=cut   
   return $LEOCHARRE::DEBUG2::DEBUG;
}

sub debug {
#   my $val = shift; $val = shift if ref $val;
   my $val = ref $_[0] ? $_[1] : $_[0];   
   DEBUG or return 1;


   if ( !$LEOCHARRE::DEBUG2::DEBUG_LEVEL ){
      $val=~/\n$/;
      print STDERR " $val\n";
      return 1;
   }

   
   
   my $sub = (caller(1))[3];
   # if used in a script, caller wont be there
   $sub ||= 'main';

   if ($LEOCHARRE::DEBUG2::DEBUG_LEVEL == 1){      
   
      $sub=~s/^.*:://; # just want last part
   
   }
      

   if( $LEOCHARRE::DEBUG2::_LAST_DEBUG_HAD_NEWLINE ){
      print STDERR " $sub(),";
   } 
 
   print STDERR " $val";   

   $LEOCHARRE::DEBUG2::_LAST_DEBUG_HAD_NEWLINE = ( $val=~/\n$/ ? 1 : 0  );
   
   return 1;   
}

sub _debug_test {
   my $val = ref $_[0] ? $_[1] : $_[0];
   $val=~s/\s+$// if defined $val;
   my $callerpkg = caller;
   my $sub = (caller(1))[3];
   
   printf STDERR " package is %s, call pkg is $callerpkg, callspace %s [$val]\n",__PACKAGE__,$sub;

   return 1;
}

sub import {
    ## find out who is calling us
    my $pkg = caller;

    ## while strict doesn't deal with globs, it still
    ## catches symbolic de/referencing
    no strict 'refs';

    ## iterate through all the globs in the symbol table
    foreach my $glob (keys %LEOCHARRE::DEBUG2::) {
        ## skip anything without a subroutine and 'import'
        next if not defined *{$LEOCHARRE::DEBUG2::{$glob}}{CODE}
                or $glob eq 'import';

        ## assign subroutine into caller's package
        *{$pkg . "::$glob"} = \&{"LEOCHARRE::DEBUG2::$glob"};
    }

   # ABUSE CALLING PACKAGE, these are scalars we want
   for (qw(DEBUG _LAST_DEBUG_HAD_NEWLINE DEBUG_LEVEL)){
      my $glob = $_;   
      *{$pkg . "::$glob"} = \${"LEOCHARRE::DEBUG2::$glob"};
   }   
   
    
}


=head1 DEBUG_LEVEL

Just message and newline:

   $MYMOD::DEBUG_LEVEL = 0;

Show calling sub (default):

   $MYMOD::DEBUG_LEVEL = 1;
   

Show calling full name:

   $MYMOD::DEBUG_LEVEL = 2;

Show tons of garble:

   $MYMOD::DEBUG_LEVEL = 3;
   


=cut


1;

