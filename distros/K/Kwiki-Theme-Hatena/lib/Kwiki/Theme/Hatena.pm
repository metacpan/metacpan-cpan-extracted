package Kwiki::Theme::Hatena;
use strict;
use warnings;
use Kwiki::Theme '-Base';
use mixin 'Kwiki::Installer';

our $VERSION = '0.01';

const config_file => 'hatena_theme.yaml';
const theme_id => 'hatena';
const class_title => 'The hatena theme';

1;

__DATA__

=head1 NAME

Kwiki::Theme::Hatena - Kwiki Hatena Theme

=head1 SYNOPSIS

In C<config.yaml>:

    hatena_theme_logo_width: 60
    hatena_theme_logo_height: 60

=head1 DESCRIPTION

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

But C<theme/hatena/template/tt2/kwiki_screen.html> and C<theme/hatena/css/kwiki.css> is the GPL License. 

=head1 SEE ALSO

L<http://d.hatena.ne.jp>

=cut
__theme/hatena/template/tt2/kwiki_screen.html__
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<!-- BEGIN kwiki_screen.html -->
[% INCLUDE kwiki_begin.html %]
<table border="0" width="100%" cellspacing="0" cellpadding="0">
  <tr>
    <td bgcolor="#1841CE" nowrap>

   <a href="?" style="text-decoration:none;"><div class="header">[% IF group_name %][% group_name %]::[% END %][% site_title %]</div></a>

    </td>

    <td valign="bottom" align="left" bgcolor="#1841CE" width="60%" nowrap>
      [% IF hub.have_plugin('search').match('Kwiki::Search') %]
<form method="post" action="[% script_name %]" enctype="application/x-www-form-urlencoded" style="display: inline">
<input type="text" name="search_term" size="8" value="Search" onfocus="this.value=''" />
<input type="submit" name="submit" value="Search" align="top" style="height:20px;border:0px">
<input type="hidden" name="action" value="search" />
</form>
      [% END %]
    </td>
    
    <td align="right" bgcolor="#1841CE"><img src="[% logo_image %]" align="center" alt="Logo" title="[% site_title %]" width="[% hatena_theme_logo_width %]" height="[% hatena_theme_logo_height %]" /></td>
    
  </tr>

  <tr>
    <td width="100%" bgcolor="#06289B" colspan="3"><img border="0" src="theme/hatena/images/dot.gif" width="1" height="1" alt=""></td>
  </tr>

  <tr>
    <td width="100%" bgColor="#ffffff" colspan="3">
      <div align="center">

        <center>
        <table cellSpacing="0" cellPadding="2" width="100%" border="0">
          <tbody>
            <tr>
    <td bgcolor="#5279E7" width="50%" nowrap>
      [% IF hub.have_plugin('user_name').match('Kwiki::HatenaAuth') %]
        <font color="#C9D5F8" size="2">&nbsp;welcome to
        [% IF hub.users.current.name -%]
          <a href="http://d.hatena.ne.jp/[% hub.users.current.name %]/" style="text-decoration:none; font-weight:100;"><font color="#C9D5F8">[% hub.users.current.name | html %]</font></a>
        [% ELSE %]
          Guest
        [% END %]
        &nbsp;</font>
      [% ELSIF hub.have_plugin('user_name') %]
      [% INCLUDE user_name_title.html %]
      [% END %]
    </td>
              <td bgcolor="#5279E7" nowrap align="center">[% hub.toolbar.html.replace('">\s*?<!--', '" style="text-decoration:none; font-weight:100;"><font size="2" color="#C9D5F8"><!--').replace('">\s*?\[%', '" style="text-decoration:none; font-weight:100;"><font size="2" color="#C9D5F8">[%').replace('</a>\s*?<!--', '</font></a><!--') %]</td>
              [% IF hub.have_plugin('user_name').match('Kwiki::HatenaAuth') %]
              <td bgcolor="#5279E7" nowrap align="center">
                  [% IF hub.users.current.name -%]
                    <a href="[% script_name %]?action=logout_hatenaauth" style="text-decoration:none; font-weight:100;"><font size="2" color="#C9D5F8">Logout</font></a>
                  [% ELSE %]
                    <a href="[% hub.load_class('user_name').uri_to_login %]" style="text-decoration:none; font-weight:100;"><font size="2" color="#C9D5F8">Login</font></a>
                  [% END %]
              </td>
              [% END %]
              <td bgcolor="#5279E7" nowrap align="center">[% hub.status.html %]</td>
            </tr>
          </tbody>
        </table>
        </center>

      </div>
    </td>
  </tr>

  <tr>
    <td width="100%" bgcolor="#06289B" colspan="3"><img border="0" src="theme/hatena/images/dot.gif" width="1" height="1" alt=""></td>
  </tr>

</table>

<h1>[% screen_title || self.class_title %]
 <a href="http://b.hatena.ne.jp/entry/[% script_name _ '?' _ hub.cgi.page_name | uri %]"><img src="theme/hatena/images/b_entry_de.gif" border="0" width="16" height="12" class="icon"></a>
[% IF hub.have_plugin('user_name').match('Kwiki::HatenaAuth') %]
[% IF hub.users.current.name -%]
 <a href="http://b.hatena.ne.jp/[% hub.users.current.name -%]/append?[% script_name _ '?' _ hub.cgi.page_name | uri %]"><img src="theme/hatena/images/b_append.gif" border="0" width="16" height="12" class="icon"></a>
[% END %]
[% END %]
[% IF hub.have_plugin('RecentChangesRSS') %]
<a href="[% script_name %]?action=RecentChangesRSS"><img src="theme/hatena/images/rss_de.gif" alt="RSS" title="RSS" border="0" width="24" height="12" class="icon"></a>
[% END %]
</h1>

<div class="hatena-body">
<div class="main">

<div class="day">
    <h2><span class="date">[% hub.pages.current.edit_time %]</span></h2>

    <div class="body">
    
    <div class="section">
[% INCLUDE $content_pane %]
    </div>
    </div>
</div>

<div class="sidebar">
[% hub.widgets.html %]
</div>

[% INCLUDE kwiki_end.html %]

<!-- END kwiki_screen.html -->
__theme/hatena/css/.htaccess__
Allow from all
__theme/hatena/css/kwiki.css__
/*
Title: はてなダイアリー
Author: hatena
Access: info@hatena.ne.jp
License: GPL
Comment: はてなダイアリーのテーマ
*/
/*
	Copyright (c) 2002 Junya Kondo, Hatena Co.,Ltd.
*/

/*
はてな独自拡張クラス
*/
a.keyword {
	color: black;
	text-decoration: none;
	border-bottom: 1px solid #d0d0d0;
}
a.okeyword {
	color: black;
	text-decoration: none;
	border-bottom: 1px dashed #d0d0d0;
}

span.highlight {
	color: black;
	background-color: yellow;
}

img.photo {
	float: right;
	margin: 10px;
	border: 0;
}
img.hatena-fotolife {
	border: 1px solid #606060;
}
img.asin, img.barcode {
	border: 0;
}

h3 span.timestamp {
	font-weight: normal;
	font-size: 80%;
}

table.furigana {
}

td.furigana {
	border: #5279e7 1px solid;
	text-align: center;
	padding: 5px;
}

ul.hatena_photo li {
	display: inline;
}

img.hatena_photo {
	border: 0px;
}

div.ad {
	margin: 0% 5% 0% 5%;
	padding: 4px;
	text-align: left;
}

img.aws {
	padding: 3px;
	margin-right: 2px;
}

a.aws img {
	border: 1px solid white;
}

a.aws:hover img {
	filter:none;
	background-color: #ffcc66;
	border-bottom: 1px solid #ffcc66;
}

div.recentitem_diary {
	margin: 2% 5% 0 6%;
	font-size: 10pt;
}

div.hatena-body {
	position: relative;
	width: auto;
	_width: 100%;
	top: 0;
	left: 0;
}

div.hatena-module {
	margin: 0;
	padding: 0;
	width: 100%;
}

h4.hatena-module, div.hatena-moduletitle {
	margin: 1em 0 0.3em 0;
	padding: 0;
	font-size: 80%;
	text-align: center;
	font-weight: normal;
	border-color: #adb2ff;
	border-style: solid;
	border-width: 0px 0px 1px 0px;
}

div.hatena-modulebody ul, ul.hatena_antenna, ul.hatena_section, ul.hatena_groupantenna, ul.hatena_keyword, ul.hatena_hotkeyword, ul.hatena_hoturl, ul.hatena_hotasin {
	display: block;
	font-size: 80%;
	list-style-type: none;
	margin: 0;
	padding: 0;
}

div.hatena-modulebody dl {
	display: block;
	font-size: 80%;
	margin: 0;
	padding: 0;
}

div.hatena-modulebody dd {
	margin-left: 0;
	margin-bottom: 0.2em;
}

ul.hatena-photo li {
	display: inline;
}

ul.hatena-photo img {
	border: none;
	padding: 1px;
}

form.hatena-searchform {
	padding: 0;
	margin: 0;
}

div.hatena-profile {
	font-size: 80%;
}
div.hatena-profile p {
	margin: 0;
	padding: 0;
}
div.hatena-profile p.hatena-profile-image {
	text-align: center;
}
div.hatena-profile p.hatena-profile-image img {
	border: 0;
}
table.hatena-question-detail {
	width: 500px;
	font-size:90%;
}
table.hatena-question-detail th {
	text-align: left;
}
td.hatena-question-detail-label {
	width: 200px;
}
td.hatena-question-detail-value {
	width: 300px;
}
img.hatena-question-image {
	border: 0;
}
img.hatena-profile-image {
	border: 0;
}
div.hatena-clock {
	text-align: center;
}
/*
独自拡張おわり
*/


body {
	color: black;
	background-color: #ffffff;
	margin: 0px;
	padding: 0px;
}

div.adminmenu {
	font-size: 90%;
	margin: 2% 5% 0% 0%;
	text-align: right
}

span.adminmenu {}

h1 {
	text-align: left;
	font-size: 16pt;
	font-weight: bold;
	border-bottom: 1px dotted #adb2ff;
	margin-top: 10px;
	margin-bottom: 10px;
	margin-left: 5%;
	margin-right: 5%;
	padding: 4px 4px 4px 4px;
}

div.calendar {
	font-size: 90%;
	margin: 1% 5% 0 5%;
	padding: 1%;
	text-align: left;
}

.headline {
	font-size: 90%;
	margin: 0% 10% 0% 10%;
	padding: 2%;
	text-align: left;
	background-color: #ffee99;
}

div.intro{
	margin-top: 2%;
	margin-right: 5%;
	margin-bottom: 2%;
	margin-left: 5%;
}

div.day {
	margin: 0% 5% 0% 5%;
	padding: 4px;
}

td.main div.day div.body{
	_width: auto;
}

h2 {
	font-size: 100%;
	background-color: #5279e7;
	padding: 3px 0px 2px 10px;
	margin: 5px 0 0 0;
	width: auto;
	_width: 100%;
}

h2 span.date {
	color: #ffffff;
	font-size: 100%;
	font-style: normal;
	margin-left: 2px;
	margin-right: 2px;
}

h2 span.title {
	color: #ffffff;
	font-size: 100%;
	font-style: normal
}

h2 span.title a {
	color: #ffffff;
}

div.body {
	font-size: 90%;
	border: #5279e7 1px solid;
	margin-top: 0px;
	margin-bottom: 0px;
	padding: 3px 10px 3px 10px;
	line-height: 1.5;
	width: auto;
	_width: 100%;
}

div.section {
	margin-top: 2%;
	margin-bottom: 2%
}

h3 {
	font-size: 120%;
	font-weight: bold;
	margin-top: 2%;
	margin-bottom: 0.1%
}

h4 {
	font-size: 100%;
	font-weight: bold;
	margin: 0.6em 10% 0 0.4em;
	border-left: 5px solid #5279E7;
	border-bottom: 1px solid #5279E7;
	padding: 0px 0.5em 0.1em 0.5em;
}
h5 {
	font-size: 100%;
	margin: 0.5em 0 0 0.7em;
}

div.day span.sanchor {
	color: #5279e7;
}

div.day span.canchor {
	color: black;
}

div.day p {
	margin-bottom: 0.5%;
	margin-top: 0.5%;
	text-indent: 1em
}

div.section p {
	padding-top: 0.2%;
	padding-bottom: 0.2%;
}

div.comment {
	font-size: 90%;
	line-height: 1.5;
}

div.comment p {
	margin-left: 0em! important;
	text-indent: 0em
}


div.referer {
	font-size: 90%;
	border-top: #5279e7 1px solid;
	border-bottom: #5279e7 1px solid;
	text-align: right;
	line-height: 1.5;
}

div.refererlist {
	font-size: 90%;
	margin: 0px;
	padding: 0px;
	width: auto;
	_width: 100%;
}

div.refererlist ul {
	background-color: #edf1fd;
	padding: 5px;
	margin: 0;
	list-style-type: circle;
	list-style-position: inside;
}
div.refererlist ul ul {
	background-color: #edf1fd;
	padding: 0;
	margin: 0 0 0 5%;
	list-style-type: disc;
	list-style-position: inside;
}

div.refererlist ul li.hatena-with-icon{
list-style:none;
}

div.caption {
	margin: 8px 0 0 0;
	border-bottom: #5279e7 1px solid;
}

hr {}

hr.sep { display: none }

.sfooter {}

div.footer {
	color: #cccccc;
	margin: 5px;
	font-size: 80%;
	text-align: center;
}

div.footer a {
	color: #cccccc;
}

div.form {
	font-size: 90%;
	line-height: 1.5;
	margin: 1% 5% 1% 5%;
	padding: 1%;
	text-align: center;
}

div.form form {
	width: 100%;
}

input.field {
	color: #06040F;
	background-color: #ffffff;
	border: 1px solid #5279e7;
	text-indent: 0em ! important;

}

input.select { 
	text-indent: 0em ! important;
}

textarea {
	font-size: 90%;
	color: #06040F;
	background-color: #ffffff;
	border: 1px solid #5279e7;
	height: 30em;
	width: 50em;
}

p.message {
	color: red;
	background-color: #ffffff;
	font-size: 100%;
	padding-top: 8px;
	padding-right: 8px;
	padding-bottom: 8px;
	padding-left: 8px;
	text-align: center;
}

pre {
	background-color: #e7ebff;
	padding: 8px;
}

div.body dl {
	margin-left: 2em;
}

div.body dt {
	font-weight: bold;
	margin-bottom: 0.2em;
}
div.body dd {
	margin-left: 1em;
	margin-bottom: 0.5em;
}

div.body blockquote {
	color: #333333;
	background-color: #ffffff;
	border: #5279e7 1px solid;
	margin: 1% 2%;
	padding-top: 8px;
	padding-right: 8px;
	padding-bottom: 8px;
	padding-left: 8px;
}

div.section blockquote p {
	margin-left: 0em;
	text-indent: 0em
}

em {
	font-style: italic;
}

strong {
	font-weight: bold
}

.hide {
	color: #000000;
	background-color: #ffffff
}

/* calendar2 */
table.calendar {
	font-size: 0.8em;
	line-height: 100%;
	background-color: transparent;
	margin: 0;
}

table.calendar td {
	margin: 0;
	padding: 1px 2px 0px 2px;
	text-align: right;
}

table.calendar td.calendar-prev-month, table.calendar
td.calendar-current-month, table.calendar td.calendar-next-month {
	text-align: center;
}

table.calendar td.calendar-sunday {
	color: red;
}
table.calendar td.calendar-saturday {
	color: blue;
}
td.calendar-day img {
	width: 15px;
	height: 15px;
	border: 0;
}

table.calendar td.day-today{
background:#FFFFCC;
}

table.calendar td.day-selected{
background:#5279E7;
}

table.calendar td.day-selected a{
color:#FFFFFF;
}


/*
ツッコミ省略版本文
*/
div.commentshort {
	margin-bottom: 10px;
}

span.commentator {
}

div.commentshort p {
	margin: 0.2em 0 0.2em 0;
	line-height: 1.2em;
}

div.commentshort p .canchor a{
	color:black;
}

/*
ツッコミ本体
*/
div.commentbody {
	margin: 0.5em;
	line-height: 1.2em;
}

/*
ツッコミした人の情報
*/
div.commentator {
	line-height: 1.5em;
	font-weight: bold;
}

/*
ツッコミ本文
*/
div.commentbody p {
	margin: 0.5em;
}

/*
フォームの設定
*/
div.form form {
	margin: 0em;
}

div.field {
	display: inline;
	margin-right: 2em;
}

div.textarea {
	display: block;
	vertical-align: top;
	text-align: center;
}

form.comment textarea {
	width: 40em;
	height: 3em;
}

div.button {
	display: block;
}

/*
更新フォーム
*/
form.update {
	padding-top: 0.5em;
	padding-bottom: 0.5em;
}

form.update input, form.update textarea, form.commentstat input {
	background-color: #ffffff;
	color: #06040F;
}

form.update span.field {
	display: inline;
	margin-left: 0em;
	margin-right: 0.5em;
}

form.update div.field.title {
	display: block;
	margin-top: 1em;
}

form.update div.field.title input {
	margin-left: 0.5em;
}

form.update div.textarea {
	display: block;
	margin-top: 1em;
	text-align: center;
}

form.update textarea {
	display: block;
	margin-bottom: 1em;
	width: 35em;
	height: 15em;
	margin-left: auto;
	margin-right: auto;
}

form.update span.checkbox.hidediary {
	margin-left: 1em;
}

div.day.update div.comment {
	text-align: center;
}

div.comment form{
	margin-top: 0em;
}

td.sidebar {
	width: 120px;
	padding: 10px 0px 0px 0px;
	vertical-align: top;
}

td.main {
	width: 100%;
	padding: 0px;
	vertical-align: top;
}

div.main {
	margin-left: 170px;
}

div.sidebar {
	position: absolute;
	top: 0px;
	left: 0px;
	width: 150px;
	margin-left: 5%;
}

/* recent_list, title_list */
p.recentitem {
	padding: 1px;
	font-size: 10pt;
	text-align: center;
	margin-top: 0px;
	margin-bottom: 2px;
	border-color: #adb2ff;
	border-style: solid;
	border-width: 0px 0px 1px 0px;
}

div.recentsubtitles {
	font-size: 10pt;
	margin-top: 0px;
	margin-bottom: 1em;
	margin-left: 0em;
	line-height: 110%;
}

div.hatena-asin-detail {
	margin: 10px;
	padding-left: 10px;
}

div.hatena-asin-detail p {
	text-indent: 0em ! important;
	line-height: 150%;
}

div.hatena-asin-detail ul {
	list-style-type: none;
	margin: 0;
	margin-top: 10px;
	padding: 0;
}

img.hatena-asin-detail-image {
	float: left;
	border: 0;
}

div.hatena-asin-detail-info {
	margin-left: 10px;
	float: left;
	word-break: break-all;
}

p.hatena-asin-detail-title {
	font-weight: bold;
}

div.hatena-asin-detail-foot {
	clear: left;
}
div.section p.sectionfooter { 
  font-size:90%;
  text-align: right;
  margin-top: 1em;
}

/*
テーブル記法
*/
div.day table{
margin:10px;
}

div.day table tr th{
font-size:90%;
padding:3px;
background:#EEE;
border-bottom:1px solid gray;
}

div.day table tr td{
font-size:90%;
padding:3px;
border-bottom:1px dashed gray;
}

div.day table.plaintable{
margin:0px;
}

div.day table.plaintable tr td{
padding:0px;
font-size:100%;
border:none;
}

div.day table.plaintable tr th{
padding:0px;
background:transparent;
border:none;
font-size:100%;
}

/*
グラフ記法
*/

div.hatena-graph a img{
border:none;
}

img.hatena-graph-image{
border:none;
}
/* keywordcloud */

ul.keywordcloud {
  margin: 10px;
  padding: 0;
}

ul.keywordcloud li {
  font-size:90%;
  display: inline;
  font-family: 'Arial',sans-serif;
  color:gray;
}

a.keywordcloud0 { font-size: 80%; }
a.keywordcloud1 { font-size: 100%; }
a.keywordcloud2 { font-size: 120%; }
a.keywordcloud3 { font-size: 140%; }
a.keywordcloud4 { font-size: 160%; }
a.keywordcloud5 { font-size: 180%; }
a.keywordcloud6 { font-size: 200%; }
a.keywordcloud7 { font-size: 220%; }
a.keywordcloud8 { font-size: 240%; }
a.keywordcloud9 { font-size: 260%; }
a.keywordcloud10 { font-size: 280%; }
a.keywordcloud0, a.keywordcloud1, a.keywordcloud2, a.keywordcloud3, a.keywordcloud4, a.keywordcloud5, a.keywordcloud6, a.keywordcloud7, a.keywordcloud8, a.keywordcloud9, a.keywordcloud10 {
  text-decoration: none;
}

/* profile image */

img.hatena-id-icon{
vertical-align:middle;
margin-right:2px;
margin-bottom:4px;
border:none;
}

img.hatena-id-image{
border:none;
}

/* Kwiki::Theme::Hatena original */

form {
        padding: 0;
        margin: 0;
} 

div.header {
	color: #5279E7;
        text-align: left;
        font-size: 18pt;
        font-weight: bold;
        border: 0;
        margin: 12px 10px 4px 6px;
        padding: 0;
        font-family:"Century Gothic";
        letter-spacing: 0;
}

__template/tt2/edit_button_icon.html__
Edit
__template/tt2/rss_button.html__

__template/tt2/search_box.html__

__theme/hatena/images/.htaccess__
Allow from all
__theme/hatena/images/dot.gif__
R0lGODlhAQABAID/AMDAwAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==
__theme/hatena/images/b_entry_de.gif__
R0lGODlhEAAMAPEBABhBzv///////wAAACH5BAEAAAIALAAAAAAQAAwAAAJtFAgQIECAAAFCRJgw
YcKECRMGRJgwYUCAABMGRBgwYUCEAREGRAgQYUCEAREGBAgQYECAABEGRBgwYUCECQEGRBgwYUCE
CQEGRBgQYECECQEGRJgwYUCAABEGRJgwYcKECRMGFAgQIECAAAFCBQA7
__theme/hatena/images/b_append.gif__
R0lGODlhEAAMAJECAP///xhBzv///wAAACH5BAEAAAIALAAAAAAQAAwAAAIjVI6ZBu3/TlNOAovD
1JfnDXZJ+IGl1UFlelLpC8WXodSHUAAAOw==
__theme/hatena/images/rss_de.gif__
R0lGODlhGAAMAPEBABhBzv///////wAAACH5BAEAAAIALAAAAAAYAAwAAAKjFAgQIECAAAECBAgQ
IESECRMmTJgwYcKECRMGRAgQIMKEAAEmDAgQYUCEABMCDIgwIEKACQEGRAgwIcCACBMmBJgwYUCE
ABMCDAgQYUKAABMGRAgQIMKEAQEiTAgQYECEAAMiTJgwIMKECQEGRAgwIcCACAMiBJgQYECEABMG
RAgQYMKAABEGRJgwYcKECRMmTJgwYUCBAAECBAgQIECAAAFCBQA7
__config/hatena_theme.yaml__
hatena_theme_logo_width: 60
hatena_theme_logo_height: 60
