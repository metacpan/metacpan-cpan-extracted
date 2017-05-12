package FileCache::Appender;
use strict;
use warnings;
our $VERSION = "0.03";
$VERSION = eval $VERSION;

use Carp;
use Path::Tiny;

=head1 NAME

FileCache::Appender - cache file handles opened for appending

=head1 VERSION

This document describes FileCache::Appender version 0.03

=head1 SYNOPSIS

    use FileCache::Appender;
    # returns cached file handle, or opens file for appending
    my $fh = FileCache::Appender->file($path);

=head1 DESCRIPTION

Caches file handles opened for appending. Helps to reduce number of I/O operations if you are appending data to many files.

=head1 METHODS

=cut

my $global;

=head2 $class->new(%args)

Creates a new object. The following parameters are allowed:

=over 4

=item B<max_open>

maximum number of file handles to cache. If cache reaches this size, each time
you requesting a new file handle, one of the existing will be removed from the
cache.

=item B<mkpath>

if directory in which file should be opened doesn't exist, create it

=back

=cut

sub new {
    my ( $class, %args ) = @_;
    $args{_fd_cache}   = {};
    $args{_open_count} = 0;
    $args{max_open} ||= 512;
    return bless \%args, $class;
}

=head2 $self->file($path)

returns file handle for the file specified by I<$path>. If file handle for the
file is not in the cache, will open file for appending and cache file handle.

=cut

sub file {
    my ( $self, $path ) = @_;
    $path = path($path)->absolute;
    unless ( ref $self ) {
        $self = $global ||= $self->new;
    }
    my $cache = $self->{_fd_cache};
    unless ( $cache->{$path} ) {
        if ( $self->{_open_count} == $self->{max_open} ) {
            delete $cache->{ ( keys %$cache )[ rand $self->{_open_count}-- ] };
        }
        if ( $self->{mkpath} ) {
            my $dir = path( $path->dirname );
            $dir->exists or $dir->mkpath;
        }
        open my $fd, ">>", $path or croak "Couldn't open $path: $!";
        $self->{_open_count}++;
        $cache->{$path} = $fd;
    }
    return $cache->{$path};
}

=head2 $self->clear

clear the cache

=cut

sub clear {
    my $self = shift;
    $self->{_fd_cache}   = {};
    $self->{_open_count} = 0;
    return;
}

1;

__END__

=head1 CAVEATS

If you need to append data to a big number of files, perhaps you should use a
database.

Module does not perform any checks if file handle is still actual. If you
closed file handle that you have got from cache, you still may get this handle
next time you call I<file>. If file was renamed, you still may get the handle
pointing to it when requesting file using the old name.

=head1 BUGS

Please report any bugs or feature requests via GitHub bug tracker at
L<http://github.com/trinitum/perl-FileCache-Appender/issues>.

=head1 AUTHOR

Pavel Shaydo C<< <zwon at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 Pavel Shaydo

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
