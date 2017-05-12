package Kwiki::Keywords;
use Kwiki::Plugin '-Base';
use Kwiki::Installer '-base';

const class_id       => 'keywords';
const class_title    => 'Keywords';
const cgi_class      => 'Kwiki::CGI::Keywords';
const config_file    => 'keywords.yaml';

field keywords_directory => '-init' =>
    '$self->plugin_directory . "/keywords"';
field pages_directory => '-init' =>
    '$self->plugin_directory . "/pages"';

our $VERSION = '0.14';

sub init {
    super;
    return unless $self->is_in_cgi;
    io($self->keywords_directory)->mkdir;
    io($self->pages_directory)->mkdir;
}

sub register {
    my $registry = shift;
    $registry->add(hook => 'page:store', post => 'add_automatic_keywords');
    $registry->add(action => 'keyword_display');
    $registry->add(action => 'keyword_add');
    $registry->add(action => 'keyword_del');
    $registry->add(action => 'keyword_list');
    $registry->add(widget => 'keywords',
                   template => 'keywords_widget.html',
                   show_for => 'display',
               );
    $registry->add(widget => 'keywords_related',
                   template => 'keywords_related_widget.html',
                   show_for => 'keyword_display',
               );
    $registry->add(toolbar => 'keyword_list',
                   template => 'keyword_list_button.html'
               );
}

sub keywords_from_cgi {
    my @keywords = split /\s+/, $self->cgi->keyword;
    return \@keywords;
}

sub keyword_add {
    my $keywords = $self->keywords_from_cgi;
    my $page = $self->hub->pages->new_from_name($self->cgi->page_name);
    my $count = 1;
    for my $keyword (@$keywords) {
        next unless $keyword;
        die "'$keyword' contains illegal characters"
          unless $keyword =~ /^[\w\-]+$/;
        $self->add_keyword($page, $keyword);
        last if ++$count > 5;   # sanity limit
    }
    $self->redirect($page->uri);
}

sub keyword_del {
    my $keyword = $self->cgi->keyword;
    my $page = $self->hub->pages->new_from_name($self->cgi->page_name);
    $self->del_keyword($page, $keyword);
    $self->redirect($page->uri);
}

sub keyword_display {
    my $keywords = $self->keywords_from_cgi;
    my $pages    = $self->get_pages_for_keywords(@$keywords);
    $self->render_screen(
        screen_title => "Pages with keywords {@$keywords}",
        pages => $pages,
    )
}

sub keyword_list {
    my $keywords = $self->get_all_keywords;
    my $blog = $self->hub->have_plugin('blog');
    $self->template_process($self->screen_template,
        content_pane => 'keyword_list.html',
        screen_title => "All Keywords",
        keywords => $keywords,
        blog => $blog,
    ); 
}

sub get_all_keywords {
    my $io = io($self->keywords_directory);
    return [ 
        sort {lc($a) cmp lc($b)}
        grep {
           scalar(@{$self->get_pages_for_keyword($_)}) 
        } 
        map {
            $_->filename
        } $io->all
    ];
}

sub get_pages_for_keywords {
    return $self->get_pages_for_keyword(@_) if @_ == 1;

    my %page;
    foreach my $keyword (@_) {
        foreach (@{ $self->get_pages_for_keyword($keyword) }) {
            my $title = $_->title;
            if ($page{$title}) { $page{$title}[1]++; next;  }
            else               { $page{$title} = [ $_, 1 ]; }
        }
    }
    return [ map { $_->[0] } grep { $_->[1] == @_ } values %page ];
}

sub get_pages_for_keyword {
    my $keyword = shift;
    my $io = io($self->keywords_directory . "/$keyword");
    my $pages = $io->exists
      ? [ map { 
          $self->hub->pages->new_from_name($_->filename) 
      } grep $_, $io->all ]
      : [];
    return $pages;
}

sub keywords_for_page {
    my $page = shift;
    my $io = io($self->pages_directory . "/$page");
    my $keywords = $io->exists
      ? [ 
            map { $_->filename } sort {
                $b->mtime <=> $a->mtime or
                lc("$a") cmp lc("$b")
            } $io->all
        ]
      : [];
    return $keywords;
}

sub keywords_for_current_page {
    my $page = $self->hub->pages->current->id;
    return $self->keywords_for_page($page);
}

sub get_related_keywords {
    my ($keywords) = @_;
    my $pages = $self->get_pages_for_keywords(@$keywords);

    my %relations;
    for (@$pages) {
        my $page_keywords = $self->keywords_for_page($_->id);
        for my $related (@$page_keywords) {
            next if grep { $related eq $_ } @$keywords;
            $relations{$related}++
        }
    }
    return [ keys %relations ];   
}

sub add_automatic_keywords {
    my $hook = pop;
    my $pages = $self; # we're running in the class with class id page
    $self = $self->hub->keywords; # move ourselves into this class
    return if $self->hub->config->keywords_no_automatic;
    $self->add_author_keyword;
}

sub add_author_keyword {
    my $author = $self->hub->users->current->name;
    my $page = $self->hub->pages->current;
    $self->add_keyword($page, $author) if $author;
}

sub add_keyword {
    my $page = shift;
    my $keyword = shift;
    return unless $page->is_writable;
    my $id = $page->id;
    io($self->keywords_directory . "/$keyword/$id")->assert->touch;
    io($self->pages_directory . "/$id/$keyword")->assert->touch;
}

sub del_keyword {
    my $page = shift;
    my $keyword = shift;
    return unless $page->is_writable;
    my $id = $page->id;
    io($self->keywords_directory . "/$keyword/$id")->unlink;
    io($self->pages_directory . "/$id/$keyword")->unlink;
}

package Kwiki::CGI::Keywords;
use Kwiki::CGI -Base;

cgi 'keyword';
cgi 'page_name';

package Kwiki::Keywords;

__DATA__

=head1 NAME

Kwiki::Keywords - Keywords for Kwiki

=head1 SYNOPSIS

  kwiki -add Kwiki::Keywords

=head1 DESCRIPTION

Kwiki::Keywords provides keywords (or tags) for each Kwiki Page. You
can then browse by keyword. If a page is edited by someone with
a Kwiki UserName, the name will be added as a keyword. This feature
can be turned off by setting

  keywords_no_automatic: 1

in config.yaml.

=head1 AUTHOR

YAPC::NA, Chris Dent, Brian Ingerson

=head1 CREDITS

This module was created on the fly at YAPC::NA 2005 in Toronto by
everyone at the Kwiki presentation.

Ricardo SIGNES provided the keywords_no_auto patch, made it
so keywords are only written to writable pages, and added support
for related tags and display of tag intersections.

=head1 COPYRIGHT

Copyright (c) 2005. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__template/tt2/keywords_content.html__
<table class="keywords">
[% FOR page = pages %]
<tr>
<td class="page_name">
[% page.kwiki_link %]
</td>
<td class="edit_by">[% page.edit_by_link %]</td>
<td class="edit_time">[% page.edit_time %]</td>
</tr>
[% END %]
</table>
__template/tt2/keyword_list.html__
<ul class="keywords">
[% FOR keyword = keywords %]
<li class="keyword">
<a href="[% script_name %]?action=keyword_display;keyword=[% keyword %]">
[% keyword %]
</a>
[% IF blog %]
(<a href="[% script_name %]?action=blog_display;blog_name=[% keyword %]">as blog</a>)
[% END %]
</li>
[% END %]
</ul>
__template/tt2/keywords_widget.html__
<script>
function keyword_delete(checkbox) {
    checkbox.value = ''
    if (! confirm("Really Remove This Keyword?"))
        return false
    var myform = document.forms.keywords
    myform.elements['action'].value = 'keyword_del'
    myform.elements['keyword'].value = checkbox.name
    myform.submit()
    return true
}

function keyword_validate(myform) {
    var keyword = myform.elements['keyword'].value
    if (keyword == '') {
        alert("No Keyword Specified")
        return false
    }
    if (! keyword.match(/^[\w\-\ ]+$/)) {
        alert("Invalid Value for Keyword")
        return false
    }
    return true
}
</script>
[% keywords = hub.keywords.keywords_for_current_page %]
<div style="font-family: Helvetica, Arial, sans-serif; overflow: hidden;"
     id="keywords">
<h3 style="font-size: small; text-align: center; letter-spacing: .25em; padding-bottom: .25em;">KEYWORDS</h3>
[% IF hub.pages.current.is_writable %]
<form name="keywords" method="POST" action=""
      onsubmit="return keyword_validate(this)">
[% FOREACH keyword = keywords %]
<div style="font-size: small; display:block; text-decoration: none; padding-bottom: .25em;">
<input
 type="checkbox"
 name="[% keyword %]"
 onclick="return keyword_delete(this);"
 checked
>&nbsp;<a
 href="[% script_name %]?action=keyword_display;keyword=[% keyword %]">[% keyword %]</a>
</div>
[% END %]
<input type="hidden" name="action" value="keyword_add" />
<input type="hidden" name="page_name" value="[% page_name %]" />
<input name="keyword" type="text" value="New Keywords" onclick="this.value = ''" size="12" />
</form>
[% ELSE %]
[% FOREACH keyword = keywords %]
<div style="font-size: small; display:block; text-decoration: none; padding-bottom: .25em;">
<a href="[% script_name %]?action=keyword_display;keyword=[% keyword %]">[% keyword %]</a>
 </div>
[% END %]
[% END %]
</div>
__template/tt2/keywords_related_widget.html__
<div style="font-family: Helvetica, Arial, sans-serif; overflow: hidden;"
     id="keywords_related">
<h3 style="font-size: small; text-align: center; letter-spacing: .25em; padding-bottom: .25em;">RELATED</h3>
[% keywords = hub.keywords.keywords_from_cgi %]
[% related_keywords = hub.keywords.get_related_keywords(keywords) %]
[% FOREACH keyword = related_keywords.sort %]
<div style="font-size: small; display:block; text-decoration: none; padding-bottom: .25em;">
<a href="[% script_name %]?action=keyword_display;keyword=[% keyword %]">[% keyword %]</a>
<a href="[% script_name %]?action=keyword_display;keyword=[%
keywords.merge([keyword]).join(" ") %]">(add)</a>
</div>
[% END %]
</div>
__template/tt2/keyword_list_button.html__
<a href="[% script_name %]?action=keyword_list">
[% INCLUDE keywords_button_icon.html %]
</a>
__template/tt2/keywords_button_icon.html__
Keywords
__config/keywords.yaml__
keywords_no_automatic: 0

