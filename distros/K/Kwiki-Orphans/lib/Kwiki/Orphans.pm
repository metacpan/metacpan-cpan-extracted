package Kwiki::Orphans;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';

const class_id       => 'orphans';
const class_title    => 'Orphans';

our $VERSION = '0.11';

sub register {
    my $registry = shift;
    $registry->add(prerequisite => 'backlinks');
    $registry->add(toolbar => 'orphans',
                   template => 'orphans_list_button.html',
               );
    $registry->add(toolbar => 'incipients',
                   template => 'incipients_list_button.html',
               );
    $registry->add(action => 'orphans_list');
    $registry->add(action => 'incipients_list');
}

sub orphans_list {
    my $pages = $self->get_orphaned_pages;

    return $self->template_process($self->screen_template,
        content_pane => 'orphans_content.html',
        screen_title => 'All Orphans',
        pages => $pages,
    );
}

sub incipients_list {
    my $incipients = $self->get_incipient_pages;

    foreach my $page (@$incipients) {
        $page->{parents} =
          [map {$self->hub->pages->new_from_name($_)}
           $self->hub->backlinks->get_backlinks_for_page($page->id)];
    }

    return $self->template_process($self->screen_template,
        content_pane => 'incipients_content.html',
        screen_title => 'All Incipients',
        pages => $incipients,
    );
}

sub get_orphaned_pages {
    my @pages = $self->hub->pages->all;

    my $orphans = [];
    foreach my $page (@pages) {
        my @backlinks =
            $self->hub->backlinks->get_backlinks_for_page($page->id);
        push(@$orphans, $page) unless scalar(@backlinks);
    } 
    return $orphans;
}

sub get_incipient_pages {
    my @pages = $self->read_leftside_backlinks_database;

    my $incipients = [];
    foreach my $id (@pages) {
        my $page = $self->hub->pages->new_from_name($id);
        push(@$incipients, $page) unless $page->exists;
    }

    return $incipients;
}

sub read_leftside_backlinks_database {
    my $dir = $self->hub->backlinks->storage_directory;
    my $separator = $self->hub->backlinks->SEPARATOR;
    my %pages = map {
        s/^$dir//;
        s/^\/.*?$separator//;
        $_ => 1;
    } glob($dir . '/*');
    return keys(%pages);
}

__DATA__

=head1 NAME

Kwiki::Orphans - Discovered Orphaned Kwiki Pages

=head1 SYNOPSIS

=head1 DESCRIPTION

An orphan is a page in a wiki that has no backlinks. This means it's not 
part of the network of information that makes up a wiki. This is sad.

Kwiki::Orphans provides two ways to reduce sadness in your wiki. You can
get a list of all pages that have no backlnks. You can also get a list
of all wiki links that do not yet exist. This is done using the
Kwiki::Backlinks database.

I use this from an admin view (otherwise the toolbar starts getting a bit
noisy) to garden the wiki.

=head1 AUTHOR

Chris Dent

=head1 COPYRIGHT

Copyright (c) 2005. Chris Dent. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__template/tt2/orphans_content.html__
<table class="orphans">
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
__template/tt2/incipients_content.html__
<table class="orphans">
[% FOR page = pages %]
<tr>
<td class="page_name">
[% page.kwiki_link %]
</td>
<td>
[% FOR parent = page.parents %]
[% parent.kwiki_link %]
[% END %]
</td>
</tr>
[% END %]
</table>
__template/tt2/orphans_list_button.html__
<a href="[% script_name %]?action=orphans_list">
[% INCLUDE orphans_button_icon.html %]
</a>
__template/tt2/orphans_button_icon.html__
Orphans
__template/tt2/incipients_list_button.html__
<a href="[% script_name %]?action=incipients_list">
[% INCLUDE incipients_button_icon.html %]
</a>
__template/tt2/incipients_button_icon.html__
Incipients
