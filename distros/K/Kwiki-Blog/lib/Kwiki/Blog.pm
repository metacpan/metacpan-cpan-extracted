package Kwiki::Blog;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';

const class_id       => 'blog';
const class_title    => 'Blog';
const cgi_class      => 'Kwiki::CGI::Blog';
const css_file       => 'blog.css';

our $VERSION = '0.10';

sub register {
    my $registry = shift;
    $registry->add(wafl => bloglink => 'Kwiki::Blog::Wafl');
    $registry->add(action => 'blog_display');
    $registry->add(requires => 'keywords');
}

sub blog_display {
    my $keyword = $self->cgi->blog_name;
    my $start = $self->cgi->start || 0;
    my $count = $self->cgi->count || 10;

    $count = 10 if $count > 10;

    $start = $start > 0
      ? $start - 1
      : 0;

    my $pages = [sort {$a->age <=> $b->age}
        @{$self->hub->keywords->get_pages_for_keyword($keyword)}];
    my $end = $start + ($count -1);
    my $total_pages = scalar(@$pages);
    $end = $total_pages -1 if $end >= $total_pages;

    # XXX do this so css gets included in the screen rendering
    $pages = [map +{
        kwiki_link => $_->kwiki_link,
        to_html    => $_->to_html,
        edit_time  => $_->edit_time,
        uri        => $_->uri,
    }, @$pages[$start .. $end]];
    $self->render_screen(
        screen_title => "$keyword blog",
        pages => $pages,
        start => $start + 1,
        count => $count,
        end => $end + 1,
        total_pages => $total_pages,
        keyword => $keyword,
    );
}

package Kwiki::Blog::Wafl;
use Spoon::Formatter;
use base 'Spoon::Formatter::WaflPhrase';

sub to_html {
    my $keyword = $self->arguments;
    my $script_name = $self->hub->config->script_name;
    return
      qq(<a href="$script_name?action=blog_display;blog_name=$keyword">) .
      qq($keyword</a>);
}

package Kwiki::CGI::Blog;
use Kwiki::CGI -Base;

cgi 'blog_name';
cgi 'start';
cgi 'count';

package Kwiki::Blog;

__DATA__

=head1 NAME

Kwiki::Blog - Blogging for Kwiki

=head1 SYNOPSIS

=head1 DESCRIPTION

A very quick and dirty plugin for kwiki that could form the basis
of a way to do blogging. Needs a lot of work.

=head1 AUTHOR

Chris Dent

=head1 COPYRIGHT

Copyright (c) 2005. Chris Dent. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__template/tt2/blog_content.html__
<div class="blog">
[% INCLUDE blog_nav.html %]
[% FOR page = pages %]
<div class="blog_entry">
<h1>[% page.kwiki_link %]</h1>
<div class="blog_body">
[% page.to_html %]
</div>
<div class="blog_manage">
Edited: [% page.edit_time %] |
<a href="[% script_name %]?action=edit;page_name=[% page.uri %]">Edit</a>
</div>
</div>
[% END %]
[% INCLUDE blog_nav.html %]
</div>
__template/tt2/blog_nav.html__
<div class="blog_nav_link">
[% IF start > 1 %]
<a href="[% script_name %]?action=blog_display;blog_name=[% keyword %];start=[%
start - count %];count=[% count %]">&lt;&lt;</a> |
[% END %]
[% IF end < total_pages %]
<a href="[% script_name %]?action=blog_display;blog_name=[% keyword %];start=[%
end + 1 %];count=[% count %]">&gt;&gt;</a>
[% END %]
</div>
__css/blog.css__
.blog {
    padding: 1em;
    background-color: grey;
}

.blog_entry {
    padding: .5em;
    margin-bottom: .5em;
    border: thin solid black;
    background-color: white;
}

.blog_manage {
    margin: 0;
    border: thin solid black;
    padding: .5em;
    font-size: smaller;
}
