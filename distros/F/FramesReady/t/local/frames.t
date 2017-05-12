#!/usr/bin/perl
# $Id: frames.t,v 1.3 2010/04/06 08:10:14 aederhaag Exp $
#
# Check GET via HTTP.
#

use LWP::Protocol ();
use Test::More tests => 22;
use diagnostics;

BEGIN {
    use_ok('LWP::UserAgent::FramesReady');
    use_ok('HTTP::Response::Tree');
}


LWP::Protocol::implementor(http => 'myhttp');

my $ua = LWP::UserAgent::FramesReady->new;    # create a useragent to test
isa_ok($ua,'LWP::UserAgent::FramesReady');

is(ref($ua->callbk), 'CODE', "Test of default callbk instantiation");
$ua->callbk(undef);
is($ua->callbk, undef, "Check callbk setter/getter");

$ua->size(0);
is($ua->size, 0, "Check size getter/setter");

$ua->nomax(0);
is($ua->nomax, 0, "Check of auto-truncate getter/setter");

# $ua->proxy('ftp' => "http://www.sn.no/");

my $req = HTTP::Request->new(GET => 'http://www.foo.com/');
$req->header(Cookie => "perl=cool");
isa_ok($req, 'HTTP::Request', "Valid request checked");

my $res = $ua->request($req);
isa_ok($res, 'HTTP::Response::Tree'); # Didn't make to a Tree 
$res->{'quiet'} = 1;

# Contrive a few that should fail but exercise the code
$ret = $res->member();
is($ret, undef, "Test of NULL member for add");

$ret = $res->member('http://www.foo.com/good1');
is($ret, undef, "Try to convert URL to URI");

$ret = $res->add_child('HTTP::Response', 'http://www.foo.com/added');
is($ret, undef, "Test of a non-child add");

$ret = $res->add_child('200', 'http://www.foo.com/added');
is($ret, undef, "Test of a non-HTTP::Response object");

$res->max_depth(0);
$ret = $res->add_child('HTTP::Response', 'http://www.foo.com/added');
is($ret, undef, "Test of a non-HTTP::Response object");
$res->max_depth(3);             # Restore for next check

print $res->as_string;

my $tree_good = 0;
is($tree_good = $res->is_success, '1', "Check for response success");

SKIP: {
    skip "Skip if Tree object not found", 6 unless $tree_good;

    is(scalar $res->descendants, 2, "Check for right number of descendants");
    is(scalar $res->children, 2, "Check for right number of children");
    is($res->max_depth, 3, "Proper depth was defined");

    @childrn = $res->children;
    $chld = shift @childrn;
    is($chld->max_depth, 2, "Children inherit proper depth");
    is($chld->code, 200, "HTTP Return code valid");

    $chld = shift @childrn;
    is($chld->code, 200, "Check of second child");
}

# my $allstr = $res->cat_all_content('*');
# is(ref($allstr), 'SCALAR', "Contenate of contents tested");

$allstr = $res->cat_all_content('text/html');
is(ref($allstr), 'SCALAR', "Contenate working for html mime type");


#----------------------------------
package myhttp;

BEGIN {
   @ISA=qw(LWP::Protocol);
}

# our $cntr;

sub new
{
  my $class = shift;
  print "CTOR: $class->new(@_)\n";
  my($prot) = @_;
#   print "not " unless $prot eq "http";
#   $cntr++;
#   print "ok $cntr\n";
  my $self = $class->SUPER::new(@_);
  for (keys %$self) {
    my $v = $self->{$_};
    $v = "<undef>" unless defined($v);
    print "$_: $v\n";
  }
  $self;
}


sub request
{
  my $self = shift;
  print "REQUEST: $self->request(",
    join(",", (map defined($_)? $_ : "UNDEF", @_)), ")\n";

  my($request, $proxy, $arg, $size, $timeout) = @_;
  my $data;
  my $data1 = q!<HTML>
<HEAD>
<TITLE>Coolpics</TITLE>
<META NAME="keywords" CONTENT="Free,xxx,Movies,Pics,Pic,Bilder,pics,pic,Tumbs">
<META NAME="description" CONTENT="Free Pics,Movies,Babes,TeensEbony">
<META NAME="robots" CONTENT="INDEX, FOLLOW">
<META NAME="revisit-after" CONTENT="10 days">
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=iso-8859-1">
<script language="JavaScript">
if(top.frames.length > 0)
top.location.href=self.location;
</script>
</HEAD>

<FRAMESET ROWS="100%,*" FRAMEBORDER="NO" BORDER="0" FRAMESPACING="0">
<FRAME NAME="main_frame1" SRC="/frame1">
<FRAME NAME="main_frame2" SRC="/frame2">
</FRAMESET>

<NOFRAMES>
<BODY bgcolor="#FFFFFF" text="#000000">
<a href="/noframe"> No Frames</a>
</BODY>
</NOFRAMES>
</HTML>
!;

my $data2 = q!<HTML>
<HEAD>
<TITLE>Frame1</TITLE>
<META NAME="keywords" CONTENT="Free,xxx,Movies,Pics,Pic,Bilder,pics,pic,Tumbs">
<META NAME="description" CONTENT="Free Pics,Movies">
<META NAME="robots" CONTENT="INDEX, FOLLOW">
<META NAME="revisit-after" CONTENT="10 days">
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=iso-8859-1">
<script language="JavaScript">
if(top.frames.length > 0)
top.location.href=self.location;
</script>
</HEAD>

<BODY BGCOLOR="#FFFFFF" TEXT="#000000">
<a href="http://localhost:80/cgi-bin/lwp/frame1"> 1 Frame </a>
</BODY>
</HTML>
!;

my $data3 = q!<HTML>
<HEAD>
<TITLE>Frame2</TITLE>
<META NAME="keywords" CONTENT="Free,xxx,Movies,Pics,Pic,Bilder,pics,pic,Tumbs">
<META NAME="description" CONTENT="Free Pics,Movies">
<META NAME="robots" CONTENT="INDEX, FOLLOW">
<META NAME="revisit-after" CONTENT="10 days">
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=iso-8859-1">
<script language="JavaScript">
if(top.frames.length > 0)
top.location.href=self.location;
</script>
</HEAD>

<BODY BGCOLOR="#FFFFFF" TEXT="#000000">
<a href="http://localhost:80/cgi-bin/lwp/frame2"> 1 Frame </a>
</BODY>
</HTML>
!;
  print $request->as_string;

  my $res = HTTP::Response::Tree->new();
  $res->code(200);
  $res->content_type("text/html");
  $res->date(time);

  if ($request->{_uri} =~ /frame1/) {
    #       print "ok 6\n";
    $data = $data2;
  } elsif ($request->{_uri} =~ /frame2/) {
    #       print "ok 7\n";
    $data = $data3;
  } else {
    #       print "ok 5\n";
    $data = $data1;
  }

  $self->collect_once($arg, $res, "$data\n");
  $res;
}

1;
