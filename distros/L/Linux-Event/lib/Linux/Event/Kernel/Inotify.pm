package Linux::Event::Kernel::Inotify;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

use Carp qw(croak);
use File::Spec ();
use Scalar::Util qw(refaddr weaken);

require Linux::Event::Kernel::Inotify::Event;
require Linux::Event::Kernel::Inotify::Watch;
require Linux::Event::Loop;
require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

use constant {
    IN_ACCESS        => 0x00000001,
    IN_MODIFY        => 0x00000002,
    IN_ATTRIB        => 0x00000004,
    IN_CLOSE_WRITE   => 0x00000008,
    IN_CLOSE_NOWRITE => 0x00000010,
    IN_OPEN          => 0x00000020,
    IN_MOVED_FROM    => 0x00000040,
    IN_MOVED_TO      => 0x00000080,
    IN_CREATE        => 0x00000100,
    IN_DELETE        => 0x00000200,
    IN_DELETE_SELF   => 0x00000400,
    IN_MOVE_SELF     => 0x00000800,
    IN_ALL_EVENTS    => 0x00000fff,
    IN_UNMOUNT       => 0x00002000,
    IN_Q_OVERFLOW    => 0x00004000,
    IN_IGNORED       => 0x00008000,
    IN_ONLYDIR       => 0x01000000,
    IN_DONT_FOLLOW   => 0x02000000,
    IN_EXCL_UNLINK   => 0x04000000,
    IN_MASK_ADD      => 0x20000000,
    IN_ISDIR         => 0x40000000,
};

my @MONITORABLE = (
    [on_access        => IN_ACCESS],
    [on_modify        => IN_MODIFY],
    [on_attrib        => IN_ATTRIB],
    [on_close_write   => IN_CLOSE_WRITE],
    [on_close_nowrite => IN_CLOSE_NOWRITE],
    [on_open          => IN_OPEN],
    [on_moved_from    => IN_MOVED_FROM],
    [on_moved_to      => IN_MOVED_TO],
    [on_create        => IN_CREATE],
    [on_delete        => IN_DELETE],
    [on_delete_self   => IN_DELETE_SELF],
    [on_move_self     => IN_MOVE_SELF],
);

my @DISPATCH_ORDER = (
    [on_create        => IN_CREATE],
    [on_open          => IN_OPEN],
    [on_access        => IN_ACCESS],
    [on_modify        => IN_MODIFY],
    [on_attrib        => IN_ATTRIB],
    [on_close_write   => IN_CLOSE_WRITE],
    [on_close_nowrite => IN_CLOSE_NOWRITE],
    [on_moved_from    => IN_MOVED_FROM],
    [on_moved_to      => IN_MOVED_TO],
    [on_move_self     => IN_MOVE_SELF],
    [on_delete        => IN_DELETE],
    [on_delete_self   => IN_DELETE_SELF],
    [on_unmount       => IN_UNMOUNT],
    [on_ignored       => IN_IGNORED],
);

my %WATCH_CALLBACK = map { $_->[0] => 1 } @DISPATCH_ORDER;
$WATCH_CALLBACK{on_event} = 1;

my %CLASS_DESCRIPTOR;
my %LIVE;
my $NEXT_ID = 1;
my $DISPATCH_BUDGET = 256;

sub _class_descriptor ($class) {
    return $CLASS_DESCRIPTOR{$class} if exists $CLASS_DESCRIPTOR{$class};
    croak "$class is not a Linux::Event::Kernel::Inotify subclass"
        if !$class->isa(__PACKAGE__);
    return $CLASS_DESCRIPTOR{$class} = {
        on_overflow => $class->can('on_overflow'),
        on_error    => $class->can('on_error'),
    };
}

sub _effective_descriptor ($class, $option) {
    my %descriptor = %{ _class_descriptor($class) };
    for my $name (qw(on_overflow on_error)) {
        next if !exists $option->{$name};
        my $callback = delete $option->{$name};
        croak "new(): $name must be a coderef" if ref($callback) ne 'CODE';
        $descriptor{$name} = $callback;
    }
    return \%descriptor;
}

sub new ($class, %option) {
    croak 'new(): must be called as a class method' if ref $class;
    my $descriptor = _effective_descriptor($class, \%option);
    my $loop = delete $option{loop};
    croak 'new(): loop must be an object implementing add() and watch()'
        if defined($loop) && (!ref($loop) || !$loop->can('add')
            || !$loop->can('watch'));
    my $data = delete $option{data};
    croak 'new(): unknown options: ' . join(', ', sort keys %option) if %option;

    my $id = $NEXT_ID++;
    my $self = bless {
        id             => $id,
        descriptor     => $descriptor,
        data           => $data,
        state          => 'unattached',
        terminal       => 0,
        loop           => undef,
        fd             => undef,
        watcher        => undef,
        next_watch_id  => 1,
        watches        => {},
        watch_order    => [],
        groups         => {},
        group_identity => {},
        pending_events => [],
        resume_defer   => undef,
    }, $class;
    $LIVE{$id} = $self;
    weaken($LIVE{$id});

    $loop->add($self) if defined $loop;
    return $self;
}

sub _watch_event_mask ($callback) {
    my $mask = 0;
    for my $entry (@MONITORABLE) {
        $mask |= $entry->[1] if $callback->{ $entry->[0] };
    }
    $mask = IN_ALL_EVENTS if !$mask && $callback->{on_event};
    croak 'watch(): at least one monitorable callback or on_event is required'
        if !$mask;
    return $mask;
}

sub watch ($self, $path, %option) {
    croak 'watch(): Inotify is closed' if $self->{terminal};
    croak 'watch(): path must be a nonempty scalar'
        if !defined($path) || ref($path) || $path eq '';
    croak 'watch(): path must not contain NUL' if index($path, "\0") >= 0;

    my %callback;
    for my $name (keys %WATCH_CALLBACK) {
        next if !exists $option{$name};
        my $value = delete $option{$name};
        croak "watch(): $name must be a coderef" if ref($value) ne 'CODE';
        $callback{$name} = $value;
    }

    my %flag;
    for my $name (qw(only_dir dont_follow excl_unlink)) {
        next if !exists $option{$name};
        my $value = delete $option{$name};
        croak "watch(): $name must be 0 or 1"
            if !defined($value) || ref($value)
            || "$value" !~ /\A(?:0|1)\z/;
        $flag{$name} = $value ? 1 : 0;
    }

    croak 'watch(): unknown options: ' . join(', ', sort keys %option) if %option;
    my $event_mask = _watch_event_mask(\%callback);
    my $absolute = File::Spec->rel2abs($path);
    my $id = $self->{next_watch_id}++;

    my $watch = Linux::Event::Kernel::Inotify::Watch->_new(
        $self, $id, $absolute, $event_mask, \%callback, \%flag,
    );
    $self->{watches}{$id} = $watch;
    push @{ $self->{watch_order} }, $id
        if $self->{state} ne 'active';

    if ($self->{state} eq 'active') {
        my $ok = eval { $self->_activate_watch($watch); 1 };
        if (!$ok) {
            my $error = $@ || 'watch activation failed';
            delete $self->{watches}{$id};
            $watch->_terminate('failed');
            die $error;
        }
    }

    return $watch;
}

sub _attach_to_loop ($self, $loop) {
    croak 'add(): Inotify is not unattached'
        if $self->{terminal} || $self->{state} ne 'unattached' || $self->{loop};

    my $fd = _new_fd();
    $self->{fd} = $fd;
    $self->{loop} = $loop;

    my $ok = eval {
        for my $id (@{ $self->{watch_order} }) {
            my $watch = $self->{watches}{$id} // next;
            next if $watch->is_terminal;
            $self->_activate_watch($watch);
        }

        $self->{watcher} = $loop->watch(
            fd => $fd,
            _internal => 1,
            data => $self,
            read => \&_ready,
            error => \&_source_error,
            _callback_data_arg => 1,
        );
        1;
    };

    if (!$ok) {
        my $error = $@ || 'could not attach Inotify';
        eval { $self->{watcher}->cancel if $self->{watcher}; 1 };
        $self->{watcher} = undef;
        eval { _close_fd($fd); 1 };
        $self->{fd} = undef;
        $self->{loop} = undef;
        $self->{groups} = {};
        $self->{group_identity} = {};
        for my $watch (values %{ $self->{watches} }) {
            $watch->_reset_pending if $watch->is_active;
        }
        die $error;
    }

    $self->{state} = 'active';
    $self->{watch_order} = [];
    return $self;
}

sub _watch_kernel_mask ($watch, $event_mask = undef) {
    $event_mask = $watch->_event_mask if !defined $event_mask;
    my $mask = $event_mask;
    $mask |= IN_EXCL_UNLINK if $watch->_flag('excl_unlink');
    $mask |= IN_ONLYDIR if $watch->_flag('only_dir');
    $mask |= IN_DONT_FOLLOW if $watch->_flag('dont_follow');
    return $mask;
}

sub _watch_identity ($watch) {
    my @stat = $watch->_flag('dont_follow')
        ? lstat($watch->path)
        : stat($watch->path);
    return undef if !@stat;
    return $stat[0] . ':' . $stat[1];
}

sub _forget_group ($self, $group) {
    delete $self->{groups}{ $group->{wd} }
        if $self->{groups}{ $group->{wd} }
        && refaddr($self->{groups}{ $group->{wd} }) == refaddr($group);

    my $identity = $group->{identity};
    delete $self->{group_identity}{$identity}
        if defined($identity)
        && $self->{group_identity}{$identity}
        && refaddr($self->{group_identity}{$identity}) == refaddr($group);
    return;
}

sub _group_union_mask ($group) {
    my $mask = 0;
    for my $watch (@{ $group->{watches} }) {
        next if !$watch->is_active;
        $mask |= $watch->_event_mask;
    }
    return $mask;
}

sub _reprogram_group ($self, $group, $event_mask) {
    return 0 if !defined($self->{fd}) || !$event_mask;

    for my $watch (@{ $group->{watches} }) {
        next if !$watch->is_active;

        my $wd;
        my $ok = eval {
            $wd = _add_watch(
                $self->{fd},
                $watch->path,
                _watch_kernel_mask($watch, $event_mask),
            );
            1;
        };
        next if !$ok;

        if ($wd == $group->{wd}) {
            $group->{kernel_event_mask} = $event_mask;
            return 1;
        }

        # The pathname stopped naming the inode represented by this group.
        # Remove the accidental new watch and try another surviving alias.
        eval { _rm_watch($self->{fd}, $wd); 1 };
    }

    # Keeping a kernel-mask superset is safe because logical dispatch still
    # filters each record against the surviving Watch objects.
    return 0;
}

sub _activate_watch ($self, $watch) {
    my $mask = _watch_kernel_mask($watch);

    # IN_MASK_CREATE guarantees that a genuinely new logical subscription
    # cannot overwrite the mask of an inode that this inotify instance already
    # watches. A duplicate inode falls through to the explicit sharing path.
    my $wd = _add_watch_create($self->{fd}, $watch->path, $mask);

    if (defined $wd) {
        my $identity = _watch_identity($watch);
        my $group = {
            wd                => $wd,
            identity          => $identity,
            excl_unlink       => $watch->_flag('excl_unlink') ? 1 : 0,
            kernel_event_mask => $watch->_event_mask,
            watches           => [],
        };
        $self->{groups}{$wd} = $group;
        $self->{group_identity}{$identity} = $group if defined $identity;
        push @{ $group->{watches} }, $watch;
        $watch->_activate($wd);
        return $watch;
    }

    # The kernel reports that this inode is already watched. Where possible,
    # reject incompatible shared-watch policy before changing the kernel mask.
    my $identity = _watch_identity($watch);
    if (defined($identity) && (my $known = $self->{group_identity}{$identity})) {
        if (!!$known->{excl_unlink} != !!$watch->_flag('excl_unlink')) {
            croak 'watch(): excl_unlink must match existing watches for the same inode';
        }
    }

    $wd = _add_watch(
        $self->{fd},
        $watch->path,
        $mask | IN_MASK_ADD,
    );

    my $group = $self->{groups}{$wd};
    if (!$group) {
        # The pathname changed between the create-only probe and the sharing
        # call. Treat the object selected by the second syscall as a new group.
        $identity = _watch_identity($watch);
        $group = {
            wd                => $wd,
            identity          => $identity,
            excl_unlink       => $watch->_flag('excl_unlink') ? 1 : 0,
            kernel_event_mask => $watch->_event_mask,
            watches           => [],
        };
        $self->{groups}{$wd} = $group;
        $self->{group_identity}{$identity} = $group if defined $identity;
    }
    elsif (!!$group->{excl_unlink} != !!$watch->_flag('excl_unlink')) {
        # A rare pathname race may bypass the identity precheck. Restore the
        # previous logical union before reporting the incompatible request.
        $self->_reprogram_group($group, $group->{kernel_event_mask});
        croak 'watch(): excl_unlink must match existing watches for the same inode';
    }

    push @{ $group->{watches} }, $watch;
    $group->{kernel_event_mask} |= $watch->_event_mask;
    $watch->_activate($wd);
    return $watch;
}

sub _ready ($self) {
    return if $self->{state} ne 'active';

    if (@{ $self->{pending_events} }) {
        $self->_schedule_resume;
        return;
    }

    my $events;
    my $ok = eval {
        $events = _read_events($self->{fd});
        1;
    };
    if (!$ok) {
        return $self->_runtime_fail($@ || 'inotify read failed');
    }

    push @{ $self->{pending_events} }, @$events if @$events;
    $self->_drain_pending if @{ $self->{pending_events} };
    return;
}

sub _drain_pending ($self) {
    my $dispatched = 0;

    while ($self->{state} eq 'active'
            && @{ $self->{pending_events} }
            && $dispatched < $DISPATCH_BUDGET) {
        my $record = shift @{ $self->{pending_events} };
        $dispatched++;

        my $ok = eval {
            $self->_dispatch_record($record);
            1;
        };
        if (!$ok) {
            my $error = $@ || 'Inotify callback failed';
            $self->_schedule_resume
                if $self->{state} eq 'active'
                && @{ $self->{pending_events} };
            die $error;
        }
    }

    $self->_schedule_resume
        if $self->{state} eq 'active'
        && @{ $self->{pending_events} };
    return;
}

sub _schedule_resume ($self) {
    return if $self->{resume_defer} || $self->{state} ne 'active';
    my $loop = $self->{loop};
    return if !$loop;

    $self->{resume_defer} = $loop->defer(sub {
        $self->{resume_defer} = undef;
        return if $self->{state} ne 'active';
        $self->_drain_pending;
    });
    return;
}

sub _record_relevant ($watch, $mask) {
    return 1 if $mask & $watch->_event_mask;
    return 1 if ($mask & IN_UNMOUNT) && $watch->_callback('on_unmount');
    return 1 if ($mask & IN_IGNORED) && $watch->_callback('on_ignored');
    return 1 if ($mask & (IN_UNMOUNT | IN_IGNORED))
        && $watch->_callback('on_event');
    return 0;
}

sub _dispatch_record ($self, $record) {
    my ($wd, $mask, $cookie, $name) = @$record;

    if ($mask & IN_Q_OVERFLOW) {
        my $callback = $self->{descriptor}{on_overflow};
        if ($callback) {
            $callback->($self);
            return;
        }
        die "Linux::Event Inotify queue overflow\n";
    }

    my $group = $self->{groups}{$wd} // return;
    my $ignored = !!($mask & IN_IGNORED);
    $self->_forget_group($group) if $ignored;

    my @watch = @{ $group->{watches} };
    my $error;

    my $ok = eval {
        WATCH:
        for my $watch (@watch) {
            last WATCH if $self->{state} ne 'active';
            next WATCH if !$watch->is_active || $watch->_wd != $wd;
            next WATCH if !_record_relevant($watch, $mask);

            my $event = Linux::Event::Kernel::Inotify::Event->_new(
                $watch, $name, $mask, $cookie,
            );

            for my $entry (@DISPATCH_ORDER) {
                last if !$watch->is_active || $self->{state} ne 'active';
                my ($callback_name, $bit) = @$entry;
                next if !($mask & $bit);
                my $callback = $watch->_callback($callback_name) // next;
                $callback->($event);
            }

            next WATCH if !$watch->is_active || $self->{state} ne 'active';
            my $catch_all = $watch->_callback('on_event');
            $catch_all->($event) if $catch_all;
        }
        1;
    };
    $error = $@ if !$ok;

    if ($ignored) {
        for my $watch (@watch) {
            next if !$watch->is_active || $watch->_wd != $wd;
            delete $self->{watches}{ $watch->_id };
            $watch->_terminate('ignored');
        }
    }

    die $error if defined($error) && length($error);
    return;
}

sub _source_error ($self) {
    return if $self->{state} ne 'active';
    return $self->_runtime_fail("Linux::Event Inotify event source failed\n");
}

sub _runtime_fail ($self, $error) {
    my $callback = $self->{descriptor}{on_error};
    if ($callback) {
        my $ok = eval {
            $callback->($self, "$error");
            1;
        };
        my $callback_error = $@;
        $self->close if !$self->{terminal};
        die $callback_error if !$ok;
        return;
    }

    $self->close if !$self->{terminal};
    die $error;
}

sub _cancel_watch ($self, $watch) {
    return $watch if $watch->is_terminal;

    my $wd = $watch->_wd;
    my $error;

    delete $self->{watches}{ $watch->_id };
    if ($self->{state} ne 'active' && @{ $self->{watch_order} }) {
        my $id = $watch->_id;
        @{ $self->{watch_order} } = grep { $_ != $id }
            @{ $self->{watch_order} };
    }

    if (defined $wd && $self->{state} eq 'active') {
        my $group = $self->{groups}{$wd};
        if ($group) {
            @{ $group->{watches} } = grep {
                $_->_id != $watch->_id
            } @{ $group->{watches} };

            if (!@{ $group->{watches} }) {
                $self->_forget_group($group);
                my $ok = eval {
                    _rm_watch($self->{fd}, $wd);
                    1;
                };
                $error = $@ if !$ok;
            }
            else {
                my $union = _group_union_mask($group);
                $self->_reprogram_group($group, $union)
                    if $union != $group->{kernel_event_mask};
            }
        }
    }

    $watch->_terminate('cancelled');
    die $error if defined($error) && length($error);
    return $watch;
}

sub _fork_preflight ($self, $mode, $loop) {
    croak 'fork(): Inotify is not active in this Loop'
        if $self->{terminal} || $self->{state} ne 'active'
        || !$self->{loop} || refaddr($self->{loop}) != refaddr($loop);
    croak "fork(): Inotify does not support '$mode'"
        if $mode ne 'drop' && $mode ne 'clone' && $mode ne 'move';
    return 1;
}

sub _fork_child_clone ($self, $loop) {
    $self->{watcher} = undef;
    $self->{resume_defer} = undef;
    if (defined(my $fd = delete $self->{fd})) {
        _close_fd($fd);
    }
    $self->{pending_events} = [];
    $self->{groups} = {};
    $self->{group_identity} = {};
    my @order;
    for my $id (sort { $a <=> $b } keys %{ $self->{watches} }) {
        my $watch = $self->{watches}{$id};
        next if !$watch || $watch->is_terminal;
        $watch->_reset_pending;
        push @order, $id;
    }
    $self->{watch_order} = \@order;
    $self->{loop} = undef;
    $self->{state} = 'unattached';
    $self->_attach_to_loop($loop);
    return;
}

sub _fork_child_move ($self, $loop) {
    $self->{watcher} = undef;
    $self->{resume_defer} = undef;
    $self->{loop} = $loop;
    my $fd = $self->{fd};
    croak 'fork(): inherited Inotify fd is unavailable' if !defined $fd;
    $self->{watcher} = $loop->watch(
        fd => $fd,
        _internal => 1,
        data => $self,
        read => \&_ready,
        error => \&_source_error,
        _callback_data_arg => 1,
    );
    $self->_schedule_resume if @{ $self->{pending_events} };
    return;
}

sub _fork_child_drop ($self, $loop) {
    $self->{watcher} = undef;
    $self->{resume_defer} = undef;
    if (defined(my $fd = delete $self->{fd})) {
        _close_fd($fd);
    }
    for my $watch (values %{ $self->{watches} }) {
        $watch->_terminate('not_inherited') if !$watch->is_terminal;
    }
    $self->{pending_events} = [];
    $self->{groups} = {};
    $self->{group_identity} = {};
    $self->{watch_order} = [];
    $self->{loop} = undef;
    $self->{state} = 'not_inherited';
    $self->{terminal} = 1;
    delete $LIVE{ $self->{id} };
    return;
}

sub _fork_parent_move ($self, $child_pid) {
    if (my $defer = delete $self->{resume_defer}) {
        eval { $defer->cancel; 1 };
    }
    if (my $watcher = delete $self->{watcher}) {
        $watcher->cancel;
    }
    if (defined(my $fd = delete $self->{fd})) {
        _close_fd($fd);
    }
    for my $watch (values %{ $self->{watches} }) {
        $watch->_terminate('moved') if !$watch->is_terminal;
    }
    $self->{pending_events} = [];
    $self->{groups} = {};
    $self->{group_identity} = {};
    $self->{watch_order} = [];
    $self->{loop} = undef;
    $self->{state} = 'moved';
    $self->{terminal} = 1;
    delete $LIVE{ $self->{id} };
    return;
}

sub close ($self) {
    return $self if $self->{terminal};

    if (my $defer = delete $self->{resume_defer}) {
        eval { $defer->cancel; 1 };
    }
    if (my $watcher = delete $self->{watcher}) {
        eval { $watcher->cancel; 1 };
    }

    my $close_error;
    if (defined(my $fd = delete $self->{fd})) {
        my $ok = eval {
            _close_fd($fd);
            1;
        };
        $close_error = $@ if !$ok;
    }

    for my $watch (values %{ $self->{watches} }) {
        $watch->_terminate('closed') if !$watch->is_terminal;
    }

    $self->{watches} = {};
    $self->{watch_order} = [];
    $self->{groups} = {};
    $self->{group_identity} = {};
    $self->{pending_events} = [];
    $self->{loop} = undef;
    $self->{data} = undef;
    $self->{descriptor} = {};
    $self->{state} = 'closed';
    $self->{terminal} = 1;
    delete $LIVE{ $self->{id} };

    die $close_error if defined($close_error) && length($close_error);
    return $self;
}

sub loop ($self) { $self->{terminal} ? undef : $self->{loop} }
sub fd ($self) { $self->{state} eq 'active' ? $self->{fd} : undef }
sub state ($self) { $self->{state} }
sub is_active ($self) { $self->{state} eq 'active' }
sub is_terminal ($self) { !!$self->{terminal} }
sub watch_count ($self) { scalar keys %{ $self->{watches} } }

sub data ($self, @argument) {
    croak 'data(): Inotify is closed' if $self->{terminal};
    $self->{data} = $argument[0] if @argument;
    return $self->{data};
}

sub _objects_for_loop ($class, $loop) {
    my @object;
    for my $id (keys %LIVE) {
        my $object = $LIVE{$id} // next;
        next if $object->{terminal} || $object->{state} ne 'active';
        next if !$object->{loop}
            || refaddr($object->{loop}) != refaddr($loop);
        push @object, $object;
    }
    return \@object;
}

sub CLONE ($class) {
    %CLASS_DESCRIPTOR = ();
    %LIVE = ();
    return;
}

sub CLONE_SKIP ($class) { 1 }

sub DESTROY ($self) {
    eval { $self->close if !$self->{terminal}; 1 };
    return;
}

1;

__END__

=head1 NAME

Linux::Event::Kernel::Inotify - Watch files and directories for filesystem changes

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event::Loop;
  use Linux::Event::Kernel::Inotify;

  my $loop = Linux::Event::Loop->new;

  my $inotify = Linux::Event::Kernel::Inotify->new(
      loop => $loop,
  );

  my $watch = $inotify->watch(
      'log.txt',

      on_modify => sub ($event) {
          say $event->path . ' changed';
      },

      on_close_write => sub ($event) {
          say $event->path . ' finished being written';
      },
  );

  $loop->run;

=head1 DESCRIPTION

C<Linux::Event::Kernel::Inotify> provides Linux filesystem notifications through
L<Linux::Event::Loop>.

It can notify an application when a watched file or directory is:

=over 4

=item *

created

=item *

opened

=item *

read

=item *

modified

=item *

closed

=item *

renamed or moved

=item *

deleted

=item *

removed from the filesystem

=back

Linux::Event uses Linux C<inotify> internally.

=head1 THE THREE OBJECTS

Inotify uses three related object types.

=head2 Inotify

  my $inotify = Linux::Event::Kernel::Inotify->new(
      loop => $loop,
  );

The parent C<Inotify> object owns the Linux inotify instance.

One parent can contain many watches.

=head2 Watch

Calling C<watch> returns a
L<Linux::Event::Kernel::Inotify::Watch>:

  my $watch = $inotify->watch(
      'log.txt',
      on_modify => sub ($event) {
          ...
      },
  );

The Watch represents one logical filesystem subscription.

Use the Watch when you want to cancel that particular subscription or inspect
its state.

=head2 Event

When something happens, the callback receives a
L<Linux::Event::Kernel::Inotify::Event>:

  on_modify => sub ($event) {
      say $event->path;
  }

The Event describes the particular filesystem notification.

So the relationship is:

  Inotify
      |
      +-- Watch
      |     |
      |     +-- Event
      |     +-- Event
      |
      +-- Watch
            |
            +-- Event

=head1 WATCHING A FILE

For example:

  my $watch = $inotify->watch(
      '/var/log/myapp.log',

      on_modify => sub ($event) {
          say "log changed";
      },
  );

C<watch> returns immediately with a Watch object.

If the parent Inotify object is already attached to a Loop, the kernel watch is
activated immediately.

=head1 WATCHING A DIRECTORY

Watching a directory also reports activity involving entries inside that
directory:

  my $watch = $inotify->watch(
      '/srv/uploads',

      on_create => sub ($event) {
          say "created: " . $event->path;
      },

      on_delete => sub ($event) {
          say "deleted: " . $event->path;
      },
  );

For a directory event, C<< $event->name >> contains the child name supplied by
Linux.

C<< $event->path >> combines the watched directory with that name.

For example, if the watched path is:

  /srv/uploads

and Linux reports:

  photo.jpg

then:

  $event->path

returns:

  /srv/uploads/photo.jpg

=head1 WATCH PATHS BECOME ABSOLUTE

Relative paths are converted to absolute paths when C<watch> is called.

For example:

  my $watch = $inotify->watch(
      'log.txt',
      on_modify => sub ($event) {
          ...
      },
  );

captures the absolute path that C<log.txt> referred to at that moment.

A later C<chdir> does not silently retarget the Watch.

=head1 WATCH CALLBACKS

The ordinary filesystem callbacks are:

=over 4

=item C<on_access>

The watched file, or an entry within a watched directory, was accessed.

=item C<on_modify>

File contents were modified.

=item C<on_attrib>

Metadata changed, such as permissions, ownership, timestamps, or similar
attributes.

=item C<on_close_write>

A file that had been opened for writing was closed.

This is often useful when an application wants to wait until another program
has finished writing a file.

=item C<on_close_nowrite>

A file that had not been opened for writing was closed.

=item C<on_open>

The file was opened.

=item C<on_moved_from>

An entry was moved out of a watched directory.

=item C<on_moved_to>

An entry was moved into a watched directory.

=item C<on_create>

An entry was created inside a watched directory.

=item C<on_delete>

An entry was deleted from a watched directory.

=item C<on_delete_self>

The watched object itself was deleted.

=item C<on_move_self>

The watched object itself was moved.

=back

=head1 EVENT CALLBACK ARGUMENT

Specific callbacks receive one Event object:

  on_modify => sub ($event) {
      say $event->path;
  }

Unlike many other Linux::Event resources, the callback does not receive the
parent Inotify object or Watch as its first argument.

The Event can lead back to the logical Watch:

  my $watch = $event->watch;

and the Watch can lead back to its parent:

  my $inotify = $watch->inotify;

=head1 CATCH-ALL CALLBACK

=head2 on_event

C<on_event> receives every event selected for that logical Watch:

  my $watch = $inotify->watch(
      '/srv/data',

      on_modify => sub ($event) {
          say "modified: " . $event->path;
      },

      on_event => sub ($event) {
          say "raw mask: " . $event->mask;
      },
  );

Specific callbacks run first.

C<on_event> runs last for the same Event.

=head2 Using only on_event

C<on_event> may also be used by itself:

  my $watch = $inotify->watch(
      '/srv/data',

      on_event => sub ($event) {
          say $event->path;
      },
  );

When C<on_event> is the only monitorable callback, Linux::Event requests all
ordinary inotify events for that Watch.

When specific monitorable callbacks are also supplied, those callbacks define
the kernel event mask and C<on_event> sees the records selected by that mask.

=head1 CALLBACK ORDER

One Linux inotify record can contain more than one event bit.

When several callbacks match the same record, Linux::Event invokes them in this
order:

  on_create
  on_open
  on_access
  on_modify
  on_attrib
  on_close_write
  on_close_nowrite
  on_moved_from
  on_moved_to
  on_move_self
  on_delete
  on_delete_self
  on_unmount
  on_ignored
  on_event

The same Event object is passed to all callbacks for that logical Watch and
kernel record.

If one callback cancels the Watch, later callbacks for that Watch are not run.

=head1 MOVE COOKIES

Linux inotify provides a numeric cookie that can associate the two sides of a
rename or move.

For example:

  on_moved_from => sub ($event) {
      say "moved from cookie=" . $event->cookie;
  }

  on_moved_to => sub ($event) {
      say "moved to cookie=" . $event->cookie;
  }

Applications that need to pair rename operations can use:

  $event->cookie

to correlate related C<on_moved_from> and C<on_moved_to> notifications.

=head1 DIRECTORY EVENTS

=head2 is_directory

An Event reports whether Linux marked it as referring to a directory:

  if ($event->is_directory) {
      say $event->path . ' is a directory';
  }

This checks the Linux C<IN_ISDIR> event modifier.

=head1 WATCH LIFECYCLE EVENTS

Two additional callbacks describe kernel watch lifecycle conditions.

=head2 on_unmount

  on_unmount => sub ($event) {
      ...
  }

The filesystem containing the watched object was unmounted.

=head2 on_ignored

  on_ignored => sub ($event) {
      ...
  }

Linux has invalidated the underlying inotify watch.

For example, this may happen when the watched object disappears or the kernel
watch is otherwise removed.

C<on_unmount> and C<on_ignored> do not by themselves establish the ordinary
event mask.

Use at least one ordinary monitorable callback or C<on_event> when creating the
Watch.

=head1 CANCELLING ONE WATCH

=head2 cancel

C<watch> returns a Watch object:

  my $watch = $inotify->watch(
      '/srv/data',
      on_modify => sub ($event) {
          ...
      },
  );

Cancel only that subscription with:

  $watch->cancel;

Cancellation is immediate and terminal.

After C<cancel> returns, that Watch receives no later callback.

Calling C<cancel> again is harmless.

=head1 WATCH STATE

A Watch can be inspected through its own methods.

=head2 path

  my $path = $watch->path;

Return the absolute path captured when C<watch> was called.

=head2 state

  my $state = $watch->state;

Common Watch states include:

  pending
  active
  cancelled
  ignored
  closed
  failed

Managed-fork operations may also produce terminal states such as
C<not_inherited> or C<moved>.

=head2 is_active

  if ($watch->is_active) {
      ...
  }

Return true while the kernel subscription is active.

=head2 is_terminal

  if ($watch->is_terminal) {
      ...
  }

Return true once that Watch can no longer receive callbacks.

=head1 WATCHING BEFORE LOOP ATTACHMENT

An Inotify object can be configured before it is attached:

  my $inotify = Linux::Event::Kernel::Inotify->new;

  my $watch = $inotify->watch(
      '/srv/data',
      on_modify => sub ($event) {
          ...
      },
  );

  $loop->add($inotify);

Before attachment, the Watch is C<pending>.

Linux::Event records the logical Watch but does not create the kernel inotify
watch yet.

When the parent attaches to the Loop, its pending watches are activated.

This means you can fully configure the object before it begins receiving
filesystem events.

=head1 ADDING WATCHES AFTER ATTACHMENT

A running Inotify object can also receive new watches later:

  my $inotify = Linux::Event::Kernel::Inotify->new(
      loop => $loop,
  );

  my $watch = $inotify->watch(
      '/srv/data',
      on_modify => sub ($event) {
          ...
      },
  );

Because the parent is already active, C<watch> activates the new kernel
subscription before returning successfully.

=head1 SEVERAL LOGICAL WATCHES FOR THE SAME OBJECT

Linux itself may represent multiple subscriptions to the same underlying inode
with one kernel watch descriptor.

Linux::Event still treats each C<watch> call as its own logical Watch.

For example:

  my $logger = $inotify->watch(
      '/srv/data',
      on_modify => sub ($event) {
          log_change($event->path);
      },
  );

  my $counter = $inotify->watch(
      '/srv/data',
      on_modify => sub ($event) {
          $modified++;
      },
  );

Both logical Watches can receive the same underlying kernel event.

Cancelling one does not automatically cancel the other.

Linux::Event maintains the combined kernel mask required by the surviving
logical Watches.

=head1 WATCH OPTIONS

Three optional flags may be supplied to C<watch>.

=head2 only_dir

  only_dir => 1

Require the watched path to be a directory.

This maps to Linux C<IN_ONLYDIR> behavior.

=head2 dont_follow

  dont_follow => 1

Do not follow a symbolic link when establishing the watch.

This maps to Linux C<IN_DONT_FOLLOW>.

=head2 excl_unlink

  excl_unlink => 1

Use Linux C<IN_EXCL_UNLINK> behavior.

This can suppress events for directory children after those children have been
unlinked.

When several logical Watches resolve to the same underlying kernel watch,
C<excl_unlink> must agree between them.

=head1 PARENT OVERFLOW CALLBACK

=head2 on_overflow

The kernel inotify queue can overflow if filesystem events are produced faster
than they can be consumed.

Handle that condition on the parent Inotify object:

  my $inotify = Linux::Event::Kernel::Inotify->new(
      loop => $loop,

      on_overflow => sub ($self) {
          rebuild_filesystem_state();
      },
  );

Queue overflow is significant because some filesystem changes may have been
lost.

The safe response is usually to treat cached filesystem state as potentially
stale and rebuild or rescan it.

If C<on_overflow> is not provided, Linux::Event throws an exception instead of
silently pretending no information was lost.

=head1 PARENT ERROR CALLBACK

=head2 on_error

Fatal inotify-source errors may be handled with:

  my $inotify = Linux::Event::Kernel::Inotify->new(
      loop => $loop,

      on_error => sub ($self, $error) {
          warn "inotify failed: $error";
      },
  );

After a fatal source error, the parent Inotify object is closed.

=head1 APPLICATION DATA

=head2 data

The parent Inotify object can retain arbitrary application state:

  my $inotify = Linux::Event::Kernel::Inotify->new(
      loop => $loop,
      data => $state,
  );

Retrieve or replace it with:

  my $data = $inotify->data;

  $inotify->data($new_data);

The parent releases that data when it is closed.

=head1 CLOSING THE PARENT

=head2 close

  $inotify->close;

Closing the parent is different from cancelling one Watch.

C<close>:

=over 4

=item *

removes the Inotify object from its Loop

=item *

closes the Linux inotify descriptor

=item *

makes every remaining child Watch terminal

=item *

discards pending decoded events

=item *

releases parent application data

=back

C<close> is idempotent.

After parent close, no Watch can receive another callback.

=head1 ZERO WATCHES

An attached Inotify object does not automatically close merely because it has
zero Watches.

For example:

  my $inotify = Linux::Event::Kernel::Inotify->new(
      loop => $loop,
  );

may remain active with no current subscriptions.

This allows applications to add Watches dynamically later.

Use:

  $inotify->close;

when the whole inotify service is no longer needed.

=head1 PARENT STATE

=head2 state

  my $state = $inotify->state;

Normal parent states include:

  unattached
  active
  closed

Managed-fork operations may also produce C<not_inherited> or C<moved>.

=head2 is_active

  if ($inotify->is_active) {
      ...
  }

Return true while attached to a Loop.

=head2 is_terminal

  if ($inotify->is_terminal) {
      ...
  }

Return true once the parent can no longer be used.

=head2 watch_count

  my $count = $inotify->watch_count;

Return the number of currently retained logical Watch objects.

=head2 fd

  my $fd = $inotify->fd;

Return the active inotify file descriptor.

It is undefined while detached or after termination.

Most applications do not need this method.

=head2 loop

  my $loop = $inotify->loop;

Return the owning Loop while the parent remains usable.

=head1 EVENT INFORMATION

Every watch callback receives an immutable Event value.

The most useful methods are:

=over 4

=item C<path>

The composed useful path for the event.

=item C<name>

The optional child name supplied by Linux for directory events.

=item C<watch>

The logical Watch that received the event.

=item C<mask>

The raw Linux inotify event mask.

=item C<cookie>

The Linux move/rename cookie.

=item C<is_directory>

Whether Linux marked the event as referring to a directory.

=back

For example:

  on_create => sub ($event) {
      say "path: " . $event->path;

      if ($event->is_directory) {
          say "created object is a directory";
      }
  }

=head1 DISPATCH FAIRNESS

A very busy filesystem can produce many inotify records in one read.

Linux::Event limits one dispatch pass to 256 decoded records.

If more records remain, Linux::Event schedules continuation through:

  $loop->defer(...)

This allows sockets, timers, processes, and other ready resources to continue
making progress instead of allowing a filesystem burst to monopolize the
Loop.

=head1 CALLBACK EXCEPTIONS

If a Watch callback throws, dispatch of that current record stops and the
exception propagates through the Loop.

Already-read later filesystem records are retained and may be resumed on a
later Loop turn.

This prevents one callback exception from silently discarding already-decoded
kernel events.

=head1 LOOP-AWARE FORKING

Inotify supports C<clone> and C<move> with
L<Linux::Event::Loop> managed C<fork>.

=head2 clone

  my $pid = $loop->fork(
      clone => [$inotify],
  );

The parent keeps its existing Inotify resource.

The child creates a fresh independent Linux inotify instance and recreates its
logical Watches there.

The parent and child then observe filesystem changes independently.

=head2 move

  my $pid = $loop->fork(
      move => [$inotify],
  );

The child keeps the inherited inotify instance and attaches it to the child's
fresh Loop.

After the child reconstruction succeeds, the parent gives up its copy.

The parent Inotify and its Watch objects become terminal with state C<moved>.

=head2 Unlisted Inotify objects

An active Inotify omitted from all disposition lists remains parent-only.

Its inherited child copy is discarded and becomes C<not_inherited>.

=head2 share

C<share> is not supported for Inotify.

=head1 IMPLEMENTATION MODEL

One Inotify parent owns one Linux inotify file descriptor.

Many logical Watch objects may share underlying kernel watch descriptors when
they refer to the same inode.

Linux::Event keeps the logical subscriptions separate and performs fan-out at
dispatch time.

This provides independent cancellation and callbacks without requiring the
application to understand the kernel's watch-descriptor sharing behavior.

=head1 SEE ALSO

L<Linux::Event>,
L<Linux::Event::Loop>,
L<Linux::Event::Kernel::Inotify::Watch>,
L<Linux::Event::Kernel::Inotify::Event>.

=cut
