#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2007-2019 -- leonerd@leonerd.org.uk

package IO::Async::Internals::ChildManager;

use strict;
use warnings;

our $VERSION = '0.77';

# Not a notifier

use IO::Async::Stream;

use IO::Async::OS;

use Carp;
use Scalar::Util qw( weaken );

use POSIX qw( _exit dup dup2 nice );

use constant LENGTH_OF_I => length( pack( "I", 0 ) );

# Writing to variables of $> and $) have tricky ways to obtain error results
sub setuid
{
   my ( $uid ) = @_;

   $> = $uid; my $saved_errno = $!;
   $> == $uid and return 1;

   $! = $saved_errno;
   return undef;
}

sub setgid
{
   my ( $gid ) = @_;

   $) = $gid; my $saved_errno = $!;
   $) == $gid and return 1;

   $! = $saved_errno;
   return undef;
}

sub setgroups
{
   my @groups = @_;

   my $gid = $)+0;
   # Put the primary GID as the first group in the supplementary list, because
   # some operating systems ignore this position, expecting it to indeed be
   # the primary GID.
   # See
   #   https://rt.cpan.org/Ticket/Display.html?id=65127
   @groups = grep { $_ != $gid } @groups;

   $) = "$gid $gid " . join " ", @groups; my $saved_errno = $!;

   # No easy way to detect success or failure. Just check that we have all and
   # only the right groups
   my %gotgroups = map { $_ => 1 } split ' ', "$)";

   $! = $saved_errno;
   $gotgroups{$_}-- or return undef for @groups;
   keys %gotgroups or return undef;

   return 1;
}

# Internal constructor
sub new
{
   my $class = shift;
   my ( %params ) = @_;

   my $loop = delete $params{loop} or croak "Expected a 'loop'";

   my $self = bless {
      loop => $loop,
   }, $class;

   weaken( $self->{loop} );

   return $self;
}

sub spawn_child
{
   my $self = shift;
   my %params = @_;

   my $command = delete $params{command};
   my $code    = delete $params{code};
   my $setup   = delete $params{setup};
   my $on_exit = delete $params{on_exit};

   if( %params ) {
      croak "Unrecognised options to spawn: " . join( ",", keys %params );
   }

   defined $command and defined $code and 
      croak "Cannot pass both 'command' and 'code' to spawn";

   defined $command or defined $code or
      croak "Must pass one of 'command' or 'code' to spawn";

   my @setup = defined $setup ? $self->_check_setup_and_canonicise( $setup ) : ();

   my $loop = $self->{loop};

   my ( $readpipe, $writepipe );

   {
      # Ensure it's FD_CLOEXEC - this is a bit more portable than manually
      # fiddling with F_GETFL and F_SETFL (e.g. MSWin32)
      local $^F = -1;

      ( $readpipe, $writepipe ) = IO::Async::OS->pipepair or croak "Cannot pipe() - $!";
      $readpipe->blocking( 0 );
   }

   if( defined $command ) {
      my @command = ref( $command ) ? @$command : ( $command );

      $code = sub {
         no warnings;
         exec( @command );
         return;
      };
   }

   my $kid = $loop->fork( 
      code => sub {
         # Child
         close( $readpipe );
         $self->_spawn_in_child( $writepipe, $code, \@setup );
      },
   );

   # Parent
   close( $writepipe );
   return $self->_spawn_in_parent( $readpipe, $kid, $on_exit );
}

sub _check_setup_and_canonicise
{
   my $self = shift;
   my ( $setup ) = @_;

   ref $setup eq "ARRAY" or croak "'setup' must be an ARRAY reference";

   return () if !@$setup;

   my @setup;

   my $has_setgroups;

   foreach my $i ( 0 .. $#$setup / 2 ) {
      my ( $key, $value ) = @$setup[$i*2, $i*2 + 1];

      # Rewrite stdin/stdout/stderr
      $key eq "stdin"  and $key = "fd0";
      $key eq "stdout" and $key = "fd1";
      $key eq "stderr" and $key = "fd2";

      # Rewrite other filehandles
      ref $key and eval { $key->fileno; 1 } and $key = "fd" . $key->fileno;

      if( $key =~ m/^fd(\d+)$/ ) {
         my $fd = $1;
         my $ref = ref $value;

         if( !$ref ) {
            $value = [ $value ];
         }
         elsif( $ref eq "ARRAY" ) {
            # Already OK
         }
         elsif( $ref eq "GLOB" or eval { $value->isa( "IO::Handle" ) } ) {
            $value = [ 'dup', $value ];
         }
         else {
            croak "Unrecognised reference type '$ref' for file descriptor $fd";
         }

         my $operation = $value->[0];
         grep { $_ eq $operation } qw( open close dup keep ) or 
            croak "Unrecognised operation '$operation' for file descriptor $fd";
      }
      elsif( $key eq "env" ) {
         ref $value eq "HASH" or croak "Expected HASH reference for 'env' setup key";
      }
      elsif( $key eq "nice" ) {
         $value =~ m/^\d+$/ or croak "Expected integer for 'nice' setup key";
      }
      elsif( $key eq "chdir" ) {
         # This isn't a purely watertight test, but it does guard against
         # silly things like passing a reference - directories such as
         # ARRAY(0x12345) are unlikely to exist
         -d $value or croak "Working directory '$value' does not exist";
      }
      elsif( $key eq "setuid" ) {
         $value =~ m/^\d+$/ or croak "Expected integer for 'setuid' setup key";
      }
      elsif( $key eq "setgid" ) {
         $value =~ m/^\d+$/ or croak "Expected integer for 'setgid' setup key";
         $has_setgroups and carp "It is suggested to 'setgid' before 'setgroups'";
      }
      elsif( $key eq "setgroups" ) {
         ref $value eq "ARRAY" or croak "Expected ARRAY reference for 'setgroups' setup key";
         m/^\d+$/ or croak "Expected integer in 'setgroups' array" for @$value;
         $has_setgroups = 1;
      }
      else {
         croak "Unrecognised setup operation '$key'";
      }

      push @setup, $key => $value;
   }

   return @setup;
}

sub _spawn_in_parent
{
   my $self = shift;
   my ( $readpipe, $kid, $on_exit ) = @_;

   my $loop = $self->{loop};

   # We need to wait for both the errno pipe to close, and for waitpid
   # to give us an exit code. We'll form two closures over these two
   # variables so we can cope with those happening in either order

   my $dollarbang;
   my ( $dollarat, $length_dollarat );
   my $exitcode;
   my $pipeclosed = 0;

   $loop->add( IO::Async::Stream->new(
      notifier_name => "statuspipe,kid=$kid",

      read_handle => $readpipe,

      on_read => sub {
         my ( $self, $buffref, $eof ) = @_;

         if( !defined $dollarbang ) {
            if( length( $$buffref ) >= 2 * LENGTH_OF_I ) {
               ( $dollarbang, $length_dollarat ) = unpack( "II", $$buffref );
               substr( $$buffref, 0, 2 * LENGTH_OF_I, "" );
               return 1;
            }
         }
         elsif( !defined $dollarat ) {
            if( length( $$buffref ) >= $length_dollarat ) {
               $dollarat = substr( $$buffref, 0, $length_dollarat, "" );
               return 1;
            }
         }

         if( $eof ) {
            $dollarbang = 0  if !defined $dollarbang;
            if( !defined $length_dollarat ) {
               $length_dollarat = 0;
               $dollarat = "";
            }

            $pipeclosed = 1;

            if( defined $exitcode ) {
               local $! = $dollarbang;
               $on_exit->( $kid, $exitcode, $!, $dollarat );
            }
         }

         return 0;
      }
   ) );

   $loop->watch_process( $kid => sub { 
      ( my $kid, $exitcode ) = @_;

      if( $pipeclosed ) {
         local $! = $dollarbang;
         $on_exit->( $kid, $exitcode, $!, $dollarat );
      }
   } );

   return $kid;
}

sub _spawn_in_child
{
   my $self = shift;
   my ( $writepipe, $code, $setup ) = @_;

   my $exitvalue = eval {
      # Map of which handles will be in use by the end
      my %fd_in_use = ( 0 => 1, 1 => 1, 2 => 1 ); # Keep STDIN, STDOUT, STDERR

      # Count of how many times we'll need to use the current handles.
      my %fds_refcount = %fd_in_use;

      # To dup2() without clashes we might need to temporarily move some handles
      my %dup_from;

      my $max_fd = 0;
      my $writepipe_clashes = 0;

      if( @$setup ) {
         # The writepipe might be in the way of a setup filedescriptor. If it
         # is we'll have to dup2 it out of the way then close the original.
         foreach my $i ( 0 .. $#$setup/2 ) {
            my ( $key, $value ) = @$setup[$i*2, $i*2 + 1];
            $key =~ m/^fd(\d+)$/ or next;
            my $fd = $1;

            $max_fd = $fd if $fd > $max_fd;
            $writepipe_clashes = 1 if $fd == fileno $writepipe;

            my ( $operation, @params ) = @$value;

            $operation eq "close" and do {
               delete $fd_in_use{$fd};
               delete $fds_refcount{$fd};
            };

            $operation eq "dup" and do {
               $fd_in_use{$fd} = 1;

               my $fileno = fileno $params[0];
               # Keep a count of how many times it will be dup'ed from so we
               # can close it once we've finished
               $fds_refcount{$fileno}++;

               $dup_from{$fileno} = $fileno;
            };

            $operation eq "keep" and do {
               $fds_refcount{$fd} = 1;
            };
         }
      }

      foreach ( IO::Async::OS->potentially_open_fds ) {
         next if $fds_refcount{$_};
         next if $_ == fileno $writepipe;
         POSIX::close( $_ );
      }

      if( @$setup ) {
         if( $writepipe_clashes ) {
            $max_fd++;

            dup2( fileno $writepipe, $max_fd ) or die "Cannot dup2(writepipe to $max_fd) - $!\n";
            undef $writepipe;
            open( $writepipe, ">&=$max_fd" ) or die "Cannot fdopen($max_fd) as writepipe - $!\n";
         }

         foreach my $i ( 0 .. $#$setup/2 ) {
            my ( $key, $value ) = @$setup[$i*2, $i*2 + 1];

            if( $key =~ m/^fd(\d+)$/ ) {
               my $fd = $1;
               my( $operation, @params ) = @$value;

               $operation eq "dup"   and do {
                  my $from = fileno $params[0];

                  if( $from != $fd ) {
                     if( exists $dup_from{$fd} ) {
                        defined( $dup_from{$fd} = dup( $fd ) ) or die "Cannot dup($fd) - $!";
                     }

                     my $real_from = $dup_from{$from};

                     POSIX::close( $fd );
                     dup2( $real_from, $fd ) or die "Cannot dup2($real_from to $fd) - $!\n";
                  }

                  $fds_refcount{$from}--;
                  if( !$fds_refcount{$from} and !$fd_in_use{$from} ) {
                     POSIX::close( $from );
                     delete $dup_from{$from};
                  }
               };

               $operation eq "open"  and do {
                  my ( $mode, $filename ) = @params;
                  open( my $fh, $mode, $filename ) or die "Cannot open('$mode', '$filename') - $!\n";

                  my $from = fileno $fh;
                  dup2( $from, $fd ) or die "Cannot dup2($from to $fd) - $!\n";

                  close $fh;
               };
            }
            elsif( $key eq "env" ) {
               %ENV = %$value;
            }
            elsif( $key eq "nice" ) {
               nice( $value ) or die "Cannot nice($value) - $!";
            }
            elsif( $key eq "chdir" ) {
               chdir( $value ) or die "Cannot chdir('$value') - $!";
            }
            elsif( $key eq "setuid" ) {
               setuid( $value ) or die "Cannot setuid('$value') - $!";
            }
            elsif( $key eq "setgid" ) {
               setgid( $value ) or die "Cannot setgid('$value') - $!";
            }
            elsif( $key eq "setgroups" ) {
               setgroups( @$value ) or die "Cannot setgroups() - $!";
            }
         }
      }

      $code->();
   };

   my $writebuffer = "";
   $writebuffer .= pack( "I", $!+0 );
   $writebuffer .= pack( "I", length( $@ ) ) . $@;

   syswrite( $writepipe, $writebuffer );

   return $exitvalue;
}

0x55AA;
