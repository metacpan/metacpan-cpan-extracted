package IPC::Semaphore::SmokeSignals;
use strict;

use vars qw< $VERSION @EXPORT_OK >;
BEGIN {
    $VERSION = 0.001_002;
    @EXPORT_OK = qw< LightUp JoinUp MeetUp >;
    require IO::Handle;
    require Exporter;
    *import = \&Exporter::import;
    if(  eval { require bytes; 1 }  ) {
        bytes->import();
    }
}
use Time::HiRes qw< sleep >;
use Errno       qw< EAGAIN EWOULDBLOCK >;
use Fcntl       qw<
    O_WRONLY    O_RDONLY    O_NONBLOCK
    LOCK_EX     LOCK_NB     LOCK_UN
>;

sub _SMOKE { 0 }    # End to pull from.
sub _STOKE { 1 }    # The lit end.
sub _BYTES { 2 }    # Tokin' length.
sub _PUFFS { 3 }    # How many tokins; how many tokers at once (if I lit it).
sub _OWNER { 4 }    # PID of process that created this pipe.


sub LightUp {   # Set up a new pipe.
    return __PACKAGE__->Ignite( @_ );
}

sub JoinUp {    # Just use an existing pipe.
    return __PACKAGE__->JoinIn( @_ );
}

sub MeetUp {    # When you are not sure who should light the pipe.
    return __PACKAGE__->Meet( @_ );
}


sub _New {
    my( $class, $bytes, $path, $perm, $nowait ) = @_;

    my $smoke = IO::Handle->new();
    my $stoke = IO::Handle->new();
    if( ! $path ) {
        pipe( $smoke, $stoke )
            or  _croak( "Can't ignite pipe: $!\n" );
    } else {
        if( $perm && ! -e $path ) {
            warn "WARNING: Having to create FIFO: $path\n"
                if  $nowait;
            require POSIX;
            POSIX->import('mkfifo');    # In case import() says 'unsupported'.
            mkfifo( $path, $perm )
                or  _croak( "Can't create FIFO ($path): $!\n" );
        }
        my $extra = $perm || $nowait ? O_NONBLOCK() : 0;
        sysopen $smoke, $path, O_RDONLY()|$extra, $perm
            or  _croak( "Can't read pipe path ($path): $!\n" );
        _croak( "Path ($path) is not a FIFO (named pipe)\n" )
            if  ! -p $smoke;
        sysopen $stoke, $path, O_WRONLY()
            or  _croak( "Can't write pipe path ($path): $!\n" );
    }
    binmode $smoke;
    binmode $stoke;

    my $me = bless [], ref $class || $class;
    $me->[_SMOKE] = $smoke;
    $me->[_STOKE] = $stoke;
    $me->[_BYTES] = $bytes;

    return $me;
}


sub JoinIn {    # Use an already set-up pipe.
    my( $class, $bytes, $path ) = @_;
    my $me = $class->_New( $bytes, $path, 0 );
    return $me;
}


sub Ignite {    # Set up a new pipe.
    my( $class, $fuel, $path, $perm ) = @_;
    $perm ||= 0666
        if  $path;

    ( $fuel, my $bytes ) = $class->_PickTheMix( $fuel );

    my $me = $class->_New( $bytes, $path, $perm );

    $me->_Roll( $fuel );

    return $me;
}


sub _PickTheMix {
    my( $class, $fuel ) = @_;
    $fuel ||= 1;
    my $bytes;
    if( ref $fuel ) {
        _croak( "You brought nothing to smoke!\n" )
            if  ! @$fuel;
        $bytes = length $fuel->[0];
    } else {
        _croak( "Specify what to smoke or how much, not '$fuel'.\n" )
            if  $fuel !~ /^[1-9][0-9]*$/;
        $bytes = length $fuel;
    }
    return( $fuel, $bytes );
}


sub Meet {      # When you are not sure who should light the pipe.
    my( $class, $fuel, $path, $perm ) = @_;

    ( $fuel, my $bytes ) = $class->_PickTheMix( $fuel );

    my $me = $class->_New( $bytes, $path, $perm, 'nowait' );

    # See if somebody already lit the pipe:
    if( flock( $me->[_SMOKE], LOCK_EX() | LOCK_NB() ) ) {
        my $puff = $me->_Bogart('impatient');
        if( defined $puff ) {
            # Already lit, so return the magic smoke:
            $me->_Stoke( $puff );
        } else {
            # I got here first!  Light it up!
            $me->_Roll( $fuel );
        }
        flock( $me->[_SMOKE], LOCK_UN() );
    }

    return $me;
}


sub _Roll {     # Put the fuel in.
    my( $me, $fuel ) = @_;
    $me->[_OWNER] = $$;

    my $stoke = $me->[_STOKE];
    $stoke->blocking( 0 );
    if( ! ref $fuel ) {
        $me->[_PUFFS] = 0 + $fuel;
        my $start = '0' x length $fuel;
        $start =~ s/0$/1/;
        for my $puff (  "$start" .. "$fuel"  ) {
            $me->_Stoke( $puff );
        }
    } else {
        $me->[_PUFFS] = 0 + @$fuel;
        for my $puff (  @$fuel  ) {
            $me->_Stoke( $puff );
            _croak( "You can't use a string of null bytes as a tokin'" )
                if  $puff !~ /[^\0]/;
        }
    }
    $stoke->blocking( 1 );
}


sub _MagicDragon {  # Every magic dragon needs a good name.
    return __PACKAGE__ . '::Puff';
}


sub Puff {          # Get a magic dragon so you won't forget to share.
    my( $me, $impatient ) = @_;
    if( ref $me->[_PUFFS] ) {
        return
            if  wantarray;
        _croak( "The pipe is going out.\n" );
    }
    return $me->_MagicDragon()->_Inhale( $me, $impatient );
}


sub _Bogart {       # Take a drag (skipping proper protocol).
    my( $me, $impatient, $nil ) = @_;
    my( $smoke ) = $me->[_SMOKE];
    $smoke->blocking( 0 )
        if  $impatient;
    my $puff;
    my $got_none = ! sysread( $smoke, $puff, $me->[_BYTES] );
    my $excuse = $!;
    $smoke->blocking( 1 )
        if  $impatient;
    return undef
        if  $impatient
        &&  $got_none
        &&  (   EAGAIN() == $excuse
            ||  EWOULDBLOCK() == $excuse )
    ;
    _croak( "Can't toke pipe: $!\n" )
        if  $got_none;
    if( ! $nil && $puff !~ /[^\0]/ ) {  # Pipe is being smothered.
        $me->_Stoke( $puff );
        $me->_Snuff();                  # Stop us from using it.
        return
            if  wantarray;
        _croak( "The pipe is going out.\n" );
    }
    return $puff;
}


sub _Stoke {        # Return some magic smoke (skipping proper protocol).
    my( $me, $puff ) = @_;
    my $stoke = $me->[_STOKE];
    my $bytes = $me->[_BYTES];
    if(  $bytes != length $puff  ) {
        _croak( "Tokin' ($puff) is ", length($puff), " bytes, not $bytes!" );
    }
    syswrite( $stoke, $puff )
        or  die "Can't stoke pipe (with '$puff'): $!\n";
}


# Returns undef if we aren't allowed to extinguish it.
# Returns 0 if pipe is now completely extinguished.
# Otherwise, returns number of outstanding tokins remaining.

sub Extinguish {    # Last call!
    my( $me, $impatient ) = @_;
    my $puffs = $me->[_PUFFS];

    my $left = undef;           # Returned if we didn't start the fire.
    $left = 0                   # Returned when it is all the way out...
        if  defined $puffs      # ...since we did start the fire.
        &&  $$ == ( $me->[_OWNER] || 0 );

    return $left                # We already put out at least ours.
        if  ref $puffs && ! @$puffs;

    if( defined $left ) {       # We brought it up so we can take it down:
        $left = $me->_Smother( $impatient );
        return $left            # Not all the way out yet.
            if  $left;
    }
    # Either all the way out or just extinguishing our access to it:
    $me->_Snuff();
    return $left;
}


sub _Snuff {
    my( $me ) = @_;
    for my $puffs ( $me->[_PUFFS] ) {
        return
            if  ref $puffs && ! @$puffs;
        $puffs = [];
    }
    close $me->[_STOKE];
    close $me->[_SMOKE];
}


sub _Smother {
    my( $me, $impatient ) = @_;
    my $puffs = $me->[_PUFFS];
    my $eop = "\0" x $me->[_BYTES]; # The End-Of-Pipe tokin'.
    my $eops;                       # How many EOPs in pipe?
    my $room;                       # How much room in pipe for EOP tokins?
    if( ! ref $puffs ) {            # Our first try at shutting down:
        $room = $eops = 0;          # Nothing drained, no EOPs sent.
    } else {
        ( $puffs, $room, $eops ) = @$puffs;
    }

    my $left;
    my $loops = 0;
    while( 0 < ( $left = $puffs + $eops ) ) {
        my $puff = $me->_Bogart(
            $impatient || ! $eops,      # Don't wait before injecting EOP.
            'nil' );
        if( ! defined $puff ) {         # Pipe empty:
            if( ! $room && ! $eops ) {  # "No room" but pipe empty:
                $me->_Stoke( $eop ); ++$eops;   # Risk just 1 EOP.
            }
        } elsif( $puff =~ /[^\0]/ ) {   # We eliminated another non-EOP tokin':
            --$puffs;
            ++$room if $room < 2;
            $loops = 0;                 # Don't sleep while reaping tokins.
        } else {
            --$eops;                    # Got an EOP back.
        }
        last                            # All puffed out!
            if  ! $puffs && ! $eops;
        # Don't inject EOPs if would just cause $impatient to never return:
        if(     ! $impatient        # If patient, then we might loop w/ sleep.
            ||  ! defined $puff     # We are about to return, so inject.
            ||  $puff =~ /[^\0]/    # We got a non-EOP tokin' so add more EOP.
        ) {
            while( $puffs && $eops < $room ) {
                $me->_Stoke( $eop ); ++$eops;
            }
        }
        if( $impatient && ! defined $puff ) {   # We had emptied the pipe:
            $me->[_PUFFS] = [$puffs,$room,$eops];
            return $left;                       # Report: Others need time.
        }
        sleep( 0.1 )                            # Don't do a tight CPU loop.
            if  2 < ++$loops;
    }
    return 0;
}


sub _croak {
    require Carp;
    Carp::croak( @_ );
}


our @CARP_NOT;

package IPC::Semaphore::SmokeSignals::Puff;
push @CARP_NOT, __PACKAGE__;

sub _Inhale {
    my( $class, $pipe, $impatient ) = @_;
    my( $puff ) = $pipe->_Bogart($impatient)
        or  return;
    $puff   or  return undef;
    return bless [ $pipe, $puff ], $class;
}

sub Sniff {
    my( $me ) = @_;
    return $me->[1];
}

sub Exhale {
    my( $me ) = @_;
    return
        if  ! @$me;
    my( $pipe, $puff ) = splice @$me;
    $pipe->_Stoke( $puff );
}

sub DESTROY {
    my( $me ) = @_;
    $me->Exhale();
}


1;
__END__

=head1 NAME

IPC::Semaphore::SmokeSignals - A mutex and an LRU from crack pipe technology

=head1 SYNOPSIS

    use IPC::Semaphore::SmokeSignals qw< LightUp >;

    my $pipe = LightUp();

    sub threadSafe
    {
        my $puff = $pipe->Puff();
        # Only one thread will run this code at a time!
        ...
    }

=head1 DESCRIPTION

A friend couldn't get APR::ThreadMutex to work so I offered to roll my own
mutual exclusion code when, *bong*, I realized this would be trivial to do
with a simple pipe.

It is easiest to use as a very simple mutex (see Synopsis above).

You can also use this as a semaphore on a relatively small number of relatively
small tokins (each tokin' must be the same number of bytes and the total
number of bytes should be less than your pipe's capacity or else you're in
for a bad trip).

It also happens to give out tokins in LRU order (least recently used).

To use it as a semaphore / LRU:

    my $bong = LightUp( 12 );
    my @pool;

    sub sharesResource
    {
        my $dragon = $bong->Puff();
        # Only 12 threads at once can run this code!

        my $puff = $dragon->Sniff();
        # $puff is '01'..'12' and is unique among the threads here now

        Do_exclusive_stuff_with( $pool[$puff-1] );
        if(  ...  ) {
            $dragon->Exhale();  # Return our tokin' prematurely
            die ExpensivePostMortem();
        }
    }

    sub stowParaphernalia
    {
        # Calling all magic dragons; waiting for them to exhale:
        $bong->Extinguish();
        ...
    }

=head1 EXPORTS

There are 3 functions that you can request to be exported into your package.
They serve to prevent you from having to type the rather long module name
(IPC::Semaphore::SmokeSignals) more than once.

=head2 LightUp

C<LightUp()> activates a new pipe for coordinating that only $N things can
happen at once.

    use IPC::Semaphore::SmokeSignals 'LightUp';

    $pipe = LightUp( $fuel, $path, $perm );

To use an un-named pipe (such as if you are about to spawn some children):

    my $pipe = LightUp();
    # same as:
    my $pipe = LightUp(1);

    my $pipe = LightUp(50);
    # same as:
    my $pipe = LightUp(['01'..'50']);

This has the advantages of requiring no clean-up and having no chance of
colliding identifiers (unlike with SysV semaphores).

It is often better to use C<MeetUp()> if using a named pipe (FIFO), but it
is possible to use a named pipe via:

    my $pipe = LightUp( 8, "/var/run/my-app.pipe" );
    # same as:
    my $pipe = LightUp( 8, "/var/run/my-app.pipe", 0666 );
    # same as:
    my $pipe = LightUp( [1..8], "/var/run/my-app.pipe", 0666 );

C<LightUp(...)> is just short for:

    IPC::Semaphore::SmokeSignals->Ignite(...);

The first argument, C<$fuel>, if given, should be one of:

=over

=item A false value

This is the same as passing in a '1'.

=item An array reference

The array should contain 1 or more strings, all having the same length (in
bytes).

=item A positive integer

Passing in C<$N> gives you C<$N> tokins each of length C<length($N)>.  So
C<12> is the same as C<['01'..'12']>.

=back

The second argument, C<$path>, if given, should give the path to a FIFO (or
to where a FIFO should be created).  If C<$path> is not given or is a false
value, then Perl's C<pipe()> function is called to create a non-named pipe.

The third argument, C<$perm>, if given, overrides the default permissions
(0666) to use if a new FIFO is created.  Your umask will be applied (by the
OS) to get the permissions actually used.

Having a second process C<LightUp()> the same C<$path> after another process
has lit it up and while any process is still using it leads to problems.  The
module does not protect you from making that mistake.  This is why it is
usually better to use C<MeetUp()> when wanting to use a FIFO.

=head2 JoinUp

C<JoinUp()> connects to an existing named pipe (FIFO):

    use IPC::Semaphore::SmokeSignals 'JoinUp';

    $pipe = JoinUp( $bytes, $path );

C<JoinUp(...)> is just short for:

    IPC::Semaphore::SmokeSignals->JoinIn(...);

The C<$bytes> argument must be the number of bytes of each tokin' used when
the FIFO was created [by LightUp() or by MeetUp()].

The FIFO must already exist (at C<$path>).  The call to C<JoinUp()> can
block waiting for the creator to connect to the FIFO.

=head2 MeetUp

C<MeetUp()> coordinates several unrelated processes connecting to (and maybe
creating) a named pipe (FIFO), ensuring that only one of them initializes it.

    use IPC::Semaphore::SmokeSignals 'MeetUp';

    $pipe = MeetUp( $fuel, $path, $perm );

C<MeetUp(...)> is just short for:

    IPC::Semaphore::SmokeSignals->Meet(...);

The C<$fuel> and C<$path> arguments are identical to those same arguments for
C<LightUp()>.

It is often best to omit the C<$perm> argument (or pass in a false value),
which will cause C<MeetUp()> to fail if the FIFO, C<$path>, does not yet
exist.  This is because deleting the FIFO makes it possible for there to be
a race during initialization.

If you pass in a true value for C<$perm>, likely C<0666>, then the FIFO will
be created if needed (but this will also trigger a warning).

=head1 METHODS

=head2 Ignite

    my $pipe = IPC::Semaphore::SmokeSignals->Ignite( $fuel, $path, $perm );

See L<LightUp>.

=head2 JoinIn

    my $pipe = IPC::Semaphore::SmokeSignals->JoinIn( $bytes, $path );

See L<JoinUp>.

=head2 Meet

    my $pipe = IPC::Semaphore::SmokeSignals->Meet( $fuel, $path, $perm );

See L<MeetUp>.

=head2 Puff

    my $dragon = $pipe->Puff();

    my $dragon = $pipe->Puff('impatient');

C<Puff()> takes a drag on your pipe and stores the tokin' it gets in a magic
dragon that it gives to you.  Store the dragon in a lexical variable so that
when you leave the scope of that variable, the tokin' will automatically be
returned to the pipe (when the variable holding the dragon is destroyed),
making that tokin' available to some other pipe user.

The usual case is to use a semaphore to protect a block of code from being
run by too many processes (or threads) at the same time.

If you need to keep your tokin' reserved beyond any lexical scope containing
your call to C<Puff()>, then you can pass the dragon around, even making
copies of it.  When the last copy is destroyed, the tokin' will be returned.
Or you can release it early by calling C<Exhale()> on it.

If there are no available tokins, then the call to C<Puff()> will block,
waiting for a tokin' to become available.  Alternately, you can pass in a
true value as the only argument to C<Puff()> and this will cause C<Puff()>
to return immediately, either returning a magic dragon containing a tokin'
or just returning a false value.

For example:

    {
        my $dragon = $pipe->Puff('impatient');
        if( ! $dragon ) {
            warn "Can't do that right now.\n";
        } else {
            # This code must never run more than $N times at once:
            ...
        }
    }

If the initializer of the pipe has called C<Extinguish()> on the pipe, then
any calls to C<Puff()> (in any process) can die with the message:

    "The pipe is going out.\n"

Or, you can call C<Puff()> in a list context so that, instead of die()ing, it
will just return 0 items.  For example:

    {
        my( $dragon ) = $pipe->Puff('impatient')
            or  return 'done';
        if( ! $dragon ) {
            warn "Can't do that right now.\n";
        } else {
            # This code must never run more than $N times at once:
            ...
        }
    }

The C<or return> is only run if C<$pipe> has been C<Extinguish()>ed.  For
example, when C<Puff()> returns an C<undef>, the list assignment will return
the number of values assigned (1), which is a true value, preventing the
C<or return> from running.

Or you can just not worry about this by not calling C<Extinguish()>.

=head2 Sniff

    my $tokin = $dragon->Sniff();

Calling C<Sniff()> on a magic dragon returned from C<Puff()> will let you see
the value of the tokin' that you have reserved.

Calling C<Sniff()> on a magic dragon that has already had C<Exhale()> called
on it will return C<undef>.

=head2 Exhale

    $dragon->Exhale();

Calling C<Exhale()> on a magic dragon returned from C<Puff()> causes the
dragon to release the reserved tokin' immediately.

This can also be done by just overwriting the dragon, for example:

    $dragon = undef;

but only if C<$dragon> is the last/only existing copy of the dragon.

=head2 Extinguish

    $pipe->Extinguish();

    my $leftovers = $pipe->Extinguish( 'impatient' );

C<Extinguish()> marks the pipe as being shut down and starts pulling out and
discarding all of the tokins in it.  But it is a no-op (and returns C<undef>)
if the caller was not the process that lit the pipe.

If you pass it a true value, then it will still remove tokins from the pipe as
fast as possible, but it will not hang waiting for any outstanding tokin' to
be returned to the pipe.  In such a case, the number of outstanding tokins is
returned.

In all cases, 0 is returned if the call managed to completely shut down the
pipe (always the case if no true value was passed in).

=head1 NAMED PIPES

If you need a semaphore (or LRU) between unrelated processes or just
processes where it is inconvenient to create the SmokeSignals object in
their parent process, then you can use a named pipe (a FIFO):

    use IPC::Semaphore::SmokeSignals qw< MeetUp >;

    my $pipe = MeetUp( 12, "/var/run/mp-app" );

Please don't add code to delete the FIFO when you think you are done with it.
That can just lead to races in initialization.

Or, if you want to designate one process as being responsible for setting up
the paraphernalia:

    use IPC::Semaphore::SmokeSignals qw< LightUp JoinUp >;

    my $path = "/var/run/my-app.pipe";
    my $pipe =
        $is_owner
            ? LightUp( 12, $path, 0666 )
            : JoinUp( length('12'), $path );

In this case, calls to JoinUp() will block, waiting for the owner to at least
put the pipe in place (but not waiting until the pipe is fully lit).  Note
that this can thwart our checking to make sure that the total size of all of
the tokins does not exceed your pipe's capacity (which could later lead to
deadlock).

=head1 PLANS

A future version may allow for setting a maximum wait time.

=head1 CONTRIBUTORS

Author: Tye McQueen, http://perlmonks.org/?node=tye

=cut
