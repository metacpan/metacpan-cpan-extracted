package Kwiki::Archive;
use Kwiki::Plugin -Base;

const class_id => 'archive';
const class_title => 'Page Archive';
const show_revisions => 1;

sub register {
    my $registry = shift;
    $registry->add(hook => 'page:store', post => 'commit_hook');
}

sub init {
    if ($self->empty) {
        $self->generate;
        $self->commit_all;
    };
}

sub empty {
    my $dir = io($self->plugin_directory);
    $dir->exists and $dir->empty;
}

sub generate {
    my $dir = $self->plugin_directory;
    umask 0000;
    chmod 0777, $dir;
}

sub commit_hook {
    my $hook = pop;
    return unless $hook->returned_true;
    my $page = $self;
    $self = $page->hub->archive;
    $self->commit($page);
}

sub commit_all {
    for my $page ($self->pages->all) {
        $self->commit($page);
    }
}

sub page_properties {
    my $page = shift;
    my $properties = $page->metadata->to_hash;
    $properties->{edit_by} ||= '';
    $properties->{edit_time} ||= scalar(gmtime);
    $properties->{edit_unixtime} ||= scalar(time);
    return $properties;
}

sub revision_number {
    $self->history(shift)->[0]->{revision_id} || 0;    
}

sub revision_numbers {
    my $page = shift;
    [map $_->{revision_id}, @{$self->history($page)}];
}

__DATA__

=head1 NAME 

Kwiki::Archive - Kwiki Page Archive Plugin Base Class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
