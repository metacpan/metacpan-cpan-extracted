package Kwiki::FetchRSS;
use Kwiki::Plugin '-Base';
use Kwiki::Installer '-base';

our $VERSION = '0.08';

const class_id    => 'fetchrss';
const class_title => 'Fetch RSS';
const config_file => 'fetchrss.yaml';
const css_file    => 'fetchrss.css';
field 'cache';
field 'error';
field 'expire';
field 'timeout' => -init => '$self->hub->config->fetchrss_ua_timeout';

sub register {
    my $registry = shift;
    $registry->add( wafl => fetchrss => 'Kwiki::FetchRSS::Wafl' );
}

sub cache_dir {
    $self->plugin_directory;
}

sub get_content {
    my $url = shift;
    my $content;

    require LWP::UserAgent;
    my $ua  = LWP::UserAgent->new();
    $ua->timeout($self->timeout);
    if (defined($self->hub->config->fetchrss_proxy) and
        $self->hub->config->fetchrss_proxy ne '' ) {
        $ua->proxy([ 'http' ], $self->hub->config->fetchrss_proxy);
    }
    my $response = $ua->get($url);
    if ($response->is_success()) {
        $content  = $response->content();
        if (length($content)) {
            $self->cache->set( $url, $content, $self->expire );
        } else {
            $self->error('zero length response');
        }
    } else {
        $self->error($response->status_line);
    }
    return $content;
}

sub setup_cache {
    require Cache::FileCache;
    $self->cache(Cache::FileCache->new( {
         namespace   => $self->class_id,
         cache_root  => $self->cache_dir,
         cache_depth => 1,
         cache_umask => 002,
    } ));
}

sub get_cached_result {
    my $name  = shift;
    return($self->cache->get($name));
}

sub get_feed { my ($url, $expire) = @_;

    require XML::Feed;

    $self->expire($expire
        ? $expire
        : $self->hub->config->fetchrss_default_expire()
    );
    $self->setup_cache;

    my $content = $self->get_cached_result($url);
    if ( !defined($content) or !length($content) ) {
        $content = $self->get_content($url);
    }

    if (defined($content) and length($content)) {
        my $feed; 
        # XXX needs to be an eval here, sometimes the parse
        # make poop on bad input
        eval {
            $feed = XML::Feed->parse(\$content) or die XML::Feed->errstr;
        };
        return $feed unless $@;
        $self->error("xml parser error: $@");
    }
    return {error => $self->error};
}

package Kwiki::FetchRSS::Wafl;
use Spoon::Formatter;
use base 'Spoon::Formatter::WaflPhrase';

sub to_html {
    my ($url, $full, $expire) = split(/,?\s+/, $self->arguments);
    return $self->wafl_error unless $url;
    my $feed = $self->hub->fetchrss->get_feed($url, $expire);
    $self->hub->template->process('fetchrss.html', full => $full,
        method => $self->method, fetchrss_url => $url,
        feed => $feed);
}


1;

package Kwiki::FetchRSS;

1;

__DATA__

=head1 NAME

Kwiki::FetchRSS - Wafl Phrase for including RSS feeds in a Kwiki Page

=head1 DESCRIPTION

  {fetchrss <rss url> [full] [expire]}

Kwiki::FetchRSS retrieves and caches an RSS feed from a blog, news 
site, wiki, wherever and presents it in a Kwiki page. It can optionally
display the description text for each item, or just the headline. Cache
expiration times for each phrase may be set, or a default can be set
in the configuration file fetrchrss.yaml.

You can see Kwiki::FetchRSS in action at http://www.burningchrome.com/wiki/

This code needs some feedback to find its way in life.

=head1 AUTHORS

Alex Goller
Chris Dent <cdent@burningchrome.com>

=head1 SEE ALSO

L<Kwiki>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, the authors

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__template/tt2/fetchrss.html__
<!-- BEGIN fetchrss.html -->
<div class="fetchrss_box">
<div class="fetchrss_titlebox">
[% IF feed.error %]
Error: [% feed.error %]
[% END %]
<center>
[% IF feed.rss.image.link && feed.rss.image.url %]
<a href="[% feed.rss.image.link %]">
 <img src="[% feed.rss.image.url %]"
  alt="[% feed.rss.image.title %]"
  border="0"
  [% IF feed.rss.image.width %]
   width="[% feed.rss.image.width %]"
  [% END %]
  [% IF feed.rss.image.height %]
   height="[% feed.rss.image.height %]"
  [% END %]
[% END %]

[% IF feed.title %]
 <div class="fetchrss_title">
   <a href="[% feed.link %]">[% feed.title %]</a></h3>
 </div>
[% END %]
</center>
</div>

[% FOREACH item = feed.entries %]
 <div class="fetchrss_item">
     <a href="[% item.link %]">[% item.title %]</a><br />
   [% IF full && item.content.body %]
     <blockquote class="fetchrss_description">
         [% item.content.body %]
     </blockquote>
   [% END %]
 </div>
[% END %]

[% IF feed.channel.copyright %]
<div class="fetchrss_titlebox">
<sub>[% feed.channel.copyright %]</sub>
</div>
[% END %]
</div>
<!-- END fetchrss.html -->
__config/fetchrss.yaml__
fetchrss_proxy:
fetchrss_ua_timeout: 30
fetchrss_default_expire: 1h
__css/fetchrss.css__
.fetchrss_box {
  clear: both;
  margin-top: 5px;
  margin-left: 5px;
  border: 1px dashed #aaaaaa;
  background: #dddddd;
  font-family: Arial,Helvetica,Verdana,sans-serif;
}
.fetchrss_titlebox {
  background: #ffffff;
  padding-bottom: 5px;
  padding-top: 5px;
}
.fetchrss_title { font-weight: bold; font-size: large;}
.fetchrss_item { padding-left: 5px; }
.fetchrss_description { font-size: smaller; }
