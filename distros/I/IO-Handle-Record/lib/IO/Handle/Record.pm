package IO::Handle::Record;

use 5.008008;
use strict;
use warnings;
use Storable;
use Class::Member::GLOB qw/record_opts
			   read_buffer expected expect_fds received_fds
			   end_of_input _received_fds
			   write_buffer fds_to_send written/;
use Errno qw/EAGAIN EINTR/;
use Carp;
my $have_inet6;
BEGIN {
  eval {
    require Socket6;
    $have_inet6=1;
  };
};
use Socket;
require XSLoader;

our $VERSION = '0.15';
XSLoader::load('IO::Handle::Record', $VERSION);

use constant {
  HEADERLENGTH=>8,		# 2 unsigned long
};

# this is called from the XS stuff in recvmsg
sub open_fd {
  my ($fd, $flags)=@_;
  use Fcntl qw/O_APPEND O_RDONLY O_WRONLY O_RDWR O_ACCMODE/;
  use POSIX ();
  use IO::Handle ();

  if( ($flags & O_ACCMODE) == O_RDONLY ) {
    $flags='<';
  } elsif( ($flags & O_ACCMODE) == O_WRONLY ) {
    if( $flags & O_APPEND ) {
      $flags='>>';
    } else {
      $flags='>';
    }
  } elsif( ($flags & O_ACCMODE) == O_RDWR ) {
    if( $flags & O_APPEND ) {
      $flags='+>>';
    } else {
      $flags='+>';
    }
  } else {
    POSIX::close($fd);
    return undef;
  }

  my $obj=bless IO::Handle->new_from_fd($fd, $flags),
                IO::Handle::Record::typeof($fd);

  if( ref($obj)=~/Socket/ ) {
    ${*$obj}{io_socket_domain}=socket_family($fd);
    ${*$obj}{io_socket_type}=socket_type($fd);

    if($obj->sockdomain==AF_INET or
       ($have_inet6 and $obj->sockdomain==&Socket6::AF_INET6) ) {
      if($obj->socktype==SOCK_STREAM) {
	${*$obj}{io_socket_proto}=&Socket::IPPROTO_TCP;
      } elsif($obj->socktype==SOCK_DGRAM) {
	${*$obj}{io_socket_proto}=&Socket::IPPROTO_UDP;
      } elsif($obj->socktype==SOCK_RAW) {
	${*$obj}{io_socket_proto}=&Socket::IPPROTO_ICMP;
      }
    }
  }

  return $obj;
}

sub read_record {
  my $I=shift;

  my $reader=(issock($I)
	      ? sub { recvmsg( $_[0], $_[1], $_[2], (@_>3?$_[3]:0) ); }
	      : sub { sysread $_[0], $_[1], $_[2], (@_>3?$_[3]:()); });

  unless( defined $I->expected ) {
    undef $I->end_of_input;
    undef $I->received_fds if( $I->can('received_fds') );
    $I->read_buffer='' unless( defined $I->read_buffer );
    my $buflen=length($I->read_buffer);
    while( $buflen<HEADERLENGTH ) {
      my $len=$reader->( $I, $I->read_buffer, HEADERLENGTH-$buflen, $buflen );
      if( defined($len) && $len==0 ) { # EOF
	undef $I->read_buffer;
	$I->end_of_input=1;
	return;
      } elsif( !defined($len) && $!==EAGAIN ) {
	return;			# non blocking file handle
      } elsif( !defined($len) && $!==EINTR ) {
	next;			# interrupted
      } elsif( !$len ) {	# ERROR
	$len=length $I->read_buffer;
	undef $I->read_buffer;
	croak "IO::Handle::Record: sysread";
      }
      $buflen+=$len;
    }
    my $L=($I->record_opts && $I->record_opts->{local_encoding}) ? 'L' : 'N';
    if( $I->can('expect_fds') ) {
      ($I->expected, $I->expect_fds)=unpack $L.'2', $I->read_buffer;
    } else {
      ($I->expected)=unpack $L.'2', $I->read_buffer;
    }
    $I->read_buffer='';
  }

  my $wanted=$I->expected;
  my $buflen=length($I->read_buffer);
  while( $buflen<$wanted ) {
    my $len=$reader->( $I, $I->read_buffer, $wanted-$buflen, $buflen );

    if( defined $len and $len>0 ) {
      $buflen+=$len;
    } elsif( defined $len ) {	# EOF
      $len=length $I->read_buffer;
      undef $I->read_buffer;
      croak "IO::Handle::Record: premature end of file";
    } elsif( $!==EAGAIN ) {
      return;
    } elsif( $!==EINTR ) {
      next;
    } else {
      undef $I->read_buffer;
      croak "IO::Handle::Record: sysread";
    }
  }

  if( $I->can('expect_fds') and
      $I->expect_fds>0 and defined $I->_received_fds ) {
    $I->received_fds=[splice @{$I->_received_fds}, 0, $I->expect_fds];
  }
  my $rc=eval {
    local $Storable::Eval;
    $I->record_opts and $Storable::Eval=$I->record_opts->{receive_CODE};
    Storable::thaw( $I->read_buffer );
  };
  if( $@ ) {
    my $e=$@;
    $e=~s/ at .*//s;
    croak $e;
  }

  undef $I->expected;
  undef $I->read_buffer;

  return @{$rc};
}

sub write_record {
  my $I=shift;

  my $writer=(issock($I)
	      ? sub { sendmsg( $_[0], $_[1], $_[2], (@_>3?$_[3]:0) ); }
	      : sub { syswrite $_[0], $_[1], $_[2], (@_>3?$_[3]:()); });

  my $can_fds_to_send=$I->can('fds_to_send');
  if( @_ ) {
    croak "IO::Handle::Record: busy"
      if( defined $I->write_buffer );
    my $L=($I->record_opts && $I->record_opts->{local_encoding}) ? 'L' : 'N';
    my $msg=eval {
      local $Storable::Deparse;
      local $Storable::forgive_me;
      $I->record_opts and do {
	$Storable::forgive_me=$I->record_opts->{forgive_me};
	$Storable::Deparse=$I->record_opts->{send_CODE};
      };
      local $SIG{__WARN__}=sub {};
      $L eq 'L'
	? Storable::freeze \@_
	: Storable::nfreeze \@_;
    };
    if( $@ ) {
      my $e=$@;
      $e=~s/ at .*//s;
      croak $e;
    }

    if( $can_fds_to_send ) {
      $I->write_buffer=pack( $L.'2', length($msg),
			     (defined $I->fds_to_send
			      ? 0+@{$I->fds_to_send}
			      : 0) ).$msg;
    } else {
      $I->write_buffer=pack( $L.'2', length($msg), 0 ).$msg;
    }
    $I->written=0;
  }

  my $written;

  # if there are file descriptors to send send them first along with the length
  # header only. (work around a bug in the suse 11.1 kernel)
  if( $I->written==0 and
      $can_fds_to_send and
      defined $I->fds_to_send and
      @{$I->fds_to_send} ) {
    while(!defined ($written=$writer->($I, $I->write_buffer, HEADERLENGTH))) {
      if( $!==EINTR ) {
	next;
      } elsif( $!==EAGAIN ) {
	return;
      } else {
	croak "IO::Handle::Record: syswrite";
      }
    }
    $I->written+=$written;
  }

  while( $I->written<length($I->write_buffer) and
	 (defined ($written=$writer->($I, $I->write_buffer,
				      length($I->write_buffer)-$I->written,
				      $I->written)) or
	  $!==EINTR) ) {
    if( defined $written ) {
      $I->written+=$written;
    }
  }
  if( $I->written==length($I->write_buffer) ) {
    undef $I->write_buffer;
    undef $I->written;
    return 1;
  } elsif( $!==EAGAIN ) {
    return;
  } else {
    croak "IO::Handle::Record: syswrite";
  }
}

sub read_simple_record {
  my $I=shift;
  local $/;
  my $delim;
  if( $I->record_opts ) {
    $/=$I->record_opts->{record_delimiter} || "\n";
    $delim=$I->record_opts->{field_delimiter} || "\0";
  } else {
    $/="\n";
    $delim="\0";
  }

  my $r=<$I>;
  return unless( defined $r );	# EOF

  chomp $r;
  return split /\Q$delim\E/, $r;
}

sub write_simple_record {
  my $I=shift;
  my $rdelim;
  my $delim;
  if( $I->record_opts ) {
    $rdelim=$I->record_opts->{record_delimiter} || "\n";
    $delim=$I->record_opts->{field_delimiter} || "\0";
  } else {
    $rdelim="\n";
    $delim="\0";
  }

  print( $I join( $delim , @_ ), $rdelim );
  $I->flush;
}

*IO::Handle::write_record=\&write_record;
*IO::Handle::read_record=\&read_record;
*IO::Handle::end_of_input=\&end_of_input;
*IO::Handle::write_simple_record=\&write_simple_record;
*IO::Handle::read_simple_record=\&read_simple_record;
*IO::Handle::record_opts=\&record_opts;
*IO::Handle::expected=\&expected;
*IO::Socket::UNIX::expect_fds=\&expect_fds;
*IO::Handle::read_buffer=\&read_buffer;
*IO::Socket::UNIX::received_fds=\&received_fds;
*IO::Socket::UNIX::_received_fds=\&_received_fds;
*IO::Handle::written=\&written;
*IO::Handle::write_buffer=\&write_buffer;
*IO::Socket::UNIX::fds_to_send=\&fds_to_send;
*IO::Socket::UNIX::peercred=\&peercred;

1;
__END__

=head1 NAME

IO::Handle::Record - IO::Handle extension to pass perl data structures

=head1 SYNOPSIS

 use IO::Socket::UNIX;
 use IO::Handle::Record;

 ($p, $c)=IO::Socket::UNIX->socketpair( AF_UNIX,
                                        SOCK_STREAM,
                                        PF_UNSPEC );
 while( !defined( $pid=fork ) ) {sleep 1}

 if( $pid ) {
   close $c; undef $c;

   $p->fds_to_send=[\*STDIN, \*STDOUT];
   $p->record_opts={send_CODE=>1};
   $p->write_record( {a=>'b', c=>'d'},
                     sub { $_[0]+$_[1] },
                     [qw/this is a test/] );
 } else {
   close $p; undef $p;

   $c->record_opts={receive_CODE=>sub {eval $_[0]}};
   ($hashref, $coderef, $arrayref)=$c->read_record;
   readline $c->received_fds->[0];       # reads from the parent's STDIN
 }

=head1 DESCRIPTION

C<IO::Handle::Record> extends the C<IO::Handle> class.
Since many classes derive from C<IO::Handle> these extensions can be used
with C<IO::File>, C<IO::Socket>, C<IO::Pipe>, etc.

The methods provided read and write lists of perl data structures. They can
pass anything that can be serialized with C<Storable> even subroutines
between processes.

The following methods are added:

=over 4

=item B<$handle-E<gt>record_opts>

This lvalue method expects a hash reference with options as parameter.
The C<send_CODE> and C<receive_CODE> options correspond
to localized versions of C<$Storable::Deparse> and C<$Storable::Eval>
respectively. Using them Perl code can be passed over a connection.
See the L<Storable> manpage for further information.

Further, setting C<forgive_me> sets C<$Storable::forgive_me> before
C<freeze()>ing anything. That way GLOB values are stored as strings.

In a few cases IO::Handle::Record passes binary data over the connection.
Normally network byte order is used there. You can save a few CPU cycles
if you set the C<local_encoding> option to true. In this case the byte
order of the local machine is used.

Example:

 $handle->record_opts={send_CODE=>1, receive_CODE=>1, local_encoding=>1};

=item B<$handle-E<gt>fds_to_send=\@fds>

Called before C<write_record> sets a list of file handles that are passed
to the other end of a UNIX domain stream socket. The next C<write_record>
transfers them as open files. So the other process can read or write to
them.

=item B<@fds=@{$handle-E<gt>received_fds}>

This is the counterpart to C<fds_to_send>. After a successful C<read_record>
the receiving process can fetch the transferred handles from this list.
The handles are GLOBs blessed to one of:

=over 4

=item B<*> IO::File

=item B<*> IO::Dir

=item B<*> IO::Pipe

=item B<*> IO::Socket::UNIX

=item B<*> IO::Socket::INET

=item B<*> IO::Socket::INET6

=item B<*> IO::Handle

=back

according to their type. C<IO::Handle> is used as kind of catchall type.
Open devices are received as such. C<IO::Handle::Record> does not load
all of these modules. That's up to you.

=item B<$handle-E<gt>write_record(@data)>

writes a list of perl data structures.

C<write_record> returns 1 if the record has been transmitted. C<undef> is
returned if C<$handle> is non blocking and a EAGAIN condition is met. In
this case reinvoke the operation without parameters
(just C<$handle-E<gt>write_record>) when the handle becomes ready.
Otherwise it throws an exception C<IO::Handle::Record: syswrite error>.
Check C<$!> in this case.

EINTR is handled internally.

Example:

 $handle->write_record( [1,2],
                        sub {$_[0]+$_[1]},
                        { list=>[1,2,3],
                          hash=>{a=>'b'},
                          code=>sub {print "test\n";} } );

=item B<@data=$handle-E<gt>read_record>

reads one record of perl data structures.

On success it returns the record as list. An empty list is returned if
C<$handle> is in non blocking mode and not enough data has been read.
Check $!==EAGAIN to catch this condition. When the handle becomes ready
just repeat the operation to read the next data chunk. If a complete record
has arrived it is returned.

On EOF an empty list is returned. To distinguish this from the non blocking
empty list return check C<$handle-E<gt>end_of_input>.

EINTR is handled internally.

Example:

 ($array, $sub, $hash)=$handle->read_record;

=item B<$handle-E<gt>end_of_input>

When an end of file condition is read this is set to true.

=item B<($pid, $uid, $gid)=$handle-E<gt>peercred>

B<ONLY FOR UNIX DOMAIN SOCKETS ON LINUX>

Return the PID, eUID and eGID of the peer at the time of the connect.

=item B<$handle-E<gt>read_buffer>

=item B<$handle-E<gt>expected>

=item B<$handle-E<gt>expect_fds>

=item B<$handle-E<gt>_received_fds>

=item B<$handle-E<gt>write_buffer>

=item B<$handle-E<gt>written>

these methods are used internally to provide a read and write buffer for
non blocking operations.

=back

=head2 Exceptions

=over 4

=item * C<IO::Handle::Record: sysread>

thrown in C<read_record>. Check C<$!> for more information.

=item * C<IO::Handle::Record: premature end of file>

thrown in C<read_record> on end of file if according to the internal
protocol more input is expected.

=item * C<IO::Handle::Record: busy>

thrown in C<write_record> if a non-blocking write is not yet finished. There
may be only one write operation at a time. If that hits you organise a queue.

=item * C<IO::Handle::Record: syswrite>

thrown in C<write_record> on an error of the underlying transport method.
Check C<$!> for more information.

=item * Other exceptions

thrown in C<read_record> and C<write_record> if something cannot be encoded
or decoded by the C<Storable> module. If that hits you the C<Storable> module
at one side is probably too old.

=back

=head2 EXPORT

None.

=head1 Data Transfer Format

The Perl data is serialized using Storable::freeze or Storable::nfreeze.
Storable::freeze is used if the C<local_encoding> option is set,
Storable::nfreeze otherwise.

The length in bytes of this data chunk and the number of file handles
that are passed along with the data are then each C<pack()>ed as a 4 byte
binary value using the C<L> or C<N> template. C<L> is used of C<local_encoding>
is in effect.

If there are file descriptors to be passed they are sent by a separate
sendmsg call along with 2 length fields only.

Both fields is the prepended to the data chunk:

 +-----------------+------------------------+
 | data length (N) | number of file handles |
 | 4 bytes         | 4 bytes                |
 +-----------------+------------------------+
 |                                          |
 |                                          |
 |                                          |
 |                                          |
 |                   data                   |
 |                                          |
 |                 N bytes                  |
 |                                          |
 |                                          |
 |                                          |
 |                                          |
 |                                          |
 +------------------------------------------+

B<WARNING:> The transfer format has changed in version 0.07 (never made it
to CPAN) and again in version 0.08.

=head1 TODO

=over 4

=item B<*> compression

=item B<*> credential passing over UNIX domain sockets

=back

=head1 SEE ALSO

C<IO::Handle>

=head1 AUTHOR

Torsten Foertsch, E<lt>torsten.foertsch@gmx.net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2009 by Torsten Foertsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
