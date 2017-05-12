package HyperWave::CSP::Message;
#
# Copes with Messages for HyperWave
# 
# Copyright (c) 1998 Bek Oberin.  All rights reserved.
# 
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# Last updated by gossamer on Fri Mar 20 21:26:20 EST 1998
#

#
# NB:  People have to input the 'data' part in the format
#      they want it to be, we don't format that bit.
#

use strict;

use Carp;

my $MSGID = 86;

#
# Constructor 
# optionally takes command, data and msgid arguments in which
# case it builds a new command
#
sub new {
   my $proto = shift;
   my $command = shift;
   my $data = shift;
   my $msgid = shift;

   my $class = ref($proto) || $proto;
   my $self  = {};

   $self->{"length"} = undef;
   $self->{"length_set"} = 0;
   $self->{"msgtype"} = undef;
   $self->{"data"} = undef;
   $self->{"msgid"} = undef;
   if ($command) {
      $self->{"msgtype"} = $command;
      if ($data) {
         $self->{"data"} = $data;
      }
      if ($msgid) {
         $self->{"msgid"} = $msgid;
      } else {
         $self->{"msgid"} = $MSGID++;
      }
   }

   bless($self, $class);
   return $self;
}

#
# destructor
#
sub DESTROY {
   # nothing yet
}

#
# Data
#

#
# methods to access per-object data 
#
# With args, they set the value.  Without any, they only retrieve it/them.  
#

sub length {
   my $self = shift;

   if (@_) {
      # set it
      $self->{"length"} = shift;
      $self->{"length_set"} = 1;
   } else {
      # return it
      if (!$self->{"length"}) {
         # NB:  The 11 is the number of the self->length_formatted() plus
         # the separating space.  Has to be done this way to avoid getting
         # into a repeating loop.
         $self->{"length"} = 11 + length($self->msgid_formatted() . " " .  $self->msgtype_formatted . " " .  $self->data_formatted());
      }
   }

   return $self->{"length"};
}

sub length_formatted {
   my $self = shift;
  
   return sprintf("%10d", $self->length());

}

sub msgid {
   my $self = shift;

   # set it
   if (@_) {
      $self->{"msgid"} = shift;
      $self->{"length"} = undef unless $self->{"length_set"};
   }
   return $self->{"msgid"};
}

sub msgid_formatted {
   my $self = shift;
   
   return $self->msgid();

}

sub msgtype {
   my $self = shift;
   if (@_) {
      $self->{"msgtype"} = shift;
      $self->{"length"} = undef unless $self->{"length_set"};
   }
   return $self->{"msgtype"};
}

sub msgtype_formatted {
   my $self = shift;
   
   return $self->msgtype();

}

#sub msgtype_string {
#   my $self = shift;
#   return $message_types[$self->{"msgtype"}];
#}

sub data {
   my $self = shift;
   if (@_) {
      $self->{"data"} = shift;
      $self->{"length"} = undef unless $self->{"length_set"};
   }
   return $self->{"data"};
}

sub data_formatted {
   my $self = shift;

   return $self->data();
}

sub as_string {
   my $self = shift;
   my $tmp;

   if (!defined($self->{"length"})) {
      $self->length();
      # This just makes sure it's set.
   }
   
   return
      $self->length_formatted() . " " .
      $self->msgid_formatted() . " " .
      $self->msgtype_formatted . " " .
      $self->data_formatted();
}

#
# Debug function only!!
#
sub dump {
   my $self = shift;
   my $text = shift;

   print(STDERR "DUMPING Message $self\n");
   print(STDERR ">>$text<<\n") if $text;
   print(STDERR "length = " . dumpvar::stringify($self->{"length"}) . "\n");
   print(STDERR "msgid = " . dumpvar::stringify($self->{"msgid"}) . "\n");
   print(STDERR "msgtype = " . dumpvar::stringify($self->{"msgtype"}) . "\n");
   print(STDERR "data = " . dumpvar::stringify($self->{"data"}) . "\n");
   print(STDERR "END DUMP.\n");
}


#
# End.
#
1;  # so the require or use succeeds
