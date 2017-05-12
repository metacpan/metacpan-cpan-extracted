package Festival::Client;
#
# Perl interface to the Festival server
#
# The basis for this code came from the festival_client.pl program by
# Kevin A. Lenzo (lenzo@cs.cmu.edu) which comes with the Festival
# distribution.
#
# Last updated by gossamer on Thu May 21 16:11:24 EST 1998
#

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

use Symbol;
use Fcntl;
use Carp;
use IO::Socket;

require 'dumpvar.pl';

@ISA = qw(Exporter);
@EXPORT = qw( Default_Client_PORT );
@EXPORT_OK = qw();
$VERSION = "1.0";

=head1 NAME

Festival::Client - Communicate with a Festival server

=head1 SYNOPSIS

   use Festival::Client;
     
   $Festival = Festival::Client->New("my.festival.server");
   $Festival->say("Something to say");

=head1 DESCRIPTION

C<Festival> is a class implementing a simple Festival client in
Perl.

=cut

###################################################################
# Some constants                                                  #
###################################################################

my $Default_Festival_Port = 1314;

my $Client_Info = "0.01";

my $DEBUG = 0;

###################################################################
# Functions under here are member functions                       #
###################################################################

=head1 CONSTRUCTOR

=item new ( [ HOST [, PORT ] ] )

This is the constructor for a new Festival object. C<HOST> is the
name of the remote host to which a Festival connection is required.

C<PORT> is the Festival port to connect to, it defaults to the
standard port 1314 if nothing else is found.

The constructor returns the open socket, or C<undef> if an error has
been encountered.

=cut

sub new {
   my $prototype = shift;
   my $host = shift;
   my $port = shift;

   my $class = ref($prototype) || $prototype;
   my $self  = {};

   warn "new\n" if $DEBUG > 1;

   $self->{"host"} = $host || $ENV{HWHOST} || $ENV{HGHOST} || 'localhost';
   $self->{"port"} = $port || $ENV{HWPORT} || $ENV{HGPORT} || $Default_Festival_Port;

   #
   # Resolve things and open the connection
   #

   # Deal with a port specified from /etc/services list
   if ($self->{"port"} =~ /\D/) { 
      $self->{"port"} = getservbyname($self->{"port"}, 'tcp');
   }

   print "Addr: " . $self->{"host"} . ", Port: " . $self->{"port"} . "\n" if $DEBUG;
   $self->{"socket"} = new IO::Socket::INET (
       Proto    => "tcp",
       PeerAddr => $self->{"host"},
       PeerPort => $self->{"port"},
   );

   #croak "new: connect socket: $!" unless $self->{"socket"};
   return 0 unless $self->{"socket"};

   bless($self, $class);
   return $self;
}


#
# destructor
#
sub DESTROY {
   my $self = shift;

   warn "DESTROY\n" if $DEBUG > 1;

   shutdown($self->{"socket"}, 2);
   close($self->{"socket"});

   return 1;
}


=head1 SAY ( TEXT )

The obvious.

=cut

sub say {
   my $self = shift;
   my $text = shift;

   warn "say \"$text\"\n" if $DEBUG > 1;

   my $buffer = "(SayText \"$text\")\n";
   
   if (!defined(syswrite($self->{"socket"}, $buffer, length($buffer)))) {
      warn "syswrite: $!";
      return 0;
   }
   
   return 1;
}


=pod

=head1 AUTHOR

Bek Oberin <gossamer@tertius.net.au>

=head1 COPYRIGHT

Copyright (c) 1998 Bek Oberin.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#
# End code.
#
1;
