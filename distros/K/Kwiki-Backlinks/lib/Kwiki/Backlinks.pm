package Kwiki::Backlinks;
use Kwiki::Plugin '-Base';
use Kwiki::Installer '-base';

const class_id             => 'backlinks';
const class_title          => 'Backlinks';
const SEPARATOR            => '____';
const MAX_FILE_LENGTH      => 255;
const preference_query     =>
      'Show How Many Backlinks?';

const links_to_hook        => [qw(titlewiki wiki forced)];

field hooked => 0;

# This filesystem based style of data storage is based
# on one of the early implementation of Backlinks for MoinMoin

our $VERSION = '0.10';

# init is called on load class,
# which the installer does, so skip if in cgi
sub init {
    super;
    return unless $self->is_in_cgi;
    io($self->storage_directory)->mkdir;
    $self->assert_database;
}

sub storage_directory {
    $self->plugin_directory;
}

sub assert_database {
    return unless io->dir($self->storage_directory)->empty;
    for my $page ($self->hub->pages->all) {
        $self->update($page);
    }
}

sub register {
    my $registry = shift;
    $registry->add(widget => 'backlinks',
                   template => 'backlinks.html',
                   show_for => [ qw(display edit)],
                   show_if_preference => 'show_backlinks',
                  );
    $registry->add(hook => 'page:store', post => 'update_hook');
    $registry->add(preference => $self->show_backlinks);
    $registry->add(prerequisite => 'user_preferences');
}

sub show_backlinks {
    my $p = $self->new_preference('show_backlinks');
    $p->query($self->preference_query);
    $p->type('pulldown');
    my $choices = [
        0  => 0,
        5  => 5,
        10 => 10,
        25 => 25,
        50 => 50,
        100 => 100
    ];
    $p->choices($choices);
    $p->default(5);
    return $p;
}

sub delete_hook {
    my $page = $self->get_page;
    $self = $self->hub->backlinks;
    $self->clean_destination_links($page); # redundant but tidy
    $self->clean_source_links($page);
}

sub update_hook {
    my $page = $self;
    my $hook = pop;
    $self = $self->hub->backlinks;
    # save current as we need to manipulate within update and below
    my $current = $self->hub->pages->current;
    $self->update($page);
    $self->hub->pages->current($current);
}

sub update {
    my $page = shift;
    my $units;
    my $formatter = $self->hub->formatter;
    unless ($self->hooked) {
        $self->hooked(1);
        my $table = $formatter->table;
        for my $class (@$table{@{$self->links_to_hook}}) {
            $self->hub->add_hook(
                $class . '::unit_match', post => 'backlinks:add_match'
            );
        }
    }
    $self->hub->pages->current($page);
    $self->clean_source_links($page);
    $self->hub->formatter->text_to_parsed($page->content);
}

sub add_match {
    my $hook = pop;
    my $unit = $self;
    $self = $self->hub->backlinks;
    my $match = $unit->matched;
    return if $match =~ /^!/;
    ($match) = ($match =~ /(\w+)]?$/);
    $self->write_link($self->uri_escape($match));
}

sub clean_source_links {
    my $page = shift;
    my $source = $page->id;
    my $chunk = $source . $self->SEPARATOR . '*';
    $self->clean_links($chunk);
}

sub clean_destination_links {
    my $page = shift;
    my $destination = $page->id;
    my $chunk = '*' . $self->SEPARATOR . $destination;
    $self->clean_links($chunk);
}

sub clean_links {
    my $chunk = shift;
    my $dir = $self->storage_directory . '/';
    my $path = $dir . $chunk;
    unlink glob $path;
}

sub write_link {
    my $destination_id = shift;
    my $source_id = $self->hub->pages->current->id;
    $self->touch_index_file($source_id, $destination_id);
}

sub get_filename {
    my ($source, $dest) = @_;
    my $dir = $self->storage_directory;
    "$dir/$source" . $self->SEPARATOR . $dest;
}

sub touch_index_file {
    my ($source, $dest) = @_;
    # XXX hack to avoid overly long filenames. means for the time
    # being that really long page names just don't get backlinks
    if (length($source . $dest . $self->SEPARATOR) <=
        $self->MAX_FILE_LENGTH) {
        my $file = $self->get_filename($source, $dest);
        my $fileref = io($file);
        $fileref->touch->assert;
    }
}

sub all_backlinks {
    my $count = $self->preferences->show_backlinks->value;
    return [] unless $count;
    my $pages = $self->hub->pages;
    my @backlink_pages = grep {$_->exists} map {$pages->new_page($_)}
        $self->get_backlinks_for_page($self->hub->pages->current->id);
    $count = $count > scalar(@backlink_pages)
      ? scalar(@backlink_pages)
      : $count;
    @backlink_pages = 
        map {
            +{ page_uri => $_->uri, page_title => $_->title } 
        } sort {
            $b->modified_time <=> $a->modified_time
        } @backlink_pages;
    [@backlink_pages[0 .. $count -1]];
}

sub get_backlinks_for_page {
    my $page_id = shift;
    my $chunk = $self->SEPARATOR . $page_id;
    my $dir = $self->storage_directory . '/';
    my $path = $dir . "*$chunk";
    map { s/^$dir//; s/$chunk$//; $_} glob($path);
}


__DATA__

=head1 NAME

Kwiki::Backlinks - Maintain and display a simple database of links to the current page

=head1 DESCRIPTION

Kwiki::Backlinks uses the file system to keep track of which pages in 
a wiki link to which pages in the same wiki. That data is then used
to display on every page in the wiki. This is considered a nice
feature by some and an absolute requirement for enabling emergent 
understanding by others.

You can see Kwiki::Backlinks in action at L<http://www.burningchrome.com/wiki/>

This code also happens to demonstrate a novel use of Spoon hooks.

The backlinks database may also be used as a generic database of linking
activity in the wiki. L<Kwiki::Orphans> uses the database to reveal
pages which have no incoming links. The backlinks for any given page 
can be found the the following incantation:

    @backlinks = $self->hub->backlinks->get_backlinks_for_page($page->id);

This returns a list of page ids.

=head1 AUTHORS

Chris Dent, <cdent@burningchrome.com>
Brian Ingerson, <ingy@ttul.org>

=head1 CREDITS

Thanks to Ricardo SIGNES for the idea and patch for showing backlinks
on the edit page. Small price for very valuable gain.

=head1 SEE ALSO

L<Kwiki>
L<Spoon::Hooks>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, Chris Dent

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
__template/tt2/backlinks.html__
<!-- BEGIN backlinks -->
[% backlinks = hub.backlinks.all_backlinks %]
[% IF backlinks.size %]
<div style="font-family: Helvetica, Arial, sans-serif; overflow: hidden;"
     id="backlinks">
<h3 style="font-size: small; text-align: center; letter-spacing: .25em; padding-bottom: .25em;">BACKLINKS</h3>
[% FOREACH link = backlinks %]
<a style="font-size: small; display:block; text-align: center; text-decoration: none; padding-bottom: .25em;"
   href="[% script_name %]?[% link.page_uri %]">[% link.page_title %]</a>
[% END %]
</div> 
[% END %]
<!-- END backlinks -->
