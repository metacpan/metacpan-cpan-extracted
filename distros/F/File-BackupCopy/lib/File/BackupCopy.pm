package File::BackupCopy;
use strict;
use warnings;
use File::Copy;
use File::Temp 'tempfile';
use File::Basename;
use File::Spec;
use Exporter;
use re '/aa';
use Carp;
use Errno;

our $VERSION = '1.01';
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
	$backup_name = File::Spec->catfile($dir, basename($backup_name));
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
 
    my $backup_stub = $dir ? File::Spec->catfile($dir, basename($file_name))
 	                   : $file_name;
    my $num = (sort { $b <=> $a }
	       map {
		   if (/.+\.~(\d+)~$/) {
		       $1
		   } else {
		       ()
	           }
               } glob("$backup_stub.~*~"))[0];

    if (defined($num)) {
	++$num;
    } else {
	return backup_copy_simple($file_name, error => $error, dir => $dir)
	    if $if_exists;
	$num = '1';
    }
    
    my ($fh, $tempname) = eval { tempfile(DIR => $dir || dirname($file_name)) };
    if ($@) {
	return _backup_copy_error($error, $@);
    }

    copy($file_name, $fh)
	or return _backup_copy_error($error,
			 "failed to make a temporary copy of $file_name: $!");
    close $fh;
    
    my $backup_name = rename_backup($tempname, $backup_stub, $num, $error);
    unless ($backup_name) {
	unlink($tempname) or carp("can't unlink $tempname: $!");
    }
    return $backup_name;
}

# The rename_backup function performs the final stage of numbered backup
# creation: atomical rename of the temporary backup file to the actual
# backup name.
# The calling sequence is:
#    rename_backup($tempfile, $backup_stub, $num, $error)
# where $tempfile    is the name of the temporary file holding the backup,
#       $backup_stub is the name of the backup file without the actual
#                    numbered suffix (may contain directory components,
#                    if required).
#       $num         is the first unused backup number,
#       $error       is the reference to error message storage or undef.
# The function creates the new backup file name from $backup_stub and
# $num and attempts to rename $tempfile to it.  If the rename failed
# because such file already exists (i.e. another process created it in
# between), the function increases the $num and retries.  The process
# continues until the rename succeeds or a fatal error is encountered,
# whichever occurs first.
#
# Three versions of the function are provided.  The right one to use
# is selected when the module is loaded:

BEGIN {
    if (eval { symlink("",""); 1 }) {
	*{rename_backup} = \&rename_backup_posix;
    } elsif ($^O eq 'MSWin32' && eval { require Win32API::File }) {
	Win32API::File->import(qw(MoveFile fileLastError));
	*{rename_backup} = \&rename_backup_win32;
    } else {
	warn "using last resort rename method susceptible to a race condition";
	*{rename_backup} = \&rename_backup_last_resort;
    }
}

# rename_backup_posix - rename_backup for POSIX systems.
# -------------------
# In order to ensure atomic rename, the temporary file is first
# symlinked to the desired backup name.  This will fail if the
# name already exists, in which case the function will try next
# backup number.  Once the symlink is created, temporary file
# is renamed to it.  This operation will silently destroy the
# symlink and replace it with the backup file.
sub rename_backup_posix {
    my ($tempfilename, $backup_stub, $num, $error) = @_;
    my $backup_name;
    while (1) {
	$backup_name = "$backup_stub.~$num~";
	last if symlink($tempfilename, $backup_name);
	unless ($!{EEXIST}) {
	    return _backup_copy_error($error,
			  "can't link $tempfilename to $backup_name: $!");
	}
	++$num;
    }
    
    unless (rename($tempfilename, $backup_name)) {
	return _backup_copy_error($error,
		      "can't rename temporary file to $backup_name: $!");
    }
    return $backup_name;
}

# rename_backup_win32 - rename_backup for MSWin32 systems with Win32API::File
# -------------------
# This function is used if Win32API::File was loaded successfully.  It uses
# the MoveFile function to ensure atomic renames.
sub rename_backup_win32 {
    my ($tempfilename, $backup_stub, $num, $error) = @_;
    my $backup_name;
    while (1) {
	$backup_name = "$backup_stub.~$num~";
	last if MoveFile($tempfilename, $backup_name);
	# 80  - ERROR_FILE_EXISTS
	#     - "The file exists."
        # 183 - ERROR_ALREADY_EXISTS
	#     - "Cannot create a file when that file already exists."
	unless (fileLastError() == 80 || fileLastError() == 183) {
	    return _backup_copy_error($error,
			  "can't rename $tempfilename to $backup_name: $^E");
	}
	++$num;
    }
    return $backup_name;
}

# rename_backup_last_resort - a weaker version for the rest of systems
# -------------------------
# It is enabled on systems not offering the symlink function (except where
# Win32API::File can be used).  This version uses a combination of -f test
# and rename.  It suffers from an obvious race condition which occurs in
# the time window between these.
sub rename_backup_last_resort {
    my ($tempfilename, $backup_stub, $num, $error) = @_;
    my $backup_name;
    while (1) {
	$backup_name = "$backup_stub.~$num~";
	unless (-f $backup_name) {
	    last if rename($tempfilename, $backup_name);
	    return _backup_copy_error($error,
			  "can't rename temporary file to $backup_name: $!");
	}
	++$num;
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

=head1 LICENSE

GPLv3+: GNU GPL version 3 or later, see
L<http://gnu.org/licenses/gpl.html>.

This  is  free  software:  you  are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

=head1 AUTHORS

Sergey Poznyakoff <gray@gnu.org>

=cut
