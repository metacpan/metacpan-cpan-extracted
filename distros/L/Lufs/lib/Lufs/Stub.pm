package Lufs::Stub;

sub init {
    my $self = shift;
    my $arg = shift;

    return 1;
}

sub AUTOLOAD {
    my $self = shift;
    my $method = (split/::/,$AUTOLOAD)[-1];
    $method eq 'DESTROY' && return;
    $self->TRACE("$method not implemented: $_[0]");
    0;
}

#####################################
############# lufs calls ############
#####################################

sub mount {
    my $self = shift;
    return 1;
}

sub umount { 
    my $self = shift;
    return 1;
}

sub stat {
    my $self = shift;
    my $file = shift;
    $file =~ s{/\.$}{/};
    my $ref = shift;
    if ($file eq '/') {
        $ref->{f_ino} = 1;
        $ref->{f_mode} = 0040000 | 0755;
        $ref->{f_nlink} = 1;
        $ref->{f_uid} = 0;
        $ref->{f_gid} = 0;
        $ref->{f_size} = 2048;
        $ref->{f_atime} = time;
        $ref->{f_mtime} = time;
        $ref->{f_ctime} = time;
        $ref->{f_blksize} = 512;
        $ref->{f_blocks} = 4;
        return 1;
    }
    elsif ($file =~ /(hello|world)/) {
        $ref->{f_ino} = $file eq 'hello'?2:3;
        $ref->{f_mode} = 0100000 | 0666;
        $ref->{f_nlink} = 1;
        $ref->{f_uid} = 1;
        $ref->{f_gid} = 1;
        $ref->{f_size} = 4096;
        $ref->{f_atime} = time;
        $ref->{f_mtime} = time;
        $ref->{f_ctime} = time;
        $ref->{f_blksize} = 512;
        $ref->{f_blocks} = 8;
        return 1;
    }
    return 0;
}

sub readdir {
    my $self = shift;
    my $dir = shift;
    my $ref = shift;
    if ($dir eq '/') {
        push @{$ref}, qw/hello world/;
    }
}

sub mkdir {
    my $self = shift;
    my $dir = shift;
    my $mode = shift;
    return -1;
}

sub open {
    my $self = shift;
    my ($file,$mode) = @_;
    if ($file =~ /(?:hello|world)/) {
        return 1;
    }
    return 0;
}

sub read {
    my $self = shift;
    my $file = shift;
    my $offset = shift;
    my $count = shift;
    unless ($file =~ /(hello|world)/) { return 0 }
    if ($offset > 4096) { return 0 }
    $_[0] = "$1 "x($count/6);
    return $count;
}

sub release {
    my $self = shift;
    my ($file) = shift;
    return 1;
}

sub write {
    my $self = shift;
    my ($file, $offset, $count, $buf) = @_;
    return length($buf);
}

1;
__END__

=head1 NAME

Lufs::Stub - A hello-world filesystem for use with perlufs

=head1 DESCRIPTION

This is an example, demonstrating the API.
Unless stated otherwise, methods are expected to return 1 for succes, and 0 for failure.

=head1 METHODS

=head2 init (CONFIG)
 
CONFIG is a hashref with configuration data, from both lufsd.conf and the -o switch.

=head2 mount

This gets called whenever the filesystem is mounted.

=head2 umount

This gets called whenever the filesystem is umounted.

=head2 stat (FILE, STAT)

STAT is a hash reference. you should fill in the approriate values.

=head2 readdir (DIR, LIST)

LIST is an array ref that you should fill. You do not need to push `.' and `..', this will be done for you.

=head2 mkdir (DIR, MODE)

MODE is the access mode for the dir that you are creating

=head2 open (FILE, MODE)

=head2 release (FILE)

=head2 read (FILE, OFFSET, COUNT, BUF)

Assign the data to the last argument, return the number of bytes read.

=head2 write (FILE, OFFSET, COUNT, BUF)
	
Return the number of bytes written.

=head2 readlink (FILE)

This should return a string: the filename that the link points at.

=head1 AUTHOR

Raoul Zwart, E<lt>rlzwart@cpan.orgE<gt>

=head1 SEE ALSO

L<Lufs::Howto>, L<Lufs>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Raoul Zwart

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
