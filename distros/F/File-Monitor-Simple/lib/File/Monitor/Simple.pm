package File::Monitor::Simple;

use strict;
use warnings;
use base 'Class::Accessor::Fast';
use File::Find::Rule;
use File::Modified;
use File::Spec;

use vars '$VERSION';

$VERSION = '1.00';

__PACKAGE__->mk_accessors(
    qw/directory
      modified
      regex
      watch_list
      /
);

# directory   : scalar location to monitor
# modified    : File::Modified object with current state
# regex       : File pattern to monitor. Really a string a not "qr"
# watch_list  : hashref of monitored files. Keys are names. Values are "1"


sub new {
    my ( $class, %args ) = @_;

    my $self = {%args};

    bless $self, $class;

    $self->_init;

    return $self;
}

sub _init {
    my $self = shift;

    my $watch_list = $self->_index_directory;
    $self->watch_list($watch_list);

    $self->modified(
        File::Modified->new(
            # mtime works on directories, while 'MD5' doesn't
            method => 'mtime',
            files  => [ keys %{$watch_list} ],
        )
    );
}

sub watch {
    my $self = shift;

    my @changes;
    my @changed_files;
    
    eval { @changes = $self->modified->changed };
    if ($@) {
        # warn "error: $@";
        # File::Modified will die if a file is deleted.
        my ($deleted_file) = $@ =~ /stat '(.+)'/;
        push @changed_files, $deleted_file || 'unknown file';

        # re-scan to remove the deleted file
        $self->_init;
    }

    if (@changes) {
        # update all mtime information
        $self->modified->update;

        # check if any files were changed
        @changed_files = grep { defined $_ && -f $_ } @changes;

        # Check if only directories were changed.  This means
        # a new file was created.
        if (@changed_files) {
            # We found some changed files. 
            # Don't bother to look for added files, too. 
        }
        else {

            # look through the new list for new files
            my $old_watch = $self->watch_list;

            # re-index to find new files
            $self->_init;

            @changed_files = grep { !defined $old_watch->{$_} } keys %{ $self->watch_list };

            return unless @changed_files;
        }
    }
    else {
        # no changes found;
    }

    return @changed_files;

}

# =begin private
# 
# =head2 _index_directory()
# 
#  $self->_index_directory;
# 
# Looks in $self->directory and compares all files to $self->regex.
# Matched files are registered for monitoring. 
# 
# =end private
# 
# =cut 

sub _index_directory {
    my $self = shift;

    my $dir   = $self->directory || die "No directory specified";
    my $regex = $self->regex     || '\.pm$';

    # Find all the directories in this directory, as well as any files matching the regex
    my $iterator = File::Find::Rule->any(
        File::Find::Rule->file->name(qr/$regex/),
        File::Find::Rule->directory,
    )->start( $dir );

    my %list;
    while ( my $match = $iterator->match ) {
        $list{$match} = 1
    } 

    return \%list;
}

1;
__END__

=head1 NAME

File::Monitor::Simple - Watch for changed application files

=head1 SYNOPSIS

    my $watcher = File::Monitor::Simple->new(
        directory => '/path/to/MyApp',
        regex     => '\.yml$|\.yaml$|\.pm$',
    );
    
    while (sleep 1) {
        my @changed_files = $watcher->watch;
    }

=head1 DESCRIPTION

This class monitors a directory of files for changes made to any file
matching a regular expression.  It correctly handles new files added to the
application as well as files that are deleted.

=head1 METHODS

=head2 new ( directory => $path [, regex => $regex, delay => $delay ] )

Creates a new Watcher object.

=head2 watch

Returns a list of files that have been added, deleted, or changed since the
last time watch was called.

=head1 SEE ALSO

L<Catalyst>, L<HTTP::Server::Restarter>, L<File::Modified>, L<File::Monitor>

=head1 AUTHORS

Sebastian Riedel, <sri@cpan.org>

Andy Grundman, <andy@hybridized.org>

Mark Stosberg, <mark@summersault.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
