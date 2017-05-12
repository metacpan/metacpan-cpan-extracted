=head1 NAME

IPC::DirQueue - disk-based many-to-many task queue

=head1 SYNOPSIS

    my $dq = IPC::DirQueue->new({ dir => "/path/to/queue" });
    $dq->enqueue_file("filename");

    my $dq = IPC::DirQueue->new({ dir => "/path/to/queue" });
    my $job = $dq->pickup_queued_job();
    if (!$job) { print "no jobs left\n"; exit; }
    # ...do something interesting with $job->get_data_path() ...
    $job->finish();

=head1 DESCRIPTION

This module implements a FIFO queueing infrastructure, using a directory
as the communications and storage media.  No daemon process is required to
manage the queue; all communication takes place via the filesystem.

A common UNIX system design pattern is to use a tool like C<lpr> as a task
queueing system; for example,
C<http://patrick.wagstrom.net/old/weblog/archives/000128.html> describes the
use of C<lpr> as an MP3 jukebox.

However, C<lpr> isn't as efficient as it could be.  When used in this way, you
have to restart each task processor for every new task.  If you have a lot of
startup overhead, this can be very inefficient.   With C<IPC::DirQueue>, a
processing server can run persistently and cache data needed across multiple
tasks efficiently; it will not be restarted unless you restart it.

Multiple enqueueing and dequeueing processes on multiple hosts (NFS-safe
locking is used) can run simultaneously, and safely, on the same queue.

Since multiple dequeuers can run simultaneously, this provides a good way
to process a variable level of incoming tasks using a pre-defined number
of worker processes.

If you need more CPU power working on a queue, you can simply start
another dequeuer to help out.  If you need less, kill off a few dequeuers.

If you need to take down the server to perform some maintainance or
upgrades, just kill the dequeuer processes, perform the work, and start up
new ones. Since there's no 'socket' or similar point of failure aside from
the directory itself, the queue will just quietly fill with waiting jobs
until the new dequeuer is ready.

Arbitrary 'name = value' string-pair metadata can be transferred alongside data
files.   In fact, in some cases, you may find it easier to send unused and
empty data files, and just use the 'metadata' fields to transfer the details of
what will be worked on.

=head1 METHODS

=over 4

=cut

package IPC::DirQueue;
use strict;
use bytes;
use Time::HiRes qw();
use Fcntl qw(O_WRONLY O_CREAT O_EXCL O_RDONLY);
use IPC::DirQueue::Job;
use IPC::DirQueue::IndexClient;
use Errno qw(EEXIST);

our @ISA = ();

our $VERSION = "1.0";

use constant SLASH => '/';

# our $DEBUG = 1;
our $DEBUG; # = 1;

###########################################################################

=item $dq->new ($opts);

Create a new queue object, suitable for either enqueueing jobs
or picking up already-queued jobs for processing.

C<$opts> is a reference to a hash, which may contain the following
options:

=over 4

=item dir => $path_to_directory (no default)

Name the directory where the queue files are stored.  This is required.

=item data_file_mode => $mode (default: 0666)

The C<chmod>-style file mode for data files.  This should be specified
as a string with a leading 0.  It will be affected by the current
process C<umask>.

=item queue_file_mode => $mode (default: 0666)

The C<chmod>-style file mode for queue control files.  This should be
specified as a string with a leading 0.  It will be affected by the
current process C<umask>.

=item ordered => { 0 | 1 } (default: 1)

Whether the jobs should be processed in order of submission, or
in no particular order.

=item queue_fanout => { 0 | 1 } (default: 0)

Whether the queue directory should be 'fanned out'.  This allows better
scalability with NFS-shared queues with large numbers of pending files, but
hurts performance otherwise.   It also implies B<ordered> = 0. (This is
strictly experimental, has overall poor performance, and is not recommended.)

=item indexd_uri => $uri (default: undef)

A URI of a C<dq-indexd> daemon, used to maintain the list of waiting jobs.  The
URI must be of the form  C<dq://hostname[:port]> . (This is strictly
experimental, and is not recommended.)

=item buf_size => $number (default: 65536)

The buffer size to use when copying files, in bytes.

=item active_file_lifetime => $number (default: 600)

The lifetime of an untouched active lockfile, in seconds.  See 'STALE LOCKS AND
SIGNAL HANDLING', below, for more details.

=back

=cut

sub new {
  my $class = shift;
  my $opts = shift;
  $opts ||= { };
  $class = ref($class) || $class;
  my $self = $opts;
  bless ($self, $class);

  die "no 'dir' specified" unless $self->{dir};
  $self->{data_file_mode} ||= '0666';
  $self->{data_file_mode} = oct ($self->{data_file_mode});
  $self->{queue_file_mode} ||= '0666';
  $self->{queue_file_mode} = oct ($self->{queue_file_mode});

  if ($self->{queue_fanout}) {
    $self->{queue_fanout} = 1;
    $self->{ordered} = 0;           # fanout wins
  }
  elsif (!defined $self->{ordered}) {
    $self->{ordered} = 1;
  }

  $self->{buf_size} ||= 65536;
  $self->{active_file_lifetime} ||= 600;

  $self->{ensured_dir_exists} = { };
  $self->ensure_dir_exists ($self->{dir});

  if ($self->{indexd_uri}) {
    $self->{indexclient} = IPC::DirQueue::IndexClient->new({
            uri => $self->{indexd_uri}
          });
  }

  $self;
}

sub dbg;

###########################################################################

=item $dq->enqueue_file ($filename [, $metadata [, $pri] ] );

Enqueue a new job for processing. Returns C<1> if the job was enqueued, or
C<undef> on failure.

C<$filename> is the path to the file to be enqueued.  Its contents
will be read, and will be used as the contents of the data file available
to dequeuers using C<IPC::DirQueue::Job::get_data_path()>.

C<$metadata> is an optional hash reference; every item of metadata will be
available to worker processes on the C<IPC::DirQueue::Job> object, in the
C<$job-E<gt>{metadata}> hashref.  Note that using this channel for metadata
brings with it several restrictions:

=over 4

=item 1. it requires that the metadata be stored as 'name' => 'value' string pairs

=item 2. neither 'name' nor 'value' may contain newline (\n) or NUL (\0) characters

=item 3. 'name' cannot contain colon (:) characters

=item 4. 'name' cannot start with a capital letter 'Q' and be 4 characters in length

=back

If those restrictions are broken, die() will be called with the following
error:

      die "IPC::DirQueue: invalid metadatum: '$k'";

This is a change added in release 0.06; prior to that, that metadatum would be
silently dropped.

An optional priority can be specified; lower priorities are run first.
Priorities range from 0 to 99, and 50 is default.

=cut

sub enqueue_file {
  my ($self, $file, $metadata, $pri) = @_;
  if (!open (IN, "<$file")) {
    warn "IPC::DirQueue: cannot open $file for read: $!";
    return;
  }
  my $ret = $self->_enqueue_backend ($metadata, $pri, \*IN);
  close IN;
  return $ret;
}

=item $dq->enqueue_fh ($filehandle [, $metadata [, $pri] ] );

Enqueue a new job for processing. Returns C<1> if the job was enqueued, or
C<undef> on failure. C<$pri> and C<$metadata> are as described in
C<$dq-E<gt>enqueue_file()>.

C<$filehandle> is a perl file handle that must be open for reading.  It will be
closed on completion, regardless of success or failure. Its contents will be
read, and will be used as the contents of the data file available to dequeuers
using C<IPC::DirQueue::Job::get_data_path()>.

=cut

sub enqueue_fh {
  my ($self, $fhin, $metadata, $pri) = @_;
  my $ret = $self->_enqueue_backend ($metadata, $pri, $fhin);
  close $fhin;
  return $ret;
}

=item $dq->enqueue_string ($string [, $metadata [, $pri] ] );

Enqueue a new job for processing.  The job data is entirely read from
C<$string>. Returns C<1> if the job was enqueued, or C<undef> on failure.
C<$pri> and C<$metadata> are as described in C<$dq-E<gt>enqueue_file()>.

=cut

sub enqueue_string {
  my ($self, $string, $metadata, $pri) = @_;
  my $enqd_already = 0;
  return $self->_enqueue_backend ($metadata, $pri, undef,
        sub {
          return if $enqd_already++;
          return $string;
        });
}

=item $dq->enqueue_sub ($subref [, $metadata [, $pri] ] );

Enqueue a new job for processing. Returns C<1> if the job was enqueued, or
C<undef> on failure. C<$pri> and C<$metadata> are as described in
C<$dq-E<gt>enqueue_file()>.

C<$subref> is a perl subroutine, which is expected to return one of the
following each time it is called:

    - a string of data bytes to be appended to any existing data.  (the
      string may be empty, C<''>, in which case it's a no-op.)

    - C<undef> when the enqueued data has ended, ie. EOF.

    - C<die()> if an error occurs.  The C<die()> message will be converted into
      a warning, and the C<enqueue_sub()> call will return C<undef>.

(Tip: note that this is a closure, so variables outside the subroutine can be
accessed safely.)

=cut

sub enqueue_sub {
  my ($self, $subref, $metadata, $pri) = @_;
  return $self->_enqueue_backend ($metadata, $pri, undef, $subref);
}

# private implementation.
sub _enqueue_backend {
  my ($self, $metadata, $pri, $fhin, $callbackin) = @_;

  if (!defined($pri)) { $pri = 50; }
  if ($pri < 0 || $pri > 99) {
    warn "IPC::DirQueue: bad priority $pri is > 99 or < 0";
    return;
  }

  my ($now, $nowmsecs) = Time::HiRes::gettimeofday;

  my $job = {
    pri => $pri,
    metadata => $metadata,
    time_submitted_secs => $now,
    time_submitted_msecs => $nowmsecs
  };

  # NOTE: this can change until the moment we've renamed the ctrl file
  # into 'queue'!
  my $qfnametmp = $self->new_q_filename($job);
  my $qcnametmp = $qfnametmp;

  my $pathtmp = $self->q_subdir('tmp');
  $self->ensure_dir_exists ($pathtmp);

  my $pathtmpctrl = $pathtmp.SLASH.$qfnametmp.".ctrl";
  my $pathtmpdata = $pathtmp.SLASH.$qfnametmp.".data";

  if (!sysopen (OUT, $pathtmpdata, O_WRONLY|O_CREAT|O_EXCL,
      $self->{data_file_mode}))
  {
    warn "IPC::DirQueue: cannot open $pathtmpdata for write: $!";
    return;
  }
  my $pathtmpdata_created = 1;

  my $siz;
  eval {
    $siz = $self->copy_in_to_out_fh ($fhin, $callbackin,
                              \*OUT, $pathtmpdata);
  };
  if ($@) {
    warn "IPC::DirQueue: enqueue failed: $@";
  }
  if (!defined $siz) {
    goto failure;
  }
  $job->{size_bytes} = $siz;

  # get the data dir
  my $pathdatadir = $self->q_subdir('data');

  # hashing the data dir, using 2 levels of directory hashing.  This has a tiny
  # effect on speed in all cases up to 10k queued files, but has good results
  # in terms of the usability of those dirs for users doing direct access, so
  # enabled by default.
  if (1) {
    # take the last two chars for the hashname.  In most cases, this will
    # be the last 2 chars of a hash of (hostname, pid), so effectively
    # random.  Remove it from the filename entirely, since it's redundant
    # to have it both in the dir name and the filename.
    $qfnametmp =~ s/([A-Za-z0-9+_])([A-Za-z0-9+_])$//;
    my $hash1 = $1 || '0';
    my $hash2 = $2 || '0';
    my $origdatadir = $pathdatadir;
    $pathdatadir = "$pathdatadir/$hash1/$hash2";
    # check to see if that hashdir exists... build it up if req'd
    if (!-d $pathdatadir) {
      foreach my $dir ($origdatadir, "$origdatadir/$hash1", $pathdatadir)
      {
        (-d $dir) or mkdir ($dir);
      }
    }
  }

  # now link(2) the data tmpfile into the 'data' dir.
  my $pathdata = $self->link_into_dir ($job, $pathtmpdata,
                                    $pathdatadir, $qfnametmp);
  if (!$pathdata) {
    goto failure;
  }
  my $pathdata_created = 1;
  $job->{pathdata} = $pathdata;

  # ok, write a control file now that data is safe and we know it's
  # new filename...
  if (!$self->create_control_file ($job, $pathtmpdata, $pathtmpctrl)) {
    goto failure;
  }
  my $pathtmpctrl_created = 1;

  # now link(2) that into the 'queue' dir.
  my $pathqueuedir = $self->q_subdir('queue');
  my $fanout = $self->queue_dir_fanout_create($pathqueuedir);

  my $pathqueue = $self->link_into_dir ($job, $pathtmpctrl,
                $self->queue_dir_fanout_path($pathqueuedir, $fanout),
                $qcnametmp);

  if (!$pathqueue) {
    dbg ("failed to link_into_dir, enq failed");
    goto failure;
  }

  # and incr the fanout counter for that fanout dir
  $self->queue_dir_fanout_commit($pathqueuedir, $fanout);

  # touch the "queue" directory to indicate that it's changed
  # and a file has been enqueued; required to support Reiserfs
  # and XFS, where this is not implicit
  $pathqueuedir = $self->q_subdir('queue');
  $self->touch($pathqueuedir) or warn "touch failed on $pathqueuedir";
  dbg ("touched $pathqueuedir at ".time);

  if ($self->{indexclient}) {
    $self->{indexclient}->enqueue($pathqueuedir, $pathqueue);
  }

  # my $pathqueue_created = 1;     # not required, we're done!
  return 1;

failure:
  if ($pathtmpctrl_created) {
    unlink $pathtmpctrl or warn "IPC::DirQueue: cannot unlink $pathtmpctrl";
  }
  if ($pathtmpdata_created) {
    unlink $pathtmpdata or warn "IPC::DirQueue: cannot unlink $pathtmpdata";
  }
  if ($pathdata_created) {
    unlink $pathdata or warn "IPC::DirQueue: cannot unlink $pathdata";
  }
  return;
}

###########################################################################

=item $job = $dq->pickup_queued_job( [ path => $path ] );

Pick up the next job in the queue, so that it can be processed.

If no job is available for processing, either because the queue is
empty or because other worker processes are already working on
them, C<undef> is returned; otherwise, a new instance of C<IPC::DirQueue::Job>
is returned.

Note that the job is marked as I<active> until C<$job-E<gt>finish()>
is called.

If the (optional) parameter C<path> is used, its value indicates the path of
the desired job's data file. By using this, it is possible to cancel
not-yet-active items from anywhere in the queue, or pick up jobs out of
sequence.  The data path must match the value of the I<pathqueue> member of
the C<IPC::DirQueue::Job> object passed to the C<visit_all_jobs()> callback.

=cut

sub pickup_queued_job {
  my ($self, %args) = @_;

  my $pathqueuedir = $self->q_subdir('queue');
  my $pathactivedir = $self->q_subdir('active');
  $self->ensure_dir_exists ($pathactivedir);

  my $iter = $self->queue_iter_start($pathqueuedir);

  while (1) {
    my $nextfile = $self->queue_iter_next($iter);

    if (!defined $nextfile) {
      # no more files in the queue, return empty
      last;
    }

    my $nextfilebase = $self->queue_dir_fanout_path_strip($nextfile);

    next if ($nextfilebase !~ /^\d/);
    my $pathactive = $pathactivedir.SLASH.$nextfilebase;
    my $pathqueue  = $pathqueuedir.SLASH.$nextfile;

    next if (exists($args{path}) && ($pathqueue ne $args{path}));

    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
        $atime,$mtime,$ctime,$blksize,$blocks) = lstat($pathactive);

    if (defined $mtime) {
      # *DO* call time() here.  In extremely large dirs, it may take
      # several seconds to traverse the entire listing from start
      # to finish!
      if (time() - $mtime < $self->{active_file_lifetime}) {
        # active lockfile; it's being worked on.  skip this file
        next;
      }

      if ($self->worker_still_working($pathactive)) {
        # worker is still alive, although not updating the lock
        dbg ("worker still working, skip: $pathactive");
        next;
      }

      # now, we want to try to avoid 2 or 3 dequeuers removing
      # the lockfile simultaneously, as that could cause this race:
      #
      # dqproc1: [checks file]        [unlinks] [starts work]
      # dqproc2:        [checks file]                         [unlinks]
      #
      # ie. the second process unlinks the first process' brand-new
      # lockfile!
      #
      # to avoid this, use a random "fudge" on the timeout, so
      # that dqproc2 will wait for possibly much longer than
      # dqproc1 before it decides to unlink it.
      #
      # this isn't perfect.  TODO: is there a "rename this fd" syscall
      # accessible from perl?

      my $fudge = get_random_int() % 256;
      if (time() - $mtime < $self->{active_file_lifetime}+$fudge) {
        # within the fudge zone.  don't unlink it in this process.
        dbg ("within active fudge zone, skip: $pathactive");
        next;
      }

      # else, we can kill the stale lockfile
      unlink $pathactive or warn "IPC::DirQueue: unlink failed: $pathactive";
      warn "IPC::DirQueue: killed stale lockfile: $pathactive";
    }

    # ok, we're free to get cracking on this file.
    my $pathtmp = $self->q_subdir('tmp');
    $self->ensure_dir_exists ($pathtmp);

    # use the name of the queue file itself, plus a tmp prefix, plus active
    my $pathtmpactive = $pathtmp.SLASH.
                $nextfilebase.".".$self->new_lock_filename().".active";

    dbg ("creating tmp active $pathtmpactive");
    if (!sysopen (LOCK, $pathtmpactive, O_WRONLY|O_CREAT|O_EXCL,
        $self->{queue_file_mode}))
    {
      if ($!{EEXIST}) {
        # contention; skip this file
        dbg ("IPC::DirQueue: $pathtmpactive already created, skipping: $!");
      }
      else {
        # could be serious; disk space, permissions etc.
        warn "IPC::DirQueue: cannot open $pathtmpactive for write: $!";
      }
      next;
    }
    print LOCK $self->gethostname(), "\n", $$, "\n";
    close LOCK;

    if (!-f $pathqueue) {
      # queue file already gone; another worker got it before we did.
      # catch this case before we create a lockfile.
      # see the "pathqueue_gone" comment below for an explanation
      dbg("IPC::DirQueue: $pathqueue no longer exists, skipping");
      goto nextfile;
    }

    my $job = IPC::DirQueue::Job->new ($self, {
      jobid => $nextfilebase,
      pathqueue => $pathqueue,
      pathactive => $pathactive
    });

    my $pathnewactive = $self->link_into_dir_no_retry ($job,
                        $pathtmpactive, $pathactivedir, $nextfilebase);
    if (!defined($pathnewactive)) {
      # link failed; another worker got it before we did
      # no need to unlink tmpfile, the "nextfile" action will do that
      goto nextfile;
    }

    if ($pathactive ne $pathnewactive) {
      die "oops! active paths differ: $pathactive $pathnewactive";
    }

    if (!open (IN, "<".$pathqueue))
    {
      # since we read the list of files upfront, this can happen:
      #
      # dqproc1: [gets lock] [work] [finish_job]
      # dqproc2:                                 [gets lock]
      #
      # "dqproc1" has already completed the job, unlinking both the active
      # *and* queue files, by the time "dqproc2" gets to it.  This is OK;
      # just skip the file, since it's already done.  [pathqueue_gone]

      dbg("IPC::DirQueue: cannot open $pathqueue for read: $!");
      unlink $pathnewactive;
      next;     # NOT "goto nextfile", as pathtmpactive is already unlinked
    }

    my $red = $self->read_control_file ($job, \*IN);
    close IN;

    next if (!$red);

    $self->queue_iter_stop($iter);
    return $job;

nextfile:
    unlink $pathtmpactive or warn "IPC::DirQueue: unlink failed: $pathtmpactive";
  }

  $self->queue_iter_stop($iter);
  return;   # empty
}

###########################################################################

=item $job = $dq->wait_for_queued_job ([ $timeout [, $pollinterval] ]);

Wait for a job to be queued within the next C<$timeout> seconds.

If there is already a job ready for processing, this will return immediately.
If one is not available, it will sleep, wake up periodically, check for job
availabilty, and either carry on sleeping or return the new job if one
is now available.

If a job becomes available, a new instance of C<IPC::DirQueue::Job> is
returned. If the timeout is reached, C<undef> is returned.

If C<$timeout> is not specified, or is less than 1, this function will wait
indefinitely.

The optional parameter C<$pollinterval> indicates how frequently to wake
up and check for new jobs.  It is specified in seconds, and floating-point
precision is supported.  The default is C<1>.

Note that if C<$timeout> is not a round multiple of C<$pollinterval>,
the nearest round multiple of C<$pollinterval> greater than C<$timeout>
will be used instead.  Also note that C<$timeout> is used as an integer.

=cut

sub wait_for_queued_job {
  my ($self, $timeout, $pollintvl) = @_;

  my $finishtime;
  if ($timeout && $timeout > 0) {
    $finishtime = time + int ($timeout);
  }

  dbg "wait_for_queued_job starting";

  if ($pollintvl) {
    $pollintvl *= 1000000;  # from secs to usecs
  } else {
    $pollintvl = 1000000;   # default: 1 sec
  }

  my $pathqueuedir = $self->q_subdir('queue');
  $self->ensure_dir_exists ($pathqueuedir);

  # TODO: would be nice to use fam for this, where available.  But
  # no biggie...

  while (1) {
    # check the stat time on the queue dir *before* we call pickup,
    # to avoid a race condition where a job is added while we're
    # checking in that function.

    my @stat = stat ($pathqueuedir);
    my $qdirlaststat = $stat[9];

    my $job = $self->pickup_queued_job();
    if ($job) { return $job; }

    # there's another semi-race condition here, brought about by a lack of
    # sub-second precision from stat(2).  if the last enq occurred inside
    # *this* current 1-second window, then *another* one can happen inside this
    # second right afterwards, and we wouldn't notice.

    # in other words (ASCII-art alert):
    #    TIME   | t                                         | t+1
    #    E      |          enq                      enq     |
    #    D      |    stat       pickup_queued_job           |

    # the enqueuer process E enqueues a job just after the stat, inside the
    # 1-second period "t".  dequeuer process D dequeues it with
    # pickup_queued_job(). all is well.  But then, E enqueues another job
    # inside the same 1-second period "t", and since the stat() has already
    # happened for "t", and since we've already picked up the job in "t", we
    # don't recheck; result is, we miss this enqueue event.
    #
    # Avoid this by checking in a busy-loop until time(2) says we're out of
    # that "danger zone" 1-second period.  Any further enq's would then
    # cause stat(2) to report a different timestamp.

    while (time == $qdirlaststat) {
      Time::HiRes::usleep ($pollintvl);
      dbg "wait_for_queued_job: spinning until time != stat $qdirlaststat";
      my $job = $self->pickup_queued_job();
      if ($job) { return $job; }
    }

    # sleep until the directory's mtime changes from what it was when
    # we ran pickup_queued_job() last.

    dbg "wait_for_queued_job: sleeping on $pathqueuedir";
    while (1) {
      my $now = time;
      if ($finishtime && $now >= $finishtime) {
        dbg "wait_for_queued_job timed out";
        return undef;           # out of time
      }

      Time::HiRes::usleep ($pollintvl);

      @stat = stat ($pathqueuedir);
      # dbg "wait_for_queued_job: stat $stat[9] $qdirlaststat $pathqueuedir";
      last if (defined $stat[9] &&
            ((defined $qdirlaststat && $stat[9] != $qdirlaststat)
                    || !defined $qdirlaststat));
    }

    dbg "wait_for_queued_job: activity, calling pickup";
  }
}

###########################################################################

=item $dq->visit_all_jobs($visitor, $visitcontext);

Visit all the jobs in the queue, in a read-only mode.  Used to list
the entire queue.

The callback function C<$visitor> will be called for each job in
the queue, like so:

  &$visitor ($visitcontext, $job);

C<$visitcontext> is whatever you pass in that variable above.
C<$job> is a new, read-only instance of C<IPC::DirQueue::Job> representing
that job.

If a job is active (being processed), the C<$job> object also contains the
following additional data:

  'active_host': the hostname on which the job is active
  'active_pid': the process ID of the process which picked up the job

=cut

sub visit_all_jobs {
  my ($self, $visitor, $visitcontext) = @_;

  my $pathqueuedir = $self->q_subdir('queue');
  my $pathactivedir = $self->q_subdir('active');

  my $iter = $self->queue_iter_start($pathqueuedir);

  my $nextfile;
  while (1) {
    $nextfile = $self->queue_iter_next($iter);

    if (!defined $nextfile) {
      # no more files in the queue, return empty
      last;
    }

    my $nextfilebase = $self->queue_dir_fanout_path_strip($nextfile);

    next if ($nextfilebase !~ /^\d/);
    my $pathqueue = $pathqueuedir.SLASH.$nextfile;
    my $pathactive = $pathactivedir.SLASH.$nextfilebase;

    next if (!-f $pathqueue);

    my $acthost;
    my $actpid;
    if (open (IN, "<$pathactive")) {
      $acthost = <IN>; chomp $acthost;
      $actpid = <IN>; chomp $actpid;
      close IN;
    }

    my $job = IPC::DirQueue::Job->new ($self, {
      is_readonly => 1,     # means finish() will not rm files
      jobid => $nextfilebase,
      active_host => $acthost,
      active_pid => $actpid,
      pathqueue => $pathqueue,
      pathactive => $pathactive
    });

    if (!open (IN, "<".$pathqueue)) {
      dbg ("queue file disappeared, job finished? skip: $pathqueue");
      next;
    }

    my $red = $self->read_control_file ($job, \*IN);
    close IN;

    if (!$red) {
      warn "IPC::DirQueue: cannot read control file: $pathqueue";
      next;
    }

    &$visitor ($visitcontext, $job);
  }

  $self->queue_iter_stop($iter);
  return;
}

###########################################################################

# private API: performs logic of IPC::DirQueue::Job::finish().
sub finish_job {
  my ($self, $job, $isdone) = @_;

  dbg ("finish_job: ", $job->{pathactive});

  if ($job->{is_readonly}) {
    return;
  }

  if ($isdone) {
    unlink($job->{pathqueue})
            or warn "IPC::DirQueue: unlink failed: $job->{pathqueue}";
    unlink($job->{QDFN})
            or warn "IPC::DirQueue: unlink failed: $job->{QDFN}";

    if ($self->{indexclient}) {
      my $pathqueuedir = $self->q_subdir('queue');
      $self->{indexclient}->dequeue($pathqueuedir, $job->{pathqueue});
    }

    # touch the dir so that other dequeuers re-check; activity can
    # introduce a small race, I think.  (don't think this is necessary)
    # $self->touch($pathqueuedir) or warn "touch failed on $pathqueuedir";
  }

  unlink($job->{pathactive})
            or warn "IPC::DirQueue: unlink failed: $job->{pathactive}";
}

###########################################################################

sub get_dir_filelist_sorted {
  my ($self, $dir) = @_;

  if (!opendir (DIR, $dir)) {
    return [];          # no dir?  nothing queued
  }
  # have to read the lot, to sort them.
  my @files = sort grep { /^\d/ } readdir(DIR);
  closedir DIR;
  return \@files;
}

###########################################################################

sub copy_in_to_out_fh {
  my ($self, $fhin, $callbackin, $fhout, $outfname) = @_;

  my $buf;
  my $len;
  my $siz = 0;

  binmode $fhout;
  if ($callbackin) {
    while (1) {
      my $stringin = $callbackin->();

      if (!defined($stringin)) {
        last;       # EOF
      }

      $len = length ($stringin);
      next if ($len == 0);  # empty string, nothing to write

      if (!print $fhout $stringin) {
        warn "IPC::DirQueue: enqueue: cannot write to $outfname: $!";
        close $fhout;
        return;
      }
      $siz += $len;
    }
  }
  else {
    binmode $fhin;
    while (($len = read ($fhin, $buf, $self->{buf_size})) > 0) {
      if (!print $fhout $buf) {
        warn "IPC::DirQueue: cannot write to $outfname: $!";
        close $fhin; close $fhout;
        return;
      }
      $siz += $len;
    }
    close $fhin;
  }

  if (!close $fhout) {
    warn "IPC::DirQueue: cannot close $outfname";
    return;
  }
  return $siz;
}

sub link_into_dir {
  my ($self, $job, $pathtmp, $pathlinkdir, $qfname) = @_;
  $self->ensure_dir_exists ($pathlinkdir);
  my $path;

  # retry 10 times; add a random few digits on link(2) failure
  my $maxretries = 10;
  for my $retry (1 .. $maxretries) {
    $path = $pathlinkdir.SLASH.$qfname;

    dbg ("link_into_dir retry=", $retry, " tmp=", $pathtmp, " path=", $path);

    if (link ($pathtmp, $path)) {
      last; # got it
    }

    # link() may return failure, even if it succeeded.
    # use lstat() to verify that link() really failed.
    my ($dev,$ino,$mode,$nlink,$uid) = lstat($pathtmp);
    if ($nlink == 2) {
      last; # got it
    }

    # failed.  check for retry limit first
    if ($retry == $maxretries) {
      warn "IPC::DirQueue: cannot link $pathtmp to $path";
      return;
    }

    # try a new q_filename, use randomness to avoid
    # further collisions
    $qfname = $self->new_q_filename($job, 1);

    dbg ("link_into_dir retrying: $retry");
    Time::HiRes::usleep (250 * $retry);
  }

  # got it! unlink(2) the tmp file, since we don't need it.
  dbg ("link_into_dir unlink tmp file: $pathtmp");
  if (!unlink ($pathtmp)) {
    warn "IPC::DirQueue: cannot unlink $pathtmp";
    # non-fatal, we can still continue anyway
  }

  dbg ("link_into_dir return: $path");
  return $path;
}

sub link_into_dir_no_retry {
  my ($self, $job, $pathtmp, $pathlinkdir, $qfname) = @_;
  $self->ensure_dir_exists ($pathlinkdir);

  dbg ("lidnr: ", $pathtmp, " ", $pathlinkdir, "/", $qfname);

  my ($dev1,$ino1,$mode1,$nlink1,$uid1) = lstat($pathtmp);
  if (!defined $nlink1) {
    warn ("lidnr: tmp file disappeared?! $pathtmp");
    return;         # not going to have much luck here
  }

  my $path = $pathlinkdir.SLASH.$qfname;

  if (-f $path) {
    dbg ("lidnr: target file already exists: $path");
    return;         # we've been beaten to it
  }

  my $linkfailed;
  if (!link ($pathtmp, $path)) {
    dbg("link failure, recovering: $!");
    $linkfailed = 1;
  }

  # link() may return failure, even if it succeeded. use lstat() to verify that
  # link() really failed.  use lstat() even if it reported success, just to be
  # sure. ;)

  my ($dev3,$ino3,$mode3,$nlink3,$uid3) = lstat($path);
  if (!defined $nlink3) {
    dbg ("lidnr: link failed, target file nonexistent: $path");
    return;
  }

  # now, be paranoid and verify that the inode data is identical
  if ($dev1 != $dev3 || $ino1 != $ino3 || $uid1 != $uid3) {
    # the tmpfile and the target don't match each other.
    # if the link failed, this means that another qproc got
    # the file before we did, which is not an error.
    if (!$linkfailed) {
      # link supposedly succeeded, so this *is* an error.  warn
      warn ("lidnr: tmp file doesn't match target: $path ($dev3,$ino3,$mode3,$nlink3,$uid3) vs $pathtmp ($dev1,$ino1,$mode1,$nlink1,$uid1)");
    }
    return;
  }
  
  # got it! unlink(2) the tmp file, since we don't need it.
  dbg ("lidnr: unlink tmp file: $pathtmp");
  if (!unlink ($pathtmp)) {
    warn "IPC::DirQueue: cannot unlink $pathtmp";
    # non-fatal, we can still continue anyway
  }

  dbg ("lidnr: return: $path");
  return $path;
}

sub create_control_file {
  my ($self, $job, $pathtmpdata, $pathtmpctrl) = @_;

  dbg ("create_control_file $pathtmpctrl for $pathtmpdata ($job->{pathdata})");
  if (!sysopen (OUT, $pathtmpctrl, O_WRONLY|O_CREAT|O_EXCL,
      $self->{queue_file_mode}))
  {
    warn "IPC::DirQueue: cannot open $pathtmpctrl for write: $!";
    return;
  }

  print OUT "QDFN: ", $job->{pathdata}, "\n";
  print OUT "QDSB: ", $job->{size_bytes}, "\n";
  print OUT "QSTT: ", $job->{time_submitted_secs}, "\n";
  print OUT "QSTM: ", $job->{time_submitted_msecs}, "\n";
  print OUT "QSHN: ", $self->gethostname(), "\n";

  my $md = $job->{metadata};
  foreach my $k (keys %{$md}) {
    my $v = $md->{$k};
    if (($k =~ /^Q...$/)
        || ($k =~ /[:\0\n]/s)
        || ($v =~ /[\0\n]/s))
    {
      close OUT;
      die "IPC::DirQueue: invalid metadatum: '$k'"; # TODO: clean up files?
    }
    print OUT $k, ": ", $v, "\n";
  }

  if (!close (OUT)) {
    warn "IPC::DirQueue: cannot close $pathtmpctrl for write: $!";
    return;
  }

  return 1;
}

sub read_control_file {
  my ($self, $job, $infh) = @_;
  local ($_);

  while (<$infh>) {
    my ($k, $value) = split (/: /, $_, 2);
    chop $value;
    if ($k =~ /^Q[A-Z]{3}$/) {
      $job->{$k} = $value;
    }
    else {
      $job->{metadata}->{$k} = $value;
    }
  }

  # all jobs must have a datafile (even if it's empty)
  if (!$job->{QDFN} || !-f $job->{QDFN}) {
    return;
  }

  return $job;
  # print OUT "QDFN: ", $job->{pathdata}, "\n";
  # print OUT "QDSB: ", $job->{size_bytes}, "\n";
  # print OUT "QSTT: ", $job->{time_submitted_secs}, "\n";
  # print OUT "QSTM: ", $job->{time_submitted_msecs}, "\n";
  # print OUT "QSHN: ", $self->gethostname(), "\n";
}

sub worker_still_working {
  my ($self, $fname) = @_;
  if (!$fname) {
    return;
  }
  if (!open (IN, "<".$fname)) {
    return;
  }
  my $hname = <IN>; chomp $hname;
  my $wpid = <IN>; chomp $wpid;
  close IN;
  if ($hname eq $self->gethostname()) {
    if (!kill (0, $wpid)) {
      return;           # pid is local and no longer running
    }
  }

  # pid is still running, or remote
  return 1;
}

###########################################################################

sub q_dir {
  my ($self) = @_;
  return $self->{dir};
}

sub q_subdir {
  my ($self, $subdir) = @_;
  return $self->q_dir().SLASH.$subdir;
}

sub new_q_filename {
  my ($self, $job, $addextra) = @_;

  my @gmt = gmtime ($job->{time_submitted_secs});

  # NN.20040718140300MMMM.hash(hostname.$$)[.rand]
  #
  # NN = priority, default 50
  # MMMM = microseconds from Time::HiRes::gettimeofday()
  # hostname = current hostname

  my $buf = sprintf ("%02d.%04d%02d%02d%02d%02d%02d%06d.%s",
        $job->{pri},
        $gmt[5]+1900, $gmt[4]+1, $gmt[3], $gmt[2], $gmt[1], $gmt[0],
        $job->{time_submitted_msecs},
        hash_string_to_filename ($self->gethostname().$$));

  # normally, this isn't used.  but if there's a collision,
  # all retries after that will do this; in this case, the
  # extra anti-collision stuff is useful
  if ($addextra) {
    $buf .= ".".$$.".".$self->get_random_int();
  }

  return $buf;
}

sub hash_string_to_filename {
  my ($str) = @_;
  # get a 16-bit checksum of the input, then uuencode that string
  $str = pack ("u*", unpack ("%16C*", $str));
  # transcode from uuencode-space into safe, base64-ish space
  $str =~ y/ -_/A-Za-z0-9+_/;
  # and remove the stuff that wasn't in that "safe" range
  $str =~ y/A-Za-z0-9+_//cd;
  return $str;
}

sub new_lock_filename {
  my ($self) = @_;
  return sprintf ("%d.%s.%d", time, $self->gethostname(), $$);
}

sub get_random_int {
  my ($self) = @_;

  # we try to use /dev/random first, as that's globally random for all PIDs on
  # the system.  this avoids brokenness if the caller has called srand(), then
  # forked multiple enqueueing procs, as they will all share the same seed and
  # will all return the same "random" output.
  my $buf;
  if (sysopen (IN, "</dev/random", O_RDONLY) && read (IN, $buf, 2)) {
    my ($hi, $lo) = unpack ("C2", $buf);
    return ($hi << 8) | $lo;
  } else {
    # fall back to plain old rand(), use perl's implicit srand() call,
    # and hope caller hasn't called srand() yet in a parent process.
    return int rand (65536);
  }
}

sub gethostname {
  my ($self) = @_;

  my $hname = $self->{myhostname};
  return $hname if $hname;

  # try using Sys::Hostname. may fail on non-UNIX platforms
  eval '
    use Sys::Hostname;
    $self->{myhostname} = hostname;     # cache the result
  ';

  # could have failed.  supply a default in that case
  $self->{myhostname} ||= 'nohost';

  return $self->{myhostname};
}

sub ensure_dir_exists {
  my ($self, $dir) = @_;
  return if exists ($self->{ensured_dir_exists}->{$dir});
  $self->{ensured_dir_exists}->{$dir} = 1;
  (-d $dir) or mkdir($dir);
}

sub queuedir_is_bad {
  my ($self, $pathqueuedir) = @_;

  # try creating the dir; it may not exist yet
  $self->ensure_dir_exists ($pathqueuedir);
  if (!opendir (RETRY, $pathqueuedir)) {
    # still can't open it! problem
    warn "IPC::DirQueue: cannot open queue dir \"$pathqueuedir\": $!\n";
    return 1;
  }
  # otherwise, we could open it -- it just needed to be created.
  closedir RETRY;
  return 0;
}

sub dbg {
  return unless $DEBUG;
  warn "dq debug: ".join(' ',@_)."\n";
}

###########################################################################

sub queue_iter_start {
  my ($self, $pathqueuedir) = @_;

  if ($self->{indexclient}) {
    dbg ("queue iter: getting list for $pathqueuedir");
    my @files = sort grep { /^\d/ } $self->{indexclient}->ls($pathqueuedir);

    if (scalar @files <= 0) {
      return if $self->queuedir_is_bad($pathqueuedir);
    }

    return { files => \@files };
  }
  elsif ($self->{ordered}) {
    dbg ("queue iter: opening $pathqueuedir (ordered)");
    my $files = $self->get_dir_filelist_sorted($pathqueuedir);
    if (scalar @$files <= 0) {
      return if $self->queuedir_is_bad($pathqueuedir);
    }

    return { files => $files };
  }
  elsif ($self->{queue_fanout}) {
    return $self->queue_iter_fanout_start($pathqueuedir);
  }
  else {
    my $dirfh;
    dbg ("queue iter: opening $pathqueuedir");
    if (!opendir ($dirfh, $pathqueuedir)) {
      return if $self->queuedir_is_bad($pathqueuedir);
      if (!opendir ($dirfh, $pathqueuedir)) {
        warn "oops? pathqueuedir bad";
        return;
      }
    }

    return { fh => $dirfh };
  }

  die "cannot get here";
}

sub queue_iter_next {
  my ($self, $iter) = @_;

  if ($self->{indexclient}) {
    return shift @{$iter->{files}};
  }
  elsif ($self->{ordered}) {
    return shift @{$iter->{files}};
  }
  elsif ($self->{queue_fanout}) {
    return $self->queue_iter_fanout_next($iter);
  }
  else {
    return readdir($iter->{fh});
  }

  return;
}

sub queue_iter_stop {
  my ($self, $iter) = @_;

  return unless $iter;
  if (defined $iter->{fanfh}) { closedir($iter->{fanfh}); }
  if (defined $iter->{fh}) { closedir($iter->{fh}); }
}

###########################################################################

sub queue_dir_fanout_create {
  my ($self, $pathqueuedir) = @_;

  if (!$self->{queue_fanout}) {
    return;
  }

  my @letters = split '', q{0123456789abcdef};
  my $fanout = $letters[get_random_int() % (scalar @letters)];

  $self->ensure_dir_exists ($pathqueuedir);
  $self->ensure_dir_exists ($pathqueuedir.SLASH.$fanout);
  return $fanout;
}

sub queue_dir_fanout_commit {
  my ($self, $pathqueuedir, $fanout) = @_;

  if (!$self->{queue_fanout}) {
    return;
  }

  # now touch all levels ($pathqueuedir will be touched later)
  $self->touch($pathqueuedir.SLASH.$fanout)
      or die "cannot touch fanout for $pathqueuedir/$fanout";
}

sub queue_dir_fanout_path {
  my ($self, $pathqueuedir, $fanout) = @_;

  if (!$self->{queue_fanout}) {
    return $pathqueuedir;
  }
  else {
    return $pathqueuedir.SLASH.$fanout;
  }
}

sub queue_dir_fanout_path_strip {
  my ($self, $fname) = @_;

  if ($self->{queue_fanout}) {
    $fname =~ s/^.*\///;
  }
  return $fname;
}

sub queue_iter_fanout_start {
  my ($self, $pathqueuedir) = @_;
  my $iter = { };

  {
    my @fanouts;
    dbg ("queue iter: opening $pathqueuedir");
    if (!opendir (DIR, $pathqueuedir)) {
      @fanouts = ();          # no dir?  nothing queued
    }
    else {
      my %map = map {
              $_ => (-M $pathqueuedir.SLASH.$_)
            } grep { /^[a-z0-9]$/ } readdir(DIR);
      @fanouts = sort { $map{$a} <=> $map{$b} } keys %map;
      dbg ("fanout: $pathqueuedir, order is ".join ' ', @fanouts);
    }
    closedir DIR;
    $iter->{fanoutlist} = \@fanouts;
    $iter->{pathqueuedir} = $pathqueuedir;

  }
  return $iter;
}

sub queue_iter_fanout_next {
  my ($self, $iter) = @_;

  # dir handles are:
  # /path/to/queue     = $iter->{fh}
  #               /f   = $iter->{fanfh}

next_fanout:

  # open the {fanfh} handle, if it isn't already going
  if (!defined $iter->{fanfh}) {
    my $nextfanout = shift @{$iter->{fanoutlist}};
    if (!defined $nextfanout) {
      dbg ("fanout: end of list");
      return;
    }

    my $dirfh;
    dbg ("fanout: opening next dir: $nextfanout");
    if (!opendir ($dirfh, $iter->{pathqueuedir}.SLASH.$nextfanout)) {
      warn "opendir failed $iter->{pathqueuedir}/$nextfanout: $!";
      return;
    }

    $iter->{fanstr} = $nextfanout;
    $iter->{fanfh} = $dirfh;
  }

  my $fname = readdir($iter->{fanfh});
  if (defined $fname) {
    return $iter->{fanstr}.SLASH.$fname;        # best-case scenario
  }
  
  dbg ("fanout: finished this dir, trying next one");
  closedir($iter->{fanfh});
  $iter->{fanstr} = undef;
  $iter->{fanfh} = undef;
  goto next_fanout;
}

use constant UTIME_TAKES_UNDEF_FOR_TOUCH => ($] >= 5.007002);

sub touch {
  my ($self, $path) = @_;

  # 'Since perl 5.7.2, if the first two elements of the list are "undef", then
  # the utime(2) function in the C library will be called with a null second
  # argument. On most systems, this will set the file's access and modification
  # times to the current time'.

  if (UTIME_TAKES_UNDEF_FOR_TOUCH) {
    return utime undef, undef, $path;
  } else {
    my $now = time;
    return utime $now, $now, $path;
  }
}

###########################################################################

1;

=back

=head1 STALE LOCKS AND SIGNAL HANDLING

If interrupted or terminated, dequeueing processes should be careful to either
call C<$job-E<gt>finish()> or C<$job-E<gt>return_to_queue()> on any active
tasks before exiting -- otherwise those jobs will remain marked I<active>.

Dequeueing processes can also call C<$job-E<gt>touch_active_lock()>
periodically, while processing large tasks, to ensure that the task is still
marked as I<active>.

Stale locks are normally dealt with automatically.  If a lock is still
I<active> after about 10 minutes of inactivity, the other dequeuers on
that machine will probe the process ID listed in that lock file using
C<kill(0)>.  If that process ID is no longer running, the lock is presumed
likely to be stale. If a given timeout (10 minutes plus a random value
between 0 and 256 seconds) has elapsed since the lock file was last
modified, the lock file is deleted.

This 10-minute default can be modified using the C<active_file_lifetime>
parameter to the C<IPC::DirQueue> constructor.

Note: this means that if the dequeueing processes are spread among
multiple machines, and there is no longer a dequeuer running on the
machine that initially 'locked' the task, it will never be unlocked,
unless you delete the I<active> file for that task.

=head1 QUEUE DIRECTORY STRUCTURE

C<IPC::DirQueue> maintains the following structure for a queue directory:

=over 4

=item queue directory

The B<queue> directory is used to store the queue control files.  Queue
control files determine what jobs are in the queue; if a job has a queue
control file in this directory, it is listed in the queue.

The filename format is as follows:

    50.20040909232529941258.HASH[.PID.RAND]

The first two digits (C<50>) are the priority of the job.  Lower priority
numbers are run first.  C<20040909232529> is the current date and time when the
enqueueing process was run, in C<YYYYMMDDHHMMSS> format.   C<941258> is the time in
microseconds, as returned by C<gettimeofday()>.  And finally, C<HASH> is a
variable-length hash of some semi-random data, used to increase the chance of
uniqueness.

If there is a collision, the timestamps are regenerated after a 250 msec sleep,
and further randomness will be added at the end of the string (namely, the
current process ID and a random integer value).   Up to 10 retries will be
attempted.  Once the file is atomically moved into the B<queue> directory
without collision, the retries cease.

If B<queue_fanout> was used in the C<IPC::DirQueue> constructor, then
the B<queue> directory does not contain the queue control files directly;
instead, there is an interposing set of 16 "fan-out" directories, named
according to the hex digits from C<0> to C<f>.

=item active directory

The B<active> directory is used to store active queue control files.

When a job becomes 'active' -- ie. is picked up by C<pickup_queued_job()> --
its control file is moved from the B<queue> directory into the B<active>
directory while it is processed.

=item data directory

The B<data> directory is used to store enqueued data files.

It contains a two-level "fan-out" hashed directory structure; each data file is
stored under a single-letter directory, which in turn is under a single-letter
directory.   This increases the efficiency of directory lookups under many
filesystems.

The format of filenames here is similar to that used in the B<queue> directory,
except that the last two characters are removed and used instead for the
"fan-out" directory names.

=item tmp directory

The B<tmp> directory contains temporary work files that are in the process
of enqueueing, and not ready ready for processing.

The filename format here is similar to the above, with suffixes indicating
the type of file (".ctrl", ".data").

=back

Atomic, NFS-safe renaming is used to avoid collisions, overwriting or
other unsafe operations.

=head1 SEE ALSO

C<IPC::DirQueue::Job>

=head1 AUTHOR

Justin Mason E<lt>dq /at/ jmason.orgE<gt>

=head1 MAILING LIST

The IPC::DirQueue mailing list is at E<lt>ipc-dirqueue-subscribe@perl.orgE<gt>.

=head1 COPYRIGHT

C<IPC::DirQueue> is distributed under the same license as perl itself.

=head1 AVAILABILITY

The latest version of this library is likely to be available from CPAN.

