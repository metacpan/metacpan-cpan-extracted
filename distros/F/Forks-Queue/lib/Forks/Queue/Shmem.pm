package Forks::Queue::Shmem;
use base 'Forks::Queue::File';
use strict;
use warnings;
use Carp;

our $VERSION = '0.06';
our $DEV_SHM = "/dev/shm";
our $DEBUG;
*DEBUG = \$Forks::Queue::DEBUG;

sub new {
    my $class = shift;
    my %opts = (%Forks::Queue::OPTS, @_);

    if (! -d $DEV_SHM) {
        croak "\$DEV_SHM not set to a valid shared memory virtual filesystem";
    }

    if ($opts{file}) {
        $opts{loc} //= $opts{file};
        $opts{loc} =~ s{.*/(.)}{$1};
        $opts{loc} =~ s{/+$}{};
        $opts{file} = "$DEV_SHM/" . $opts{loc};
    } else {
        $opts{file} = _impute_file();
    }

    $opts{lock} = $opts{file} . ".lock";
    $opts{limit} //= -1;
    $opts{on_limit} //= 'fail';
    $opts{style} //= 'fifo';
    my $list = delete $opts{list};

    my $fh;

    $opts{_header_size} //= 2048;
    $opts{_end} = 0;            # whether "end" has been called for this obj
    $opts{_pos} = 0;		# "cursor", index of next item to shift out
    $opts{_tell} = $opts{_header_size};        # file position of cursor

    $opts{_count} = 0;          # index of next item to be appended
    $opts{_pids} = { $$ => 'P' };

    # how often to refactor the queue file. use small values to keep file
    # sizes small and large values to improve performance
    $opts{_maintenance_freq} //= 32;

    open $fh, '>>', $opts{lock} or die;
    close $fh or die;

    my $self = bless { %opts }, $class;

    if ($opts{join} && -f $opts{file}) {
        $DB::single = 1;
        open $fh, '+<', $opts{file} or die;
        $self->{_fh} = *$fh;
        my $fhx = select $fh; $| = 1; select $fhx;
        Forks::Queue::File::_SYNC { $self->_read_header } $self;
    } else {
        if (-f $opts{file}) {
            carp "Forks::Queue: Queue file $opts{file} already exists. ",
                 "Expect trouble if another process created this file.";
        }
        open $fh, '>>', $opts{file} or die;
        close $fh or die;

        open $fh, '+<', $opts{file} or die;

        my $fx = select $fh;
        $| = 1;
        select $fx;

        $self->{_fh} = *$fh;
        seek $fh, 0, 0;

        $self->{_locked}++;
        $self->_write_header;
        $self->{_locked}--;
        if (tell($fh) < $self->{_header_size}) {
            print $fh "\0" x ($self->{_header_size} - tell($fh));
        }
    }
    if (defined($list)) {
        if (ref($list) eq 'ARRAY') {
            $self->push( @$list );
        } else {
            carp "Forks::Queue::new: 'list' option must be an array ref";
        }
    }
    return $self;
}

my $id = 0;
sub _impute_file {
    my $base = $0;
    $base =~ s{.*[/\\](.)}{$1};
    $base =~ s{[/\\]$}{};
    $id++;
    return "$DEV_SHM/shmq-$$-$id-$base";
}

1;

=head1 NAME

Forks::Queue::Shmem - Forks::Queue implementation using shared memory

=head1 SYNOPSIS

    use Forks::Queue::Shmem;
    $q = Forks::Queue::Shmem->new;

    use Forks::Queue;
    $q = Forks::Queue->new( impl => 'Shmem, ... );

=head1 VERSION

0.06

=head1 DESCRIPTION

Shared memory implementation of L<Forks::Queue|Forks::Queue>.
Only available on systems that have a C</dev/shm> virtual filesystem.

A shared memory implementation is appropriate for programs that
rapidly update the queue but are not likely to let the size of data
in the queue exceed the available memory on the host machine.
Use L<Forks::Queue::File> if you demand high capacity for your queue.

See L<Forks::Queue> for the public API to this class.

=head2 Constructor options

In addition to the standard options described in
L<the Forks::Queue constructor|Forks::Queue/"new">, the
C<Forks::Queue::Shmem> constructor also recognizes some
additional options:

=over 4

=item * file

The name of the filename to hold the queue data. An absolute
pathname should not be provided here. The virtual queue file
will reside under the shared memory virtual filesystem
(probably C</dev/shm>) on your system, if it exists.

=item * style

=item * limit

=item * on_limit

=item * join

=item * persist

See L<Forks::Queue> for descriptions of these options.

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2017, Marty O'Brien.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

=cut

