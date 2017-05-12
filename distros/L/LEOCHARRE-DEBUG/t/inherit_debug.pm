package inherit_debug;
use lib './lib';
use LEOCHARRE::DEBUG;
use strict;


sub new {

   my $class = shift;
   my $self ={};
   bless $self, $class;
   return $self;   
}

sub debug_is_on {
   my $self = shift;
   debug("as func\n");   
   $self->debug("as method\n");
   DEBUG or return 0;
   return 1;
}


sub change_callers {
   my $self = shift;

   $self->misc_method;
   $self->haha_method;
   $self->misc_method;
   $self->misc_method;
   $self->haha_method;   

   return 1;
}


sub misc_method {
   my $self = shift;
   debug("hi there");

   debug("nice.\n");
   return 1;
}

sub haha_method {
   my $self = shift;
   debug("haha..");

   $self->misc_method;
   debug("ha.\n");
   return 1;
}



1;
