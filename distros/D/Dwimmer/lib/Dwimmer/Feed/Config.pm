package Dwimmer::Feed::Config;
use strict;
use warnings;

our $VERSION = '0.32';

my %DEFAULT;

sub get_config_hash {
	my ($self, $db, $site_id) = @_;
	die 'Need 3 args for get_config_hash' if @_ != 3;

	return $db->get_config_hash(site_id => $site_id);
}

sub get_config {
	my ($self, $db, $site_id) = @_;
	die 'Need 3 args for get_config' if @_ != 3;

	my $config = $db->get_config(site_id => $site_id);
}

sub get {
	my ($self, $db, $site_id, $field) = @_;
	die 'Need 4 args for get' if @_ != 4;

	my $config = $db->get_config_hash(site_id => $site_id);
	return $config->{$field} // $DEFAULT{$field};
}

$DEFAULT{subject_tt} = q{[% title %]};

$DEFAULT{text_tt} = q{
Title: [% title %]
Link: [% link %]
Source: [% source %]
Tags: [% tags %]
Author: [% author %]

Date: [% issued %]
Summary:
[% summary %]
----------------------------
};

$DEFAULT{html_tt} = q{
<html><head><title></title></head><body>
<h1><a href="[% other.url %]">[% e.title %]</a></h1>
<p>[% e.summary %]</p>
<hr />

<p>Entry</p>
<p><a href="http://twitter.com/home?status=[% other.twitter_status %]">tweet</a></p>
<p>Original URL: [% e.link %]</p>
<p>Link: [% e.link %]</p>
<p>Entry ID: [% e.id %]</p>
<p>Tags: [% e.tags %]</p>
<p>Author: [% e.author %]</p>
<p>Date: [% e.issued %]</p>
<p>HTTP Status: [% other.status %]</p>
[% IF other.redirected %]
  <p>Redirected</p>
[% END %]

<hr />
<p>Source:</p>
<p>ID: [% e.source_id %]</p>
<p>Title: <a href="[% source.url %]">[% source.title %]</a></p>
<p>Twitter:
[% IF source.twitter %]
   <a href="https://twitter.com/#!/[% source.twitter %]">[% source.twitter %]</a></p>
[% ELSE %]
   NO twitter</p>
[% END %]

</body></html>
};


$DEFAULT{atom_tt} = q{
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">

<title>[% title %]</title>
<subtitle>[% subtitle %]></subtitle>
<link href="[% url %]"/>
<id>[% id %]</id>
<updated>[% last_build_date %]</updated>

<author>
  <name>[% admin_name %]</name>
  <email>[% admin_email %]</email>
</author>
<generator uri="http://search.cpan.org/dist/Dwimmer/" version="[% dwimmer_version %]">Dwimmer</generator>

[% FOR e IN entries %]
<entry>
  <author>
     <name>[% e.author_name %]</name>
     <uri>[% e.author_uri %]</uri>
  </author>
  <title>[% e.title %]</title>
  <link href="[% e.link %]"/>
  <id>[% e.id %]</id>
  <updated>[% e.issued %]</updated>
  <published>[% e.issued %]</published>
  <summary><![CDATA[[% e.display %]]]></summary>
</entry>
[% END %]

</feed>
};

$DEFAULT{rss_tt} = q{
<?xml version="1.0"?>
<?xml-stylesheet title="CSS_formatting" type="text/css" href="http://www.interglacial.com/rss/rss.css"?>
<rss version="2.0"><channel>

<link>[% url %]</link>
<title>[% title %]</title>
<description>[% description %]</description>
<language>[% language %]</language>
<lastBuildDate>[% last_build_date %]</lastBuildDate>
<webMaster>[% admin_email %]</webMaster>

<docs>http://www.interglacial.com/rss/about.html</docs>

[% FOR e IN entries %]
<item>
  <title>[% e.title %]</title>
  <link>[% e.link %]</link>
  <description><![CDATA[[% e.display %]]]></description>
  <dc:date>[% e.issued %]</dc:date>
</item>
[% END %]

</channel></rss>
};

$DEFAULT{header_tt} = q {
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en-us">
<head>
<title>[% title %]</title>
 <link href="/rss.xml" rel="alternate" type="application/rss+xml" title ="[% name %] RSS Feed" />
 <link href="/atom.xml" rel="alternate" type="application/atom+xml" title ="[% name %] ATOM Feed" />
 <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />

 <script type="text/javascript" src="https://apis.google.com/js/plusone.js"></script>
</head>
<body>
<style>
html {
  margin: 0;
  padding: 0;
}
body {
  margin: 0;
  padding: 0;
  /* text-align: center;*/
  width: 800px;
  margin-left: auto;
  margin-right: auto;
  font-size: 16px;

}
#header_text {
}

.entry {
  background-color: #DDD;
  padding: 10px;
  margin-top: 10px;
  margin-bottom: 10px;

  -moz-border-radius: 5px;
  -webkit-border-radius: 5px;
  border: 1px solid #000;
}

.postentry {
  min-height: 220px;
  height:auto !important;
  min-height: 220px;
}

.left {
  width: 675px;
  position: relative;
  background-color: #EEEEEE;

  padding: 5px;

  -moz-border-radius: 5px;
  -webkit-border-radius: 5px;
  border: 1px solid #000;

}

.entry_info {
  margin-top: 10px;
  width: 675px;
  background-color: #E4E4E4;
  padding: 5px;
  -moz-border-radius: 5px;
  -webkit-border-radius: 5px;
  border: 1px solid #000;
}

.social_link {
  float: right;
  position: relative;
  width: 70px;
  background-color: #DFDFDF;
  text-align: center;

  padding: 5px;
  -moz-border-radius: 5px;
  -webkit-border-radius: 5px;
  border: 1px solid #000;

}


.title {
  font-size: 24px;
  font-weight: bold;
}
.title a {
   text-decoration: none;
}
.error {
    color: red;
}

#header_text ul li {
   display: inline;
}

</style>
};

$DEFAULT{footer_tt} = qq{
<div>
<div>
Last updated: [% last_update %]
</div>
</div>

[% IF clicky %]
  <script src="//static.getclicky.com/js" type="text/javascript"></script>
  <script type="text/javascript">try{ clicky.init([% clicky %]); }catch(e){}</script>
  <noscript><p><img alt="Clicky" width="1" height="1" src="//in.getclicky.com/[% clicky %]ns.gif" /></p></noscript>
[% END %]

</body>
</html>
};

$DEFAULT{index_tt} = q{
  <h1>[% title %]</h1>
  <div id="header_text">
     <ul>
        [% IF admin_name %]<li> Admin: [% admin_name %] [% admin_email %]</li>[% END %]
        <li><a href="/feeds.html">feeds</a></li>
        <li><a href="/archive">archive</a></li>
     </ul>
  </div>
  <div>Number of entries: [% entries.size %]</div>

[% FOR e IN entries %]
  <div class="entry postentry">

    <div class="social_link">
        <a href="http://twitter.com/share" class="twitter-share-button"
         data-text="[% e.title %]" data-url="[% e.link %]" data-count="vertical" data-via="szabgab">Tweet</a>
        <script type="text/javascript" src="http://platform.twitter.com/widgets.js">
        </script>

      <script>reddit_url='[% e.link %]'</script>
      <script>reddit_title='[% e.title %]'</script>
      <script type="text/javascript" src="http://reddit.com/button.js?t=2"></script>


       <g:plusone size="tall" href="[% e.link %]"></g:plusone>

<!--
        <a name="fb_share" type="box_count" class="fb_share"
        share_url="[% e.link %]">Share</a>
         <script src="http://static.ak.fbcdn.net/connect.php/js/FB.Share" type="text/javascript"></script>
-->

    </div>

    <div class="left">
    <div class="source"><a href="[% e.source_url %]">[% e.source_name %]</a></div>
    <div class="title"><a href="[% e.link %]">[% e.title %]</a></div>
    <div class="summary">
    [% e.display %]
    </div>
    </div>
    <div class="entry_info">
    <div class="date">Posted on [% e.issued %]</div>
    <div class="permalink">For the full article visit <a href="[% e.link %]">[% e.title %]</a></div>
    </div>
  </div>
[% END %]
};

$DEFAULT{feeds_tt} = q{
  <h1>[% name %]feeds</h1>
  <a href="/">home</a>

[% FOR e IN entries %]
  <div class="entry">
  <div class="title"><a href="[% e.url %]">[% e.title %]</a></div>
  [% IF e.twitter %]
     <div class="twitter"><a href="https://twitter.com/#!/[% e.twitter %]">@[% e.twitter %]</a></div>
  [% END %]
  <div class="latest">Latest: <a href="[% e.latest_entry.link %]">[% e.latest_entry.title %]</a> on [% e.latest_entry.issued %]</div>
Status: [% e.last_fetch_status %]<br />
  [% IF e.last_fetch_error %]
     <div class="error">Latest error: [% e.last_fetch_error %] at [% e.last_fetch_time %]</div>
  [% END %]
  </div>
[% END %]

</div>
};


1;
