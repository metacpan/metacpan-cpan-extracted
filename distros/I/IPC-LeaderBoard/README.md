# NAME

[![Build Status](https://travis-ci.org/binary-com/perl-IPC-LeaderBoard.svg?branch=master)](https://travis-ci.org/binary-com/perl-IPC-LeaderBoard)
[![codecov](https://codecov.io/gh/binary-com/perl-IPC-LeaderBoard/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-IPC-LeaderBoard)

IPC::LeaderBoard - fast per-symbol online get/update information

# VERSION

0.02

# STATUS

# SYNOPSIS

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
    my $success = $leader_board->update(0, [1, 2, 3, 4], 0 => 6, 1 => 8)

    # $shared = [1, 2, 3, 4], $private = [6, 8]
    ($shared, $private) = $leader_board->read_slot(0);

    # update just private integer with index 1 with value 2
    $leader_board->update(0, 1 => 2);

    # update just shared values of 0-th slot
    my $success = $leader_board->update(0, [1, 2, 3, 4]);

# DESCRIPTION

LeaderBoard uses shared memory IPC to fast set/get integers on arbitrary row,
(slot) defined by it's index.

There are the following assumptions:

- only one master is present

    `create` method dies, if it founds that some other master ownes shared
    memory (file lock is used for that).

- master is launched before slaves

    `attach` dies, if slave finds, that master-owner isn't present, or,
    if it presents, the masters provider/symbol information isn't actual.
    In the last case master should be restarted first.

- there is no hot-deploy mechanism

    Just restart master/slaves

- read slot before update it

    The vesion/generation pattern is used do detect, whether update
    has been successfull or not. Update failure means, some other
    `LeaderBoard` instance updated the slot; you should re-read it
    and try uptate it again (if the update will be still actual after
    data refresh)

- no semantical difference between slave and master

    Master was introduced to lock leadear board to prevent other masters
    connect to it and re-initialize (corrupt) data. After attach slave validates,
    that LeaderBoard is valid (i.e. number of slots, as well as the sizes
    of private and shared areas match to the declared).

    Hence, master can be presented only by one instance, while slaves
    can be presented by multiple instances.

- slot data organization and consistency

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

    Read or write for integer values (shr1, p1, ..) read/write **atomicity** is guaranteed
    by [IPC::ScoreBoard](https://metacpan.org/pod/IPC::ScoreBoard), which in the final, uses special CPU-instructions for that.

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
    can made inconsistent `update`, or updating non-actual data.

    In the same time, you might end up with the inconsistent `read_slot`
    of the shared data: the individual values (integer) are consistent (atomic),
    but you they might belong to the different generations. There is an assumption
    in the `LeaderBoard` design, that it is **fine**: would you try to update
    the shared data, the `update` will fail, hence, no any harm will occur. If
    you need to handle that, just check return value `update`.

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
    but that shoudl be **insignificant for the sake of speed**. If it is
    significant, use shared memory for that, re-design your approach (e.g
    use additional slots) or use some other module.

The update process should be rather simple: `killall $slave_1, $slave_2, ... $master`
and then start all together. `create` / `attach` should be wrappend into
`eval` (or `Try::Tiny` & friends), to repeat seveal attempts with some delay.

The `update` method might fail, (i.e. it does not returns true), when it detects,
that somebody else already has changed an row. It is assumed that no any harm
in it. If needed the row can be refreshed (re-read), and the next update
might be successfull.

It is assumed, that if `read` returs outdated data and the `update` decision
has been taken, than update will silently fail (return false), without any
loud exceptions; so, the next read-update cycle might be successful, but
probably, the updated values are already correct, so, no immediate update
would occur.

# AUTHOR

binary.com, `<perl at binary.com>`

# BUGS

Please report any bugs or feature requests to
[https://github.com/binary-com/perl-IPC-LeaderBoard/issues](https://github.com/binary-com/perl-IPC-LeaderBoard/issues).

# LICENSE AND COPYRIGHT

Copyright (C) 2016 binary.com

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
