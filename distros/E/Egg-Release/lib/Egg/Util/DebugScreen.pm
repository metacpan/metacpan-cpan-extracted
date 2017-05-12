package Egg::Util::DebugScreen;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: DebugScreen.pm 342 2008-05-29 16:05:06Z lushe $
#
use strict;
use warnings;
use Egg::Release;
use HTML::Entities;

our $VERSION = '3.04';

sub _debug_screen {
	my($e)= @_;
	$e->setup_error_header;
	$e->finished(0);
	$e->response->body( _content($e) );
	$e->_output;
}
sub _content {
	my($e)= @_;
	my $err= $e->errstr || 'Internal Error.';
	my($res, $querys, $escape)= ($e->response, '', q{'"&<>@});
	$err= encode_entities($err, $escape);
	$err=~s{\n} [<br />\n]sg;
	my $param;
	if ($param= $e->request->params and %$param) {
		$querys = q{ <div class="querys"><b>Request Querys:</b><table>};
		while (my($key, $value)= each %$param) {
			$querys.= q{<tr><th>}. encode_entities($key, $escape). qq{</th>};
			$value  = encode_entities($value, $escape) unless ref($value);
			$querys.= qq{<td>${value}</td></tr>\n};
		}
		$querys.= q{</table></div>};
	}
	<<END_OF_DISP;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
         "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="@{[
  $res->content_language($e->config->{content_language} || 'en')
  ]}">
<head>
<meta http-equiv="Content-Language" content="@{[ $res->content_language ]}" />
<meta http-equiv="Content-Type" content="@{[
  $res->content_type($e->config->{content_type} || 'text/html')
  ]}" />
<meta http-equiv="Content-Style-Type" content="text/css" />
<meta name="robots" content="noindex,nofollow,noarchive" /> 
<title>EGG - Error.</title>
<style type="text/css">@{[ _style() ]}</style>
</head>
<body>
<div id="egg_error_container">
<h1>$e->{namespace} v@{[ $e->VERSION ]}</h1>
<div id="egg_error_content"> $err$querys </div>
<div id="egg_error_footer">
<a href="$Egg::Release::DISTURL" target="_blank">
Powered by Egg <strong>$Egg::Release::VERSION</strong></a>
</div>
</div>
</body></html>
END_OF_DISP
}
sub _style {
	<<END_STYLE;
body {
	background:#FFF376;
	margin:0px;
	text-align:center;
	}
h1 {
	margin:0px; padding:1px 3px 1px 10px;
	font:bold 16pt Times,sans-serif;
	background:#FFBF00;
	border:#B7974E solid 2px; border-bottom:0px;
	}
#egg_error_container {
	margin:10px auto 0px auto; padding:0px;
	width:720px;
	text-align:left;
	}
#egg_error_content {
	background:#FFF;
	margin:0px; padding:10px;
	border-right:#B7974E solid 2px; border-left:#B7974E solid 2px;
	text-align:left;
	}
#egg_error_content .querys {
	margin:10px; padding:2px;
	background:#F9D787; color:#555;
	border:#333 solid 1px;
	font-size:10px;
	}
#egg_error_content .querys table {
	width:99.5%;
	border-collapse:collapse;
	font-size:12px; color:#000;
	}
#egg_error_content .querys table th, #egg_error_content .querys table td {
	padding:2px 3px 1px 5px;
	border-bottom:#C5AB6A solid 1px;
	}
#egg_error_content .querys table th { background:#FFF1B9 }
#egg_error_content .querys table td { background:#FFFFED }
#egg_error_footer {
	background:#FFBF00;
	border:#B7974E solid 2px; border-top:0px;
	font:italic 10pt Times,sans-serif;
	text-align:right;
	}
#egg_error_footer a { color:#000 }
END_STYLE
}

1;

__END__

=head1 NAME

Egg::Util::DebugScreen - Debugging screen for Egg.

=head1 DESCRIPTION

The message is displayed on the screen where the appearance was in order when 
the project generates the exception.

This module is set up by L<Egg::Util::Debug> when debug mode is effective.
To use other classes, it sets it to environment variable EGG_DEBUG_SCREEN_CLASS.

This module initializes the response status when the exception is generated and
displays the screen. In a word, please note that Egg continues processing assuming
that '200 OK' was specified when the response status is undefined.

=head1 SEE ALSO

L<Egg::Release>,
L<HTML::Entities>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

