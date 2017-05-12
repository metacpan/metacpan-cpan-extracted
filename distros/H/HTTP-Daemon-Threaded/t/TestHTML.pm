package TestHTML;

use Module::Util qw(find_installed);
use HTTP::Daemon::Threaded::Content;
use HTTP::Date qw(time2str);
use HTTP::Status;
use HTTP::Response;
use base ('HTTP::Daemon::Threaded::Content');

use strict;
use warnings;

our %pages = (
	'index' => \&mainPage,
	'frames' => \&framePage,
	'stackpage' => \&stackPage,
	'stackpane' => \&stackPane,
	'sourcepane' => \&sourcePane,
	'sourcetree' => \&sourceTree,
);

our $mtime = time2str((stat(find_installed(__PACKAGE__)))[9]);

sub new { my $class = shift; return $class->SUPER::new(@_); }

sub getContent {
	my ($self, $fd, $req, $uri, $params, $session) = @_;

#	print STDERR "Session ", (defined($session) ? 'exists' : 'undef'), "\n";

	unless (($uri=~/\/(\w+)\.html$/i) && (exists $pages{$1})) {
		$self->logInfo("Can't find $1\n");
		return $fd->send_error(RC_NOT_FOUND);
	}
	$session = $self->{SessionCache}->createSession()
		unless $session;

	my $html = $pages{$1}->();
	my $res = HTTP::Response->new(RC_OK);
	$res->header('Content-Type' => 'text/html');
	$res->header('Last-Modified' => $mtime);

	$res->header('Set-Cookie' => $session->getCookie()),
	$session->cookieSent()
		if $session->isNew();

	$res->content($html);
	$self->logInfo("sending response\n");
	return $fd->send_response($res);
}

sub getHeader {
	my ($self, $fd, $req, $uri, $params, $session) = @_;

#	print STDERR "Session ", (defined($session) ? 'exists' : 'undef'), "\n";

	unless (($uri=~/\/(\w+)\.html$/i) && (exists $pages{$1})) {
		$self->logInfo("Can't HEAD $1\n");
		return $fd->send_error(RC_NOT_FOUND);
	}

	$session = $self->{SessionCache}->createSession()
		unless $session;
	my $html = $pages{$1}->();
	my $res = HTTP::Response->new(RC_OK, 'OK',
		[ 'Content-Type' => 'text/html',
			'Content-Length' => length($html),
			'Last-Modified' => $mtime,
		]);

	$res->header('Set-Cookie' => $session->getCookie()),
	$session->cookieSent()
		if $session->isNew();

	$res->request($req);
	return $fd->send_response($res);
}
#
#	the main frameset page
#	the title is set from the input app name
#

sub mainPage {
	return '<html><body>Some really simple HTML.</body></html>';
}

sub framePage {
	return
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
";
}

#
#	empty page for the stack pane
#	the PID:TID is provided
#
sub stackPage {

	return
"<html>
<body>
<table border=0 width='100%'>
<tr bgcolor='#FDFABF'><tr><th>Frame</th><th>Package::method()</th><th>Line</th></tr>
</table>
</body>
</html>
";
}
#
#	the source pane; the list of module names is passed
#	in; the first name is assumed to be the "main" file
#	script name
#
sub sourcePane {
	my $base =
'<html>
<body>
<center><h2>Here\'s a frame</h2></center>
</body>
</html>
';
	return $base;
}
#
#	set sourcetree pane content:
#	first param is main script file;
#	rest are packages, which get sorted
#
sub sourceTree {
	my $self = shift;
	my $main = shift;

	@_ = sort @_;

	unshift @_, $main;

	my $base =
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
';
	return $base;
}

sub stackPane {
	my $self = shift;
	my $base =
'<html>
<body>
Some other stuff goes here...
</body>
</html>
';
	return $base;
}

1;

