package File::Tail::Inotify2;

use 5.008008;
use strict;
use warnings;
use Linux::Inotify2;
use File::Basename qw(dirname);
use Fcntl qw(SEEK_SET SEEK_END);
use Carp ();

our $VERSION = '1.02';

use constant {
    FMASK => IN_MODIFY | IN_MOVE_SELF,
    DMASK => IN_CREATE | IN_MOVED_FROM | IN_MOVED_TO,
};

sub new {
    my $class = shift;
    my %args  = (
        file    => undef,
        on_read => undef,
        @_,
    );

    for (qw(file on_read)) {
        Carp::croak "Mandatory parameter $_ was missing."
            unless $args{$_};
    }

    unless ( ref $args{on_read} && ref $args{on_read} eq 'CODE' ) {
        Carp::croak "on_read must be CODE";
    }

    my $inotify = Linux::Inotify2->new
        or Carp::croak "Cannot create Inotify2 object: $!";

    my $self = bless {
        file    => $args{file},
        on_read => $args{on_read},
        curpos  => 0,
        in_move => 0,
        inotify => $inotify,
        },
        ref $class || $class;

    $self->_set_watcher;

    return $self;
}

sub poll {
    my $self = shift;
    1 while $self->{inotify}->poll || $self->{in_move};
}

sub _set_watcher {
    my $self = shift;
    $self->_set_file_watcher;
    $self->_set_dir_watcher;
}

sub _set_file_watcher {
    my $self = shift;
    my $size = (stat $self->{file})[7];
    $self->{curpos} = $size;
    $self->{inotify}->watch( $self->{file}, FMASK, $self->_in_modify );
}

sub _in_modify {
    my $self = shift;
    return sub {
        my $event = shift;
        if ( $event->IN_MODIFY ) {
            open my $fh, '<', $event->fullname
                or Carp::croak "Cannot open " . $event->fullname . ": $!";
            seek $fh, $self->{curpos}, SEEK_SET;

            while (<$fh>) {
                $self->{on_read}->($_);
            }

            $self->{curpos} = tell $fh;
            close $fh
                or Carp::croak "Cannot close " . $event->fullname . ": $!";
        }
        if ( $event->IN_MOVE_SELF ) {
            $event->w->cancel;
        }
    };
}

sub _set_dir_watcher {
    my $self = shift;
    $self->{inotify}->watch(
        dirname( $self->{file} ),
        DMASK,
        sub {
            my $event = shift;
            if ( $event->IN_MOVED_FROM && $event->fullname eq $self->{file} ) {
                $self->{in_move} = 1;
            }
            if ( ($event->IN_CREATE || $event->IN_MOVED_TO) && $event->fullname eq $self->{file} ) {
                $self->{curpos} = (stat $event->fullname)[7];
                $self->_set_file_watcher;
                $self->{in_move} = 0;
            }
        }
    );
}

1;
__END__

=head1 NAME

File::Tail::Inotify2 - Simple interface to tail a file using inotify.

=head1 SYNOPSIS

    use File::Tail::Inotify2;
    my $watcher = File::Tail::Inotify2->new(
        file    => $filename,
        on_read => sub {
            my $line = shift;
            print $line;
        }
    );
    $watcher->poll;

=head1 DESCRIPTION

Yet another module to tail a file. Even if the file are renamed by
logrotate(8), this module tail a new file created by logrotate(8).

=head1 WARNINGS

This module works on Linux. Other OS are not supported.

=head1 METHOD

=over 4

=item $watcher = File::Tail::Inotify2->new( file => $filename, on_read => $cb->($read_line) )

Returns a File::Tail::Inotify2 object. If C<$filename> is modified, C<$cb-E<gt>($read_line)> is called per line.

=item $watcher->poll

Starts watching a file and will never exit.

=back

=head1 SEE ALSO

L<Linux::Inotify2>, L<File::Tail>, L<File::SmartTail>, L<Tail::Tool>

=head1 AUTHOR

Yoshihiro Sasaki, E<lt>ysasaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Yoshihiro Sasaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

# vim: set ts=4 sw=4 tw=78 expandtab:
