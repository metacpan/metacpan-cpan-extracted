package Log::File::Rolling;

use 5.006001;
use strict;
use warnings;

use Time::Piece;
use Fcntl ':flock'; # import LOCK_* constants

our $VERSION = '0.101';



sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my %p = @_;

    my $self = bless {}, $class;

    # base class initialization
    #$self->_basic_init(%p);

    $self->{timezone} = $p{timezone} || 'gmtime';
    die "unsupported timezone: '$self->{timezone}' (currently must be 'localtime' or 'gmtime')"
        if $self->{timezone} ne 'localtime' && $self->{timezone} ne 'gmtime';

    $self->{filename_format} = $p{filename};

    if (exists $p{current_symlink}) {
        $self->{current_symlink} = $p{current_symlink};
    }

    $self->{rolling_fh_pid} = $$;
    $self->_createFilename();
    $self->_rolling_open_file();

    return $self;
}

sub log { # parts borrowed from Log::Dispatch::FileRotate, Thanks!
    my $self = shift;
    my $message = shift;

    if ($self->_createFilename()) {
        $self->{rolling_fh_pid} = 'x'; # force reopen
    }

    if (defined $self->{fh} and ($self->{rolling_fh_pid}||'') eq $$ and defined fileno $self->{fh}) { # flock won't work after a fork()
        my $inode  = (stat($self->{fh}))[1];         # get real inode
        my $finode = (stat($self->{filename}))[1];   # Stat the name for comparision
        if(!defined($finode) || $inode != $finode) { # Oops someone moved things on us. So just reopen our log
            $self->_rolling_open_file;
        } elsif (!$self->{current_symlink_inited}) {
            $self->_update_current_symlink;
        }
        $self->_lock();
        my $fh = $self->{fh};
        print $fh $message;
        $self->_unlock();
    } else {
        $self->{rolling_fh_pid} = $$;
        $self->_rolling_open_file;
        $self->_lock();
        my $fh = $self->{fh};
        print $fh $message;
        $self->_unlock();
    }
}

sub _rolling_open_file {
    my $self = shift;

    open my $fh, '>>:raw', $self->{filename}
        or die "Cannot write to '$self->{filename}': $!";
    $self->{fh} = $fh;

    $self->_update_current_symlink;
}

sub _update_current_symlink {
    my $self = shift;

    return if !exists $self->{current_symlink};

    my $current_symlink_value = readlink($self->{current_symlink});

    if (!defined $current_symlink_value || $current_symlink_value ne $self->{filename}) {
        my $temp_symlink_file = "$self->{current_symlink}.temp$$";
        unlink($temp_symlink_file);

        symlink($self->{filename}, $temp_symlink_file)
            || die "unable to create symlink '$temp_symlink_file': $!";

        if (!rename($temp_symlink_file, $self->{current_symlink})) {
            unlink($temp_symlink_file);
            die "unable to overwrite symlink '$self->{current_symlink}': $!";
        }
    }

    $self->{current_symlink_inited} = 1;
}

sub _lock { # borrowed from Log::Dispatch::FileRotate, Thanks!
    my $self = shift;
    flock($self->{fh},LOCK_EX);
    # Make sure we are at the EOF
    seek($self->{fh}, 0, 2);
    return 1;
}

sub _unlock { # borrowed from Log::Dispatch::FileRotate, Thanks!
    my $self = shift;
    flock($self->{fh},LOCK_UN);
    return 1;
}


## Returns true if the filename changed
sub _createFilename {
    my $self = shift;

    my $time = time();
    return 0 if defined $self->{current_filename_time} && $time == $self->{current_filename_time};

    $self->{filename} = Time::Piece->${\$self->{timezone}}->strftime($self->{filename_format});
    $self->{current_filename_time} = $time;
    return 1;
}

1;




__END__


=encoding utf-8

=head1 NAME

Log::File::Rolling - Log to date/time-stamped files

=head1 SYNOPSIS

  use Log::File::Rolling;

  my $logger = Log::File::Rolling->new(
                   filename => 'myapp.%Y-%m-%d.log',
                   current_symlink => 'myapp.log.current',
                   timezone => 'localtime',
               );

  $logger->log("My log message\n");

=head1 ABSTRACT

This module provides an object for logging to files. The log file will be "rolled" over to the next file whenever the filename changes according to the C<filename> format parameter. When this occurs, an optional C<current_symlink> file will be pointed to the current file.

=head1 DESCRIPTION

This module was forked from the L<Log::Dispatch::File::Rolling> to add the symlink feature and fix a few other minor issues (see the C<Changes> file for details).

Similar to the original, this module should also have these properties:

=over 4

=item fork()-safe

This module will close and re-open the logfile after a fork.

=item multitasking-safe

This module uses flock() to lock the file while writing to it.

=item stamped filenames

This module's "stamped" filenames are rendered with L<Time::Piece>'s C<strftime> function. By default it uses C<gmtime> for UTC timestamps, but this can be changed by passing C<localtime> into the constructor's C<timezone> parameter (see the synopsis).

B<NOTE>: Because of a caching optimisation, files should not be rotated more often than once per second.

=item current symlinks

If you pass in C<current_symlink> to the constructor, it will create a symlink at your provided filename. This symlink will always link to the most recent log file. You can then use C<tail -F> to monitor an application's logs with no interruptions even when the filename rolls over.

=back

=head1 METHODS

=over 4

=item new()

Constructs an object. An empty file will be created at this point.

=item log()

Takes a message as an argument which will be stringified and appended to the current file.

=back

=head1 SEE ALSO

L<The Log-File-Rolling github repo|https://github.com/hoytech/Log-File-Rolling>

L<Log::Dispatch::File::Rolling>

Looking for functionality like log-levels and message time-stamping? Check out L<Log::Defer>.

=head1 AUTHOR

M. Jacob, E<lt>jacob@j-e-b.netE<gt>

This module was forked from L<Log::Dispatch::File::Rolling> by Doug Hoyte.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003, 2004, 2007, 2010, 2013 M. Jacob E<lt>jacob@j-e-b.netE<gt>, 2016 Doug Hoyte

Based on:

  Log::Dispatch::File::Stamped by Eric Cholet <cholet@logilune.com>
  Log::Dispatch::FileRotate by Mark Pfeiffer, <markpf@mlp-consulting.com.au>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
