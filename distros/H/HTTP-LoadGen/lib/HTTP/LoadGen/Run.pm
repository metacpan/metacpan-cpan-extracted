package HTTP::LoadGen::Run;

BEGIN {
  {
    package HTTP::LoadGen::Run::_dbg;
    use Filter::Simple sub {
      s/^(\s*)#D /$1/mg if $ENV{"HTTP__LoadGen__Run__dbg"};
    };
  }
  HTTP::LoadGen::Run::_dbg->import;
}

use strict;
use warnings;
no warnings qw!uninitialized!;
use Coro;
use Coro::Signal ();
use AnyEvent;
use AnyEvent::TLS;
use AnyEvent::Socket ();
use AnyEvent::Handle ();
use Errno qw/EPIPE/;

{
  our $VERSION = '0.03';

  use Exporter qw/import/;
  our @EXPORT=qw/RC_STATUS RC_STATUSLINE RC_STARTTIME RC_CONNTIME RC_FIRSTTIME
		 RC_HEADERTIME RC_BODYTIME RC_HEADERS RC_BODY RC_HTTPVERSION
		 RC_DNSCACHED RC_CONNCACHED
		 RQ_METHOD RQ_SCHEME RQ_HOST RQ_PORT RQ_URI RQ_PARAM
		 KEEPALIVE_USE KEEPALIVE_STORE KEEPALIVE/;
}

# this is if defined a hash reference.
# The elements are hostname=>ddd.ddd.ddd.ddd
# It is overwritten only if said so by parameters.
my $dnscache;
sub dnscache () : lvalue {$dnscache};

# In normal mode this is "$destip $destport"=>[$connectionhandle1, ...].
# In debugging mode (if $ENV{"HTTP__LoadGen__Run__dbg"}) $connectionhandle
# is replaced by [$connectionhandle, $localport, $localip]
my %conncache;
sub conncache () {\%conncache}
{
  no warnings 'redefine';
  *conncache=\&HTTP::LoadGen::conncache if exists $INC{'HTTP/LoadGen.pm'};
}

my %tls_cache;
sub tlscache () {\%tls_cache}
{
  no warnings 'redefine';
  *tlscache=\&HTTP::LoadGen::tlscache if exists $INC{'HTTP/LoadGen.pm'};
}

use constant {
  KEEPALIVE_USE=>1,		# use a kept alive connection if available
  KEEPALIVE_STORE=>2,		# keep the connection alive if possible
  KEEPALIVE=>3,			# USE|STORE combined

  RQ_METHOD=>0,			# req params see $el in run_urllist
  RQ_SCHEME=>1,
  RQ_HOST=>2,
  RQ_PORT=>3,
  RQ_URI=>4,
  RQ_PARAM=>5,

  RC_STATUS=>0,			# indices into run_url's result
  RC_STATUSLINE=>1,
  RC_HTTPVERSION=>2,
  RC_STARTTIME=>3,
  RC_CONNTIME=>4,
  RC_FIRSTTIME=>5,
  RC_HEADERTIME=>6,
  RC_BODYTIME=>7,
  RC_HEADERS=>8,
  RC_BODY=>9,
  RC_DNSCACHED=>10,
  RC_CONNCACHED=>11,

  DEFAULT_TIMEOUT=>300,		# connection inactivity timeout
};

sub build_req {
  my ($method, $scheme, $host, $port, $uri, $param)=@_;
  my $hdr=$param->{headers} || [];
  my ($need_host_hdr, @h, $body);

  my $eol="\015\012";

  $need_host_hdr=1;
  for (my $i=0; $i<@$hdr; $i+=2) {
    push @h, $hdr->[$i].': '.$hdr->[$i+1];
    undef $need_host_hdr if lc($hdr->[$i]) eq 'host';
  }
  unshift @h, 'Host: '.$host.($scheme eq 'https'
			      ? ($port==443 ? '' : ':'.$port)
			      : ($port==80  ? '' : ':'.$port))
    if $need_host_hdr;

  if (exists $param->{body}) {
    $body=$param->{body};
    push @h, 'Content-Length: '.length $body if length $body;
  } else {
    $body='';
  }

  return (join( $eol, "\u$method $uri HTTP/1.1", @h ).$eol.$eol.$body);
}

sub gen_cb {
  my ($store_time)=@_;
  my $sig=Coro::Signal->new;
  my @queue;
  return (sub {
	    if (defined $$store_time) {
	      $$$store_time=AE::now;
	      undef $$store_time;
	    }
	    push @queue, [@_];
	    $sig->send if $sig->awaited;
	  },
	  sub {$sig->wait unless @queue; @{shift @queue}});
}

# use push_read($cb) here since the built-in 'line' doesn't handle
# lines with single embedded \r correctly, e.g. "aa\rbb\r\n" is not
# accepted as a 'line'
sub readln {
  my ($handle, $cb, $wait)=@_;
  $handle->push_read
    (sub {
       $_[0]->{rbuf} =~ s/^(([^\015\012]|\015(?!\012))*)(\015?\012)// or return;
       $cb->($_[0], $1, $2);
       1;
     });
  wantarray ? ($wait->())[1,2] : ($wait->())[1];
}

sub readchunk {
  my ($handle, $cb, $wait, $len)=@_;
  $handle->push_read(chunk=>$len, $cb);
  ($wait->())[1];
}

sub readchunked {
  my ($handle, $cb, $wait)=@_;
  my $body='';
  my ($len, $xlen);

  {
    $xlen=readln $handle, $cb, $wait;
    return unless length $xlen;
    $len=hex $xlen;
    #D warn "  --> readchunked: about to read chunk of $len (hex:$xlen) bytes\n";
    if( $len==0 ) {
      readln $handle, $cb, $wait; # read the line break after the 0-chunk
      return $body;
    }
    $body.=readchunk $handle, $cb, $wait, $len;
    readln $handle, $cb, $wait;	# read the line break after the chunk
    redo;
  }
}

sub readEOF {
  my ($handle, $cb, $wait)=@_;
  $handle->on_eof(undef);
  $handle->on_error(sub {$cb->(delete $_[0]->{rbuf})});
  $handle->on_read(sub {});
  ($wait->())[0];
}

sub tlsctx {
  my ($ctx)=@_;
  return $ctx unless ref $ctx eq 'HASH';
  my $c=tlscache;
warn "c=$c, ctx=$c->{$ctx}";
  return $c->{$ctx}||=AnyEvent::TLS->new(%$ctx);
}

sub config_handle {
  my ($handle, $cb, $err, $eof, $restart, $was_cached)=@_;
  $handle->on_error
    (sub {
       if ($!==EPIPE || $!==0 and $was_cached) {
	 $$restart=1;
       } else {
	 @{$err}[RC_STATUS, RC_STATUSLINE]=(599, $_[2]);
       }
       #D warn "Caught Error: $_[2] / fatal=$_[1]\n";
       $cb->();
     });
  $handle->on_eof
    (sub {
       $$eof=1;
       #D warn "Caught EOF\n";
       $cb->();
     });
  $handle->on_starttls
    (sub {
       @{$err}[RC_STATUS, RC_STATUSLINE]=(599, $_[2]) unless $_[1];
       #D if( $_[1] ) {
       #D   warn "TLS Handshake done\n";
       #D } else {
       #D   warn "TLS Handshake failed: $_[2]\n";
       #D }
       $cb->();
     });
}

my @no_response_body_codes;
my %no_response_body_methods;

sub register_no_response_body_method {
  $no_response_body_methods{$_[0]}=1;
}

sub delete_no_response_body_method {
  delete $no_response_body_methods{$_[0]};
}

sub register_no_response_body_code {
  $no_response_body_codes[$_[0]]=1;
}

sub delete_no_response_body_code {
  undef $no_response_body_codes[$_[0]];
}

sub no_response_body {
  #my ($code, $method)=@_;
  $no_response_body_codes[$_[0]] ||
    exists $no_response_body_methods{$_[1]};
}

BEGIN {
  for (100..199, 204, 304) {
    register_no_response_body_code $_;
  }
  register_no_response_body_method 'HEAD';
}

sub run_url {
  my ($method, $scheme, $host, $port, $uri, $param)=@_;
  $method=uc $method;
  $scheme=lc $scheme;
  $host=lc $host;

  my $store_time;
  my ($cb, $wait)=gen_cb \$store_time;
  my (@rc, @err, $eof, $line);

  #D warn "Starting $method $scheme://$host:$port$uri\n";

  my $ip;
  if( defined $dnscache ) {
    if( exists $dnscache->{$host} ) {
      $ip=$dnscache->{$host};
      $rc[RC_DNSCACHED]=1;
    } else {
      AnyEvent::Socket::inet_aton $host, $cb;
      my @addr=$wait->();
      if( @addr ) {
	$dnscache->{$host}=$ip=AnyEvent::Socket::format_address $addr[0];
      } else {
	@err[RC_STATUS, RC_STATUSLINE]=(599, "Cannot resolve host $host");
	return (\@err, undef);
      }
      $rc[RC_DNSCACHED]=0;
    }
  } else {
    AnyEvent::Socket::inet_aton $host, $cb;
    my @addr=$wait->();
    if( @addr ) {
      $ip=AnyEvent::Socket::format_address $addr[0];
    } else {
      @err[RC_STATUS, RC_STATUSLINE]=(599, "Cannot resolve host $host");
      return (\@err, undef);
    }
    $rc[RC_DNSCACHED]=0;
  }

  #D warn "$host resolves to IP $ip".($rc[RC_DNSCACHED]?' (cached)':'')."\n";

  my $conncache=conncache;

  my ($connh, $restart);
  #D my ($lip, $lport);		# only used when debugging
 RESTART: {
    #D warn "Restarting connection to $ip:$port\n" if $restart;
    undef $restart;
    undef $connh;
    undef $store_time;
    undef $eof;

    my $key;

    if( exists $param->{keepalive} and
	$param->{keepalive}&KEEPALIVE_USE and
	exists $conncache->{$key="$ip $port"} and
	$connh=do{my $l=$conncache->{$key};
		  shift @$l while(@$l and !$l->[0]->[1]); # drop all unusables
		  shift @$l} ) {
      #D ($lport, $lip)=@{$connh}[2,3];
      $connh=$connh->[0];

      $rc[RC_CONNCACHED]=1;

      #D warn "Using kept-alive connection ".
      #D      $lip.':'.$lport." ==> $ip:$port\n";

      $rc[RC_STARTTIME]=$rc[RC_CONNTIME]=AE::now;
      config_handle $connh, $cb, \@err, \$eof, \$restart, 1;
    } else {
      $rc[RC_CONNCACHED]=0;
      AnyEvent::Socket::tcp_connect $ip, $port, $cb, sub {
	$rc[RC_STARTTIME]=AE::now;
	$store_time=\$rc[RC_CONNTIME];
	exists $param->{conn_timeout} ? $param->{conn_timeout} : 0;
      };

      unless( ($connh)=$wait->() ) {
	#D warn "Connection to $ip failed: $!";
	@err[RC_STATUS, RC_STATUSLINE]=(599, "Connection failed: $!");
	return (\@err, $connh);
      }

      #D ($lport, $lip)=AnyEvent::Socket::unpack_sockaddr getsockname $connh;
      #D $lip=AnyEvent::Socket::format_address $lip;

      #D warn "New connection established ".
      #D      $lip.':'.$lport." ==> $ip:$port\n";

      $connh=AnyEvent::Handle->new( fh=>$connh,
				    timeout=>(exists $param->{timeout}
					      ? $param->{timeout}
					      : DEFAULT_TIMEOUT),
				    peername=>$host,
				    (exists $param->{tls_ctx}
				     ? (tls_ctx=>tlsctx $param->{tls_ctx})
				     : ()) );

      config_handle $connh, $cb, \@err, \$eof, \$restart, 0;
      if ($scheme eq "https") {
	#D warn "Starting TLS\n";
	$connh->starttls('connect');
	$wait->();
	return (\@err, $connh) if @err;
      }
    }

    #D {
    #D   my $rq=build_req $method, $scheme, $host, $port, $uri, $param;
    #D   $rq=~s/\n?\z/\n/;
    #D   warn "--Sending Request----------------------------------------\n".
    #D        $rq.
    #D        "--Response Header----------------------------------------\n";
    #D }

    $connh->push_write(build_req $method, $scheme, $host, $port, $uri, $param);

    # read status line
    $store_time=\$rc[RC_FIRSTTIME];
    $line=readln $connh, $cb, $wait;
    #D if( $restart ) {
    #D   warn "RESTARTING\n".
    #D        "  line='$line'\n".
    #D        "----rbuf-----------------------------------------------\n".
    #D        $connh->{rbuf}.
    #D        "\n----end of rbuf----------------------------------------\n";
    #D }
    redo RESTART if $restart;

    return (\@err, $connh) if @err; # error

    #D warn "$line\n";
    unless (@rc[RC_HTTPVERSION, RC_STATUS, RC_STATUSLINE]=
	    $line=~m!^HTTP/(\d+\.\d+)\s+(\d+)(?:\s+(.+))!) {
      redo RESTART if length !$line and $rc[RC_CONNCACHED];

      @err[RC_STATUS, RC_STATUSLINE]=(599, "Invalid HTTP status line: $line");
      return (\@err, $connh);
    }
  }

  # read header
  $rc[RC_HEADERS]=\my %headers;
  my ($name, $value);
  while (defined($line=readln $connh, $cb, $wait) and length $line) {
    #D warn "$line\n";
    if( ($name, $value)=$line=~/^(\S+)\s*:\s*(.+)/ ) {
      $name=lc $name;
      push @{$headers{$name}}, $value;
    } elsif(!defined $name) {
      @err[RC_STATUS, RC_STATUSLINE]=(599, "Invalid HTTP header block");
      return (\@err, $connh);
    } else {			# MIME continuation lines
      $line=~s/^\s+//;
      my $l=$headers{$name};
      $l->[$#{$l}].=$line;
    }
  }

  $rc[RC_HEADERTIME]=AE::now;

  # don't read the response body if the message MUST NOT include one
  # STATUS 1xx, 204, 304 and HEAD requests

  unless (no_response_body $rc[RC_STATUS], $method) {
    if( exists $headers{'transfer-encoding'} and
	$headers{'transfer-encoding'}->[0] ne 'identity' ) {
      # according to RFC2616 section 4.4 anything other than 'identity'
      # means 'chunked'
      $rc[RC_BODY]=readchunked $connh, $cb, $wait;
      return (\@err, $connh) if @err;
    } elsif(exists $headers{'content-length'}) {
      $rc[RC_BODY]=readchunk $connh, $cb, $wait,
	                     $headers{'content-length'}->[0];
      return (\@err, $connh) if @err;
    #} elsif( ct=multipart/byteranges ) {    # not implemented
    } else {
      $rc[RC_BODY]=readEOF $connh, $cb, $wait;
      return (\@err, $connh) if @err;
    }
  }

  $rc[RC_BODYTIME]=AE::now;

  #D warn "--Response Body------------------------------------------\n".
  #D      ($ENV{"HTTP__LoadGen__Run__dbg"}>1
  #D       ? do {my $s=$rc[RC_BODY]; $s=~s/\n?$/\n/; $s}
  #D       : "BODY omitted: set HTTP__LoadGen__Run__dbg>1 to get it\n")
  #D   unless(no_response_body $rc[RC_STATUS], $method);
  #D warn "---------------------------------------------------------\n";

  # update connection cache
  if(!$eof and
     exists $param->{keepalive} and
     ($param->{keepalive} & KEEPALIVE_STORE) and
     ($rc[RC_HTTPVERSION]>=1.1 &&
      !(exists $headers{connection} and
	$headers{connection}->[0]=~/close/i) or
      $rc[RC_HTTPVERSION]<1.1 &&
      (exists $headers{connection} and
       $headers{connection}->[0]=~/keep-alive/i))) {
    my $ccel=[$connh, 1];
    #D push @$ccel, $lport, $lip;
    $connh->on_starttls(undef);
    $connh->on_read(undef);
    $connh->on_eof(undef);
    # EOF as well as any other error is now handled by on_error
    $connh->on_error(sub {
		       #D warn "Connection ($ccel->[3]:$ccel->[2])=>($ip:$port) closed while cached: $_[2]\n";
		       $ccel->[1]=0;
		     });
    push @{$conncache->{"$ip $port"}}, $ccel;
  }

  return (\@rc, $connh);
}

sub run_urllist {
  my ($o)=@_;
  my ($times, $before, $after, $itgenerator)=
    @{$o}{qw/times before after InitURLs/};

  for( my $i=0; $times<=0 or $i<$times; $i++ ) {
    my ($el, $rc, $connh);
    for( my $it=$itgenerator->(); $el=$it->($rc, $el); ) {
      $before->($el) if $before;
      ($rc, $connh)=run_url @$el;
      if($after) {
	$after->($rc, $el, $connh) and return;
      }
    }
  }
}

1;
__END__

=encoding utf8

=head1 NAME

HTTP::LoadGen::Run - HTTP client for HTTP::LoadGen

=head1 SYNOPSIS

 BEGIN {$ENV{HTTP__LoadGen__Run__dbg}=1} # turn on debugging
 use HTTP::LoadGen::Run;

 # where to cache DNS lookup results
 HTTP::LoadGen::Run::dnscache=\%cache;

 # fetch an URL
 $rc=HTTP::LoadGen::Run::run_url $method, $scheme, $host, $port, $uri, $param;

 # fetch a list of URLs
 HTTP::LoadGen::Run::run_urllist +{times=>10,
                                   before=>sub {...},
                                   after=>sub {...},
                                   InitURLs=>sub {...}};

=head1 DESCRIPTION

C<HTTP::LoadGen::Run> implements the HTTP client for L<HTTP::LoadGen>.

=head2 Functions

=head3 $rc=HTTP::LoadGen::Run::run_url $method, $scheme, $host, $port, $uri, $param

performs one HTTP request as specified by the parameters.
See L<URLList in HTTP::LoadGen|HTTP::LoadGen/URLList (either InitURLs or URLList or both must be present)> for more information on the parameters.

Note, C<predelay> and C<postdelay> specifications are evaluated by
L<HTTP::LoadGen::loadgen()|HTTP::LoadGen/HTTP::LoadGen::loadgen \%data>.
So, they don't have any effect here.

=head3 HTTP::LoadGen::Run::run_urllist \%config

performs a set of HTTP requests one at a time using C<run_url>. C<%config>
is a hash that may contain these keys:

=over 4

=item InitURLs

The value is an iterator generator as described in
L<InitURLs in HTTP::LoadGen|HTTP::LoadGen/InitURLs (either InitURLs or URLList or both must be present)>.

This value must be a code reference. There are no predefined iterators here.

=item times

see L<times in HTTP::LoadGen|HTTP::LoadGen/times (optional)>.

=item before

an optional code reference called as

 $config->{before}->($rq);

before each request. The C<ReqStart> hook in L<HTTP::LoadGen> is implemented
this way.

=item after

an optional code reference called as

 $config->{before}->($rc, $rq);

after each request. The C<ReqDone> hook in L<HTTP::LoadGen> is implemented
this way.

=back

=head3 HTTP::LoadGen::Run::dnscache

an lvalue function that allows to set/get a hash where DNS lookup results
are cached.

=head3 HTTP::LoadGen::Run::register_no_response_body_method $method

register a new HTTP method that is expected to not send a response body
by default. Normally, C<HEAD> is the only one that shows that behavior.

=head3 HTTP::LoadGen::Run::delete_no_response_body_method $method

delete a method from the set that do not send a response body.

=head3 HTTP::LoadGen::Run::register_no_response_body_code $http_code

register a new HTTP status code that is known to not include a response body
by default. Normally, C<1xx>, C<204> and C<304> show that behavior.

=head3 HTTP::LoadGen::Run::delete_no_response_body_code $http_code

delete a HTTP status code from the set that do not include a response body.

=head3 $no_body=HTTP::LoadGen::Run::no_response_body $http_code, $method

asks if a pair of HTTP status and request method is expected to include
a response body.

returns true if the body is omitted.

=head3 HTTP::LoadGen::Run::conncache

the cache of kept-alive connections. Returns a hash ref.

=head3 HTTP::LoadGen::Run::build_req

internal use.

=head3 HTTP::LoadGen::Run::config_handle

internal use.

=head3 HTTP::LoadGen::Run::gen_cb

internal use.

=head3 HTTP::LoadGen::Run::readEOF

internal use.

=head3 HTTP::LoadGen::Run::readchunk

internal use.

=head3 HTTP::LoadGen::Run::readchunked

internal use.

=head3 HTTP::LoadGen::Run::readln

internal use.

=head3 HTTP::LoadGen::Run::tlscache

internal use, experimental.

=head3 HTTP::LoadGen::Run::tlsctx

internal use, experimental.

=head1 EXPORT

All of the following constants are exported by default.
See also L<HTTP::LoadGen>.

=head2 Keep-Alive specification

=over 4

=item KEEPALIVE_USE (C<1>)

it is permitted to use a kept-alive connection if available

=item KEEPALIVE_STORE (C<2>)

it is permitted to keep the connection alive for later usage

=item KEEPALIVE (C<3>)

both of the above

=back

=head2 Request descriptor

These constants are indices into an array returned by the URL iterator.

=over 4

=item RQ_METHOD (C<0>)

the HTTP request method, C<GET>, C<POST>, etc.

=item RQ_SCHEME (C<1>)

C<http> or C<https>.

=item RQ_HOST (C<2>)

the hostname or IP address

=item RQ_PORT (C<3>)

the port number

=item RQ_URI (C<4>)

the URI.

=item RQ_PARAM (C<5>)

the C<$param> hash.

=back

=head2 Result elements

These constants are indices into the array returned by C<run_url>.

=over 4

=item RC_STATUS (C<0>)

=item RC_STATUSLINE (C<1>)

=item RC_HTTPVERSION (C<2>)

=item RC_STARTTIME (C<3>)

=item RC_CONNTIME (C<4>)

=item RC_FIRSTTIME (C<5>)

=item RC_HEADERTIME (C<6>)

=item RC_BODYTIME (C<7>)

=item RC_HEADERS (C<8>)

=item RC_BODY (C<9>)

=item RC_DNSCACHED (C<10>)

=item RC_CONNCACHED (C<11>)

see L<HTTP::LoadGen/Request descriptor and return element>.

=back

=head1 SEE ALSO

L<HTTP::LoadGen>

=head1 AUTHOR

Torsten Förtsch, E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Torsten Förtsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
