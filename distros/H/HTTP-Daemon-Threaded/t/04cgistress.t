BEGIN {
	push @INC, './t';
	print STDERR "*** Note: This test may run for a minute or more\n";
	print STDERR "*** Note2: several harmless \"Scalars leaked\" messages may be reported\n";
}

use Test::More tests => 1;
use threads;
use LWP::Simple;
use LWP::UserAgent;
use LWPBulkFetch;
use strict;
use warnings;

my $thrdcnt = 4;
my $child1;
my $sep = ($^O eq 'MSWin32') ? '\\' : '/';
my $forkhttpd = 1;
#
#	NOTE: we need to use different port than 01basics.t, since some
#	platforms hang onto the listener port for extended periods
#	after we've closed it
#
my $port = 12876;
my $result = 0;
my $cycles = 20;
my $quiet = 1;

while (@ARGV) {
	my $opt = shift @ARGV;
	$thrdcnt = shift @ARGV,
	next
		if ($opt eq '-t');

	$forkhttpd = undef,
	next
		if ($opt eq '-n');

	$port = shift @ARGV,
	next
		if ($opt eq '-p');

	$cycles = shift @ARGV,
	next
		if ($opt eq '-c');

	$quiet = undef,
	next
		if ($opt eq '-l');
}

if ($forkhttpd) {
	$child1 = fork();

	die "Can't fork HTTP Client child: $!" unless defined $child1;

	unless ($child1) {
		my $cmd = 'perl -w t' . $sep . "cgidtest.pl -p $port -c 5 -d ./t -l 1 -s";
		system($cmd);
		exit 1;
	}
#
#	wait a while for things to get rolling
#
	sleep 5;
}
#
#	start some threads
#
my @thrds = ();
push @thrds, threads->create(\&run, $port, $cycles)
	foreach (1..$thrdcnt);
#
#	wait for them to get rolling
#
sleep 5;
#
#	wait for them to finish
#
$result += $_->join()
	foreach (@thrds);

#print "Result is $result\n";
is($result, $thrdcnt, 'stress test');
#
#	shutdown the server
#
if ($forkhttpd) {
	get "http://localhost:$port/stop";

	kill($child1);

	waitpid($child1, 0);
}

sub run {
	my ($port, $cycles) = @_;

	my $url = "http://localhost:$port/";
	my $index = '<html><body>Some really simple HTML.</body></html>';
	my ($ct, $cl, $mtime, $exp, $server);
	my $indexlen = length($index);	# change this!
#
#	now run each LWP request and see what we get back
#
#	1. simple HEAD
#
	foreach (1..$cycles) {
	print STDERR "Simple HEAD\n"
		unless $quiet;

	($ct, $cl, $mtime, $exp, $server) = head($url . 'index.html');
	return 0
		unless (defined($ct) && ($ct eq 'text/html'));
#
#	2. simple GET
#
	print STDERR "Simple GET\n"
		unless $quiet;

	my $page = get $url;
	return 0 unless (defined($page) && ($page eq $index));
#
#	3. document HEAD
#
	print STDERR "Document HEAD\n"
		unless $quiet;
	my $jspage =
'/*
 this would normally be a nice piece of javascript
*/
';

	($ct, $cl, $mtime, $exp, $server) = head($url . 'scripty.js');
	return 0 unless	(defined($ct) && ($ct eq 'text/javascript') &&
		defined($cl) && (($cl == crlen($jspage)) || ($cl == length($jspage))));
#
#	4. CGI HEAD
#
	print STDERR "CGI HEAD\n"
		unless $quiet;

my $postpg = <<'EOPAGE';
<!DOCTYPE html
	PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
<head>
<title>Untitled Document</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>
<body>
that is other<br>
this is some<br>
when is right this minute<br>
where is up<br>

</body>
</html>
EOPAGE

	($ct, $cl, $mtime, $exp, $server) = head($url . 'posted?this=some&that=other&where=up&when=right%20this%20minute');
	return 0 unless (defined($ct) && ($ct eq 'text/html; charset=UTF-8'));
#
#	5. document GET
#
	print STDERR "Document GET\n"
		unless $quiet;
	$page = get $url . 'scripty.js';
	return 0 unless (defined($page) && (!crcmp($page, $jspage)));
#
#	6. CGI GET
#
	print STDERR "CGI GET\n"
		unless $quiet;
	$page = get $url . 'posted?this=some&that=other&where=up&when=right%20this%20minute';
	return 0 unless (defined($page) && (!crcmp($page, $postpg)));
#
#	7. multidoc GET
#
	print STDERR "Multidoc GET\n"
		unless $quiet;

my %multidoc = (
$url . 'frames.html',
"<html>
<head><title>Test Content Handler</title>
</head>

<frameset rows='55%,45%'>

	<frameset cols='80%,20%'>
		<frame id='sources' src='sourcepane.html' scrolling=no frameborder=1>
		<frame id='srctree' src='sourcetree.html' scrolling=yes frameborder=1>
	</frameset>

	<frame name='stackpane' src='stackpane.html' scrolling=no frameborder=0>

</frameset>
</html>
",

$url . 'stackpane.html',
'<html>
<body>
Some other stuff goes here...
</body>
</html>
',
$url . 'sourcepane.html',
'<html>
<body>
<center><h2>Here\'s a frame</h2></center>
</body>
</html>
',

$url . 'sourcetree.html',
'<html>
<head>
<style type="text/css">
td, th, a {
	font-family: Verdana, Geneva, Arial, Helvetica, sans-serif;
	font-size: 10px;
	color: #666;
	white-space: nowrap;
}

a {
	text-decoration: none;
}

</style>

</head>
<body>
<div class="srctree">
<table border=0 id="treetable">
<tr><th colspan=2 align=left>Source Packages</th></tr>
<tr><td>&nbsp;&nbsp;</td><td align=left><a href="" onclick="">One</td></tr>
<tr><td>&nbsp;&nbsp;</td><td align=left><a href="" onclick="">Two</td></tr>
<tr><td>&nbsp;&nbsp;</td><td align=left><a href="" onclick="">Three</td></tr>
</table>
</div>

</body>
</html>
'

);
	my $fetched = LWPBulkFetch->new($url . 'frames.html');
	my $returl;
	return 0 unless $fetched;

	my $ok = 1;
	while (($returl, $page) = each %multidoc) {
		$ok = undef, last
			unless $fetched->{$returl} && (!crcmp($page, $fetched->{$returl}));
	}
	return 0 unless $ok;
#
#	8. simple POST
#
	print STDERR "Simple POST GET\n"
		unless $quiet;
	my $ua = LWP::UserAgent->new();

	$page = $ua->post($url . 'posted',
		{ this => 'some', that => 'other', where => 'up', when => 'right this minute'});
	return 0
		unless defined($page);

	$page = $page->content();
	return 0 unless (defined($page) && (!crcmp($page, $postpg)));
#
#	9. POST w/ content
#
	print STDERR "Content POST\n"
		unless $quiet;

	my $xml =
'<first>
	<second>this is the second</second>
	<third>this is the third</third>
</first>
';

	my $r = HTTP::Request->new( POST => $url . 'postxml' );
	$r->header('Content-Type' => 'text/xml');
	$r->header('Content-Length' => length($xml));
	$r->content( $xml );

#print STDERR "\n", $r->as_string(), "\n";

	my $response = $ua->request( $r );

#print STDERR "\n", $response->as_string(), "\n";

	$page = $response->is_success ? $response->content : undef;
#	print STDERR "failed\n" unless $page;
	return 0 unless (defined($page) && (!crcmp($page, $xml)));
	}	# end foreach cycle
	return 1;
}

sub crlen {
	my $crs = ($_[0]=~tr/\n//);
	return length($_[0]) + $crs;
}

sub crcmp {
	$_[0]=~s/[\r\n]//g;
	$_[1]=~s/[\r\n]//g;
	return ($_[0] cmp $_[1]);
}
