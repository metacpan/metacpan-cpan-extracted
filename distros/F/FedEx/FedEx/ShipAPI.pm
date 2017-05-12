package Business::FedEx::ShipAPI;

#use strict;
use warnings;

our @ISA = qw(Business::FedEx);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '0.01';
use Business::FedEx;
use Win32::API ();
use Business::FedEx::Constants qw(:all);

#Must use a realy large buffer for gif files to flow through nicely
use constant RECEIVE_BUFFER_LENGTH => 32767;

our $errstr = "";
our $err = 0;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;  
  my %args = (host => '127.0.0.1',
	      port => 6970,
	      username => '',
	      password => '',
	      Errstr => \$errstr,
	      Err => \$err,
	      @_);

  my $self = $class->SUPER::new(%args);
  return undef unless _init($self);
  return $self;
}

sub DESTROY {
#  warn "DESTROYING: ", ref(shift), "\n";
}

{
  my $_WEBAPIConnect;
  my $_WEBAPIDisconnect;
  my $_WEBAPITransaction;
  my $_WEBAPISetLogFile;
  my $_WEBAPISetLogMode;
  my $_WEBAPISetTraceFile;
  my $_WEBAPISetTraceMode;
  my $_WEBAPISend;
  my $_WEBAPIReceive;
  my $_WEBAPISetReadTimeout;

  sub _init {
    # initialize the API DLL calls
    # shift self for the error handling routines
    my $self = shift;
    eval {
      $_WEBAPIConnect = Win32::API->new(WEBAPICLIENT, WEBAPIConnect, ['P', 'N', 'P', 'P'], 'N') or die $^E;
      $_WEBAPIDisconnect = Win32::API->new(WEBAPICLIENT, WEBAPIDisconnect, [], 'N') or die $^E;
      $_WEBAPITransaction = Win32::API->new(WEBAPICLIENT, WEBAPITransaction, ['P', 'N', 'P', 'N', 'N'], 'N') or die $^E;
      $_WEBAPISetLogFile = Win32::API->new(WEBAPICLIENT, WEBAPISetLogFile, ['P'], 'N') or die $^E;
      $_WEBAPISetLogMode = Win32::API->new(WEBAPICLIENT, WEBAPISetLogMode, ['N'], 'N') or die $^E;
      $_WEBAPISetTraceFile = Win32::API->new(WEBAPICLIENT, WEBAPISetTraceFile, ['P'], 'N') or die $^E;
      $_WEBAPISetTraceMode = Win32::API->new(WEBAPICLIENT, WEBAPISetTraceMode, ['N'], 'N') or die $^E;
      $_WEBAPISetReadTimeout = Win32::API->new(WEBAPICLIENT, WEBAPISetReadTimeout, ['N'], 'N') or die $^E;
    };
    if ($@) {
      print "DIED: " . $@;
      $self->SUPER::set_err(-1, "Error in _init: $@");
      return 0;
    }
    return 1;
  }

  sub connect {
    my $self = shift;
    my %args = (host => $self->{'host'},
		port => $self->{'port'},
		username => $self->{'username'},
		password => $self->{'password'},
		@_
	       );

    my $ret = $_WEBAPIConnect->Call($args{'host'},
				    $args{'port'},
				    $args{'username'},
				    $args{'password'}
				   );
    
    if ($ret != WEBAPI_OK) {
      $self->SUPER::set_err($ret, "Error in connect ($ret): " . FedEx::Constants::lookup_errstr($ret));
      return 0
    }

    return 1;
  }

  sub disconnect {
    $_WEBAPIDisconnect->Call();
    return 1;
  }

#  int WEBAPITransaction(char *sBuf, int sBufLen, char *rBuf, int rBufLen, int *actualRecvBufLen);
  sub transaction {
    my $self = shift;

    # do we need to manipulate this in any way?  add \0 at end?
    my $buf = (shift);  # . "\0"; #null terminate?
    my $len_buf = length($buf);
    
    my $rbuf = " " x RECEIVE_BUFFER_LENGTH; # return buffer, need it have a size?
    my $len_rbuf = length($rbuf);
    my $actual_rbuf; # the actual bytes read in the recieve buffer

    # not sure what needs to be passed by reference, but this seems to work :)
    my $ret = $_WEBAPITransaction->Call($buf,
					$len_buf,
					$rbuf,
					$len_rbuf,
					\$actual_rbuf);

    #print "FH: $openfile\n";
    # not exactly, we need to parse the response code
    # here and then set an error accordingly...the error
    # will be sent back by FedEx
    if ($ret != WEBAPI_OK) {
      $self->SUPER::set_err($ret, "Error in transaction ($ret): " . Business::FedEx::Constants::lookup_errstr($ret));
      return ""
    }

    return $rbuf;
  }
}


1;
__END__

=head1 NAME

FedEx::ShipAPI - Interface to the FedEx API libraries (Win32 ONLY!!)

=head1 SYNOPSIS

  use FedEx::ShipAPI;
  my $s = new FedEx::ShipAPI(host=>'127.0.0.1', port=>6970);
  $s->connect() or die $FedEx::ShipAPI::errstr;
  $s->transaction(XXXX);
  $s->disconnect();

=head1 API

  int WEBAPIConnect(char *system, int port, char *userId, char *passWord);
  int WEBAPITransaction(char *sBuf, int sBufLen, char *rBuf, int rBufLen, int *actualRecvBufLen);
  int WEBAPIDisconnect(void);
  int WEBAPIReceive(char *rBuf, int rBufLen, int *actualRecvBufLen, int *rBufType);
  int WEBAPISend(char *sBuf, int sBufLen, int sBufType);
  int WEBAPISetLogFile(char *fileName);
  void WEBAPISetLogMode(int mode);
  int WEBAPISetTraceFile(char *fileName);
  void WEBAPISetTraceMode(int mode);
  void WEBAPISetReadTimeout(int duration);

=head1 DESCRIPTION

Use this to bounce transactions off the FedEx gateway shipping server

=head2 EXPORT

None by default.


=head1 AUTHOR

Alex Schmelkin, alex@davanita.com

=head1 SEE ALSO

Business::FedEx
Business::FedEx::Constants
Business::FedEx::ShipRequest

=cut

