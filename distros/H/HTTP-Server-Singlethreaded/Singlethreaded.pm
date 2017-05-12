package HTTP::Server::Singlethreaded;

BEGIN{
	eval ( $ENV{OS}=~/win/i ? <<WIN : <<NOTWIN )

	sub BROKENSYSWRITE(){1}

WIN

	sub BROKENSYSWRITE(){0}

NOTWIN

}


use 5.006;
use strict;
use warnings;
use vars qw/

%Static 
%Function
%CgiBin
%Path


$DefaultMimeType
%MimeType

@Port
$Timeout
$MaxClients
$ServerType
$VERSION
$RequestTally
$uid $gid $forkwidth @kids
$WebEmail
$StaticBufferSize
@Cport
@Caddr
@Sport
@Saddr
/;

sub DEBUG() {
#	1
	0 
};

$RequestTally = 0;
$StaticBufferSize ||= 50000;

# file number of request
my $fn;
# arrays indexed by $fn
my @Listeners;    # handles to listening sockets
my @PortNo;       # listening port numbers indexed by $fn
my @Clients;      # handles to client sockets
my @inbuf;        # buffered information read from clients
my @outbuf;       # buffered information for writing to clients
my @LargeFile;    # handles to large files being read, indexed by
                  # $fn of the client they are being read for
my @continue;     # is there a continuation defined for this fn?
my @PostData;     # data for POST-style requests

#lists of file numbers
my @PollMe;       #continuation functions associated with empty output buffers

$VERSION = '0.12';

# default values:
$ServerType ||= __PACKAGE__." $VERSION (Perl $])";
@Port or @Port = (80,8000);
$Timeout ||= 5;
$MaxClients ||= 10;
$DefaultMimeType ||= 'text/plain';
keys(%MimeType ) or
  @MimeType{qw/txt htm html jpg gif png/} =
  qw{text/plain text/html text/html image/jpeg image/gif image/png};

sub Serve();
# use IO::Socket::INET;
use Socket  qw(:DEFAULT :crlf);
BEGIN{
	use Fcntl;
        # determine if O_NONBLOCK is available,
        # for use in fcntl($l, F_SETFL, O_NONBLOCK) 
        eval{
          # print "O_NONBLOCK is ",O_NONBLOCK,
          #      " and F_SETFL is ",F_SETFL,"\n";
          no warnings; O_NONBLOCK; F_SETFL;
        };
        if ($@){
           warn "O_NONBLOCK is broken, but a workaround is in place.\n";
	   eval'sub BROKEN_NONBLOCKING(){1}';
        }else{
	   eval'sub BROKEN_NONBLOCKING(){0}';
        };
}

sub makeref($){
	ref($_[0]) ? $_[0] : \$_[0]
};

sub import(){

  DEBUG and print __PACKAGE__," import called\n";

  shift; # we don't need to know __PACKAGE__

  # DYNAMIC RECONFIGURATION SECTION
  my %args = @_;
  DEBUG and do{
	print "$_ is $args{$_}\n" foreach sort keys %args

  };
  exists $args{port} and *Port = $args{port};
  exists $args{timeout} and *Timeout = $args{timeout};
  exists $args{maxclients} and *MaxClients = $args{maxclients};
  exists $args{static} and *Static = $args{static};
  exists $args{function} and *Function = $args{function};
  exists $args{cgibin} and *CgiBin = $args{cgibin};
  exists $args{servertype} and *ServerType = $args{servertype};
  exists $args{webemail} and *WebEmail = makeref($args{webemail});
  exists $args{path} and *Path = $args{path};

  @Port or die __PACKAGE__." invoked with empty \@Port array";

  @Listeners = ();
  for (@Port) {
     my $l;
     socket($l, PF_INET, SOCK_STREAM,getprotobyname('tcp'))
        || die "socket: $!";
     unless (BROKEN_NONBLOCKING){
       fcntl($l, F_SETFL, O_NONBLOCK) 
        || die "can't set non blocking: $!";
     };
     setsockopt($l, SOL_SOCKET,
                SO_REUSEADDR,
                pack("l", 1))
        || die "setsockopt: $!";
     bind($l, sockaddr_in($_, INADDR_ANY))
        || do {warn "bind: $!";next};
     listen($l,SOMAXCONN)
        || die "listen: $!";
     if (defined $l){
        print "bound listener to $_\n";
        $PortNo[fileno($l)] = $_;
        push @Listeners,$l;
     }else{
         print "Could not bind listener to $_\n";
     };
  } ;

  @Listeners or die __PACKAGE__." could not bind any listening sockets among @Port";

###########################################################################
#   uncomment the following if so desired
###########################################################################
#   if($defined $uid){
#      $> = $< = $uid
#   };
# 
#   if($defined $gid){
#      $) = $( = $gid
#   };
# 
#   if($defined $forkwidth){
#      my $pid; my $i=0;
#      while (++$i < $forkwidth){
#         $pid = fork or last;
#         unshift @kids, $pid
#      };
#      unless($kids[0] ){
#        @kids=();
#      };
#      $forkwidth = "$i of $forkwidth";
#   };
#   END{ kill 'TERM', $_ for @kids };
############################################################################



   for (keys %Function){
      die "$Function{$_} is not a coderef"
        unless (ref $Function{$_} eq 'CODE');
      $Path{$_} = $Function{$_};
   }
   for (keys %Static){
      die "path $_ already defined" if exists $Path{$_};
      $Path{$_} = "STATIC $Static{$_}";
   }
   for (keys %CgiBin){
      die "path $_ already defined" if exists $Path{$_};
      $Path{$_} = "CGI $CgiBin{$_}";
   }

   {
      # import Serve into caller's package
      no strict;
      *{caller().'::Serve'} = \&Serve;
   }


};

my %RCtext =(
    100=> 'Continue',
    101=> 'Switching Protocols',
    200=> 'OK',
    201=> 'Created',
    202=> 'Accepted',
    203=> 'Non-Authoritative Information',
    204=> 'No Content',
    205=> 'Reset Content',
    206=> 'Partial Content',
    300=> 'Multiple Choices',
    301=> 'Moved Permanently',
    302=> 'Found',
    303=> 'See Other',
    304=> 'Not Modified',
    305=> 'Use Proxy',
    306=> '(Unused)',
    307=> 'Temporary Redirect',
    400=> 'Bad Request',
    401=> 'Unauthorized',
    402=> 'Payment Required',
    403=> 'Forbidden',
    404=> 'Not Found',
    405=> 'Method Not Allowed',
    406=> 'Not Acceptable',
    407=> 'Proxy Authentication Required',
    408=> 'Request Timeout',
    409=> 'Conflict',
    410=> 'Gone',
    411=> 'Length Required',
    412=> 'Precondition Failed',
    413=> 'Request Entity Too Large',
    414=> 'Request-URI Too Long',
    415=> 'Unsupported Media Type',
    416=> 'Requested Range Not Satisfiable',
    417=> 'Expectation Failed',
    500=> 'Internal Server Error',
    501=> 'Not Implemented',
    502=> 'Bad Gateway',
    503=> 'Service Unavailable',
    504=> 'Gateway Timeout',
    505=> 'HTTP Version Not Supported'
); 


our @Moustache;  # per-fn %_ references

sub dispatch(){
# based on the request, which is in $_,
# figure out what to do, and do it.
# return a numeric resultcode in $ResultCode
# and data in $Data

   if(DEBUG){
     print "Request on fn $fn:\n${_}END_REQUEST\n";
   };

   # defaults:
   *_ = $Moustache[$fn] = {
       Data => undef,
       ResultCode => 200
   };

   $continue[$fn] = undef;

   # rfc2616 section 5.1
   /^(\w+) (\S+) HTTP\/(\S+)\s*(.*)$CRLF$CRLF/s
      or do { $_{ResultCode} = 400;
              return <<EOF;
Content-type:text/plain

This server only accepts requests that
match the perl regex
/^(\\w+) (\\S+) HTTP\\/(\\S+)/

EOF
   };
   @_{qw/
      REQUEST_METHOD REQUEST_URI HTTPver RequestHeader
      REMOTE_ADDR REMOTE_PORT SERVER_ADDR SERVER_PORT/
   } = (
      $1,$2,$3,$4,
      $Caddr[$fn], $Cport[$fn],
      $Saddr[$fn], $Sport[$fn]
   );
   if(DEBUG){for( sort keys %_ ){
      print "$_ is $_{$_}\n";
   }};

   # REQUEST_URI is
   # equivalent to SCRIPT_NAME . PATH_INFO . '?' . QUERY_STRING

   my $shortURI;
   ($shortURI ,$_{QUERY_STRING}) = $_{REQUEST_URI}=~m#(/[^\?]*)\??(.*)$#;
   $shortURI =~ s/%(..)/chr hex $1/ge; # RFC2616 sec. 3.2
   if (uc($_{REQUEST_METHOD}) eq 'POST'){
      $_{POST_DATA} = $PostData[$fn];
   };

   my @URIpath = split '/',$shortURI,-1; 
   my @Castoffs;
   my $mypath;
   while (@URIpath){
      $mypath = join '/',@URIpath;
      DEBUG and warn "considering $mypath\n";
      if (exists $Path{$mypath}){
         $_{SCRIPT_NAME} = $mypath;
         print "PATH $mypath is $Path{$mypath}";
         $_{PATH_INFO} = join '/', @Castoffs;
         print " and PATH_INFO is $_{PATH_INFO}\n";
         if (ref $Path{$mypath}){
            my $DynPage;
            eval {
               $DynPage = &{$Path{$mypath}};
            };
            $@ or return $DynPage;
            $_{ResultCode} = 500;
            return <<EOF;
Content-type:text/plain

Internal server error while processing routine
for $mypath:

$@
EOF
         };
         if ($Path{$mypath} =~/^STATIC (.+)/){
            my $FILE;
            my $filename = "$1/$_{PATH_INFO}";
            print "filename: $filename\n";
            $filename =~ s/\/\.\.\//\//g; # no ../../ attacks
            my ($ext) = $filename =~ /\.(\w+)$/;
            my $ContentType = $MimeType{$ext}||$DefaultMimeType;
            # unless (-f $filename and -r _ ){
            unless(open $FILE, "<", $filename){
               $_{ResultCode} = 404;
               return <<EOF;
Content-type: text/plain

Could not open $filename for reading
$!

for $mypath: $Path{$mypath}

Request:

$_

EOF
            };
            # range will go here when supported
            my $size = -s $filename;
            my $slurp;
            my $read = sysread $FILE, $slurp, $StaticBufferSize ;

            if ($read < $size){
               $LargeFile[$fn] = $FILE;
            };

            return "Content-type: $ContentType\n\n$slurp";

         };
         $_{ResultCode} = 404;
         return <<EOF;
Content-type:text/plain

This version of Singlethreaded does not understand
how to serve

$mypath

$Path{$mypath}

Responsible person: $WebEmail

We received this request:

$_

EOF
      };
      if((length $URIpath[$#URIpath]) > 0){
         unshift @Castoffs, pop @URIpath;
      }else{
         $URIpath[$#URIpath] = '/'
      };
   };


   $_{ResultCode} = 404;
   <<EOF;
Content-type:text/plain

$$ $RequestTally handling fileno $fn

apparently this Singlethreaded server does not
have a default handler installed at its 
virtual root.

Castoffs: [@Castoffs]

Responsible person: [$WebEmail]

$_

EOF

};


sub HandleRequest(){
   $RequestTally++;
   print "Handling request $RequestTally on fn $fn\n";
   DEBUG and warn "Inbuf:\n$inbuf[$fn]\n";
   *_ = \delete $inbuf[$fn]; # tight, huh? (the scalar slot)
   
   my $dispatchretval = dispatch;
   $dispatchretval or return undef;
   $outbuf[$fn]=<<EOF;  # change to .= if/when we support pipelining
HTTP/1.1 $_{ResultCode} $RCtext{$_{ResultCode}}
Server: $ServerType
Connection: close
EOF
   # *_ = $Moustache[$fn];  # also, the hash slot -- this is done in &dispatch, never mind
   HandleDRV($dispatchretval);
   DEBUG and warn "Outbuf:\n$outbuf[$fn]\n";
};
sub HandleDRV{
   my $dispatchretval = shift;
   @_ and $dispatchretval = [$dispatchretval,shift]; # support old-style
   $continue[$fn] = undef;
   { no warnings; length $_{Data} and $outbuf[$fn] .= $_{Data}; }
   if(ref($dispatchretval)){
      $continue[$fn] = $dispatchretval;

   }else{
	$outbuf[$fn].=$dispatchretval
   }

};

my $client_tally = 0;
sub Serve(){
   DEBUG and print "L: (@Listeners) C: (@Clients)\n";
   my ($rin,$win,$ein,$rout,$wout,$eout);
   my $nfound;

BEGIN_SERVICE:

  # support for continuation coderefs to empty outbufs
  @PollMe = grep {
	 $fn = $_;
         DEBUG and warn "polling $_";
         if ( $continue[$_] ) {
           *_ = $Moustache[$_]; # the hash slot 
	   DEBUG and warn "still working with $_";
           $_{Data} = '';
   	   HandleDRV( &{$continue[$_]} );
	   $continue[$_];
         }
  } @PollMe;



   # poll for new connections?
   my $Accepting = ($client_tally < $MaxClients);
   $rin = $win = $ein = '';
   if($Accepting){
      for(@Listeners){
         $fn = fileno($_);
         vec($rin,$fn,1) = 1;
         vec($win,$fn,1) = 1;
         vec($ein,$fn,1) = 1;
      };
   };


   my @Outs;
   my @CompleteRequests;
   # list all clients in $ein and $rin
   # list connections with pending outbound data in $win;
   for(@Clients){
      $fn = fileno($_);
      vec($rin,$fn,1) = 1;
      vec($ein,$fn,1) = 1;
      if( length $outbuf[$fn]){
         vec($win,$fn,1) = 1;
         push @Outs, $_;
      }
   };

   # Select.
   $nfound = select($rout=$rin, $wout=$win, $eout=$ein, $Timeout);
   $nfound > 0 or return;
   my $Services = 0; # goes true when writing outbound bytes
   # accept new connections
   if($Accepting){
      for(@Listeners){
         my $paddr;
         vec($rout,fileno($_),1) or next;
         # relies on listeners being nonblocking
         # thanks, thecap
         # (at http://www.perlmonks.org/index.pl?node_id=6535)
#BLAH         if (BROKEN_NONBLOCKING){ # this is a constant so the unused one
#BLAH                                  # will be optimized away
#BLAH          acc:
#BLAH          $paddr=accept(my $NewServer, $_);
#BLAH          if ($paddr){
#BLAH            $fn =fileno($NewServer); 
#BLAH	    ($Cport[$fn], my $iaddr) = sockaddr_in($paddr);
#BLAH	    $Caddr[$fn] = inet_ntoa($iaddr);
#BLAH            $inbuf[$fn] = $outbuf[$fn] = '';
#BLAH            print "Accepted $NewServer (",
#BLAH                  $fn,") ",
#BLAH                  ++$client_tally,
#BLAH                  "/$MaxClients on $_ ($fn) port $PortNo[fileno($_)]\n";
#BLAH            push @Clients, $NewServer;
#BLAH
#BLAH
#BLAH          }
#BLAH
#BLAH	  # select again to see if there's another
#BLAH          # client enqueued on $_
#BLAH          my $rvec;
#BLAH          vec($rvec,fileno($_),1) = 1;
#BLAH          select($rvec,undef,undef,0);
#BLAH          vec($rvec,fileno($_),1) and goto acc;
#BLAH      
#BLAH         }else{  # WORKING NON_BLOCKING
          while ($paddr=accept(my $NewServer, $_)){
            $fn =fileno($NewServer); 
	    $continue[$fn] = undef;
	    $Moustache[$fn] = {};
            $inbuf[$fn] = $outbuf[$fn] = '';
	    ($Cport[$fn], my $iaddr) = sockaddr_in($paddr);
	    $Caddr[$fn] = inet_ntoa($iaddr);

	    my $mysockaddr = getsockname($NewServer);
	    ($Sport[$fn], $iaddr) = sockaddr_in($mysockaddr);
	    $Saddr[$fn] = inet_ntoa($iaddr);

            print "Accepted $NewServer (",
                  $fn,") ",
                  ++$client_tally,
                  "/$MaxClients on $_ ($fn) port $PortNo[fileno($_)]\n";
            push @Clients, $NewServer;

	    BROKEN_NONBLOCKING and last; # much simpler
          }
#BLAH   }
      }
   } # if accepting connections

   # Send outbound data from outbufs 
   my $wlen;
   for my $OutFileHandle (@Outs){
      $fn = fileno($OutFileHandle);
      ((defined $fn) and vec($wout,$fn,1)) or next;
         $Services++;
      $wlen = syswrite $OutFileHandle, $outbuf[$fn], (BROKENSYSWRITE ? 1 : length($outbuf[$fn]));
      if(defined $wlen){
        DEBUG and print "wrote $wlen of ",length($outbuf[$fn])," to ($fn)\n";
        substr $outbuf[$fn], 0, $wlen, '';
      
        if(
           length($outbuf[$fn]) < $StaticBufferSize
        ){
	 # then we would like to add some more to our outbuf
         if(
           # support for chunking large files (not HTTP1.1 chunking, just
           # reading as we go
           defined($LargeFile[$fn])
         ){
             my $slurp;
             my $read = sysread $LargeFile[$fn], $slurp, $StaticBufferSize ;
             # zero for EOF and undef on error
             if ($read){
               $outbuf[$fn].= $slurp; 
             }else{
                print "sysread error: $!" unless defined $read;
                delete $LargeFile[$fn];
             };
         }elsif(
           # support for continuation coderefs
           $continue[$fn]
         ){
           *_ = $Moustache[$fn]; # the hash slot 
           $_{Data} = '';
   	   HandleDRV( &{$continue[$fn]} );
           length ($outbuf[$fn]) or push @PollMe, $fn;
           next;
         };
        }
      }else{
         warn "Error writing to socket $OutFileHandle ($fn): $!";
         $outbuf[$fn] = '';
      }

      # rewrite this when adding keepalive support
      length($outbuf[$fn]) or close $OutFileHandle;
   }

   # read incoming data to inbufs and list inbufs with complete requests
   # close bad connections
   for(@Clients){
      defined($fn = fileno($_)) or next;
      if(vec($rout,$fn,1)){

         my $char;
         sysread $_,$char,64000;
	 if(length $char){
                DEBUG and print "$fn: read [$char]\n";
		$inbuf[$fn] .= $char;
                # CompleteRequest or not?
                if($inbuf[$fn] =~
/^POST .*?Content-Length: ?(\d+)[\015\012]+(.*)$/is){
                   DEBUG and print "posting $1 bytes\n";
                   if(length $2 >= $1){
                      push @CompleteRequests, $fn;
                      $PostData[$fn] = $2;
                   }else{
                      if(DEBUG){
                       print "$fn: Waiting for $1 octets of POST data\n";
                       print "$fn: only have ",length($2),"\n";
                      }
                   }
		}elsif(substr($inbuf[$fn],-4,4) eq "\015\012\015\012"){
                   push @CompleteRequests, $fn;
                }elsif(DEBUG){
                   print "Waiting for request completion. So far have\n[",
                   $inbuf[$fn],"]\n";

                };   
	 }else{
            print "Received empty packet on $_ ($fn)\n";
		 print "CLOSING fd $fn\n";
                 close $_ or print "error on close: $!\n";
                 $client_tally--;
                 print "down to $client_tally / $MaxClients\n";
	 };
      }
      if(vec($eout,$fn,1)){
         # close this one
         print "error on $_ ($fn)\n";
	 print "CLOSING fd $fn\n";
         close $_ or print "error on close: $!\n";
      };
   }

   # prune @Clients array

   @Clients = grep { defined fileno($_) } @Clients;
   $client_tally = @Clients;
   DEBUG and print "$client_tally / $MaxClients\n";

   # handle complete requests
   # (outbound data will get written next time)
   for $fn (@CompleteRequests){

      HandleRequest

   };

   $Services and goto BEGIN_SERVICE; # keep selecting while we actually do something


};




1;
__END__

=head1 NAME

HTTP::Server::Singlethreaded - a framework for standalone web applications

=head1 SYNOPSIS

  # configuration first:
  #
  BEGIN { # so the configuration happens before import() is called
  # static directories are mapped to file paths in %Static
  $HTTP::Server::Singlethreaded::Static{'/images/'} = '/var/www/images';
  $HTTP::Server::Singlethreaded::Static{'/'} = '/var/www/htdocs';
  #
  # configuration for serving static files (defaults are shown)
  $HTTP::Server::Singlethreaded::DefaultMimeType = 'text/plain';
  @HTTP::Server::Singlethreaded::MimeType{qw/txt htm html jpg gif png/} =
  qw{text/plain text/html text/html image/jpeg image/gif image/png};
  #
  # internal web services are declared in %Functions 
  $HTTP::Server::Singlethreaded::Function{'/AIS/'} = \&HandleAIS;
  #
  # external CGI-BIN directories are declared in %CgiBin
  # NOT IMPLEMENTED YET
  $HTTP::Server::Singlethreaded::CgiBin{'/cgi/'} = '/var/www/cgi-bin';
  #
  # @Port where we try to listen
  @HTTP::Server::Singlethreaded::Port = (80,8000);
  #
  # Timeout for the selecting 
  $HTTP::Server::Singlethreaded::Timeout = 5
  #
  # overload protection
  $HTTP::Server::Singlethreaded::MaxClients = 10
  #
  }; # end BEGIN
  # merge path config and open listening sockets
  # configuration can also be provided in Use line.
  use HTTP::Server::Singlethreaded
     timeout => \$NotSetToAnythingForFullBlocking,
     function => { # must be a hash ref
                    '/time/' => sub {
                       "Content-type: text/plain\n\n".localtime
                    }
     },
     path => \%ChangeConfigurationWhileServingBySettingThis;
  #
  # "top level select loop" is invoked explicitly
  for(;;){
    #
    # manage keepalives on database handles
    if ((time - $lasttime) > 40){
       ...
       $lasttime = time;
    };
    # Auto restart on editing this file
    BEGIN{$OriginalM = -M $0}
    exec "perl -w $0" if -M $0 != $OriginalM;
    #
    # do pending IO, invoke functions, read statics
    # HTTP::Server::Singlethreaded::Serve()
    Serve(); # this gets exported
  }

=head1 DESCRIPTION

HTTP::Server::Singlethreaded is a framework for providing web applications without
using a web server (apache, boa, etc.) to handle HTTP.

=head1 CONFIGURATION

One of %Static, %Function, %CgiBin should contain a '/' key, this will
handle just the domain name, or a get request for /.

=head2 %Static

the %Static hash contains paths to directories where files can be found
for serving static files.

=head3 $StaticBufferSize

How much of a large file do we read in at once?  Without memory 
mapping, we have to read in files, and then write them out. Files larger
than this will get this much read from them when the output buffer is
smaller than this size.  Defaults to 50000 bytes, so output buffers
for a request should fluctuate between zero and 100000 bytes while
serving a large file.

=head2 %Function

Paths to functions => functions to run.  The entire server request is
available in C<$_> and several variables are available in C<%_>.  C<$_{PATH_INFO}>,C<$_{QUERY_STRING}> are of interest. The whole standard CGI environment
will eventually appear in C<%_> for use by functions but it does not yet.

=head2 %CgiBin

CgiBin is a functional wrapper that forks and executes a named
executable program, after setting the common gateway interface
environment variables and changing
directory to the listed directory. NOT IMPLEMENTED YET

=head2 @Port

the C<@Port> array lists the ports the server tries to listen on.

=head2 name-based virtual hosts

not implemented yet; a few configuration interfaces are possible,
most likely a hash of host names that map to strings that will be
prepeneded to the key looked up in %Path, something like

   use HTTP::Server::Singlethreaded 
      vhost => {
         'perl.org' => perl =>
         'www.perl.org' => perl =>
         'web.perl.org' => perl =>
         'example.org' => exmpl =>
         'example.com' => exmpl =>
         'example.net' => exmpl =>
         'www.example.org' => exmpl =>
         'www.example.com' => exmpl =>
         'www.example.net' => exmpl =>
      },
      static => {
         '/' => '/var/web/htdocs/',
         'perl/' => '/var/vhosts/perl/htdocs',
         'exmpl/' => '/var/vhosts/example/htdocs'
      }
   ;

Please submit comments via rt.cpan.org.

=head2 $Timeout

the timeout for the select.  C<0> will cause C<Serve> to simply poll.
C<undef>, to cause Serve to block until thereis a connection, can only
be passed on the C<use> line.

=head2 $MaxClients

if we have more active clients than this we won't accept more. Since
we're not respecting keepalive at this time, this number indicates
how long of a backlog singlethreaded will maintain at any moment,and
should be orders of magnitude lower than the number of simultaneous
web page viewers possible. Depending on how long your functions take.

=head2 $WebEmail

an e-mail address for whoever is responsible for this server,
for use in error messages.

=head2 $forkwidth  ( commented out by default )

Set $forkwidth to a number greater than 1
to have singlethreaded fork after binding. If running on a
multiprocessor machine for instance, or if you want to verify
that the elevator algorithm works. After C<import()>, $forkwidth
is altered to indicate which process we are in, such as
"2 of 3". The original gets an array of the process IDs of all
the children in @kids, as well as a $forkwidth variable that
matches C</(\d+) of \1/>. Also, all children are sent a TERM
signal from the parent process's END block.  Uncomment the
relevant lines in the module source if you need this. Forking after
initializing the module should work too.  This might get removed
as an example of featureitis.

=head2 $uid and $gid

when starting as root in a *nix, specify these numerically. The
process credentials will be changed after the listening sockets
are bound.

=head1 Dynamic Reconfiguration

Dynamic reconfiguration is possible, either by directly altering
the configuration variables or by passing references to import().

=head1 Action Selection Method

The request is split on slashes, then matched against the configuration
hash until there is a match.  Longer matching pieces trump shorter ones.

Having the same path listed in more than one of C<%Static>,
C<%Functions>, or C<%CgiBin> is
an error and the server will not start in that case. It will die
while constructing C<%Path>.

=head1 Writing Functions For Use With HTTP::Server::Singlethreaded

This framework uses the C<%_> hash for passing data between elements
which are in different packages.

=head2 Data you get

=head3 the whole enchilada

The full RFC2616-sec5 HTTP Request is available for inspection in C<$_>.
Certain parts have been parsed out and are available in C<%_>. These
include

=head3 Method

Your function can access all the HTTP methods. You are not restricted
to GET or POST as with the CGI environment.

=head3 URI

Whatever the client asked for.

=head3 HTTPver

such as C<1.1>

=head3 QUERY_STRING, PATH_INFO

as in CGI

=head2 Data you give

The HandleRequest() function looks at two data only:

=head3 ResultCode

C<$_{ResultCode}> defaults to 200 on success and gets set to 500
when your function dies.  C<$@> will be included in the output.
Singlethreaded knows all the result code strings defined in RFC2616.

As of late 2004, Mozilla FireFox will show you error messages while
Microsoft Internet Explorer hides error messages from its users, at
least with the default configuration.

=head3 Data

Store your complete web page output into C<$_{Data}>, just as you
would write output starting with server headers when writing
a simple CGI program. Or leave $_{Data} alone and return a valid
page, beginning with headers.  When returning a continuation coderef
and data both, the data must be stored in  C<$_{Data}>.

=head1 AVOIDING DEADLOCKS

The server blocks while reading files and executing functions.  You may use a closure
to describe a callback.  %_ is restored between callbacks while handling a request.

=head1 CALLBACK FUNCTIONS 

Instead of a string to send to the client, the function 
returns a coderef to indicate
that Singlethreaded needs to check back later to see if the page
is ready, by running the coderef, next time around.  Data for
the client, if any, must be stored in C<$_{Data}> when you want
the callback to be called again (indicated by continuing to return
a coderef.)

When the callback function returns a non-reference, that string is
considered the end of the response.

=head2 example

Lets say we have two functions called C<Start()> and C<More($)> that
we are wrapping as a web service with Singlethreaded. C<Start> returns
a handle that is passed as an argument to C<More> to prevent instance
confusion.  C<More> will
return either some data or emptystring or undef when it is done.  Here's
how to wrap them:

   sub StartMoreWrapper{
      my $handle = Start or die "Start() failed";
      $_{Data} = <<HEAD;
   Content-type: text/html

   <html><body bgcolor="FFFFFF">
   Here are the results from More:
   <pre>
   HEAD

      my $continue_coderef = sub{
         my $rv = More($handle);
         if(defined $rv){
              $_{Data} = $rv;
              return ($con);
         };
         <<TAIL;
   </pre> thanks for playing </body></html>
   TAIL
      }
   }

And be sure to put C<'/startresults' => \&StartMoreWrapper> into the
functions hash.



=head1 What Singlethreaded is good for

Singlethreaded is designed to provide a web interface to a database,
leveraging a single persistent DBI handle into an unlimited number
of simultaneous HTTP requests.  

It will work to serve a mini-cpan repository.

It has been used to create a JSON message-passing hub.

=head1 HISTORY

=over 8

=item 0.01

August 18-22, 2004.  %CgiBin is not yet implemented.

=item 0.02

August 22, 2004.  Nonblocking sockets apparently just
plain don't exist on Microsoft Windows, so on that platform
we can only add one new client from each listener on each
call to serve. Which should make no difference at all. At least
not noticeable. The connection time will be longer for some of
the clients in a burst of simultaneous connections.  Writing
around this would not be hard: another select loop that only
cares about the Listeners would do it.

=item 0.03

The listen queue will now be drained until empty on platforms
without nonblocking listen sockets thanks to a second C<select>
call.

Large files are now read in pieces instead of being slurped whole.

=item 0.04

Support for continuations for page generating functions is in place.

=item 0.05

Support for POST data is in place. POST data appears in C<$_{POST_DATA}>.
Other CGI variables now available in C<%_> include PATH_INFO, QUERY_STRING, REMOTE_ADDR, REQUEST_METHOD, REQUEST_URI and SCRIPT_NAME.

=item 0.06

Fixed a bug with serving files larger than the chunksize, that inserted
a gratuitous newline.  Singlethreaded will now work to serve a minicpan
mirror.

=item 0.08 March, 2008

address of this end of the connection now available

=item 0.10  June, 2008

improved handling of callbacks

improved association logic WRT trailing slashes

repeated selects inside C<Serve()> while outputting

only writing one byte at a time on Windows,
where Cygwin's syswrite does not
do partial writes. (patch welcome to improve this situation)

less debugging output by default, and some informational prints
changed to warnings (to get line number info)

=item 0.11  July, 2008

removed "poll" functions, which were redundant with "continue" functions.  Any
reference returned from a function is now presumed to be a coderef.  This will
break any installed code that used the "poll" feature or returned the continue
coderef in a hashref or arrayref as previously allowed.

There was a serious problem preventing continuation systems from working right,
so I doubt anyone was using those features.

=item 0.12  July, 2009

silenced a warning about C<$_{Data}> being uninitialized

instead of actually implementing keep-alive, added a "Connection: close" header
line at the beginning of each response

=back

=head1 EXPORTS

C<Serve()> is exported, and must be called in a loop.

=head1 AUTHOR

David Nicol E<lt>davidnico@cpan.orgE<gt> 

This module is released AL/GPL, the same terms as Perl.

=head1 References

Paul Tchistopolskii's public domain phttpd 

HTTP::Daemon

the University of Missouri - Kansas City Task Definition Interface

perlmonks

TipJar LLC chat hub system (http://tipjar.com/nettoys/bathtub.html)

=cut

