=head1 DESCRIPTION

This is based on test run script "local/http.t" from libwww-perl.

This test is designed to verify that extract-links can use links
extracted from web page downloads.


=cut

use strict;
use warnings;

our ($loaded, %pages, $infos, @start, $conf, $urls);

#$::verbose=0xFFF;

#BEGIN {print "1..11\n"; } #no because we are also a daemon..
END {print "not ok 1\n" unless $loaded;}
sub nogo {print "not "; }
sub ok {my $t=shift; print "ok $t\n";}


if ($^O eq "MacOS") {
  print "1..0\n";
  exit(0);
}

$| = 1;				# autoflush

require IO::Socket;		# make sure this works before we try to make a HTTP::Daemon

sub make_pages ($\%) {
  my $base=shift;
  $base=~s,/$,,;
  my $pageref=shift;
  %$pageref=
    (
     "index" => <<EOF,
<HTML><HEAD><TITLE>Test Index</TITLE></HEAD>
<BODY>

<P>
  This is the index file for testing.

<P>
  The following should be recorded then downloaded and processed
  <A HREF="$base/page.html">existing local url</A>
  The following should be recorded but failed because it doesn't exist
  <A HREF="$base/non_exist.html">non existing local url</A>
  The following should be recorded but not downloaded
  <A HREF="http://www.example.com/link_controller_no_download.html">non
  existing remode url</A>
  As should this since we don't consider numeric IP addresses
  equivalent to hostnames
  <A HREF="http://127.0.0.1/bad_download">local url that shouldn't be got</A>
</BODY>
<HTML>
EOF
     "page_html" => <<EOF,
<HTML><HEAD><TITLE>Test Page</TITLE></HEAD>
<BODY>

<P>
  This is a first test page.

<P>
  The following should be recorded then downloaded and processed
  <A HREF="$base/page2">existing local url</A>
  The following should be recorded but not downloaded
  <A HREF="http://www.example.com/link_controller_no_download2.html">non
  existing remode url</A>
</BODY>
<HTML>
EOF
     "page2" => <<EOF,
<HTML><HEAD><TITLE>Test Page</TITLE></HEAD>
<BODY>

<P>
  This is a second test page.

<P>
  The following should be recorded then downloaded and processed
  <A HREF="$base/page2">repeated existing local url</A>
  The following should be recorded but not downloaded
  <A HREF="http://www.example.com/link_controller_no_download2.html">non
  existing remode url</A>
</BODY>
<HTML>
EOF
     bad_download => <<EOF,
<HTML><HEAD><TITLE>Bad Test Page</TITLE></HEAD>
<BODY>

<P>
  This is a page that is only referenced through our own IP address.  If
  it is downloaded then we have done something wrong.

<P>
  <A HREF="http://bad_download.example.com>url which shouldn't be there</A>
</BODY>
<HTML>
EOF
    );
}

use HTTP::Status;
use HTTP::Headers;
use HTTP::Response;

# First we make ourself a daemon in another process
my $D = shift || '';
my $V = shift || '';
if ($D eq 'daemon') {

  require HTTP::Daemon;

  $V eq "verbose" and $::verbose=1;

#if this timeout is too short it seems to be cause problems with
#testing in high load situations.  It shouldn't be too long since that
#will leave a port open for longer.  However, we bind to the
#`localhost' IP aaddress and so should be reasonably safe.

  my $d = HTTP::Daemon->new(Timeout => 100, LocalAddr => '127.0.0.1');

  my $base=$d->url;

  print "Please to meet you at: <URL:", $base, ">\n";
  open(STDOUT, $^O eq 'VMS'? ">nl: " : ">/dev/null");

  %pages=();
  make_pages($base,%pages);

  print STDERR "pages defined: ", join (" ", keys %pages), "\n"
    if $::verbose;

  while (my $c = $d->accept) {
    my $r = $c->get_request;
    if ($r) {
      my $p = lc ( ($r->url->path_segments)[1] );
      $p =~ s/[^A-Za-z0-9-]/_/g;
      $p eq "" and $p = "index";
      my $m = lc( $r->method );
      my $func = "httpd_" . $m . "_$p";
    CASE: {
	defined &$func && do {
	  print STDERR "function request $m $p\n" if $::verbose;
	  no strict "refs";
	  &$func($c, $r);
	  last;
	};
	$m eq "get" and defined $pages{$p} and do {
	  print STDERR "hash request $m $p\n" if $::verbose;
	  my $cont=$pages{$p};
	  my $head=HTTP::Headers->new( Content_Type =>
				       "text/html; version=3.2",
				       "Content-Length" =>
				       length($cont));
	  my $res=HTTP::Response->new(RC_OK, status_message(RC_OK),
				      $head, $cont);
	  $c->send_response($res);
	  last;
	};
	print STDERR "unhandled request $m $p\n" if $::verbose;
	$c->send_error(404);
      }
      print STDERR "finished request\n" if $::verbose;
      $c = undef;		# close connection
    }
    print STDERR "no more requests\n" if $::verbose;
  }
  print STDERR "HTTP Server terminated\n" if $::verbose;
  exit;
} else {
  use Config;
  my $perl = $Config{'perlpath'};
  $perl = $^X if $^O eq 'VMS';
  open(DAEMON, "$perl t/extract-www.t daemon " . ($::verbose ? "verbose " : "") . "|")
    or die "Can't exec daemon: $!";
}

print "1..11\n";

my $greeting = <DAEMON>;
$greeting =~ /(<[^>]+>)/;

require URI;
my $base = URI->new($1);
sub url {
  my $u = URI->new(@_);
  $u = $u->abs($_[1]) if @_ > 1;
  $u->as_string;
}


print "Will access HTTP server at $base\n" if $::verbose;
$loaded = 1;
ok(1);

$::infos=".fixlink-infostruc-defs";
do "t/config/files.pl" or die "files.pl script not read: " . ($@ ? $@ :$!);


#die "files.pl failed $@" if $@;
#die "files.pl failed $!" if $!;

unlink $::infos;
-e $::infos and die "can't unlink infostruc file $::infos";
open DEFS, ">$infos" or die "couldn't open $infos $!";
print DEFS "www $base\n";
close DEFS or die "couldn't close $infos $!";

sub httpd_get_redirect {
  my($c) = @_;
  $c->send_redirect("/echo/redirect");
}

sub httpd_get_redirect2 { shift->send_redirect("/redirect3/") }
sub httpd_get_redirect3 { shift->send_redirect("/redirect4/") }
sub httpd_get_redirect4 { shift->send_redirect("/redirect5/") }
sub httpd_get_redirect5 { shift->send_redirect("/redirect6/") }
sub httpd_get_redirect6 { shift->send_redirect("/redirect2/") }

sub httpd_get_basic  {
  my($c, $r) = @_;
  #print STDERR $r->as_string;
  my($u,$p) = $r->authorization_basic;
  if (defined($u) && $u eq 'ok 12' && $p eq 'xyzzy') {
    $c->send_basic_header(200);
    print $c "Content-Type: text/plain";
    $c->send_crlf;
    $c->send_crlf;
    $c->print("$u\n");
  } else {
    $c->send_basic_header(401);
    $c->print("WWW-Authenticate: Basic realm=\"libwww-perl\"\015\012");
    $c->send_crlf;
  }
}

# Don't yet provide proxy support??

#  sub httpd_get_proxy
#  {
#     my($c,$r) = @_;
#     if ($r->method eq "GET" and
#         $r->url->scheme eq "ftp") {
#         $c->send_basic_header(200);
#         $c->send_crlf;
#     } else {
#         $c->send_error;
#     }
#  }

#  $ua->proxy(ftp => $base);
#  $req = new HTTP::Request GET => "ftp://ftp.perl.com/proxy";

@start = qw(perl -Iblib/lib);

my @prog= (@start, qw(blib/script/extract-links),
  "--config-file=$conf", "--out-uri-list=$urls", );

if ($::verbose ) {
  push @prog, "--verbose";
} else {
  push @prog, "--silent";
}

print STDERR "Prog: ", join (" ", @prog) , "\n"
  if $::verbose;

nogo if system @prog;

ok(2);

#check that the url list contains all things needed

open URLS, $urls;
my @urls=<URLS>;
close URLS;

print STDERR "urls output in urls list:\n ", join( " ", @urls), "\n\n"
	if $::verbose;

ok(3);

nogo unless
  grep ( m<\Q$base\Epage\.html> , @urls) == 1;

ok(4);

nogo unless
  grep ( m<\Q$base\Enon_exist\.html> , @urls) == 1;

ok(5);

nogo unless
  grep ( m<http://www\.example\.com/link_controller_no_download\.html> , @urls)
  == 1;

ok(6);

nogo unless
  grep ( m<http://127\.0\.0\.1/bad_download> , @urls) == 1;

ok(7);

nogo unless grep ( m<\Q$base\Epage2> , @urls) == 1;

ok(8);

nogo unless
  grep ( m<http://www\.example\.com/link_controller_no_download2\.html> , @urls)
  == 1;

ok(9);

#check that we didn't follow links we shouldn't follow

nogo if grep ( m<http://bad_download.example.com> , @urls) > 0;

ok(10);

#create a user agent just to shut down the server...


require LWP::UserAgent;
require HTTP::Request;
my $ua = new LWP::UserAgent;
$ua->agent("Mozilla/0.01 " . $ua->agent);
$ua->from('gisle@aas.no');

print "Terminating server...\n" if $::verbose;
sub httpd_get_quit {
  my($c) = @_;
  $c->send_error(503, "Bye, bye");
  exit;			# terminate HTTP server
}

#FIXME; we should do this even if we die somewhere in the middle

my $req = new HTTP::Request GET => url("/quit", $base);
my $res = $ua->request($req);

print "not " unless $res->code == 503 and $res->content =~ /Bye, bye/;
print "ok 11\n";

