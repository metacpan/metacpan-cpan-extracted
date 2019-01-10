package File::ChangeNotify::Watcher::Default;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.31';

use Time::HiRes qw( sleep );

use Moo;

with 'File::ChangeNotify::Watcher';

sub sees_all_events {0}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _always_requires_mtime {1}
## use critic

sub BUILD {
    my $self = shift;

    $self->_set_map( $self->_current_map );

    return;
}

sub wait_for_events {
    my $self = shift;

    while (1) {
        my @events = $self->_interesting_events;
        return @events if @events;

        sleep $self->sleep_interval;
    }
}

sub _interesting_events {
    my $self = shift;

    my @interesting;

    my $old_map = $self->_map;
    my $new_map = $self->_current_map;

    for my $path ( sort keys %{$old_map} ) {
        if ( !exists $new_map->{$path} ) {
            if ( $old_map->{$path}{is_dir} ) {
                $self->_remove_directory($path);
            }

            push @interesting, $self->event_class->new(
                path => $path,
                type => 'delete',
            );
        }
        else {
            # If we're tracking stat info changes then we get the old & new
            # stat info back in @extra. No need to stat the path _again_.
            my ( $modified, @extra )
                = $self->_path_was_modified( $path, $old_map, $new_map );
            if ($modified) {
                push @interesting, $self->event_class->new(
                    path => $path,
                    type => 'modify',
                    @extra,
                    $self->_modify_event_maybe_content_changes(
                        $path, $old_map, $new_map
                    ),
                );
            }
        }
    }

    for my $path ( sort grep { !exists $old_map->{$_} } keys %{$new_map} ) {
        push @interesting, $self->event_class->new(
            path => $path,
            type => 'create',
        );
    }

    $self->_set_map($new_map);

    return @interesting;
}

sub _path_was_modified {
    my $self    = shift;
    my $path    = shift;
    my $old_map = shift;
    my $new_map = shift;

    my $old_entry = $old_map->{$path};
    my $new_entry = $new_map->{$path};

    # If it's a file and the mtime or size changed we know it's been modified
    # in some way.
    return 1
        if !$old_entry->{is_dir}
        && ( $old_entry->{stat}{mtime} != $new_entry->{stat}{mtime}
        || $old_entry->{size} != $new_entry->{size} );

    if (
        my @attrs = $self->_modify_event_maybe_file_attribute_changes(
            $path, $old_map, $new_map
        )
    ) {

        return ( 1, @attrs );
    }

    return 0;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Fallback default watcher subclass

__END__

=pod

=encoding UTF-8

=head1 NAME

File::ChangeNotify::Watcher::Default - Fallback default watcher subclass

=head1 VERSION

version 0.31

=head1 DESCRIPTION

This class implements watching by comparing two snapshots of the filesystem
tree. It if inefficient and dumb, and so it is the subclass of last resort.

Its C<< $watcher->wait_for_events >> method sleeps between
comparisons of the filesystem snapshot it takes.

=head1 SUPPORT

Bugs may be submitted at L<http://rt.cpan.org/Public/Dist/Display.html?Name=File-ChangeNotify> or via email to L<bug-file-changenotify@rt.cpan.org|mailto:bug-file-changenotify@rt.cpan.org>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for File-ChangeNotify can be found at L<https://github.com/houseabsolute/File-ChangeNotify>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 - 2019 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
