package LEOCHARRE::DEBUG;
use strict;
use vars qw($VERSION);
$VERSION = sprintf "%d.%02d", q$Revision: 1.14 $ =~ /(\d+)/g;

$LEOCHARRE::DEBUG::_DEBUG = 0;
$LEOCHARRE::DEBUG::USE_COLOR = 0;

sub _DEBUG { return $LEOCHARRE::DEBUG::_DEBUG; }

sub __DEBUG {
   my $pkg = shift;
   return sub {
      my $val = ref $_[0] ? $_[1] : $_[0];
      no strict 'refs';
      ${"$pkg\::DEBUG"} = $val if defined $val;   
      return ${"$pkg\::DEBUG"};
   };  
}


sub __debug {
   my $pkg = shift;

   return sub {
      no strict 'refs';
      my $DEBUG = ${"$pkg\::DEBUG"}; #TODO there is a way to do this at compile time
      #  instead of run time
   
      $DEBUG or return 1;
   
      my $_prepend = ' # ';
      
      
   
      # are we being used as method?
      # so that $self->debug() works like debug()
	   my $val = shift;
	   if (ref $val){ # then likely used as method
	      $val = shift; # use the next value.
	   }
	   no strict 'refs';	   	
	   
	   my $debug_label = shift;
	   $debug_label ||= 1;
	
	   # if they specify a label starting with a letter, show ONLY those debug messages
	   if ($debug_label=~/^[a-z]/i){
	      $debug_label eq $DEBUG or return 1;
	   }
	
	   # if they specify a number, show ONLY if DEBUG is at LEAST that
	   else {
	      no warnings;
	      ( $DEBUG >= $debug_label ) or return 1;
	   }
	
	 
	   
	   # SET CALLER NAMESPACE
	   my $sub = (caller(1))[3];
	   # if used in a script, caller wont be there
	   $sub ||= 'main';
	
	
	   my $caller_changed = 0;
	   if (${"$pkg\::_DEBUG_LAST_CALLER"} ne $sub ){
	      $caller_changed = 1;
	      
	      # if last had no new line.. then put a newline      
	      ${"$pkg\::_DEBUG_SHOW_NAMESPACE"} or print STDERR "\n";	      
	      ${"$pkg\::_DEBUG_SHOW_NAMESPACE"} = 1;
	      
	   }
	   ${"$pkg\::_DEBUG_LAST_CALLER"} = $sub;	     
	
	   unless (${"$pkg\::_DEBUG_SHOW_WHOLE_NAMESPACE"}){   
	      $sub=~s/^.*:://; # print sub() instead of MyPackage::sub()   
	   }	  
	
	   if( ${"$pkg\::_DEBUG_SHOW_NAMESPACE"} or $caller_changed){
	      print STDERR " $_prepend$sub(),";
	   }
      
	   defined $val or $val ='';

      # if ref.. use dumper
      if ( ref $val ){
         require Data::Dumper;
         $val = Data::Dumper::Dumper($val);
      }
      
	   print STDERR " $val\n";
	
	
	   if ($val=~/\n$/ ) {
	      ${"$pkg\::_DEBUG_SHOW_NAMESPACE"} = 1;
	   }
	   else {
	      ${"$pkg\::_DEBUG_SHOW_NAMESPACE"} = 0;
	   }
	
	   return 1;   
   };
}


sub __debug_smaller {
   my $pkg = shift;

   return sub {
      no strict 'refs';
      my $DEBUG = ${"$pkg\::DEBUG"}; #TODO there is a way to do this at compile time, not run time
      $DEBUG or return 1;
      # are we being used as method?
      # so that $self->debug() works like debug()

      
      my @msgs = grep { length $_ } map { __resolve_one_message($_) } @_;



      # what's the debug level
      my $debug_level = __resolve_debug_level($pkg);

      if ( $debug_level > 1 ){
         
   
	      # SET CALLER NAMESPACE
	      my $sub = (caller(1))[3];
	      # if used in a script, caller wont be there
	      $sub ||= $pkg;
         $sub =  ($sub eq 'main') ? $0 : "$sub()";

         @msgs = map { " $_" } @msgs;
         unshift @msgs, "\n# $sub";

      }

      
      __cleanup_message(\$_) for @msgs;



      if ( $LEOCHARRE::DEBUG::USE_COLOR or ($debug_level > 2) ){
         require Term::ANSIColor;
         $Term::ANSIColor::AUTORESET = 1;
         #$LEOCHARRE::DEBUG::USE_COLOR ||= 'green';
	      print STDERR Term::ANSIColor::colored ("@msgs", 
            ($LEOCHARRE::DEBUG::USE_COLOR=~/[a-z]/ ? $LEOCHARRE::DEBUG::USE_COLOR :  'green'));
      }
      else {
         print STDERR "@msgs";
      }
	   return 1;
   };
}

# new stuff
sub __cleanup_message {
   my $mref = shift;
   $$mref=~s/\.$/\.\n/;
   #$$mref=~s/^([A-Z])/\n$1/;
   1;
}

sub __resolve_debug_level { # show whole namespace or none
   my $pkg = shift;
   # return 0, 1, 2
   

   no strict 'refs';

   ${"$pkg\::DEBUG"} or return 0;


   ( $LEOCHARRE::DEBUG::DEBUG_SHOW_WHOLE_NAMESPACE
      or ( ${"$pkg\::DEBUG"} > 1 ))
      and return 2;


   #${"$pkg\::DEBUG"} == 1 and return 1;
   1;


}

sub __resolve_one_message {
   my $msg = shift;
   
   if( ( ref $msg ) and (( ref $msg eq 'ARRAY' ) or (ref $msg eq 'HASH')) ){
      require Data::Dumper;
      my $msg2 = Data::Dumper::Dumper($msg);
      return $msg2;
   }
   elsif ( ref $msg ){ # method of package .. ?
      return;
   }
   return $msg;
}



# end new stuff

sub import {
    ## find out who is calling us
    my $pkg = caller;

    for (@_){
      if ($_=~/use_color/){
         $LEOCHARRE::DEBUG::USE_COLOR = 'dark';
      }
    }

    ## while strict doesn't deal with globs, it still
    ## catches symbolic de/referencing
    no strict 'refs';


    #print STDERR "  [$pkg]\n";

    ## iterate through all the globs in the symbol table
  #  foreach my $glob (keys %LEOCHARRE::DEBUG::) {
        ## skip anything without a subroutine and 'import'
   #     next if not defined *{$LEOCHARRE::DEBUG::{$glob}}{CODE}
    #            or $glob eq 'import';

        ## assign subroutine into caller's package
       # *{$pkg . "::$glob"} = \&{"LEOCHARRE::DEBUG::$glob"};
   # }

   my ($D1,$D2,$D3,$D4) =(0,1,0,0);
   
   *{"$pkg\::DEBUG"} = __DEBUG($pkg);
   #*{"$pkg\::debug"} = __debug($pkg);
   *{"$pkg\::debug"} = __debug_smaller($pkg);
  
   *{"$pkg\::DEBUG"} = \$D1; #0;
   *{"$pkg\::_DEBUG_SHOW_NAMESPACE"} = \$D2; #1;
   *{"$pkg\::_DEBUG_LAST_CALLER"} = \$D3;#$0;
   *{"$pkg\::_DEBUG_SHOW_WHOLE_NAMESPACE"} = \$D4 ;# 0;
   *{"$pkg\::__resolve_one_message"} = \&__resolve_one_message;
   *{"$pkg\::__resolve_debug_level"} = \&__resolve_debug_level;
   *{"$pkg\::__cleanup_message"} = \&__cleanup_message;


   *{"$pkg\::debug_detect_cliopt"} = 
   sub {
      for (@ARGV){
         if ($_ eq '-d'){
            ${"$pkg\::DEBUG"} = 1;
            last;
         }
      }
   };



   # if we are being imported by a script (main) and there is and -d @ARGV, then turn debug on


   #if ($pkg eq 'main'){
    #  if ( "@ARGV"=~/[\s|]-d[\s|]/ ){
     #    ${"$pkg\::DEBUG"} = 1;
     # }
   #}

   # ABUSE CALLING PACKAGE, these are scalars we want
  # for (qw(DEBUG _DEBUG_SHOW_NAMESPACE _DEBUG_SHOW_WHOLE_NAMESPACE _DEBUG_LAST_CALLER)){
   #   my $glob = $_;   
   #   *{$pkg . "::$glob"} = \${"LEOCHARRE::DEBUG::$glob"};
  # }    
}











1;

=pod

=head1 NAME

LEOCHARRE::DEBUG - deprecated

=head1 SYNOPSIS

In A.pm

   package A;
   use LEOCHARRE::DEBUG;
   use strict;


   sub new {
      my $class = shift;
      my $self ={};
      bless $self, $class;
      return $self;   
   }

   sub test {
      my $self = shift;
      DEBUG or return 0;
      debug('ok .. i ran.');
      
      debug('ok .. i am more verbose.',2); # shows only if DEBUG level is 2 or more
      
      return 1;
   }

In script.t

   use Test::Simple 'no_plan';
   use strict;
   use A;

   my $o = new A;

   $A::DEBUG = 1;
   ok( $o->test );

   $A::DEBUG = 0;
   ok( !($o->test) );

=pod

=head1 DESCRIPTION

Deprecated. Use L<LEOCHARRE::Debug> instead.

=head1 USING COLOR

requires Term::ANSIColor
use color..

   use LEOCHARRE::DEBUG 'use_color';
   DEBUG 1;
   debug('i am gray');

by default we use 'dark'
if you want to change..

$LEOCHARRE::DEBUG::USE_COLOR = 'red';

Also..

   use LEOCHARRE::DEBUG;
   $LEOCHARRE::DEBUG::USE_COLOR = 'red';
   debug('i am red'); 


=head1 DEBUG()

set and get accessor
returns number
this is also the debug level. 
if set to 0, no debug messages are shown.

   print STDERR "oops" if DEBUG;

=head1 debug_detect_cliopt()

inspects the @ARGV and if there's a '-d' opt, sets debug to 1

=head1 debug()

argument is message, will only print to STDERR if DEBUG is on.
optional argument is debug level that must be on for this to print, it is assumed
level 1 (DEBUG on) if none passed.

   package My:Mod;
   use LEOCHARRE::DEBUG;
   
   My::Mod::DEBUG = 1;
   
   debug('only show this if DEBUG is on');
   # same as:
   debug('only show this if DEBUG is on',1);
   
   debug('only show this if DEBUG is on',2); # will not show, debug level is 1

   My::Mod::DEBUG = 2;   
   debug('only show this if DEBUG is on',2); # will show, debug level is 2
   debug('only show this if DEBUG is on'); # will also show, debug level is at least 1
   
   debug('only show this if DEBUG is on',3); # will not show, debug level is not 3 or more.
   
   My::Mod::DEBUG = 0; 
   debug('only show this if DEBUG is on'); # will not show, debug is off
   debug('only show this if DEBUG is on',3); # will not show, debug is off

   

   
   

   

If your message argument does not end in a newline, next message will not be prepended with
the subroutine name.

   sub dostuff {
      debug("This is..");

      # ...

      debug("done.\n");

      debug("ok?");      
   }

Would print

   dostuff(), This is.. done.
   dostuff(), ok?



=head1 DESCRIPTION

I want to be able in my code to do this


   package My::Module;
   
   sub run {
      print STDERR "ok\n" if DEBUG;
   }     
   
   
   package main;
   
   $My::Module::DEBUG = 1;
   
   My::Module::run();

And I am tired of coding this

   $My::ModuleName::DEBUG = 0;
   sub DEBUG : lvalue { $My::ModuleName::DEBUG }

Using this module the subroutine DEBUG will return true or false, and it can be set via the
namespace of the package using it.

=head1 NOTES

This package, alike LEOCHARRE::CLI, are under the author's name because the code herein comprises 
his particular mode of work. These modules are used throughout his works, and in no way interfere
with usage of those more general modules.

=head1 DEBUG level

If DEBUG is set to at least "1", messages are shown as long as they are debug level 1.
If you do not specify a debug level to debug(), 1 is assumed.

   $MYMOD::DEBUG = 0;

Show at least debug() calls with argument 2

   $MYMOD::DEBUG = 2;
   

Show at least debug() with argument 3

   $MYMOD::DEBUG = 3;


=head2 DEBUG tags

What if you want to show only messages that match a tag?
If you pass a tag label starting in a letter and specify in DEBUG..
   
   $MYMOD::DEBUG = 'a';

   debug('hi'); # will not show

   debug('hi','a'); # WILL show

   debug('hi','b'); # will not show
   debug('hi',2); # will not show


=head1 SEE ALSO

L<LEOCHARRE::CLI>
L<LEOCHARRE::Debug>

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 COPYRIGHT

Copyright (c) 2009 Leo Charre. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.
   
=cut
