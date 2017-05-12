#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2008-2012 -- leonerd@leonerd.org.uk

package IPC::PerlSSH::Async;

use strict;
use warnings;
use base qw( IO::Async::Notifier IPC::PerlSSH::Base );
IPC::PerlSSH::Base->VERSION( '0.16' );

use IO::Async::Process 0.37;

our $VERSION = '0.07';

use Carp;

=head1 NAME

C<IPC::PerlSSH::Async> - Asynchronous wrapper around L<IPC::PerlSSH>

=head1 SYNOPSIS

I<Note:> the constructor has changed since version 0.03.

 use IO::Async::Loop;
 use IPC::PerlSSH::Async;

 my $loop = IO::Async::Loop->new();

 my $ips = IPC::PerlSSH::Async->new(
    on_exception => sub { die "Failed - $_[0]\n" },

    Host => "over.there",
 );

 $loop->add( $ips );

 $ips->eval(
    code => "use POSIX qw( uname ); uname()",
    on_result => sub { print "Remote uname is ".join( ",", @_ )."\n"; },
 );

 # We can pass arguments
 $ips->eval( 
    code => 'open FILE, ">", shift; print FILE shift; close FILE;',
    args => [ "foo.txt", "Hello, world!" ],
    on_result => sub { print "Wrote foo.txt\n" },
 );

 # We can load pre-defined libraries
 $ips->use_library(
    library => "FS",
    funcs   => [qw( unlink )],
    on_loaded => sub {
       $ips->call(
          name => "unlink",
          args => [ "foo.txt" ],
          on_result => sub { print "Removed foo.txt\n" },
       );
    },
 );

 $loop->loop_forever;

=head1 DESCRIPTION

This module provides an object class that implements the C<IPC::PerlSSH>
behaviour in an asynchronous way, suitable for use in an C<IO::Async>-based
program.

Briefly, C<IPC::PerlSSH> is a module that allows execution of perl code in a
remote perl instance, usually accessed via F<ssh>, with the notable
distinction that the module does not need to be present in the remote end, nor
does any special server need to be running, besides F<ssh> itself. For more
detail, see the L<IPC::PerlSSH> documentation.

=cut

=head1 INITIAL PARAMETERS

As well as the L</PARAMETERS> named below, the constructor will take any of
the constructor arguments named by L<IPC::PerlSSH>, to set up the connection.

=cut

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=over 8

=item on_exception => CODE

Optional. A default callback to use if a call to C<eval()>, C<store()> or
C<call()> does not provide one. If it is changed while a result it
outstanding, the handler that was in place at the time it was invoked will be
used in case of errors. Changes will only affect new C<eval()>, C<store()> or
C<call()> calls made after the change.

=item on_exit => CODE

Optional. A callback to invoke if the remote perl process exits. Will be
passed directly to the C<IO::Async::Process> C<on_finish> method.

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $loop = delete $args{loop};

   my $self = $class->SUPER::new( %args );

   if( $loop ) {
      warnings::warnif( deprecated => "'loop' constructor argument is deprecated" );
      $loop->add( $self );
   }

   return $self;
}

sub _init
{
   my $self = shift;
   my ( $params ) = @_;

   # This will delete keys
   $self->{IPC_PerlSSH_command} = [ $self->build_command_from( $params ) ];

   $self->{message_queue} = [];

   return $self->SUPER::_init( $params );
}

sub configure
{
   my $self = shift;
   my %params = @_;

   if( exists $params{on_exception} ) {
      my $on_exception = delete $params{on_exception};
      !$on_exception or ref $on_exception eq "CODE"
         or croak "Expected 'on_exception' to be a CODE reference";

      $self->{on_exception} =  $on_exception;
   }

   if( exists $params{on_exit} ) {
      my $on_exit = delete $params{on_exit};
      !$on_exit or ref $on_exit eq "CODE"
         or croak "Expected 'on_exit' to be a CODE reference";

      $self->{on_exit} =  $on_exit;
   }

   $self->SUPER::configure( %params );
}

sub _add_to_loop
{
   my $self = shift;
   $self->SUPER::_add_to_loop( @_ );

   my $on_exit = $self->{on_exit} || sub {
      print STDERR "Remote SSH died early";
   };

   if( my $command = delete $self->{IPC_PerlSSH_command} ) {
      # TODO: IO::Async ought to have nice ways to do this
      my $process = $self->{process} = IO::Async::Process->new(
         command => $command,
         stdio => { via => "pipe_rdwr" },
         on_finish => $on_exit,
      );

      $process->stdio->configure(
         on_read => $self->_replace_weakself( "on_read" ),
      );

      $self->add_child( $process );
   }

   $self->send_firmware;
}

sub on_read
{
   my $self = shift;
   my ( $buffref, $closed ) = @_;

   if( $closed ) {
      while( my $cb = shift @{ $self->{message_queue} } ) {
         $cb->( "CLOSED" );
      }
      return 0;
   }

   my ( $message, @args ) = $self->parse_message( $$buffref );
   return 0 unless defined $message;

   my $cb = shift @{ $self->{message_queue} };
   $cb->( $message, @args );

   return 1;
}

sub write
{
   my $self = shift;
   $self->{process}->stdio->write( @_ );
}

sub do_message
{
   my $self = shift;
   my %args = @_;

   my $message = $args{message};
   my $args    = $args{args};

   my $on_response = $args{on_response};
   ref $on_response eq "CODE" or croak "Expected 'on_response' as a CODE reference";

   $self->write_message( $message, @$args );

   push @{ $self->{message_queue} }, $on_response;
}

=head1 METHODS

=cut

=head2 $ips->eval( %args )

This method evaluates code in the remote host, passing arguments and returning
the result.

The C<%args> hash takes the following keys:

=over 8

=item code => STRING

The perl code to execute, in a string. (i.e. NOT a CODE reference).

=item args => ARRAY

Optional. An ARRAY reference containing arguments to pass to the code.

=item on_result => CODE

Continuation to invoke when the code returns a result.

=item on_exception => CODE

Optional. Continuation to invoke if the code throws an exception.

=back

The code should be passed in a string, and is evaluated using a string
C<eval> in the remote host, in list context. If this method is called in
scalar context, then only the first element of the returned list is returned.
Only string scalar values are supported in either the arguments or the return
values; no deeply-nested structures can be passed.

To pass or return a more complex structure, consider using a module such as
L<Storable>, which can serialise the structure into a plain string, to be
deserialised on the remote end.

If the remote code threw an exception, then this function propagates it as a
plain string. If the remote process exits before responding, this will be
propagated as an exception.

=cut

sub eval
{
   my $self = shift;
   my %args = @_;

   my $code = $args{code};
   my $args = $args{args};

   my $on_result = $args{on_result};
   ref $on_result eq "CODE" or croak "Expected 'on_result' as a CODE reference";

   my $on_exception = $args{on_exception} || $self->{on_exception};
   ref $on_exception eq "CODE" or croak "Expected 'on_exception' as a CODE reference";

   $self->do_message(
      message => "EVAL",
      args    => [ $code, $args ? @$args : () ],

      on_response => sub {
         my ( $ret, @args ) = @_;

         if( $ret eq "RETURNED" )  { $on_result->( @args ); }
         elsif( $ret eq "DIED" )   { $on_exception->( $args[0] ); }
         elsif( $ret eq "CLOSED" ) { $on_exception->( "Remote connection closed" ); }
         else                      { warn "Unknown return result $ret"; }
      },
   );
}

=head2 $ips->store( %args )

This method sends code to the remote host to store in a named procedure which
can be executed later.

The C<%args> hash takes the following keys:

=over 8

=item name => STRING

A name for the stored procedure.

=item code => STRING

The perl code to store, in a string. (i.e. NOT a CODE reference).

=item on_stored => CODE

Continuation to invoke when the code is successfully stored.

=item on_exception => CODE

Optional. Continuation to invoke if compiling the code throws an exception.

=back

The code should be passed in a string, along with a name which can later be
called by the C<call> method.

While the code is not executed, it will still be compiled into a CODE
reference in the remote host. Any compile errors that occur will still invoke
the C<on_exception> continuation. If the remote process exits before
responding, this will be propagated as an exception.

=cut

sub store
{
   my $self = shift;
   my %args = @_;

   my $name = $args{name};
   my $code = $args{code};

   my $on_stored = $args{on_stored};
   ref $on_stored eq "CODE" or croak "Expected 'on_stored' as a CODE reference";

   my $on_exception = $args{on_exception} || $self->{on_exception};
   ref $on_exception eq "CODE" or croak "Expected 'on_exception' as a CODE reference";

   $self->_has_stored_code( $name ) and return $on_exception->( "Already have a stored function called '$name'" );

   $self->do_message(
      message => "STORE",
      args    => [ $name, $code ],

      on_response => sub {
         my ( $ret, @args ) = @_;

         if( $ret eq "OK" ) {
            $self->{stored}{$name} = 1;
            $on_stored->();
         }
         elsif( $ret eq "DIED" )   { $on_exception->( $args[0] ); }
         elsif( $ret eq "CLOSED" ) { $on_exception->( "Remote connection closed" ); }
         else                      { warn "Unknown return result $ret"; }
      },
   );
}

sub _has_stored_code
{
   my $self = shift;
   my ( $name ) = @_;
   return exists $self->{stored}{$name};
}

=head2 $ips->call( %args )

This method invokes a stored procedure that has earlier been defined using the
C<store> method. The arguments are passed and the result is returned in the
same way as with the C<eval> method.

The C<%params> hash takes the following keys:

=over 8

=item name => STRING

The name of the stored procedure.

=item args => ARRAY

Optional. An ARRAY reference containing arguments to pass to the code.

=item on_result => CODE

Continuation to invoke when the code returns a result.

=item on_exception => CODE

Optional. Continuation to invoke if the code throws an exception or exits.

=back

=cut

sub call
{
   my $self = shift;
   my %args = @_;

   my $name = $args{name};
   my $args = $args{args};

   my $on_result = $args{on_result};
   ref $on_result eq "CODE" or croak "Expected 'on_result' as a CODE reference";

   my $on_exception = $args{on_exception} || $self->{on_exception};
   ref $on_exception eq "CODE" or croak "Expected 'on_exception' as a CODE reference";

   $self->_has_stored_code( $name ) or return $on_exception->( "Do not have a stored function called '$name'" );

   $self->do_message(
      message => "CALL",
      args    => [ $name, $args ? @$args : () ],

      on_response => sub {
         my ( $ret, @args ) = @_;

         if( $ret eq "RETURNED" )  { $on_result->( @args ); }
         elsif( $ret eq "DIED" )   { $on_exception->( $args[0] ); }
         elsif( $ret eq "CLOSED" ) { $on_exception->( "Remote connection closed" ); }
         else                      { warn "Unknown return result $ret"; }
      },
   );
}

=head2 $ips->use_library( %args )

This method loads a library of code from a module, and stores them to the
remote perl by calling C<store> on each one.

The C<%params> hash takes the following keys:

=over 8

=item library => STRING

Name of the library to load

=item funcs => ARRAY

Optional. Reference to an array containing names of functions to load.

=item on_loaded => CODE

Continuation to invoke when all the functions are stored.

=item on_exception => CODE

Optional. Continuation to invoke if storing a function throws an exception or
exits.

=back

The library name may be a full class name, or a name within the
C<IPC::PerlSSH::Library::> space.

If the funcs list is non-empty, then only those named functions are stored
(analogous to the C<use> perl statement). This may be useful in large
libraries that define many functions, only a few of which are actually used.

For more information, see L<IPC::PerlSSH::Library>.

=cut

sub use_library
{
   my $self = shift;
   my %args = @_;

   my $library = $args{library};
   my $funcs   = $args{funcs};

   my $on_loaded = $args{on_loaded};
   ref $on_loaded eq "CODE" or croak "Expected 'on_loaded' as a CODE reference";

   my $on_exception = $args{on_exception} || $self->{on_exception};
   ref $on_exception eq "CODE" or croak "Expected 'on_exception' as a CODE reference";

   my ( $package, $funcshash ) = eval { $self->load_library_pkg( $library, $funcs ? @$funcs : () ) };
   if( $@ ) {
      $on_exception->( $@ );
      return;
   }

   $self->{stored_pkg}{$package} and delete $funcshash->{_init};

   $self->do_message(
      message => "STOREPKG",
      args    => [ $package, %$funcshash ],

      on_response => sub {
         my ( $ret, @args ) = @_;

         if( $ret eq "OK" ) {
            $self->{stored_pkg}{$package} = 1;
            $self->{stored}{$_} = 1 for keys %$funcshash;
            $on_loaded->();
         }
         elsif( $ret eq "DIED" )   { $on_exception->( $args[0] ); }
         elsif( $ret eq "CLOSED" ) { $on_exception->( "Remote connection closed" ); }
         else                      { warn "Unknown return result $ret"; }
      },
   );
}

sub DESTROY
{
   my $self = shift;

   # Be safe at global destruction time
   $self->{stream}->close if defined $self->{stream};
}

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>
