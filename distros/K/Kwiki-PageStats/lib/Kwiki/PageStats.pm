package Kwiki::PageStats;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';

const class_id             => 'page_stats';
const class_title          => 'PageStats';
const lock_count           => 10;

field count => 0;
field 'mtime';

our $VERSION = '0.06';

sub storage_directory {
    $self->plugin_directory;
}

sub register {
    my $registry = shift;
    $registry->add(status => 'page_stats',
                   template => 'page_stats.html',
                   show_for => 'display',
                  );
    $registry->add(toolbar => 'Page Status',
                   template => 'page_stats_button.html',
                   show_for => 'display'
                  );
    $registry->add(action => 'page_stats_list');

    $registry->add(preference => $self->show_page_stats);
}

sub page_stats_list {
    my @pages;
    for my $page ($self->pages->all) {
        my $io_file = io->catfile($self->plugin_directory, $page->id);
        if ($io_file->exists) {
            $page->{hits} = $io_file->all;
            push @pages, $page;
        }
    }
    @pages = sort {$b->{hits} <=> $a->{hits}} @pages;

    $self->render_screen(pages => \@pages);
}

sub show_page_stats {
    my $p = $self->new_preference('show_page_stats');
    $p->query('Show hits in status bar?');
    $p->type('boolean');
     $p->default(1);
    return $p;
}

sub increment_page_count {
    my $file = io($self->data_file)->file;
    my $previous = 0;
    my $mtime;
    if ($file->exists) {
        $previous = $file->all;
        $mtime = $file->mtime;
    }
    $file->close;
    $previous++;
    $self->count($previous);
    $self->mtime($mtime) if $mtime;
}

sub write_page_count {
    my $file = io($self->data_file)->file;
    $file->print($self->count);
    $file->close;
}

sub touch_ctime {
    my $file = io($self->ctime_file);
    $file->touch unless $file->exists;
}

sub file_ctime {
    my $time = io($self->ctime_file)->file->ctime;
    return scalar gmtime($time);
}

sub page_stats {
    return unless $self->preferences->show_page_stats->value;
    eval {$self->lock;};
    return 'X' if $@;
    $self->increment_page_count;
    $self->write_page_count;
    $self->touch_ctime;
    $self->unlock;
    if ($self->hub->have_plugin('time_zone')) {
        return {
            count => $self->count,
            ctime => $self->hub->time_zone->format(
                io($self->ctime_file)->file->ctime),
            $self->mtime ?
                (mtime => $self->hub->time_zone->format($self->mtime)) : ()
        };
    } else {
        return {
            count => $self->count,
            ctime => $self->file_ctime,
            $self->mtime ? (mtime => scalar gmtime($self->mtime)) : ()
        };
    }
}

sub ctime_file {
    $self->data_file . '.time';
}

sub data_file {
    my $id = $self->hub->pages->current->id;
    $self->storage_directory . '/' . $id;
}

sub lock_directory {
    $self->data_file . '.lck';
}

# taken from PurpleWiki and Kwiki-Purple
sub lock {
    my $tries = 0;
    while (!mkdir($self->lock_directory, 0555)) {
        die "unable to create page counting lock directory"
          if ($! != 17);
        $tries++;
        die "timeout attempting to lock page count"
          if ($tries > $self->lock_count);
        sleep 1;
    }
}

sub unlock {
    rmdir($self->lock_directory) or
      die "unable to remove page count locking directory";
}

__DATA__

=head1 NAME

Kwiki::PageStats - Count and show page hits with a hook.

=head1 DESCRIPTION

Kwiki::PageStats shows a count of how many times a page has been 
viewed since the installation of the plugin and when the last hit 
on the page was made.

=head1 CREDITS

Henry Laxen provided a patch that uses the TimeZone plugin, if
present, to show the times relative to the current users time
zone. Henry has also provided an icon for the menu bar and some
grammar fixes in the output.

Gugod (Kang-min Liu) provided a patch to add a page_stats_list
action that reports on the number of hits for all pages. Which
is a nicely handy way to get an overview of how much action your
wiki is seeing.

=head1 AUTHORS

Chris Dent, <cdent@burningchrome.com>

=head1 SEE ALSO

L<Kwiki>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, Chris Dent

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
__template/tt2/page_stats_button.html__
<a href="[% script_name %]?action=page_stats_list" title="Page Stats">
[% INCLUDE page_stats_button_icon.html %]
</a>
__template/tt2/page_stats_button_icon.html__
<!-- BEGIN page_stats_button_icon.html -->
<img src="icons/gnome/image/page_stats.png" alt="Page Stats" />
<!-- END page_stats_button_icon.html -->
__template/tt2/page_stats_content.html__
<table class="page_stats">
[% FOR page = pages %]
<tr>
<td class="page_name">[% page.kwiki_link %]</td>
<td class="page_hits">[% page.hits %]</td>
</tr>
[% END %]
</table>
__template/tt2/page_stats.html__
<!-- BEGIN page_stats -->
[% page_info = hub.page_stats.page_stats %]
[% IF page_info.count %]
<div style="font-family:Helvetica,Arial,sans-serif; font-size:small;"
     id="page_stats">
[% page_info.count %] hit[% IF page_info.count > 1 %]s[% END %] since [% page_info.ctime %].
[% IF page_info.mtime %]
Last hit at [% page_info.mtime %]
[% END %]
</div>
[% END %]
<!-- END page_stats -->
__icons/gnome/image/page_stats.png__
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAQAAAC1QeVaAAAAAmJLR0QAAKqN
IzIAAAAJcEhZcwAAAEgAAABIAEbJaz4AAABTSURBVBjTfZBLDgAxCEKBzMU8
uUezm06q9uNK85AQiMBlnJ/TAnBWYAEA9LmesKo2m07Yv36spbMtmvLRsZbJ
blwCdYHu6GlroVOQVMKtHydfxQ/lrx+ZnZ8xEQAAAABJRU5ErkJggg==
