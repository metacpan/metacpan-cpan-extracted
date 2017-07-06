package IPC::LeaderBoard;

use strict;
use warnings;

use Fcntl ':flock';    # import LOCK_* constants
use Guard;
use IPC::ScoreBoard;
use Moo;
use Path::Tiny;
use namespace::clean;

our $VERSION = '0.04';

my $max_lock_attempts = $ENV{IPC_LEADERBOARD_MAX_SPINLOCK_ATTEMPTS} // 10000;

=head1 NAME

IPC::LeaderBoard - fast per-symbol online get/update information

=head1 VERSION

0.02

=head1 STATUS

=begin HTML

<p>
    <a href="https://travis-ci.org/binary-com/perl-IPC-LeaderBoard"><img src="https://travis-ci.org/binary-com/perl-IPC-LeaderBoard.svg" /></a>
</p>

=end HTML


=head1 SYNOPSIS

    use IPC::LeaderBoard;

    # in master-process
    my $master = IPC::LeaderBoard::create(
        n_slots           => 2,                          # number of symbols
        slot_shared_size  => 4,                          # number integers per slot, concurrent access
        slot_private_size => 2,                          # number integers per slot, non-concurrent access
        mmaped_file       => "/var/run/data/my.scores",  # mmaped file
    );
    # ... initialize data here

    # in slave processes
    my $slave  = IPC::LeaderBoard::attach(
      # exactly the same parameters as for master
    );

    my $leader_board = $slave; # or $master, does not matter

    # get shared and private arrays of integers for the 0-th slot
    my ($shared, $private) = $leader_board->read_slot(0);

    # update shared integers with values 1,2,3,4 and 0-th private integer
    # with value 6
    my $success = $leader_board->update(0, [1, 2, 3, 4], 0 => 6, 1 => 8);

    # $shared = [1, 2, 3, 4], $private = [6, 8]
    ($shared, $private) = $leader_board->read_slot(0);

    # update just private integer with index 1 with value 2
    $leader_board->update(0, 1 => 2);

    # update just shared values of 0-th slot
    $success = $leader_board->update(0, [1, 2, 3, 4]);

=head1 DESCRIPTION

LeaderBoard uses shared memory IPC to fast set/get integers on arbitrary row,
(slot) defined by it's index.

There are the following assumptions:

=over 2

=item * only one master is present

C<create> method dies, if it founds that some other master ownes shared
memory (file lock is used for that).

=item * master is launched before slaves

C<attach> dies, if slave finds, that master-owner isn't present, or,
if it presents, the masters provider/symbol information isn't actual.
In the last case master should be restarted first.

=item * there is no hot-deploy mechanism

Just restart master/slaves

=item * read slot before update it

The vesion/generation pattern is used do detect, whether update
has been successfull or not. Update failure means, some other
C<LeaderBoard> instance updated the slot; you should re-read it
and try uptate it again (if the update will be still actual after
data refresh)

=item * no semantical difference between slave and master

Master was introduced to lock leadear board to prevent other masters
connect to it and re-initialize (corrupt) data. After attach slave validates,
that LeaderBoard is valid (i.e. number of slots, as well as the sizes
of private and shared areas match to the declared).

Hence, master can be presented only by one instance, while slaves
can be presented by multiple instances.

=item * slot data organization and consistency

A leaderboard is an array of slots of the same size:

 +------------------------------------------------------------------------+
 | slot 1                                                                 |
 +------------------------------------------------------------------------+
 | slot 2                                                                 |
 +------------------------------------------------------------------------+
 | ...                                                                    |
 +------------------------------------------------------------------------+
 | slot N                                                                 |
 +------------------------------------------------------------------------+

A slot is addressed by its index.

Each slot contains a spin-lock, a shared part, a generation field and a private part like

It is supposed, that only leader (independent for each slot) will update the shared part,
while other competitors will update only own private parts, i.e.:

 |      |        shared part       |        |                         private part                         |
 | spin |                          | gene-  | process1           | process2           | process3           |
 | lock | shr1 | shr2 | ... | shrN | ration | p1 | p2 | ... | pN | p1 | p2 | ... | pN | p1 | p2 | ... | pN |

All values (shrX and pX) in the leaderboard are integer numbers. Only the current leader updates
the shared part, and does that in safe manner (i.e. protected by spin-lock and generation). Each process can
update its own private part of a slot.

Read or write for integer values (shr1, p1, ..) read/write B<atomicity> is guaranteed
by L<IPC::ScoreBoard>, which in the final, uses special CPU-instructions for that.

The SpinLock pattern guarantees the safety of shared part update, i.e. in
the case of two or more concurrent write request, they will be done in
sequential manner.

The Generation pattern guarantees that you update the most recent values
in the shared part of the slot, i.e. if some process updated shared
part of the slot, between slot read and update operations of the
current process, than, the update request of the current process
would fail. You have re-read the slot, and try to update it again, but
after re-read the update might be not required.

Both SpinLock and Generation patterns guarantee, that you'll never
can made inconsistent C<update>, or updating non-actual data.

In the same time, you might end up with the inconsistent C<read_slot>
of the shared data: the individual values (integer) are consistent (atomic),
but you they might belong to the different generations. There is an assumption
in the C<LeaderBoard> design, that it is B<fine>: would you try to update
the shared data, the C<update> will fail, hence, no any harm will occur. If
you need to handle that, just check return value C<update>.

There are no any guarantees for slot private data; but it isn't needed.
The shared data should store information about leader, hence when a
new leader arrives, it updates the information; or the current leader update
it's information on the LeaderBoard in the appropriate slot. No data loss might
occur.

When competitor (i.e. some process) updates private data, nobody else
can update it (i.e. you shouldn't write progam such a way, that one
process-competitor updates data of the other process-competitor), hence,
private data cannot be corrupted if used properly.

The private data might be inconsistent on read (e.g. competitor1 reads
private data of competitor2, while it is half-updated by competitor2);
but that shoudl be B<insignificant for the sake of speed>. If it is
significant, use shared memory for that, re-design your approach (e.g
use additional slots) or use some other module.

=back

The update process should be rather simple: C<killall $slave_1, $slave_2, ... $master>
and then start all together. C<create> / C<attach> should be wrappend into
C<eval> (or C<Try::Tiny> & friends), to repeat seveal attempts with some delay.

The C<update> method might fail, (i.e. it does not returns true), when it detects,
that somebody else already has changed an row. It is assumed that no any harm
in it. If needed the row can be refreshed (re-read), and the next update
might be successfull.

It is assumed, that if C<read> returs outdated data and the C<update> decision
has been taken, than update will silently fail (return false), without any
loud exceptions; so, the next read-update cycle might be successful, but
probably, the updated values are already correct, so, no immediate update
would occur.

=for Pod::Coverage BUILD DEMOLISH attach create mmaped_file n_slots read_slot slot_private_size slot_shared_size

=cut

has mmaped_file => (
    is       => 'ro',
    required => 1
);

has n_slots => (
    is       => 'ro',
    required => 1
);

has slot_shared_size => (
    is       => 'ro',
    required => 1
);

has slot_private_size => (
    is       => 'ro',
    required => 1
);

has _mode => (
    is       => 'ro',
    required => 1
);

has _score_board     => (is => 'rw');
has _fd              => (is => 'rw');
has _generation_idx  => (is => 'rw');
has _last_generation => (is => 'rw');
has _last_idx        => (
    is      => 'rw',
    default => sub { -1 });

sub BUILD {
    my $self = shift;
    my $mode = $self->_mode;
    die("unknown mode '$mode'") unless $mode =~ /(slave)|(master)/;

    # construct ids (number, actually the order) for all symbols
    # and providers. Should be sorted to guaranttee the same
    # ids in different proccess
    # There is an assumption, that processes, using LeaderBoard, should
    # restarte in case of symbols/providers change.

    my $filename = $self->mmaped_file;
    if (!(-e $filename) && ($mode eq 'slave')) {
        die("LeaderBoard ($filename) is abandoned, cannot attach to it (file not exists)");
    }

    my $scoreboard_path = path($filename);
    $scoreboard_path->touch if !-e $filename;
    my $fd = $scoreboard_path->filehandle('<');

    my $score_board;
    if ($mode eq 'slave') {
        # die, if slave was able to lock it, that means, that master
        # didn't accquired the exclusive lock, i.e. no master
        flock($fd, LOCK_SH | LOCK_NB)
            && die("LeaderBoard ($filename) is abandoned, cannot attach to it (shared lock obtained)");
        my ($sb, $nslots, $slotsize) = IPC::ScoreBoard->open($filename);
        # just additional check, that providers/symbols information is actual
        my $declared_size = $self->slot_shared_size + $self->slot_private_size + 2;
        die("number of slots mismatch") unless $nslots == $self->n_slots;
        die("slot size mismatch") unless $slotsize == $declared_size;
        $score_board = $sb;
    } else {
        # die if we can't lock it, that means, another master-process
        # already acquired it
        flock($fd, LOCK_EX | LOCK_NB)
            || die("LeaderBoard ($filename) is owned by some other process, cannot lock it exclusively");
        # we use the addtitional fields: for spinlock and generation
        my $declared_size = $self->slot_shared_size + $self->slot_private_size + 2;
        $score_board = IPC::ScoreBoard->named($filename, $self->n_slots, $declared_size, 0);
        $self->_fd($fd);
    }
    $self->_generation_idx($self->slot_shared_size + 1);    # [spin_lock | shared_data | generation | private_data ]
    $self->_score_board($score_board);
    return;
}

sub DEMOLISH {
    my $self = shift;
    # actually we need that only for tests
    if ($self->_mode eq 'master') {
        flock($self->_fd, LOCK_UN) if ($self->_fd);
    }
    return;
}

sub attach {
    return IPC::LeaderBoard->new({
        _mode => 'slave',
        @_,
    });
}

sub create {
    return IPC::LeaderBoard->new({
        _mode => 'master',
        @_,
    });
}

# our use-case implies, that if we read a bit outdated data, this is OK, because
# the generation field will be outdated, hence, no update would occur
sub read_slot {
    my ($self, $idx) = @_;
    die("wrong index") if ($idx >= $self->n_slots) || $idx < 0;

    my @all_values = $self->_score_board->get_all($idx);
    # drop spinlock and generation
    my $generation = splice @all_values, $self->_generation_idx, 1;
    splice @all_values, 0, 1;

    # record generation + index for further possible update
    $self->_last_idx($idx);
    $self->_last_generation($generation);

    # separate shared and private data
    my $shared_size    = $self->slot_shared_size;
    my @shared_values  = @all_values[0 .. $shared_size - 1];
    my @private_values = @all_values[$shared_size .. $shared_size + $self->slot_private_size - 1];

    return \@shared_values, \@private_values;
}

sub update {
    my ($self, $idx, @rest) = @_;
    my $values           = (@rest && ref($rest[0]) eq 'ARRAY') ? shift(@rest) : undef;
    my %private_values   = @rest;
    my $operation_result = 0;
    die("wrong index") if ($idx >= $self->n_slots) || $idx < 0;
    die("update for only last read index is allowed") if $idx != $self->_last_idx;

    my $sb = $self->_score_board;

    # updating shared values
    if ($values) {
        die("values size mismatch slot size") if @$values != $self->slot_shared_size;

        # obtain spin-lock
        my $attempts = 0;
        while ($sb->incr($idx, 0) != 1) {
            $sb->decr($idx, 0);
            if (++$attempts > $max_lock_attempts) {
                warn("failed to acquire spin lock for row $idx after $attempts attempts");
                return 0;
            }
        }
        # release the lock at the end of the scope
        scope_guard { $sb->decr($idx, 0) };

        # now we hold the record, nobody else can update it.
        # Atomically read generation value via increment it to zero.
        # The simple $sb->get(...) cannot be used, because it does not guarantees
        # atomicity, i.e. slot re-write is possible due to L1/L2 caches in CPU
        my $actual_generation = $sb->incr($idx, $self->_generation_idx, 0);
        if ($actual_generation == $self->_last_generation) {
            # now we are sure, that nobody else updated the record since our last read
            # so we can safely update it

            # +1 because the 1st field is spinlock
            $sb->set($idx, $_ + 1, $values->[$_]) for (0 .. @$values - 1);
            # increment the generation field
            $sb->incr($idx, $self->_generation_idx);
            # success
            $operation_result = 1;
        }
    }

    # updating private values
    if (%private_values) {
        my $idx_delta = $self->_generation_idx + 1;
        for my $private_idx (keys %private_values) {
            my $value = $private_values{$private_idx};
            if (($private_idx >= $self->slot_private_size) || ($private_idx < 0)) {
                die("wrong private index");
            }
            $sb->set($idx, $private_idx + $idx_delta, $value);
        }
    }

    return $operation_result;
}

=head1 AUTHOR

binary.com, C<< <perl at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/binary-com/perl-IPC-LeaderBoard/issues>.

=cut

1;
