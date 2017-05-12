#!/usr/bin/perl
no locale;
use Config;
# vim: set sw=4 ts=4 si et:
use File::Basename qw(basename dirname);
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
        if ($Config{'osname'} eq 'VMS' or
            $Config{'osname'} eq 'OS2');  # "case-forgiving"
open OUT,">$file" or die "Can't create $file: $!";
chmod(0755, $file);
print "Extracting $file (with variable substitutions)\n";

my $VERSION="unknown";
if (-r "../TagReader.pm"){ # get version
    open(F,"../TagReader.pm")||die;
    while(<F>){
        if (/\$VERSION *= *(.+)/){
            $VERSION=$1;
            $VERSION=~s/[^\.\d]//g;
        }
    }
    close F;
}

print OUT "$Config{'startperl'} -w
my \$VERSION = \"$VERSION\";
";

while(<DATA>){
        print OUT;
}

__END__ 
# vim: set sw=4 ts=4 si et: 
# Copyright: GPL
# Author: Guido Socher
#
no locale;
use strict;
use vars qw($opt_E $opt_e $opt_h $opt_s);
use Getopt::Std;
require 5.003;
use Socket;
# 
sub interrupt();
sub proxy_check(@);
sub httphead($$$);
sub parseurl($);
sub help();
#------------------
my @udat;
my @proxy;
my @noproxy;
my %cache; # check repleated urls only once
my $proxyvalid=0;
my $url;
my $res;
my $exitstat=0;
my ($http_proxy,$no_proxy,$l);
my $err=1;
my $dotcnt=0;
my $interruptvar=0;
my $timeoutint=11; # timeout interval in seconds (value range should be 5-25).
#------------------
#
# The http 1.0 proctocol is described in 
# RFC 1945
# This script uses also 1.1 elemets
#
#------------------
$SIG{'ALRM'}=\&interrupt;
#
$opt_e=0;
$opt_E=0;
&getopts("ehEs")||die "ERROR: No such option. -h for help.\n";
help() if ($opt_h);
#
if ($ENV{'HTTP_PROXY'}){
    $http_proxy=$ENV{'HTTP_PROXY'};
}elsif ($ENV{'http_proxy'}){
    $http_proxy=$ENV{'http_proxy'};
}
if ($ENV{'NO_PROXY'}){
    $no_proxy=$ENV{'NO_PROXY'};
}elsif ($ENV{'no_proxy'}){
    $no_proxy=$ENV{'no_proxy'};
}
if ($http_proxy){
    @proxy=parseurl($http_proxy);
    if ($proxy[0] eq 'http'){
        $proxyvalid=1;
        if ($no_proxy){
            @noproxy=split(/[, ]+/,$no_proxy);
        }
    }else{
        print STDERR "ERROR: http_proxy or HTTP_PROXY variable defined but not set correcly.\n";
        exit(1);
    }
}
if (scalar @ARGV < 1){
    # read output of tr_blck -a on stdin 
    $|=1; #flush for dot printing
    while(<>){
        chomp;
        $l=$_;
        next unless (/\w/); #ignore empty lines
        next if (/=\"\//); # ignore abs file system links
        if (/: *\w+=\"(.+)\"/){
            @udat=proxy_check(parseurl($1));
            if ($udat[0] eq 'http'){
                $interruptvar=0;
                if ($opt_E){
                    print ".";
                    $dotcnt=($dotcnt+1)%40;
                    print "\n" if ($dotcnt==0);
                }
                eval{
                    alarm $timeoutint; # the request must return in a given time sec.
                    $res=httphead($udat[1],$udat[2],$udat[3]);
                    alarm 0;
                };
                if ($interruptvar){
                    $err=1;
                    $res="ERROR: timeout";
                }
                if ($opt_e || $opt_E){
                    if ($opt_E && $err){
                        print "\n";
                        $dotcnt=0;
                    }
                    # print nothing if no error
                    print "$l :: $res\n" if ($err);
                }else{
                    print "$l :: $res\n";
                }
            }else{
                print "$l -- SORRY: not http, can not check it\n" unless($opt_e || $opt_E);
            }
        }else{
            print "$l -- SORRY: can not check this url\n" unless($opt_e || $opt_E);
        }
    }
    print "\n" if ($opt_E);
}else{
    for $url (@ARGV){
        @udat=proxy_check(parseurl($url));
        if ($udat[0] eq 'http'){
            $interruptvar=0;
            if ($opt_E){
                print ".";
                $dotcnt=($dotcnt+1)%40;
                print "\n" if ($dotcnt==0);
            }
            eval{
                alarm $timeoutint; # the request must return in $timeoutint sec.
                $res=httphead($udat[1],$udat[2],$udat[3]);
                alarm 0;
            };
            if ($interruptvar){
                $err=1;
                $res="ERROR: timeout";
            }
            if ($opt_e || $opt_E){
                if ($opt_E && $err){
                    print "\n";
                    $dotcnt=0;
                }
                # print nothing if no error
                print "$url :: $res\n" if ($err);
            }else{
                print "$url :: $res\n";
            }
            $exitstat=1 if($err);
        }else{
            print STDOUT "ERROR: can not parse url or can not get host info\n";
            $exitstat=2;
        }
    }
    print "\n" if ($opt_E);
    exit($exitstat);
}
#------------------
sub interrupt(){
    $interruptvar++;
    die "interrupt\n";
}
#------------------
# Take an array of the form ('http',$server,$port,$file)
# and check if this request should go via proxy if the proxy is set
# The result is an array of the form ('http',$server,$port,$file)
# but possibly modified for a proxy request.
sub proxy_check(@){
    my @arr=@_;
    my ($np,$nfile,$proto,$server,$port,$file);
    if (scalar @arr == 4){
        ($proto,$server,$port,$file)=@arr;
        if ($proxyvalid){
            foreach $np (@noproxy){
                if (index($server,$np) != -1){
                    # matches-> do not use proxy
                    return(@arr);
                }
            }
            # use the proxy
            if (${port} == 80){
                $nfile="$proto://${server}$file";
            }else{
                $nfile="$proto://$server:${port}$file";
            }
            return(($proto,$proxy[1],$proxy[2],$nfile));
        }
    }
    return(@arr);
}
#------------------
# take a (server,port,file) and get the HTTP head.
# file must start with /
# returns "server: reason" or "ERROR connect: reason"
# This sub sets global var $err
# Note: This function may block for ever if the server does connect
#       but not reply. It is best to put an alarm timeout arround it.
sub httphead($$$){
    my $server=shift;
    my $port=shift;
    my $file=shift;
    my ($l,$paddr,$proto,$newloc,$wserver,$reason,$result);
    my $wait_for_loc;
    my @in_addrs;
    $err=1;
    #check the cache to see if we did already verify this url:
    if($cache{"$server $file"}){
        $result=$cache{"$server $file"};
        $err=0 if ($result=~/ (200|301|302)/);
        return($result);
    }
    # generate a packed IP addr from server and port
    @in_addrs = (gethostbyname($server))[4];
    if (scalar @in_addrs > 0){
        $paddr = sockaddr_in($port,$in_addrs[0]);
    }else{
        $result="ERROR: $server lookup failure";
        $cache{"$server $file"}=$result;
        return($result);
    }
    $proto = getprotobyname('tcp');
    socket(S,PF_INET,SOCK_STREAM,$proto)||die "ERROR socket:$!\n";
    connect(S,$paddr)||return "ERROR connect: $!";
    select(S);$|=1;select(STDOUT);
    print S "HEAD $file HTTP/1.0\r\n";
    # end of request is an empty line:
    print S "User-Agent: Httpcheck/1.0 (Perl $])\r\n";
    print S "Host: $server\r\n\r\n";
    $l=0;
    $wait_for_loc=0;
    # Note: some servers keep the connection alive. Therefore we need
    #       to close the connection as soon as we have enough info.
    #       Otherwise we might accidently timeout.
    while(<S>){
        $l++;
        last if ($l > 15);
        # dbg:
        # print;
        chomp();
        s/\r$//; # remove ^M, not all servers put it!
        #The answer looks like: HTTP/1.0 200 OK 
        if (/^HTTP\S+ (.+)/){
            $reason=$1;
            $err=0 if ($reason=~ /200/);
            if ($reason=~ /301|302/){
                # Moved, wait for "Location:"
                $err=0;
                $wait_for_loc=1 
            }
            unless($reason=~ /200|301|302/){
                $reason= "ERROR: $reason";
            }
            next;
        }
        if (/^Location: (.+)/){
            $wait_for_loc=0;
            $newloc=$1;
        }
        if (/^Server: (.+)/){
            $wserver=$1;
        }
        last if (/^Content-type:/);
        #check if we have all information:
        last if ($wserver && $reason && $wait_for_loc==0);
    }
    close S;
    $wserver="UnknownServerType" unless ($wserver);
    $reason="no status code" unless ($reason);
    $wserver=~s/\s+//g;
    if ($newloc){
        $result="$wserver: $reason, New location: $newloc ";
        $result="$reason, New location: $newloc " if($opt_s);
    }else{
        $result="$wserver: $reason ";
        $result="$reason " if($opt_s);
    }
    $cache{"$server $file"}=$result;
    return($result);
}
#------------------
# Take a url of the form http://ser.ver/file
# and return (protocol,server,port,file) or 
# (nothttp) if this url can not be parsed.
sub parseurl($){
    my $url=shift;
    my ($port,$server,$file);
    if ($url=~ m%http://([\w\.\-]+)%i){
        $server=$1;
        if($url=~ m%http://[\w\.\-]+:(\d+)%i){
            $port=$1;
        }else{
            $port=80;
        }
        if($url=~ m%http://[\w\.\-\:]+/(.+)%i){
            $file="/$1";
            $file=~s/\#.+//; #take care of named anchors
        }else{
            $file="/";
        }
        ('http',$server,$port,$file);
    }else{
        ('nothttp');
    }
}
#------------------
sub help(){
    print "tr_httpcheck -- check if a particular web-pages exists 
USAGE: tr_httpcheck [-heEs] [url1 url2...]

OPTIONS: 

    -h this help

    -e print only results if an error was found

    -E Like -e but print a . for every checked url.

    -s print result in short format without the URL

If no URL is given then tr_httpcheck reads output from 
\"tr_blck -a\" on stdin and processes it. 
Note: This program does only http type of protocol checks. It can e.g not
check https or ftp.

EXAMPLES: 
 check a single url:
 tr_httpcheck http://www.oche.de/

 check many URLs extracted with tr_blck
 from web pages:
 tr_blck -a *.html |  tr_httpcheck -E

You may set the environment variable HTTP_PROXY and NO_PROXY or
http_proxy and no_proxy to use a proxy. If both are set then the
uppercase version takes precedence.
The format of the http_proxy variable looks like \"http://www-proxy:8080/\"
and the no_proxy is a comma or space seperated list of servers or domains
for which a direct connection should be made.

tr_httpcheck is part of the HTML::TagReader package.
\n";
print "Version: $VERSION\n";
    exit;
}
#------------------
__END__

=head1 NAME

tr_httpcheck -- check if a particular web-pages exists

=head1 SYNOPSIS

USAGE: tr_httpcheck [-heEs] [url1 url2...]

=head1 DESCRIPTION

tr_httpcheck is a post-processor for tr_blck to allow for checking
of absolute linke of the type http://....

=head1 OPTIONS

B<-h> this help

B<-e> print only results if an error was found

B<-E> Like -e but print a . for every checked url.

B<-s> print result in short format without the URL

If no URL is given then tr_httpcheck reads output from 
\"tr_blck -a\" on stdin and processes it. 
Note: This program does only http type of protocol checks. It can e.g not
check https or ftp.

=head1 EXAMPLES

check a single url:
tr_httpcheck http://www.oche.de/

check many URLs extracted with tr_blck
from web pages:
 tr_blck -a *.html |  tr_httpcheck -E

=head1 ENVIRONMENT

You may set the environment variable HTTP_PROXY and NO_PROXY or
http_proxy and no_proxy to use a proxy. If both are set then the
uppercase version takes precedence.
The format of the http_proxy variable looks like "http://www-proxy:8080/"
and the no_proxy is a comma or space seperated list of servers or domains
for which a direct connection should be made.

=head1 AUTHOR

tr_httpcheck is part of the HTML::TagReader package and was written by
Guido Socher [guido(at)linuxfocus.org]

=head1 NOTES

If you are interessted in a link checker to check links only via the
web-server then this is not the right program for you.  This program is
just a simple addon to tr_blck.  Other programs like e.g

http://linkchecker.sourceforge.net/ or

http://www.linklint.org/ or

http://linkchecker.stacken.kth.se/ (webpage where
you can enter a url to check)

can be used if you want to check your web-pages only
remotely via a web server.

=cut

Status-Codes according to RFC 1945
200 is OK
204 is No Content
301 is Moved Permanently
302 is Moved Temporarily
400 is Bad Request
401 is Unauthorized
403 is Forbidden
404 is Not Found
500 is Internal Server Error
501 is Not Implemented
502 is Bad Gateway
503 is Service Unavailable

Here is an example of a GET request from communicator 4.7:
GET /xxxx.html HTTP/1.0\r
Connection: Keep-Alive\r
User-Agent: Mozilla/4.07 [en] (X11; I; Linux 2.0.33 i586)\r
Host: sophus.oche.de\r
Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, image/png, */*\r
Accept-Encoding: gzip\r
Accept-Language: en\r
Accept-Charset: iso-8859-1,*,utf-8\r
\r

Here are some example answers from a number of different servers/proxies:

HTTP/1.1 200 OK
Date: Tue, 04 May 1999 18:27:37 GMT
Server: Apache/1.3.3 (Unix)  (Red Hat/Linux)
Last-Modified: Thu, 29 Apr 1999 20:12:38 GMT
ETag: "4b005-163f-3728bd36"
Accept-Ranges: bytes
Content-Length: 5695
Connection: close
Content-Type: text/html
 
HTTP/1.0 200 OK
Content-Length: 9733
Expires: Thu, 06 May 1999 14:00:03 GMT
Content-Type: text/html
Age: 0
X-Cache: MISS from Cache.RWTH-Aachen.de
Proxy-Connection: close
  
HTTP/1.0 200 OK
Last-Modified: Tue, 04 May 1999 17:50:44 GMT
Content-Type: text/html
Content-Length: 13036
Expires: Thu, 06 May 1999 17:50:46 GMT
 
HTTP/1.1 200
Date: Tue, 04 May 1999 18:30:15 GMT
Server: Apache/1.2.6
Pragma: no-cache
Connection: close
Content-Type: text/html
  
HTTP/1.1 200 OK
Server: Apache/1.3.0 (Unix) Debian/GNU PHP/3.0
Keep-alive: timeout=20, max=100
Content-type: text/html
Date: Wed, 05 May 1999 07:10:30 GMT

HTTP/1.1 301 Moved Permanently
Date: Thu, 13 May 1999 16:27:55 GMT
Server: Apache/1.3.3 (Unix)  (Red Hat/Linux)
Location: http://www.linuxfocus.org/~guido.socher/
Connection: close
Content-Type: text/html
 
ENDOFFILE

