package Forks::Queue::SQLite;
use strict;
use warnings;
use Carp;
use JSON;
use DBI;
use DBD::SQLite;
use Time::HiRes 'time';
use base 'Forks::Queue';
use 5.010;    #  using  // //=  operators

our $VERSION = '0.11';
our ($DEBUG,$XDEBUG);
*DEBUG = \$Forks::Queue::DEBUG;
*XDEBUG = \$Forks::Queue::XDEBUG;

$SIG{IO} = sub { } if $Forks::Queue::NOTIFY_OK;

our $jsonizer = JSON->new->allow_nonref(1)->ascii(1);

sub new {
    my $class = shift;
    my %opts = (%Forks::Queue::OPTS, @_);

    if ($opts{join} && !$opts{db_file}) {
        croak "Forks::Queue::SQLite: db_file opt required with join";
    }
    if ($opts{file} && !$opts{db_file}) {
        carp "file => passed to FQ::SQLite constructor! ",
             "You probably meant db_file => ... !";
    }
    $opts{db_file} //= _impute_file();
    $opts{limit} //= -1;
    $opts{on_limit} //= 'fail';
    $opts{style} //= 'fifo';
    my $list = delete $opts{list};

    if (!$opts{join} && -f $opts{db_file}) {
        carp "Forks::Queue: sqlite db file $opts{db_file} already exists!";
    }

    my $exists = $opts{join} && -f $opts{db_file};
    $opts{_pid} = [ $$, TID() ];
    # process id is tied to database handle. If process id doesn't match
    # $self->{_pid}, we must open a new process id.

    my $self = bless { %opts }, $class;

    if (!$exists) {
        my $dbh = DBI->connect("dbi:SQLite:dbname=" . $opts{db_file},
                               "", "");
        $self->{_dbh} = $opts{_dbh} = $dbh;
        if (!eval { $self->_init }) {
            carp "Forks::Queue::SQLite: db initialization failed";
            return;
        }
    } else {
        $self->_dbh;
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

# wrapper for database operations I expect to succeed, but may fail with
# intermittent synchronization issues ("attempt to write to a readonly 
# database...") on perl v5.10 and v5.12. Pausing and retrying the operation
# generally fixes these issues.
sub _try {
    my ($count, $code) = @_;
    $count = 1 if $] >= 5.014;
    my $z = $code->();
    my ($f0,$f1) = (1,1);
    while (!$z) {
        last if --$count <= 0;
        ($f0,$f1)=($f1,$f0+$f1);
        my (undef,undef,$lcaller) = caller(0);
        $DEBUG && print STDERR "retry after ${f0}s: $lcaller\a\n";
        sleep $f0;
        $z = $code->();
    }
    return $z;
}

sub _init {
    my $self = shift;
    my $dbh = $self->{_dbh};

    my $z1 = $dbh->do("CREATE TABLE the_queue (
                           timestamp decimal(27,15), batchid mediumint,
                           item text)");
    if (!$z1) {
        carp "Forks::Queue::SQLite: error creating init table";
        return;
    }

    my $z2 = $dbh->do("CREATE TABLE pids (pid mediumint,tid mediumint)");
    if (!$z2) {
        carp "Forks::Queue::SQLite: error creating init table";
        return;
    }

    my $sth = $dbh->prepare("INSERT INTO pids VALUES (?,?)");
    my $z3 = $sth->execute(@{$self->{_pid}});
    if (!$z3) {
        carp "Forks::Queue::SQLite: error adding process id to tracker";
        return;
    }

    my $z4 = $dbh->do("CREATE TABLE status(key text,value text)");
    if (!$z4) {
        carp "Forks::Queue::SQLite: error creating init table";
        return;
    }

    $self->_status("db_file", $self->{db_file});
    $self->_status("owner", "@{$self->{_pid}}");
    $self->_status("style", $self->{style});
    $self->_status("limit", $self->{limit});
    $self->_status("on_limit", $self->{on_limit});
    return 1;
}

sub TID { $INC{'threads.pm'} ? threads->tid : 0 }

sub _dbh {
    my $self = shift;
    my $tid = TID();
    if ($self->{_dbh} && $$ == $self->{_pid}[0] && $tid == $self->{_pid}[1]) {
        return $self->{_dbh};
    }

    $self->{_pid} = [$$,$tid];
    $self->{_dbh} =
        DBI->connect("dbi:SQLite:dbname=".$self->{db_file},"","");
    $self->{_dbh}{AutoCommit} = 1;
    if (!$self->{_DESTROY}) {
        $self->{_dbh}->begin_work;
        $self->{_dbh}->do("DELETE FROM pids WHERE pid=$$ AND tid=$tid");
        $self->{_dbh}->do("INSERT INTO pids VALUES ($$,$tid)");
        $self->{_dbh}->commit;
        $self->{style} = $self->_status("style");
        $self->{limit} = $self->_status("limit");
        $self->{on_limit} = $self->_status("on_limit");
    }
    return $self->{_dbh};
}

sub DESTROY {
    my $self = shift;
    $self->{_DESTROY}++;
    my $dbh = $self->_dbh;
    my $tid = $self->{_pid} ? $self->{_pid}[1] : TID();
    my $t = [[-1]];
    my $pid_rm = $dbh && eval {
        $dbh->{PrintWarn} =            # suppress "attempt to write ..."
            $dbh->{PrintError} = 0;    # warnings, particularly on 5.010, 5.012
        $dbh->begin_work;

        my $z1 = _try(3, sub {
            $dbh->do("DELETE FROM pids WHERE pid=$$ AND tid=$tid") } );

        if ($z1) {
            my $sth = $dbh->prepare("SELECT COUNT(*) FROM pids");
            my $z2 = $sth->execute;
            $t = $sth->fetchall_arrayref;
        } else {
            $DEBUG && print STDERR "$$ DESTROY: DELETE FROM pids failed\n";
            $t = [[-2]];
        }
        $dbh->commit;
        $DEBUG and print STDERR "$$ DESTROY npids=$t->[0][0]\n";
	1;
    };
    $dbh && eval { $dbh->disconnect };
    if ($t && $t->[0] && $t->[0][0] == 0) {
        $DEBUG and print STDERR "$$ Unlinking files from here\n";
        if (!$self->{persist}) {
            sleep 1;
            unlink $self->{db_file};
        }
    } else {
    }
}

sub _status {
    # if transactions are desired, they must be provided by the caller
    my $self = shift;
    my $dbh = $self->_dbh;
    return if !$dbh && $self->{_DESTROY};
    if (@_ == 1) {
        my $sth = $dbh->prepare("SELECT value FROM status WHERE key=?");
        if (!$sth && $self->{_DESTROY}) {
            warn "prepare failed in global destruction: $$";
            return;
        }

        my $key = $_[0];
        my $z = _try( 3, sub { $sth->execute($key) } );

        if (!$z) {
            carp "Forks::Queue::SQLite: ",
                 "lookup on status key '$_[0]' failed";
            return;
        }
        my $t = $sth->fetchall_arrayref;
        if (@$t == 0) {
            return;    # no value
        }
        return $t->[0][0];
    } elsif (@_ == 2) {
        my ($key,$value) = @_;
        my $sth1 = $dbh->prepare("DELETE FROM status WHERE key=?");
        my $sth2 = $dbh->prepare("INSERT INTO status VALUES(?,?)");

        my $z1 = _try( 3, sub { $sth1->execute($key) } );
        my $z2 = $z1 && _try( 5, sub { $sth2->execute($key,$value) } );

        return $z1 && $z2;
    } else {
        croak "Forks::Queue::SQLite: wrong number of args to _status call";
    }
    return;
}

sub end {
    my $self = shift;
    my $dbh = $self->_dbh;

    my $end = $self->_end;
    if ($end) {
        carp "Forks::Queue: end() called from $$, ",
            "previously called from $end";
    }

    if (!$end) {
        $dbh->begin_work;
        $self->_status("end",$$);
        $dbh->commit;
    }
    $self->_notify;
    return;
}

sub _end {
    my $self = shift;
    return $self->{_end} ||= $self->_status("end");
    # XXX - can  end  condition be cleared? Not yet, but when it can,
    #       this code will have to change
}


# MagicLimit: a tie class to allow $q->limit to work as an lvalue

sub Forks::Queue::SQLite::MagicLimit::TIESCALAR {
    my ($pkg,$obj) = @_;
    return bless \$obj,$pkg;
}

sub Forks::Queue::SQLite::MagicLimit::FETCH {
    $XDEBUG && print STDERR "MagicLimit::FETCH => ",${$_[0]}->{limit},"\n";
    return ${$_[0]}->{limit};
}

sub Forks::Queue::SQLite::MagicLimit::STORE {
    my ($tie,$val) = @_;
    $XDEBUG && print STDERR "MagicLimit::STORE => $val\n";
    my $queue = $$tie;
    my $oldval  = $queue->{limit};
    $queue->{limit} = $val;

    my $dbh = $queue->_dbh;
    $dbh->begin_work;
    $queue->_status("limit",$val);
    $dbh->commit;
    return $oldval;
}

sub limit :lvalue {
    my $self = shift;
    if (!$self->{_limit_magic}) {
        tie $self->{_limit_magic}, 'Forks::Queue::SQLite::MagicLimit', $self;
        $XDEBUG && print STDERR "tied \$self->\{_limit_magic\}\n";
    }
    if (@_) {
        $self->_dbh->begin_work;
        $XDEBUG && print STDERR "setting _limit_magic to $_[0]\n";
        $self->_status("limit", shift);
        if (@_) {
            $XDEBUG && print STDERR "setting on_limit to $_[0]\n";
            $self->_status("on_limit", $self->{on_limit} = $_[0]);
        }
        $self->_dbh->commit;
    } else {
        $self->{limit} = $self->_status("limit");
        $XDEBUG && print STDERR "updating {limit} to $self->{limit}\n";
    }
    return $self->{_limit_magic};
}

sub status {
    my $self = shift;
    my $dbh = $self->_dbh;
    my $status = {};
    my $sth = $dbh->prepare("SELECT key,value FROM status");
    my $z = $sth->execute;
    my $tt = $sth->fetchall_arrayref;
    foreach my $t (@$tt) {
        $status->{$t->[0]} = $t->[1];
    }
    $status->{avail} = $self->_avail;  # update {count}, {avail}
    $status->{end} //= 0;
    return $status;
}

sub _avail {
    # if transactions are needed, set them up in the caller
    my ($self,$dbh) = @_;
    $dbh ||= $self->_dbh;
    return unless $dbh;
    my $sth = $dbh->prepare("SELECT COUNT(*) FROM the_queue");
    return unless $sth;
    my $z = $sth->execute;
    my $tt = $sth->fetchall_arrayref;
    return $self->{avail} = $tt->[0][0];
}

sub _maintain {
    my ($self) = @_;
    return;
}

sub push {
    my ($self,@items) = @_;
    $self->_push(+1,@items);
}

sub unshift {
    my ($self,@items) = @_;
    $self->_push(-1,@items);
}

sub _add {
    # do not use transactions here!
    # if they are needed, call begin_work/commit from the caller
    my ($self,$item,$timestamp,$id) = @_;
    my $jitem = $jsonizer->encode($item);
    my $dbh = $self->_dbh;
    my $sth = $dbh->prepare("INSERT INTO the_queue VALUES(?,?,?)");

    my $z = _try(3, sub { $sth->execute($timestamp, $id, $jitem) } );
    
    return $z;
}

sub _push {
    my ($self,$tfactor,@items) = @_;

    my (@deferred_items,$failed_items);
    my $pushed = 0;

    if ($self->_end) {
        carp "Forks::Queue: put call from process $$ ",
             "after end call from process " . $self->{_end};
        return 0;
    }

    my $limit = $self->{limit};
    $limit = 9E9 if $self->{limit} <= 0;

    my $dbh = $self->_dbh;
    

    $dbh->begin_work;
    my $stamp = Time::HiRes::time;
    my $id = $self->_batch_id($stamp,$dbh);
    while (@items && $self->_avail < $limit) {
        my $item = shift @items;
        $self->_add($item, $stamp, $id++);
        $pushed++;
    }
    $dbh->commit;
    if (@items > 0) {
        @deferred_items = @items;
        $failed_items = @deferred_items;
    }
    $self->_notify if $pushed;

    if ($failed_items) {
        if ($self->{on_limit} eq 'fail') {
            carp "Forks::Queue: queue buffer is full ",
                "and $failed_items items were not added";
        } else {
            $DEBUG && print STDERR "$$ $failed_items on put. ",
                                   "Waiting for capacity\n";
            $self->_wait_for_capacity;
            $DEBUG && print STDERR "$$ got some capacity\n";
            $pushed += $self->_push($tfactor,@deferred_items);
        }
    }
    return $pushed;
}

sub _wait_for_item {
    my $self = shift;
    my $ready = 0;
    do {
        $ready = $self->_avail || $self->_end || $self->_expired;
        sleep($Forks::Queue::SLEEP_INTERVAL || 1) if !$ready;
    } while !$ready;
    return $self->{avail};
}

sub _wait_for_capacity {
    my $self = shift;
    if ($self->{limit} <= 0) {
        return 9E9;
    }
    my $ready = 0;
    while (!$ready) {
        last if $self->_avail < $self->{limit};
        last if $self->_end;
        sleep($Forks::Queue::SLEEP_INTERVAL || 1);
    }
    return $self->{avail} < $self->{limit};
}

sub _batch_id {
    my ($self,$stamp,$dbh) = @_;
    $dbh ||= $self->_dbh;
    my $sth = $dbh->prepare("SELECT MAX(batchid) FROM the_queue WHERE timestamp=?");
    my $z = $sth->execute($stamp);
    my $tt = $sth->fetchall_arrayref;
    if (@$tt == 0) {
        return 0;
    } else {
        return $tt->[0][0];
    }
}

sub dequeue {
    my $self = shift;
    Forks::Queue::_validate_input($_[0], 'count', 1) if @_;
    if ($self->{style} ne 'lifo') {
        return @_ ? $self->_retrieve(-1,1,2,0,$_[0]) 
                  : $self->_retrieve(-1,1,2,0);
    } else {
        return @_ ? $self->_retrieve(+1,1,2,0,$_[0])
                  : $self->_retrieve(+1,1,2,0);
    }
}

sub shift :method {
    my $self = shift;
    # purge, block
    return @_ ? $self->_retrieve(-1,1,1,0,$_[0]) : $self->_retrieve(-1,1,1,0);
}

sub pop {
    my $self = shift;
    Forks::Queue::_validate_input($_[0], 'index', 1) if @_;
    # purge, block
    my @popped = $self->_retrieve(+1,1,1,0,$_[0] // 1);
    return @_ ? reverse(@popped) : $popped[0];
}

sub shift_nb {
    my $self = shift;
    # purge, no block
    return @_ ? $self->_retrieve(-1,1,0,0,$_[0]) : $self->_retrieve(-1,1,0,0);
}

sub pop_nb {
    my $self = shift;
    # purge, no block
    my @popped = @_
        ? $self->_retrieve(+1,1,0,0,$_[0]) : $self->_retrieve(+1,1,0,0);
    return @_ ? @popped : $popped[0];
    return @popped;
}

sub extract {
    my $self = shift;
    Forks::Queue::_validate_input( $_[0], 'index' ) if @_;
    my $index = shift || 0;
    Forks::Queue::_validate_input( $_[0], 'count', 1) if @_;
    my $count = $_[0] // 1;
    my $reverse = 0;

    my $tfactor = -1;
    if ($self->{style} eq 'lifo') {
        $tfactor = 1;
        $reverse = 1;
    }
    if ($count <= 0) {
        carp "Forks::Queue::extract: count must be positive";
        return;
    }
    if ($index < 0) {
        if ($index + $count > 0) {
            $count = -$index;
        }
        $index = -$index - 1;
        $index -= $count - 1;

        $tfactor *= -1;
        $reverse = !$reverse;
    }
    # purge, no block
    my @items = $self->_retrieve( $tfactor, 1, 0, $index, $index+$count);
    if ($reverse) {
        @items = reverse(@items);
    }
    return @_ ? @items : $items[0] // ();
}

sub insert {
    my ($self, $pos, @items) = @_;
    Forks::Queue::_validate_input($pos,'index');
    my (@deferred_items);
    my $inserted = 0;
    if ($self->_end) {
        carp "Forks::Queue: insert call from process $$ ",
            "after end call from process " . $self->{_end} .  "\n";
        return 0;
    }

    my $limit = $self->{limit};
    $limit = 9E9 if $self->{limit} <= 0;

    if ($pos >= $self->_avail) {
        return $self->put(@items);
    }
    if ($pos <= -$self->_avail) {
        #return $self->unshift(@items);
        $pos = 0;
    }
    if ($pos < 0) {
        $pos += $self->_avail;
    }

    # find timestamps for items $pos and $pos+1
    # choose 0+@items intermediate timestamps
    #     if $pos+1 is undef, use current time as timestamp
    # as in the _push function, add items
    my $dbh = $self->_dbh;
    my $sths = $dbh->prepare(
        "SELECT timestamp,batchid FROM the_queue ORDER BY timestamp,batchid LIMIT ?");
    $dbh->begin_work;
    my $z = $sths->execute($pos+1);
    my $tt = $sths->fetchall_arrayref;
    $DB::single = 1;
    my ($t1,$t2,$b1,$b2);
    if (@$tt > 0) {
        $t2 = $tt->[-1][0];
        $b2 = $tt->[-1][1];
    } else {
        $t2 = Time::HiRes::time();
        $b2 = 0;
    }
    if (@$tt == $pos) {
        $t1 = $t2;
        $b1 = $b2;
        $b2 = 0;
        if ($t2 < 0) {
            $t2 = -Time::HiRes::time();
        } else {
            $t2 = Time::HiRes::time();
        }
    } elsif ($pos == 0) {
        $t1 = $t2 - 100000;
        $b1 = 0;
    } else {
        $t1 = $tt->[-2][0];
        $b1 = $tt->[-2][1];
    }

    my ($t3,$b3);
    if ($t1 == $t2) {
        my $sthr = $dbh->prepare("UPDATE the_queue SET batchid=batchid+? 
                                  WHERE timestamp=? AND batchid>=?");
        $sthr->execute(0+@items,$t1,$b2);
        $t3 = $t1;
        $b3 = $b1+1;
    } else {
        $t3 = ($t1 + $t2) / 2;
        $b3 = 0;
        if ($t3 == $t1) {
            $b3 = $b1+1;
        }
    }
    while (@items && $self->_avail < $limit) {
        my $item = shift @items;
        _try(3, sub { $self->_add($item,$t3,$b3) });
        $inserted++;
        $b3++;
    }
    $dbh->commit;
    if (@items > 0) {
        @deferred_items = @items;
    }
    if (@deferred_items) {
        if ($self->{on_limit} eq 'fail') {
            carp "Forks::Queue: queue buffer is full and ",
                0+@deferred_items," items were not inserted";
        } else {
            $DEBUG && print STDERR "$$ ",0+@deferred_items, " on insert. ",
                                   "Waiting for capacity\n";
            $self->_wait_for_capacity;
            $DEBUG && print STDERR "$$ got some capacity\n";
            $inserted += $self->insert($pos+$inserted,@deferred_items);
        }
    }
    $self->_notify if $inserted;
    return $inserted;
}

sub _retrieve {
    my $self = shift;
    my $tfactor = shift;
        # tfactor = -1: select newest items first
        # tfactor = +1: select oldest items first
    my $purge = shift;
        # purge = 0: do not delete items that we retrieve
        # purge = 1: delete items that we retrieve
    my $block = shift;
        # block = 0: no block if queue is empty
        # block = 1: block only if queue is empty
        # block = 2: block if full request can not be fulfilled
    my $lo = shift;
    my $hi = @_ ? $_[0] : $lo+1;
    return if $hi <= $lo;

    # attempt to retrieve items $lo .. $hi and return them
    # retrieved items are removed from the queue if $purge is set
    # get newest items first if $tfactor > 0, oldest first if $tfactor < 0
    # only block while
    #     $block is set
    #     zero items have been found

    if ($lo > 0 && $block) {
        carp "Forks::Queue::SQLite::_retrieve: "
            . "didn't expect block=$block and lo=$lo";
        $block = 0;
    }

    my $order = $tfactor > 0 
        ? "timestamp DESC,batchid DESC" : "timestamp,batchid";
    my $dbh = $self->_dbh;
    my $sths = $dbh->prepare(
        "SELECT item,batchid,timestamp FROM the_queue 
         ORDER BY $order LIMIT ?");
    my $sthd = $purge && $dbh->prepare(
        "DELETE FROM the_queue WHERE item=? AND timestamp=? AND batchid=?");
    my @return;
    if (!$sths) {
        warn "prepare queue SELECT statement failed: $dbh->errstr";
    }

    while (@return <= 0) {
        my $limit = $hi - @return + ($lo < 0 ? $lo : 0);
        $dbh->begin_work;
        my $z = $sths && $sths->execute($limit);
        my $tt = $sths && $sths->fetchall_arrayref;
        if ($lo < 0 && -$lo > @$tt) {
            $hi += (@$tt - $lo);
            $lo += (@$tt - $lo);
        }
        if (!$tt || @$tt == 0) {
            $dbh->rollback;
            if ($block) {
                $self->_wait_for_item;
                next;
            } else {
                return;
            }
        } elsif ($block > 1 && $lo == 0 && @$tt < $hi) {
            # not enough items on queue to satisfy request
            $dbh->rollback;
            next;
        } elsif (@$tt <= $lo) {
            # not enough items on queue to satisfy request
            $dbh->rollback;
            return;
        }
        $hi = @$tt if $hi > @$tt;

        foreach my $itt ($lo .. $hi-1) {
            if (!defined($tt->[$itt])) {
                warn "\nResult $itt from $lo .. $hi-1 is undefined!";
            }
            my ($item,$bid,$timestamp) = @{$tt->[$itt]};
            CORE::push @return, $jsonizer->decode($item);
            if ($purge) {

                my $zd = _try(4, sub { $sthd->execute($item,$timestamp,$bid)} );
                if (!$zd) {
                        warn "Forks::Queue::SQLite: ",
                             "purge failed: $item,$timestamp,$bid";
                }
            }
        }
        $dbh->commit;
    } continue {
        if ($block) {
            if ($self->_end || $self->_expired) {
                $block = 0;
            }
        }
    }
    return @_ ? @return : $return[0] // ();
}



sub _pop {
    my $self = shift;
    my $tfactor = shift;
    my $purge = shift;
    my $block = shift;
    my $wantarray = shift;
    my ($count) = @_;
    $count ||= 1;

    my $order = "timestamp,batchid";
    if ($tfactor > 0) {
        $order = "timestamp DESC,batchid DESC";
    }
    my $dbh = $self->_dbh;
    my $sths = $dbh->prepare(
        "SELECT item,timestamp,pid FROM the_queue ORDER BY $order LIMIT ?");
    my $sthd = $dbh->prepare(
        "DELETE FROM the_queue WHERE item=? AND timestamp=? AND pid=?");
    my @return = ();
    while (@return == 0) {
        my $limit = $count - @return;
        my $z = $sths->execute($limit);
        my $tt = $sths->fetchall_arrayref;
        if (@$tt == 0) {
            if ($block && $self->_wait_for_item) {
                next;
            } else {
                last;
            }
        }
        foreach my $t (@$tt) {
            my ($item,$bid,$timestamp) = @$t;
            CORE::push @return, $jsonizer->decode($item);
            if ($purge) {
		$dbh->begin_work;
                my $zd = $sthd->execute($item,$timestamp,$bid);
                if (!$zd) {
                    carp "purge failed: $item,$timestamp,$bid\n";
                }
		$dbh->commit;
            }
        }
    }
    return $wantarray ? @return : $return[0];
}

sub clear {
    my $self = shift;
    my $dbh = $self->_dbh;
    $dbh->begin_work;
    $dbh->do("DELETE FROM the_queue");
    $dbh->commit;
}

sub peek_front {
    my $self = shift;
    my ($index) = @_;
    $index ||= 0;
    if ($index < 0) {
        return $self->peek_back(-$index - 1);
    }
    # no purge, no block, always retrieve a single item
    return $self->_retrieve(-1,0,0,$index);
}

sub peek_back {
    my $self = shift;
    my ($index) = @_;
    $index ||= 0;
    if ($index < 0) {
        return $self->peek_front(-$index - 1);
    }
    # no purge, no block, always retrieve a single item
    return $self->_retrieve(+1,0,0,$index);
}

sub _notify {
    return unless $Forks::Queue::NOTIFY_OK;

    my $self = shift;
    my $dbh = $self->_dbh;
    my $sth = $dbh->prepare("SELECT pid,tid FROM pids");
    my $z = $sth->execute;
    my $pt = $sth->fetchall_arrayref;
    my @pids = map { $_->[0] } grep { $_->[0] != $$ } @$pt;
    if (@pids) {
        $DEBUG && print STDERR "$$ notify: @pids\n";
        kill 'IO', @pids;
    }
    my @tids = map { $_->[1] } grep { $_->[0] == $$ && $_->[1] != TID() } @$pt;
    if (@tids) {
        foreach my $tid (@tids) {
            my $thr = threads->object($tid);
            $thr && $thr->kill('IO');
        }
    }
}

my $id = 0;
sub _impute_file {
    my $base = $0;
    $base =~ s{.*[/\\](.)}{$1};
    $base =~ s{[/\\]$}{};
    $id++;
    my @candidates;
    if ($^O eq 'MSWin32') {
        @candidates = (qw(C:/Temp C:/Windows/Temp));
    } else {
        @candidates = qw(/tmp /var/tmp);
    }
    for my $candidate ($ENV{FORKS_QUEUE_DIR},
                       $ENV{TMPDIR}, $ENV{TEMP},
                       $ENV{TMP}, @candidates,
                       $ENV{HOME}, ".") {
        if (defined($candidate) && $candidate ne '' &&
            -d $candidate && -w _ && -x _) {
            return $candidate . "/fq-$$-$id-$base.sql3";
        }
    }
    my $file = "./fq-$$-$id-$base.sql3";
    carp "Forks::Queue::SQLite: queue db file $file might not be a good location!";
    return $file;
}

sub _DUMP {
    my ($self,$fh_dump) = @_;
    my $dbh = $self->_dbh;
    $fh_dump ||= *STDERR;

    my $sth = $dbh->prepare("SELECT * FROM pids");
    my $z = $sth->execute;
    print {$fh_dump} "\n\n=== pids ===\n------------\n";
    foreach my $r (@{$sth->fetchall_arrayref}) {
        print {$fh_dump} join("\t",@$r),"\n";
    }

    $sth = $dbh->prepare("SELECT * FROM status");
    $z = $sth->execute;
    print {$fh_dump} "\n\n=== status ===\n--------------\n";
    foreach my $r (@{$sth->fetchall_arrayref}) {
        print {$fh_dump} join("\t",@$r),"\n";
    }

    $sth = $dbh->prepare("SELECT * FROM the_queue");
    $z = $sth->execute;
    print {$fh_dump} "\n\n=== queue ===\n-------------\n";
    foreach my $r (@{$sth->fetchall_arrayref}) {
        print {$fh_dump} join("\t",@$r),"\n";
    }
    print {$fh_dump} "\n\n";
}

1;

=head1 NAME

Forks::Queue::SQLite - SQLite-based implementation of Forks::Queue

=head1 VERSION

0.11

=head1 SYNOPSIS

    my $q = Forks::Queue->new( impl => 'SQLite', db_file => "queue-file" );
    $q->put( "job1" );
    $q->put( { name => "job2", task => "do something", data => [42,19] } );
    ...
    $q->end;
    for my $w (1 .. $num_workers) {
        if (fork() == 0) {
            my $task;
            while (defined($task = $q->get)) {
                ... perform task in child ...
            }
            exit;
        }
    }

=head1 DESCRIPTION

SQLite-based implementation of L<Forks::Queue|Forks::Queue>.
It requires the C<sqlite3> libraries and the L<DBD::SQLite|DBD::SQLite>
Perl module.

=head1 METHODS

See L<Forks::Queue> for an overview of the methods supported by
this C<Forks::Queue> implementation.

=head2 new

=head2 $queue = Forks::Queue::SQLite->new( %opts )

=head2 $queue = Forks::Queue->new( impl => 'SQLite', %opts )

The C<Forks::Queue::SQLite> constructor recognized the following 
configuration options.

=over 4

=item * db_file

The name of the file to use to store queue data and metadata.
If omitted, a temporary filename is chosen.

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
