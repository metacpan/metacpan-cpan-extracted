package LaBrea::Tarpit::Get;

#require 5.005_62;
use strict;
#use diagnostics;
#use warnings;
use vars qw($VERSION @ISA @EXPORT_OK);

$VERSION = do { my @r = (q$Revision: 1.05 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use LaBrea::NetIO qw(open_tcp);
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	parse_http_URL
	open_http
	parse_http_response
	short_response
	make_line
	not_hour
	not_day
	auto_update
);

## No Autoload function, all subs are used at least once

=head1 NAME

LaBrea::Tarpit::Get

=head1 SYNOPSIS

  use LaBrea::Tarpit::Get;

  ($rv,$host,$port,$path)=parse_http_URL($url)
  ($handle,$host,$port,$path)=open_http(*S,$url);
  $rv=parse_http_response(\$buffer,\%response);
  $rv=short_response($url,\%response,\%content,$timeout);
  $line = make_line($url,$err,\%content);
  $rv = not_hour($file);
  $rv = not_day($file);
  $rv=auto_update($url,$file,$cur_ver,$timeout);

=head1 DESCRIPTION - LaBrea::Tarpit::Get

Module connects to a web site running
LaBrea::Tarpit::Report::html_report.plx and retrieves a short_report as
described in LaBrea::Tarpit::Report.

Run C<examples/web_scan.pl> from a cron job hourly or 
daily to update the statistics from all know sites running
LaBrea::Tarpit. A report can then be generated showing the activity
worldwide. 

 # MIN HOUR DAY MONTH DAYOFWEEK   COMMAND
 30 * * * * ./web_scan.pl ./other_sites.txt ./tmp/site_stats

See: LaBrea::Tarpit::Report::other_sites

=over 2

=item ($handle,$host,$port,$path)= parse_http_URL($url);

Separate an http URL into its components

  input:	URL of the form
	http://www.foo.com[:8080]/file.html

  https:// service is not supported

  returns: (undef, error message)
		or
	   (file_handle,hostname,port,path)
	where port and path may be empty

=cut

sub parse_http_URL {
  my ($url) = @_;
  return (undef, 'URL must begin with http://')
	unless $url =~ m|^http://|;
  my $port = '';
  my $path = '';
  my $remote;
  if ( $url =~ m|http://([a-zA-Z0-9\-\.]+)(/[^?]+)|i ) {
    $remote	= $1;
    $path	= $2;
  } elsif ( $url =~ m|http://([a-zA-Z0-9\-\.]+):(\d+)(/[^?]+)|i ) {
    $remote	= $1;
    $port	= $2;
    $path	= $3;
  } elsif ( $url =~ m|http://([a-zA-Z0-9\-\.]+)|i ) {
    $remote	= $1
  } else {
    return (undef,'invalid URL');
  }
  return (1,$remote,$port,$path);
}

=item ($handle,$host,$port,$path)=open_http(*S,$url);

Open connection to http target

  input:	*S,$url	[default port = 80]
  returns:	(undef, error)	on error

		(file_handle,
		 hostname,
		 port
		 path )		on success

=cut

sub open_http {
  my ($S,$x) = @_;
  my ($s,$remote,$port,$path) = parse_http_URL($x);
  return (undef,$remote) unless $s;	# return error if any
  return (undef,'missing filename') unless $path;
  $port = 80 unless $port;
  $x = open_tcp($S,$remote,$port);
  return (undef,$x) if $x;
  return ($S,$remote,$port,$path)
}

=item $rv=parse_http_response(\$buffer,\%response);

Parse an http server response into a hash of headers.

  i.e.	(representative, will vary)

  rc		 => 200
  msg		 => OK
  date		 => Wed, 24 Apr 2002 21:46:30 GMT
  server	 => Apache/1.3.22
  protocol	 => HTTP/1.1
  content-type	 => text/plain
  content-length => 92
  last-modified	 => Wed, 24 Apr 2002 21:46:34 GMT
  expires	 => Wed, 24 Apr 2002 21:47:04 GMT
  connection	 => close
  content	 => (complete text buffer)

  input:	\$text_in, \%response
  returns:	true on success, %response filled
		false on failure

  NOTE:		%response{rc}	(server response code)
		%response(msg}	(server messages)
		are ALWAYS filled with something.
		In the case of server failure, the 
		cause of the failure will be inserted
		into %response(msg} and undef returned.

=cut

###################################################
# parse_http_response
#
# input:	\$buffer,\%response
# return:	true on success, else false
#		response is filled
#
sub parse_http_response {
  my ($b,$r) = @_;
  $$b =~ s/\r//g;		# remove dos returns
  @_ = split('\n',$$b);
  %$r = ();
# get response protocol and response code
  unless ( $_[0] =~ /([^\s]+)\s+(\d+)\s*(.*)/ ) {
    $r->{rc} = '';
    $r->{msg} = 'unknown server response';
    return undef;
  } else {
    $r->{protocol} = $1;
    $r->{rc} = $2;
    $r->{msg} = $3 || '';
    return undef unless $2 == 200;	# response OK
  }
  shift;		# zap server response
  unless (@_) {
    $r->{msg} = 'no headers from server';   
    return undef;
  }
  while( $_ = shift @_ ) {
    last unless $_;
    my ($key,$val) = split(/:\s+/,$_,2);
    $r->{lc $key} = $val;
  }
  $r->{content} = '';
  unless (@_) {
    $r->{msg} = 'no content, no data found';
    return undef;
  }
  while( @_ ) {
    $r->{content} .= (shift @_) . "\n";
  }
  1;
}

=item $rv=short_response($url,\%response,\%content,$timeout);

Fetch the short report from C<$url> and place the headers in C<%response>,
the content, parsed, in C<%content>. Optional C<$timeout>, default is 60
seocnds.

%response contains http headers

%content contains key => value pairs

  LaBrea	=> version
  Tarpit	=> version
  Report	=> version
  Util		=> version
  now		=> seconds since epoch (local)
  tz		=> time zone (i.e. -0700)
  threads	=> number of threads
  total_IPs	=> total IP's
  bw		=> bandwidth

  input:	URL,	# complete url
	   i.e. www.foo.com/html_report.plx
		\%response,
		\%content,

  returns:	false on success
		error message on failure

=cut

sub short_response {
  my ($url,$rsp,$cnt,$timr) = @_;
  local *S;
  my ($s,$r,$port,$path) = open_http(*S,$url);
  return $r unless $s;
  $timr = 60 unless $timr;

  my $max = 1024;		# maximum response size
				# including headers
  my $buffer = '';
  eval {
    local $SIG{ALRM} = sub {
	close $s;
	die 'short_response TIMEOUT';
    };
    alarm $timr;

    print $s qq
|GET $path?short HTTP/1.0
Host: $r:$port
User-Agent: LaBrea::Tarpit::Get $VERSION

|;
  while ( $_ = readline($s) ) {
    $buffer .= $_;
    last if length($buffer) > $max;
  }
  close $s;
  alarm 0;
  };
  return 'timeout, failed to get short response'
	if $@ =~ /short_response TIMEOUT/;
  return $@ if $@;	# show other errors
  return 'invalid short response, no data' 
	unless $buffer;
  
  return $rsp->{rc} . ' ' . $rsp->{msg}
	unless parse_http_response(\$buffer,$rsp);

  return 'invalid content-type ' . $rsp->{'content-type'}
	unless $rsp->{'content-type'} =~ m|text/plain|i;

  %$cnt = split(/[=\n]/,$rsp->{content});
  return 'invalid data in short response'
	unless	exists $cnt->{LaBrea} &&
		exists $cnt->{Tarpit} &&
		exists $cnt->{Report} &&
		exists $cnt->{Util} &&
		exists $cnt->{now} &&
		exists $cnt->{tz} &&
		exists $cnt->{threads} &&
		exists $cnt->{total_IPs} &&
		exists $cnt->{bw};
  0;
}

=item $line = make_line($url,$err,\%content);

Make a line of text summarizing the short report where C<$err> is the return
value from C<short_report>

  Format:

  url threads total_IPs bw time tz version:nn:nn:nn
    or
  url error message

=cut

sub make_line {
  my ($url,$err,$cnt) = @_;
  return "$url ", ($err ||
  "$cnt->{threads} $cnt->{total_IPs} $cnt->{bw} $cnt->{now} $cnt->{tz} $cnt->{LaBrea}:$cnt->{Tarpit}:$cnt->{Report}:$cnt->{Util}");
}

=item $rv = not_hour($file);

Check if the file has been accessed this hour;

  input:	path/to/file
  returns:	true, not current hour
		false if accessed this hour
		or non-existent or not readable

=cut

sub not_hour {
  return undef unless -e $_[0] && -r $_[0];
  my @old = localtime((stat($_[0]))[8]);
  @_ = localtime(time);
  return $old[2] != $_[2] || $old[3] != $_[3];
}

=item $rv = not_day($file);

Check if the file has been accessed this day;

  input:	path/to/file
  returns:	true, not accessed this day
		false if accessed this day
		or non-existent or not readable

=cut

sub not_day {
  return 1 unless -e $_[0] && -r $_[0];
  return (localtime((stat($_[0]))[8]))[3] != (localtime(time))[3];
}

=item $rv=auto_update($url,$file,$cur_ver,$timeout);

Update the 'other_sites.txt' file from $url on a daily
basis only.

  input:  url,	# complete url to 'other_sites.txt'
	# http://scans.bizsystems.net/other_sites.txt

          file,	# path to your 'other_sites.txt'

	  cur_ver	# optional current version
	# the current file will be opened and scanned
	# if this is not supplied

	  timeout	# wait for http response	
	# default 60 seconds
  returns:	false on success or no update needed
		error msg on failure

=back

=cut

sub auto_update {
  my ($url,$file,$cur_ver,$timr,$debug) = @_;
  $timr = 60 unless $timr;
  local *S;
  my ($S,$host,$port,$path)=open_http(*S,$url);
  return $host unless $S;	# return error message
  my $buffer = '';
  eval {
      local $SIG{ALRM} = sub {
        close $S;
        die 'auto_update TIMEOUT';
      };
      alarm $timr;

      print $S <<EOF;
GET /$path HTTP/1.0
Host: $host:$port
User-Agent: LaBrea::Tarpit::Get $VERSION

EOF

      while (<$S>) {
	$buffer .= $_;
      }
      close $S;
      alarm 0;
  };			# end eval
  return 'url timed out' if $@ =~ /TIMEOUT/;
  return $@ if $@;				# return errors
  my %response;
  parse_http_response(\$buffer,\%response);
  return 'failed to find version number'
	unless $response{content} =~ /VERSION\s*=\s*(\d+)/;
  my $new_ver = $1;
  unless ($cur_ver) {		# sigh.... must get old version number
				# very inefficient
    return "failed to open $file"
	unless open(S,$file);
    while (<S>) {
      next unless $_ =~ /VERSION\s*=\s*(\d+)/;
      $cur_ver = $1;
      last;
    }
    close S;
  }
  return 'failed to find current version number'
	unless $cur_ver;
  if ( $cur_ver < $new_ver ) {
    return "failed to open $file..tmp for update"
	unless open(S,'>'.$file.'.tmp');
    $_ = select S;
    $| = 1;
    select $_;
    print S $response{content};
    close S;
# atomic update
    rename $file .'.tmp', $file unless $debug;
  }
  return undef;
}
1;
__END__

=head1 EXPORT_OK

	parse_http_URL
	open_http
	parse_http_response
	short_response
	make_line
	not_hour
	not_day
	auto_update

=head1 COPYRIGHT

Copyright 2002 - 2004, Michael Robinton & BizSystems
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or 
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=head1 AUTHOR

Michael Robinton, michael@bizsystems.com

=head1 SEE ALSO

perl(1), LaBrea::Tarpit(3), LaBrea::Codes(3), LaBrea::Tarpit::Report(3),
LaBrea::Tarpit::Util(3), LaBrea::Tarpit::DShield(3)

=cut

