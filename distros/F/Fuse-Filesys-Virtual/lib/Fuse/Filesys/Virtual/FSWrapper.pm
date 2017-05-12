#
# Fuse::Filesys::Virtual::FSWrapper
#
#

package Fuse::Filesys::Virtual::FSWrapper;

use warnings;
use strict;

=head1 NAME

Fuse::Filesys::Virtual::FSWrapper - Filesys::Virtual wrapper

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Internal module for Fuse::Filesys::Virtual, provides some functions
to Filesys::Virtual object.

    use Fuse::Filesys::Virtual::FSWrapper;

    my $fs = Filesys::Virtual::Foo->new();
    my $wfs = Fuse::Filesys::Virtual::FSWrapper->new($fs);

    ...

    $wfs->rename("/path/to/oldname", "path/to/newname");

=head1 EXPORT

Nothing.

=cut

use Carp;
use Filesys::Virtual;
use Fcntl ':mode';
use POSIX ();

our $AUTOLOAD;

#
# get entries
# (\@dirs, \@files);
#
sub _list_recurse {
    my $self = shift;
    my ($cur) = @_;

    my @dirs;
    my @files;

    if ($self->test('d', $cur)) {
	my @entries =
	    grep { $_ ne '.' && $_ ne '..' } $self->list($cur);

	for my $e (@entries) {
	    my $path = ($cur =~ /\/$/) ? "$cur$e" : "$cur/$e";

	    if ($self->test('d', $path)) {
		push(@dirs, $path);

		my ($d, $f) = $self->_list_recurse($path);
		push(@dirs, @{$d});
		push(@files, @{$f});
	    }
	    else {
		push(@files, $path);
	    }
	}
    }
    else {
	push(@files, $cur);
    }

    return (\@dirs, \@files);
}

=head1 FUNCTIONS

=head2 new

Wrap Filesys::Virtual object.
wrapped object is returned.

=cut

sub new {
    my $class = shift;
    my ($fs) = @_;

    my $self = {
	filesys => $fs,
    };
    bless $self, $class;

    return $self;
}


sub _copy_file {
    my $self = shift;
    my ($srcname, $destname) = @_;

    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
	$atime,$mtime,$ctime,$blksize,$blocks)
	= $self->stat($srcname);

    my $in = $self->open_read($srcname)
	or croak "$srcname: cannot open: $!";

    my $out = $self->open_write($destname, undef)
	or croak "$destname: cannot create: $!";

    my $buf;
    my $buflen = 4096;
    while(read($in, $buf, $buflen)) {
	print $out $buf;
    }

    $self->close_write($out);
    $self->close_read($in);

    eval { $self->utime($atime, $mtime, $destname); };
    eval { $self->chmod($mode, $destname); };
}

#
# rename a file (not a directory)
#
sub _rename_file {
    my $self = shift;
    my ($oldname, $newname) = @_;

    eval {
	$self->_copy_file($oldname, $newname);

	$self->delete($oldname) or croak "cannot delete $oldname: $!";
    };
    if ($@) {
	# print STDERR "$@";
	my $err = $! || 1;

	$self->delete($newname);
	$! = $err;

	return; # undef
    }

    $self->delete($oldname);

    return 1;
}


#
# rename a directory (recursive copy)
#
sub _rename_dir {
    my $self = shift;
    my ($oldname, $newname) = @_;

    my ($srcdirs, $srcfiles) = $self->_list_recurse($oldname);
    unshift(@{$srcdirs}, $oldname);

    my %dirstats;

    for my $dir (@{$srcdirs}) {
	my $destdir = $dir;
	$destdir =~ s/^\Q$oldname\E/$newname/;
	
        my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
	    $atime,$mtime,$ctime,$blksize,$blocks)
	    = $self->stat($dir);

	unless ($self->test('d', $destdir)) {
	    $self->mkdir($destdir, $mode);
	}
	$dirstats{$destdir} = { atime => $atime, mtime => $mtime };
    }

    for my $file (@{$srcfiles}) {
	my $destfile = $file;
	$destfile =~ s/^\Q$oldname\E/$newname/;

	$self->_copy_file($file, $destfile);
    }

    for my $d (keys %dirstats) {
	eval { $self->utime($dirstats{$d}->{atime},
			    $dirstats{$d}->{mtime},
			    $d); };
    }

    #
    # TODO:
    # If error is found while deleting original files, 
    # should I rollback filesys?
    #
    for my $file (@{$srcfiles}) {
	$self->delete($file);
    }
    for my $dir (reverse @{$srcdirs}) {
	$self->rmdir($dir);
    }

    return 1;
}

=head2 rename (OLDNAME, NEWNAME)

rename oldname to newname

=cut

sub rename {
    my $self = shift;
    my ($oldname, $newname) = @_;

    my $dest = $newname;

    if ($self->test('d', $newname)) {
	$dest .= '/' unless ($dest =~ /\/$/);
	my @segs = split(/\//, $oldname);
	$dest .= $segs[$#segs];
    }

    if ($self->test('d', $oldname)) {
	return $self->_rename_dir($oldname, $dest);
    }
    else {
	return $self->_rename_file($oldname, $dest);
    }
}

# Fix nlink
# ex. File::Find does NOT follow directory having nlink <= 2.
sub _fix_stat {
    my $self = shift;
    my ($fname) = @_;

    my @s = $self->_call_original_method("stat", $fname);
    return @s unless (@s);

    if (@s && POSIX::S_ISDIR($s[2])) {
	$s[3] = $self->_count_nlink($fname);
    }

    return @s;
}

=head2 stat

Same as Filesys::Virtual::stat.
(but nlink is corrected for directory.)

=cut

sub stat {
    my $self = shift;
    $self->_fix_stat(@_);
}

sub _count_nlink {
    my $self = shift;
    my ($fname) = @_;

    my $nlink = 2; # '.', '..'

    for my $name ($self->{filesys}->list($fname)) {
	next if ($name eq '.' || $name eq '..');
	my $tmp = "$fname/$name";
	$tmp =~ s/\/\//\//g;
	$nlink++ if ($self->{filesys}->test('d', $tmp));
    }

    return $nlink;
}

sub _fake_test {
    my $self = shift;
    my ($test, $fname) = @_;

    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
	$atime,$mtime,$ctime,$blksize,$blocks) = $self->stat($fname);

    if ($test eq 'd') {
	return POSIX::S_ISDIR($mode) ? 1 : undef;
    }
    elsif ($test eq 'f') {
	return POSIX::S_ISREG($mode) ? 1 : undef;
    }
    elsif ($test eq 'e') {
	return defined($ino) ? 1 : undef;
    }

    return undef;
}

#
# other method is same as original...
#
sub AUTOLOAD {
    my $self = shift;

    my $method = $AUTOLOAD;
    $method =~ s/.*:://;

    $self->_call_original_method($method, @_);
}

sub _call_original_method {
    my $self = shift;
    my $method = shift;

    {
	no warnings "redefine";
	local *Filesys::Virtual::carp = sub {
	    my $msg = shift;
	    Carp::croak($msg) if ($msg =~ / Unimplemented/);
	    Carp::carp($msg);
	};

	return $self->{filesys}->$method(@_);
    }
}

sub DESTROY {
}

1;
