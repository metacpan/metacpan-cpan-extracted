use strict;
use Test::More tests => 3;
use LWPx::Record::DataSection -record_response_header => ':all';
use LWP::Simple qw($ua);

my $res = $ua->get('http://www.example.com/');
ok $res->is_success;
is scalar $res->redirects, 1;
is $res->base, 'http://www.iana.org/domains/example/';

# below are recorded by
# LWPX_RECORD_APPEND_DATA=1 prove -l t/01_simple.t

__DATA__

@@ GET http://www.example.com/
HTTP/1.0 302 Found
Connection: Keep-Alive
Location: http://www.iana.org/domains/example/
Server: BigIP
Content-Length: 0
Client-Peer: 192.0.32.10:80
Client-Response-Num: 1


@@ GET http://www.iana.org/domains/example/
HTTP/1.1 200 OK
Connection: Keep-Alive
Date: Wed, 23 Feb 2011 11:04:13 GMT
Accept-Ranges: bytes
Age: 3      
Server: Apache/2.2.3 (CentOS)
Content-Length: 2945
Content-Type: text/html; charset=UTF-8
Last-Modified: Wed, 09 Feb 2011 17:13:15 GMT
Client-Peer: 192.0.32.8:80
Client-Response-Num: 1
Link: </_css/reset-fonts-grids.css>; rel="stylesheet"; type="text/css"
Link: </_css/screen.css>; media="screen"; rel="stylesheet"; type="text/css"
Link: </_css/print.css>; media="print"; rel="stylesheet"; type="text/css"
Link: </favicon.ico>; rel="shortcut icon"; type="image/ico"
Title: IANA — Example domains

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<title>IANA &mdash; Example domains</title>
	<!-- start common-head -->
	<meta http-equiv="Content-type" content="text/html; charset=utf-8" />
	<link rel="stylesheet" type="text/css" href="/_css/reset-fonts-grids.css" />
	<link rel="stylesheet" type="text/css" media="screen" href="/_css/screen.css" />
	<link rel="stylesheet" type="text/css" media="print" href="/_css/print.css" />
	<link rel="shortcut icon" type="image/ico" href="/favicon.ico" />
	<script type="text/javascript" src="/_js/prototype.js"></script>
	<script type="text/javascript" src="/_js/corners.js"></script>
	<script type="text/javascript" src="/_js/common.js"></script>
	<!-- end common-head -->

</head>
<body>
	<!-- start common-bodyhead -->
	<div id="header-frame">
	<div id="header">
	<div id="header-logo"><a href="/"><img src="/_img/iana-logo-pageheader.png" alt="Homepage"/></a></div>
	<div id="header-nav">
	<ul>
	<li><a href="/domains/">Domains</a></li>
	<li><a href="/numbers/">Numbers</a></li>
	<li><a href="/protocols/">Protocols</a></li>
	<li><a href="/about/">About IANA</a></li>
	</ul>
	</div>
	</div>
	</div>

	<div id="body-container">
	<div id="body">
	<!-- end common-bodyhead -->


	<h1>Example Domains</h1>

	<p>As described in <a href="/go/rfc2606">RFC 2606</a>,
	we maintain a number of domains such as EXAMPLE.COM and EXAMPLE.ORG
	for documentation purposes. These domains may be used as illustrative
	examples in documents without prior coordination with us. They are 
	not available for registration.</p>

	 <!-- start common-bodytail -->
	</div>
	</div>

	<div id="footer-frame">
	<div id="footer">


	<table width=100%>
	<tr>
		<td id="iana-footer-first"><b><a href="/about/">About</a></b><br/>
                <a href="/about/presentations/">Presentations</a><br/>
                <a href="/about/performance/">Performance</a><br/>
		<a href="/reports/">Reports</a><br/>
                </td>

		<td><b><a href="/domains/">Domains</a></b><br/>
		<a href="/domains/root/">Root Zone</a><br/>
		<a href="/domains/int/">.INT</a><br/>
		<a href="/domains/arpa/">.ARPA</a><br/>
		<a href="/domains/idn-tables/">IDN Repository</a></td>

		<td><b><a href="/protocols/">Protocols</a></b><br/>
		<br/>
		<b><a href="/numbers/">Number Resources</a></b><br/>
		<a href="/abuse/">Abuse Information</a></td>

		<td id="iana-footer-icann"><img src="/_img/icann-logo-micro.png"><br/>IANA is operated by the<br/><a href="http://www.icann.org/">Internet Corporation for Assigned Names and Numbers</a></td>
	</tr>
	</table>

<div id="footer-beta-feedback">
        <p>Please direct general feedback regarding IANA to <a href="mailto:iana@iana.org?subject=General%20website%20feedback">iana@iana.org</a>.</p>
        </div>

	</div>
	</div>
	<!-- end common-bodytail -->


</body>
</html>

