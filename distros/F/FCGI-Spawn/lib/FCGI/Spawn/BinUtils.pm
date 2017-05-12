package FCGI::Spawn::BinUtils;

use strict;
use warnings;

# use base 'Exporter';    # FIXME Perl6::Export::Attrs

use English qw/$UID $EUID $GID $EGID/;

use Carp;

# Contains 'setuid' and 'setgid' subs
require POSIX; # No import cause it's too much

# our @EXPORT_OK = qw/init_pid_callouts_share sig_handle re_open_log get_fork_rv
#     get_shared_scalar
#     /;

my $ipc;

sub _init_ipc {
    my $mm_scratch = shift;
    unless ( defined $ipc ) {
        eval {
            require IPC::MM;
            1;
        } or die "IPC::MM: $@ $!";
        my $rv = $ipc = IPC::MM::mm_create( map { $mm_scratch->{$_} }
                mm_size => 'mm_file', );
        $rv or die "IPC::MM init: $@ $!";
        my $uid = $mm_scratch->{'uid'};
        $rv = not IPC::MM::mm_permission( $ipc, '0600', $uid, -1 );
        $rv or die "SHM unpermitted: $!";    # Return value invert
    }
}

sub _make_shared {
    my ( $type, $mm_scratch ) = @_;
    &_init_ipc($mm_scratch);
    my $method    = "mm_make_$type";
    my $tie_class = 'IPC::MM::' . ucfirst $type;
    my $ipc_var   = $IPC::MM::{$method}->($ipc);
    my $shared_var;
    $shared_var = {} if $type eq 'hash';
    tie( ( $type eq 'hash' ) ? %$shared_var : $shared_var,
        $tie_class, $ipc_var );
    return $shared_var;
}

sub init_pid_callouts_share {
    &_make_shared( 'hash' => shift, );
}

sub sig_handle {
    my ( $sig, $pid ) = @_;
    return sub {
        $sig = ( $sig eq 'INT' ) ? 'TERM' : $sig;
        kill $sig, $pid;
    };
}

sub re_open_log {
    my $log_file = shift;
    close STDERR if defined fileno STDERR;
    close STDOUT if defined fileno STDOUT;
    open( STDERR, ">>", $log_file ) or die "Opening log $log_file: $!";
    open( STDOUT, ">>", $log_file ) or die "Opening log $log_file: $!";
    open STDIN, "<", '/dev/null' or die "Can't read /dev/null: $!";
}

# Function
# Sets user and group of the current process
# Takes     :   Int user id, Int group id
# Requires  :   English, Carp modules
# Changes   :   user and group of the current process
# Throws    :   If user and group of the current process were not set
# Returns   :   n/a
sub set_uid_gid {
    my ( $user_id => $group_id ) = @_;

    # Set group id
    _set_group_id($group_id);
    croak("Group id $group_id was not set!")
        unless ( $GID == $group_id )
        and ( $EGID == $group_id );

    # Set user id
    _set_user_id($user_id);
    croak("User id $user_id was not set!")
        unless ( $UID == $user_id )
        and ( $> == $user_id );

}

# Function
# Sets user and group of the current process
# Takes     :   n/a
# Requires  :   POSIX module
# Changes   :   user of the current process
# Returns   :   n/a
sub _set_user_id {
    my $user_id = shift;

    POSIX::setuid($user_id);
    $UID  = $user_id;
    $EUID = $user_id;
}

# Function
# Sets group of the current process
# Takes     :   n/a
# Requires  :   POSIX module
# Changes   :   group of the current process
# Returns   :   n/a
sub _set_group_id {
    my $group_id = shift;

    POSIX::setgid($group_id);
    $GID  = $group_id;
    $EGID = "$group_id $group_id";
}

# These below are for tests

sub get_shared_scalar {
    eval {
        require File::Temp;
        1;
    } or die "File::Temp: $@ $!";
    my $rv = _make_shared(
        'scalar' => {
            mm_file => File::Temp->new(),
            mm_size => 65535,
            'uid'   => $UID,
        }
    );
}

sub get_fork_rv {
    my $cref = shift;
    my $rv   = &get_shared_scalar();
}

1;

__END__

=pod

=head1 SUBROUTINES/METHODS

=head2 C<set_uid_gid( Int $user_id => Int $group_id );>

Sets user id and group id of the current process. Throws if they were not
set.

Returns: n/a

=cut

