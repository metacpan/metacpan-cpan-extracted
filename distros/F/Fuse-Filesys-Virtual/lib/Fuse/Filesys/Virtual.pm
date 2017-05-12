#
# Fuse::Filesys::Virtual
#
# bridge of Fuse and Filesys::Virtual
#

package Fuse::Filesys::Virtual;

use warnings;
use strict;

=head1 NAME

Fuse::Filesys::Virtual - mount Perl module written using Filesys::Virtual

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Fuse::Filesys::Virtual;

    my $fs = Filesys::Virtual::Foo->new();
    my $fuse = Fuse::Filesys::Virtual->new($fs, { debug => 1});

    $fuse->main(mountpoint => '/mnt', mountopts => "allow_other");

=head1 EXPORT

Nothing.

=cut

use POSIX qw(:errno_h :fcntl_h);

use base qw(Fuse::Class);

use Fuse::Filesys::Virtual::FSWrapper;
use Fuse::Filesys::Virtual::HandleCache;

=head1 FUNCTIONS

=cut

sub _debug {
    my $self = shift;
    my (@msg) = @_;

    local ($@, $!);
    print STDERR __PACKAGE__, ": ", @msg if ($self->{debug});
}

=head2 new (FS, ATTR_HASH_REF)

Constructor. Takes FS and ATTR_HASH_REF as a parameter.

  FS - An instance of Virtual::Filesys
  ATTR_HASH_REF - reference to attribute hash.

Following key-value is recognized.

  debug : true or false

=cut

sub new {
    my $class = shift;
    my ($filesys, $attr) = @_;

    my $wrapped = Fuse::Filesys::Virtual::FSWrapper->new($filesys);
    my $self = {
	_filesys => $wrapped,
	_cache => Fuse::Filesys::Virtual::HandleCache->new($wrapped),
	debug => $attr->{debug},
    };

    bless $self, $class;
}

=head2 getattr

Same as Fuse.

=cut

sub getattr {
    my $self = shift;
    my ($fname) = @_;

    my @ret = eval {
	$self->{_filesys}->stat($fname);
    };
    if ($@) {
	$self->_debug($@);
	$! = EPERM if ($! == 0);
	return -$!;
    }
    return @ret;
}

=head2 readlink

Always returns -EPERM.
This function is not supported by Virtual::Filesys.

=cut

sub readlink {
    my $self = shift;
    return -EPERM();
}

=head2 getdir

Same as Fuse.

=cut

sub getdir {
    my $self = shift;
    my ($dirname) = @_;

    my @ret = eval {
	$self->{_filesys}->list($dirname);
    };
    if ($@) {
	$self->_debug($@);
	$! = EPERM if ($! == 0);
	return -$!;
    }

    push(@ret, 0);
    return @ret;
}

=head2 mknod

Same as Fuse.

=cut

sub mknod {
    my $self = shift;
    my ($fname, $modes) = @_;

    eval {
	if ($self->{_filesys}->stat($fname)) {
	    $! = EEXIST;
	    die "file exists";
	}
	else {
	    my $fh = $self->{_filesys}->open_write($fname, 0);
	    die "cannot create $fname: $!" unless($fh);
	    $self->{_filesys}->close_write($fh);
	}
    };
    if ($@) {
	$self->_debug($@);
	$! = EPERM if ($! == 0);
	return -$!;
    }

    return 0;
}

=head2 mkdir

Same as Fuse.

=cut

sub mkdir {
    my $self = shift;
    my ($dirname, $modes) = @_;

    eval {
	$self->{_filesys}->mkdir($dirname);
    };
    if ($@) {
	$self->_debug($@);
	$! = EPERM if ($! == 0);
	return -$!;
    }

    return 0;
}

=head2 unlink

Same as Fuse.

=cut

sub unlink {
    my $self = shift;
    my ($fname) = @_;

    my $busy = eval {
	return -EBUSY() if ($self->{_cache}->is_busy($fname));
    };
    return $busy if ($busy);

    eval {
	unless ($self->{_filesys}->delete($fname)) {
	    $! = EPERM;
	    die "failure";
	}
    };
    if ($@) {
	$self->_debug($@);
	$! = EPERM if ($! == 0);
	return -$!;
    }

    return 0;
}

=head2 rmdir

Same as Fuse.

=cut

sub rmdir {
    my $self = shift;
    my ($dirname) = @_;

    my $busy = eval {
	return -EBUSY() if ($self->{_cache}->is_busy($dirname));
    };
    return $busy if ($busy);

    eval {
	$self->{_filesys}->rmdir($dirname);
    };
    if ($@) {
	$self->_debug($@);
	$! = EPERM if ($! == 0);
	return -$!;
    }

    return 0;
}

=head2 symlink

Always returns -EPERM.
This function is not supported by Virtual::Filesys.

=cut

sub symlink {
    my $self = shift;
    return -EPERM();
}

=head2 rename

Same as Fuse.
But his function is implemented by Copy & Delete.

=cut

sub rename {
    my $self = shift;
    my ($oldname, $newname) = @_;

    my $busy = eval {
	return -EBUSY() if ($self->{_cache}->is_busy($oldname));
    };
    return $busy if ($busy);

    $busy = eval {
	return -EBUSY() if (!$self->{_filesys}->test('d', $newname)
			    && $self->{_cache}->is_busy($newname));
    };
    return $busy if ($busy);

    eval {
	$self->{_filesys}->rename($oldname, $newname)
	    or die "cannot rename: $!";
    };
    if ($@) {
	$self->_debug($@);
	$! = EPERM if ($! == 0);
	return -$!;
    }

    return 0;
}

=head2 link

Always returns -EPERM.
This function is not supported by Virtual::Filesys.

=cut

sub link {
    my $self = shift;
    return -EPERM();
}

=head2 chmod

Always returns 0(success), but nothing is done.
This function is not supported by Virtual::Filesys.

=cut

sub chmod {
    my $self = shift;
    return 0;
}

=head2 chown

Always returns -EPERM.
This function is not supported by Virtual::Filesys.

=cut

sub chown {
    my $self = shift;
    return -EPERM();
}

=head2 truncate

Always returns -EPERM.
This function is not supported by Virtual::Filesys.

=cut

sub truncate {
    my $self = shift;
    my ($fname) = @_;

    eval {
	$self->{_cache}->truncate($fname);
    };
    if ($@) {
	$self->_debug($@);
	$! = EPERM if ($! == 0);
	return -$!;
    }

    return 0;
}

=head2 utime

Same as Fuse.

=cut

sub utime {
    my $self = shift;
    my ($fname, $atime, $mtime) = @_;

    eval {
	$self->{_filesys}->utime($atime, $mtime, $fname);
    };
    if ($@) {
	$self->_debug($@);
	$! = EPERM if ($! == 0);
	return -$!;
    }

    return 0;
}

=head2 open

Same as Fuse.

=cut

sub open {
    my $self = shift;
    my ($fname, $flags) = @_;

    my $ret = eval {
	if ($flags & O_RDONLY) {
	    return -ENOENT() if ($self->{_filesys}->test('f', $fname));
	}

	# parent directory found?
	my $dir = $fname;
	$dir =~ s/\/[^\/]+$//;
	if ($dir eq '' || $self->{_filesys}->test('d', $dir)) {
	    return 0;
	}
	else {
	    return -ENOENT();
	}
    };
    if ($@) {
	$self->_debug($@);
	$! = EPERM if ($! == 0);
	return -$!;
    }

    return $ret;
}

=head2 read

Same as Fuse.

=cut

sub read {
    my $self = shift;
    my ($fname, $size, $offset) = @_;

    my $ret = eval {
	$self->{_cache}->read($fname, $size, $offset);
    };
    if ($@) {
	$self->_debug($@);
	$! = EPERM if ($! == 0);
	return -$!;
    }

    return $ret;
};

=head2 write

Same as Fuse.

=cut

sub write {
    my $self = shift;
    my ($fname, $buf, $offset) = @_;

    my $ret = eval {
	$self->{_cache}->write($fname, $buf, $offset);
    };
    if ($@) {
	$self->_debug($@);
	$! = EPERM if ($! == 0);
	return -$!;
    }

    # Fuse pod says we must return 'errno', but it does not work...
    # return written size here.
    return $ret;
}

=head2 flush

Always returns 0(no error).
This function is not supported by Virtual::Filesys.

=cut

sub flush {
    my $self = shift;
    my ($fname) = @_;

    return 0;
}

=head2 release

Same as Fuse.

=cut

sub release {
    my $self = shift;
    my ($fname) = @_;

    eval {
	$self->{_cache}->release($fname);
    };

    return 0;
}

=head2 fsync

Always returns 0(no error).
This function is not supported by Virtual::Filesys.

=cut

sub fsync {
    my $self = shift;
    my ($fname) = @_;

    eval {
	$self->flush($fname);
    };
    if ($@) {
	$self->_debug($@);
	$! = EPERM if ($! == 0);
	return $!;
    }

    return 0;
}


=head1 AUTHOR

Toshimitsu FUJIWARA, C<< <tttfjw at gmail.com> >>

=head1 BUGS

Threading is not supported.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Fuse::Filesys::Virtual

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Toshimitsu FUJIWARA, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Fuse::Filesys::Virtual
