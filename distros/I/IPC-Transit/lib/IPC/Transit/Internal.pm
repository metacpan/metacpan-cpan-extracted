package IPC::Transit::Internal;
$IPC::Transit::Internal::VERSION = '1.171860';
use strict;use warnings;
use IPC::SysV;
use IPC::Msg;
use POSIX;


use vars qw(
    $config
);

{
my $queue_cache = {};
sub _initialize_queue {
    my %args = @_;
    my $qid = _get_queue_id(%args);
    if(not $queue_cache->{$qid}) {
        $queue_cache->{$qid} = IPC::Msg->new($qid, _get_flags('create_ipc'))
            or die "failed to _initialize_queue: failed to create queue_id $qid: $!\n";
    }
    return $queue_cache->{$qid};
}

sub _remove {
    my %args = @_;
    my $qname = $args{qname};
    my $qid = _get_queue_id(%args);
    $queue_cache->{$qid}->remove if $queue_cache->{$qid};
    unlink _get_transit_config_dir() . "/$qname";
}

sub _stat {
    my %args = @_;
    my $qid = _get_queue_id(%args);
    _initialize_queue(%args);
    my @heads = qw(uid gid cuid cgid mode qnum qbytes lspid lrpid stime rtime ctime);
    my $ret = {};
    my @items = @{$queue_cache->{$qid}->stat};
    foreach my $item (@items) {
        $ret->{shift @heads} = $item;
    }
    $ret->{qname} = $args{qname};
    $ret->{qid} = $qid;
    return $ret;
}
}

sub _drop_all_queues {
    foreach my $qname (keys %{$config->{queues}}) {
        _remove(qname => $qname);
    }
}
sub _stats {
    my $ret = [];
    _gather_queue_info();
    foreach my $queue_name (keys %{$config->{queues}}) {
        push @$ret, IPC::Transit::stat(qname => $queue_name);
    }
    return $ret;
}

sub _get_transit_config_dir {
    my $dir = $IPC::Transit::config_dir || '/tmp/ipc_transit/';
    return $dir;
}

sub _lock_config_dir {
    my $lock_file = _get_transit_config_dir() . '/.lock';
    my ($have_lock, $fh);
    for (1..2) {
        if(sysopen($fh, $lock_file, _get_flags('exclusive_lock'))) {
            $have_lock = 1;
            last;
        }
        sleep 1;
    }
    if(not $have_lock) {
        _unlock_config_dir();
        sysopen($fh, $lock_file, _get_flags('exclusive_lock'));
    }
    #we have the advisory lock for sure now
}


sub _unlock_config_dir {
    my $lock_file = _get_transit_config_dir() . '/.lock';
    unlink $lock_file or die "_unlock_config_dir: failed to unlink $lock_file: $!";
}

sub _gather_queue_info {
    _mk_queue_dir();
    $config->{queues} = {} unless $config->{queues};
    foreach my $filename (glob _get_transit_config_dir() . '/*') {
        my $info = {};
        open my $fh, '<', $filename
            or die "IPC::Transit::Internal::_gather_queue_info: failed to open $filename for reading: $!";
        while(my $line = <$fh>) {
            chomp $line;
            my ($key, $value) = split '=', $line;
            $info->{$key} = $value;
        }
        die 'required key "qid" not found' unless $info->{qid};
        die 'required key "qname" not found' unless $info->{qname};
        $config->{queues}->{$info->{qname}} = $info;
    }
}

sub _queue_exists {
    my $qname = shift;
    _mk_queue_dir();
    return $config->{queues}->{$qname};
}

sub _get_queue_id {
    my %args = @_;
    _mk_queue_dir();
    my $qname = $args{qname};

    #return it if we have it
    return $config->{queues}->{$qname}->{qid}
        if $config->{queues} and $config->{queues}->{$qname};

    #we don't have it; let's load it and try again
    _gather_queue_info();
    return $config->{queues}->{$qname}->{qid}
        if $config->{queues} and $config->{queues}->{$qname};

    #we still don't have it; get a lock, load it, try again, ane make
    #it if necessary
    _lock_config_dir();
    eval {
        #now re-load the config
        _gather_queue_info();

        #if we now have it, unlock and return it
        if($config->{queues} and $config->{queues}->{$qname}) {
            _unlock_config_dir();
            return $config->{queues}->{$qname}->{qid};
        }

        #otherwise, we need to make one
        {   my $file = _get_transit_config_dir() . "/$qname";
            open my $fh, '>', $file or die "IPC::Transit::Internal::_get_queue_id: failed to open $file for writing: $!";
            my $new_qid = IPC::SysV::ftok($file, 1);
            print $fh "qid=$new_qid\n";
            print $fh "qname=$qname\n";
            close $fh;
        }
        _unlock_config_dir();
    };
    if($@) {
        _unlock_config_dir();
    }
    _gather_queue_info();
    return $config->{queues}->{$qname}->{qid};
}

sub _mk_queue_dir {
    mkdir _get_transit_config_dir(), 0777
        unless -d _get_transit_config_dir();
}

#gnarly looking UNIX goop hidden below
{
my $flags = {
    create_ipc =>       IPC::SysV::S_IRUSR() |
                        IPC::SysV::S_IWUSR() |
                        IPC::SysV::S_IRGRP() |
                        IPC::SysV::S_IWGRP() |
                        IPC::SysV::S_IROTH() |
                        IPC::SysV::S_IWOTH() |
                        IPC::SysV::IPC_CREAT(),

    nowait =>           IPC::SysV::IPC_NOWAIT(),

    exclusive_lock =>   POSIX::O_RDWR() |
                        POSIX::O_CREAT() |
                        POSIX::O_EXCL(),

    nonblock =>         POSIX::O_NONBLOCK(),
};

sub
_get_flags {
    my $name = shift;
    return $flags->{$name};
}
}
1;
