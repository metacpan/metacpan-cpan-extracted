package ExclusiveLock::Guard;
use strict;
use warnings;
our $VERSION = '0.07';

use Errno qw(EWOULDBLOCK);
use Fcntl qw(LOCK_EX LOCK_NB LOCK_UN);
use File::stat;

my $ERRSTR;

sub errstr { $ERRSTR }

sub new {
    my($class, $filename, %args) = @_;
    my $retry_count = $args{retry_count} || 5;

    my $fh;
    my $count = 0;
    my $is_locked = 1;
    while (1) {
        $ERRSTR = undef;
        $is_locked = 1;
        unless (open $fh, '>', $filename) {
            $ERRSTR = "failed to open file:$filename:$!";
            return;
        }
        if ($args{nonblocking}) {
            unless (flock $fh, LOCK_EX | LOCK_NB) {
                if ($! != EWOULDBLOCK) {
                    $ERRSTR = "failed to flock file:$filename:$!";
                    return;
                }
                $is_locked = 0;
            }
        } else {
            unless (flock $fh, LOCK_EX) {
                $ERRSTR = "failed to flock file:$filename:$!";
                return;
            }
        }
        unless (-f $filename && stat($fh)->ino == do { my $s = stat($filename); $s ? $s->ino : -1 }) {
            unless (flock $fh, LOCK_UN) {
                $ERRSTR = "failed to unlock flock file:$filename:$!";
                return;
            }
            unless (close $fh) {
                $ERRSTR = "failed to close file:$filename:$!";
                return;
            }
            if ($retry_count && ++$count > $retry_count) {
                $ERRSTR = "give up! $retry_count times retry to lock.";
                return;
            }
            next;
        }
        last;
    }

    bless {
        filename  => $filename,
        fh        => $fh,
        is_locked => $is_locked,
    }, $class;
}

sub is_locked { $_[0]->{is_locked} }

sub DESTROY {
    my $self = shift;
    return unless $self->{is_locked};

    my $fh       = delete $self->{fh};
    my $filename = delete $self->{filename};
    unless (close $fh) {
        warn "failed to close file:$filename:$!";
        return;
    }

    # try unlink lock file
    if (open my $unlink_fh, '<', $filename) { # else is unlinked lock file by another process?
        # A
        if (flock $unlink_fh, LOCK_EX | LOCK_NB) { # else is locked the file by another process
            if (-f $filename && stat($unlink_fh)->ino == do { my $s = stat($filename); $s ? $s->ino : -1 }) { # else is unlink and create file by another process in the A timing
                unless (unlink $filename) {
                    warn "failed to unlink file:$filename:$!";
                }
                unless (flock $unlink_fh, LOCK_UN) {
                    warn "failed to unlock flock file:$filename:$!";
                }
                unless (close $unlink_fh) {
                    warn "failed to close file:$filename:$!";
                }
            }
        }
    }
}

1;
__END__

=head1 NAME

ExclusiveLock::Guard - lexically-scoped lock management

=head1 SYNOPSIS

    use ExclusiveLock::Guard;

    sub blocking_transaction {
        my $lock = ExclusiveLock::Guard->new('/tmp/foo.lock')
            or die 'lock error: ' . ExclusiveLock::Guard->errstr;
        # inner of lock
    }
    blocking_transaction();
    # outer of lock

for non-blocking

    sub nonblocking_transaction {
        my $lock = ExclusiveLock::Guard->new('/tmp/foo.lock', nonblocking => 1 )
            or die 'lock error: ' . ExclusiveLock::Guard->errstr;
        unless ($lock->is_locked) {
            warn 'is locked';
            return;
        }

        # inner of lock
    }
    nonblocking_transaction();
    # outer of lock

=head1 DESCRIPTION

ExclusiveLock::Guard is very simple lock maneger.
To automatically create and remove the lock file.

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo {at} shibuya {dot} plE<gt>

=head1 COPYRIGHT

Copyright 2012- Kazuhiro Osawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
