package IPC::Fork::Simple;

=head1 NAME

IPC::Fork::Simple - Simplified interprocess communication for forking
processes.

=head1 SYNOPSIS

 use IPC::Fork::Simple;

 my $ipc = IPC::Fork::Simple->new();
 my $pid = fork();
 if ( $pid ) {
     $ipc->spawn_data_handler();
     # Do important stuff here.
     # ...
     # 
     waitpid( $pid, 0 );
     $ipc->collect_data_from_handler();
     warn "Child sent: " . ${$ipc->from_child( $pid, 'test' )};
 } else {
     $ipc->init_child();
     $ipc->to_master( 'test', 'a' x 300 ) || die $!;
 }

=head1 DESCRIPTION

IPC::Fork::Simple is a module designed to simplify interprocess communication
used between a parent and its child forks. This version of the module only
supports one-way communication, from the child to the parent.

=head1 THEORY OF OPERATION

The basic idea behind this module is to one or more forks to return data to
their parent easily. This module divides a forking program into "master",
"child", and "other" forks. The master fork creates the first
IPC::Fork::Simple module and then calls fork() any number of times. Any
children created by the master will then call L<init_child> to specify
their participation in the system. Child forks that do not call L<init_child>,
prior forks that may have created the master, or other unrealted processes
in the same process group, will be considered other forks and will not have
a role in the system.

When a child is ready to send data to the master, it must assign that data
a name by which it will be retrieved later by the master. When the master
is ready to collect the data from a child, it will request that data by name
and CID. Data passed from the child to the master will be automatically
serialized/unserialized by L<Storable>, so almost any data type can be
transmitted, of up to 4 gigabytes in size.

Once a fork calls L<init_child>, the master will then be able to track the
child fork, returning any data that is sent, and returning whether or not
the child has closed its connection with he master.

=head1 USAGE

There are three methods of use for IPC::Fork::Simple, each relating to the 
actions taken by the master while the children are running.

=head2 Blocking Wait

A single call to L<process_child_data> with the appropriate BLOCK flag will
cause L<process_child_data> to block until a child has disconnected. By
calling L<process_child_data> once for each child, all data from all
children can be collected easily. Using this method makes it hard for the
master process to do anything other than spawn and monitor children.

=head2 Polling

A call to L<process_child_data> with a false parameter will cause
L<process_child_data> to only process pending data. If placed inside of a
loop, the master process can still gather data while it performs other work.
To determine when the children have ended the master can poll
L<finished_children> for the number and CIDs of children who have disconnected.
This method will allow the master to perform other tasks while the children
are running, but it will have to make periodic callbacks to
L<process_child_data>.

=head2 Data Handler

Calling L<spawn_data_handler> will cause the master to fork, and create a
process which will automatially listen for and gather data from any children
spawned by the master, either before or after the call to L<spawn_data_handler>.
When the master is ready to collect the data from the children, the data handler
will copy all data to the master and exit. To determine when a child has exited
L<finished_children> can be polled or the appropriate BLOCK flag can be passed
to L<collect_data_from_handler>. This method completely frees up the master to
perform other tasks. This method uses less memory and performs faster than the
others for large numbers of forks or for master processes that consume large
amounts of memory.

=head2 Notes

It was previously documented that calling wait(2) (or a similar function) to
determine if a child had ended was valid. This will correctly detect when a
child has exited, but an immediate call to one of the data or finished
child retrieval functions may not return that child's data. The only way
to be sure a child's data has been received is to check L<finished_children>
or attempt to fetch the data.

=head1 CHILD IDENTIFICATION

Internally, children are identified by a child id number, or CID. This
number is guaranteed to be unique for each child (and is currently
implemented as an integer starting with 0).

Child processes also have a symbolic name used to identify themselves. This
name defaults to the child's PID, but can be changed. Symbolic names can be
re-used, and attempting to access data by symbolic name after a symbolic name
has been re-used will return the data from one of the children at random. It
is recommended that the symbolic name be unique, but it is not required. PIDs
are not guaranteed to be unique. See L<from_cid> and L<NOTES> for details.

L<finished_children> will return a list of children who have ended, and
L<running_children> will do the same for children who have called
L<init_child> but not yet ended.

=head1 EXPORTS

By default, nothing is exported by IPC::Fork::Simple. Two tags are available
to export specific flags. Helper functions can be exported by their name.

=head2 :packet_flags

FLAG_PACKET flags are used to describe the reason L<process_child_data> has
returned, and generally describing the the last action by a child.

Note: Other flags, and thus other return values, do exist, however they should
never be returned to the caller unless due to a bug in IPC::Fork::Simple.

=head3 FLAG_PACKET_NOERROR

No error has occurred. This flag is only returned when L<process_child_data>
is called without blocking, but no data or events were pending.

=head3 FLAG_PACKET_CHILD_DISCONNECTED

A child has ended (successfully or otherwise).

=head3 FLAG_PACKET_DATA

A child has sent data and it has been successfully received.

=head3 FLAG_PACKET_CHILD_HELLO

A child has called L<init_child>.

=head2 :block_flags

Block flags define different blocking methods for calls to
L<process_child_data>. See L<process_child_data> for details.

=head3 BLOCK_NEVER

Never blocks. Processes all available data on the socket and then returns.

Note: Technically, it is possible for this flag to block. For example, if a
child sends partial data, the call will block until the rest of the data is
received. These cases should be extremely rare.

=head3 BLOCK_UNTIL_CHILD

Blocks until a child disconnects.

Note: This flag will cause a return in other cases which are only used
internally, however it's possible a bug may cause a L<process_child_data> to
return to the caller under other conditions.

=head3 BLOCK_UNTIL_DATA

Blocks until a child returns data or disconnects. The notes for
BLOCK_UNTIL_CHILD apply here too (as this is simply a superset of
BLOCK_UNTIL_CHILD).

=cut

##############################################################################

use strict;
use IO::Socket::INET;
use IO::Select;
use Storable qw/ thaw freeze /;
use Carp;
use Socket;

use constant 1.01;
use constant DEBUG                      => 0;
use constant CLIENT_AUTHENTICATION_TIME => 30;    # seconds

if ( DEBUG ) {
    require Data::Dumper;
    import Data::Dumper;
    require Data::Hexdumper;
    import Data::Hexdumper;
}

use vars qw( $VERSION );
$VERSION = 1.47;

if ( DEBUG ) {
    $SIG{__WARN__} = sub { warn "$$ " . shift; };
}

require Exporter;
our ( @ISA, @EXPORT_OK, %EXPORT_TAGS );

# Here are some constants we defined based on the size of various data types.
# These data types are not defined in machine-dependent ways, so these should
# only need to be changed when the packet formats change.

# 1 byte for flags.
use constant HEADER_SIZE    => 1;
use constant HEADER_PACKING => 'c';

# Data name length (4 bytes) + data length (4 bytes).
use constant HEADER_DATA_ADDITIONAL_SIZE => 8;
use constant HEADER_DATA_PACKING         => 'NN';

# Number of finished children (4 bytes).
use constant HEADER_FINISHED_ADDITIONAL_SIZE => 4;
use constant HEADER_FINISHED_PACKING         => 'N';

# cid length (4 bytes) + whether or not the child is finished (1 byte) +
# source's symbolic name length (4 bytes).
use constant HEADER_FINISHED_EACH_ADDITIONAL_SIZE => 9;
use constant HEADER_FINISHED_EACH_PACKING         => 'NcN';

# Source's cid, source's symbolic name length (4 bytes) + data name length (4
# bytes) + data length (4 bytes).
use constant HEADER_HANDLER_DATA_ADDITIONAL_SIZE => 16;
use constant HEADER_HANDLER_DATA_PACKING         => 'NNNN';

# Shared key, symbolic name length (4 bytes).
use constant HEADER_CHILD_HELLO_ADDITIONAL_SIZE => 8;
use constant HEADER_CHILD_HELLO_PACKING         => 'NN';

# Constants used to define the type of packet being sent. FLAG_PACKET_* values
# occupy the bottom 4 bits of the "flags" byte, while FLAG_DATA_* values have
# the top 4 bits. The bottom 4 bits (for FLAG_PACKET_*) are treated as a
# 4-bit integer, while the upper 4 bits (for FLAG_DATA_*) are treated as a
# bitfield. The max value for FLAG_PACKET_* flags is 2**4 == 15.
# FLAG_RETURN_* values are return values used by _data_from_socket to
# indicate other return conditions. They're never transmitted as part of a
# packet, but need to share the same data-space as FLAG_PACKET_* values, so
# we start counting FLAG_PACKET_* from the highest FLAG_RETURN_ value +1.
#
# When adding these, pay attention to the regular expression for exporting
# these constants.

# No error encountered.
use constant FLAG_RETURN_NOERROR => 0;
# A child was disconnected.
use constant FLAG_RETURN_CHILD_DISCONNECTED => 1;

# Copy these two constants out into the FLAG_PACKET namespace for export use.
use constant FLAG_PACKET_NOERROR            => FLAG_RETURN_NOERROR;
use constant FLAG_PACKET_CHILD_DISCONNECTED => FLAG_RETURN_CHILD_DISCONNECTED;

# Packet contains data.
use constant FLAG_PACKET_DATA => 2;
# Packet contains data on all children that have connected (their cid,
# symbolic name, and whether or not they have finished).
use constant FLAG_PACKET_FINISHED_CHILDREN => 3;
# Query for children that have disconnected.
use constant FLAG_PACKET_ASK_FINISHED_CHILDREN => 4;
# Master asking the data handler to send all child data.
use constant FLAG_PACKET_GET_CHILD_DATA => 5;
# Master asking the data handler to exit after returning all data.
use constant FLAG_PACKET_GET_CHILD_DATA_AND_EXIT => 6;
# Master asking the data handler to send all child data, but block until there
# is some, if there is none.
use constant FLAG_PACKET_GET_CHILD_DATA_BLOCK => 7;
# Master asking the data handler to send all child data, but block until a
# child has exited.
use constant FLAG_PACKET_GET_CHILD_DATA_FINISHED_BLOCK => 8;
# Data handler reporting it has sent all data to parent and is clearing its
# stored data.
use constant FLAG_PACKET_DATA_HANDLER_DATA_CHECKPOINT => 9;
# Child connecting to master and registering its symbolic name.
use constant FLAG_PACKET_CHILD_HELLO => 10;
# Data for all children, sent from the data handler.
use constant FLAG_PACKET_HANDLER_DATA => 11;

# FLAG_DATA_* values should be powers of 2 and start at 16, in order to fit
# into MASK_FLAG_DATA's bitmask.

# Bit representing whether or not the contained data is to be enqueued (as
# opposed to overwritten).
use constant FLAG_DATA_ENQUEUE => 16;

# Mask bits to locate the FLAG_DATA_* bits.
use constant MASK_FLAG_DATA => 0xf0;

# Constants to improve readability. When adding these, pay attention to the
# regular expression for exporting these constants.
use constant BLOCK_NEVER       => 0;
use constant BLOCK_UNTIL_CHILD => 1;
use constant BLOCK_UNTIL_DATA  => 2;

{
    my @packet_flags = map { /::([^:]+)$/; $1 }
     grep( /^IPC::Fork::Simple::FLAG_PACKET_/, keys( %constant::declared ) );
    my @block_flags = map { /::([^:]+)$/; $1 }
     grep( /^IPC::Fork::Simple::BLOCK/, keys( %constant::declared ) );

    @ISA = ( 'Exporter' );
    @EXPORT_OK = ( 'partition_list', @packet_flags, @block_flags );

    %EXPORT_TAGS = (
        'packet_flags' => [@packet_flags],
        'block_flags'  => [@block_flags],
    );
}

sub ASSERT ($) {
    my ( $cond ) = @_;

    if ( !$cond ) {
        local $Carp::CarpLevel = 1;
        confess "Assertion failed!";
    }
}

sub _new_defaults {
    my ( $self ) = @_;

    $self->{'child_info'}              = {};
    $self->{'is_child'}                = 0;
    $self->{'finished_children'}       = {};
    $self->{'socket_to_cid'}           = {};
    $self->{'next_cid'}                = 0;
    $self->{'unauthenticated_clients'} = {};

    # Don't really need these here, they're just for my own knowledge.
    $self->{'handler_port'}         = undef;
    $self->{'handler_socket'}       = undef;
    $self->{'handler_select'}       = undef;
    $self->{'handler_child_socket'} = undef;
    $self->{'handler_pid'}          = undef;
    $self->{'is_handler_parent'}    = undef;
    $self->{'master_ip'}            = '127.0.0.1';
}

=head1 METHODS

=head2 new

Constructor for an IPC::Fork::Simple object. Takes no arguments. Returns an
IPC::Fork::Simple object on success, or die()'s on failure.

=cut

sub new {
    my ( $class ) = @_;
    my $self = {};
    bless $self, $class;

    $self->_new_defaults();

    $self->{'master_socket'} =
     IO::Socket::INET->new( Type => SOCK_STREAM, LocalAddr => $self->{'master_ip'}, Listen => 100 );
    if ( !$self->{'master_socket'} ) {
        die "Failed to create socket " . $self->{'master_port'} . ": $!";
    }
    $self->{'master_select'} = IO::Select->new( $self->{'master_socket'} );
    if ( !$self->{'master_select'} ) {
        die "Failed to create IO::Select object!";
    }
    $self->{'master_port'} = $self->{'master_socket'}->sockport() || die $!;
    $self->{'shared_key'} = int( rand( 0xFFFFFFFF ) );

    return $self;
}

=head2 new_child

Constructor for an IPC::Fork::Simple child-only object, used for bi-
directional with a master.

The first parameter is an opaque value containing master connection info as
returned by L<get_connection_info> on an existing IPC::Fork::Simple object.

The second, optional, parameter is a symbolic name for this process. See
L<init_child> for information on symbolic process names. If not set, defaults
to the process ID.

=cut

sub new_child {
    my ( $class, $opaque, $symbolic ) = @_;
    my $self = {};
    bless $self, $class;

    return unless $opaque;

    $self->_new_defaults();

    my $connection_info = thaw( $opaque );

    $self->{'master_ip'}   = $connection_info->{'ip'};
    $self->{'master_port'} = $connection_info->{'port'};
    $self->{'shared_key'}  = $connection_info->{'shared_key'};
    return unless $self->init_child( $symbolic );

    return $self;
}

=head2 spawn_data_handler

Only usable by the master.

Runs the parent in data hander mode (see above). Causes the caller to
fork(), which may be undesirable in some circumstances. Calls die() on failure.

=cut

sub spawn_data_handler {
    my ( $self ) = @_;
    return if $self->{'is_child'};
    return if $self->{'handler_pid'};

    local $SIG{'PIPE'} = 'IGNORE';

    $self->{'handler_socket'} =
     IO::Socket::INET->new( Type => SOCK_STREAM, LocalAddr => $self->{'master_ip'}, Listen => 100 );
    if ( !$self->{'handler_socket'} ) {
        die "Failed to create socket " . $self->{'handler_port'} . ": $!";
    }
    $self->{'handler_ip'}     = $self->{'master_ip'};
    $self->{'handler_port'}   = $self->{'handler_socket'}->sockport() || die $!;
    $self->{'handler_select'} = IO::Select->new();
    if ( !$self->{'handler_select'} ) {
        die "Failed to create IO::Select object";
    }

    my ( $rh, $wh );
    pipe( $rh, $wh );
    $self->{'handler_pid'} = fork();
    if ( !defined $self->{'handler_pid'} ) {
        die "Fork failed: $!";
    }
    if ( $self->{'handler_pid'} ) {
        local $SIG{PIPE} = 'IGNORE';
        undef $self->{'handler_child_socket'};
        foreach my $s ( $self->{'master_select'}->handles ) {
            close $s;
        }
        undef $self->{'master_select'};
        undef $self->{'master_socket'};
        $self->{'is_child'}          = 0;
        $self->{'is_handler_parent'} = 1;
        close( $wh );
        <$rh>;
        close( $rh );
        $self->{'handler_socket_comm'} = $self->{'handler_socket'}->accept()
         || die "Accept failure... I don't know what to do! $!";
        $self->{'handler_select'}->add( $self->{'handler_socket_comm'} );

    } else {

        sub _send_finished_children {
            my ( $self ) = @_;
            my $finished_child_data = '';

            foreach my $cid ( keys( %{ $self->{'child_info'} } ) ) {
                $finished_child_data .= pack(
                    HEADER_FINISHED_EACH_PACKING,    # packing
                    $cid,
                    ( exists $self->{'finished_children'}->{$cid} ? 1 : 0 ),
                    length( $self->{'child_info'}->{$cid}->{'symbolic_name'} )
                ) . $self->{'child_info'}->{$cid}->{'symbolic_name'};
            }

            $self->{'handler_child_socket'}->send(
                pack(
                    HEADER_PACKING . HEADER_FINISHED_PACKING,    # packing
                    FLAG_PACKET_FINISHED_CHILDREN,
                    scalar( keys( %{ $self->{'child_info'} } ) )
                 )
                 . $finished_child_data
            ) || die "Failed to report finished children to master: $!";

            $self->{'finished_children'} = {};
        }

        sub _handler_data_to_socket {
            my ( $socket, $info, $source_cid, $data_name, $queued ) = @_;

            my $source_symbolic_name = $info->{$source_cid}->{'symbolic_name'};
            my $flags                = FLAG_PACKET_HANDLER_DATA;
            my $data;

            if ( $queued ) {
                $flags |= FLAG_DATA_ENQUEUE;
                $data = \$info->{$source_cid}->{'data_queue'}->{$data_name};
            } else {
                $data = \$info->{$source_cid}->{'data'}->{$data_name};
            }

            my $r = $socket->send(
                pack(
                    HEADER_PACKING . HEADER_HANDLER_DATA_PACKING,    # packing
                    $flags,
                    $source_cid,
                    length( $source_symbolic_name ),
                    length( $data_name ),
                    length( ${$data} )
                 )
                 . $source_symbolic_name
                 . $data_name
                 . ${$data}
            ) || die "Failed to send data to master: $!";

            return 0 unless $r;
            return 1;
        }

        $0 = 'data_handler';

        $self->{'handler_child_socket'} = IO::Socket::INET->new(
            Type     => SOCK_STREAM,
            PeerAddr => $self->{'handler_ip'},
            PeerPort => $self->{'handler_port'}
        );
        if ( !$self->{'handler_child_socket'} ) {
            die "Failed to create client socket to " . $self->{'handler_port'} . ": $!";
        }

        undef $self->{'handler_select'};
        undef $self->{'handler_socket'};
        undef $self->{'handler_socket_comm'};
        undef $self->{'is_child'};

        $self->{'is_handler_parent'} = 0;
        close( $wh );
        close( $rh );

        $self->{'master_select'}->add( $self->{'handler_child_socket'} );

        while ( 1 ) {
            my $r = $self->_data_from_socket( $self->{'master_select'}, BLOCK_UNTIL_CHILD );
            if ( $r == FLAG_PACKET_ASK_FINISHED_CHILDREN ) {
                $self->_send_finished_children();
            } elsif ( ( $r == FLAG_PACKET_GET_CHILD_DATA )
                || ( $r == FLAG_PACKET_GET_CHILD_DATA_AND_EXIT )
                || ( $r == FLAG_PACKET_GET_CHILD_DATA_FINISHED_BLOCK )
                || ( $r == FLAG_PACKET_GET_CHILD_DATA_BLOCK ) )
            {

                # If we're exiting, gather all outstanding data first.
                if ( $r == FLAG_PACKET_GET_CHILD_DATA_AND_EXIT ) {
                    while ( keys( %{ $self->{'socket_to_cid'} } ) ) {
                        $self->_data_from_socket( $self->{'master_select'}, BLOCK_UNTIL_CHILD );
                    }

                    # If they only want us to return when we've got data...
                } elsif ( ( $r == FLAG_PACKET_GET_CHILD_DATA_BLOCK )
                    || ( $r == FLAG_PACKET_GET_CHILD_DATA_FINISHED_BLOCK ) )
                {
                    my $do_we_have_data;

                    # Gymnastics to determine if we have something to share.
                    # If a child has sent data or exited, we can continue.
                    # Otherwise, block until we collect something. Remember,
                    # once we send something we delete it, so if we have
                    # anything at all we know it will be new to the master.
                    do {
                        $do_we_have_data = 0;
                        if ( scalar( keys( %{ $self->{'finished_children'} } ) ) ) {
                            $do_we_have_data = 1;
                            # Only check for new data as a condition to continue
                            # if the caller wants us to.
                        } elsif ( $r == FLAG_PACKET_GET_CHILD_DATA_BLOCK ) {
                            foreach my $cid ( keys( %{ $self->{'child_info'} } ) ) {
                                if (   ( keys( %{ $self->{'child_info'}->{$cid}->{'data'} } ) )
                                    || ( keys( %{ $self->{'child_info'}->{$cid}->{'data_queue'} } ) ) )
                                {
                                    $do_we_have_data = 1;
                                }
                            }
                        }
                        if ( !$do_we_have_data ) {
                            $self->_data_from_socket( $self->{'master_select'}, BLOCK_UNTIL_DATA );
                        }
                    } until ( $do_we_have_data );
                }

                $self->_send_finished_children();
                foreach my $cid ( keys( %{ $self->{'child_info'} } ) ) {
                    foreach my $data_name ( keys( %{ $self->{'child_info'}->{$cid}->{'data'} } ) ) {
                        _handler_data_to_socket(
                            $self->{'handler_child_socket'},
                            $self->{'child_info'},
                            $cid,
                            $data_name,
                            0    # send queued data?
                        );
                    }
                    foreach my $data_name ( keys( %{ $self->{'child_info'}->{$cid}->{'data_queue'} } ) ) {
                        _handler_data_to_socket(
                            $self->{'handler_child_socket'},
                            $self->{'child_info'},
                            $cid,
                            $data_name,
                            1    # send queued data?
                        );
                    }
                }
                $self->{'handler_child_socket'}
                 ->send( pack( HEADER_PACKING, FLAG_PACKET_DATA_HANDLER_DATA_CHECKPOINT ) )
                 || die "Failed to report checkpoint to master: $!";
                if ( $r == FLAG_PACKET_GET_CHILD_DATA_AND_EXIT ) {
                    last;
                }

                foreach my $cid ( keys( %{ $self->{'child_info'} } ) ) {
                    $self->{'child_info'}->{$cid}->{'data'}       = {};
                    $self->{'child_info'}->{$cid}->{'data_queue'} = {};
                }
            } elsif ( ( $r != FLAG_PACKET_DATA ) && ( $r != FLAG_RETURN_CHILD_DISCONNECTED ) ) {
                warn "Should not be here! Got packet for: $r";
            }
        }
        # Data handler fork has done its job... exit!
        exit 0;
    }
}

=head2 collect_data_from_handler

Only usable by the master when using the data handler method.

When using the data hander method of operation (see above), this function
will cause the data hander fork to return all data it has received from
children to the master and will cause the data hander to clear its cache
of child data.

The first, optional, parameter defines whether or not the data handler
should stay running after returning all data. For backwards compatibility, the
default (false) is to exit after collecting all data.

If this parameter is set to true, the data handler will not exit after the
data is sent, allowing the caller to collect data again at a later time.

If this parameter is set to false,  no more child processes will be able to
send data back to the master, as the data handler will have exited. This
should only be called after all children have ended.

The second, optional, parameter is one of the BLOCK flags, as used by
L<process_child_data>. See EXAMPLES for details on the meaning of these flags.

=cut

sub collect_data_from_handler {
    my ( $self, $keep_alive, $block ) = @_;
    my ( $r, $msg );

    if ( !$self->{'handler_pid'} ) { return; }
    local $SIG{'PIPE'} = 'IGNORE';

    if ( $keep_alive ) {
        if ( $block == BLOCK_NEVER ) {
            $msg = FLAG_PACKET_GET_CHILD_DATA;
        } elsif ( $block == BLOCK_UNTIL_DATA ) {
            $msg = FLAG_PACKET_GET_CHILD_DATA_BLOCK;
        } elsif ( $block == BLOCK_UNTIL_CHILD ) {
            $msg = FLAG_PACKET_GET_CHILD_DATA_FINISHED_BLOCK;
        } else {
            carp "Invalid value for BLOCK!";
        }
    } else {
        $msg = FLAG_PACKET_GET_CHILD_DATA_AND_EXIT;
    }
    $self->{'handler_socket_comm'}->send( pack( HEADER_PACKING, $msg ) )
     || die "Failed to send data to data handler: $!";

    # _data_from_socket will return when
    # FLAG_PACKET_DATA_HANDLER_DATA_CHECKPOINT is received.
    do {
        $r = $self->_data_from_socket( $self->{'handler_select'}, BLOCK_UNTIL_CHILD );
    } until ( $r == FLAG_PACKET_DATA_HANDLER_DATA_CHECKPOINT );

    if ( !$keep_alive ) {
        # _data_from_socket will return when the remote socket is closed.
        $self->_data_from_socket( $self->{'handler_select'}, BLOCK_UNTIL_CHILD );
        waitpid( $self->{'handler_pid'}, 0 );
        $self->{'handler_pid'} = 0;
    }
    return 1;
}

=head2 init_child

Only usable by a child.

Only to be called by a child after a fork, this method configured this
child for communication with the master (or data handler). Will die on failure.

The first, optional, parameter is a symbolic name for this child with which
the master can retrieve data. Each child will automatically be assigned a
unique id (cid), but the optional symbolic name can be used to simplify
development. If not set, the symbolic name will be set to the process ID. The
symbolic name can not be a zero-length string.

Note: If a symbolic name is re-used, fetching data by symbolic name will fetch
data for one randomly chosen child that shares that name. If symbolic names
will be re-used, it's suggested that data is fetched instead by cid.

Be aware that PIDs, the default symbolic name, may be re-used on a system,
leading to a collision of symbolic names. In order to avoid this issue, do not
call wait (or otherwise reap the child process) until you have fetched (and
then cleared) all of its data. Alternately, address child processes by cid
instead.

=cut

sub init_child {
    my ( $self, $symbolic_name ) = @_;

    # We can't really protect against being called on the master...
    return if $self->{'is_child'};
    local $SIG{'PIPE'} = 'IGNORE';
    delete $self->{'master_socket'};
    delete $self->{'child_info'};

    if ( ( !defined $symbolic_name ) || ( length( $symbolic_name ) == 0 ) ) {
        $symbolic_name = $$;
    }

    $self->{'symbolic_name'} = $symbolic_name;
    $self->{'is_child'}      = 1;
    $self->{'child_socket'} =
     IO::Socket::INET->new( Type => SOCK_STREAM, PeerAddr => $self->{'master_ip'}, PeerPort => $self->{'master_port'} );
    if ( !$self->{'child_socket'} ) {
        die "Failed to connect to master socket " . $self->{'master_port'} . ": $!";
    }

    $self->{'child_socket'}->send(
        pack(
            HEADER_PACKING . HEADER_CHILD_HELLO_PACKING,    # Packing
            FLAG_PACKET_CHILD_HELLO,
            $self->{'shared_key'},
            length( $self->{'symbolic_name'} )
         )
         . $self->{'symbolic_name'}
    ) || die "Failed to send data to master: $!";
    return 1;
}

=head2 to_master

Only usable by a child.

Sends data to the master (or data handler). Takes two parameters, the first a
string, used as a symbolic name for the data by which it will be retrieved. The
second parameter is the data (a scalar) that should be sent.  Data can be in any
format understandable by L<Storable>, however since this data is sent between
forks, data containing filehandles should not be passed.

=cut

sub to_master {
    my ( $self, $name, $data ) = @_;
    return unless $self->{'is_child'};
    if ( !$self->{'child_socket'} ) { die "Must call init_child before sending data!"; }
    # Last parameter here says not to enqueue the data.
    return $self->_data_to_socket( $self->{'child_socket'}, $name, $data, 0 );
}

=head2 push_to_master

Only usable by a child.

Pushes data into a queue sent to the master. Unlike L<to_master>, data sent with
L<push_to_master> is not overwritten, but appended to, much like when working
with an array. Function semantics are otherwise identical to L<to_master>.

The first parameter is the symbolic name for the data, and the second is a
reference to the data that will be sent.

=cut

sub push_to_master {
    my ( $self, $name, $data ) = @_;
    return unless $self->{'is_child'};
    if ( !$self->{'child_socket'} ) { die "Must call init_child before sending data!"; }
    return $self->_data_to_socket( $self->{'child_socket'}, $name, $data, FLAG_DATA_ENQUEUE );
}

=head2 from_cid

Only usable by the master.

Retrieves data from a child after the child has sent it. Takes two parameters,
the first is the cid from which the data was sent, and the second is a symbolic
name (a string) for the data, which the child specified when the data was sent.

Returns nothing if no data is available, or a reference to whatever data the
child sent. Note: You may need to use ref() in order to determine the type of
the data sent.

=cut

sub from_cid {
    my ( $self, $cid, $name ) = @_;
    if (   ( $self->{'is_child'} )
        || ( !$self->{'child_info'}->{$cid} )
        || ( !$self->{'child_info'}->{$cid}->{'data'} ) )
    {
        return;
    }
    return $self->{'child_info'}->{$cid}->{'data'}->{$name};
}

=head2 from_child

Only usable by the master.

Semantics are the same as L<from_cid>, but searches by symbolic name instead
of cid.

=cut

sub from_child {
    my ( $self, $sn, $name ) = @_;
    return if ( $self->{'is_child'} );

    my $cid = $self->_find_cid_for_symbolic_name( $sn );
    return unless defined $cid;
    return $self->from_cid( $cid, $name );
}

=head2 pop_from_cid

Only usable by the master.

Retrieves pushed data from a child after the child has sent it. Takes two
parameters, the first is the cid from which the data was sent, and the second is
a symbolic name (a string) for the data, which the child specified when the data
was sent.

Called in scalar context, returns nothing if no data is available, or a
reference to the oldest data the child pushed. Called in array context, returns
an empty array if no data is available, or an array of references to the data
pushed by the child, ordered oldest to most recent.

After the data is returned, it is removed from the internal list, so a
subsequent call to L<pop_from_cid> will return the next oldest set of data.
Note: You may need to use ref() in order to determine the type of the data sent.

=cut

sub pop_from_cid {
    my ( $self, $cid, $name ) = @_;
    if (   ( $self->{'is_child'} )
        || ( !$self->{'child_info'}->{$cid} )
        || ( !$self->{'child_info'}->{$cid}->{'data_queue'} )
        || ( !$self->{'child_info'}->{$cid}->{'data_queue'}->{$name} ) )
    {
        return;
    }

    if ( wantarray ) {
        my @r = @{ $self->{'child_info'}->{$cid}->{'data_queue'}->{$name} };
        $self->{'child_info'}->{$cid}->{'data_queue'}->{$name} = [];
        return @r;
    } else {
        return shift @{ $self->{'child_info'}->{$cid}->{'data_queue'}->{$name} };
    }
}

=head2 pop_from_child

Only usable by the master.

Semantics are the same as L<from_cid>, but searches by symbolic name
instead of cid.

=cut

sub pop_from_child {
    my ( $self, $sn, $name ) = @_;
    return if $self->{'is_child'};

    my $cid = $self->_find_cid_for_symbolic_name( $sn );
    return unless defined $cid;

    if ( wantarray ) {
        my @r = $self->pop_from_cid( $cid, $name );
        return @r;
    } else {
        my $r = $self->pop_from_cid( $cid, $name );
        return $r;
    }
}

=head2 finished_children

Only usable by the master.

In scalar context, returns the number of children who have finished.

In array contaxt and the first, optional, parameter is true, returns a hash of
cid-to-symbolic name mappings for these children. If the first parameter is not
set, or is false, returns a list of CIDs that have finished.

=cut

sub finished_children {
    my ( $self, $as_hash ) = @_;

    # We're the parent of a running handler fork, so we need to ask the
    # handler to return the current total to us.
    if ( ( $self->{'is_handler_parent'} ) && ( $self->{'handler_pid'} ) ) {
        $self->_do_finished_children_request();
    }

    if ( wantarray ) {
        if ( $as_hash ) {
            return %{ $self->{'finished_children'} };
        } else {
            return keys( %{ $self->{'finished_children'} } );
        }
    } else {
        return scalar( keys( %{ $self->{'finished_children'} } ) );
    }
}

=head2 running_children

Only usable by the master.

In scalar context, returns the number of children who have called
L<init_child> but have not yet ended.

In array contaxt and the first, optional, parameter is true, returns a hash of
cid-to-symbolic name mappings for these children. If the first parameter is
not set, or is false, returns a list of CIDs that have not yet finished.

=cut

sub running_children {
    my ( $self, $as_hash ) = @_;

    # We're the parent of a running handler fork, so we need to ask the
    # handler to return the current total to us.
    if ( ( $self->{'is_handler_parent'} ) && ( $self->{'handler_pid'} ) ) {
        $self->_do_finished_children_request();
    }

    my %running_children;

    foreach my $cid ( keys( %{ $self->{'child_info'} } ) ) {
        if ( !exists $self->{'finished_children'} ) {
            $running_children{$cid} = $self->{'child_info'}->{'symbolic_name'};
        }
    }

    if ( wantarray ) {
        if ( $as_hash ) {
            return %running_children;
        } else {
            return keys( %running_children );
        }
    } else {
        return scalar( keys( %running_children ) );
    }
}

=head2 process_child_data

Only usable by the master when using the blocking wait and polling methods.

Processes data from all children. Takes a single parameter, a BLOCK flag that
determines if, and how, L<process_child_data> should block. See the EXPORTS
section for details on these flags.

L<child_data> and L<finished_children> can be called between calls
to process_child_data, but there is no guarantee there will be any data
available.

If L<process_child_data> is not called often or fast enough, children will be
forced to block on calls to L<to_master>, and data loss is possible.

Returns a FLAG_PACKET flag describing the last child action. See the EXPORTS
section for details on these flags.

=cut

sub process_child_data {
    my ( $self, $block ) = @_;
    return if $self->{'is_child'};
    return if $self->{'handler_pid'};
    return $self->_data_from_socket( $self->{'master_select'}, $block );
}

=head2 clear_finished_children

Only usable by the master.

Deletes the master's copy of the list of children who have ended. If a data
handler is being used, its copy of the list is not affected.

The only optional parameter is the list of child PIDs to remove data for. If
specified, only the entries for those specified children will be removed. If no
list is passed, then all data will be cleared.

=cut

sub clear_finished_children {
    my ( $self, @children ) = @_;
    if ( @children ) {
        foreach my $c ( @children ) {
            delete $self->{'finished_children'}->{$c};
        }
    } else {
        $self->{'finished_children'} = {};
    }
}

=head2 clear_child_data

Only usable by the master.

Deletes the master's copy of the data (standard and enqueued) children who have
ended. If a data handler is being used, its copy of the lists are not affected.

The only optional parameter is the list of child PIDs to remove data for. If
specified, only the entries for those specified children will be removed. If no
list is passed, then all data will be cleared.

=cut

sub clear_child_data {
    my ( $self, @children ) = @_;
    if ( @children ) {
        foreach my $c ( @children ) {
            delete $self->{'child_info'}->{$c};
        }
    } else {
        $self->{'child_info'} = {};
    }
}

=head2 get_connection_info

Only usable by the master.

Retrieves an opaque value representing connection data for this object (or its
data handler). Only useful to pass into L<new_child>.

=cut

sub get_connection_info {
    my ( $self ) = @_;

    return if $self->{'is_child'};

    return freeze(
        {
            'port'       => $self->{'master_port'},
            'ip'         => $self->{'master_ip'},
            'shared_key' => $self->{'shared_key'},
        }
    );
}

=head2 get_waitable_fds

Only usable by the master.

Returns an array of any waitable/important filehandles. Useful if the caller
wants to implement his own loop and only call IPC::Fork::Simple methods when
there is data waiting for IPC::Fork::Simple. The caller could select on the
list of returned handles here and if one is readable, then call the appropriate
IPC::Fork::Simple method and to allow the module to handle its data.

=cut

sub get_waitable_fds {
    my ( $self ) = @_;

    return () if $self->{'is_child'};

    if ( $self->{'is_handler_parent'} ) {
        return $self->{'handler_select'}->handles();
    } else {
        return $self->{'master_select'}->handles();
    }
}

### Exportable functions

=head1 USEFUL FUNCTIONS

Included with IPC::Fork::Simple are some helpful functions. These are not
exported by default. Note, these are not methods, they are standard functions.
They must be called directly and not as methods on an IPC::Fork::Simple object.

=head2 partition_list

Partitions a list of length L into N pieces as evenly as possible. If even
partitioning is not possible, the first L % N elements will be one element
larger than the rest.

The first parameter is the number of partitions (N), the second is an array
reference to the data to partition. An array of N array references will be
returned. If this value is <= 1, a single element array containing a copy of
the list is returned.

Example:

 @r = partition_list( 3, [1..10] );
 # @r is now: [ 1, 2, 3, 4 ], [ 5, 6, 7 ], [ 8, 9, 10 ]

=cut

sub partition_list {
    my ( $count, $list ) = @_;
    die "Invalid parameters" if ref $count;
    return ( [@{$list}] ) unless $count > 1;

    my @final;
    my $start = 0;
    my $size_of_partition;
    my $leftover;
    my $i;

    if ( $count < scalar( @{$list} ) ) {
        $size_of_partition = int( scalar( @{$list} ) / $count );
        $leftover          = scalar( @{$list} ) % $count;
        if ( $leftover ) {
            $size_of_partition++;
        }
    } else {
        $size_of_partition = 1;
    }

    for ( $i = 0; $i < $count; $i++ ) {
        if ( $start >= scalar( @{$list} ) ) {
            $final[$i] = [];
        } else {
            # This is weird syntax for getting an array slice out of an arrayref.
            $final[$i] = [@{$list}[$start .. $start + $size_of_partition - 1]];
            $start += $size_of_partition;
            if ( $leftover ) {
                $leftover--;
                if ( $leftover == 0 ) {
                    $size_of_partition--;
                }
            }
        }
    }

    return @final;
}

### End of public methods, begin private stuff...

# Send data to our parent, which could be a master or a data handler. The
# caller is expected to know which and set the appropriate flags.
sub _data_to_socket {
    my ( $self, $socket, $name, $data, $data_flags ) = @_;
    local $SIG{'PIPE'} = 'IGNORE';
    $data = freeze( \$data );

    if ( !defined $data_flags ) {
        $data_flags = 0;
    }

    my $flags = ( FLAG_PACKET_DATA | $data_flags );

    my $r = $socket->send(
        pack( HEADER_PACKING . HEADER_DATA_PACKING, $flags, length( $name ), length( $data ) ) . $name . $data )
     || die "Failed to send data to socket: $!";

    return $r ? 1 : 0;
}

# Waits on a socket for data, or a child to disconnect. Expects caller to know
# whether or not to unwrap the received data (if the client is a master).
# Returns the FLAG_PACKET_* type of the packet received, usually FLAG_PACKET_DATA,
# unless it's called in blocking mode
sub _data_from_socket {
    my ( $self, $select, $block ) = @_;
    my $data;

    my $disconnect_client = sub {
        my ( $s ) = @_;
        $select->remove( $s );
        if ( defined $self->{'socket_to_cid'}->{$s} ) {
            # Don't register a "finished child" if it's the data handler that
            # exited. handler_socket_comm is only set on a master.
            if (   ( !$self->{'handler_socket_comm'} )
                || ( $s != $self->{'handler_socket_comm'} ) )
            {
                $self->{'finished_children'}->{ $self->{'socket_to_cid'}->{$s} } =
                 $self->{'child_info'}->{ $self->{'socket_to_cid'}->{$s} }->{'symbolic_name'};
            }
            delete $self->{'socket_to_cid'}->{$s};
        }
        delete $self->{'unauthenticated_clients'}->{$s};
        $s->close();
    };

    my $flush_unauthenticated_clients = sub {
        my $start_ts = time();
        while ( my ( $k, $v ) = each( %{ $self->{'unauthenticated_clients'} } ) ) {
            if ( $start_ts > $v->{'ts'} + CLIENT_AUTHENTICATION_TIME ) {
                $disconnect_client->( $v->{'socket'} );
            }
        }
    };

    my $VALIDATE = sub {
        my ( $s, $cond ) = @_;

        if ( !$cond ) {
            $disconnect_client->( $s );
            return undef;
        }
        return 1;
    };

    my $recv_more = sub {
        my ( $socket, $more ) = @_;
        my $data = '';

        while ( length( $data ) < $more ) {
            my $r;
            $socket->recv( $r, $more - length( $data ) );
            if ( ( !defined $r ) || ( length( $r ) == 0 ) ) {
                $disconnect_client->( $socket );
                return undef;
            }
            $data .= $r;
        }

        # Not necessary, but we can keep it in case something goes awry above.
        if ( ( !defined $data ) || ( length( $data ) != $more ) ) {
            $disconnect_client->( $socket );
            return undef;
        }

        if ( DEBUG ) {
            my @guessconst;
            foreach my $c ( keys( %constant::declared ) ) {
                if ( $c =~ /::HEADER_.+_SIZE$/ ) {
                    if ( length( $data ) == eval $c ) {
                        $c =~ s/^.+:://;
                        push @guessconst, $c;
                    }
                }
            }
            warn "Read "
             . length( $data )
             . " bytes ("
             . join( ',', @guessconst ) . "?)\n"
             . hexdump( data => $data ) . "\n";
        }
        return $data;
    };

    # Wrap the select in a do/while loop so we restart after catching any
    # signals, regardless of any signal handlers the caller may have
    # installed. By using a do/while loop, we're guaranteed to run at least
    # once, even if we're set not to block.
    do {
        # Passing 'undef' will block indefinitely. Passing 0 will not block. We
        # accept a few different BLOCK values here, so what we're saying is to
        # pass undef (ie, block) if we're in any mode other than BLOCK_NEVER.
        # This probably should be re-written to be clearer.
        while ( my @ready = $select->can_read( ( $block != BLOCK_NEVER ? undef : 0 ) ) ) {

            # Only a data handler has a handler_child_socket.
            # Process requests from the master last, to insure we have the
            # most up-to-data data from our children.
            if ( $self->{'handler_child_socket'} ) {
                # Intentionally skip the last element of @ready here!
                for ( my $i = 0; $i < $#ready; $i++ ) {
                    if ( $ready[$i] == $self->{'handler_child_socket'} ) {
                        $ready[$i]      = $ready[$#ready];
                        $ready[$#ready] = $self->{'handler_child_socket'};
                    }
                }
            }

            foreach my $s ( @ready ) {
                if ( ( $self->{'master_socket'} ) && ( $s == $self->{'master_socket'} ) ) {
                    my $new_sock = $s->accept();
                    next unless $new_sock;
                    $select->add( $new_sock );
                    $flush_unauthenticated_clients->();
                    $self->{'unauthenticated_clients'}->{$new_sock} = {
                        sock => $new_sock,
                        ts   => time(),
                    };
                } else {
                    $data = $recv_more->( $s, HEADER_SIZE );
                    if ( !defined $data ) {
                        if ( $self->{'unauthenticated_clients'}->{$s} ) {
                            # This isn't a condition the caller should care
                            # about.
                            next;
                        }
                        return FLAG_RETURN_CHILD_DISCONNECTED;
                    }

                    my ( $flags ) = unpack( HEADER_PACKING, $data );
                    my $data_flags = ( $flags & MASK_FLAG_DATA );
                    $flags = ( $flags & ~MASK_FLAG_DATA );

                    if (   $flags == FLAG_PACKET_ASK_FINISHED_CHILDREN
                        || $flags == FLAG_PACKET_GET_CHILD_DATA
                        || $flags == FLAG_PACKET_GET_CHILD_DATA_AND_EXIT
                        || $flags == FLAG_PACKET_GET_CHILD_DATA_BLOCK
                        || $flags == FLAG_PACKET_GET_CHILD_DATA_FINISHED_BLOCK
                        || $flags == FLAG_PACKET_DATA_HANDLER_DATA_CHECKPOINT )
                    {
                        return $flags;
                    }

                    if ( $flags == FLAG_PACKET_CHILD_HELLO ) {
                        # Okay, lets get the length of the child's symbolic name.
                        $data = $recv_more->( $s, HEADER_CHILD_HELLO_ADDITIONAL_SIZE );
                        if ( !defined $data ) {
                            if ( $self->{'unauthenticated_clients'}->{$s} ) {
                                # This isn't a condition the caller should care
                                # about.
                                next;
                            }
                            return FLAG_RETURN_CHILD_DISCONNECTED;
                        }

                        # Unpack the shared key and symbolic name length.
                        my ( $proposed_key, $name_len ) = unpack( HEADER_CHILD_HELLO_PACKING, $data );
                        next unless $VALIDATE->( $s, $name_len > 0 );
                        next unless $VALIDATE->( $s, $proposed_key == $self->{'shared_key'} );
                        delete $self->{'unauthenticated_clients'}->{$s};

                        $data = $recv_more->( $s, $name_len );
                        next unless $VALIDATE->( $s, defined $data );

                        $self->{'socket_to_cid'}->{$s} = $self->{'next_cid'};
                        $self->{'child_info'}->{ $self->{'next_cid'} } = {
                            'symbolic_name' => $data,
                            'data'          => {},
                            'data_queue'    => {},
                        };
                        $self->{'next_cid'}++;

                    } elsif ( $flags == FLAG_PACKET_DATA ) {
                        $data = $recv_more->( $s, HEADER_DATA_ADDITIONAL_SIZE );
                        return FLAG_RETURN_CHILD_DISCONNECTED if !defined $data;

                        my ( $namelen, $datalen ) = unpack( HEADER_DATA_PACKING, $data );

                        ASSERT( defined $self->{'socket_to_cid'}->{$s} );
                        my $cid = $self->{'socket_to_cid'}->{$s};

                        if ( !$namelen || !$datalen ) {
                            warn "Got badly formatted data from child.";
                            next;
                        }

                        $data = $recv_more->( $s, $namelen + $datalen );
                        return FLAG_RETURN_CHILD_DISCONNECTED if !defined $data;

                        my $name = substr( $data, 0, $namelen );
                        $data = substr( $data, $namelen );

                        # If we have a handler_child_socket then we are a data
                        # handler, so we should not thaw or unthaw data.
                        if ( !$self->{'handler_child_socket'} ) {
                            $data = thaw( $data );
                        }

                        if ( $data_flags & FLAG_DATA_ENQUEUE ) {
                            if ( !exists $self->{'child_info'}->{$cid}->{'data_queue'}->{$name} ) {
                                $self->{'child_info'}->{$cid}->{'data_queue'}->{$name} = [];
                            }
                            push @{ $self->{'child_info'}->{$cid}->{'data_queue'}->{$name} }, $data;
                        } else {
                            $self->{'child_info'}->{$cid}->{'data'}->{$name} = $data;
                        }
                        if ( $block == BLOCK_UNTIL_DATA ) { return FLAG_PACKET_DATA; }

                    } elsif ( $flags == FLAG_PACKET_HANDLER_DATA ) {
                        $data = $recv_more->( $s, HEADER_HANDLER_DATA_ADDITIONAL_SIZE );
                        return FLAG_RETURN_CHILD_DISCONNECTED if !defined $data;

                        my ( $cid, $symboliclen, $namelen, $datalen ) = unpack( HEADER_HANDLER_DATA_PACKING, $data );

                        if ( !$namelen || !$datalen || !$symboliclen ) {
                            warn "Got badly formatted data from child.";
                            next;
                        }

                        $data = $recv_more->( $s, $namelen + $datalen + $symboliclen );
                        return FLAG_RETURN_CHILD_DISCONNECTED if !defined $data;

                        my $symbolic = substr( $data, 0,            $symboliclen );
                        my $name     = substr( $data, $symboliclen, $namelen );
                        $data = substr( $data, $namelen + $symboliclen );

                        # Only a master of a data handler receives this flag,
                        # so we always thaw.
                        $data = thaw( $data );

                        if ( $data_flags & FLAG_DATA_ENQUEUE ) {
                            if ( !exists $self->{'child_info'}->{$cid}->{'data_queue'}->{$name} ) {
                                $self->{'child_info'}->{$cid}->{'data_queue'}->{$name} = [];
                            }
                            push @{ $self->{'child_info'}->{$cid}->{'data_queue'}->{$name} }, $data;
                        } else {
                            $self->{'child_info'}->{$cid}->{'data'}->{$name} = $data;
                        }
                        if ( $block == BLOCK_UNTIL_DATA ) { return FLAG_PACKET_DATA; }

                    } elsif ( $flags == FLAG_PACKET_FINISHED_CHILDREN ) {
                        $data = $recv_more->( $s, HEADER_FINISHED_ADDITIONAL_SIZE );
                        return FLAG_RETURN_CHILD_DISCONNECTED if !defined $data;

                        my ( $count ) = unpack( HEADER_FINISHED_PACKING, $data );
                        while ( $count-- ) {
                            $data = $recv_more->( $s, HEADER_FINISHED_EACH_ADDITIONAL_SIZE );
                            return FLAG_RETURN_CHILD_DISCONNECTED if !defined $data;

                            my ( $finished_cid, $is_finished, $symbolic_name_length ) =
                             unpack( HEADER_FINISHED_EACH_PACKING, $data );

                            $data = $recv_more->( $s, $symbolic_name_length );
                            return FLAG_RETURN_CHILD_DISCONNECTED if !defined $data;

                            if ( $is_finished ) {
                                $self->{'finished_children'}->{$finished_cid} = $data;
                            }

                            if ( !exists $self->{'child_info'}->{$finished_cid} ) {
                                $self->{'child_info'}->{$finished_cid} = {
                                    'data'       => {},
                                    'data_queue' => {},
                                };
                            }
                            $self->{'child_info'}->{$finished_cid}->{'symbolic_name'} = $data;
                        }

                        return FLAG_PACKET_FINISHED_CHILDREN;
                    } else {
                        if ( !exists $self->{'unauthenticated_clients'} ) {
                            warn "Got packet type ($flags) that I don't know how to handle!";
                        } else {
                            $disconnect_client->( $s );
                        }
                        next;
                    }
                    #next;
                }
            }
        }

        if ( $select->count == 0 ) {
            # Technically, this could be hit any time we lose all other forks,
            # but various code paths have us only reaching this point when we
            # go to request data from the handler and he's not there any more.
            die "Data handler exited unexpectedly!";
        }
     } while ( ( $block == BLOCK_UNTIL_CHILD )
        || ( $block == BLOCK_UNTIL_DATA ) );
    return FLAG_RETURN_NOERROR;
}

sub _find_cid_for_symbolic_name {
    my ( $self, $name ) = @_;

    if ( DEBUG ) {
        warn Dumper( $self->{'child_info'} );
    }

    foreach my $cid ( keys( %{ $self->{'child_info'} } ) ) {
        return $cid if $self->{'child_info'}->{$cid}->{'symbolic_name'} eq $name;
    }
    return undef;
}

# This will update running children too.
sub _do_finished_children_request {
    my ( $self ) = @_;
    local $SIG{'PIPE'} = 'IGNORE';
    my $r;

    $self->{'handler_socket_comm'}->send( pack( HEADER_PACKING, FLAG_PACKET_ASK_FINISHED_CHILDREN ) )
     || die "Failed to send data to parent: $$ -> $!";
    do {
        $r = $self->_data_from_socket( $self->{'handler_select'}, BLOCK_UNTIL_CHILD );
    } while ( $r != FLAG_PACKET_FINISHED_CHILDREN );
}

=head1 EXAMPLES

=head2 Data Handler

 use warnings;
 use strict;
 
 use IPC::Fork::Simple;
 
 my $ipc = IPC::Fork::Simple->new();
 my $pid = fork();
 
 if ( $pid ) {
     $ipc->spawn_data_handler();
     waitpid( $pid, 0 );
     $ipc->collect_data_from_handler();
     warn length(${$ipc->from_child( $pid, 'test' )});
 } else {
     $ipc->init_child();
     $ipc->to_master( 'test', 'a' x 300 ) || die $!;
 }

=head2 Blocking

 use warnings;
 use strict;
 
 use IPC::Fork::Simple;
 use POSIX ":sys_wait_h";
 
 my $ipc = IPC::Fork::Simple->new();
 
 my $pid = fork();
 die 'stupid fork' unless defined $pid;
 
 if ( $pid ) {
     $ipc->process_child_data(1);
     my @finished = $ipc->finished_children();
     die unless 1 == scalar( $ipc->finished_children() );
     die unless 300 == length(${$ipc->from_child( $pid, 'test' )});
     die unless 300 == length(${$ipc->from_cid( $finished[0], 'test' )});
 } else {
     $ipc->init_child();
     $ipc->to_master( 'test', 'a' x 300 ) || die $!;
 }
 
=head2 Polling

 use warnings;
 use strict;
 
 use IPC::Fork::Simple;
 use POSIX ":sys_wait_h";
 
 my $ipc = IPC::Fork::Simple->new();
 my $pid = fork();
 
 if ( $pid ) {
     while ( !$ipc->finished_children() ) {
         $ipc->process_child_data(0);
         waitpid( -1, WNOHANG );
         sleep(0);
     }
     warn length(${$ipc->from_child( $pid, 'test' )});
 } else {
     $ipc->init_child();
     $ipc->to_master( 'test', 'a' x 300 ) || die $!;
 }

=head2 Data queues

 use warnings;
 use strict;
 
 use IPC::Fork::Simple;
 
 my $ipc = IPC::Fork::Simple->new();
 
 my $pid = fork();
 die 'stupid fork' unless defined $pid;
 
 if ( $pid ) {
     $ipc->process_child_data(1);
     die unless 300 == length(${$ipc->pop_from_child( $pid, 'test' )});
     die unless 301 == length(${$ipc->pop_from_child( $pid, 'test' )});
     die unless 302 == length(${$ipc->pop_from_child( $pid, 'test' )});
 } else {
     $ipc->init_child();
     $ipc->push_to_master( 'test', 'a' x 300 ) || die $!;
     $ipc->push_to_master( 'test', 'b' x 301 ) || die $!;
     $ipc->push_to_master( 'test', 'c' x 302 ) || die $!;
 }

=head2 Bi-directional communication

 use warnings;
 use strict;
 
 use IPC::Fork::Simple qw/:block_flags/;
 
 my $ipc = IPC::Fork::Simple->new();
 my $master_pid = $$;
 my $pid = fork();
 die 'stupid fork' unless defined $pid;
 
 if ( $pid ) {
     $ipc->process_child_data(BLOCK_UNTIL_DATA);
     my $child_connection_data = $ipc->from_child( $pid, 'connection_info' );
     my $ipc2 = IPC::Fork::Simple->new_child( ${$child_connection_data} ) || die;
     $ipc2->to_master( 'master_test', 'a' x 300 );
 } else {
     $ipc->init_child();
     my $ipc2 = IPC::Fork::Simple->new();
     $ipc->to_master( 'connection_info', $ipc2->get_connection_info() ) || die $!;
     $ipc2->process_child_data(BLOCK_UNTIL_DATA);
     die unless length( ${$ipc2->from_child( $master_pid, 'master_test' )} ) == 300;
 }

=head2 Bi-directional communication with data handlers

 use warnings;
 use strict;
 
 use IPC::Fork::Simple qw/:block_flags/;
 
 my $ipc = IPC::Fork::Simple->new();
 my $master_pid = $$;
 my $pid = fork();
 die 'stupid fork' unless defined $pid;
 
 if ( $pid ) {
     $ipc->spawn_data_handler();
     my $child_connection_data;
 
     $ipc->collect_data_from_handler(1, BLOCK_UNTIL_DATA);
     $child_connection_data = $ipc->from_child( $pid, 'connection_info' )
 
     my $ipc2 = IPC::Fork::Simple->new_child( ${$child_connection_data} ) || die;
     $ipc2->to_master( 'master_test', 'a' x 300 );
 } else {
     $ipc->init_child();
 
     my $ipc2 = IPC::Fork::Simple->new();
     $ipc2->spawn_data_handler();
     $ipc->to_master( 'connection_info', $ipc2->get_connection_info() ) || die $!;
     my $test;
 
     do {
         sleep(0);
         $ipc2->collect_data_from_handler(1);
         $test = $ipc2->from_child( $master_pid, 'master_test' )
     } until ( $test );
 
     die unless length( ${$test} ) == 300;
 }
 
=head2 Further examples

Further examples can be found in the t/functional directory supplied with the
distribution.

=head1 NOTES

=head2 Zombies

Child processes are not reaped automatically by this module, so the caller
will need to call wait (or similar function) as usual to reap child processes.

=head2 Security

This module creates a TCP listen socket on a random high-numbered port on
127.0.0.1. If a malicious program connects to that socket, it could cause the
master process to hang waiting for that socket to disconnect. This module takes
basic steps to insure this does not happen (connecting clients must present the
correct 32-bit key within 30 seconds of connecting, but this is only checked
when another client connects), but this is not fool-proof.

=head2 Invalid connections

If someone connects, but does not send the proper data, it is possible that we
could return from L<process_child_data> with FLAG_PACKET_CHILD_DISCONNECTED
but without updating any data or the finished child list. I believe all possible
causes of this have been resolved, but developers should still be aware of this
potential issue.

Callers checking for a return value of FLAG_PACKET_CHILD_DISCONNECTED should
therefor also check L<finished_children> to make sure a real child actually
finished.

=head2 Unit tests

The module currently lacks unit tests but does have a collection of functional
tests. During "make test" these functional tests are not run, as they can be
system intensive. Ideally, unit tests will be developed for this purpose, but
until then they can be run by hand. They can be found in the t/functional
directory as part of the distribution.

=head1 TO DO

Merge the internal finished_children hash with the internal child_info hash.
The child_info hash already holds most of the data, a flag to determine
whether or not that child is still connected would be simple to add, but
removing the quick lookups against finished_children would make the code more
verbose in places. Merging the two hashes would also reduce data duplication
of the symbolic name.

Add unit tests, or make functional tests run as part of "make test".

=head1 CHANGES

=head2 1.47 - 20110622, jeagle

Implement basic integrity checks to prevent unexpected connections from
interfering with normal operation.

Add L<partition_list> function, L<get_waitable_fds> method.

=head2 1.46 - 20100830, jeagle

Version bump and repackage for CPAN.

=head2 1.45 - 20100623, jeagle

Clean and prepare for export to CPAN.

Version bump to synchronize source repository version with module version.

=head2 0.8 - 20100506, jeagle

Replace MSG_NOSIGNAL with an ignored SIGPIPE, because we can't rely on
MSG_NOSIGNAL to be defined everywhere.

=head2 0.7 - 20100427, jeagle

Disable SIGPIPE for failed send()s, returns error instead (to match
documentation/intention).

Correctly process large reads (>64k).

=head2 0.6 - 20100309, phirince

Extra check in pop_from_cid to get rid of undefined value errors.

=head2 0.5 - 20100219, jeagle

Correct layout issues with example documentation.

Clarify the use of wait(2) in determining if a "child" has ended.

=head2 0.4 - 20100219, jeagle

Fix more bugs related to PID size assumptions.

Fix various networking bugs that could cause data loss.

Implement new bi-directional communication abilities.

Implement new data queue types.

Allow processes to identify themselves by a symbolic name, instead of pid (if
not set, defaults to pid).

=head2 0.3 - 20090512, phirince

Fixed bug 2741310 - IPC::Fork::Simple assumed pids are 16 bits instead of 32
bits.

=head2 0.2 - 20090217, jeagle

Fixed a bug with L<process_child_data> returning early when a signal is
received.

=head2 0.1 - 20090130, jeagle

Initial release.

=cut

1;
