package File::BackupCopy;
use strict;
use warnings;
use File::Copy;
use File::Temp;
use File::Basename;
use File::Spec;
use Exporter;
use re '/aa';
use Carp;
use Errno;

our $VERSION = '1.00';
our @ISA = qw(Exporter);
our @EXPORT = qw(BACKUP_NONE
                 BACKUP_SINGLE
                 BACKUP_SIMPLE
                 BACKUP_NUMBERED
                 BACKUP_AUTO
                 backup_copy);

our @EXPORT_OK = qw(backup_copy_simple backup_copy_numbered backup_copy_auto);

use constant {
    BACKUP_NONE => 0,         # No backups at all (none,off)
    BACKUP_SINGLE => 1,       # Always make single backups (never,simple)
    BACKUP_SIMPLE => 1,
    BACKUP_NUMBERED => 2,     # Always make numbered backups (t,numbered)
    BACKUP_AUTO => 3          # Make numbered if numbered backups exist,
	                      # simple otherwise (nil,existing)
};

my %envtrans = (
    none => BACKUP_NONE,
    off => BACKUP_NONE,
    never => BACKUP_SIMPLE,
    simple => BACKUP_SIMPLE,
    t => BACKUP_NUMBERED,
    numbered => BACKUP_NUMBERED,
    nil => BACKUP_AUTO,
    existing => BACKUP_AUTO
);

my %backup_func = (
    BACKUP_NONE() => sub {},
    BACKUP_SIMPLE() => \&backup_copy_simple,
    BACKUP_NUMBERED() => \&backup_copy_numbered,
    BACKUP_AUTO() => \&backup_copy_auto
);

sub backup_copy {
    my $file = shift;

    my ($type, %opts);
    if (@_ == 1) {
	$type = shift;
    } elsif (@_ % 2 == 0) {
	%opts = @_;
	$type = delete $opts{type};
    } else {
	croak "wrong number of arguments";
    }

    unless (defined($type)) {
	my $v = $ENV{VERSION_CONTROL} || BACKUP_AUTO;
	if (exists($envtrans{$v})) {
	    $type = $envtrans{$v};
	} else {
	    $type = BACKUP_AUTO;
	}
    }    
    &{$backup_func{$type}}($file, %opts);
}

sub _backup_copy_error {
    my ($error, $msg) = @_;
    if ($error) {
	$$error = $msg;
	return undef;
    }
    confess $msg;
}

sub backup_copy_simple {
    my $file_name = shift;
    local %_ = @_;
    my $error = delete $_{error};
    my $dir = delete $_{dir};
    croak "unrecognized keyword arguments" if keys %_;    
    my $backup_name = $file_name . '~';
    if ($dir) {
	$backup_name = File::Spec->catfile($dir, $backup_name);
    }
    copy($file_name, $backup_name)
	or return _backup_copy_error($error,
			      "failed to copy $file_name to $backup_name: $!");
    return $backup_name;
}

sub backup_copy_internal {
    my $file_name = shift;

    my ($if_exists, $error, $dir);
    if (@_ == 1) {
	$if_exists = shift;
    } elsif (@_ % 2 == 0) {
	local %_ = @_;
	$if_exists = delete $_{if_exists};
	$error = delete $_{error};
	$dir = delete $_{dir};
	croak "unrecognized keyword arguments" if keys %_;
    } else {
	croak "wrong number of arguments";
    }
 
    my $fh = eval { File::Temp->new(DIR => $dir || dirname($file_name)) };
    if ($@) {
	return _backup_copy_error($error, $@);
    }

    copy($file_name, $fh)
	or return _backup_copy_error($error,
				"failed to make a temporary copy of $file_name: $!");

    my $pat = $dir ? File::Spec->catfile($dir, "$file_name.~*~")
	           : "$file_name.~*~";
    my $num = (sort { $b <=> $a }
	       map {
		   if (/.+\.~(\d+)~$/) {
		       $1
		   } else {
		       ()
	           }
               } glob($pat))[0];

    if (!defined($num)) {
	return backup_copy_simple($file_name, error => $error, dir => $dir)
	    if $if_exists;
	$num = '1';
    }
    
    my $backup_name;
    while (1) {
	$backup_name = "$file_name.~$num~";
	if ($dir) {
	    $backup_name = File::Spec->catfile($dir, $backup_name);
	}
	last if symlink($fh->filename, $backup_name);
	unless ($!{EEXIST}) {
	    return _backup_copy_error("can't link "
				 . $fh->filename .
				 " to $backup_name: $!");
	}
	++$num;
    }
    
    unless (rename($fh->filename, $backup_name)) {
	return _backup_copy_error("can't rename temporary file to $backup_name: $!");
    }
    return $backup_name;
}

sub backup_copy_numbered {
    my ($file_name, %opts) = @_;
    $opts{if_exists} = 0;
    backup_copy_internal($file_name, %opts);
}

sub backup_copy_auto {
    my ($file_name, %opts) = @_;
    $opts{if_exists} = 1;
    backup_copy_internal($file_name, %opts);
}
    
1;
__END__

=head1 NAME

File::BackupCopy - create a backup copy of the file.
    
=head1 SYNOPSIS

    use File::BackupCopy;

    $backup_name = backup_copy($file_name);

    $backup_name = backup_copy($file_name, BACKUP_NUMBERED);

    $backup_name = backup_copy($file_name, type => BACKUP_NUMBERED,
                          dir => $directory, error => \my $error);
    if (!$backup_name) {
        warn $error;
    }

=head1 DESCRIPTION

The File::BackupCopy module provides functions for creating backup copies of
files.  Normally, the name of the backup copy is created by appending a
single C<~> character to the original file name.  This naming is called
I<simple backup>.  Another naming scheme is I<numbered backup>.  In this
scheme, the name of the backup is created by suffixing the original file
name with C<.~I<N>~>, where I<N> is a decimal number starting with 1.
In this naming scheme, the backup copies of file F<test> would be
called F<test.~1~>, F<test.~2~> and so on.

=head2 backup_copy

    $backup_name = backup_copy($orig_name);
    
    $backup_name = backup_copy($orig_name, $scheme);

    $backup_name = backup_copy($orig_name, %opts);

The B<backup_copy> function is the principal interface for managing backup
copies.  Its first argument specifies the name of the existing file for
which a backup copy is required.  Optional second argument controls the
backup naming scheme.  Its possible values are:

=over 4

=item BACKUP_NONE

Don't create backup.
    
=item BACKUP_SINGLE or BACKUP_SIMPLE

Create simple backup (F<I<FILE>~>).
    
=item BACKUP_NUMBERED

Create numbered backup (F<I<FILE>.~B<N>~>).

=item BACKUP_AUTO

Automatic selection of the naming scheme.  Create numbered backup if the
file has numbered backups already.  Otherwise, make simple backup. 

=back

If the second argument is omitted, the function will consult the value of
the environment variable B<VERSION_CONTROL>.  Its possible values are:

=over 4

=item none, off

Don't create any backups (B<BACKUP_NONE>).

=item simple, never

Create simple backups (B<BACKUP_SIMPLE>).

=item numbered, t

Create numbered backups (B<BACKUP_NUMBERED>).

=item existing, nil    

Automatic selection of the naming scheme (B<BACKUP_AUTO>).

=back

If B<VERSION_CONTROL> is unset or set to any other value than those listed
above, B<BACKUP_AUTO> is assumed.

The function returns the name of the backup file it created (C<undef> if
called with B<BACKUP_NONE>).  On error, it calls B<croak()>.

When used in the third form, the B<%opts> are keyword arguments that
control the function behavior.  The following arguments are understood:

=over 4

=item type =E<gt> $scheme

Request a particular backup naming scheme.  The following two calls are
equivalent:

    backup_copy($file, type => BACKUP_SIMPLE)
    
    backup_copy($file, BACKUP_SIMPLE)

=item dir =E<gt> $directory

Create backup files in I<$directory>.  The directory must exist and be
writable.

By default backup files are created in the same directory as the original file.

=item error =E<gt> $ref

This changes default error handling.  Instead of croaking on error, the
error message will be stored in I<$ref> (which should be a reference to
a scalar) and C<undef> will be returned.

This can be used for an elaborate error handling and recovery, e.g.:

    $bname = backup_copy($file, \my $err);
    unless ($bname && defined($err)) {
        error("can't backup_copy file $file: $err");
        # perhaps more code follows
    }
    ...    

=back    
    
The following functions are available for using a specific backup naming
scheme.  These functions must be exported explicitly.
    
=head2 backup_copy_simple

    use File::BackupCopy qw(backup_copy_simple);
    $backup_name = backup_copy_simple($orig_name, %opts);

Creates simple backup.  Optional I<%opts> have the same meaning as in
B<backup_copy>, except that, obviously, B<type> keyword is not accepted.    

    
=head2 backup_copy_numbered
    
    use File::BackupCopy qw(backup_copy_numbered);
    $backup_name = backup_copy_numbered($orig_name, %opts);

Creates numbered backup.  See above for a description of I<%opts>.

=head2 backup_copy_auto

    use File::BackupCopy qw(backup_copy_auto);
    $backup_name = backup_copy_auto($orig_name, %opts);

Creates numbered backup if any numbered backup version already exists for
the file.  Otherwise, creates simple backup.

Optional I<%opts> have the same meaning as in
B<backup_copy>, except that, obviously, B<type> keyword is not accepted.    
    
=cut    
