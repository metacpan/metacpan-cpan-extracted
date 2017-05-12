#!/usr/bin/perl -w
use strict;
use lib 'lib';

use HTTP::Request::FromTemplate;
use LWP::UserAgent;

my $host = '192.168.1.103';
my $number = $ARGV[0];
my $time = time;

my $ua = LWP::UserAgent->new();
my $template = do { local $/; <DATA> };
my $req = HTTP::Request::FromTemplate->new( template => \$template )->process({ 
  host => $host,
  number => $number,
  time => $time
});
print $req->as_string;
my $res = $ua->request($req);
print $res->as_string;

__DATA__
POST http://[% host %]/cgi-bin/webcm HTTP/1.1
Host: [% host %]
Referer: http://[% host %]/cgi-bin/webcm
Content-Length: [% content_length %]
Content-Type: application/x-www-form-urlencoded

getpage=..%2Fhtml%2Fde%2Fmenus%2Fmenu2.html&errorpage=..%2Fhtml%2Fde%2Fmenus%2Fmenu2.html&var%3Alang=de&var%3Apagename=foncalls&var%3Aerrorpagename=foncalls&var%3Amenu=fon&var%3Apagemaster=&time%3Asettings%2Ftime=[% time %]%2C-60&telcfg%3Asettings%2FUseClickToDial=1&telcfg%3Asettings%2FDialPort=1&telcfg%3Acommand%2FDial=[% number %]