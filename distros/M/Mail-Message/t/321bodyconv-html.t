#!/usr/bin/env perl
#
# Test conversions as HTML/XHTML without help of external modules
#

use strict;
use warnings;

use Mail::Message;
use Mail::Message::Test;
use Mail::Message::Head::Complete;
use Mail::Message::Field::Fast;
use Mail::Message::Convert::Html;

use Test::More tests => 7;


my $html  = Mail::Message::Convert::Html->new;
my $xhtml = Mail::Message::Convert::Html->new(produce => 'XHTML');

#
# test fieldToHtml
#

my $to   = Mail::Message::Field::Fast->new(To => 'me@example.com (Mark Overmeer)');
is($html->fieldToHtml($to), '<strong>To: </strong><a href="mailto:me@example.com">me@example.com</a> (Mark Overmeer)');

my $to2  = Mail::Message::Field::Fast->new('reply-to' => 'me@example.com, you@tux.aq');
is($html->fieldToHtml($to2), '<strong>Reply-To: </strong><a href="mailto:me@example.com">me@example.com</a>, <a href="mailto:you@tux.aq">you@tux.aq</a>');

#
# test headToHtmlTable
#

my $head = Mail::Message::Head::Complete->new;
$head->add(To         => 'me@example.com (Mark Overmeer)');
$head->add(From       => 'you@tux.aq, john.doe@some.where.else (Doe, John)');
$head->add('X-Sender' => 'Mail::Box software cooperation');
$head->add(Subject    => 'No e-mail@at.this.line');

my $table_dump = <<'TABLE-DUMP';
<table  width=>"50%">
<tr><th valign="top" align="left">To:</th>
    <td valign="top"><a href="mailto:me@example.com">me@example.com</a> (Mark Overmeer)</td></tr>
<tr><th valign="top" align="left">From:</th>
    <td valign="top"><a href="mailto:you@tux.aq">you@tux.aq</a>, <a href="mailto:john.doe@some.where.else">john.doe@some.where.else</a> (Doe, John)</td></tr>
<tr><th valign="top" align="left">Subject:</th>
    <td valign="top">No e-mail@at.this.line</td></tr>
</table>
TABLE-DUMP

my $table = $html->headToHtmlTable($head, 'width=>"50%"');
is($table, $table_dump);

my $xtable = $xhtml->headToHtmlTable($head, 'width=>"50%"');
is($xtable, $table_dump);

#
# test headToHtmlHead
#

my $html_head_dump = <<'HTML_HEAD_DUMP';
<head>
<title>No e-mail@at.this.line</title>
<meta name="Author" content="you@tux.aq">
<meta name="To" content="me@example.com (Mark Overmeer)">
<meta name="From" content="you@tux.aq, john.doe@some.where.else (Doe, John)">
<meta name="Subject" content="No e-mail@at.this.line">
</head>
HTML_HEAD_DUMP

my $html_head = $html->headToHtmlHead($head);
is($html_head, $html_head_dump);

my $xhtml_head_dump = $html_head_dump =~ s!"\>!" />!gr;
my $xhtml_head = $xhtml->headToHtmlHead($head);
is($xhtml_head, $xhtml_head_dump);


$html_head = $html->headToHtmlHead
 ( $head
 , title    => 'Title, not subject'
 , keywords => 'html tags like < and >, & and ", must be encoded'
 );

$html_head_dump = <<'HTML_HEAD_DUMP';
<head>
<title>Title, not subject</title>
<meta name="Author" content="you@tux.aq">
<meta name="Keywords" content="html tags like &lt; and &gt;, &amp; and &quot;, must be encoded">
<meta name="To" content="me@example.com (Mark Overmeer)">
<meta name="From" content="you@tux.aq, john.doe@some.where.else (Doe, John)">
<meta name="Subject" content="No e-mail@at.this.line">
</head>
HTML_HEAD_DUMP
is($html_head, $html_head_dump);

$html_head = $html->headToHtmlHead
 ( $head
 , title    => 'Title, not subject'
 , keywords => 'html tags'
 , subject  => ''
 , extra    => 'new one'
 , TO       => 'overrule'
 );
$html_head_dump = <<'HTML_HEAD_DUMP';
<head>
<title>Title, not subject</title>
<meta name="Author" content="you@tux.aq">
<meta name="Extra" content="new one">
<meta name="Keywords" content="html tags">
<meta name="To" content="overrule">
<meta name="From" content="you@tux.aq, john.doe@some.where.else (Doe, John)">
</head>
HTML_HEAD_DUMP

exit 0;
