# -*- Perl -*-
#
# uses File::Temp to create the temporary file, and offers various
# degrees of more paranoid write handling, and means to set Unix file
# permissions and ownerships on the resulting file. note however that
# rename() may not be safe depending on the filesystem and what
# exactly fails. run perldoc(1) on this file for more information

package File::AtomicWrite;

use strict;
use warnings;

use Carp qw(croak);
use Fcntl qw(:seek);
use File::Basename qw(dirname);
use File::Path qw(mkpath);
use File::Temp qw(tempfile);
# for olden versions of perl
use IO::Handle;

our $VERSION = '1.21';

# Default options
my %default_params = ( MKPATH => 0, template => ".tmp.XXXXXXXXXX" );

######################################################################
#
# Class methods

# accepts output filename, perhaps optional tmp file template, and a
# filehandle or scalar ref, and handles all the details in a single shot
sub write_file {
    my ( $class, $user_params ) = @_;
    $user_params = {} unless defined $user_params;

    if ( !exists $user_params->{input} ) {
        croak "missing 'input' option";
    }

    my ( $tmp_fh, $tmp_filename, $params_ref, $digest ) = _init($user_params);

    # attempt cleanup if things go awry (use the OO interface and custom
    # signal handlers of your own if this is a problem)
    local $SIG{TERM} = sub { _cleanup( $tmp_fh, $tmp_filename ); exit };
    local $SIG{INT}  = sub { _cleanup( $tmp_fh, $tmp_filename ); exit };
    local $SIG{__DIE__} = sub { _cleanup( $tmp_fh, $tmp_filename ) };

    my $input_ref = ref $params_ref->{input};
    unless ( $input_ref eq 'SCALAR' or $input_ref eq 'GLOB' ) {
        croak "invalid type for input option: " . ref $input_ref;
    }

    my $input = $params_ref->{input};
    if ( $input_ref eq 'SCALAR' ) {
        unless ( print $tmp_fh $$input ) {
            my $save_errstr = $!;
            _cleanup( $tmp_fh, $tmp_filename );
            croak "error printing to temporary file: $save_errstr";
        }
        if ( exists $params_ref->{CHECKSUM}
            and !exists $params_ref->{checksum} ) {
            $digest->add($$input);
        }
    } elsif ( $input_ref eq 'GLOB' ) {
        while ( my $line = readline $input ) {
            unless ( print $tmp_fh $line ) {
                my $save_errstr = $!;
                _cleanup( $tmp_fh, $tmp_filename );
                croak "error printing to temporary file: $save_errstr";
            }
            if ( exists $params_ref->{CHECKSUM}
                and !exists $params_ref->{checksum} ) {
                $digest->add($$input);
            }
        }
    }

    _resolve( $tmp_fh, $tmp_filename, $params_ref, $digest );
}

sub new {
    my ( $class, $user_param ) = @_;
    $user_param = {} unless defined $user_param;

    croak "option 'input' only for write_file class method"
      if exists $user_param->{input};

    my $self = {};

    @{$self}{qw/_tmp_fh _tmp_filename _params _digest/} = _init($user_param);

    bless $self, $class;
    return $self;
}

sub safe_level {
    my ( $class, $level ) = @_;
    croak 'safe_level() requires a value' unless defined $level;
    File::Temp->safe_level($level);
}

sub set_template {
    my ( $class, $template ) = @_;
    croak 'set_template() requires a template' unless defined $template;
    $default_params{template} = $template;
    return;
}

######################################################################
#
# Instance methods

sub checksum {
    my ( $self, $csum ) = @_;
    croak 'checksum requires an argument' unless defined $csum;
    $self->{_params}->{checksum} = $csum;

    if ( !$self->{_digest} ) {
        $self->{_params}->{CHECKSUM} = 1;
        $self->{_digest} = _init_checksum( $self->{_params} );
    }

    return $self;
}

sub commit { _resolve( @{ $_[0] }{qw/_tmp_fh _tmp_filename _params _digest/} ) }

sub DESTROY { _cleanup( @{ $_[0] }{qw/_tmp_fh _tmp_filename/} ) }

sub fh { $_[0]->{_tmp_fh} }

sub filename { $_[0]->{_tmp_filename} }

# for when things go awry
sub _cleanup {
    my ( $tmp_fh, $tmp_filename ) = @_;
    # recommended by perlport(1) prior to unlink/rename calls
    close $tmp_fh if defined $tmp_fh;
    unlink $tmp_filename if defined $tmp_filename;
}

sub _init {
    my ($user_params) = @_;
    $user_params = {} unless defined $user_params;
    my $params_ref = { %default_params, %$user_params };

    if (   !exists $params_ref->{file}
        or !defined $params_ref->{file} ) {
        croak q{missing 'file' option};
    }

    my $digest = _init_checksum($params_ref);

    $params_ref->{_dir} = dirname( $params_ref->{file} );
    if ( !-d $params_ref->{_dir} ) {
        _mkpath( $params_ref->{MKPATH}, $params_ref->{_dir} );
    }

    if ( exists $params_ref->{tmpdir} ) {
        if ( !-d $params_ref->{tmpdir}
            and $params_ref->{tmpdir} ne $params_ref->{_dir} ) {
            _mkpath( $params_ref->{MKPATH}, $params_ref->{tmpdir} );

            # partition sanity check
            my @dev_ids = map { ( stat $params_ref->{$_} )[0] } qw/_dir tmpdir/;
            if ( $dev_ids[0] != $dev_ids[1] ) {
                croak 'tmpdir and file directory on different partitions';
            }
        }
    } else {
        $params_ref->{tmpdir} = $params_ref->{_dir};
    }

    if ( exists $params_ref->{safe_level} ) {
        File::Temp->safe_level( $params_ref->{safe_level} );
    }

    my ( $tmp_fh, $tmp_filename ) = tempfile(
        $params_ref->{template},
        DIR    => $params_ref->{tmpdir},
        UNLINK => 0
    );
    if ( !defined $tmp_fh ) {
        die "unable to obtain temporary filehandle\n";
    }

    if ( exists $params_ref->{binmode_layer}
        and defined $params_ref->{binmode_layer} ) {
        binmode( $tmp_fh, $params_ref->{binmode_layer} );
    } elsif ( exists $params_ref->{BINMODE} and $params_ref->{BINMODE} ) {
        binmode($tmp_fh);
    }

    return $tmp_fh, $tmp_filename, $params_ref, $digest;
}

sub _init_checksum {
    my ($params_ref) = @_;
    my $digest = 0;

    if ( exists $params_ref->{CHECKSUM} and $params_ref->{CHECKSUM} ) {
        eval { require Digest::SHA1; };
        if ($@) {
            croak 'cannot checksum as lack Digest::SHA1';
        }
        $digest = Digest::SHA1->new;
    } else {
        # so can rely on 'exists' test elsewhere hereafter
        delete $params_ref->{CHECKSUM};
    }

    return $digest;
}

sub _resolve {
    my ( $tmp_fh, $tmp_filename, $params_ref, $digest ) = @_;

    if ( exists $params_ref->{CHECKSUM}
        and !exists $params_ref->{checksum} ) {
        $params_ref->{checksum} = $digest->hexdigest;
    }

    # help the bits reach the disk?
    $tmp_fh->flush() or die "flush() error: $!\n";
    # TODO may need eval or exclude on other platforms
    if ( $^O !~ m/Win32/ ) {
        $tmp_fh->sync() or die "sync() error: $!\n";
    }

    eval {
        if ( exists $params_ref->{min_size} ) {
            _check_min_size( $tmp_fh, $params_ref->{min_size} );
        }
        if ( exists $params_ref->{CHECKSUM} ) {
            _check_checksum( $tmp_fh, $params_ref->{checksum} );
        }
    };
    if ($@) {
        _cleanup( $tmp_fh, $tmp_filename );
        die $@;
    }

    # recommended by perlport(1) prior to unlink/rename calls
    #
    # TODO I've seen false positives from close() calls (from a very old
    # version of XML::LibXML) though certain file systems only report
    # errors at close() time. if someone can document a false positive,
    # instead create an option and let the caller decide...
    close($tmp_fh) or die "problem closing filehandle: $!\n";

    # spare subsequent useless close attempts, if any
    undef $tmp_fh;

    if ( exists $params_ref->{mode} ) {
        my $mode = $params_ref->{mode};
        croak 'invalid mode data'
          if !defined $mode
          or $mode !~ m/^[0-9]+$/;

        my $int_mode = substr( $mode, 0, 1 ) eq '0' ? oct($mode) : ( $mode + 0 );

        my $count = chmod( $int_mode, $tmp_filename );
        if ( $count != 1 ) {
            my $save_errstr = $!;
            _cleanup( $tmp_fh, $tmp_filename );
            die "unable to chmod temporary file: $save_errstr\n";
        }
    }

    if ( exists $params_ref->{owner} ) {
        eval { _set_ownership( $tmp_filename, $params_ref->{owner} ); };
        if ($@) {
            _cleanup( $tmp_fh, $tmp_filename );
            die $@;
        }
    }

    if ( exists $params_ref->{mtime} ) {
        croak 'invalid mtime data'
          if !defined $params_ref->{mtime}
          or $params_ref->{mtime} !~ m/^[0-9]+$/;

        my ($file_atime) = ( stat $tmp_filename )[8];
        my $count = utime( $file_atime, $params_ref->{mtime}, $tmp_filename );
        if ( $count != 1 ) {
            my $save_errstr = $!;
            _cleanup( $tmp_fh, $tmp_filename );
            die "unable to utime temporary file: $save_errstr\n";
        }
    }

    # If the file does not exist, but the backup does;
    # the backup is left unmodified
    if ( exists $params_ref->{backup} && -f $params_ref->{file} ) {
        croak 'invalid backup suffix'
          if !defined $params_ref->{backup}
          or $params_ref->{backup} eq '';

        # The backup file will be hardlinked in same directory as original
        my $backup_filename = $params_ref->{file} . $params_ref->{backup};
        if ( -f $backup_filename ) {
            my $count = unlink($backup_filename);
            if ( $count != 1 ) {
                my $save_errstr = $!;
                _cleanup( $tmp_fh, $tmp_filename );
                die "unable to unlink existing backup file: $save_errstr\n";
            }
        }

        # make hardlink -- Haiku OS does not appear to support these;
        # http://www.cpantesters.org/cpan/report/7c2a3994-bc30-11e8-83ca-8681f4fbe649
        # which is warned about in the perlport POD
        if ( !link( $params_ref->{file}, $backup_filename ) ) {
            my $save_errstr = $!;
            _cleanup( $tmp_fh, $tmp_filename );
            die "unable to link existing file to backup file: $save_errstr\n";
        }
    }

    unless ( rename( $tmp_filename, $params_ref->{file} ) ) {
        my $save_errstr = $!;
        _cleanup( $tmp_fh, $tmp_filename );
        croak "unable to rename file: $save_errstr";
    }

    # spare subsequent useless unlink attempts, if any
    undef $tmp_filename;

    return 1;
}

sub _mkpath {
    my ( $mkpath, $directory ) = @_;

    if ($mkpath) {
        mkpath($directory);
        croak "could not create parent directory" unless -d $directory;
    } else {
        croak "parent directory does not exist";
    }

    return 1;
}

sub _check_checksum {
    my ( $tmp_fh, $checksum ) = @_;

    seek( $tmp_fh, 0, SEEK_SET )
      or die("tmp fh seek() error: $!\n");

    my $digest = Digest::SHA1->new;
    $digest->addfile($tmp_fh);

    my $on_disk_checksum = $digest->hexdigest;

    if ( $on_disk_checksum ne $checksum ) {
        croak 'temporary file SHA1 hexdigest does not match supplied checksum';
    }

    return 1;
}

sub _check_min_size {
    my ( $tmp_fh, $min_size ) = @_;

    # must seek, as OO method allows the fh or filename to be passed off
    # and used by who knows what first
    seek( $tmp_fh, 0, SEEK_END )
      or die("tmp fh seek() error: $!\n");

    my $written = tell($tmp_fh);
    if ( $written == -1 ) {
        die("tmp fh tell() error: $!\n");
    } elsif ( $written < $min_size ) {
        croak 'bytes written failed to exceed min_size required';
    }

    return 1;
}

# accepts "0" or "user:group" type ownership details and a filename,
# attempts to set ownership rights on that filename. croak()s if
# anything goes awry
sub _set_ownership {
    my ( $filename, $owner ) = @_;

    croak 'invalid owner data' if !defined $owner or length $owner < 1;

    # defaults if nothing comes of the subsequent parsing
    my ( $uid, $gid ) = ( -1, -1 );

    my ( $user_name, $group_name ) = split /[:.]/, $owner, 2;

    my ( $login, $pass, $user_uid, $user_gid );

    # only customize user if have something from caller
    if ( defined $user_name and $user_name ne '' ) {
        if ( $user_name =~ m/^([0-9]+)$/ ) {
            $uid = $1;
        } else {
            ( $login, $pass, $user_uid, $user_gid ) = getpwnam($user_name)
              or croak 'user not in password database';
            $uid = $user_uid;
        }
    }

    # only customize group if have something from caller
    if ( defined $group_name and $group_name ne '' ) {
        if ( $group_name =~ m/^([0-9]+)$/ ) {
            $gid = $1;
        } else {
            my ( $group_name, $pass, $group_gid ) = getgrnam($group_name)
              or croak 'group not in group database';
            $gid = $group_gid;
        }
    }

    my $count = chown( $uid, $gid, $filename );
    if ( $count != 1 ) {
        die "unable to chown temporary file\n";
    }

    return 1;
}

1;
__END__

=head1 NAME

File::AtomicWrite - writes files atomically via rename()

=head1 SYNOPSIS

  use File::AtomicWrite ();

  # oneshot: requires filename and all the input data
  # (as a filehandle or scalar ref)
  File::AtomicWrite->write_file(
      {   file  => 'data.dat',
          input => $filehandle,
      }
  );
  # how paranoid are you?
  File::AtomicWrite->write_file(
      {   file     => '/etc/passwd',
          input    => \$scalarref,
          CHECKSUM => 1,
          min_size => 100,
      }
  );

  # instance interface: use to stream data or to have
  # custom signal handlers
  use Digest::SHA1;
  my $aw = File::AtomicWrite->new(
      {   file     => 'name',
          min_size => 1,
          ...
      }
  );
  my $digest   = Digest::SHA1->new;
  my $tmp_fh   = $aw->fh;
  my $tmp_file = $aw->filename;
  print $tmp_fh ...;
  $digest->add(...);
  $aw->checksum( $digest->hexdigest )->commit;

=head1 DESCRIPTION

This module offers atomic file writes via a temporary file created in
the same directory (and therefore probably the same partition) as the
specified B<file>. After data has been written to the temporary file,
the C<rename> system call is used to replace the target B<file>. The
module optionally supports various sanity checks (B<min_size>,
B<CHECKSUM>) that help ensure the data is written without errors.

Should anything go awry, the module will C<die> or C<croak>. All calls
should be wrapped in C<eval> blocks or better yet L<Try::Tiny>.

  eval { File::AtomicWrite->write_file(...) };
  if ($@) { die "uh oh: $@" }

The module attempts to C<flush> and C<sync> the temporary filehandle
prior to the C<rename> call. This may cause portability problems. If so,
please let the author know. Also notify the author if false positives
from the C<close> call are observed.

=head1 CLASS METHODS

=over 4

=item B<write_file> I<options hash reference>

Requires a hash reference that must contain both the B<input> and
B<file> options. Performs the various required steps in a single method
call. Only if all checks pass will the B<input> data be moved to the
B<file> file via C<rename>. If not, the module will throw an error and
attempt to cleanup any temporary files created.

See L</"OPTIONS"> for additional settings that can be passed to
C<write_file>.

B<write_file> installs C<local> signal handlers for C<INT>, C<TERM>, and
C<__DIE__> to try to cleanup any active temporary files if the process
is killed or dies. If these are a problem instead use the OO interface
and setup signal handlers as necessary.

=item B<safe_level> I<safe_level value>

Method to customize the L<File::Temp> module C<safe_level> value.
Consult the L<File::Temp> documentation for more information on
this option.

Can also be set via the B<safe_level> option.

=item B<set_template> I<File::Temp template>

Method to customize the default L<File::Temp> template used when
creating temporary files. NOTE: if customized, the template must contain
a sufficient number of C<X> that suffix the template string, as
otherwise L<File::Temp> will throw an error:

  template => "mytmp.X",          # Wrong
  template => "mytmp.XXXXXXXXXX", # better

Can also be set via the B<template> option.

=item B<new> I<options hash reference>

Takes most of the same options as C<write_file> and returns an object,
notably not I<input> on the presumption that the temporary file or file
handle will be used by other code to write the file. Sanity checks are
deferred until the B<commit> method is called. The B<checksum> method
call with a suitable argument is required for that verification to pass.

If a rollback is required C<undef> the File::AtomicWrite object; the
object destructor should then unlink the temporary file. However, should
the process receive a TERM, INT, or other signal that causes the script
to exit the temporary file will not be cleaned up. If this is
undesirable, a signal handler must be installed:

  my $aw = File::AtomicWrite->new({file => 'somefile'});
  for my $sig_name (qw/INT TERM/) {
      $SIG{$sig_name} = sub { exit }
  }
  ...

Consult perlipc(1) for more information on signal handling, and the
C<eg/cleanup-test> program under this module distribution. A C<__DIE__>
signal handler may also be necessary, consult the C<die> L<perlfunc>
documentation for details.

Instances must not be reused; create a new instance instead of calling
B<new> again on an existing instance. Reuse may cause undefined behavior
or other unexpected problems.

=back

=head1 INSTANCE METHODS

=over 4

=item B<fh>

Returns the temporary filehandle.

=item B<filename>

Returns the file name of the temporary file.

=item B<checksum> I<SHA1 hexdigest>

Takes a single argument that must contain the L<Digest::SHA1>
C<hexdigest> of the data written to the temporary file. Enables the
B<CHECKSUM> option.

=item B<commit>

Call this method once finished with the temporary file. A number of
sanity checks (if enabled via the appropriate L</"OPTIONS">) will be
performed. If these pass, the temporary file will be renamed to the
real filename.

No subsequent use of the instance should be made after calling this
method as this would lead to undefined behavior.

=back

=head1 OPTIONS

The B<write_file> and B<new> methods accept a number of options,
supplied via a hash reference. Mandatory options:

=over 4

=item B<file> => I<filename>

A filename in the current working directory, or a path to the file that
will (eventually) be created. By default, the temporary file will be
written into the parent directory of the B<file> path. This default can
be changed by using the B<tmpdir> option.

If the B<MKPATH> option is true, the module will attempt to create any
missing directories. If the B<MKPATH> option is false or not set, the
module will throw an error should any parent directories of the B<file>
not exist.

=item B<input> => I<scalar ref or filehandle>

Mandatory for the B<write_file> method, illegal for the B<new> method.
Scalar reference, or otherwise some filehandle reference that can be
looped over via C<readline>. Supplies the data to be written to B<file>.

=back

Optional options:

=over 4

=item B<backup> => I<suffix>

Make a backup with this (non-empty) suffix. The backup is always
created, even if there was no change. If a previous backup existed, it
is deleted first. Usual throwing of error.

=item B<BINMODE> => I<true or false>

If true, C<binmode> is set on the temporary filehandle prior to
writing the B<input> data to it. Default is not to set C<binmode>.

=item B<binmode_layer> => I<LAYER>

Supply a C<LAYER> argument to C<binmode>. Enables B<BINMODE>.

  # just binmode (binary data)
  ...->write_file({ ..., BINMODE => 1 });

  # custom binmode layer
  ...->write_file({ ..., binmode_layer => ':utf8' });

=item B<checksum> => I<sha1 hexdigest>

If this option exists, and B<CHECKSUM> is true, the module will not
create a L<Digest::SHA1> C<hexdigest> of the data being written out to
disk, but instead will rely on the value passed by the caller.

Only for the B<write_file> interface; instead call the B<checksum>
method to supply a C<hexdigest> checksum of the data written when using
the instance interface; see the L</SYNOPSIS> for an example of this.

=item B<CHECKSUM> => I<true or false>

If true, L<Digest::SHA1> will be used to checksum the data read back
from the disk against the checksum derived from the data written out to
the temporary file.

Use the B<checksum> option (or B<checksum> method) to supply a
L<Digest::SHA1> C<hexdigest> checksum. This will spare the module the
task of computing the checksum on the data being written.

Only for the B<write_file> interface.

=item B<min_size> => I<size>

Specify a minimum size (in bytes) that the data written must
exceed. If not, the module throws an error. (It was a process that
wrote out a zero-sized C</etc/passwd> file that prompted the
creation of this module.)

=item B<MKPATH> => I<true or false>

If true, attempt to create the parent directories of B<file> should that
directory not exist. If false (or unset), and the parent directory does
not exist, the module throws an error. If the directory cannot be
created, the module throws an error.

If true, this option will also attempt to create the B<tmpdir>
directory, if that option is set.

=item B<mode> => I<unix mode>

Accepts a Unix mode for C<chmod> to be applied to the file. Usual
throwing of error. If the mode is a string starting with C<0>,
C<oct> is used to convert it:

  my $orig_mode = (stat $source_file)[2] & 07777;
  ...->write_file({ ..., mode => $orig_mode });

  my $mode = '0644';
  ...->write_file({ ..., mode => $mode });

The module does not change C<umask>, nor is there a means to specify
the permissions on directories created if B<MKPATH> is set.

=item B<mtime> => I<mtime>

Accepts C<mtime> timestamp for C<utime> to be applied to the file.
Usual throwing of error.

=item B<owner> => I<unix ownership string>

Accepts similar arguments to chown(1) to be applied via C<chown>
to the file. Usual throwing of error.

  ...->write_file({ ..., owner => '0'   });
  ...->write_file({ ..., owner => '0:0' });
  ...->write_file({ ..., owner => 'user:somegroup' });

=item B<safe_level> => I<safe_level value>

Optional means to set the L<File::Temp> module C<safe_level> value.
Consult the L<File::Temp> documentation for more information on
this option.

This value can also be set via the B<safe_level> class method.

=item B<template> => I<File::Temp template>

Template to supply to L<File::Temp>. Defaults to a reasonable value if
unset. NOTE: if customized, the template must contain a sufficient
number of C<X> that suffix the template string, as otherwise
L<File::Temp> will throw an error.

Can also be set via the B<set_template> class method.

=item B<tmpdir> => I<directory>

If set to a directory, the temporary file will be written to this
directory instead of by default to the parent directory of the target
B<file>. If the B<tmpdir> is on a different partition than the parent
directory for B<file>, or if anything else goes awry, the module will
throw an error: rename(2) does not operate across partition boundaries.

This option is advisable when writing files to include directories such
as C</etc/logrotate.d>, as the programs that read include files from
these directories may read even a temporary dot file while it is being
written. To avoid this (slight but non-zero) risk, use the B<tmpdir>
option to write the configuration out in full under a different
directory on the same partition.

=back

=head1 BUGS

No known bugs (lots of potential issues, though, see below).

=head2 Reporting Bugs

L<http://github.com/thrig/File-AtomicWrite>

=head2 Known Issues

See L<perlport> for various portability problems possible with the
C<rename> call. Consult L<rename(2)> or equivalent for caveats. Note
however that L<rename(2)> is used heavily by common programs such as
L<mv(1)> and C<rsync>.

File hard links created by L<ln(1)> will be broken by this module, as
this module has no way of knowing whether any other files link to the
inode of the file being operated on:

  % touch afile
  % ln afile afilehardlink
  % ls -i afile*
  3725607 afile         3725607 afilehardlink
  % perl -MFile::AtomicWrite -e \
    'File::AtomicWrite->write_file({file =>"afile",input=>\"foo"})'
  % ls -i afile*
  3725622 afile         3725607 afilehardlink

Union or bind mounts might also be a problem, if what is actually some
other filesystem is present between the temporary and final file
locations.

Some filesystems may also require a fsync call on a filehandle of the
directory containing the file (see fsync(2) on RHEL, for example), to
ensure that the directory data also reaches disk, in addition to the
contents of the file. Certain filesystem options may also need to be
set, such as C<data=journal> or C<data=ordered> on ext3, so that any
crashes or unexpected glitches have less chance of unanticipated
problems (such as the file write being ordered after the rename).

Renames may strip fancy ACL or selinux contexts.

=head1 SEE ALSO

Supporting modules:

L<Digest::SHA1>, L<File::Basename>, L<File::Path>, L<File::Temp>

This isn't easy:

L<http://danluu.com/file-consistency/>

L<https://homes.cs.washington.edu/~lijl/papers/ferrite-asplos16.pdf>

L<https://unix.stackexchange.com/questions/464382>

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

C<mtime> and other features contributed by Stijn De Weirdt.

=head1 COPYRIGHT

Copyright (C) 2009-2016,2018 Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

=cut
