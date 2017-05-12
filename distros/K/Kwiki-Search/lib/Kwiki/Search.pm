package Kwiki::Search;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';
use Kwiki ':char_classes';
our $VERSION = '0.12';

const class_id => 'search';
const cgi_class => 'Kwiki::Search::CGI';
const css_file => 'search.css';

sub register {
    my $registry = shift;
    $registry->add(action => 'search');
    $registry->add(toolbar => 'search_box', 
                   template => 'search_box.html',
                  );
}

sub search {
    my $pages = $self->perform_search;
    my $term = $self->cgi->search_term;
    my $num = @$pages;
    my $screen_title = length($term)
    ? "$num Pages Matching '$term'"
    : "All $num Pages";
    $self->render_screen(
        screen_title => $screen_title,
        pages => $pages,
    );
}

sub perform_search {
    my $search = $self->cgi->search_term;
    $search =~ s/[^$WORD\ \-\.\^\$\*\|\:]//g;
    [ 
        grep {
            ($_->id =~ m{$search}i ||
             $_->content =~ m{$search}i
            ) and $_->active
        } $self->pages->all 
    ]
}

package Kwiki::Search::CGI;
use Kwiki::CGI -base;

cgi search_term => -utf8;

package Kwiki::Search;
__DATA__

=head1 NAME 

Kwiki::Search - Kwiki Search Plugin

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__template/tt2/search_box.html__
<form method="post" action="[% script_name %]" enctype="application/x-www-form-urlencoded" style="display: inline">
<input type="text" name="search_term" size="8" value="Search" onfocus="this.value=''" />
<input type="hidden" name="action" value="search" />
</form>
__template/tt2/search_content.html__
<table class="search">
[% FOR page = pages %]
<tr>
<td class="page_name">[% page.kwiki_link %]</td>
<td class="edit_by">[% page.edit_by_link %]</td>
<td class="edit_time">[% page.edit_time %]</td>
</tr>
[% END %]
</table>
__css/search.css__
table.search {
    width: 100%;
}

table.search td {
    white-space: nowrap;
    padding: .2em 1em .2em 1em;
}

table.search td.page_name   { 
    text-align: left;
}
table.search td.edit_by   { 
    text-align: center;
}
table.search td.edit_time { 
    text-align: right;
}

