package File::LogReader;
use strict;
use warnings;
use Digest::SHA1 qw/sha1_hex/;
use YAML qw/DumpFile LoadFile/;
use Fcntl ':flock';

=head1 NAME

File::LogReader - tail log files with state between runs

=cut

=head1 SYNOPSIS

Tail log files across multiple runs over time.

    use File::LogReader;

    my $lr = File::LogReader->new( filename => $filename );
    while( my $line = $lr->read_line ) {
        # do stuff with $line
    }
    $lr->commit;

=head1 DESCRIPTION

This module makes it easy to periodically check a file for new content
and act on it.  For instance, you may want to parse a log file whenever
it is updated.

=cut

our $VERSION = '0.04';

=head2 METHODS

=head3 new

Create a new object.  Options:

=over 4

=item filename

The name of the file to read from

=item state_dir

A directory to store state files.  Defaults to ~/.logreader

=back

=cut

sub new {
    my $class = shift;
    my $self = {
        state_dir => "$ENV{HOME}/.logreader",
        @_,
    };

    die 'filename is mandatory!' unless $self->{filename};
    die 'file must exist!' unless -e $self->{filename};

    unless( -d $self->{state_dir} ) {
        mkdir $self->{state_dir} 
            or die "Can't make the state directory: $self->{state_dir}: $!";
    }

    (my $pathless = $self->{filename}) =~ s#.+/##;
    $self->{state_file} = "$self->{state_dir}/$pathless.state";

    bless $self, $class;
    $self->_set_file_position;

    return undef unless $self->_obtain_lock;
    return $self;
}

=head3 read_line

Return a single line of input from the file, or undef;

=cut

sub read_line {
    my $self = shift;

    my $fh = $self->_fh;
    return <$fh>;
}

=head2 commit

Saves the read position of the current file.

=cut

sub commit {
    my $self = shift;
    my $fh = $self->_fh;
    die "Nothing to commit!" unless $fh;

    my $pos = tell($fh);
    DumpFile( $self->{state_file}, 
        { 
            pos => $pos, 
            hash => $self->_calc_hash($pos),
        },
    );
    $self->_release_lock;
}

sub _set_file_position {
    my $self = shift;

    return unless -f $self->{state_file};
    my $state = LoadFile($self->{state_file});

    my $fh = $self->_fh;
    seek $fh, $state->{pos}, 1;
    my $pos = tell($fh);

    if ($pos < $state->{pos}) {
        # warn "File is smaller! - seeking to beginning of file";
        seek $fh, 0, 0;
        return;
    }

    my $current_hash = $self->_calc_hash($state->{pos});
    if ($current_hash ne $state->{hash}) {
        # warn "hash doesn't match!  seeking to beginning of file";
        seek $fh, 0, 0;
        return;
    }

    # warn "hash matches - staying put";
}

sub _calc_hash {
    my $self = shift;
    my $from_pos = shift;

    my $MAX_BYTES = 1024;

    my $fh = $self->_fh;

    # Compute a hash from the specified byte range
    my $num_bytes = $from_pos < $MAX_BYTES ? $from_pos : $MAX_BYTES;
    seek $fh, $from_pos - $num_bytes, 0;
    
    my $content;
    my $rc = read $fh, $content, $num_bytes;
    unless (defined $rc) {
        die "Couldn't read $num_bytes bytes from $self->{filename}: $!";
    }
    return sha1_hex($content),
}

sub _fh {
    my $self = shift;
    if (!exists $self->{fh}) {
        open($self->{fh}, $self->{filename}) 
            or die "Can't open $self->{filename}: $!";
    }
    return $self->{fh};
}

sub _release_lock {
    my $self = shift;
    undef $self->{_lock_fh};
}

sub _obtain_lock {
    my $self = shift;
    my $lock_file = "$self->{state_file}.lock";

    open(my $lock_fh, ">$lock_file") or die "Can't open $lock_file: $!";
    $self->{_lock_fh} = $lock_fh;
    return flock($lock_fh, LOCK_EX | LOCK_NB);
}

=head1 AUTHOR

Luke Closs, C<< <file-logreader at 5thplane.com> >>

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-LogReader>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::LogReader

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-LogReader>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-LogReader>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-LogReader>

=item * Search CPAN

L<http://search.cpan.org/dist/File-LogReader>

=back

=head1 OTHER CONTRIBUTORS

Thanks to Matthew O'Connor for pairing on the locking.

=head1 COPYRIGHT & LICENSE

Copyright 2007,2008 Luke Closs, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
