#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2007-2018 -- leonerd@leonerd.org.uk

package IO::Async::Resolver;

use strict;
use warnings;
use base qw( IO::Async::Function );

our $VERSION = '0.77';

# Socket 2.006 fails to getaddrinfo() AI_NUMERICHOST properly on MSWin32
use Socket 2.007 qw(
   AI_NUMERICHOST AI_PASSIVE
   NI_NUMERICHOST NI_NUMERICSERV NI_DGRAM
   EAI_NONAME
);

use IO::Async::Metrics '$METRICS';
use IO::Async::OS;

# Try to use HiRes alarm, but we don't strictly need it.
# MSWin32 doesn't implement it
BEGIN {
   require Time::HiRes;
   eval { Time::HiRes::alarm(0) } and Time::HiRes->import( qw( alarm ) );
}

use Carp;

my $started = 0;
my %METHODS;

=head1 NAME

C<IO::Async::Resolver> - performing name resolutions asynchronously

=head1 SYNOPSIS

This object is used indirectly via an L<IO::Async::Loop>:

 use IO::Async::Loop;
 my $loop = IO::Async::Loop->new;

 $loop->resolver->getaddrinfo(
    host    => "www.example.com",
    service => "http",
 )->on_done( sub {
    foreach my $addr ( @_ ) {
       printf "http://www.example.com can be reached at " .
          "socket(%d,%d,%d) + connect('%v02x')\n",
          @{$addr}{qw( family socktype protocol addr )};
    }
 });

 $loop->resolve( type => 'getpwuid', data => [ $< ] )
    ->on_done( sub {
    print "My passwd ent: " . join( "|", @_ ) . "\n";
 });

 $loop->run;

=head1 DESCRIPTION

This module extends an L<IO::Async::Loop> to use the system's name resolver
functions asynchronously. It provides a number of named resolvers, each one
providing an asynchronous wrapper around a single resolver function.

Because the system may not provide asynchronous versions of its resolver
functions, this class is implemented using a L<IO::Async::Function> object
that wraps the normal (blocking) functions. In this case, name resolutions
will be performed asynchronously from the rest of the program, but will likely
be done by a single background worker process, so will be processed in the
order they were requested; a single slow lookup will hold up the queue of
other requests behind it. To mitigate this, multiple worker processes can be
used; see the C<workers> argument to the constructor.

The C<idle_timeout> parameter for the underlying L<IO::Async::Function> object
is set to a default of 30 seconds, and C<min_workers> is set to 0. This
ensures that there are no spare processes sitting idle during the common case
of no outstanding requests.

=cut

sub _init
{
   my $self = shift;
   my ( $params ) = @_;
   $self->SUPER::_init( @_ );

   $params->{code} = sub {
      my ( $type, $timeout, @data ) = @_;

      if( my $code = $METHODS{$type} ) {
         local $SIG{ALRM} = sub { die "Timed out\n" };

         alarm( $timeout );
         my @ret = eval { $code->( @data ) };
         alarm( 0 );

         die $@ if $@;
         return @ret;
      }
      else {
         die "Unrecognised resolver request '$type'";
      }
   };

   $params->{idle_timeout} = 30;
   $params->{min_workers}  = 0;

   $started = 1;
}

sub debug_printf_call
{
   my $self = shift;
   my ( $type, undef, @data ) = @_;

   my $arg0;
   if( $type eq "getaddrinfo" ) {
      my %args = @data;
      $arg0 = sprintf "%s:%s", @args{qw( host service )};
   }
   elsif( $type eq "getnameinfo" ) {
      # cheat
      $arg0 = sprintf "%s:%s", ( Socket::getnameinfo( $data[0], NI_NUMERICHOST|NI_NUMERICSERV ) )[1,2];
   }
   else {
      $arg0 = $data[0];
   }

   $self->debug_printf( "CALL $type $arg0" );
}

sub debug_printf_result
{
   my $self = shift;
   my ( @result ) = @_;
   $self->debug_printf( "RESULT n=" . scalar @result );
}

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

=head2 resolve

   @result = $loop->resolve( %params )->get

Performs a single name resolution operation, as given by the keys in the hash.

The C<%params> hash keys the following keys:

=over 8

=item type => STRING

Name of the resolution operation to perform. See BUILT-IN RESOLVERS for the
list of available operations.

=item data => ARRAY

Arguments to pass to the resolver function. Exact meaning depends on the
specific function chosen by the C<type>; see BUILT-IN RESOLVERS.

=item timeout => NUMBER

Optional. Timeout in seconds, after which the resolver operation will abort
with a timeout exception. If not supplied, a default of 10 seconds will apply.

=back

On failure, the fail category name is C<resolve>; the details give the
individual resolver function name (e.g. C<getaddrinfo>), followed by other
error details specific to the resolver in question.

 ->fail( $message, resolve => $type => @details )

=head2 resolve (void)

   $resolver->resolve( %params )

When not returning a future, additional parameters can be given containing the
continuations to invoke on success or failure:

=over 8

=item on_resolved => CODE

A continuation that is invoked when the resolver function returns a successful
result. It will be passed the array returned by the resolver function.

 $on_resolved->( @result )

=item on_error => CODE

A continuation that is invoked when the resolver function fails. It will be
passed the exception thrown by the function.

=back

=cut

sub resolve
{
   my $self = shift;
   my %args = @_;

   my $type = $args{type};
   defined $type or croak "Expected 'type'";

   if( $type eq "getaddrinfo_hash" ) {
      $type = "getaddrinfo";
   }

   exists $METHODS{$type} or croak "Expected 'type' to be an existing resolver method, got '$type'";

   my $on_resolved;
   if( $on_resolved = $args{on_resolved} ) {
      ref $on_resolved or croak "Expected 'on_resolved' to be a reference";
   }
   elsif( !defined wantarray ) {
      croak "Expected 'on_resolved' or to return a Future";
   }

   my $on_error;
   if( $on_error = $args{on_error} ) {
      ref $on_error or croak "Expected 'on_error' to be a reference";
   }
   elsif( !defined wantarray ) {
      croak "Expected 'on_error' or to return a Future";
   }

   my $timeout = $args{timeout} || 10;

   $METRICS and $METRICS->inc_counter( resolver_lookups => [ type => $type ] );

   my $future = $self->call(
      args => [ $type, $timeout, @{$args{data}} ],
   )->else( sub {
      my ( $message, @detail ) = @_;
      $METRICS and $METRICS->inc_counter( resolver_failures => [ type => $type ] );
      Future->fail( $message, resolve => $type => @detail );
   });

   $future->on_done( $on_resolved ) if $on_resolved;
   $future->on_fail( $on_error    ) if $on_error;

   return $future if defined wantarray;

   # Caller is not going to keep hold of the Future, so we have to ensure it
   # stays alive somehow
   $self->adopt_future( $future->else( sub { Future->done } ) );
}

=head2 getaddrinfo

   @addrs = $resolver->getaddrinfo( %args )->get

A shortcut wrapper around the C<getaddrinfo> resolver, taking its arguments in
a more convenient form.

=over 8

=item host => STRING

=item service => STRING

The host and service names to look up. At least one must be provided.

=item family => INT or STRING

=item socktype => INT or STRING

=item protocol => INT

Hint values used to filter the results.

=item flags => INT

Flags to control the C<getaddrinfo(3)> function. See the C<AI_*> constants in
L<Socket>'s C<getaddrinfo> function for more detail.

=item passive => BOOL

If true, sets the C<AI_PASSIVE> flag. This is provided as a convenience to
avoid the caller from having to import the C<AI_PASSIVE> constant from
C<Socket>.

=item timeout => NUMBER

Time in seconds after which to abort the lookup with a C<Timed out> exception

=back

On success, the future will yield the result as a list of HASH references;
each containing one result. Each result will contain fields called C<family>,
C<socktype>, C<protocol> and C<addr>. If requested by C<AI_CANONNAME> then the
C<canonname> field will also be present.

On failure, the detail field will give the error number, which should match
one of the C<Socket::EAI_*> constants.

 ->fail( $message, resolve => getaddrinfo => $eai_errno )

As a specific optimisation, this method will try to perform a lookup of
numeric values synchronously, rather than asynchronously, if it looks likely
to succeed.

Specifically, if the service name is entirely numeric, and the hostname looks
like an IPv4 or IPv6 string, a synchronous lookup will first be performed
using the C<AI_NUMERICHOST> flag. If this gives an C<EAI_NONAME> error, then
the lookup is performed asynchronously instead.

=head2 getaddrinfo (void)

   $resolver->getaddrinfo( %args )

When not returning a future, additional parameters can be given containing the
continuations to invoke on success or failure:

=over 8

=item on_resolved => CODE

Callback which is invoked after a successful lookup.

 $on_resolved->( @addrs )

=item on_error => CODE

Callback which is invoked after a failed lookup, including for a timeout.

 $on_error->( $exception )

=back

=cut

sub getaddrinfo
{
   my $self = shift;
   my %args = @_;

   $args{on_resolved} or defined wantarray or
      croak "Expected 'on_resolved' or to return a Future";

   $args{on_error} or defined wantarray or
      croak "Expected 'on_error' or to return a Future";

   my $host    = $args{host}    || "";
   my $service = $args{service}; defined $service or $service = "";
   my $flags   = $args{flags}   || 0;

   $flags |= AI_PASSIVE if $args{passive};

   $args{family}   = IO::Async::OS->getfamilybyname( $args{family} )     if defined $args{family};
   $args{socktype} = IO::Async::OS->getsocktypebyname( $args{socktype} ) if defined $args{socktype};

   # Clear any other existing but undefined hints
   defined $args{$_} or delete $args{$_} for keys %args;

   # It's likely this will succeed with AI_NUMERICHOST if host contains only
   # [\d.] (IPv4) or [[:xdigit:]:] (IPv6)
   # Technically we should pass AI_NUMERICSERV but not all platforms support
   # it, but since we're checking service contains only \d we should be fine.

   # These address tests don't have to be perfect as if it fails we'll get
   # EAI_NONAME and just try it asynchronously anyway
   if( ( $host =~ m/^[\d.]+$/ or $host =~ m/^[[:xdigit:]:]$/ or $host eq "" ) and
       $service =~ m/^\d*$/ ) {

       my ( $err, @results ) = Socket::getaddrinfo( $host, $service,
          { %args, flags => $flags | AI_NUMERICHOST }
       );

       if( !$err ) {
          my $future = $self->loop->new_future->done( @results );
          $future->on_done( $args{on_resolved} ) if $args{on_resolved};
          return $future;
       }
       elsif( $err == EAI_NONAME ) {
          # fallthrough to async case
       }
       else {
          my $future = $self->loop->new_future->fail( $err, resolve => getaddrinfo => $err+0 );
          $future->on_fail( $args{on_error} ) if $args{on_error};
          return $future;
       }
   }

   my $future = $self->resolve(
      type    => "getaddrinfo",
      data    => [
         host    => $host,
         service => $service,
         flags   => $flags,
         map { exists $args{$_} ? ( $_ => $args{$_} ) : () } qw( family socktype protocol ),
      ],
      timeout => $args{timeout},
   );

   $future->on_done( $args{on_resolved} ) if $args{on_resolved};
   $future->on_fail( $args{on_error}    ) if $args{on_error};

   return $future if defined wantarray;

   # Caller is not going to keep hold of the Future, so we have to ensure it
   # stays alive somehow
   $self->adopt_future( $future->else( sub { Future->done } ) );
}

=head2 getnameinfo

   ( $host, $service ) = $resolver->getnameinfo( %args )->get

A shortcut wrapper around the C<getnameinfo> resolver, taking its arguments in
a more convenient form.

=over 8

=item addr => STRING

The packed socket address to look up.

=item flags => INT

Flags to control the C<getnameinfo(3)> function. See the C<NI_*> constants in
L<Socket>'s C<getnameinfo> for more detail.

=item numerichost => BOOL

=item numericserv => BOOL

=item dgram => BOOL

If true, set the C<NI_NUMERICHOST>, C<NI_NUMERICSERV> or C<NI_DGRAM> flags.

=item numeric => BOOL

If true, sets both C<NI_NUMERICHOST> and C<NI_NUMERICSERV> flags.

=item timeout => NUMBER

Time in seconds after which to abort the lookup with a C<Timed out> exception

=back

On failure, the detail field will give the error number, which should match
one of the C<Socket::EAI_*> constants.

 ->fail( $message, resolve => getnameinfo => $eai_errno )

As a specific optimisation, this method will try to perform a lookup of
numeric values synchronously, rather than asynchronously, if both the
C<NI_NUMERICHOST> and C<NI_NUMERICSERV> flags are given.

=head2 getnameinfo (void)

   $resolver->getnameinfo( %args )

When not returning a future, additional parameters can be given containing the
continuations to invoke on success or failure:

=over 8

=item on_resolved => CODE

Callback which is invoked after a successful lookup.

 $on_resolved->( $host, $service )

=item on_error => CODE

Callback which is invoked after a failed lookup, including for a timeout.

 $on_error->( $exception )

=back

=cut

sub getnameinfo
{
   my $self = shift;
   my %args = @_;

   $args{on_resolved} or defined wantarray or
      croak "Expected 'on_resolved' or to return a Future";

   $args{on_error} or defined wantarray or
      croak "Expected 'on_error' or to return a Future";

   my $flags = $args{flags} || 0;

   $flags |= NI_NUMERICHOST if $args{numerichost};
   $flags |= NI_NUMERICSERV if $args{numericserv};
   $flags |= NI_DGRAM       if $args{dgram};

   $flags |= NI_NUMERICHOST|NI_NUMERICSERV if $args{numeric};

   if( $flags & (NI_NUMERICHOST|NI_NUMERICSERV) ) {
      # This is a numeric-only lookup that can be done synchronously
      my ( $err, $host, $service ) = Socket::getnameinfo( $args{addr}, $flags );

      if( $err ) {
         my $future = $self->loop->new_future->fail( $err, resolve => getnameinfo => $err+0 );
         $future->on_fail( $args{on_error} ) if $args{on_error};
         return $future;
      }
      else {
         my $future = $self->loop->new_future->done( $host, $service );
         $future->on_done( $args{on_resolved} ) if $args{on_resolved};
         return $future;
      }
   }

   my $future = $self->resolve(
      type    => "getnameinfo",
      data    => [ $args{addr}, $flags ],
      timeout => $args{timeout},
   )->transform(
      done => sub { @{ $_[0] } }, # unpack the ARRAY ref
   );

   $future->on_done( $args{on_resolved} ) if $args{on_resolved};
   $future->on_fail( $args{on_error}    ) if $args{on_error};

   return $future if defined wantarray;

   # Caller is not going to keep hold of the Future, so we have to ensure it
   # stays alive somehow
   $self->adopt_future( $future->else( sub { Future->done } ) );
}

=head1 FUNCTIONS

=cut

=head2 register_resolver( $name, $code )

Registers a new named resolver function that can be called by the C<resolve>
method. All named resolvers must be registered before the object is
constructed.

=over 8

=item $name

The name of the resolver function; must be a plain string. This name will be
used by the C<type> argument to the C<resolve> method, to identify it.

=item $code

A CODE reference to the resolver function body. It will be called in list
context, being passed the list of arguments given in the C<data> argument to
the C<resolve> method. The returned list will be passed to the
C<on_resolved> callback. If the code throws an exception at call time, it will
be passed to the C<on_error> continuation. If it returns normally, the list of
values it returns will be passed to C<on_resolved>.

=back

=cut

# Plain function, not a method
sub register_resolver
{
   my ( $name, $code ) = @_;

   croak "Cannot register new resolver methods once the resolver has been started" if $started;

   croak "Already have a resolver method called '$name'" if exists $METHODS{$name};
   $METHODS{$name} = $code;
}

=head1 BUILT-IN RESOLVERS

The following resolver names are implemented by the same-named perl function,
taking and returning a list of values exactly as the perl function does:

 getpwnam getpwuid
 getgrnam getgrgid
 getservbyname getservbyport
 gethostbyname gethostbyaddr
 getnetbyname getnetbyaddr
 getprotobyname getprotobynumber

=cut

# Now register the inbuilt methods

register_resolver getpwnam => sub { my @r = getpwnam( $_[0] ) or die "$!\n"; @r };
register_resolver getpwuid => sub { my @r = getpwuid( $_[0] ) or die "$!\n"; @r };

register_resolver getgrnam => sub { my @r = getgrnam( $_[0] ) or die "$!\n"; @r };
register_resolver getgrgid => sub { my @r = getgrgid( $_[0] ) or die "$!\n"; @r };

register_resolver getservbyname => sub { my @r = getservbyname( $_[0], $_[1] ) or die "$!\n"; @r };
register_resolver getservbyport => sub { my @r = getservbyport( $_[0], $_[1] ) or die "$!\n"; @r };

register_resolver gethostbyname => sub { my @r = gethostbyname( $_[0] ) or die "$!\n"; @r };
register_resolver gethostbyaddr => sub { my @r = gethostbyaddr( $_[0], $_[1] ) or die "$!\n"; @r };

register_resolver getnetbyname => sub { my @r = getnetbyname( $_[0] ) or die "$!\n"; @r };
register_resolver getnetbyaddr => sub { my @r = getnetbyaddr( $_[0], $_[1] ) or die "$!\n"; @r };

register_resolver getprotobyname   => sub { my @r = getprotobyname( $_[0] ) or die "$!\n"; @r };
register_resolver getprotobynumber => sub { my @r = getprotobynumber( $_[0] ) or die "$!\n"; @r };

=pod

The following three resolver names are implemented using the L<Socket> module.

 getaddrinfo
 getaddrinfo_array
 getnameinfo

The C<getaddrinfo> resolver takes arguments in a hash of name/value pairs and
returns a list of hash structures, as the C<Socket::getaddrinfo> function
does. For neatness it takes all its arguments as named values; taking the host
and service names from arguments called C<host> and C<service> respectively;
all the remaining arguments are passed into the hints hash. This name is also
aliased as simply C<getaddrinfo>.

The C<getaddrinfo_array> resolver behaves more like the C<Socket6> version of
the function. It takes hints in a flat list, and mangles the result of the
function, so that the returned value is more useful to the caller. It splits
up the list of 5-tuples into a list of ARRAY refs, where each referenced array
contains one of the tuples of 5 values.

As an extra convenience to the caller, both resolvers will also accept plain
string names for the C<family> argument, converting C<inet> and possibly
C<inet6> into the appropriate C<AF_*> value, and for the C<socktype> argument,
converting C<stream>, C<dgram> or C<raw> into the appropriate C<SOCK_*> value.

The C<getnameinfo> resolver returns its result in the same form as C<Socket>.

Because this module simply uses the system's C<getaddrinfo> resolver, it will
be fully IPv6-aware if the underlying platform's resolver is. This allows
programs to be fully IPv6-capable.

=cut

register_resolver getaddrinfo => sub {
   my %args = @_;

   my $host    = delete $args{host};
   my $service = delete $args{service};

   $args{family}   = IO::Async::OS->getfamilybyname( $args{family} )     if defined $args{family};
   $args{socktype} = IO::Async::OS->getsocktypebyname( $args{socktype} ) if defined $args{socktype};

   # Clear any other existing but undefined hints
   defined $args{$_} or delete $args{$_} for keys %args;

   my ( $err, @addrs ) = Socket::getaddrinfo( $host, $service, \%args );

   die [ "$err", $err+0 ] if $err;

   return @addrs;
};

register_resolver getaddrinfo_array => sub {
   my ( $host, $service, $family, $socktype, $protocol, $flags ) = @_;

   $family   = IO::Async::OS->getfamilybyname( $family );
   $socktype = IO::Async::OS->getsocktypebyname( $socktype );

   my %hints;
   $hints{family}   = $family   if defined $family;
   $hints{socktype} = $socktype if defined $socktype;
   $hints{protocol} = $protocol if defined $protocol;
   $hints{flags}    = $flags    if defined $flags;

   my ( $err, @addrs ) = Socket::getaddrinfo( $host, $service, \%hints );

   die [ "$err", $err+0 ] if $err;

   # Convert the @addrs list into a list of ARRAY refs of 5 values each
   return map {
      [ $_->{family}, $_->{socktype}, $_->{protocol}, $_->{addr}, $_->{canonname} ]
   } @addrs;
};

register_resolver getnameinfo => sub {
   my ( $addr, $flags ) = @_;

   my ( $err, $host, $service ) = Socket::getnameinfo( $addr, $flags || 0 );

   die [ "$err", $err+0 ] if $err;

   return [ $host, $service ];
};

=head1 EXAMPLES

The following somewhat contrieved example shows how to implement a new
resolver function. This example just uses in-memory data, but a real function
would likely make calls to OS functions to provide an answer. In traditional
Unix style, a pair of functions are provided that each look up the entity by
either type of key, where both functions return the same type of list. This is
purely a convention, and is in no way required or enforced by the
L<IO::Async::Resolver> itself.

 @numbers = qw( zero  one   two   three four
                five  six   seven eight nine  );

 register_resolver getnumberbyindex => sub {
    my ( $index ) = @_;
    die "Bad index $index" unless $index >= 0 and $index < @numbers;
    return ( $index, $numbers[$index] );
 };

 register_resolver getnumberbyname => sub {
    my ( $name ) = @_;
    foreach my $index ( 0 .. $#numbers ) {
       return ( $index, $name ) if $numbers[$index] eq $name;
    }
    die "Bad name $name";
 };

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
