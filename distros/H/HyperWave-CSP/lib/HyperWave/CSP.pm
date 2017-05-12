package HyperWave::CSP;
#
# Perl interface to the HyperWave server
# 
# Copyright (c) 1998 Bek Oberin.  All rights reserved.
# 
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
# 
#
# Last updated by gossamer on Fri Mar 20 21:24:44 EST 1998
#

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

use HyperWave::CSP::Message;

use Socket;
use Symbol;
use Fcntl;
use Carp;
use Locale::Language;

require 'dumpvar.pl';

@ISA = qw(Exporter);
@EXPORT = qw( Default_CSP_PORT );
@EXPORT_OK = qw();
$VERSION = "0.03.1";

#
# Debug Levels:
#   0.  Nothing
#   1.  See full explanations of any errors
#   2.  See entering of functions
#   3.  See what's sent and received and a bunch more info
#
my $DEBUG = 0;

=head1 NAME

HyperWave::CSP - Communicate with a HyperWave server

=head1 SYNOPSIS

   use HyperWave::CSP;
     
   $server = HyperWave::CSP->New("my.hyperwave.server");
   $server->quit;

=head1 DESCRIPTION

C<HyperWave> is a class implementing a simple HyperWave client in
Perl.

=cut

###################################################################
# Some constants                                                  #
###################################################################

my $Default_CSP_Port = 418;

my $Client_Info = "Perl Module HyperWave::CSP v$VERSION";

# Which version of the HyperWave protocol we recognize.
my $Protocol_Version = "717L";

# Hyperwave message numbers
my %MESSAGE = (
   GETDOCBYANCHOR => 2,
   GETCHILDCOLL => 3,
   GETPARENT => 4,
   GETCHILDDOCCOLL => 5,
   GETOBJECT => 7,
   GETANCHORS => 8,
   GETOBJBYQUERY => 9,
   GETOBJBYQUERYCOLL => 10,
   OBJECTBYIDQUERY => 11,
   GETTEXT => 12,
   INSDOC => 14,
   INSCOLL => 17,
   GETSRCSBYDEST => 19,
   MVCPDOCSCOLL =>  22,
   MVCPCOLLSCOLL =>  23,
   IDENTIFY =>  24,
   READY =>  25,
   COMMAND =>  26,
   CHANGEOBJECT => 27,
   EDITTEXT =>  28,
   GETANDLOCK =>  29,
   UNLOCK =>  30,
   INCOLLECTIONS =>  31,
   INSERTOBJECT =>  32,
   INCOLLSCLUSTER =>  33,
   GETOBJBYFTQUERY =>  34,
   GETOBJBYFTQUERYCOLL =>  35,
   PIPEDOCUMENT =>  36,
   DELETEOBJECT =>  37,
   PUTDOCUMENT =>  38,
   GETREMOTE =>  39,
   GETREMOTECHILDREN => 40,
   PIPEREMOTE => 41,
   HG_BREAK => 42,
   HG_MAPID => 43,
   CHILDREN => 44,
   GETCGI => 45,
   PIPECGI => 46,
   );

my @SERVER_ERRORS = (
   "Access denied",
   "No documents?",
   "No collection name",
   "Object is not a document",
   "No object received",
   "No collections received",
   "Connection to low-level database failed",
   "Object not found",
   "Collection already exists",
   "Father collection disappeared",
   "Father collection not a collection",
   "Collection not empty",
   "Destination not a collection",
   "Source equals destination",
   "Request pending",
   "Timeout",
   "Name not unique",
   "Database now read-only; try again later",
   "Object locked; try again later",
   "Change of base-attribute",
   "Attribute not removed",
   "Attribute exists",
   "Syntax error in command",
   "No or unknown language specified",
   "Wrong type in object",
   "Client version too old",
   "No connection to other server",
   "Synchronization error",
   "No path entry",
   "Wrong path entry",
   "Wrong password (server-to-server server authentication)",
   "No more users for license",
   "No more documents for this session and license",
   "Remote server not responding",
   "Query overflow",
   "Break by user",
   "Not implemented",
   "No connection to fulltext server",
   "Connection timed out",
   "Something wrong with fulltext index",
   "Query syntax error",
   "No error",
   "Request pending",
   "No connection to document server",
   "Wrong protocol version",
   "Not initialized",
   "Bad request",
   "Bad document number",
   "Cannot write to local store",
   "Cannort read from local store",
   "Store read error",
   "Write error",
   "Close error",
   "Bad path",
   "No path",
   "Cannot open file",
   "Cannot read from file",
   "Cannot write to file",
   "Could not connect to client",
   "Could not accept connect to client",
   "Could not read from socket",
   "Could not write to socket",
   "-- (unused) --",
   "Received too much data",
   "Received too few data",
   "-- (unused) --",
   "Not implemented",
   "User break",
   "Internal error",
   "Invalid object",
   "Job timed out",
   "Cannot open port",
   "Received no data",
   "No port to handle this request",
   "Document not cached",
   "Bad cache type",
   "Cannot write to cache",
   "Cannot read from cache",
   "Do not know what to read",
   "Could not insert into cache",
   "Could not connect to remote server",
   "Lock refused"
);


###################################################################
# Functions under here are member functions                       #
###################################################################

=head1 CONSTRUCTOR

=item new ( [ HOST [, PORT [, USERNAME [, PASSWORD [, ENCRYPT [, LANGUAGE ] ] ] ] ] ] )

This is the constructor for a new HyperWave object. C<HOST> is the
name of the remote host to which a HyperWave connection is required.
If not given the environment variables C<HWHOST> and then C<HGHOST>
are checked, and if a host is not found then C<localhost> is used.

C<PORT> is the HyperWave port to connect to, it defaults to the
environment variable C<HWPORT>, then C<HGPORT> and then to the
standard port 418 if nothing else is found.

C<USERNAME> and C<PASSWORD> are the HyperWave username and password,
they default to anonymous.  C<ENCRYPT> will eventually allow you to
pass the password in in encrypted form rather than plaintext, but is
not yet implemented.

C<LANGUGAE> also is not yet used, and defaults to the value of the
environment variable C<HWLANGUAGE> and then to English.

The constructor returns the open socket, or C<undef> if an error has
been encountered.

=cut

sub new {
   my $proto = shift;
   my $host = shift;
   my $port = shift;
   my $username = shift || "guest";
   my $password = shift || "none";
   my $encrypt = shift || 0;
   my $language = shift;

   my $class = ref($proto) || $proto;
   my $self  = {};

   warn "new\n" if $DEBUG > 1;

   $self->{"host"} = $host || $ENV{HWHOST} || $ENV{HGHOST} || 'localhost';
   $self->{"port"} = $port || $ENV{HWPORT} || $ENV{HGPORT} || $Default_CSP_Port;
   $self->{"language"} = 
      &language2code($language || $ENV{HWLANGUAGE} || 'English');
   if (!defined($self->{"language"})) {
      warn "new:  Unknown language name\n" if $DEBUG;
      $self->{"error"} = "0.02";
      return undef;
   }

   $self->{"error"} = "0.02";
   $self->{"server_error"} = 0;

   #
   # Resolve things and open the connection
   #
   if (!($self->{"socket"} = &_open_hw_connection($self->{"host"}, $self->{"port"}))) {
      warn "new: _open_hw_connection returned 0\n" if $DEBUG;
      $self->{"error"} = "0.02";
      return undef;
   }

   #
   # Initialize connection
   #
   my $message;
   if (!($message = &_initialize_hw_connection($self->{"socket"}))) {
       warn "new: _initialize_hw_connection returned 0\n" if $DEBUG;
       $self->{"error"} = "0.02";
       close($self->{"socket"});
       return undef;
   }

   $self->{"Protocol_Version"} = $message->msgid;
   if ($message->msgid < $Protocol_Version) {
      warn "new:  server version '" . $message->msgid . 
           "' less than client version '$Protocol_Version'." if $DEBUG;
   }

   #
   # Identify ourselves
   #
   $message = 
      HyperWave::CSP::Message->new($MESSAGE{"IDENTIFY"}, &_hw_int($encrypt) .
         &_hw_string($username) . 
         &_hw_string($password) . 
         &_hw_string($Client_Info));

   if (!&_send_hw_msg($self->{"socket"}, $message)) {
      $self->{"error"} = "0.02";
      warn "new: _send_hw_msg returned 0\n";
      return undef;
   }

   $message = &_receive_hw_msg($self->{"socket"});
   if (!$message) {
      $self->{"error"} = "0.02";
      warn "new: _receive_hw_msg returned 0\n";
      return undef;
   }
   my ($userid, $user) = $message->data =~ m/^(\S+) (\S+)\0$/;
   $self->{"userid"} = $userid;
   $self->{"username"} = $user;

   warn "new: username '$user' id '$userid' returned by server\n" if $DEBUG > 2;

   bless($self, $class);
   return $self;
}


#
# destructor
#
sub DESTROY {
   my $self = shift;

   shutdown($self->{"socket"}, 2);
   close($self->{"socket"});

   return 1;
}


=head1 METHODS

Unless otherwise stated all methods return either a I<true> or
I<false> value, with I<true> meaning that the operation was a success.
When a method states that it returns a value, failure will be returned
as I<undef> or an empty list.

=cut

sub command {
   my $self = shift;
   my $command = shift;
   my $response_required = shift;
   my $extra_data = shift;

   my $data;
   my $respond = 1;

   warn "command\n" if $DEBUG > 1;

   if (!$command) {
      warn "command: no command specified";
      return 0;
   } else {
      $data = &_hw_int($respond) . &_hw_string($command);
   }

   my $message = HyperWave::CSP::Message->new($MESSAGE{"COMMAND"}, $data);

   if (!&_send_hw_msg($self->{"socket"}, $message)) {
      $self->{"error"} = "0.02";
      warn "command: _send_hw_msg returned 0\n";
      return 0;
   }

   if ($response_required) {
      $message = &_receive_hw_msg($self->{"socket"});
      if (!$message) {
         $self->{"error"} = "0.02";
         warn "command: _receive_hw_msg returned 0\n";
         return 0;
      }
      return $message->{"data"};

   } else {
      return 1;
   }
}

=pod

=item command_stat ( )

Returns string containing various statistics for the server.

=item command_ftstat ( )

Returns string containing various statistics for the server.

=item command_dcstat ( )

Returns string containing various statistics for the server.

=item command_who ( )

Returns string containing current users for the server.

=cut

sub command_stat {
   my $self = shift;
   return $self->command("stat", 1);
}

sub command_ftstat {
   my $self = shift;
   return $self->command("ftstat", 1);
}

sub command_dcstat {
   my $self = shift;
   return $self->command("dcstat", 1);
}

sub command_who {
   my $self = shift;
   return $self->command("who", 1);
}

=pod

=item get_objnum_by_name ( NAME )

Returns object number for the document with NAME as an attribute, 
or false on error.

=cut

sub get_objnum_by_name {
   my $self = shift;
   my $object_name = shift;

   my $count;
   my $objids;

   warn "get_objnum_by_name\n" if $DEBUG > 1;

   my $message = HyperWave::CSP::Message->new($MESSAGE{"GETOBJBYQUERY"},
                                         &_hw_string("Name=$object_name"));

   if (!&_send_hw_msg($self->{"socket"}, $message)) {
      warn "get_objnum_by_name: _send_hw_msg returned 0\n";
      $self->{"error"} = "0.02";
      return 0;
   }

   $message = &_receive_hw_msg($self->{"socket"});
   if (!$message) {
      warn "get_objnum_by_name: _receive_hw_msg returned 0\n";
      $self->{"error"} = "0.02";
      return 0;
   }

   ($self->{"server_error"}, $count, my $tmp, $objids) = 
      $message->data =~ /^(\d+) (\d+)( (.*))?$/;
   if ($self->{"server_error"}) {
      $self->{"error"} = "0.02";
      return 0;
   }

   if ($count = 0) {
      warn "get_objnum_by_name: no objects found.\n";
      $self->{"error"} = "0.02";
      return 0;
   } elsif ($count > 1) {
      warn "get_objnum_by_name: more than one object found where 1 expected.\n";
      $self->{"error"} = "0.02";
      return 0;
   }
   return $objids;

}


=pod

=item get_url ( OBJNUM )

Returns a guess at a URL that might work for the document OBJNUM to be
retreived via the HyperWave HTTP interface.  Note that it is ONLY
a guess.  For one thing, it depends on the HyperWave server running
a web interface on the default HTTP port.

=cut
sub get_url {
   my $self = shift;
   my $objnum = shift;

   warn "get_url\n" if $DEBUG > 1;

   my $objrecord;

   if (!($objrecord = $self->get_attributes($objnum))) {
      $self->{"error"} = "0.02";
      warn "get_url: get_attributes returned 0";
      return 0;
   }
   my %attributes;
   $attributes{$1}=$2 while $objrecord =~ m/(.+)=(.+)\n?/g;

   return "http://" . $self->{"host"} . "/" . $attributes{'Name'};

}


=pod

=item get_attributes ( OBJNUM )

Returns a string containing the attributes for OBJNUM.  The string
is in form C<key1=value1\nkey2=value2\n...>.

=cut
sub get_attributes {
   my $self = shift;
   my $objnum = shift;

   my $objrecord;

   warn "get_attributes\n" if $DEBUG > 1;

   my $message = HyperWave::CSP::Message->new($MESSAGE{"GETOBJECT"},
                                         &_hw_int($objnum));

   if (!&_send_hw_msg($self->{"socket"}, $message)) {
      warn "get_attributes: _send_hw_msg returned 0\n";
      $self->{"error"} = "0.02";
      return 0;
   }

   $message = &_receive_hw_msg($self->{"socket"});
   if (!$message) {
      warn "get_attributes: _receive_hw_msg returned 0\n";
      $self->{"error"} = "0.02";
      return 0;
   }

   ($self->{"server_error"}, $objrecord) = $message->data =~ /^(\d+) (.*)\0$/s;
   if ($self->{"server_error"} != 0) {
      warn "Error '" . $self->{"server_error"} . "' from HyperWave.\n";
      $self->{"error"} = "0.02";
      return 0;
   }

   return $objrecord;

}

=pod

=item get_attributes_hash ( OBJNUM )

Like get_attributes() except that the attributes are returned as a 
hash.

=cut
sub get_attributes_hash {
   my $self = shift;
   my $objnum = shift;

   warn "get_attributes_hash\n" if $DEBUG > 1;

   my $attributes = $self->get_attributes($objnum);
   if (!$attributes) {
      warn "get_attributes_hash: get_attributes returned 0\n";
      $self->{"error"} = "0.02";
      return 0;
   }

   my %attributes;

   $attributes{$1}=$2 while $attributes =~ m/(.+?)=(.+)\n?/g;

   return %attributes;
}


=pod

=item get_text ( OBJNUM )

Returns body text for the objnum passed.  This usually means HTML
sans anchors in practical terms.

=cut
sub get_text {
   my $self = shift;
   my $objnum = shift;

   my $text;

   warn "get_text\n" if $DEBUG > 1;

   my $objrecord = $self->get_attributes($objnum);

   warn "objrecord: '$objrecord'\n" if $DEBUG > 2;

   my $message = HyperWave::CSP::Message->new($MESSAGE{"GETTEXT"},
                                         &_hw_string($objrecord));

   if (!&_send_hw_msg($self->{"socket"}, $message)) {
      $self->{"error"} = "0.02";
      warn "get_text: _send_hw_msg returned 0\n";
      return 0;
   }

   $message = &_receive_hw_msg($self->{"socket"});
   if (!$message) {
      $self->{"error"} = "0.02";
      warn "get_text: _receive_hw_msg returned 0\n";
      return 0;
   }

   ($self->{"server_error"}, $text) = $message->data =~ /^(\d+) (.*)\0$/s;
   if ($self->{"server_error"} != 0) {
      $self->{"error"} = "0.02";
      warn "Error '" . $self->{"server_error"} . "' from HyperWave.\n";
      return 0;
   }

   return $text;
}

=pod

=item get_html ( OBJNUM )

Returns HTML text, including anchors, for the objnum passed.

=cut
sub get_html {
   my $self = shift;
   my $objnum = shift;

   my %anchors;

   warn "get_html\n" if $DEBUG > 1;

   my %doc_attributes = $self->get_attributes_hash($objnum);

   # TODO this next isn't proper language handling!
   my $title = $doc_attributes{'Title'} =~ s/^en://;

   my $html = $self->get_text($objnum);

   # sort anchors
   my $anchors = $self->get_anchors($objnum);
   if (!$anchors) {
      warn "get_html: get_anchors returned 0\n";
      return 0;
   }

   foreach my $anchor (split(/\s+/,$anchors)) {
      my %attributes = $self->get_attributes_hash($anchor);
      my $position = $attributes{'Position'};
      $anchors{$position} = \%attributes;
   }

   # Add in anchors
   foreach my $position (reverse sort keys %anchors) {
      my %attributes = %{$anchors{$position}};
      my ($startpos, $endpos) = $attributes{'Position'} =~ m/(\S*) (\S*)/;

      warn "finding anchors from " . 
         dumpvar::stringify(%attributes) . "\n" if $DEBUG > 2;

      if ($attributes{'LinkType'} eq 'intag') {
         # internal links
         my $tagattr = $attributes{'TagAttr'};
         my $dest = $self->get_url(hex($attributes{'Dest'}));

         warn "get_html:  we think it's a picture at '$dest'\n" if $DEBUG > 2;

         substr($html, hex($endpos), 0) = "0.02\"$dest\"";
      } elsif ($attributes{'Hint'}) {
         # external link
         my $url;
         ($url) = $attributes{'Hint'} =~ m/URL:(.*)/;

         warn "get_html:  we think it's an external URL to '$url'\n" if $DEBUG > 2;

         substr($html, hex($endpos), 0) = "0.02";
         substr($html, hex($startpos), 0) = "0.02\"$url\">";
      } elsif ($attributes{'Dest'}) {
         # internal links
         my $url = $self->get_url(hex($attributes{'Dest'}));

         warn "get_html:  we think it's an internal link to '$url'\n" if $DEBUG > 2;
         
         substr($html, hex($endpos), 0) = "0.02";
         substr($html, hex($startpos), 0) = "0.02\"$url\">";
      } elsif ($attributes{'Dest'} eq 'Anchor') {
         # external link
         my $url = $self->get_url(hex($attributes{'Dest'}));

         warn "get_html:  we think it's an external anchor to '$url'\n" if $DEBUG > 2;

         substr($html, hex($endpos), 0) = "0.02";
         substr($html, hex($startpos), 0) = "0.02\"$url\">";
      } else {
         # Umm??
         $self->{"error"} = "0.02";
         warn "get_html:  unknown link:\n" if $DEBUG;

         substr($html, hex($endpos), 0) = "0.02";
         substr($html, hex($startpos), 0) = "0.02\"???\">";
      }

   }

   # TODO: Headers?  <BODY> tag stuff?
   $html =~ s@^@<HTML>\n<HEAD>\n<TITLE>$title</TITLE>\n</HEAD>\n<BODY>\n@;

   return $html;
}

=pod

=item exec_cgi ( OBJNUM )

Returns output of the CGI, for the objnum passed.  Depends on the
CGI script not requiring input.

=cut
sub exec_cgi {
   my $self = shift;
   my $objnum = shift;

   my $text;

   my $objrecord = $self->get_attributes($objnum);

   my $message = HyperWave::CSP::Message->new($MESSAGE{"GETCGI"},
                                         $objrecord);

   if (!&_send_hw_msg($self->{"socket"}, $message)) {
      warn "exec_cgi: _send_hw_msg returned 0\n";
      $self->{"error"} = "0.02";
      return 0;
   }

   $message = &_receive_hw_msg($self->{"socket"});
   if (!$message) {
      $self->{"error"} = "0.02";
      warn "exec_cgi: _receive_hw_msg returned 0\n";
      return 0;
   }

   ($self->{"server_error"}, $text) = $message->data =~ /^(\d+) (.*)\0$/s;
   if ($self->{"server_error"} != 0) {
      warn "Error '" . $self->{"server_error"} . "' from HyperWave.\n";
      $self->{"error"} = "0.02";
      return 0;
   }

   return $text;
}

=pod

=item insert_attribute ( OBJNUM, NAME, VALUE )

Adds an attribute to the given objnum.  Note that HyperWave allows
multiple attributes of the same name, so if you add an attribute that
already exists you'll end up with two.  Use change_attribute if you
want to overwrite the old one.

=cut
sub insert_attribute {
   my $self = shift;
   my $objnum = shift;
   my $atrname = shift;
   my $atrvalue = shift;

   my $message = HyperWave::CSP::Message->new($MESSAGE{"CHANGEOBJECT"},
                                         "add $atrname=$atrvalue");

   if (!&_send_hw_msg($self->{"socket"}, $message)) {
      warn "insert_attribute: _send_hw_msg returned 0\n";
      $self->{"error"} = "0.02";
      return 0;
   }

   $message = &_receive_hw_msg($self->{"socket"});
   if (!$message) {
      warn "insert_attribute: _receive_hw_msg returned 0\n";
      $self->{"error"} = "0.02";
      return 0;
   }

   ($self->{"server_error"}) = $message->data =~ /^(\d+)$/s;
   if ($self->{"server_error"} != 0) {
      warn "Error '" . $self->{"server_error"} . "' from HyperWave.\n";
      $self->{"error"} = "0.02";
      return 0;
   }

   return 1;
}


=pod

=item remove_attribute ( OBJNUM, NAME, VALUE )

Removes an attribute to the given objnum.  Note that you DO need to
know the old value because HyperWave allows multiple attributes with
the same value.

=cut
sub remove_attribute {
   my $self = shift;
   my $objnum = shift;
   my $atrname = shift;
   my $atrvalue = shift;

   my $message = HyperWave::CSP::Message->new($MESSAGE{"CHANGEOBJECT"},
                                         "rem $atrname=$atrvalue");

   if (!&_send_hw_msg($self->{"socket"}, $message)) {
      warn "remove_attribute: _send_hw_msg returned 0\n";
      $self->{"error"} = "0.02";
      return 0;
   }

   $message = &_receive_hw_msg($self->{"socket"});
   if (!$message) {
      warn "remove_attribute: _receive_hw_msg returned 0\n";
      $self->{"error"} = "0.02";
      return 0;
   }

   ($self->{"server_error"}) = $message->data =~ /^(\d+)$/s;
   if ($self->{"server_error"} != 0) {
      warn "Error '" . $self->{"server_error"} . "' from HyperWave.\n";
      $self->{"error"} = "0.02";
      return 0;
   }

   return 1;
}

=pod

=item change_attribute ( OBJNUM, NAME, OLD_VALUE, NEW_VALUE )

Alters an attribute to the given objnum (NB: needs to know old value).

=cut
sub change_attribute {
   my $self = shift;
   my $objnum = shift;
   my $atrname = shift;
   my $atroldvalue = shift;
   my $atrnewvalue = shift;

   my $message = HyperWave::CSP::Message->new($MESSAGE{"CHANGEOBJECT"},
                    "rem $atrname=$atroldvalue\add $atrname=$atrnewvalue");

   if (!&_send_hw_msg($self->{"socket"}, $message)) {
      $self->{"error"} = "0.02";
      warn "change_attribute: _send_hw_msg returned 0\n";
      return 0;
   }

   $message = &_receive_hw_msg($self->{"socket"});
   if (!$message) {
      $self->{"error"} = "0.02";
      warn "change_attribute: _receive_hw_msg returned 0\n";
      return 0;
   }

   ($self->{"server_error"}) = $message->data =~ /^(\d+)$/s;
   if ($self->{"server_error"} != 0) {
      warn "Error '" . $self->{"server_error"} . "' from HyperWave.\n";
      $self->{"error"} = "0.02";
      return 0;
   }

   return 1;
}

=pod

=item get_children ( OBJNUM )

Returns objnums for all the children in the objnum passed.  If the
object was a leaf node (ie: no children) you'll get a 0 back.

=cut
sub get_children {
   my $self = shift;
   my $objnum = shift;

   my $children;
   my $kidcount;

   my $message = HyperWave::CSP::Message->new($MESSAGE{"CHILDREN"},
                                         $objnum);

   if (!&_send_hw_msg($self->{"socket"}, $message)) {
      warn "get_children: _send_hw_msg returned 0\n";
      $self->{"error"} = "0.02";
      return 0;
   }

   $message = &_receive_hw_msg($self->{"socket"});
   if (!$message) {
      warn "get_children: _receive_hw_msg returned 0\n";
      $self->{"error"} = "0.02";
      return 0;
   }

   ($self->{"server_error"}, $kidcount, $children) = $message->data =~ /^(\d+) (\d+) (.*)$/s;
   if ($self->{"server_error"} != 0) {
      warn "Error '" . $self->{"server_error"} . "' from HyperWave.\n";
      $self->{"error"} = "0.02";
      return 0;
   }

   if (!$kidcount) {
      # No error, just no children (prob'ly a leaf collection)
      return 0;
   }

   return $children;
}

=pod

=item get_parents ( OBJNUM )

Returns objnums for all the parents in the objnum passed.  If the
object had no parents (it was the root collection) you'll get a 0
back.

=cut
sub get_parents {
   my $self = shift;
   my $objnum = shift;

   my $parents;
   my $parentcount;
   my $error;

   my $message = HyperWave::CSP::Message->new($MESSAGE{"GETPARENT"},
                                         $objnum);

   if (!&_send_hw_msg($self->{"socket"}, $message)) {
      $self->{"error"} = "0.02";
      warn "get_parents: _send_hw_msg returned 0\n";
      return 0;
   }

   $message = &_receive_hw_msg($self->{"socket"});
   if (!$message) {
      warn "get_parents: _receive_hw_msg returned 0\n";
      $self->{"error"} = "0.02";
      return 0;
   }

   ($self->{"server_error"}, $parentcount, $parents) = $message->data =~ /^(\d+) (\d+) (.*)$/s;
   if ($self->{"server_error"} != 0) {
      warn "Error '" . $self->{"server_error"} . "' from HyperWave.\n";
      $self->{"error"} = "0.02";
      return 0;
   }

   if (!$parentcount) {
      # No error, just no parents (prob'ly a root collection)
      return 0;
   }

   return $parents;
}

=pod

=item get_anchors ( OBJNUM )

Returns objnums for all the anchors in the document passed.

=cut
sub get_anchors {
   my $self = shift;
   my $objnum = shift;

   my $acount;
   my $anchors;
   my $error;

   my $message = HyperWave::CSP::Message->new($MESSAGE{"GETANCHORS"},
                                         $objnum);

   if (!&_send_hw_msg($self->{"socket"}, $message)) {
      $self->{"error"} = "0.02";
      warn "get_anchors: _send_hw_msg returned 0\n";
      return 0;
   }

   $message = &_receive_hw_msg($self->{"socket"});
   if (!$message) {
      warn "get_anchors: _receive_hw_msg returned 0\n";
      $self->{"error"} = "0.02";
      return 0;
   }

   ($self->{"server_error"}, $acount, $anchors) = $message->data =~ /^(\d+) (\d+) (.*)$/s;
   if ($self->{"server_error"} != 0) {
      warn "Error '" . $self->{"server_error"} . "' from HyperWave.\n";
      $self->{"error"} = "0.02";
      return 0;
   }

   if (!$acount) {
      # No error, just no anchors
      return 0;
   }

   $anchors =~ s/\s*$//;
   warn "get_anchors: returning " .
      dumpvar::stringify($anchors) . "\n" if $DEBUG > 2;

   return $anchors;
}


=pod

=item insert_object ( OBJRECORD );

Inserts an object on the HyperWave server.  Returns object ID of the
new object.

C<OBJRECORD> should be in the form
C<Attribute=AttributeValue\nAttr2=Value2> and must contain certain
parameters such as the parent object, name, document type, etc.  It is
suggested that you use one of the other insert_* commands as they provide
a friendlier interface.  This command is provided primarily for
completeness.

=cut

sub insert_object {
   my $self = shift;
   my $objrecord = shift;
   
   my $message = HyperWave::CSP::Message->new($MESSAGE{"INSERTOBJECT"}, _hw_string($objrecord));

   if (!&_send_hw_msg($self->{"socket"}, $message)) {
      $self->{"error"} = "0.02";
      warn "insert_object: _send_hw_msg returned 0\n" if $DEBUG;
      return 0;
   }

   $message = &_receive_hw_msg($self->{"socket"});
   if (!$message) {
      $self->{"error"} = "0.02";
      warn "insert_object: _receive_hw_msg returned 0\n" if $DEBUG;
      return 0;
   }

   $message->data =~ /^(\d+) (\d+)?/s;
   $self->{"server_error"} = $1;
   my $objid = $2;
   if ($self->{"server_error"} != 0) {
      $self->{"error"} = "0.02";
      warn "Error '" . $self->{"server_error"} . "' from HyperWave.\n" if $DEBUG;
      return 0;
   }

   return $objid;
}

=pod

=item insert_collection ( PARENT_OBJNUM, NAME [, OTHER_PARAMS ] )

Inserts a collection on the HyperWave server.  Returns object ID of
the new collection.

C<PARENT_OBJNUM> is the object number (probably returned from
get_objnum_by_name() of the collection to insert this collection into.
C<NAME> is the name attribute, this will become the apparent URL to
somebody using the WaveMaster interface.

C<OTHER_PARAMS> should be in the form
C<Attribute=AttributeValue\nAttr2=Value2> and so on.  You might
particularly want to set a Title for the collection.

=cut

sub insert_collection {
   my $self = shift;
   my $parentobjnum = shift;
   my $name = shift;
   my $objrecord = shift;

   warn "insert_collection\n" if $DEBUG > 1;
   
   return $self->insert_object("Parent=$parentobjnum\nName=$name\nType=Document\nDocumentType=Collection\n$objrecord");

}

=pod

=item insert_image ( OBJNUM, PARENT, NAME )

Adds a new picture.  NOT YET IMPLEMENTED.

=cut
sub insert_image {
   my $self = shift;
   my $parentobjnum = shift;
   my $name = shift;
   my $objrecord = shift;

   warn "insert_collection\n" if $DEBUG > 1;
   
   return $self->insert_object("Parent=$parentobjnum\nName=$name\nType=Document\nDocumentType=Image\n$objrecord");

}

=pod

=item insert_text ( OBJNUM, PARENT )

Adds a new text object (no anchors).  NOT YET IMPLEMENTED.

=cut
sub insert_text {
   my $self = shift;
   my $parentobjnum = shift;
   my $name = shift;
   my $objrecord = shift;

   warn "insert_collection\n" if $DEBUG > 1;
   
   return $self->insert_object("Parent=$parentobjnum\nName=$name\nType=Document\nDocumentType=text\n$objrecord");

}

=pod

=item insert_html ( OBJNUM )

Adds a new html object (we parse the anchors).  NOT YET IMPLEMENTED.

=cut
sub insert_html {
   my $self = shift;
   my $parentobjnum = shift;
   my $name = shift;

   # TODO: 1.  Parse anchors.
   my $objrecord = shift;

   warn "insert_collection\n" if $DEBUG > 1;
   
   return $self->insert_object("Parent=$parentobjnum\nName=$name\nType=Document\nDocumentType=text\n$objrecord");

}

=pod

=item error ( )

Returns a human-readable string describing the previous server
error.

=cut
sub error_message {
   my $self = shift;

   return $self->{"error"};
}

=pod

=item server_error_message ( )

Returns a human-readable string describing the previous server
error.

=cut
sub server_error_message {
   my $self = shift;

   if (!$self->{"server_error"}) {
      return "No Error";
   } elsif (($self->{"server_error"} >= 1) && ($self->{"server_error"} <= 37)) {
      return $SERVER_ERRORS[$self->{"server_error"} - 1];
   } elsif (($self->{"server_error"} >= 513) && ($self->{"server_error"} <= 516)) {
      return $SERVER_ERRORS[$self->{"server_error"} - 512 + 37];
   } elsif (($self->{"server_error"} >= 1024) && ($self->{"server_error"} <= 1064)) {
      return $SERVER_ERRORS[$self->{"server_error"} - 1024 + 37 + 4];
   } else {
      return "Unknown Error";
   }

}


###################################################################
# Functions under here are not member functions and not exported. #
###################################################################

#
# Used internally to construct things
#
sub _hw_string {
   return shift() . "\0";
}

sub _hw_int {
   return shift() . " ";
}

sub _hw_intarray {
   my @array = @_;

   my $output = "0.02";
   foreach (@array) {
      $output .= "$_ ";
   }
   return $output;
}

sub _hw_opaque {
   my $data = shift;
   return length($data) . " " . $data;
}

#
# Connects to the server
# Accepts a hostname and port, returns a connected socket or 0 on error
#
sub _open_hw_connection {
   my $server_host = shift;
   my $server_port = shift;

   my $socket = Symbol::gensym();

   warn "_open_hw_connection\n" if $DEBUG > 1;

   warn "_open_hw_connection: server = '$server_host', port = '$server_port'\n"       if $DEBUG > 2;

   # Deal with a port specified from /etc/services list
   if ($server_port =~ /\D/) { 
      $server_port = getservbyname($server_port, 'tcp');
      warn "_open_hw_connection: port resolved to: '$server_port'\n" if $DEBUG > 2;
   }

   my $iaddr;
   if (!($iaddr = gethostbyname($server_host))) {
      warn "_open_hw_connection: gethostbyname: $!";
      return 0;
   }

   my $paddr = sockaddr_in($server_port, $iaddr);
   my $proto = getprotobyname('tcp');

   socket($socket, PF_INET, SOCK_STREAM, $proto) || 
      croak "_open_hw_connection: socket: $!";
   connect($socket, $paddr) || croak "_open_hw_connection: connect: $!";

   return $socket;
}


#
# Negotiates connection type with the server
# Accepts a socket, returns true/false
#
sub _initialize_hw_connection {
   my $socket = shift;
   my $user = shift;
   my $password = shift;

   my $message = HyperWave::CSP::Message->new;
   my $buf;
   my $server_string;

   warn "_initialize_hw_connection\n" if $DEBUG > 2;

   if (!&_hw_write($socket, 'F'))  {
      warn "_initialize_hw_connection: _hw_write (1) returned 0\n";
      return 0;
   }

   if (!($buf = &_hw_read($socket, 1))) {
      warn "_initialize_hw_connection: _hw_read (1) returned 0\n";
      return 0;
   }
   warn "_initialize_hw_connection: _hw_read gave us " . 
      dumpvar::stringify($buf) . "\n" if $DEBUG > 2;

   if (!&_send_ready($socket)) {
      warn "_initialize_hw_connection: _send_ready returned 0\n";
      return 0;
   }

   if (!($message = &_receive_ready($socket))) {
      warn "_initialize_hw_connection: _receive_ready returned 0\n";
      return 0;
   }

   $message->data =~ m/^0 \$([^\$]+)\$(.*)\0$/;
   if ($1 eq "ServerString") {
      $server_string = $2;
   } elsif ($1 eq "Reorganization") {
      # NB:  Whatever calls this function should check for this
      # in the return value, so we only warn that it happens for
      # information purposes.
      warn "_initialize_hw_connection: server not accepting connections." 
         if $DEBUG;
   } else {
      warn "_initialize_hw_connection: unknown data in ready message.";
      $message->dump;
   }

   warn "_initialize_hw_connection: server_string: " . 
          dumpvar::stringify($server_string) . "\n" if $DEBUG > 2;

   return $message;
}


#
# Reads up to the number of bytes from the socket
# returns 0 on failure, otherwise the buffer read
#
sub _hw_read {
   my $socket = shift;
   my $length_to_read = shift;

   warn "_hw_read\n" if $DEBUG > 2;

   my $buff1 = "0.02";
   my $tries_remaining = 5;

   # loop until it's all read, or we timeout
   if (!defined(sysread($socket, $buff1, $length_to_read))) {
      warn "_hw_read: sysread: $!";
   }
   $length_to_read -= length($buff1);
   my $buffer = $buff1;
   while ($length_to_read && $tries_remaining) {
      sleep(5);
      $tries_remaining--;
      $buff1 = "0.02";
      if (!defined(sysread($socket, $buff1, $length_to_read))) { 
         warn "_hw_read: sysread: $!";
      }
      $length_to_read -= length($buff1);
      $buffer .= $buff1;
      warn "_hw_read: read = \"0.02\" of " . 
         $length_to_read . "\n" if $DEBUG > 2;
   }

   if (!$tries_remaining) {
      warn "_hw_read: ran out of tries!\n" if $DEBUG;
      return 0;
   }

   warn "_hw_read: returning = '$buffer'\n" if $DEBUG > 2;
   return $buffer;

}


#
# Write the buffer to the socket
#
sub _hw_write {
   my $socket = shift;
   my $buffer = shift;

   warn "_hw_write\n" if $DEBUG > 2;
   
   warn "_hw_write: sending " .
      dumpvar::stringify($buffer) . "\n" if $DEBUG > 2;

   my $length_sent;

   if (!defined(syswrite($socket, $buffer, length($buffer)))) {
      warn "_hw_write: syswrite: $!";
   }

   return 1;
}


#
# Get a message
#
sub _receive_hw_msg {
   my $socket = shift;

   warn "_receive_hw_msg\n" if $DEBUG > 1;

   my $buffer;
   my $length;
   my $message = HyperWave::CSP::Message->new;

   # initial length field plus separating space
   if (!($length = &_hw_read($socket, 11))) {
      warn "_receive_hw_msg: _hw_read(1) returned 0\n";
      return 0;
   }
   if (!($length =~ s/\s*(\d+)\s/$1/)) {
      warn "_receive_hw_msg: _hw_read(1) returned wrong data '$length'\n";
      return 0;
   }
   $message->length($length);

   warn "_receive_hw_msg: got length '$length'\n" if $DEBUG > 2;

   # everything else
   if (!($buffer = &_hw_read($socket, $message->length - 11))) {
      warn "_receive_hw_msg: _hw_read(2) returned 0\n";
      return 0;
   }
   $buffer =~ m/^\s*(\d+)\s+(\d+)\s+(.*)$/s;
   $message->msgid($1);
   $message->msgtype($2);
   $message->data($3);

   $message->dump("receive_hw_message") if $DEBUG > 2;

   return $message;
}


#
# Receives a 'ready' message from the server
#
sub _receive_ready {
   my $socket = shift;

   warn "_receive_ready\n" if $DEBUG > 1;

   my $message = _receive_hw_msg($socket);
   if (!$message) {
      warn "_receive_ready: _receive_hw_msg returned 0\n";
      return 0;
   }

   if (!$message->msgid) {
      warn "_receive_ready: _receive_hw_msg returned error\n";
      return 0;
   }

   if ($message->msgtype() != $MESSAGE{"READY"}) {
      warn "_receive_ready: _receive_hw_msg returned wrong message\n";
      return 0;
   }

   return $message;
}


#
# Send a message
#
sub _send_hw_msg {
   my $socket = shift;
   my $message = shift;

   warn "_send_hw_msg\n" if $DEBUG > 1;

   if (!&_hw_write($socket, $message->as_string)) {
      warn "_send_hw_msg: _hw_write returned 0\n";
      return 0;
   }

   return 1;
}



# 
# Send a 'ready' message
#
sub _send_ready {
   my $socket = shift;

   warn "_send_ready\n" if $DEBUG > 1;

   my $ready_msg = HyperWave::CSP::Message->new($MESSAGE{"READY"});
   $ready_msg->msgid($Protocol_Version);

   if (!&_send_hw_msg($socket, $ready_msg)) {
      warn "_send_ready: _send_hw_msg returned 0\n";
      return 0;
   }

   return 1;
}

=pod

=head1 SEE ALSO

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
