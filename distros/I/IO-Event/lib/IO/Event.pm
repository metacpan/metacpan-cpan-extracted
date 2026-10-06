
our $debug = 0;
our $edebug = 0;
our $sdebug = 0;

{
package IO::Event;

# ABSTRACT: Tied Filehandles for Nonblocking IO with Object Callbacks
our $VERSION = '0.814'; # VERSION

use strict;
no strict 'refs';
use warnings;
use Carp qw(confess);

our $base;
our @ISA;  ## no critic (ClassHierarchies::ProhibitExplicitISA)

sub idle
{
    IO::Event->import('no_emulate_Event') unless $base;
    &{$base . "::idle"}(@_);
}

sub loop
{
    IO::Event->import('no_emulate_Event') unless $base;
    &{$base . "::loop"}(@_);
}

sub unloop
{
    &{$base . "::unloop"}(@_);
}

sub unloop_all
{
    &{$base . "::unloop_all"}(@_);
}

sub timer
{
    shift;
    IO::Event->import('no_emulate_Event') unless $base;
    $base->timer(@_);
}

sub new
{
    IO::Event->import('no_emulate_Event') unless $base;
    &{$base . "::new"}(@_);
}

sub import
{
    my ($pkg, @stuff) = @_;
    for my $s (@stuff) {
        if ($s eq 'emulate_Event') {
            $base = 'IO::Event::Emulate';
            require IO::Event::Emulate;
        } elsif ($s eq 'no_emulate_Event') {
            require Event;
            # Event only uses Time::HiRes when its import is called,
            # otherwise timers have one second granularity
            Event->import;
            require IO::Event::Event;
            $base = 'IO::Event::Event';
        } elsif ($s eq 'AnyEvent') {
            require AnyEvent;  ## no critic (Community::DiscouragedModules)
            require IO::Event::AnyEvent;
            $base = 'IO::Event::AnyEvent';
        } else {
            die "unknown import: $s";
        }
        @ISA = $base;  ## no critic (ClassHierarchies::ProhibitExplicitISA)
    }
    return 1;
}

sub AUTOLOAD
{
    my $self = shift;
    our $AUTOLOAD;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;

    # for whatever reason, UNIVERSAL::can()
    # doesn't seem to work on some filehandles

    my $r;
    my @r;
    my $fh = ${*$self}{ie_fh};
    if ($fh) {
        if (wantarray) {  ## no critic (Community::Wantarray)
            eval { @r = $fh->$method(@_) };
        } else {
            eval { $r = $fh->$method(@_) };
        }
        if ($@ && $@ =~ /Can't locate object method "(.*?)" via package/) {
            my $event = ${*$self}{ie_event};
            if ($1 ne $method) {
                # nothing to do
            } elsif ($event && $event->can($method)) {
                if (wantarray) {  ## no critic (Community::Wantarray)
                    eval { @r = $event->$method(@_) };
                } else {
                    eval { $r = $event->$method(@_) };
                }
            } else {
                confess qq{Can't locate object method "$method" via "@{[ ref($self) ]}", "@{[ ref($fh)||'IO::Handle' ]}", or "@{[ ref($event) ]}"};
            }
        }
    } else {
        my $event = ${*$self}{ie_event};
        if ($event && $event->can($method)) {
            if (wantarray) {  ## no critic (Community::Wantarray)
                eval { @r = $event->$method(@_) };
            } else {
                eval { $r = $event->$method(@_) };
            }
        } else {
            confess qq{Can't locate object method "$method" via "@{[ ref($self) ]}" or "@{[ ref($event) ]}"};
        }
    }
    confess $@ if $@;
    return @r if wantarray;  ## no critic (Community::Wantarray)
    return $r;
}

}{package IO::Event::Common;

use strict;
use warnings;
use Symbol;
use Carp;
require IO::Handle;
use POSIX qw(BUFSIZ EBADF EINVAL ETIMEDOUT);
use Errno ();
use Socket;
use Scalar::Util qw(weaken reftype);
use Time::HiRes qw(time);

our $in_callback = 0;

my %fh_table;
my %rxcache;

my @pending_callbacks;

sub display_bits
{
    print STDERR unpack("b*", $_[0]);
}

sub count_bits
{
    scalar(grep { $_ } split(//, unpack("b*", $_[0])));
}

sub display_want
{
    my ($name, $vec, %hash) = @_;
    my ($pkg, $file, $line) = caller;
    print STDERR "\n\nAT $file: $line\n";
    print STDERR "$name\n";
    for my $ioe (values %hash) {
        printf STDERR "%03d-", fileno(${*$ioe}{ie_fh});
        # display_bits(${*$ioe}{ie_vec});
        print STDERR "\n";
    }
    print STDERR "----------";
    display_bits($vec);
    printf STDERR " - %d\n", count_bits($vec);
    print STDERR scalar(keys(%hash));
    print STDERR "\n";
    exit 1;
}

my $counter = 1;

sub new
{
    my ($pkg, $fh, $handler, $options) = @_;

    # stolen from IO::Handle
    my $self = bless gensym(), $pkg;

    $handler = (caller(2))[0]
        unless $handler;

    confess unless ref $fh;

    unless (ref $options) {
        $options = {
            description => $options,
        };
    }

    # some bits stolen from IO::Socket
    ${*$self}{ie_fh} = $fh;
    ${*$self}{ie_handler} = $handler;
    ${*$self}{ie_ibuf} = '';
    ${*$self}{ie_obuf} = '';
    ${*$self}{ie_obufsize} = BUFSIZ*4;
    ${*$self}{ie_autoread} = 1;
    ${*$self}{ie_pending} = {};
    ${*$self}{ie_desc} = $options->{description} || "wrapper for $fh";
    ${*$self}{ie_writeclosed} = EINVAL if $options->{read_only};
    ${*$self}{ie_readclosed} = EINVAL if $options->{write_only};

    $self->ie_register();
    $fh->blocking(0);
    print "New IO::Event: ${*$self}{ie_desc} - now nonblocking\n" if $debug;

    # stolen from IO::Multiplex
    tie(*$self, $pkg, $self);
    return $self;
}

sub reset
{
    my $self = shift;
    delete ${*$self}{ie_writeclosed};
    delete ${*$self}{ie_readclosed};
    delete ${*$self}{ie_eofinvoked};
    delete ${*$self}{ie_overflowinvoked};
}

# mark as listener
sub listener
{
    my ($self, $listener) = @_;
    $listener = 1 unless defined $listener;
    my $o = ${*$self}{ie_listener};
    ${*$self}{ie_listener} = $listener;
    return $o;
}

# call out
sub ie_invoke
{
    my ($self, $required, $method, @args) = @_;

    if ($in_callback && ! ${*$self}->{ie_reentrant}) {
        # we'll do this later
        push(@pending_callbacks, [ $self, $required, $method, @args ])
            unless exists ${*$self}{ie_pending}{$method};
        ${*$self}{ie_pending}{$method} = 1; # prevent double invocation.  needed?
        print STDERR "Delaying invocation of $method on ${*$self}{ie_desc} because we're already in a callback\n" if $debug;
        return;
    }

    local($in_callback) = 1;

    $self->ie_do_invoke($required, $method, @args);

    while (@pending_callbacks) {
        my ($ie, $req, $meth, @a) = @{shift @pending_callbacks};
        delete ${*$ie}{ie_pending}{$meth};
        print STDERR "Processing delayed invocation of $meth on ${*$ie}{ie_desc}\n" if $debug;
        $ie->ie_do_invoke($req, $meth, @a);
    }
    return;
}

sub ie_do_invoke
{
    my ($self, $required, $method, @args) = @_;

    print STDERR "invoking ${*$self}{ie_fileno} ${*$self}{ie_handler}->$method\n"
        if $debug;

    return if ! $required && ! ${*$self}{ie_handler}->can($method);
    if ($debug) {
        my ($pkg, $line, $func) = caller();
        print "DISPATCHING $method on ${*$self}{ie_desc} from $func at line $line\n";
    }
    eval {
        ${*$self}{ie_handler}->$method($self, @args);
    };

    print STDERR "return from ${*$self}{ie_fileno} ${*$self}{ie_handler}->$method handler: $@\n" if $debug;

    return unless $@;
    if (${*$self}{ie_handler}->can('ie_died')) {
        ${*$self}{ie_handler}->ie_died($self, $method, $@);
    } else {
        confess $@;
        exit 1;  ## no critic (ControlStructures::ProhibitUnreachableCode)
    }

}

#
# we use a single event handler so that the AUTOLOAD
# function can try a single $event object when looking for
# methods
#
sub ie_dispatch
{
    print STDERR "D" if $sdebug;
    my ($self, $ievent) = @_;
    my $fh = ${*$self}{ie_fh};
    my $got = $ievent->got;
    {
        if ($got & Event::Watcher::R()) {
            last if $self->ie_dispatch_read($fh);
        }
        if ($got & Event::Watcher::W()) {
            last if $self->ie_dispatch_write($fh);
        }
        if ($got & Event::Watcher::E()) {
            $self->ie_dispatch_exception($fh);
        }
        if ($got & Event::Watcher::T()) {
            $self->ie_dispatch_timer();
        }
    }
}


sub ie_dispatch_read
{
    my ($self, $fh) = @_;
    printf STDERR "R%d", $self->fileno if $sdebug;
    if (${*$self}{ie_listener}) {
        $self->ie_invoke(1, 'ie_connection');
    } elsif (${*$self}{ie_autoread}) {
        $self->ie_input();
    } else {
        $self->ie_invoke(1, 'ie_read_ready', $fh);
    }
    return 1 if ${*$self}{ie_writeclosed} && ${*$self}{ie_readclosed};
    return 0;
}

sub ie_dispatch_write
{
    my ($self, $fh) = @_;
    printf STDERR "W%d", $self->fileno if $sdebug;
    if (${*$self}{ie_connecting}) {
        $self->writeevents(0);
        delete ${*$self}{ie_connecting};
        delete ${*$self}{ie_connect_timeout};
        $self->ie_invoke(0, 'ie_connected');
    } else {
        my $obuf = \${*$self}{ie_obuf};
        my $rv;
        if (length($$obuf)) {
            $rv = syswrite($fh, $$obuf);
            if (defined $rv) {
                substr($$obuf, 0, $rv) = '';
            } elsif ($!{EAGAIN} || $!{EWOULDBLOCK}) {
                # this shouldn't happen, but
                # it's not that big a deal
            } else {
                # the file descriptor is toast
                ${*$self}{ie_writeclosed} = $!;
                $self->ie_invoke(0, 'ie_werror', $obuf);
            }
        }
        if (${*$self}{ie_closerequested}) {
            if (! length($$obuf)) {
                $self->ie_deregister();
                ${*$self}{ie_fh}->close();
                delete ${*$self}{ie_closerequested};
            }
        } elsif (${*$self}{ie_shutdownrequested}) {
            if (! length($$obuf)) {
                shutdown(${*$self}{ie_fh}, 1);
                ${*$self}{ie_writeclosed} = 1;
                delete ${*$self}{ie_shutdownrequested};
                $self->ie_invoke(0, 'ie_outputdone', $obuf, 0);
            }
        } else {
            $self->ie_invoke(0, 'ie_output', $obuf, $rv);
            return 1 if ${*$self}{ie_writeclosed}
                && ${*$self}{ie_readclosed};
            if (! length($$obuf)) {
                $self->ie_invoke(0, 'ie_outputdone', $obuf, 1);
                return 1 if ${*$self}{ie_writeclosed}
                    && ${*$self}{ie_readclosed};
                if (! length($$obuf)) {
                    $self->writeevents(0);
                }
            }
            if (length($$obuf) > ${*$self}{ie_obufsize}) {
                ${*$self}{ie_overflowinvoked} = 1;
                $self->ie_invoke(0, 'ie_outputoverflow', 1, $obuf);
            } elsif (${*$self}{ie_overflowinvoked}) {
                ${*$self}{ie_overflowinvoked} = 0;
                $self->ie_invoke(0, 'ie_outputoverflow', 0, $obuf);
            }
        }
    }
    return 1 if ${*$self}{ie_writeclosed} && ${*$self}{ie_readclosed};
    return 0;
}

sub ie_dispatch_exception
{
    my ($self, $fh) = @_;
    printf STDERR "E%d", fileno(${*$self}{ie_fh}) if $sdebug;
    if (${*$self}{ie_closerequested}) {
        $self->forceclose;
    } elsif (${*$self}{ie_writeclosed} && ${*$self}{ie_readclosed}) {
        $self->forceclose;
    } elsif ($fh->eof) {
        if (length(${*$self}{ie_ibuf})) {
            $self->ie_invoke(0, 'ie_input', \${*$self}{ie_ibuf});
        }
        if (${*$self}{ie_eofinvoked}++) {
            warn "EOF repeat";
        } else {
            ${*$self}{ie_closecalled} = 0;
            $self->ie_invoke(0, 'ie_eof', \${*$self}{ie_ibuf});
            unless (${*$self}{ie_closecalled}) {
                $self->close;
            }
        }
    } else {
        # print STDERR "!?!";
        $self->ie_invoke(0, 'ie_exception');
    }
}


sub ie_dispatch_timer
{
    my ($self) = @_;
    printf STDERR "T%d", fileno(${*$self}{ie_fh}) if $sdebug;
    if (${*$self}{ie_connecting}
        && ${*$self}{ie_connect_timeout}
        && time >= ${*$self}{ie_connect_timeout})
    {
        delete ${*$self}{ie_connect_timeout};
        $self->ie_invoke(0, 'ie_connect_failed', ETIMEDOUT)
            or $self->ie_invoke(0, 'ie_timer');
    } else {
        $self->ie_invoke(0, 'ie_timer');
    }
}


# same name as handler since we want to intercept invocations
# when processing pending callbacks.  Why?
sub ie_input
{
    my $self = shift;
    my $ibuf = \${*$self}{ie_ibuf};

    #
    # We'll loop just to make sure we don't miss an event
    #
    for (;;) {
        my $ol = length($$ibuf);
        my $rv = ${*$self}{ie_fh}->sysread($$ibuf, BUFSIZ, $ol);

#       my $x = defined($rv) ? $rv : "$!";          # LOST EVENTS
#       print STDERR "<INPUT ${*$self}{ie_desc}=$x>";       # LOST EVENTS

        if ($rv) {
            delete ${*$self}{ie_readclosed};
        } elsif (defined($rv)) {
            # must be 0 and closed!
            ${*$self}{ie_readclosed} = 1;
            last;
        } elsif ($!{EAGAIN} || $!{EWOULDBLOCK}) {
            # readclosed = 0?
            last;
        } else {
            # errors other than EAGAIN aren't recoverable
            ${*$self}{ie_readclosed} = $!;
            last;
        }

        $self->ie_invoke(1, 'ie_input', $ibuf);
        last if ${*$self}{ie_readclosed};
    }

    if (${*$self}{ie_readclosed}) {
        $self->ie_invoke(1, 'ie_input', $ibuf)
            if length($$ibuf);
        if (${*$self}{ie_connecting}) {
            ${*$self}{ie_writeclosed} = $!;
            $self->writeevents(0);
            delete ${*$self}{ie_connecting};
            delete ${*$self}{ie_connect_timeout};
            $self->ie_invoke(0, 'ie_connect_failed', $!);
        } else {
            $self->ie_invoke(0, 'ie_eof', $ibuf)
                unless ${*$self}{ie_eofinvoked}++;
        }
        $self->readevents(0);
    }
}

sub reentrant
{
    my $self = shift;
    my $old = ${*$self}{ie_reentrant};
    if (@_) {
        ${*$self}{ie_reentrant} = $_[0];
    }
    return $old;
}

sub output_bufsize
{
    my $self = shift;
    my $old = ${*$self}{ie_obufsize};
    if (@_) {
        ${*$self}{ie_obufsize} = $_[0];
        if (length(${*$self}{ie_obuf}) > ${*$self}{ie_obufsize}) {
            $self->ie_invoke(0, 'ie_outputoverflow', 1, ${*$self}{ie_obuf});
            ${*$self}{ie_overflowinvoked} = 1;
        } elsif (${*$self}{ie_overflowinvoked}) {
            $self->ie_invoke(0, 'ie_outputoverflow', 0, ${*$self}{ie_obuf});
            ${*$self}{ie_overflowinvoked} = 0;
        }
        # while this should trigger callbacks, we don't want to assume
        # that our caller's code is re-enterant.
    }
    return $old;
}

# get/set autoread
sub autoread
{
    my $self = shift;
    my $old = ${*$self}{ie_autoread};
    if (@_) {
        ${*$self}{ie_autoread} = $_[0];
        if (${*$self}{ie_readclosed}) {
            delete ${*$self}{ie_readclosed};
            $self->readevents(1);
        }
    }
    return $old;
}

sub writeevents
{
    my $self = shift;
    my $old = ${*$self}{ie_want_write_events};
    return !! $old unless @_;
    my $new = !! shift;
    return $old if defined($old) && $old eq $new;
    ${*$self}{ie_want_write_events} = $new;
    $self->set_write_polling($new);
    return $old;
}

sub readevents
{
    my $self = shift;
    my $old = ${*$self}{ie_want_read_events};
    return !! $old unless @_;
    my $new = !! shift;
#   print STDERR "<READEVENTS ${*$self}{ie_desc} = $new>";      # LOST EVENTS
    return $old if defined($old) && $old eq $new;
    ${*$self}{ie_want_read_events} = $new;
    $self->set_read_polling($new);
    return $old;
}

sub drain
{
    my $self = shift;
    $self->writeevents(1);
}

# register with Event
sub ie_register
{
    my ($self) = @_;
    my $fh = ${*$self}{ie_fh};
    $fh->blocking(0);
    $fh->autoflush(1);

    my $fileno = ${*$self}{ie_fileno} = $fh->fileno;
    return ($fh, $fileno);
}

# deregister with Event
sub ie_deregister
{
    my ($self) = @_;
    my $fh = ${*$self}{ie_fh};
    delete $fh_table{$fh};
    $self->readevents(0);
    $self->writeevents(0);
}

# the standard max() function
sub ie_max
{
    my ($max, @stuff) = @_;
    for my $t (@stuff) {
        $max = $t if $t > $max;
    }
    return $max;
}

# get the Filehandle
sub filehandle
{
    my ($self) = @_;
    return ${*$self}{ie_fh};
}

# get the Event
sub event
{
    my ($self) = @_;
    return ${*$self}{ie_event};
}

# set the handler
sub handler
{
    my $self = shift;
    my $old = ${*$self}{ie_handler};
    ${*$self}{ie_handler} = $_[0]
        if @_;
    return $old;
}

# is there enough?
sub can_read
{
    my ($self, $length) = @_;
    my $l = length(${*$self}{ie_ibuf});
    return $l if $l && $l >= $length;
    return "0 but true" if $length <= 0;
    return 0;
}

# reads N characters or returns undef if it can't
sub getsome
{
    my ($self, $length) = @_;
    return undef unless ${*$self}{ie_autoread};
    my $ibuf = \${*$self}{ie_ibuf};
    $length = length($$ibuf)
        unless defined $length;
    my $tmp = substr($$ibuf, 0, $length);
    substr($$ibuf, 0, $length) = '';
    return undef if ! length($tmp) && ! $self->eof2;
    return $tmp;
}

# from base perl
# will this work right for SOCK_DGRAM?
sub connect
{
    my $self = shift;
    my $fh = ${*$self}{ie_fh};
    my $rv = $fh->connect(@_);
    $self->reset;
    $self->readevents(1);
    unless($fh->connected()) {
        ${*$self}{ie_connecting} = 1;
        $self->writeevents(1);
        ${*$self}{ie_connect_timeout} = time
            + ${*$self}{ie_socket_timeout}
            if ${*$self}{ie_socket_timeout};
    }
    return $rv;
}

# from IO::Socket
sub listen
{
    my $self = shift;
    my $fh = ${*$self}{ie_fh};
    my $rv = $fh->listen();
    $self->listener(1);
    return $rv;
}

# from IO::Socket
sub accept
{
    my ($self, $handler) = @_;
    my $fh = ${*$self}{ie_fh};
    my $newfh = $fh->accept();
    return undef unless $newfh;

    # it appears that sockdomain isn't set on accept()ed sockets
    my $sd = $fh->sockdomain;

    my $desc;
    if ($sd == &AF_INET) {
        $desc = sprintf "Accepted socket from %s:%s to %s:%s",
            $newfh->peerhost, $newfh->peerport,
            $newfh->sockhost, $newfh->sockport;
    } elsif ($sd == &AF_UNIX) {
        # Unset peerpath crashes on FreeBSD 9
        my $pp = eval { $newfh->peerpath };
        if ($pp) {
            $desc = sprintf "Accepted socket from %s to %s",
                $pp, $newfh->hostpath;
        } else {
            $desc = sprintf "Accepted socket from to %s",
                $newfh->hostpath;
        }
    } else {
        $desc = "Accept for ${*$self}{ie_desc}";
    }
    $handler = ${*$self}{ie_handler}
        unless defined $handler;
    my $new = IO::Event->new($newfh, $handler, $desc);
    ${*$new}{ie_obufsize} = ${*$self}{ie_obufsize};
    ${*$new}{ie_reentrant} = ${*$self}{ie_reentrant};
    return $new;
}

# not the same as IO::Handle
sub input_record_separator
{
    my $self = shift;
    my $old = ${*$self}{ie_irs};
    ${*$self}{ie_irs} = $_[0]
        if @_;
    if ($debug) {
        my $fn = $self->fileno;
        my $x = ${*$self}{ie_irs};
        $x =~ s/\n/\\n/g;
        print "input_record_separator($fn) = '$x'\n";
    }
    return $old;
}

# 0 = read
# 1 = write
# 2 = both
sub shutdown
{
    my ($self, $what) = @_;
    my $r;
    if ($what == 1 || $what == 2) {
        if (length(${*$self}{ie_obuf})) {
            ${*$self}{ie_shutdownrequested} = $what;
            if ($what == 2) {
                $r = shutdown(${*$self}{ie_fh}, 0)
            }
        } else {
            $r = shutdown(${*$self}{ie_fh}, $what);
            ${*$self}{ie_writeclosed} = 1;
        }
    } elsif ($what == 0) {
        $r = shutdown(${*$self}{ie_fh}, 0);
    } else {
        die;
    }
    if ($what == 0 || $what == 2) {
        ${*$self}{ie_readclosed} = 1;
    }
    return 1 unless defined($r);
    return $r;
}

# from IO::Handle
sub close
{
    my ($self) = @_;
    my $obuf = \${*$self}{ie_obuf};
    ${*$self}{ie_closecalled} = 1;
    if (length($$obuf)) {
        ${*$self}{ie_closerequested} = 1;
        ${*$self}{ie_writeclosed} = 1;
        ${*$self}{ie_readclosed} = 1;
    } else {
        return $self->forceclose;
    }
}

sub forceclose
{
    my ($self) = @_;
    $self->ie_deregister();
    my $ret = ${*$self}{ie_fh}->close();
    ${*$self}{ie_writeclosed} = 1;
    ${*$self}{ie_readclosed} = 1;
    ${*$self}{ie_totallyclosed} = 1;
    print STDERR "forceclose(${*$self}{ie_desc})\n" if $debug;
    return $ret;
}

# from IO::Handle
sub open
{
    my $self = shift;
    my $fh = ${*$self}{ie_fh};
    $self->ie_deregister();
    $self->close()
        if $fh->opened;
    $self->reset;
    my $r;
    if (@_ == 1) {
        $r = CORE::open($fh, $_[0]);
    } elsif (@_ == 2) {
        $r = CORE::open($fh, $_[0], $_[1]);
    } elsif (@_ == 3) {
        $r = CORE::open($fh, $_[0], $_[1], $_[4]);
    } elsif (@_ > 3) {
        $r = CORE::open($fh, $_[0], $_[1], $_[4], @_);
    } else {
        confess("open w/o enoug args");
    }
    return undef unless defined $r;
    $self->ie_register();
    return $r;
}


# from IO::Handle       VAR LENGTH [OFFSET]
#
# this returns nothing unless there is enough to fill
# the request or it's at eof
#
sub sysread
{
    my $self = shift;

    unless (${*$self}{ie_autoread}) {
        my $buf = shift;
        my $length = shift;
        my $rv = ${*$self}{ie_fh}->sysread($buf, $length, @_);

        if ($rv) {
            delete ${*$self}{ie_readclosed};
        } elsif (defined($rv)) {
            # must be 0 and closed!
            ${*$self}{ie_readclosed} = 1;
        } elsif ($!{EAGAIN} || $!{EWOULDBLOCK}) {
            # nothing there
        } else {
            # errors other than EAGAIN aren't recoverable
            ${*$self}{ie_readclosed} = $!;
        }
        return $rv;
    }

    my $ibuf = \${*$self}{ie_ibuf};
    my $length = length($$ibuf);

    return undef unless $length >= $_[1] || $self->eof2;

    (defined $_[2] ?
        substr ($_[0], $_[2], length($_[0]))
        : $_[0])
            = substr($$ibuf, 0, $_[1]);

    substr($$ibuf, 0, $_[1]) = '';
    return ($length-length($$ibuf));
}

# from IO::Handle
sub syswrite
{
    my ($self, $data, $length, $offset) = @_;
    if (defined $offset or defined $length) {
        return $self->print(substr($data, $offset, $length));
    } else {
        return $self->print($data);
    }
}

# like Data::LineBuffer
sub get
{
    my $self = shift;
    return undef unless ${*$self}{ie_autoread};
    my $ibuf = \${*$self}{ie_ibuf};
    my $irs = "\n";
    my $index = index($$ibuf, $irs);
    if ($index < 0) {
        return undef unless $self->eof2;
        my $l = $$ibuf;
        $$ibuf = '';
        return undef unless length($l);
        return $l;
    }
    my $line = substr($$ibuf, 0, $index - length($irs) + 1);
    substr($$ibuf, 0, $index + 1) = '';
    return $line;
}

# like Data::LineBuffer
# input_record_separator is always "\n".
sub unget
{
    my $self = shift;
    my $irs = "\n";
    no warnings;
    substr(${*$self}{ie_ibuf}, 0, 0)
        = join($irs, @_, undef);
}

# from IO::Handle
sub getline
{
    my $self = shift;
    return undef unless ${*$self}{ie_autoread};
    my $ibuf = \${*$self}{ie_ibuf};
    my $fh = ${*$self}{ie_fh};
    my $irs = exists ${*$self}{ie_irs} ? ${*$self}{ie_irs} : $/;
    my $line;


    # perl's handling if input record separators is
    # not completely simple.
    $irs = $$irs if ref $irs;
    my $index;
    if ($irs =~ /^\d/ && int($irs)) {
        if ($irs > 0 && length($$ibuf) >= $irs) {
            $line = substr($$ibuf, 0, $irs);
        } elsif ($self->eof2) {
            $line = $$ibuf;
        }
    } elsif (! defined $irs) {
        if ($self->eof2) {
            $line = $$ibuf;
        }
    } elsif ($irs eq '') {
        # paragraph mode
        $$ibuf =~ s/^\n+//;
        $irs = "\n\n";
        $index = index($$ibuf, "\n\n");
    } else {
        # multi-character (or just \n)
        $index = index($$ibuf, $irs);
    }
    if (defined $index) {
        $line = $index > -1
            ? substr($$ibuf, 0, $index+length($irs))
            : ($self->eof2 ? $$ibuf : undef);
    }
    if ($debug) {
        no warnings;
        my $x = $$ibuf;
        substr($x, 0, length($line)) = '';
        $x =~ s/\n/\\n/g;
        my $y = $irs;
        $y =~ s/\n/\\n/g;
        print "looked for '$y', returning undef, keeping '$x'\n" unless defined $line;
        my $z = $line;
        $z =~ s/\n/\\n/g;
        print "looked for '$y', returning '$z', keeping '$x'\n" if defined $line;
    }
    return undef unless defined($line) && length($line);
    substr($$ibuf, 0, length($line)) = '';
    return $line;
}

# is the following a good idea?
#sub tell
#{
#   my ($self) = @_;
#   return ${*$self}{ie_fh}->tell() + length(${*$self}{ie_obuf});
#}

# from IO::Handle
sub getlines
{
    my $self = shift;
    return undef unless ${*$self}{ie_autoread};
    my $ibuf = \${*$self}{ie_ibuf};
    #my $ol = length($$ibuf);
    my $irs = exists ${*$self}{ie_irs} ? ${*$self}{ie_irs} : $/;
    my @lines;
    if ($debug) {
        my $x = $irs;
        $x =~ s/\n/\\n/g;
        my $fn = $self->fileno;
        print "getlines($fn, '$x')\n";
    }
    if ($irs =~ /^\d/ && int($irs)) {
        if ($irs > 0) {
            @lines = unpack("(a$irs)*", $$ibuf);
            $$ibuf = '';
            $$ibuf = pop(@lines)
                if length($lines[$#lines]) != $irs && ! $self->eof2;
        } else {
            return undef unless $self->eof2;
            @lines = $$ibuf;
            $$ibuf = '';
        }
    } elsif (! defined $irs) {
        return undef unless $self->eof2;
        @lines = $$ibuf;
        $$ibuf = '';
    } elsif ($irs eq '') {
        # paragraphish mode.
        $$ibuf =~ s/^\n+//;
        @lines = grep($_ ne '', split(/(.*?\n\n)\n*/s, $$ibuf));
        $$ibuf = '';
        $$ibuf = pop(@lines)
            if @lines && substr($lines[$#lines], -2) ne "\n\n" && ! $self->eof2;
        if ($debug) {
            my $x = join('|', @lines);
            $x =~ s/\n/\\n/g;
            my $y = $$ibuf;
            $y =~ s/\n/\\n/g;
            print "getlines returns '$x' but holds onto '$y'\n";
        }
    } else {
        # multicharacter
        $rxcache{$irs} = qr/(.*?\Q$irs\E)/s
            unless exists $rxcache{$irs};
        my $irsrx = $rxcache{$irs};
        @lines = grep($_ ne '', split(/$rxcache{$irs}/, $$ibuf));
        return undef
            unless @lines;
        $$ibuf = '';
        $$ibuf = pop(@lines)
            if substr($lines[$#lines], 0-length($irs)) ne $irs && ! $self->eof2;
    }
    return @lines;
}

# from IO::Handle
sub ungetc
{
    my ($self, $ord) = @_;
    my $ibuf = \${*$self}{ie_ibuf};
    substr($$ibuf, 0, 0) = chr($ord);
}

# from FileHandle::Unget & original
sub ungets
{
    my $self = shift;
    substr(${*$self}{ie_ibuf}, 0, 0)
        = join('', @_);
}

*xungetc = \&ungets;
*ungetline = \&ungets;

# from IO::Handle
sub getc
{
    my ($self) = @_;
    $self->getsome(1);
}

# from IO::Handle
sub print
{
    my ($self, @data) = @_;
    $! = ${*$self}{ie_writeclosed} && return undef
        if ${*$self}{ie_writeclosed};
    my $ol;
    my $rv;
    my $er;
    my $obuf = \${*$self}{ie_obuf};
    if ($ol = length($$obuf)) {
        $$obuf .= join('', @data);
        $rv = length($$obuf) - $ol;
    } else {
        my $fh = ${*$self}{ie_fh};
        my $data = join('', @data);
        $rv = CORE::syswrite($fh, $data);
        if (defined($rv) && $rv < length($data)) {
            $$obuf = substr($data, $rv, length($data)-$rv);
            $self->writeevents(1);
            $rv = 1;
        } elsif ((! defined $rv) && ($!{EAGAIN} || $!{EWOULDBLOCK})) {
            $$obuf = $data;
            $self->writeevents(1);
            $rv = 1;
        } else {
            $er = 0+$!;
        }
    }
    if (length($$obuf) > ${*$self}{ie_obufsize}) {
        $self->ie_invoke(0, 'ie_outputoverflow', 1, $obuf);
        ${*$self}{ie_overflowinvoked} = 1;
    } elsif (${*$self}{ie_overflowinvoked}) {
        $self->ie_invoke(0, 'ie_outputoverflow', 0, $obuf);
        ${*$self}{ie_overflowinvoked} = 0;
    }
    $! = $er;
    return $rv;
}

# from IO::Handle
sub eof
{
    my ($self) = @_;
    return 0 if length(${*$self}{ie_ibuf});
    return 1 if ${*$self}{ie_readclosed};
    return 0;
    # return ${*$self}{ie_fh}->eof;
}

# internal use only.
# just like eof, but we assume the input buffer is empty
sub eof2
{
    my ($self) = @_;
    if ($debug) {
        my $fn = $self->fileno;
        print "eof2($fn)...";
        print " readclosed" if ${*$self}{ie_readclosed};
        #print " EOF" if ${*$self}{ie_fh}->eof;
        my $x = 0;
        $x = 1 if ${*$self}{ie_readclosed};
        # $x = ${*$self}{ie_fh}->eof unless defined $x;
        print " =$x\n";
    }
    return 1 if ${*$self}{ie_readclosed};
    return 0;
    # return ${*$self}{ie_fh}->eof;
}

sub fileno
{
    my $self = shift;
    return undef unless $self && ref($self) && reftype($self) eq 'GLOB';
    return ${*$self}{ie_fileno}
        if defined ${*$self}{ie_fileno};
    return undef unless ${*$self}{ie_fh} && reftype(${*$self}{ie_fh}) eq 'GLOB';
    return ${*$self}{ie_fh}->fileno();
}

sub DESTROY
{
    my $self = shift;
    my $no = $self->fileno;
    $no = '?' unless defined $no;
    print "DESTROY $no...\n" if $debug;
    return undef unless $self && ref($self) && reftype($self) eq 'GLOB';
    ${*$self}{ie_event}->cancel
        if ${*$self}{ie_event};
}


sub TIEHANDLE
{
    my ($pkg, $self) = @_;
    return $self;
}

sub PRINTF
{
    my $self = shift;
    $self->print(sprintf(shift, @_));
}

sub READLINE
{
    my $self = shift;
    wantarray ? $self->getlines : $self->getline;  ## no critic (Community::Wantarray)
}

sub ie_desc
{
    my ($self, $new) = @_;
    my $r = ${*$self}{ie_desc} || "no description";
    ${*$self}{ie_desc} = $new if defined $new;
    return $r;
}

no warnings;

*PRINT = \&print;

*READ = \&sysread;

# from IO::Handle
*read = \&sysread;

*WRITE = \&syswrite;

*CLOSE = \&close;

*EOF = \&eof;

*TELL = \&tell;

*FILENO = \&fileno;

*SEEK = \&seek;

*BINMODE = \&binmode;

*OPEN = \&open;

*GETC = \&getc;

use warnings;

}{package IO::Event::Socket::INET;

# XXX version 1.26 required for IO::Socket::INET

use strict;
use warnings;
use List::SomeUtils qw(any);

use parent -norequire, 'IO::Event';

sub new
{
    my ($pkg, $first, $second, %sock) = @_;

    # emulate behavior in the IO::Socket::INET API
    if (! %sock && ! $second) {
        $sock{PeerAddr} = $first;
    } else {
        $sock{$first} = $second;
    }

    my $handler = $sock{Handler} || (caller)[0];
    delete $sock{Handler};

    my $timeout;
    if ($sock{Timeout}) {
        $timeout = $sock{Timeout};
        delete $sock{Timeout};
    }

    $sock{Blocking} = 0;

    my (%ds) = %sock;

    delete $sock{Description};

    require IO::Socket::INET;
    my $fh = IO::Socket::INET->new(%sock);
    return undef unless defined $fh;

    my $peer = any { /Peer/ } keys %sock;
    if ($peer) {
        $ds{LocalPort} = $fh->sockport
            unless defined $ds{LocalPort};
        $ds{LocalHost} = $fh->sockhost
            unless defined $ds{LocalHost};
    }

    my $desc = $ds{Description}
        || join(" ",
            map {
                defined $ds{$_}
                    ? "$_=$ds{$_}"
                    : $_
            } sort keys %ds);

    return undef unless $fh;
    my $self = $pkg->SUPER::new($fh, $handler, $desc);
    bless $self, $pkg;
    $self->listener(1)
        if $sock{Listen};
    $fh->blocking(0); # XXX may be redundant
    if ($peer) {
        if ($fh->connected()) {
            $self->ie_invoke(0, 'ie_connected');
        } else {
            ${*$self}{ie_connecting} = 1;
            $self->writeevents(1);
            ${*$self}{ie_connect_timeout} = $timeout + time
                if $timeout;
        }
    }
    ${*$self}{ie_socket_timeout} = $timeout
        if $timeout;

    return $self;
}

}{
package IO::Event::Socket::UNIX;

use strict;
use warnings;

use parent -norequire, 'IO::Event';

sub new
{
    my ($pkg, $a, $b, %sock) = @_;

    # emulate behavior in the IO::Socket::INET API
    if (! %sock && ! $b) {
        $sock{Peer} = $a;
    } else {
        $sock{$a} = $b;
    }

    my $handler = $sock{Handler} || (caller)[0];
    delete $sock{Handler};

    my $desc = $sock{Description}
        || join(" ", map { "$_=$sock{$_}" } sort keys %sock);
    delete $sock{Description};

    require IO::Socket::UNIX;
    my $fh = IO::Socket::UNIX->new(%sock);

    return undef unless $fh;
    my $self = $pkg->SUPER::new($fh, $handler, $desc);
    bless $self, $pkg;
    $self->listener(1)
        if $sock{Listen};
    $fh->blocking(0);
    if ($sock{Peer}) {
        if ($fh->connected()) {
            $self->ie_invoke(0, 'ie_connected');
        } else {
            ${*$self}{ie_connecting} = 1;
            $self->writeevents(1);
        }
    }

    return $self;
}

}#end package
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::Event - Tied Filehandles for Nonblocking IO with Object Callbacks

=head1 VERSION

version 0.814

=head1 SYNOPSIS

 use IO::Event;
 use IO::Event 'emulate_Event';
 use IO::Event 'AnyEvent';

 my $ioe = IO::Event->new($filehandle);

 my $ioe = IO::Event::Socket::INET->new( [ARGS] )

 my $ioe = IO::Event::Socket::UNIX->new( [ARGS] )

 my $timer = IO::Event->timer(
    [after => $seconds],
    interval => $seconds,
    cb => CODE);

 my $idler = IO::Event->idle(
    [min => $seconds],
    [max => $seconds],
    [reentrant => 0],
    cb => CODE);

 IO::Event::loop();

 IO::Event::unloop_all();

=head1 DESCRIPTION

IO::Event provides a object-based callback system for
handling nonblocking IO.  The design goal is to provide a
system that just does the right thing w/o the user needing
to think about it much.

All APIs are kept as simple as possible yet at the same time,
all functionality is accessible if needed.  Simple things are
easy.  Hard things are possible.

Most of the time file handling syntax will work fine:
C<< <$filehandle> >> and C<print $filehandle 'stuff'>.

IO::Event provides automatic buffering of output (with a
callback to throttle).  It provides automatic line-at-a-time
input.

After initial setup, call C<IO::Event::loop()>.

IO::Event was originally written to use L<Event>.  IO::Event still
defaults to using L<Event> but it can now use L<AnyEvent> or its
own event loop.

=head1 CHOOSING AN EVENT HANDLER

Until you create your first IO::Event object, you can choose
which underlying event handler to use.  The default is L<Event>.
To choose an event handler, use one of the following lines,
import C<no_emulate_Event>, C<emulate_Event>, or C<AnyEvent>.

 use IO::Event 'no_emulate_Event'
 use IO::Event 'emulate_Event'
 use IO::Event 'AnyEvent'

The C<no_emulate_Event> option means: use L<Event>.  The C<emulate_Event>
option means IO::Event should use its own event loop.

Why?

You should use L<AnyEvent> if you want to have compatibility with
other event loops.  You should use C<emulate_Event> if you don't
need compatibility with other event loops and you have missing-event
bugs when using L<Event>.  You should use L<Event> if it works for you.

The APIs are a bit different depending on which event loop you're using.

=head2 L<Event>

To use L<Event>'s event loop:

 use IO::Event 'no_emulate_Event';

or just:

 use IO::Event

IO::Event's definition for C<loop()>, C<timer()>, C<idle()> and
C<unloop_all()> all default to the L<Event> version unless
C<emulate_Event> or C<AnyEvent> have been imported.  This allows you to
easily switch back and forth between L<Event>'s API and
the others.

=head2 L<AnyEvent>

To use L<AnyEvent>'s select loop, import C<AnyEvent>.

 use IO::Event 'AnyEvent';

You can use L<AnyEvent>'s API directly or you can use IO::Event's
emulated APIs: C<IO::Event::loop()>, C<IO::Event::unloop()>, C<IO::Event::timer()>,
and C<IO::Event::idle()>.  These behave like L<Event>'s routines of the
same name but use L<AnyEvent> underneath.

During testing, using the pure-perl event loop of L<AnyEvent::Impl::Perl> from
L<AnyEvent> version 5.271, some read events were dropped.  To work around this, a synthetic
read-ready event is dispatched for all connected read filehandles every two
seconds.  Turn this off or adjust its frequency by changing
C<$IO::Event::AnyEvent::lost_event_hack>.  A numeric value is the time (in seconds)
between dispatching read events.  A false value turns off this performance-sapping hack.

L<AnyEvent> only provides basic support for idle() events: it promises to invoke
them "every now and then".

=head2 C<emulate_Event>

To use IO::Event's own select loop, import C<emulate_Event>.

 use IO::Event 'emulate_Event';

IO::Event does not provide a complete emulation of everything that
L<Event> does.  It provides the full timer API:

 my $timer = IO::Event::timer( [ARGS] )

instead of

 my $timer = Event::timer( [ARGS] )

However it does not provide timer events on filehandles, nor does
it provide events for signals, or variable accesses.

Use C<IO::Event::loop()> instead of C<Event::loop()>.   Use
C<IO::Event::unloop_all()> instead of C<Event::unloop_all()>.
Use C<IO::Event::idle()> instead of C<Event::idle()>.
It does not provide any other methods or functions from
L<Event>.   If you need them, please send a patch.

=head1 CONSTRUCTORS

=over 4

=item IO::Event->new($filehandle, [ $handler, [ $options ]])

The basic C<new> constructor takes a filehandle and returns
a pseudo-filehandle.  Treat the IO::Event object as
a filehandle.  Do not use the original filehandle without
good reason (let us know if you find a good reason so we
can fix the problem).

The handler is the class or object where you provide callback
functions to handle IO events.  It defaults to the package
of the calling context.

If present, C<$options> is a hash reference with the following
possible keys:

=over 13

=item description

A text description of this filehandle.  Used for debugging and
error messages.

=item read_only

Set to true if this is a read-only filehandle.  Do not accept output.

=item write_only

Set to true if this is a write-only filehandle.  Do not attempt to read.

=item autoread

Set to 0 if this should not be an auto-read filehandle.

=back

=item IO::Event::Socket::INET->new( [ARGS] )

This constructor uses IO::Socket::INET->new() to create a
socket using the ARGS provided.  It returns an
IO::Event object.

The handler defaults as above or can be set with an
additional pseudo-parameter for IO::Socket::UNIX->new():
C<Handler>.  A description for the socket can be provided
with an additional pseudo-parameter: C<Description>.

=item IO::Event::Socket::UNIX->new( [ARGS] )

This constructor uses IO::Socket::UNIX->new() to create a
socket using the ARGS provided.  It returns an
IO::Event object.

The handler defaults as above or can be set with an
additional pseudo-parameter for IO::Socket::UNIX->new():
C<Handler>.  A description for the socket can be provided
with an additional pseudo-parameter: C<Description>.

=back

=head1 MANDATORY HANDLERS

These handler methods must be available in the handler
object/class if the situation in which they would be
called arises.

=over 4

=item ie_input($handler, $ioe, $input_buffer_reference)

Invoked when there is fresh data in the input buffer.  The
input can be retrieved via directly reading it from
C<$$input_buffer_reference> or via C<read()> from the
$ioe filehandle, or by using a variety of standard
methods for getting data:

    <$ioe>          like IO::Handle
    $ioe->get()     like Data::LineBuffer
    $ioe->read()        like IO::Handle
    $ioe->sysread()     like IO::Handle
    $ioe->getline()     like IO::Handle
    $ioe->getlines()    like IO::Handle
    $ioe->getsome()     see below
    $ioe->ungets()      like FileHandle::Unget

At end-of-file, ie_input will only be invoked once.  There
may or may not be data in the input buffer.

=item ie_connection($handler, $ioe)

Invoked when a listen()ing socket is ready to accept().
It should call accept:

    sub ie_connection
    {
        my ($pkg, $ioe) = @_;
        my $newfh = $ioe->accept()
    }

=item ie_read_ready($handler, $ioe, $underlying_file_handle)

If autoreading is turned off then this will be invoked.

=item ie_werror($handler, $ioe, $output_buffer_reference)

A write error has occurred when trying to drain the write
buffer.  Provide an empty subroutine if you don't care.

=back

=head1 OPTIONAL HANDLERS

These handler methods will be called if they are defined
but it is not required that they be defined.

=over 4

=item ie_eof($handler, $ioe, $input_buffer_reference)

This is invoked when the read-side of the filehandle has
been closed by its source.

=item ie_output

This is invoked when data has just been written to the
underlying filehandle.

=item ie_outputdone

This is invoked when all pending data has just been written
to the underlying filehandle.

=item ie_connected

This is invoked when a C<connect()> completes.

=item ie_connect_failed($handler, $ioe, $error_code)

This is invoked when a C<connect()> fails.  For a timeout,
the error code will be C<ETIMEDOUT>.

=item ie_died($handler, $ioe, $method, $@)

If another handler calls C<die> then ie_died will be called
with the IO::Event object, the name of the method just
invoked, and the die string.  If no ie_died() callback exists
then execution will terminate.

=item ie_timer

This is invoked for timer events.

=item ie_exception

Invoked when an exceptional condition arises on the
underlying filehandle

=item ie_outputoverflow($handler, $ioe, $overflowing, $output_buffer_reference)

Invoked when there is too much output data and the output buffers
are overflowing.  You can take some action to generate less output.
This will be invoked exactly once (with $overflowing == 1) when
there is too much data in the buffer and then exactly once again
(with $overflowing == 0) when there is no longer too much data in the
buffer.

=back

=head1 METHODS

In addition to methods described in detail below, the following
methods behave like their C<IO> (mostly C<IO::Socket>) counterparts
(except for being mostly non-blocking...):

    connect
    listen
    open
    read
    sysread
    syswrite
    print
    eof
    shutdown

Through AUTOLOAD (see the SUBSTITUTED METHODS section) methods
are passed to underlying C<Event> objects:

    loop
    unloop
    and many more...

Through AUTOLOAD (see the SUBSTITUTED METHODS section) methods
are passed to underlying C<IO> objects:

    fileno
    stat
    truncate
    error
    opened
    untaint
    and many more...

IO::Event defines its own methods too:

=over 4

=item ->accept($handler, %options)

accept() is nearly identical to the normal IO::Socket::accept()
method except that instead of optionally passing a class
specifier for the new socket, you optionally pass a
handler object or class.   The returned filehandle is an
IO::Event object.

Supported options:

=over

=item description

Sets the description for the new socket

=item autoread

Set to 0 if you do not want auto-read

=back

=item ->can_read($amount)

Returns true if C<$amount> bytes worth of input is available for
reading.  Note: this does not return true at EOF so be careful not
to hang forever at EOF.

=item ->getsome($amount)

Returns C<$amount> bytes worth of input or undef if the request
can't be filled.  Returns what it can at EOF.

=item ->get()

get() is like getline() except that it pre-chomp()s the
results and assumes the input_record_separator is "\n".
This is like get() from L<Data::LineBuffer>.

=item ->unget()

Push chomp()ed lines back into the input buffer.
This is like unget() from L<Data::LineBuffer>.

=item ->ungetline(), ->xungetc(), ->ungets()

This is what ungetc() should be: it pushes a string back into
the input buffer.  This is unlike IO::Handle->ungetc which
takes an ordinal and pushes one character back into the
the input buffer.  This is like L<FileHandle::Unget>.

=item ->handler($new_handler)

Sets the handler object/class if $new_handler is provided.
Returns the old handler.

=item ->filehandle()

Returns the underlying C<IO::Handle>.

=item ->event()

Returns the underling C<Event>.

=item ->listener($listening)

Used to note that a filehandle is being used to listen
for connections (instead of receiving data).  A passed
parameter of 0 does the opposite.  Returns the old value.
This is mostly used internally in IO::Event.

=item ->input_record_separator($new_sep)

IO::Handle doesn't allow input_record_separator's on a per filehandle
basis.  IO::Event does.  If you don't ever set a filehandle's input
record separator, then it continuously defaults to the current value
of C<$/>.  If you set it, then it will use your value and never
look at C<$/> again.

=item ->readevents($readevents)

Get/set listening for read-ready events on the underlying
filehandle.  This could be used by ie_outputoverflow to
control input flows.

=item ->output_bufsize($output_bufsize)

Get/set the size of the output buffer.

=item ->autoread($autoread)

Get/set automatic reading if data when data can be read.
Without autoread turned on, the input buffer isn't filled
and none of the read methods will work.  The point of this
is for working with non-data filehandles.  This is an
experts-only method that kinda defeats the purpose of
this module.  This would be necessary using recv() to get
data.

=item ->drain()

Used to start looking for write-ready events on the underlying
filehandle.  In normal operation this is handled automatically.
Deprecated: use C<writeevents(1)> instead.

=item ->reentrant($reentrant)

Get/set reentrant callbacks.  By default, IO::Event avoids making
reentrant callbacks.  This is good because your code is less likely
to break.  This is bad because you won't learn about things right away.
For example, you will not learn the the output buffer is overflowing
during print().  You'll have to wait for the output buffer to begin
draining to find out.  This could be a problem.

=item ->close()

If there is output buffered, close will be delayed until the output
buffer drains.

=item ->forceclose

Close close immediately, even if there is output buffered.

=item ->ie_desc([new description])

Returns (and sets) the text description of the filehandle.  For debugging.

=back

=head1 EVENT LOOP FUNCTIONS

These dispatch to whichever event handler was chosen (see
L</CHOOSING AN EVENT HANDLER>).

=over 4

=item IO::Event::loop()

Run the event loop.

=item IO::Event::unloop()

Exit the current event loop.

=item IO::Event::unloop_all()

Exit all running event loops.

=item IO::Event->timer( [ARGS] )

Create a timer.  See L</TIMER API> for the arguments.

=item IO::Event->idle( [ARGS] )

Create an idle event.  See L</IDLE API> for the arguments.

=back

=head1 TIMER API

The following timer construction arguments are supported by IO::Event's
emulated event loop and IO::Event's API on top of L<AnyEvent>:

=over 4

=item cb

A callback to invoke when the timer goes off.  The callback can either be
a CODE reference or an array reference.  If it's an array reference, the
array should be a two element tuple: the first element is an object and the
second object is a method to invoke on the object.  The only argument to
the method call a reference to the timer object:

 my ($object, $method) = @{$timer->{cb}}
 $object->$method($timer)

=item at

A time at which to invoke the callback.

=item interval

An interval, in seconds between repeat invocations of the callback.

=item after

The interval until the first invocation of the callback.  After that,
invoke every I<interval>.

=back

The following methods (from L<Event>) are supported on timer objects:
start(), again(), now(), stop(), cancel(), is_cancelled(), is_running(),
is_suspended(), pending.

=head1 IDLE API

The following idle construction arguments are supported by IO::Event's
emulated event loop and IO::Event's API on top of L<AnyEvent>:

=over 4

=item cb

A callback to invoke when the event loop is idle.  The callback can either be
a CODE reference or an array reference.  If it's an array reference, the
array should be a two element tuple: the first element is an object and the
second object is a method to invoke on the object.

 my ($object, $method) = @{$timer->{cb}}
 $object->$method();

=item min

The minimum time between invocations of the callback.

=item max

The maximum time between invocations of the callback.

=back

The following methods (from L<Event>) are supported on idle objects:
start(), again(), now(), stop(), cancel(), is_cancelled(), is_running(),
is_suspended(), pending.

=head1 SUBSTITUTED METHODS

Any method invocations that fail because the method isn't defined
in IO::Event will by tried twice more: once using trying for a
method on the inner (hidden) filehandle and once more trying
for a method on the Event object that's used to create the select
loop for this module.

This dispatch is now deprecated with the choice of event handlers.

=head1 EXAMPLE SERVER

    # This is a tcp line echo server

    my $listener = IO::Event::Socket::INET->new(
        Listen => 10,
        Proto => 'tcp',
        LocalPort => 2821,
    );

    Event::loop();

    sub ie_connection
    {
        my ($pkg, $lstnr) = @_;
        my $client = $lstnr->accept();
        printf "accepted connection from %s:%s\n",
            $client->peerhost, $client->peerport;
    }

    sub ie_input
    {
        my ($pkg, $client, $ibufref) = @_;
        print $client <$client>;
    }

=head1 SYSREAD and EOF

sysread() is incompatible with eof() because eof() uses
getc().  Most of the time this isn't a problem.  In other words,
some of the time this is a problem: lines go missing.

For this reason, IO::Event never uses sysread().  In fact,
if you ask it to do a sysread() it does a read() for you instead.

On the other hand, at the current time no problems with syswrite
have come to light and IO::Event uses syswrite and never any other
form of write/print etc.

=head1 DESTRUCTION

IO::Event keeps copies of all of its registered filehandles.  If
you want to close a filehandle, you'll need to actually call close
on it.

=head1 DATA STRUCTURE

The filehandle object itself is a funny kind of hash reference.
If you want to use it to store your own data, you can.  Please
don't use hash keys that begin C<ie_> or C<io_> as those are the
prefixes used by C<IO::Event> and C<IO::Socket>.

The syntax is kinda funny:

    ${*$filehandle}{'your_hash_key'}

=head1 SEE ALSO

For a different API on top of IO::Event,
see L<IO::Event::Callback>.  It uses IO::Event but provides
a simpler and perhaps easier-to-use API.

The following perl modules do something that is kinda similar
to what is being done here:

L<AnyEvent::Handle>,
L<AnyEvent::AIO>,
L<IO::AIO>,
L<IO::Multiplex>,
L<IO::NonBlocking>,
L<IO::Select>
L<Event>,
L<POE>,
L<POE::Component::Server::TCP>,
L<Net::Socket::NonBlock>,
L<Net::Server::Multiplex>,
L<NetServer::Generic>

The API borrows most heavily from IO::Multiplex.  IO::Event
uses Event.pm and thus can be used in programs that are already
using Event or POE.

Since the original writing of IO::Event, L<AnyEvent> has been
released and now L<AnyEvent::AIO> and L<AnyEvent:Handle> should be
considered the only good alternatives to IO::Event.

For an example program using IO::Event, see L<IO::Event::rinetd>
which used to be included in this package.

=head1 BUGS

The test suite only covers 40% of the code.  The module is used
by its author and seems solid.

=head1 AUTHORS

=over 4

=item *

David Muir Sharnoff <cpan@dave.sharnoff.org>

=item *

Graham Ollis <plicease@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2002-2026 by David Muir Sharnoff <muir@idiom.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
