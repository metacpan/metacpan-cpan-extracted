package Kwiki::ListPages;

use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';

our $VERSION = '0.11';

const class_title => 'List Pages';
const class_id => 'list_pages';
const css_file => 'list_pages.css';

sub register
{
    my $registry = shift;
    $registry->add( action => 'list_pages' );
    $registry->add( toolbar => 'ListPages',
                    template => 'list_pages_button.html' );
}

sub list_pages
{
    my $pages  = {};
    my $all_pages = [];
    $pages->{$_} = [] foreach( 'A'..'Z', 0..9 );
    @$all_pages = sort $self->pages->all;
    foreach my $page (@$all_pages) {
        push(@{$pages->{ uc(substr($page->{id},0,1)) }}, $page);
    }
    $self->render_screen( pages => $pages );
}

__DATA__

=head1 NAME

Kwiki::ListPages - List all Kwiki Pages

=head1 SYNOPSIS

 1. Install Kwiki::ListPages
 2. kwiki -add Kwiki::ListPages

=head1 DESCRIPTION

This module provides an indexed list of all the pages in a Kwiki wiki via a button on the toolbar.  At the top of the list is a navigation bar with letters or numbers which have page entries associated with them.

=head1 AUTHOR

 Sue Spence <sue_cpan@pennine.com>
 Alexander Goller <alex@vivien.franken.de>

=head1 COPYRIGHT

Copyright (c) 2005 by Sue Spence & Alexander Goller. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__css/list_pages.css__
td.page_name {
   width: 25%
}
td.edit_by {
   width: 10%
}
td.edit_time {
   width: 55%
}
__template/tt2/list_pages_button.html__
<a href="[% script_name %]?action=list_pages" title="List Pages">
[% INCLUDE list_pages_button_icon.html %]
</a>
__template/tt2/list_pages_button_icon.html__
List Pages
__icons/gnome/template/list_pages_button_icon.html__
<img src="icons/gnome/image/list_pages.png" alt="List Pages" />
__template/tt2/list_pages_content.html__
[% BLOCK nav_block %]
<center>
[% FOREACH letter IN pages %]
   [% IF letter.value.size > 0 %]
    <big><a href="#[% letter.key %]">[% letter.key %]</a></big>
   [% END %]
[% END %]
[% END %]
</center>
[% PROCESS nav_block %]
<table class="list_pages">
[% FOREACH letter IN pages %]
 [% IF letter.value.size > 0 %]
 <tr>
 <td class="header" colspan="3"><a name="[%letter.key%]">[% letter.key %]</a></td>
 </tr>
   [% FOREACH page = letter.value %]
       <tr>
       <td class="page_name">[% page.kwiki_link %]</td>
       <td class="edit_by">[% page.edit_by_link %]</td>
       <td class="edit_time">[% page.edit_time %]</td>
       </tr>
   [% END %]
   <tr><td>&nbsp;</tr>
 [% END %]
[% END %]
</table>
<p>
[% PROCESS nav_block %]
__icons/gnome/image/list_pages.png__
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QA/wD/AP+gvaeTAAAA
CXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1QMNDSkFBxl9BgAAAh5JREFUeNqVk89rE0EU
xz+TpJmabSAYY5JSK2htqVBB8AeGJIqCeFBQtPpX5NB/QBDv/gF7VQjY2hbsxUs9eGgOCvbg
IZfkoPmlSXYTCZuwk6yHmjVlc/Fdhnkz7/O+b94bwZHdABb4P/sBHAT+bjby+fy6UurYDSHE
1EjDMMjlcpuTADKZDKVSCQCfz+euk5Cxv1gsuj4X0Ol0KBaLCCGmAib940QAY/xbwzDWTdP0
yJ5WRqVSIZVKbQJPXQWDwYBms4kQwg1qNpvsvd/l8ZNnhEIhpJQAVKtVbwndbpdareZmVUrx
aX+fdDqLrutks1mSySRSSlqtlhcQi8WO1WtZFt8ODxnZfTRNIx6Ps7S0hKZprhKPgnq97j5e
uVymVqtyK32Frmmg6zqaFmJt7RKLi2e8ACkl0WgUx3EA2Nra4mY6xclImJcvnrOzs4vfJzj4
/BXDMP61dhIQDAaRUtLv9xkqm+UL58BR9Hsm165e5uLqMnOzQUYTA+cqaLfbbn87nQ4jpZiP
RQj6BUINWIiFsZWGGvSwrJAXkEwmiUQiOI6DaZpsh+fY+/CR1fPz4Dj4haDW+EW1/pNH6dte
gFKKXq935AwEuHP3Hvk3r6l8P8sJOUPA78eyh3R/W5xOJLwAXddpNBrugW3bLK+s0KhUGSqF
CPg4FY8TTcQpFAqeUZ72nX1+2Hj44P51EChnyIyc5d3O9hdnxCugDBz8AX7Y0vgtAxN8AAAA
AElFTkSuQmCC

