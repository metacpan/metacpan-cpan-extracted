#
# Fuse::Filesys::Virtual::HandleCache
#
#

package Fuse::Filesys::Virtual::HandleCache;

use warnings;
use strict;

=head1 NAME

Fuse::Filesys::Virtual::HandleCache - R/W handle cache manager

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

In Fuse::Filesys::Virtual, read and write handle is cached for
performance reason.

=head1 EXPORT

Nothing.

=cut

use POSIX qw(:errno_h :fcntl_h);


=head1 FUNCTIONS

=head2 new

constractor

=cut

sub new {
    my $class = shift;
    my ($filesys) = shift;

    bless {
	_filesys => $filesys,
	_read => {},
	_write => {},
    }, $class;
}

=head2 is_busy

returns file or directory is used or not.

=cut

sub is_busy {
    my $self = shift;
    my ($fname) = @_;

    return 1 if ($self->{_read}->{$fname});
    return 1 if ($self->{_write}->{$fname});

    # directory is busy?
    for (keys %{$self->{_read}}, keys %{$self->{_write}}) {
	return 1 if (/^\Q$fname\E\//);
    }

    return undef;
}

sub _file_exist {
    my $self = shift;
    my ($fname) = @_;

    # by stat
    my $ret;
    eval {
	$ret = $self->{_filesys}->stat($fname);
    };
    return $ret unless ($@ =~ /Unimplemented/);

    eval {
	$ret = $self->{_filesys}->test('f', $fname);
    };
    return $ret unless ($@ =~ /Unimplemented/);

    die "cannot determine file status";
}

sub _read_open {
    my $self = shift;
    my ($fname) = @_;

    # already opened?
    return $self->{_read}->{$fname} if ($self->{_read}->{$fname});

    my $fh = $self->{_filesys}->open_read($fname);

    unless ($fh) {
	my $eno = $! + 0;
	if ($self->_file_exist($fname)) {
	    $! = $eno || EPERM;
	    die "cannot open file for reading: $!";
	}
	else {
	    $! = ENOENT;
	    die "file not found";
	}
    }

    return $self->{_read}->{$fname} = { fh => $fh, pos => 0 };
}

sub _read_seek {
    my $self = shift;
    my ($fname, $offset) = @_;

    my $c = $self->_read_open($fname);
    return $c if ($c->{pos} == $offset);

    my $ret = eval {
	if ($self->{_filesys}->seek($c->{fh}, $offset, 0)) {
	    $c->{pos} = $offset;
	    return $c;
	}
	die "seek error";
    };
    if ($@) {
	die $@ unless ($@ =~ /Unimplemented/);
    }
    return $ret if ($ret);

    # change current position by reading...
    $self->read_release($fname);
    $c = $self->_read_open($fname);

    my $pos = $c->{pos};
    my $buf;
    my $buflen = 4096;

    while($pos != $offset) {
	my $rlen = ($offset - $pos);
	$rlen = $buflen if ($rlen > $buflen);

	my $n = read($c->{fh}, $buf, $rlen);
	if (!defined($n) || $n < $rlen) {
	    $! = EINVAL if ($! == 0);
	    die "too large offset";
	}
	$pos += $n;
    }

    $c->{pos} = $pos;

    return $c;
}

=head2 read (FNAME, SIZE, OFFSET)

read data from cached file handle.

=cut

sub read {
    my $self = shift;
    my ($fname, $size, $offset) = @_;

    my $c = $self->_read_seek($fname, $offset);
    my $buf;
    my $n = $c->{fh}->read($buf, $size);
    $c->{pos} += $n;
    $c->{pos} ++ if ($n > 0);

    my $len = length($buf);

    return $buf;
}

sub _write_open {
    my $self = shift;
    my ($fname, $append) = @_;

    $self->read_release($fname);
    $self->write_release($fname);

    my $fh = $self->{_filesys}->open_write($fname, $append);
    unless ($fh) {
	$! = EPERM if ($! == 0);
	die "cannot open file for writing: $!";
    }

    if ($append) {
	my $size = $self->{_filesys}->size($fname) || 0;
	$self->{_write}->{$fname} = { fh => $fh, pos => $size };
    }
    else {
	$self->{_write}->{$fname} = { fh => $fh, pos => 0 };
    }

    return $self->{_write}->{$fname};
}

sub _write_seek {
    my $self = shift;
    my ($fname, $offset) = @_;

    my $c = $self->{_write}->{$fname};
    return $c if ($c && $c->{pos} == $offset);

    # if NOT append mode open, already truncated.
    $c = $self->_write_open($fname, 1);
    return $c if ($c && $c->{pos} == $offset);

    eval {
	if ($self->{_filesys}->seek($c->{fh}, $offset, 0)) {
	    $c->{pos} = $offset;
	    return $c;
	}
	else {
	    die "seek error";
	}
    };
    if ($@) {
	$! = EINVAL if ($! == 0);
	die $@;
    }

    return $c unless ($@);
}

=head2 write (FNAME, BUFF, OFFSET)

write data to cached file handle.

=cut

sub write {
    my $self = shift;
    my ($fname, $buf, $offset) = @_;

    my $c = $self->_write_seek($fname, $offset);
    my $fh = $c->{fh};

    print $fh $buf or return 0;
    $c->{pos} += length($buf);
    $c->{pos} ++ if (length($buf) > 0);

    return length($buf);
}

=head2 truncate (FNAME)

truncate a file.

=cut

sub truncate {
    my $self = shift;
    my ($fname) = @_;

    $self->read_release($fname);
    $self->write_release($fname);

    my $c = $self->_write_open($fname, undef);
}

=head2 read_release

release file handle for read

=cut

sub read_release {
    my $self = shift;
    my ($fname) = @_;

    if ($self->{_read}->{$fname}) {
	$self->{_filesys}->close_read($self->{_read}->{$fname}->{fh});
	delete $self->{_read}->{$fname};
    }
}

=head2 write_release

release file handle for write

=cut

sub write_release {
    my $self = shift;
    my ($fname) = @_;

    if ($self->{_write}->{$fname}) {
	$self->{_filesys}->close_write($self->{_write}->{$fname}->{fh});
	delete $self->{_write}->{$fname};
    }
}

=head2 release

release file handle

=cut

sub release {
    my $self = shift;
    my ($fname) = @_;

    $self->write_release($fname);
    $self->read_release($fname);
}

1;
