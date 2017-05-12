package Kwiki::Atom;
use strict;
use warnings;
use Kwiki::Plugin '-Base';
use Kwiki::Display;
use mixin 'Kwiki::Installer';
our $VERSION = '0.15';

use XML::Atom;
use XML::Atom::Feed;
use XML::Atom::Link;
use XML::Atom::Entry;
use XML::Atom::Content;

use DateTime;
use Kwiki::Atom::Server;

use constant ATOM_TYPE => "application/atom+xml";

const class_id      => 'atom';
const class_title   => 'Atom';
const css_file      => 'atom.css';
const config_file   => 'atom.yaml';
const cgi_class     => 'Kwiki::Atom::CGI';
const server_class  => 'Kwiki::Atom::Server';

field depth => 0;
field 'headers';
field 'server';

sub process {
}

sub register {
    my $registry = shift;
    $registry->add(action => 'atom_edit');
    $registry->add(action => 'atom_feed');
    $registry->add(action => 'atom_post');
    $registry->add(toolbar => 'recent_changes_atom_button', 
                   template => 'recent_changes_atom_button.html',
                   show_for => ['recent_changes'],
                  );
    $registry->add(toolbar => 'edit_atom_button', 
                   template => 'edit_atom_button.html',
                   show_for => ['display'],
                   params_class => $self->class_id,
                  );
}

sub fill_links {
    my $name = eval { $self->hub->cgi->page_name };
    my $url = CGI->new->url;
    push @{ $self->hub->{links}{all} }, ($name ? {
        rel => 'alternate',
        type => ATOM_TYPE,
        href => "$url?action=atom_edit;page_name=". $self->pages->current->uri,
    } : ()), {
        rel => 'service.feed',
        type => ATOM_TYPE,
        href => "$url?action=atom_feed",
    }, {
        rel => 'service.post',
        type => ATOM_TYPE,
        href => "$url?action=atom_post",
    };
    return;
}

sub toolbar_params {
#    require YAML;
#    open X, '>>/tmp/post.log';
#    print X "POSTDATA:\n", $self->cgi->POSTDATA, "\n";
#    print X "HEADERS:\n", YAML::Dump(\%ENV), $/;
#    close X;
    return () unless $ENV{CONTENT_TYPE} and
                    ($ENV{CONTENT_TYPE} eq ATOM_TYPE
                  or $ENV{CONTENT_TYPE} =~ m{^\w+/xml}); # XXX ecto XXX

    $self->atom_post;

    my %header = &Spoon::Cookie::content_type;
    print CGI::header(%header);
    print $self->server->print;
    exit;
}

sub fill_header {
    $self->wrap_header if !$self->headers;
    $self->headers( [ @{$self->headers||[]}, @_ ] );
}

sub wrap_header {
    my $server = $self->server($self->server_class->new);

    my %accept = map { $_ => 1 }
                 $server->request_header('Accept') =~ m{([^\s,]+/[^;,]+)}g;
    my $content_type = 'text/xml'; # fallback
    foreach my $try_type (qw(
        application/atom+xml
        application/x.atom+xml
        application/xml
    )) {
        $accept{$try_type} or next;
        $content_type = $try_type;
        last;
    }

    $content_type .= '; charset=UTF-8';
    $server->response_content_type($content_type);
    $server->client($self);

    $self->hub->headers->content_type($content_type);
}

sub make_entry {
    my ($page, $depth, $flavor) = @_;
    my $url = $self->server->uri;

    my $author = XML::Atom::Person->new;
    $author->name($page->metadata->edit_by);

    my $link_html = XML::Atom::Link->new;
    $link_html->type('text/html');
    $link_html->rel('alternate');
    $link_html->href("$url?".$page->uri);
    $link_html->title('');

    my $link_edit = XML::Atom::Link->new;
    $link_edit->type(ATOM_TYPE);
    $link_edit->rel('service.edit');
    $link_edit->href("$url?action=atom_edit;page_name=".$page->uri);
    $link_edit->title('');

    my $entry = XML::Atom::Entry->new;
    $entry->title($page->title);

    my $content = XML::Atom::Content->new;
    my $elem = $content->elem;
    my $text = ($content->LIBXML) ? 'XML::LibXML::Text'
                                  : 'XML::XPath::Node::Text';
    if ($flavor and $flavor eq 'html')  {
        $content->type('text/html');

        my $data = $page->to_html;
        my $copy = qq(<div xmlns="http://www.w3.org/1999/xhtml">$data</div>);
        my $node;
        local $@;
        eval {
            if ($content->LIBXML) {
                require XML::LibXML;
                my $parser = XML::LibXML->new;
                my $tree = $parser->parse_string($copy);
                $node = $tree->getDocumentElement;
            } else {
                require XML::XPath;
                my $xp = XML::XPath->new(xml => $copy);
                $node = (($xp->find('/')->get_nodelist)[0]->getChildNodes)[0]
                    if $xp;
            }
        };
        if (!$@ && $node) {
            $elem->appendChild($node);
            $elem->setAttribute('mode', 'xml');
        } else {
            $elem->appendChild($text->new($data));
            $elem->setAttribute('mode', 'escaped');
        }
    }
    else {
        $content->type('text/plain');
        $elem->appendChild($text->new($page->content));
        $elem->setAttribute('mode', 'escaped');
    }

    $entry->content($content);
    $entry->summary('');
    $entry->issued( DateTime->from_epoch( epoch => $page->io->ctime || time )->iso8601 . 'Z' );
    $entry->modified( DateTime->from_epoch( epoch => $page->io->mtime || time )->iso8601 . 'Z' );
    $entry->id("$url?".$page->uri);

    $entry->author($author);
    $entry->add_link($link_html);
    $entry->add_link($link_edit);

    return $entry;
}

sub update_page {
    my $page = shift;
    my $method = $self->server->request_method;
    my $entry = eval { $self->server->atom_body };

    if (!$entry) {
        print "Status: 400\n\n";
        $self->fill_header( -status => 400 );
        return;
    }

    if (!$page) {
        my $title = $entry->title;
        if ($entry->content->type =~ /\bx?html\b/i) {
            require HTML::Entities;
            HTML::Entities::decode_entities($title);
        }
        $page = $self->pages->new_page($title);

        if ($page->exists and $method eq 'POST') {
            $self->server->response_code(409);
            $self->server->{_error} = 'This page already exists';
            $self->fill_header(
                -status => 409,
                -type => 'text/plain',
                -warning => 'This page already exists',
            );
            return undef;
        }
    }

    $self->hub->users->current->name(
        eval { $self->server->get_auth_info->{Username} }
            || $self->hub->config->user_default_name
    );
    my $body = $entry->content->body;
    if ($entry->content->type =~ /\bx?html\b/i) {
        $body =~ s/<[^>]+>//g;
        require HTML::Entities;
        HTML::Entities::decode_entities($body);
    }
    $page->content($body);
    $page->update->store;

    return $page;
}

sub atom_list {
    my $url = $self->server->uri;

    my $link_feed = XML::Atom::Link->new;
    $link_feed->type(ATOM_TYPE);
    $link_feed->rel('service.feed');
    $link_feed->title($self->config->site_title);
    $link_feed->href("$url?action=atom_feed");

    my $link_post = XML::Atom::Link->new;
    $link_post->type(ATOM_TYPE);
    $link_post->rel('service.post');
    $link_post->title($self->config->site_title);
    $link_post->href("$url?action=atom_post");

    my $feed = XML::Atom::Feed->new;
    $feed->title($self->config->site_title);
    $feed->info($self->config->site_title);
    $feed->add_link($link_feed);
    $feed->add_link($link_post);
    $feed->modified(DateTime->now->iso8601 . 'Z');

    $self->munge($feed->as_xml);
}

sub atom_post {
    $self->fill_header;
    return $self->atom_list if $self->server->request_method eq 'GET';

    $self->server->{request_content} = $self->cgi->POSTDATA
        if $self->server->request_method eq 'POST';

    $self->server->run;
    $self->server->print;
}

sub atom_edit {
    $self->fill_header;
    $self->server->run;
    $self->server->print;
}

sub atom_feed {
    $self->fill_header;

    my $depth = $self->cgi->depth;
    my $flavor = $self->cgi->flavor;
    my $pages = [
        sort {
            $b->modified_time <=> $a->modified_time 
        } ($depth ? $self->pages->recent_by_count($depth) : $self->pages->all)
    ];

    my $timestamp = @$pages ? $pages->[0]->metadata->edit_unixtime : time;

    my $cache = eval { $self->hub->load_class('cache') }
      or return $self->generate($pages, $depth, $flavor, $timestamp);

    $cache->process(
        sub { $self->generate($pages, $depth, $flavor, $timestamp) },
        'atom', $depth, $flavor, $timestamp, int(time / 600)
    );
}

sub generate {
    my ($pages, $depth, $flavor, $timestamp) = @_;

    my $datetime = DateTime->from_epoch( epoch => $timestamp );
    my $url = $self->server->uri;
    my $link_html = XML::Atom::Link->new;
    $link_html->type('text/html');
    $link_html->rel('alternate');
    $link_html->title($self->config->site_title);
    $link_html->href($url);

    my $link_post = XML::Atom::Link->new;
    $link_post->type('application/atom+xml');
    $link_post->rel('service.post');
    $link_post->title($self->config->site_title);
    $link_post->href("$url?action=atom_post");

    my $feed = XML::Atom::Feed->new;
    $feed->title($self->config->site_title);
    $feed->info($self->config->site_title);
    $feed->add_link($link_html);
    $feed->add_link($link_post);
    $feed->modified($datetime->iso8601 . 'Z');

    my $author = XML::Atom::Person->new;
    $author->name($self->config->site_url);

    $self->config->script_name($url);

    for my $page (@$pages) {
        $feed->add_entry( $self->make_entry($page, $depth, $flavor) );
    }

    $self->munge($feed->as_xml);
}

sub munge {
    my $xml = shift;
    $xml =~ /<\?xml/ or $xml = qq(<?xml version="1.0"?>$xml);
    $xml =~ s/version="1.0"(?![^>]*encoding=)/version="1.0" encoding="UTF-8"/;
    $xml =~ s/(<\w+)/$1 version="0.3"/;
    $xml =~ s{\?>}{?><?xml-stylesheet type="text/css" href="css/atom.css"?>};
    return $xml;
}

package Kwiki::Atom::CGI;
use Kwiki::CGI '-base';

cgi 'depth';
cgi 'flavor';
cgi 'POSTDATA';

1;

package Kwiki::Atom;

1;

__DATA__

=head1 NAME 

Kwiki::Atom - Kwiki Atom Plugin

=head1 VERSION

This document describes version 0.15 of Kwiki::Atom, released
April 1, 2005.

=head1 SYNOPSIS

    % cd /path/to/kwiki
    % kwiki -add Kwiki::Atom

=head1 DESCRIPTION

This Kwiki plugin provides Atom 0.3 integration with Kwiki.

If you plan to offer your Atom feeds to the public, please consider installing
the B<Kwiki::Cache> module, which can significantly reduce the server load.

For more info about this kind of integration, please refer to
L<http://www.xml.com/pub/a/2004/04/14/atomwiki.html>.

Currently, this plugin has been tested with the following AtomAPI clients:

=over 4

=item * wxAtomClient.py

L<http://piki.bitworking.org/piki.cgi>

=item * ecto

L<http://ecto.kung-foo.tv/>

=back

=head1 AUTHOR

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2004, 2005 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__config/atom.yaml__
site_description: The Kwiki Wiki
site_url: http://localhost/par/
__template/tt2/recent_changes_atom_button.html__
<!-- BEGIN recent_changes_atom_button.html -->
<a href="[% script_name %]?action=atom_feed;depth=15;flavor=html" title="AtomFeed">
[% INCLUDE recent_changes_atom_button_icon.html %]
</a>
<!-- END recent_changes_atom_button.html -->
__template/tt2/recent_changes_atom_button_icon.html__
<!-- BEGIN recent_changes_atom_button_icon.html -->
Atom
<!-- END recent_changes_atom_button_icon.html -->
__icons/gnome/template/recent_changes_atom_button_icon.html__
<!-- BEGIN recent_changes_atom_button_icon.html -->
<img src="icons/gnome/image/atom_feed.png" alt="Atom" />
<!-- END recent_changes_atom_button_icon.html -->
__icons/gnome/image/atom_feed.png__
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPBAMAAADJ+Ih5AAAAMFBMVEX////yZ2fh4eH5+fm+
v7/r6+u3SEjV1dWmenqzs7PPz8/Hx8elpaXGxsbMzMyUlJQfgNlcAAAAAXRSTlMAQObYZgAA
ABZ0RVh0U29mdHdhcmUAZ2lmMnBuZyAyLjQuNqQzgxcAAAB7SURBVHjaY2DAAEy3d++NelfM
wBBrwHzziuodA4ZFDOvKy51YFjBctdVqy7iieoCh6JGFYFqr7wQGewU1QbE8/g0MlUBGWpb9
BIbNSy3S0lqnTmC4YLeyLeNIwQGGCwxaV+ZMYjjA8IiB+c7PUJ0CBrvbWyZZvduKsBMAMi0q
dW1+s4IAAAAASUVORK5CYII=
__template/tt2/edit_atom_button.html__
<!-- BEGIN edit_atom_button.html -->
<a href="[% script_name %]?action=atom_edit;page_name=[% page_uri %]" title="AtomEdit">
[% INCLUDE edit_atom_button_icon.html %]
</a>
<!-- END edit_button.html -->
__template/tt2/edit_atom_button_icon.html__
<!-- BEGIN edit_atom_button_icon.html -->
Atom
<!-- END edit_atom_button_icon.html -->

__icons/gnome/template/edit_atom_button_icon.html__
<!-- BEGIN edit_atom_button_icon.html -->
<img src="icons/gnome/image/atom_edit.png" alt="Atom" />
<!-- END edit_atom_button_icon.html -->

__icons/gnome/image/atom_edit.png__
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPBAMAAADJ+Ih5AAAAMFBMVEX////yZ2fh4eH5+fm+
v7/r6+u3SEjV1dWmenqzs7PPz8/Hx8elpaXGxsbMzMyUlJQfgNlcAAAAAXRSTlMAQObYZgAA
ABZ0RVh0U29mdHdhcmUAZ2lmMnBuZyAyLjQuNqQzgxcAAAB7SURBVHjaY2DAAEy3d++NelfM
wBBrwHzziuodA4ZFDOvKy51YFjBctdVqy7iieoCh6JGFYFqr7wQGewU1QbE8/g0MlUBGWpb9
BIbNSy3S0lqnTmC4YLeyLeNIwQGGCwxaV+ZMYjjA8IiB+c7PUJ0CBrvbWyZZvduKsBMAMi0q
dW1+s4IAAAAASUVORK5CYII=
__template/tt2/kwiki_begin.html__
<!-- BEGIN kwiki_begin.html -->
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <title>
[% IF hub.action == 'display' || 
      hub.action == 'edit' || 
      hub.action == 'revisions' 
%]
  [% hub.cgi.page_name %] -
[% END %]
[% IF hub.action != 'display' %]
  [% self.class_title %] - 
[% END %]
  [% site_title %]</title>
[% hub.load_class('atom').fill_links %]
[% FOR link = hub.links.all -%]
  <link rel="[% link.rel %]" type="[% link.type %]" href="[% link.href %]" />
[% END %]
[% FOR css_file = hub.css.files -%]
  <link rel="stylesheet" type="text/css" href="[% css_file %]" />
[% END -%]
[% FOR javascript_file = hub.javascript.files -%]
  <script type="text/javascript" src="[% javascript_file %]"></script>
[% END -%]
  <link rel="shortcut icon" href="" />
  <link rel="start" href="[% script_name %]" title="Home" />
</head>
<body>
<!-- END kwiki_begin.html -->
__css/atom.css__
feed {
  display:block;
  font-family:verdana, sans-serif;
  margin:2%;
  font-size:90%;
  color:#000000;
  background:#ffffff;
}

title {
  display:block;
  font-size:1.3em;
  color:inherit;
  background:inherit;
  font-weight:bold;
}

tagline, link {
  display:block;
  font-size:0.9em;
}

id, modified, url {
  display:none;
}

generator {
  display:block;
  font-size:0.9em;
}

info {
  display:block;
  margin:3em 4em 3em 4em;
  color:#CC3333;
  background:#FFFF66;
  border:solid #CCCC66 2px;
  text-align:center;
  padding:1.5em;
  font-family:mono;
  font-size:0.8em;
}

entry {
  display:block;
  color:inherit;
  background:inherit;
  padding:0;
  margin:1em 1em 2em 1em;
  
}

entry modified, entry name {
  display:inline;
  color:#999999;
  background:inherit;
  font-size:0.8em;
}

entry created, entry issued, entry id {
  display:none;
}

entry title {
  display:block;
  font-size:1em;
  font-weight:bold;
  color:inherit;
  background:inherit;
  padding:1em 1em 0em 1em;
  margin:0;
  border-top:solid 1px #dddddd;
}

img.floatright {
  padding-left: 1em;
  float: right;
}

img.floatleft {
  float: left;
  padding-right: 1em;
  padding-bottom: 0.2em;
}

summary {
  display:block;
  background: #FFFF88;
  font-size:0.9em;
  color:inherit;
  margin:1em;
  line-height:1.5em;
}

content {
  display:block;
  font-size:0.9em;
  color:inherit;
  background:inherit;
  margin:1em;
  line-height:1.5em;
}
