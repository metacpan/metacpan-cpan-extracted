package Device::Opto22::Firewire;

use strict;
use warnings;

use IO::Socket;
use IO::Select;
use POSIX;

our @ISA = qw(IO::Socket);

our @EXPORT_OK = ( );

our @EXPORT = qw( ); 

our $VERSION = '0.90';

$| = 1;

# Global Data Area

# TCode for transmission
our $TC_WR_QUAD_RQST  = 0;
our $TC_WR_BLK_RQST   = 1;
our $TC_RD_QUAD_RQST   = 4;
our $TC_RD_BLK_RQST    = 5;

# TCode for responses
our $TC_WR_RSP     = 2;
our $TC_RD_BLK_RSP  = 6;
our $TC_RD_QUAD_RSP = 7;

our $timeout = 5; 

sub new {

    my $class = shift @_;

	my %args = @_; 
	
    my $PeerAddr = $args{PeerAddr};
    my $PeerPort = $args{PeerPort};

    if (not ($PeerAddr && $PeerPort) )	{
          die "Inputs missing in Package $class. Require PeerAddr and PeerPort";
    }

    # This establishes a SENDER socket connection OK
    my $self = new IO::Socket::INET (PeerAddr => $PeerAddr ,
                                       PeerPort => $PeerPort ,
                                       Proto    => 'tcp',
                                       Timeout  => $timeout );

    unless ( $self ) { die "Error Socket Connecting" }
	
	# Init a error message
	${*$self}->{'error_msg'} = ""; 
	
    $SIG{ALRM} = \&_time_out ;

    bless  $self, $class;

    return $self;
}

#----------------------------------------------------------------------
# Description:  Does a socket transation
#
# Inputs:  $socket - Socket descriptor
#          $packet - Request packet to send
#
# Output:
#----------------------------------------------------------------------

sub chat {

  my ($self, $packet) = @_;
  
  my ($rsp,$cnt);

  eval {

     alarm ($timeout) ;

     print $self $packet;
     $cnt = $self->recv($rsp, 300, 0 ) ;
     alarm(0);
  };

  unless ( length($rsp) )  
  {
          ${*$self}->{'error_msg'} = "$@ - Nothing returned in Chat" ;
          return 0 ;
  }

  # Split response
  my $header  = substr $rsp, 0 , 16;
  my $payload;
  if ( length($rsp) >= 16 ) { $payload = substr $rsp, 16 }
  
  my @header_lst = unpack ("C8", $header ) ;

  my $tcode = $header_lst[3] >> 4 ;
  my $rcode = $header_lst[6] >> 4 ;

  if ($rcode) {
    ${*$self}->{'error_msg'} = "oh oh we got a NAK in Chat" ;
    return 0 ;
  }

  if ( $tcode == 2 )  { $payload = 1 ; }

  return ($payload) ;
}

#----------------------------------------------------------------------
# Description:  Formats a packet as per pg 106 of the SNAP Users Guide
#
# Inputs:  $offset (hexidecimal MemMap address)
#
# Output:  pointer to the packet consisting of 16 bytes
#----------------------------------------------------------------------

sub bld_rd_quad_packet {

  my ($self, $offset) = @_;

  my $src_id = 0;

  my $trans += 1; # global variable

  my $dest_id = 0;                      # Destination ID

  my $tl      = ($trans & 0x3f)  << 2;  # Transaction Label (shifted to set retry bits to 00)
  my $tcode   = $TC_RD_QUAD_RQST << 4;  # Bit shift over the unused priority bits

  my $fixed = 0xffff ;     # fixed area of address

  my $packet = pack "ncc n2 N N", $dest_id, $tl, $tcode, $src_id, $fixed, $offset ;

  return $packet;

}

#----------------------------------------------------------------------
# Description:  Formats a packet as per pg 106 of the SNAP Users Guide
#
# Inputs:  $offset - (hexidecimal MemMap address which is prefixed with $fixed)
#          $data   - 4 bytes of data to write
#
# Output:  pointer to the packet consisting of 16 bytes
#----------------------------------------------------------------------

sub bld_wr_quad_packet {

  my ($self, $offset, $data) = @_;

  my $trans += 1; # global variable

  my $src_id = 0  ;

  my $dest_id = 0;                      # Destination ID
  my $tl      = ($trans & 0x3f)  << 2;  # Transaction Label (shifted to set retry bits to 00)
  my $tcode   = $TC_WR_QUAD_RQST << 4;  # Bit shift over the unused priority bits

  my $fixed = 0xffff ;     # fixed area of address

  my $packet = pack "ncc n2 N N", $dest_id, $tl, $tcode, $src_id, $fixed, $offset, $data;

  return $packet;

}

#----------------------------------------------------------------------
# Description:  Formats a packet as per pg 106 of the SNAP Users Guide
#
# Inputs:  $offset - (hexidecimal MemMap address which is prefixed with $fixed)
#          $data   - 4 bytes of data to write
#
# Output:  pointer to the packet consisting of 16 bytes
#----------------------------------------------------------------------

sub bld_rd_blk_packet {

  my ($self, $offset, $length) = @_;

  my $trans += 1; # global variable

  my $src_id = 0  ;

  my $dest_id = 0;                      # Destination ID
  my $tl      = ($trans & 0x3f)  << 2;  # Transaction Label (shifted to set retry bits to 00)
  my $tcode   = $TC_RD_BLK_RQST  << 4;  # Bit shift over the unused priority bits

  my $fixed = 0xffff ;     # fixed area of address

  $length = $length << 16 ;

  my $packet = pack "ncc n2 N2", $dest_id, $tl, $tcode, $src_id, $fixed, $offset, $length ;

  return $packet;

}

#----------------------------------------------------------------------
# Description:  Formats a packet as per pg 106 of the SNAP Users Guide
#
# Inputs:  $offset - (hexidecimal MemMap address which is prefixed with $fixed)
#          $data   - 4 bytes of data to write
#
# Output:  pointer to the packet consisting of 16 bytes
#----------------------------------------------------------------------

sub bld_wr_blk_packet {

  my ($self, $offset, $length) = @_;

  my $trans += 1; # global variable

  my $src_id = 0  ;

  my $dest_id = 0;                      # Destination ID
  my $tl      = ($trans & 0x3f)  << 2;  # Transaction Label (shifted to set retry bits to 00)
  my $tcode   = $TC_WR_BLK_RQST  << 4;  # Bit shift over the unused priority bits

  my $fixed = 0xffff ;                  # fixed area of address

  $length = $length << 16 ;

  my $packet = pack "ncc n2 N2", $dest_id, $tl, $tcode, $src_id, $fixed, $offset, $length ;

  return $packet;

}

# Report error message 
sub error_msg
{
 my $self = shift @_;
 return ${*$self}->{'error_msg'};
}


#------------------
# Private Functions
#------------------
sub _time_out {

 die "Error Time Out" ;

}


sub dump_quadlet
{
 my $self = shift @_ ;
 my $data = shift @_ ;

 my $len = length($data); 
 print "Length $len\n"; 
 
 my @lst = split // , unpack  "B128" , $data ;

 my $cnt;
 foreach my $b (@lst) 
 {
 
    print "$b ";
	$cnt++;
	unless ( $cnt % 8 )  { print " "  }
    unless ( $cnt % 32 ) { print "\n" }	
 }	
 
 print "\n"; 
}

1;









