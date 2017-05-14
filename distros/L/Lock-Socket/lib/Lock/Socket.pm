package Lock::Socket::Mo;

#<<< Do not perltidy this
BEGIN {
# use Mo qw'builder default import is required';
#   The following line of code was produced from the previous line by
#   Mo::Inline version 0.39
no warnings;my$M=__PACKAGE__.'::';*{$M.Object::new}=sub{my$c=shift;my$s=bless{@_},$c;my%n=%{$c.::.':E'};map{$s->{$_}=$n{$_}->()if!exists$s->{$_}}keys%n;$s};*{$M.import}=sub{import warnings;$^H|=1538;my($P,%e,%o)=caller.'::';shift;eval"no Mo::$_",&{$M.$_.::e}($P,\%e,\%o,\@_)for@_;return if$e{M};%e=(extends,sub{eval"no $_[0]()";@{$P.ISA}=$_[0]},has,sub{my$n=shift;my$m=sub{$#_?$_[0]{$n}=$_[1]:$_[0]{$n}};@_=(default,@_)if!($#_%2);$m=$o{$_}->($m,$n,@_)for sort keys%o;*{$P.$n}=$m},%e,);*{$P.$_}=$e{$_}for keys%e;@{$P.ISA}=$M.Object};*{$M.'builder::e'}=sub{my($P,$e,$o)=@_;$o->{builder}=sub{my($m,$n,%a)=@_;my$b=$a{builder}or return$m;my$i=exists$a{lazy}?$a{lazy}:!${$P.':N'};$i or ${$P.':E'}{$n}=\&{$P.$b}and return$m;sub{$#_?$m->(@_):!exists$_[0]{$n}?$_[0]{$n}=$_[0]->$b:$m->(@_)}}};*{$M.'default::e'}=sub{my($P,$e,$o)=@_;$o->{default}=sub{my($m,$n,%a)=@_;exists$a{default}or return$m;my($d,$r)=$a{default};my$g='HASH'eq($r=ref$d)?sub{+{%$d}}:'ARRAY'eq$r?sub{[@$d]}:'CODE'eq$r?$d:sub{$d};my$i=exists$a{lazy}?$a{lazy}:!${$P.':N'};$i or ${$P.':E'}{$n}=$g and return$m;sub{$#_?$m->(@_):!exists$_[0]{$n}?$_[0]{$n}=$g->(@_):$m->(@_)}}};my$i=\&import;*{$M.import}=sub{(@_==2 and not$_[1])?pop@_:@_==1?push@_,grep!/import/,@f:();goto&$i};*{$M.'is::e'}=sub{my($P,$e,$o)=@_;$o->{is}=sub{my($m,$n,%a)=@_;$a{is}or return$m;sub{$#_&&$a{is}eq'ro'&&caller ne'Mo::coerce'?die$n.' is ro':$m->(@_)}}};*{$M.'required::e'}=sub{my($P,$e,$o)=@_;$o->{required}=sub{my($m,$n,%a)=@_;if($a{required}){my$C=*{$P."new"}{CODE}||*{$M.Object::new}{CODE};no warnings 'redefine';*{$P."new"}=sub{my$s=$C->(@_);my%a=@_[1..$#_];if(!exists$a{$n}){require Carp;Carp::croak($n." required")}$s}}$m}};@f=qw[builder default import is required];use strict;use warnings;
$INC{'Lock/Socket/Mo.pm'} = __FILE__;
}
1;
#>>>

package Lock::Socket::Error;
use Lock::Socket::Mo;
use overload '""' => sub { $_[0]->msg }, fallback => 1;

has msg => (
    is       => 'ro',
    required => 1,
);

1;

package Lock::Socket;
use strict;
use warnings;
use Carp ();
use Lock::Socket::Mo;
use Socket;

our @VERSION = '0.0.6';
our @CARP_NOT;

@Lock::Socket::Error::Bind::ISA   = ('Lock::Socket::Error');
@Lock::Socket::Error::Socket::ISA = ('Lock::Socket::Error');
@Lock::Socket::Error::Usage::ISA  = ('Lock::Socket::Error');
@Lock::Socket::Error::Import::ISA = ('Lock::Socket::Error');

### Function Interface ###

sub _uid_ip {
    return join( '.', 127, unpack( 'C2', pack( "n", $< ) ), 1 )
      unless $^O =~ m/bsd$/ or $^O eq 'darwin';
    return '127.0.0.1';
}

sub lock_socket {
    my $port = shift
      || __PACKAGE__->err( 'Usage', 'usage: lock_socket($PORT)' );
    my $addr = shift;

    my $sock = Lock::Socket->new(
        port => $port,
        defined $addr ? ( addr => $addr ) : (),
    );
    $sock->lock;
    return $sock;
}

sub lock_user_socket {
    my $port = shift
      || __PACKAGE__->err( 'Usage', 'usage: lock_user_socket($PORT)' );
    my $addr = shift;

    my $sock = Lock::Socket->new(
        port => $port + $<,
        addr => $addr || _uid_ip,
    );
    $sock->lock;
    return $sock;
}

sub try_lock_socket {
    $_[0] || __PACKAGE__->err( 'Usage', 'usage: try_lock_socket($PORT)' );
    return eval { lock_socket(@_) };
}

sub try_lock_user_socket {
    $_[0] || __PACKAGE__->err( 'Usage', 'usage: try_lock_user_socket($PORT)' );
    return eval { lock_user_socket(@_) };
}

sub import {
    my $class  = shift;
    my $caller = caller;
    no strict 'refs';

    foreach my $token (@_) {
        if ( $token eq 'lock_socket' ) {
            *{ $caller . '::lock_socket' } = \&lock_socket;
        }
        elsif ( $token eq 'try_lock_socket' ) {
            *{ $caller . '::try_lock_socket' } = \&try_lock_socket;
        }
        elsif ( $token eq 'lock_user_socket' ) {
            *{ $caller . '::lock_user_socket' } = \&lock_user_socket;
        }
        elsif ( $token eq 'try_lock_user_socket' ) {
            *{ $caller . '::try_lock_user_socket' } = \&try_lock_user_socket;
        }
        else {
            __PACKAGE__->err( 'Import',
                'not exported by Lock::Socket: ' . $token );
        }
    }
}

### Object Attributes ###

has port => (
    is       => 'ro',
    required => 1,
);

has addr => (
    is      => 'ro',
    default => '127.0.0.1',

);

has _inet_addr => (
    is      => 'ro',
    default => sub {
        my $self = shift;
        return inet_aton( $self->addr );
    },
);

has _fh => (
    is      => 'rw',
    lazy    => 0,
    builder => '_fh_builder',
);

sub _fh_builder {
    my $self = shift;
    socket( my $fh, PF_INET, SOCK_STREAM, getprotobyname('tcp') )
      || $self->err( 'Socket', "socket: $!" );
    return $fh;
}

sub fh {
    $_[0]->_fh;
}

has _is_locked => (
    is      => 'rw',
    lazy    => 0,
    default => sub { 0 },
);

sub is_locked {
    $_[0]->_is_locked;
}

### Object Methods ###

sub err {
    my $self  = shift;
    my $class = 'Lock::Socket::Error::' . $_[0];
    local @CARP_NOT = __PACKAGE__;
    die $class->new( msg => Carp::shortmess( $_[1] ) );
}

sub lock {
    my $self = shift;
    return 1 if $self->_is_locked;

    bind( $self->fh, pack_sockaddr_in( $self->port, $self->_inet_addr ) )
      || $self->err( 'Bind',
        sprintf( 'bind: %s (%s:%d)', $!, $self->addr, $self->port ) );

    $self->_is_locked(1);
}

sub try_lock {
    my $self = shift;
    return eval { $self->lock } || 0;
}

sub unlock {
    my $self = shift;
    return 1 unless $self->_is_locked;

    close( $self->_fh );
    $self->_fh( $self->_fh_builder );
    $self->_is_locked(0);

    return 1;
}

1;

__END__
=head1 NAME

Lock::Socket - application lock/mutex module based on sockets

=head1 VERSION

0.0.6 (2014-09-15)

=head1 SYNOPSIS

    ### Function API ###
    use Lock::Socket qw/lock_socket try_lock_socket/;

    # Raises exception if cannot lock
    my $lock = lock_socket(5197);

    # Or just return undef
    my $lock2 = try_lock_socket(5197)
      or die "handle your own error";

    ### Object API ###
    use Lock::Socket;

    # Create a socket
    my $sock = Lock::Socket->new( port => 5197 );

    # Lock or raise an exception
    $sock->lock;

    # Can check its status in case you forgot
    my $status = $sock->is_locked;    # 1 (or 0)
    my $addr   = $sock->addr;
    my $port   = $sock->port;

    # Re-locking changes nothing
    $sock->lock;

    # New lock on same port fails
    my $sock2 = Lock::Socket->new( port => 5197 );
    eval { $sock2->lock };            # exception

    # But trying to get a lock is ok
    my $status      = $sock2->try_lock;     # 0
    my $same_status = $sock2->is_locked;    # 0

    # If you need the underlying filehandle
    my $fh = $sock->fh;

    # You can manually unlock
    $sock->unlock;

    # ... or unlocking is automatic on scope exit
    undef $sock;

=head1 DESCRIPTION

B<Lock::Socket> provides cooperative inter-process locking for
applications that need to ensure that only one process is running at a
time.  This module works by binding an INET socket to a port on a
loopback address which the operating system conveniently restricts to a
single process.

Should you use B<Lock::Socket> instead of a file-based module? Perhaps.
Here are some statements that I believe to be true that work in its
favour:

=over

=item * B<Lock::Socket> guarantees (through the operating system) that
no two applications will hold the same lock: there is no race
condition.

=item * B<Lock::Socket> is guaranteed (again through the operating
system) to clean up neatly when your process exits, so there are no
stale locks to deal with.

=item * B<Lock::Socket> relies on functionality that is well supported
by anything that Perl runs on: no issues with flock(2) support on Win32
for example.

=back

The following statements I also believe to be true that work against
the module:

=over

=item * There is a slight chance that some unrelated process can grab
the lock that you need by accident, as the available lock namespace is
system-wide (we can't use user directories).

=item * B<Lock::Socket> has no ability to identify which process is
holding a lock.

=item * B<Lock::Socket> cannot be used for locking access to files on
NFS shares, only local resources.

=back

I'll leave it up to you and your particular situation to know if this
is the right module for you.

=head2 Function Interface

=over

=item lock_socket($PORT, [$ADDR]) -> Lock::Socket

Attempts to lock $PORT (on 127.0.0.1 by default) and returns a
B<Lock::Socket> object. Raises an exception if the lock cannot be
taken.

=item try_lock_socket($PORT, [$ADDR]) -> Lock::Socket | undef

Same as C<lock_socket()> but returns undef on failure.

=item lock_user_socket($PORT, [$ADDR]) -> Lock::Socket

Similarly to C<lock_socket()> this function attempts to take a lock and
returns a B<Lock::Socket> object or raises an exception if the lock
cannot be taken. The difference here is that this function attempts to
take a lock that is per-user, instead of system wide.

=over

=item * The actual lock port is calculated as $PORT + $UID.

=item * The loopback $ADDR by default is calculated as follows:

    Octet   Value
    ------  ------------------------------
    1       127
    2       First byte of user ID
    3       Second byte of user ID
    4       1

=back

Unfortunately on BSD systems the loopback interface appears to be
configured with a /32 netmask so there the above calculation is I<not>
performed and the address defaults to 127.0.0.1.

=item try_lock_user_socket($PORT, [$ADDR]) -> Lock::Socket | undef

Same as C<lock_user_socket()> but returns undef on failure.

=back

=head2 Object Interface

Objects are instantiated manually as follows.

    my $sock = Lock::Socket->new(
        port => $PORT, # required
        addr => $ADDR, # defaults to 127.0.0.1
    );

As soon as the B<Lock::Socket> object goes out of scope (or rather the
underlying filehandle object) the port is closed and the lock can be
obtained by someone else.

=head2 Holding a lock over 'exec'

If you want to keep holding onto a lock socket after a call to C<exec>
(perhaps after forking) you should read about the C<$^F> variable in
L<perlvar>, as you have to set it B<before> creating a lock socket to
ensure the socket will not be closed on exec.

=head2 Example application

See the F<example/solo> file in the distribution for a B<Lock::Socket>
demonstration which provides a command-line lock:

    usage: solo PORT COMMAND...

    # terminal 1
    $ example/solo 1414 sleep 10  # Have lock on 127.3.232.1:1414

    # terminal 2
    $ example/solo 1414 sleep 10  # bind error

=head1 CAVEATS

Most operating systems implement the L<Ephemeral
Port|http://en.wikipedia.org/wiki/Ephemeral_port> concept.  If you
select a port from that range it could be possible that some unrelated
process uses, if temporarily, the port that your application defines
for locking.

Unfortunately the ephemeral port range varies from system to system.
Based on the wikipedia page mentioned above, chances are good that a
port between 5001 and 32767 will work, particularly if your system
loopback device is configured with a /8 netmask (i.e. supports the
127.X.Y.1 scheme). To be sure you should investigate the platorms your
application runs on, and possibly choose an appropriate value at
runtime.

=head1 SEE ALSO

There are many other locking modules available on CPAN, most of them
relying on some type of file lock.

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>. This module was inspired by the
L<solo.pl|https://github.com/andres-erbsen/solo> script by Andres
Erbsen.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

