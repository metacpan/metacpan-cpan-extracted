###########################################################################
#
# File/Rotate.pm
#
# Copyright (c) 2000 Raphael Manfredi.
# Copyright (c) 2002-2015 Mark Rogaski, mrogaski@cpan.org;
# all rights reserved.
#
# See the README file included with the
# distribution for license information.
#
###########################################################################

use strict;

###########################################################################
package Log::Agent::File::Rotate;

#
# A rotating logfile set
#

use File::stat;
use Fcntl;
use Symbol;
use Compress::Zlib;
require LockFile::Simple;

use Log::Agent; # We're using logerr() ourselves when safe to do so

my $DEBUG = 0;

#
# ->make
#
# Creation routine.
#
# Attributes initialized by parameters:
#    path     file path
#    config   rotating configuration (a Log::Agent::Rotate object)
#
# Other attributes:
#    fd       currently opened file descriptor
#    handle   symbol used for Perl handle
#    warned   records calls made to hardwired warn() to only do them once
#    written  total amount written since opening
#    size     logfile size
#    opened   time when opening occurred
#    dev      device holding logfile
#    ino      inode number of logfile
#    lockmgr  lockfile manager
#    rotating within the rotate() routine
#
sub make {
    my $self = bless {}, shift;
    my ($path, $config) = @_;
    $self->{'path'} = $path;
    $self->{'config'} = $config;
    $self->{'fd'} = undef;
    $self->{'handle'} = gensym;
    $self->{'warned'} = {};
    $self->{'rotating'} = 0;
    $self->{'lockmgr'} = LockFile::Simple->make(
        -autoclean => 1,
        -delay     => 1,        # until sleep(.25) is supported
        -efunc     => undef,
        -hold      => 60,
        -max       => 5,
        -nfs       => !$config->single_host,
        -stale     => 1,
        -warn      => 0,
        -wfunc     => undef
    );
    return $self;
}

#
# Attribute access
#

sub path     { $_[0]->{'path'} }
sub config   { $_[0]->{'config'} }
sub fd       { $_[0]->{'fd'} }
sub handle   { $_[0]->{'handle'} }
sub warned   { $_[0]->{'warned'} }
sub written  { $_[0]->{'written'} }
sub opened   { $_[0]->{'opened'} }
sub size     { $_[0]->{'size'} }
sub dev      { $_[0]->{'dev'} }
sub ino      { $_[0]->{'ino'} }
sub lockmgr  { $_[0]->{'lockmgr'} }
sub rotating { $_[0]->{'rotating'} }

#
# ->print
#
# Print to file.
# This is where all the monitoring is performed:
#
# . If the file was renamed underneath us, re-open it.
#   This costs a stat() system call each time a log is to be emitted
#   and can be avoided by setting config->is_alone.
#
sub print {
    my $self = shift;
    my $str = join('', @_);

    my $fd = $self->fd;
    my $cf = $self->config;

    #
    # If the file was renamed underneath us, re-open it.
    # This costs a stat() system call each time a log is to be emitted
    # and can be avoided by setting config->is_alone when appropriate.
    #

    if (defined $fd && !$cf->is_alone) {
        my $st = stat($self->path);
        if (!$st || $st->dev != $self->dev || $st->ino != $self->ino) {
            $self->close;
            undef $fd;  # Will be re-opened below
        }
    }

    #
    # Open file if not already done.
    #

    unless (defined $fd) {
        $fd = $self->open;
        return unless defined $fd;
    }

    #
    # Write to logfile
    #

    return unless syswrite($fd, $str, length $str);

    #
    # If the overall logfile size is monitored, update it.
    # Unless we're alone, we have to fstat() the file descriptor.
    #

    if ($cf->max_size) {
        if ($cf->is_alone) {
            $self->{'size'} += length $str;
        } else {
            my $st = stat($fd);
            if ($st) {
                $self->{'size'} = $st->size;    # Paranoid test
            } else {
                $self->{'size'} += length $str;
            }
        }
        if ($self->size > $cf->max_size) {
            $self->rotate;
            return;
        }
    }

    #
    # If the amount of bytes written exceeds the threshold,
    # rotate the files.
    #

    if ($cf->max_write) {
        $self->{'written'} += length $str;
        if ($self->written > $cf->max_write) {
            $self->rotate;
            return;
        }
    }

    #
    # If the opening time is exceeded, rotate the files.
    #

    if ($cf->max_time) {
        if (time - $self->opened > $cf->max_time) {
            $self->rotate;
            return;
        }
    }

    # Did not rotate anything
    return;
}

#
# ->open
#
# Open current logfile.
# Returns opened handle, or nothing if error.
#
sub open {
    my $self = shift;
    my $fd = $self->handle;
    my $path = $self->path;
    my $mode = O_CREAT|O_APPEND|O_WRONLY;
    my $perm = ($self->config)->file_perm;
    warn "opening $path\n" if $DEBUG;

    unless (sysopen($fd, $path, $mode, $perm)) {
        #
        # Can't log errors via Log::Agent since we might recurse down here.
        # Therefore, use warn(), but only once, and clear condition when
        # opening is successful.
        #

        warn "$0: can't open logfile \"$path\": $!\n"
                unless $self->warned->{$path}++;
        return;
    }

    my $st = stat($fd);                         # An fstat(), really
    $self->warned->{$path} = 0;                 # Clear warning condition
    $self->{'fd'} = $fd;                        # Records: file opened
    $self->{'written'} = 0;                     # Amount written
    $self->{'opened'} = time;                   # Opening time
    $self->{'size'} = $st ? $st->size : 0;      # Current size
    $self->{'dev'} = $st->dev;
    $self->{'ino'} = $st->ino;

    return $fd;
}

#
# ->close
#
# Close current logfile.
#
sub close {
    my $self = shift;
    my $fd = $self->fd;
    return unless defined $fd;  # Already closed
    warn "closing logfile\n" if $DEBUG;
    close($fd);
    $self->{'fd'} = undef;      # Mark as closed
}

#
# ->rotate
#
# Perform logfile rotation, as configured, and log any returned error
# to the error channel.
#
sub rotate {
    my $self = shift;
    return if $self->rotating;  # no recusion if error & limits too small
    $self->{'rotating'} = 1;

    my @errors = $self->do_rotate;
    unless (@errors) {
        $self->{'rotating'} = 0;
        return;
    }

    #
    # Errors are logged using logerr().  There's no danger we could
    # recurse down here since we're protected by the `rotating' flag.
    #

    my $error = @errors == 1 ? "error" : sprintf("%d errors", scalar @errors);
    logerr "the following $error occurred while rotating logfiles:";
    foreach my $err (@errors) {
        logerr $err;
        warn "ERROR: $err\n" if $DEBUG;
    }

    $self->{'rotating'} = 0;
}

#
# ->do_rotate
#
# Perform logfile rotation, as configured.
# Returns nothing if OK, an array of error messages otherwise.
#
sub do_rotate {
    my $self = shift;
    my $path = $self->path;
    my $cf = $self->config;
    my $lock = $self->lockmgr->lock($path);

    #
    # Emission of errors has to be delayed, since we're in the middle of
    # logfile rotation, which could be the error channel.
    #

    my @errors = ();

    push(@errors, "proceeded with rotation of $path without lock")
            unless defined $lock;

    #
    # We're unix-centric in the following code fragment, but I don't know
    # how to do the same thing on non-unix operating systems.  Sorry.
    #

    my ($dir, $file) = ($path =~ m|^(.*)/(.*)|);
    ($dir, $file) = (".", $path) unless $dir;

    local *DIR;
    unless (opendir(DIR, $dir)) {
        my $error = "can't open directory \"$dir\" to rotate $path: $!";
        $lock->release if defined $lock;
        return ($error);
    }
    my @files = readdir DIR;
    closedir DIR;

    #
    # Identify the logfiles already present.
    #
    # We use the common convention of renaming un-compressed logfiles
    # as "path.0", "path.1", etc... the .0 being the more recent file,
    # and use "path.0.gz", "path.1.gz", etc... for compressed logfiles.
    #

    my @logfiles = ();  # Logfiles to rotate
    my @unlink = ();    # Logfiles to unlink
    my $lookfor = "$file.";
    my $unlink_at = $cf->backlog - 1;

    warn "unlink_at=$unlink_at\n" if $DEBUG;

    foreach my $f (@files) {
        next unless substr($f, 0, length $lookfor) eq $lookfor;
        my ($idx) = ($f =~ /\.(\d+)(?:\.gz)?$/);
        warn "f=$f, idx=$idx\n" if $DEBUG;
        next unless defined $idx;
        $f = $1 if $f =~ /^(.*)$/; # untaint
        if ($idx >= $unlink_at) {
            push(@unlink, $f);
        } else {
            $logfiles[$idx] = $f;
        }
    }

    if ($DEBUG) {
        warn "unlink=@unlink\n";
        warn "logfiles=@logfiles\n";
    }

    #
    # Delete old files, if any.
    #

    foreach my $f (@unlink) {
        unlink("$dir/$f") or push(@errors, "can't unlink $dir/$f: $!");
    }

    #
    # File rotation section...
    #
    # If backlog=5 and unzipped=2, then, when things have stabilized,
    # we have the following logfiles:
    #
    #   path.4.gz        was unlinked above
    #   path.3.gz        renamed as path.4.gz
    #   path.2.gz        renamed as path.3.gz
    #   path.1           compressed as path.2.gz
    #   path.0           renamed as path.1
    #   path             current logfile, closed and renamed path.0
    #
    # The code below is prepared to deal with missing files, or policy
    # changes. Compressed file are not uncompressed though.
    #

    my $last = $cf->backlog - 2;   # Oldest logfile already deleted
    my $gz_limit = $cf->unzipped;  # Files up to that index are .gz

    warn "last=$last, gz_limit=$gz_limit\n" if $DEBUG;

    #
    # Handle renaming of compressed files
    #

    for (my $i = $last; $i >= $gz_limit; $i--) {
        next unless defined $logfiles[$i]; # Not that much backlog yet?
        my $old = "$dir/$logfiles[$i]";
        my $new = "$path." . ($i+1) . ".gz";
        warn "compressing old=$old, new=$new\n" if $DEBUG;
        if ($old =~ /\.gz$/) {
            rename($old, $new) or
                    push(@errors, "can't rename $old to $new: $!");
        } else {
            # Compression policy changed?
            my $err = $self->mv_gzip($old, $new);
            push(@errors, $err) if defined $err;
        }
    }

    #
    # Handle compression and renaming of the oldest uncompressed file
    #

    if ($gz_limit > 0 && defined $logfiles[$gz_limit-1]) {
        my $old = "$dir/$logfiles[$gz_limit-1]";
        my $new = "$path.$gz_limit.gz";
        warn "rename and compress old=$old, new=$new\n" if $DEBUG;
        if ($old !~ /\.gz$/) {
            my $err = $self->mv_gzip($old, $new);
            push(@errors, $err) if defined $err;
        } else {
            # Compression policy changed?
            rename($old, $new) or
            push(@errors, "can't rename $old to $new: $!");
        }
    }

    #
    # Handle renaming of uncompressed files
    #

    for (my $i = $gz_limit - 2; $i >= 0; $i--) {
        next unless defined $logfiles[$i]; # Not that much backlog yet?
        my $old = "$dir/$logfiles[$i]";
        my $new = "$path." . ($i+1);
        warn "rename old=$old, new=$new\n" if $DEBUG;
        $new .= ".gz" if $old =~ /\.gz$/;  # Compression policy changed?
        rename($old, $new) or
                push(@errors, "can't rename $old to $new: $!");
    }

    #
    # Mark rotation, in case they "tail -f" on it.
    #

    my $fd = $self->fd;
    syswrite($fd, "*** LOGFILE ROTATED ON " . scalar(localtime) . "\n");

    #
    # Finally, close current logfile and rename it.
    #

    $self->close;
    if ($gz_limit) {
        rename($path, "$path.0") or
                push(@errors, "can't rename $path to $path.0: $!");
    } else {
        my $err = $self->mv_gzip($path, "$path.0.gz");
        push(@errors, $err) if defined $err;
    }

    #
    # Unlock logfile and propagate errors to be logged in new current file.
    #

    $lock->release if defined $lock;
    return @errors if @errors;
    return;
}

#
# ->mv_gzip
#
# Compress old file into new file and unlink old file, propagating mtime.
# Returns error string, nothing if OK.
#
sub mv_gzip {
    my $self = shift;
    my ($old, $new) = @_;

    local *FILE;
    my $st = stat($old);
    unless (defined $st && CORE::open(FILE, $old)) {
        return "can't open $old to compress into $new: $!";
    }
    my $gz = gzopen($new, "wb9");
    unless (defined $gz) {
        CORE::close FILE;
        return "can't write into $new: $gzerrno";
    }

    local $_;
    my $error;
    while (<FILE>) {
        unless ($gz->gzwrite($_)) {
            $error = "error while compressing $old in $new: $gzerrno";
            last;
        }
    }
    CORE::close FILE;
    $gz->gzclose();

    utime $st->atime, $st->mtime, $new; # don't care if it fails
    unlink $old or do { $error = "can't unlink $old: $!" };

    return $error if defined $error;
    return;
}

1; # for require

__END__

=head1 NAME

Log::Agent::File::Rotate - a rotating logfile set

=head1 SYNOPSIS

 #
 # This class is not user-visible.
 #
 # It is documented only for programmers wishing to inherit
 # from it to further extend its behaviour.
 #

 require Log::Agent::Driver::File;
 require Log::Agent::Rotate;
 require Log::Agent::File::Rotate;

 my $config = Log::Agent::Rotate->make(...);
 my $driver = Log::Agent::Driver::File->make(...);
 my $fh = Log::Agent::File::Rotate->make("file", $config, $driver);

=head1 DESCRIPTION

This class represents a rotating logfile and is used drivers wishing
to rotate their logfiles periodically.  From the outside, it exports
a single C<print> routine, just like C<Log::Agent::File::Native>.

Internally, it uses the parameters given by a C<Log::Agent::Rotate> object
to transparently close the current logfile and cycle the older logs.

Before rotating the current logfile, the string:

    *** LOGFILE ROTATED ON <local date>

is emitted, so that people monitoring the file via "tail -f" know about
it and are not surprised by the sudden stop of messages.

Its exported interface is:

=over 4

=item make I<file>, I<config>

This is the creation routine.  The I<config> object is an instance of
C<Log::Agent::Rotate>.

=item print I<args>

Prints I<args> to the file.  After having printed the data, monitor the file
against the thresholds defined in the configuration, and possibly rotate
the logfiles according to the parameters held in the same configuration
object.

When the C<is_alone> flag is not set in the configuration, the logfile is
checked everytime a C<print> is issued to see if its inode changed.  Indeed,
when several instances of the same program using rotating logfiles are
running, each of them may decide to cycle the logs at some point in time, and
therefore our opened handle could point to an already renamed or unlinked file.

=back

=head1 AUTHORS

Originally written by Raphael Manfredi E<lt>Raphael_Manfredi@pobox.comE<gt>,
currently maintained by Mark Rogaski E<lt>mrogaski@pobox.comE<gt>.

=head1 SEE ALSO

Log::Agent::Rotate(3), Log::Agent::Driver::File(3).

=cut
