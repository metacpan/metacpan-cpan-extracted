package Mytest;

use strict;
use warnings;

use Apache::Constants qw(REDIRECT OK DECLINED);
use Dendral::HTTP::Request;
use Data::Dumper;


sub handler
{
	my $r = shift;

	my $dendral = new Dendral::HTTP::Request($r, POST_MAX => -1, MAX_FILES => -1, MAX_FILE_SIZE => -1, TMP_DIR => '/tmp/');

	my $r_info = {
	               host         => $dendral -> host,
	               method       => $dendral -> method,
	               request_time => $dendral -> request_time,
	               the_request  => $dendral -> the_request,
	               protocol     => $dendral -> protocol,
	               unparsed_uri => $dendral -> unparsed_uri,
	               uri          => $dendral -> uri,
	               filename     => $dendral -> filename,
	               path_info    => $dendral -> path_info,
	               args         => $dendral -> args,
	               remote_ip    => $dendral -> remote_ip,
	               local_ip     => $dendral -> local_ip,
	               port         => $dendral -> port
	             };

	# Get request info
	my $r_info_s =  Dumper($r_info);

	# Get params
	my $params   = $dendral -> params();
	my $params_s = Dumper($params);

	# Get headers
	my $headers   = $dendral -> headers();
	my $headers_s = Dumper($headers);

	# Get cookies
	my $cookies   = $dendral -> cookies();
	my $cookies_s = Dumper($cookies);

	# Get files
	my $files   = $dendral -> files();
	my $files_s = Dumper($files);

	warn $r_info_s, $params_s, $headers_s, $cookies_s, $files_s;

	my $output = <<END;
<html>
<head>
	<title>Dendral::HTTP::Request module test page</title>
</head>
<body>
	<a href="?foo=bar&bar=baz">GET METHOD</a><br/><br/>

	The application/x-www-form-urlencoded form:<br/>
	<form action="" method="POST">
		<input type="text" name="foo" value="from application/x-www-form-urlencoded"/>
		<input type="text" name="bar" value="456"/>
		<input type="text" name="bar" value="789"/>
		<input type="submit"/>
	</form><br/><br/>

	The multipart/form-data form:<br/>
	<form action="" method="POST" enctype="multipart/form-data">
		<input type="text" name="foo" value="from multipart/form-data"/>
		<input type="file" name="bar"/>
		<input type="file" name="foo"/>
		<input type="submit"/>
	</form><br/><br/>

	Result:<br/><br/>

	Info:
<pre style="background-color: #E0E0E0; border: 1px solid #404040; padding: 0.4ex 1ex;">$r_info_s</pre>

	Params:
<pre style="background-color: #E0E0E0; border: 1px solid #404040; padding: 0.4ex 1ex;">$params_s</pre>

	Cookies:
<pre style="background-color: #E0E0E0; border: 1px solid #404040; padding: 0.4ex 1ex;">$cookies_s</pre>

	Headers:
<pre style="background-color: #E0E0E0; border: 1px solid #404040; padding: 0.4ex 1ex;">$headers_s</pre>

	Files:
<pre style="background-color: #E0E0E0; border: 1px solid #404040; padding: 0.4ex 1ex;">$files_s</pre>
	All done.
</body>
</html>
END
	$r -> header_out('Pragma'        => 'no-cache, no-store');
	$r -> header_out('Cache-Control' => 'no-cache');
	$r -> header_out('Expires'       => 'Thu, 01 Jan 1970 00:00:01 GMT');

	$r -> content_type('text/html; charset=utf-8');
	$r -> send_http_header();

	$r -> print($output);
return OK;
}

1;
__END__;

