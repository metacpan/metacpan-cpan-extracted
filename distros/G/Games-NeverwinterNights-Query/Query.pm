package Games::NeverwinterNights::Query;
$VERSION = "1.0";
use strict;
use Carp;
use IO::Socket;
use IO::Handle;

#
# Constructor
# Takes a hash of parameters
#

sub new
{
  my $class = shift;
  my $self = {};
  bless ($self,$class);
  return $self;
}

=item _timeout

Internal method to perform consistent timeout calls via aliarm (callback function)

=cut 

sub _timeout
{
  die "Timedout !\n";
}

=item _getResponse

Internal method to read a packet form the UDP socket

=cut

sub _getResponse
{
  my $socket = shift;
  my $size = shift;
  my $timeout = shift;
  my $buffer;
  my $recAddr;
  $SIG{ALRM} = \&_timeout;
  alarm $timeout;
  eval
  {
    $recAddr = $socket->recv($buffer,$size);
     alarm (0);
  };
  return $buffer;
}

=item query

Query a server 
Params:
	host - the host to scan
	port - the port to use

=cut

sub query
{
  my $self = shift;
  my ($host,$port); 
  my $nh = shift;
  my $np = shift;
  if($nh)
  {
    $host = $nh;
  }
  else
  {
    $host = 'localhost';
  }
  if($np)
  {
    $port = $np;
  }
  else
  {
    $port = '5121';
  }
  # Socket created with 10 second timeout value
  my $socket = IO::Socket::INET->new(
                                     PeerAddr => $host,
                                     PeerPort => $port,
                                     Proto    => 'udp');
  # Send first request									       
  my $queryAll = "\xFE\xFD\x00\xE0\xEB\x2D\x0d\x14\x01\x0B\x01\x05\x08\x0a\x33\x34\x35\x13\x03\x36\x37\x38\x39\x14\x3A\x3B\x3C\x3D\x00\x00";
  					      #fc #sn #pt #gn #md #cc #mc #ml #xl #pp #pw #pt #op #pu #vr #ds #gt #el #il #vl #ep
  my $sent = $socket->send($queryAll);
  my $response;
  my $recAddr;
  $response = _getResponse($socket,2048,10);
  my %results;
  if(!$response)
  {
  	$socket->send("\\info\\");
  	$response = _getResponse($socket,2048,10);
  	unless ($response)
  	{
  	  # Not old style just has gamespy off
  	  # so lets just ping it
  	  $socket->send("BNES\x00\x14\x01");
  	  $response = _getResponse($socket,2048,10);
  	  my @rt = split("\x0a",$response);
  	  $response = "xx\x00" .
  	  	      "UNKNOWN\x00" .
  	  	      "UNKNOWN\x00" .
  	  	      "UNKNOWN\x00" .
  	  	      "0\x00" .
  	  	      "0\x00" .
  	  	      "0\x00" .
  	  	      "0\x00" .
  	  	      "0\x00" .
  	  	      "UNKNOWN\x00" .
  	  	      "0\x00" .
  	  	      "$port\x00" .
  	  	      "0\x00" .
  	  	      "0\x00" .
  	  	      "0\x00" .
  	  	      "$rt[1]\x00" .
  	  	      "0\x00" .
  	  	      "0\x00" .
  	  	      "0\x00" .
  	  	      "0\x00" .
  	  	      "0\x00";
  	}
  }
  my @resData;
  if($response)
  {
    @resData = split("\x00",$response);
    $results{Host} = $host;
    $results{Port} = $resData[11];
    $results{GameType} = _getGameType($resData[16]);
    $results{PlayType} = $resData[2];
    $results{GameName} = $resData[3];
    $results{Module} = $resData[4];
    $results{Version} = $resData[14];
    if($resData[20] == 1)
    {
      $results{Version} .= " XP-1";
    }
    elsif($resData[20] == 2)
    {
      $results{Version} .= " XP-2";
    }
    $results{MinLevel} = $resData[7];
    $results{MaxLevel} = $resData[8];
    $results{PvP} = $resData[9];
    $results{Vault} = ($resData[19] == 1 ? "Local" : "Server");
    $results{OneParty} = ($resData[12] == 1 ? "Enabled" : "Disabled");
    $results{PlayerPausable} = ($resData[13] == 1 ? "Enabled" : "Disabled");
    $results{ItemLevelRestriction} = ($resData[18] == 1 ? "Enabled" : "Disabled");
    $results{EnforceLegalCharacters} = ($resData[17] == 1 ? "Enabled" : "Disabled");
    $results{Password} = ($resData[10] == 0 ? " Not Required" : "Required");
    $results{MaxClients} = $resData[6];
    $results{CurrentClients} = $resData[5];
    $results{ServerDescription} = $resData[15];
  }
  # try to get player data
  #if($resData[5] > 0)
  #{
    # CODE HERE TO SCAN FOR PLAYER DATA
    # It seems we are boned to get this data
    # END CODE
    # Send login request
    #$socket->send("\x42\x4e\x43\x53\x00\x14\x10\x8e\x1b\x00\x00\x01\x00\x00\xad\xc3\xf8\x02\x0a" . "player check". "\x08" . "BOGUSKEY");
    # Send Fake Keys 
    #$socket->send("\x42\x4e\x56\x53\x56\x02\x28" .
    #	"BOGUSKEY" .
    #	"\x64\x39\x32\x37\x65\x36\x34\x62\x63\x64\x38\x38\x34\x63\x34\x66\x63\x39\x66\x36\x65\x38\x65\x62\x66\x65\x31\x30\x30\x32\x38\x30\x28" .
    #	"BOGUSKEY" .
    #	"\x37\x38\x61\x35\x30\x63\x34\x62\x36\x35\x32\x37\x63\x37\x62\x34\x38\x35\x63\x37\x36\x62\x34\x38\x35\x32\x36\x66\x37\x62\x65\x63\x20\x61\x62\x32\x30\x61\x39\x61\x64\x39\x30\x38\x33\x35\x64\x32\x38\x30\x65\x36\x66\x39\x65\x35\x31\x37\x66\x31\x38\x36\x38\x61\x32");
    
    # Send fake response (SPOOFED ADDRESS)
    #$socket->send("\x42\x4d\x50\x52\x0a\x00" . "player check" . "\x00\x00");
    #$socket->send("\x42\x4d\x41\x52\x02\x00\x08\x00" .
    #		"BOGUSKEY" .
    #		"\x00\x00\x00\x00\x08\x00" .
    #		"BOGUSKEY" .
    #		"\x00\x00\x01\x00");
    #$response = _getResponse($socket,2048,10);
    #print "Login response $response\n";
    #$socket->send("\x4D\x5D\x69\x00\x02\xFF");
    #$response = _getResponse($socket,2048,20);
    #print "Response $response\n";
    #$socket->flush();
  #}
  $socket->close();
  return %results;
}

=item _getGameType

Internal method to parse the game type code

=cut

sub _getGameType
{
  my $type = shift;
  my $result = "Unknown";
  if ( $type == "274" )
  {
    $result = "Action";
  }
  elsif ( $type == "363" )
  {
    $result = "Story";
  }
  elsif ( $type == "364" )
  {
    $result = "Story Lite";
  }
  elsif ( $type == "275" )
  {
    $result = "Role Play";
  }
  elsif ( $type == "276" )
  {
    $result = "Team";
  }
  elsif ( $type == "365" )
  {
    $result = "Melee";
  }
  elsif ( $type == "366" )
  {
    $result = "Arena";
  }
  elsif ( $type == "277" )
  {
    $result = "Social";
  }
  elsif ( $type == "279" )
  {
    $result = "Alternative";
  }
  elsif ( $type == "278" )
  {
    $result = "PW Action";
  }
  elsif ( $type == "367" )
  {
    $result = "PW Story";
  }
  elsif ( $type == "368" )
  {
    $result = "Solo";
  }
  elsif ( $type == "370" )
  {
    $result = "Tech Support";
  }
  return $result;
}
1;

__END__

=head1 NAME

Query Perl class to query a Neverwint Nights Server

=head1 AUTHOR

Sal Scotto sscotto@cpan.org

=head1 REQUIRES

Perl 5.005 or greater, IO::Handle, IO::socket, Carp

=head1 SYNOPSIS

  use Games::NeverwintNights::Query
  my $sq = Games::NeverwinterNights->new();
  # default to 5121
  my %results = $sq->query("host");
  # use host and port
  my %results = $sq->query("host",5120);
  # defualt to localhost port 5121
  my %results = $sq->query();

=head1 DESCRIPTION

This class provides a way to query a neverwinter nights server for status
the keys in the resulting HASH are:

    Host
    Port
    GameType
    PlayType
    GameName
    Module
    Version
    MinLevel
    MaxLevel
    PvP
    Vault
    OneParty
    PlayerPausable
    ItemLevelRestriction
    EnforceLegalCharacters
    Password
    MaxClients
    CurrentClients
    ServerDescription

=head1 METHODS

=head2 query

This method will query the server
Params:
	host,port

=head1 COPYRIGHT

Copyright (c) 2002 Sal Scotto (sscotto@cpan.org). All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
