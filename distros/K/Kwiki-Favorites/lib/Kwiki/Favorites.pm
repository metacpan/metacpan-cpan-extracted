package Kwiki::Favorites;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';
our $VERSION = '0.13';

const class_id => 'favorites';
const css_file => 'favorites.css';

sub register {
    my $registry = shift;
    $registry->add(action => 'favorites');
    $registry->add(action => 'favorites_add');
    $registry->add(action => 'favorites_remove');
    $registry->add(toolbar => 'favorites_button', 
                   template => 'favorites_button.html',
                  );
    $registry->add(widget => 'favorites_query', 
                   template => 'favorites_query.html',
                   show_for => 'display',
                  );
}

sub favorites {
    my $favorites = 
      $self->hub->cookie->jar->{favorites} || {};
    my @pages = sort {
        $b->metadata->edit_unixtime <=> $a->metadata->edit_unixtime;
    } map {
        $self->pages->new_page($_);
    } keys %$favorites;
    $self->render_screen(pages => \@pages);
}

sub favorites_add {
    my $page_name = $self->pages->name_to_id($self->cgi->page_name);
    my $favorites = $self->hub->cookie->jar->{favorites} || {};
    $favorites->{$page_name} = 1;
    $self->hub->cookie->jar->{favorites} = $favorites;
    return "$page_name added";
}

sub favorites_remove {
    my $page_name = $self->pages->name_to_id($self->cgi->page_name);
    my $favorites = $self->hub->cookie->jar->{favorites} || {};
    delete $favorites->{$page_name};
    $self->hub->cookie->jar->{favorites} = $favorites;
    return "$page_name added";
}

__DATA__

=head1 NAME 

Kwiki::Favorites - Kwiki Favorites Plugin

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
__css/favorites.css__
table.favorites {
    width: 100%;
}

table.favorites td {
    white-space: nowrap;
    padding: .2em 1em .2em 1em;
}

table.favorites td.page_name   { 
    text-align: left;
}
table.favorites td.edit_by   { 
    text-align: center;
}
table.favorites td.edit_time { 
    text-align: right;
}
__template/tt2/favorites_button.html__
<a href="[% script_name %]?action=favorites" accesskey="f" title="Personal Favorites">
[% INCLUDE favorites_button_icon.html %]
</a>
__template/tt2/favorites_button_icon.html__
Favorites
__template/tt2/favorites_query.html__
<script type="text/javascript">
function favorites_change(self) {
    iframe = document.getElementsByTagName("iframe")[0];
    if (self.checked) {
        iframe.src = 
          '[% script_name %]?action=favorites_add&page_name=[% page_uri %]';
    }
    else {
        iframe.src = 
          '[% script_name %]?action=favorites_remove&page_name=[% page_uri %]';
    }
}
</script>
<form>
<input type="checkbox" name="favorite" onchange="favorites_change(this)" [% IF hub.cookie.jar.favorites.$page_name %]checked[% END %] />
Favorite?
<iframe height="0" width="0" frameborder="0"></iframe>
</form>
__template/tt2/favorites_content.html__
[% screen_title = "Personal Favorites" %]
[% IF not pages.size %]
<b>You have not selected any favorites.</b>
[% END %]
<table class="favorites">
[% FOR page = pages %]
<tr>
<td class="page_name">[% page.kwiki_link %]</td>
<td class="edit_by">[% page.edit_by_link %]</td>
<td class="edit_time">[% page.edit_time %]</td>
</tr>
[% END %]
</table>
