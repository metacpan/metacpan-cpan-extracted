package EV::Etcd;
use strict;
use warnings;

our $VERSION = '0.04';

use EV ();
require XSLoader;
XSLoader::load('EV::Etcd', $VERSION);

# Save reference to XS txn before we override it
my $_xs_txn = \&txn;

# Wrapper for txn to accept named parameters
no warnings 'redefine';
*txn = sub {
    my $self = shift;

    # If called with positional args (4 args: compare, success, failure, callback), pass through
    if (@_ == 4 && ref($_[0]) eq 'ARRAY') {
        return $_xs_txn->($self, @_);
    }

    # Extract callback if passed as last bare coderef
    my $callback;
    if (@_ && ref($_[-1]) eq 'CODE') {
        $callback = pop;
    }

    my %args = @_;
    $callback //= $args{callback};

    # Extract arrays, default to empty
    my $compare = $args{compare} // [];
    my $success = $args{success} // [];
    my $failure = $args{failure} // [];

    return $_xs_txn->($self, $compare, $success, $failure, $callback);
};
use warnings 'redefine';

1;

__END__

=head1 NAME

EV::Etcd - Async etcd v3 client using native gRPC and EV/libev

=head1 SYNOPSIS

    use EV;
    use EV::Etcd;

    my $client = EV::Etcd->new(
        endpoints => ['127.0.0.1:2379'],
    );

    # Async put
    $client->put('/my/key', 'value', sub {
        my ($resp, $err) = @_;
        die $err->{message} if $err;
        say "Put succeeded, revision: $resp->{header}{revision}";
    });

    # Async get
    $client->get('/my/key', sub {
        my ($resp, $err) = @_;
        die $err->{message} if $err;
        say "Value: $resp->{kvs}[0]{value}";
    });

    # Watch
    $client->watch('/my/key', sub {
        my ($resp, $err) = @_;
        for my $event (@{$resp->{events}}) {
            say "Event: $event->{type} on $event->{kv}{key}";
        }
    });

    EV::run;

=head1 DESCRIPTION

EV::Etcd provides a high-performance async client for etcd v3 using native
gRPC Core C API integrated with the EV event loop.

=head1 METHODS

=head2 new

    my $client = EV::Etcd->new(%options);

Options:

=over 4

=item endpoints

ArrayRef of etcd endpoints (host:port).

=item timeout

RPC timeout in seconds. Default is 30 seconds. Minimum value is 1 second.

=item max_retries

Maximum number of reconnection attempts for streaming operations (watch,
lease_keepalive, election_observe) after a connection failure. Default is 3.
Set to 0 to disable automatic reconnection.

=item health_interval

Interval in seconds for health monitoring. Default is 0 (disabled).
When enabled, the client periodically checks the gRPC channel connectivity
state and calls the on_health_change callback when the connection state changes.

=item on_health_change

Callback called when the connection health status changes. Receives two
arguments: a boolean indicating health status (1=healthy, 0=unhealthy) and
the current endpoint string.

    my $client = EV::Etcd->new(
        endpoints => ['127.0.0.1:2379'],
        health_interval => 5,
        on_health_change => sub {
            my ($is_healthy, $endpoint) = @_;
            warn $is_healthy ? "Connected to $endpoint" : "Disconnected from $endpoint";
        },
    );

=item auth_token

Pre-set authentication token. Use this to create an authenticated client
without calling authenticate() first. Useful when you already have a valid
token from a previous session.

    my $client = EV::Etcd->new(
        endpoints => ['127.0.0.1:2379'],
        auth_token => $saved_token,
    );

=back

=head1 ERROR HANDLING

Errors are returned as hash references with the following structure:

    {
        code      => 14,              # gRPC status code (integer)
        status    => "UNAVAILABLE",   # gRPC status name (string)
        message   => "Connection refused",  # Error message
        source    => "get",           # Which operation failed
        retryable => 1,               # Whether the error is retryable
    }

The C<retryable> field indicates whether the error is transient (status codes:
UNAVAILABLE, RESOURCE_EXHAUSTED, ABORTED, INTERNAL, DEADLINE_EXCEEDED).
Streaming operations (watch, keepalive, observe) automatically reconnect
on transient failures according to the C<max_retries> configuration.
Unary RPCs (get, put, delete, etc.) do not retry automatically; use the
C<retryable> field to implement application-level retry logic.

=head2 put

    $client->put($key, $value, $callback);
    $client->put($key, $value, \%opts, $callback);

Put a key-value pair into etcd.

Options:

=over 4

=item lease

Lease ID to associate with the key.

=item prev_kv

If true, returns the previous key-value pair in the response.

=item ignore_value

If true, updates the lease without changing the value.

=item ignore_lease

If true, updates the value without changing the lease.

=back

=head2 get

    $client->get($key, $callback);
    $client->get($key, \%opts, $callback);

Get key(s) from etcd.

Options:

=over 4

=item prefix

If true, returns all keys with the given prefix.

=item range_end

End of the key range to query.

=item limit

Maximum number of keys to return.

=item revision

Get keys at a specific revision.

=item keys_only

If true, returns only keys without values.

=item count_only

If true, returns only the count of keys.

=item sort_order

Sort order: "ascend" or "descend".

=item sort_target

What to sort by: "key", "version", "create", "mod", or "value".

=item serializable

If true, use serializable (faster but possibly stale) reads.

=item min_mod_revision, max_mod_revision

Filter keys by modification revision.

=item min_create_revision, max_create_revision

Filter keys by creation revision.

=back

=head2 delete

    $client->delete($key, $callback);
    $client->delete($key, \%opts, $callback);

Delete key(s) from etcd.

Options:

=over 4

=item prefix

If true, deletes all keys with the given prefix.

=item range_end

End of the key range to delete.

=item prev_kv

If true, returns the deleted key-value pairs in the response.

=back

=head2 watch

    my $watch = $client->watch($key, $callback);
    my $watch = $client->watch($key, \%opts, $callback);

Create a watch on a key or key range. Returns an EV::Etcd::Watch object.

The callback is called with C<($response, $error)> for each watch event.
The response contains an C<events> array with the watch events.

Options:

=over 4

=item prefix

If true, watches all keys with the given prefix.

=item range_end

End of the key range to watch.

=item start_revision

Revision to start watching from. If not specified, watches from the
current revision. Use this to resume watching after a reconnect.

=item prev_kv

If true, the response will include the previous key-value pair for
UPDATE and DELETE events.

=item progress_notify

If true, the server will periodically send progress notifications
even when there are no events, allowing the client to know the
current revision.

=item watch_id

Optional explicit watch ID. If not specified, the server assigns one.

=item auto_reconnect

If true, the watch will automatically reconnect after a connection failure,
resuming from the last seen revision. Default is true. This is useful for
long-running watches that should survive network interruptions.

    my $watch = $client->watch('/my/key', {
        auto_reconnect => 1,
        progress_notify => 1,  # Helps track revision even during inactivity
    }, sub {
        my ($event, $err) = @_;
        if ($err) {
            warn "Watch error: $err->{message}";
            return;
        }
        # Process events...
    });

=back

=head2 EV::Etcd::Watch Methods

=head3 cancel

    $watch->cancel($callback);

Cancel the watch. The callback receives C<($response, $error)> when
cancellation is complete. The response is an empty hash reference on success.

    $watch->cancel(sub {
        my ($resp, $err) = @_;
        if ($err) {
            warn "Cancel failed: $err->{message}";
        } else {
            print "Watch cancelled\n";
        }
    });

=head2 lease_grant

    $client->lease_grant($ttl, $callback);

Grant a lease with the specified TTL (time-to-live) in seconds.

The callback receives C<($response, $error)> where response contains:

=over 4

=item id

The lease ID.

=item ttl

The actual TTL granted by the server.

=back

=head2 lease_revoke

    $client->lease_revoke($lease_id, $callback);

Revoke a lease. All keys attached to the lease will be deleted.

=head2 lease_keepalive

    $client->lease_keepalive($lease_id, $callback);

Keep a lease alive. Call this periodically to prevent the lease from expiring.

=head2 lease_time_to_live

    $client->lease_time_to_live($lease_id, $callback);
    $client->lease_time_to_live($lease_id, \%opts, $callback);

Get the remaining TTL of a lease.

The callback receives C<($response, $error)> where response contains:

=over 4

=item id

The lease ID.

=item ttl

Remaining TTL in seconds. Returns -1 if the lease has expired.

=item granted_ttl

The original TTL granted when the lease was created.

=item keys

Array of keys attached to this lease (only if C<keys> option is true).

=back

Options:

=over 4

=item keys

If true, also return the list of keys attached to this lease.

=back

=head2 lease_leases

    $client->lease_leases($callback);

List all active leases.

The callback receives C<($response, $error)> where response contains:

=over 4

=item leases

Array of lease objects, each containing:

=over 4

=item id

The lease ID.

=back

=back

=head2 compact

    $client->compact($revision, $callback);
    $client->compact($revision, \%opts, $callback);

Compact the etcd key-value store up to the given revision. All keys
with revisions less than the compaction revision will be removed.

B<Warning>: This operation is irreversible. After compaction, you cannot
retrieve data from revisions before the compacted revision.

Options:

=over 4

=item physical

If true, the RPC will wait until the compaction is physically applied
to the local database such that compacted entries are totally removed
from the backend database. Default is false.

=back

=head2 status

    $client->status($callback);

Get the status of the etcd cluster member this client is connected to.
Useful for health checks and cluster monitoring.

The callback receives C<($response, $error)> where response contains:

=over 4

=item version

The etcd server version.

=item db_size

The size of the backend database in bytes.

=item leader

The member ID of the cluster leader.

=item raft_index

The current raft index of the member.

=item raft_term

The current raft term of the cluster.

=item raft_applied_index

The raft applied index of the member.

=item db_size_in_use

The actual size of the database in use (after compaction).

=item is_learner

True if this member is a learner (non-voting member).

=item errors

Array of any errors on this member (if any).

=back

=head1 LOCK SERVICE

EV::Etcd provides distributed locking through the etcd Lock service.
Locks are tied to leases - when the lease expires or is revoked, the lock
is automatically released.

=head2 lock

    $client->lock($name, $lease_id, $callback);

Acquire a distributed lock.

Arguments:

=over 4

=item name

The name (identifier) of the lock to acquire. This is a byte string that
identifies the resource being locked. Multiple clients attempting to lock
the same name will block until the lock is available.

=item lease_id

The ID of a lease to attach to the lock. The lock will be held for the
duration of the lease. If the lease expires or is revoked, the lock is
automatically released. You must first create a lease with C<lease_grant>
and optionally keep it alive with C<lease_keepalive>.

=item callback

Called with C<($response, $error)> when the lock is acquired (or fails).

=back

The response contains:

=over 4

=item key

The key that holds the lock. This key is used to unlock the lock and
should be stored by the caller. The key is unique to this lock holder
and contains the lock name as a prefix.

=item header

Standard response header with cluster_id, member_id, revision, and raft_term.

=back

Example:

    # First, create a lease for the lock
    $client->lease_grant(30, sub {
        my ($lease_resp, $err) = @_;
        die $err->{message} if $err;

        my $lease_id = $lease_resp->{id};

        # Now acquire the lock
        $client->lock("my-resource", $lease_id, sub {
            my ($lock_resp, $err) = @_;
            die $err->{message} if $err;

            my $lock_key = $lock_resp->{key};
            print "Lock acquired with key: $lock_key\n";

            # ... do protected work ...

            # Release the lock when done
            $client->unlock($lock_key, sub {
                my ($unlock_resp, $err) = @_;
                warn "Unlock failed: $err->{message}" if $err;
            });
        });
    });

=head2 unlock

    $client->unlock($key, $callback);

Release a distributed lock.

Arguments:

=over 4

=item key

The lock key returned from a successful C<lock> call. This is the unique
key that was created to hold the lock ownership.

=item callback

Called with C<($response, $error)> when the unlock completes.

=back

The response contains:

=over 4

=item header

Standard response header with cluster_id, member_id, revision, and raft_term.

=back

B<Note>: You can also release a lock by revoking its associated lease with
C<lease_revoke>. This is useful if you want to release all resources
associated with a lease at once.

=head1 AUTHENTICATION SERVICE

EV::Etcd provides full support for etcd's authentication and authorization
system. Authentication uses username/password credentials, and authorization
is based on roles with key-range permissions.

=head2 authenticate

    $client->authenticate($username, $password, $callback);

Authenticate with etcd using username and password. On success, the client
automatically stores the auth token and uses it for subsequent requests.

Arguments:

=over 4

=item username

The username to authenticate as.

=item password

The password for the user.

=item callback

Called with C<($response, $error)> when authentication completes.

=back

The response contains:

=over 4

=item token

The authentication token (also automatically stored in the client).

=item header

Standard response header.

=back

Example:

    $client->authenticate('admin', 'secret', sub {
        my ($resp, $err) = @_;
        if ($err) {
            die "Authentication failed: $err->{message}";
        }
        say "Authenticated successfully";
        # Client now automatically uses the token for all requests
    });

=head2 auth_enable

    $client->auth_enable($callback);

Enable authentication on the etcd cluster.

B<Warning>: Before enabling auth, you must create at least one user with
the root role, otherwise you will be locked out of the cluster.

Example:

    # First create root user
    $client->user_add('root', 'rootpassword', sub {
        my ($resp, $err) = @_;
        die $err->{message} if $err;

        $client->user_grant_role('root', 'root', sub {
            my ($resp, $err) = @_;
            die $err->{message} if $err;

            # Now safe to enable auth
            $client->auth_enable(sub {
                my ($resp, $err) = @_;
                say "Authentication enabled" unless $err;
            });
        });
    });

=head2 auth_disable

    $client->auth_disable($callback);

Disable authentication on the etcd cluster. Requires root privileges.

=head2 User Management

=head3 user_add

    $client->user_add($username, $password, $callback);

Create a new user.

Arguments:

=over 4

=item username

The username for the new user.

=item password

The password for the new user.

=item callback

Called with C<($response, $error)> when complete.

=back

=head3 user_delete

    $client->user_delete($username, $callback);

Delete a user.

=head3 user_change_password

    $client->user_change_password($username, $password, $callback);

Change a user's password.

=head3 user_get

    $client->user_get($username, $callback);

Get information about a user.

The response contains:

=over 4

=item roles

Array of role names assigned to the user.

=back

Example:

    $client->user_get('myuser', sub {
        my ($resp, $err) = @_;
        say "User has roles: @{$resp->{roles}}";
    });

=head3 user_list

    $client->user_list($callback);

List all users.

The response contains:

=over 4

=item users

Array of usernames.

=back

=head3 user_grant_role

    $client->user_grant_role($username, $role_name, $callback);

Grant a role to a user.

Example:

    $client->user_grant_role('myuser', 'readwrite', sub {
        my ($resp, $err) = @_;
        say "Role granted" unless $err;
    });

=head3 user_revoke_role

    $client->user_revoke_role($username, $role_name, $callback);

Revoke a role from a user.

=head2 Role Management

=head3 role_add

    $client->role_add($role_name, $callback);

Create a new role.

Example:

    $client->role_add('readonly', sub {
        my ($resp, $err) = @_;
        say "Role created" unless $err;
    });

=head3 role_delete

    $client->role_delete($role_name, $callback);

Delete a role.

=head3 role_get

    $client->role_get($role_name, $callback);

Get information about a role, including its permissions.

The response contains:

=over 4

=item perm

Array of permission objects, each containing:

=over 4

=item perm_type

Permission type: "READ", "WRITE", or "READWRITE".

=item key

The key or key prefix this permission applies to.

=item range_end

The end of the key range (if applicable).

=back

=back

Example:

    $client->role_get('myrole', sub {
        my ($resp, $err) = @_;
        for my $perm (@{$resp->{perm}}) {
            say "Permission: $perm->{perm_type} on $perm->{key}";
        }
    });

=head3 role_list

    $client->role_list($callback);

List all roles.

The response contains:

=over 4

=item roles

Array of role names.

=back

=head3 role_grant_permission

    $client->role_grant_permission($role_name, $perm_type, $key, $range_end, $callback);

Grant a permission to a role.

Arguments:

=over 4

=item role_name

The role to grant the permission to.

=item perm_type

The permission type: "READ", "WRITE", or "READWRITE".

=item key

The key or key prefix to grant access to.

=item range_end

The end of the key range. Use C<undef> for a single key, or use the
special value C<"\x00"> after the last byte of the prefix to match all
keys with that prefix.

=item callback

Called with C<($response, $error)> when complete.

=back

Example:

    # Grant read access to a single key
    $client->role_grant_permission('readonly', 'READ', '/config/setting', undef, sub {
        my ($resp, $err) = @_;
        say "Permission granted" unless $err;
    });

    # Grant read/write access to all keys under /app/
    # Range end is /app0 (the byte after / is 0)
    $client->role_grant_permission('readwrite', 'READWRITE', '/app/', '/app0', sub {
        my ($resp, $err) = @_;
        say "Permission granted" unless $err;
    });

=head3 role_revoke_permission

    $client->role_revoke_permission($role_name, $key, $range_end, $callback);

Revoke a permission from a role.

Arguments:

=over 4

=item role_name

The role to revoke the permission from.

=item key

The key or key prefix of the permission to revoke.

=item range_end

The end of the key range of the permission to revoke.

=item callback

Called with C<($response, $error)> when complete.

=back

=head2 Complete Authentication Example

    use EV;
    use EV::Etcd;

    my $client = EV::Etcd->new(endpoints => ['127.0.0.1:2379']);

    # Setup authentication (run once, as root)
    sub setup_auth {
        # Create a role with permissions
        $client->role_add('app-role', sub {
            my ($resp, $err) = @_;

            # Grant read/write on /app/ prefix
            $client->role_grant_permission('app-role', 'READWRITE', '/app/', '/app0', sub {
                my ($resp, $err) = @_;

                # Create user
                $client->user_add('appuser', 'apppassword', sub {
                    my ($resp, $err) = @_;

                    # Assign role to user
                    $client->user_grant_role('appuser', 'app-role', sub {
                        my ($resp, $err) = @_;
                        say "Auth setup complete";
                        EV::break;
                    });
                });
            });
        });
    }

    # Normal usage with authentication
    sub use_with_auth {
        $client->authenticate('appuser', 'apppassword', sub {
            my ($resp, $err) = @_;
            die "Auth failed: $err->{message}" if $err;

            # Now all operations use the auth token
            $client->put('/app/key', 'value', sub {
                my ($resp, $err) = @_;
                say "Put succeeded" unless $err;
                EV::break;
            });
        });
    }

    use_with_auth();
    EV::run;

=head1 MAINTENANCE SERVICE

EV::Etcd provides access to etcd's maintenance operations for cluster
administration and monitoring.

=head2 alarm

    $client->alarm($action, $callback);
    $client->alarm($action, \%opts, $callback);

Get, activate, or deactivate alarms on etcd cluster members.

Arguments:

=over 4

=item action

The alarm action to perform. Must be one of:

=over 4

=item GET

List all active alarms.

=item ACTIVATE

Activate an alarm on a member.

=item DEACTIVATE

Deactivate an alarm on a member.

=back

=item callback

Called with C<($response, $error)> when the operation completes.

=back

Options:

=over 4

=item member_id

The member ID to operate on. Required for ACTIVATE/DEACTIVATE on a
specific member. Use 0 for all members.

=item alarm

The alarm type. Can be "NOSPACE" (storage quota exceeded) or "CORRUPT"
(data corruption detected). Default is "NONE" which means all alarms.

=back

The response contains:

=over 4

=item alarms

Array of alarm objects, each containing:

=over 4

=item member_id

The member ID where the alarm is active.

=item alarm

The alarm type as an integer.

=item alarm_type

The alarm type as a string ("NONE", "NOSPACE", or "CORRUPT").

=back

=item header

Standard response header.

=back

Example:

    # List all alarms
    $client->alarm('GET', sub {
        my ($resp, $err) = @_;
        for my $alarm (@{$resp->{alarms}}) {
            warn "Alarm on member $alarm->{member_id}: $alarm->{alarm_type}";
        }
    });

    # Deactivate NOSPACE alarm on all members
    $client->alarm('DEACTIVATE', { alarm => 'NOSPACE' }, sub {
        my ($resp, $err) = @_;
        warn "Alarm deactivated" unless $err;
    });

=head2 defragment

    $client->defragment($callback);

Defragment the storage backend on the etcd member this client is connected to.
This reclaims storage space by removing deleted keys and compacted revisions.

B<Warning>: Defragmentation is a blocking operation and may cause latency
spikes. Run it during maintenance windows.

The response contains:

=over 4

=item header

Standard response header.

=back

Example:

    $client->defragment(sub {
        my ($resp, $err) = @_;
        if ($err) {
            warn "Defragment failed: $err->{message}";
        } else {
            say "Defragmentation complete";
        }
    });

=head2 hash_kv

    $client->hash_kv($callback);
    $client->hash_kv($revision, $callback);

Compute the hash of the KV store up to the given revision. Useful for
verifying data consistency across cluster members.

Arguments:

=over 4

=item revision (optional)

The revision to hash up to. If not specified, uses the current revision.

=item callback

Called with C<($response, $error)> when the operation completes.

=back

The response contains:

=over 4

=item hash

The hash value of the KV store.

=item compact_revision

The compaction revision of the KV store.

=item header

Standard response header.

=back

Example:

    $client->hash_kv(sub {
        my ($resp, $err) = @_;
        say "KV hash: $resp->{hash}";
        say "Compact revision: $resp->{compact_revision}";
    });

=head2 move_leader

    $client->move_leader($target_id, $callback);

Transfer leadership to another member. Only the current leader can
transfer leadership.

Arguments:

=over 4

=item target_id

The member ID of the new leader. Must be a voting member (not a learner).

=item callback

Called with C<($response, $error)> when the operation completes.

=back

The response contains:

=over 4

=item header

Standard response header.

=back

Example:

    # Get current cluster status to find member IDs
    $client->member_list(sub {
        my ($resp, $err) = @_;
        my $target = $resp->{members}[1]{id};  # Pick a different member

        $client->move_leader($target, sub {
            my ($resp, $err) = @_;
            if ($err) {
                warn "Failed to move leader: $err->{message}";
            } else {
                say "Leadership transferred";
            }
        });
    });

=head2 auth_status

    $client->auth_status($callback);

Check whether authentication is enabled on the etcd cluster.

The response contains:

=over 4

=item enabled

Boolean indicating whether authentication is enabled.

=item auth_revision

The current revision of the auth store.

=item header

Standard response header.

=back

Example:

    $client->auth_status(sub {
        my ($resp, $err) = @_;
        if ($resp->{enabled}) {
            say "Authentication is enabled (revision: $resp->{auth_revision})";
        } else {
            say "Authentication is disabled";
        }
    });

=head1 ELECTION SERVICE

EV::Etcd provides leader election support through the etcd Election service.
Elections use leases to ensure that leadership is automatically released
when a leader fails.

=head2 election_campaign

    $client->election_campaign($name, $lease_id, $value, $callback);

Campaign for leadership of an election.

This call blocks until the caller is elected as leader. Once elected, the
caller should periodically keep the lease alive to maintain leadership.

Arguments:

=over 4

=item name

The name of the election to campaign in.

=item lease_id

The lease ID to use for the campaign. The leadership is held for the
duration of this lease.

=item value

The value to set when elected. Other clients can read this value to
identify the current leader.

=item callback

Called with C<($response, $error)> when elected (or on failure).

=back

The response contains:

=over 4

=item leader

A hash containing the leader key information:

=over 4

=item name

The election name.

=item key

The key in etcd that holds the leadership (use for proclaim/resign).

=item rev

The creation revision of the leader key.

=item lease

The lease ID attached to the leadership.

=back

=item header

Standard response header.

=back

Example:

    $client->lease_grant(30, sub {
        my ($resp, $err) = @_;
        my $lease_id = $resp->{id};

        $client->election_campaign("my-election", $lease_id, "leader-1", sub {
            my ($resp, $err) = @_;
            if ($err) {
                warn "Failed to become leader: $err->{message}";
                return;
            }
            say "Elected as leader!";
            my $leader_key = $resp->{leader};
            # Store $leader_key for later use with proclaim/resign
        });
    });

=head2 election_leader

    $client->election_leader($name, $callback);

Get the current leader of an election.

Arguments:

=over 4

=item name

The name of the election.

=item callback

Called with C<($response, $error)> when complete.

=back

The response contains:

=over 4

=item kv

The key-value pair of the current leader, containing the leader's value.

=item header

Standard response header.

=back

Returns an error if there is no current leader.

Example:

    $client->election_leader("my-election", sub {
        my ($resp, $err) = @_;
        if ($err) {
            warn "No leader: $err->{message}";
        } else {
            say "Current leader value: $resp->{kv}{value}";
        }
    });

=head2 election_proclaim

    $client->election_proclaim($leader_key, $value, $callback);

Update the leader's value. Only the current leader can proclaim.

Arguments:

=over 4

=item leader_key

The leader key hash returned from C<election_campaign>.

=item value

The new value to announce.

=item callback

Called with C<($response, $error)> when complete.

=back

Example:

    $client->election_proclaim($leader_key, "new-value", sub {
        my ($resp, $err) = @_;
        if ($err) {
            warn "Proclaim failed: $err->{message}";
        }
    });

=head2 election_resign

    $client->election_resign($leader_key, $callback);

Voluntarily give up leadership.

Arguments:

=over 4

=item leader_key

The leader key hash returned from C<election_campaign>.

=item callback

Called with C<($response, $error)> when complete.

=back

Example:

    $client->election_resign($leader_key, sub {
        my ($resp, $err) = @_;
        say "Resigned from leadership" unless $err;
    });

=head2 election_observe

    $client->election_observe($name, $callback);
    $client->election_observe($name, \%opts, $callback);

Observe leader changes for an election. This creates a streaming connection
that receives notifications whenever the leader changes.

Arguments:

=over 4

=item name

The name of the election to observe.

=item callback

Called with C<($response, $error)> for each leader change.

=back

Options:

=over 4

=item auto_reconnect

If true, automatically reconnect after connection failures. Default is true.

=back

The response contains:

=over 4

=item kv

The key-value pair of the current leader.

=item header

Standard response header.

=back

Example:

    $client->election_observe("my-election", sub {
        my ($resp, $err) = @_;
        if ($err) {
            warn "Observe error: $err->{message}";
            return;
        }
        say "Leader changed: $resp->{kv}{value}";
    });

=head1 CLUSTER SERVICE

EV::Etcd provides cluster membership management through the Cluster service.

=head2 member_list

    $client->member_list($callback);

List all members in the etcd cluster.

The response contains:

=over 4

=item members

Array of member objects, each containing:

=over 4

=item id

The member ID.

=item name

The member name.

=item peer_urls

Array of peer URLs for cluster communication.

=item client_urls

Array of client URLs for client requests.

=item is_learner

Boolean indicating if the member is a learner.

=back

=item header

Standard response header.

=back

Example:

    $client->member_list(sub {
        my ($resp, $err) = @_;
        for my $member (@{$resp->{members}}) {
            say "Member $member->{name} (ID: $member->{id})";
            say "  Client URLs: @{$member->{client_urls}}";
        }
    });

=head2 member_add

    $client->member_add(\@peer_urls, $callback);
    $client->member_add(\@peer_urls, \%opts, $callback);

Add a new member to the cluster.

Arguments:

=over 4

=item peer_urls

Array of peer URLs for the new member.

=item callback

Called with C<($response, $error)> when complete.

=back

Options:

=over 4

=item is_learner

If true, add the member as a non-voting learner.

=back

=head2 member_remove

    $client->member_remove($member_id, $callback);

Remove a member from the cluster.

=head2 member_update

    $client->member_update($member_id, \@peer_urls, $callback);

Update a member's peer URLs.

=head2 member_promote

    $client->member_promote($member_id, $callback);

Promote a learner member to a voting member.

=head1 TRANSACTIONS

EV::Etcd supports atomic transactions with compare-and-swap semantics.

=head2 txn

    $client->txn(
        compare => \@compare_ops,
        success => \@success_ops,
        failure => \@failure_ops,
        callback => $callback,
    );

    # Or positional form:
    $client->txn(\@compare, \@success, \@failure, $callback);

Execute an atomic transaction. If all compare operations succeed, the
success operations are executed; otherwise, the failure operations are
executed.

Compare operations:

    { key => $key, target => 'value', value => $expected }
    { key => $key, target => 'version', version => $expected }
    { key => $key, target => 'create', create_revision => $expected }
    { key => $key, target => 'mod', mod_revision => $expected }
    { key => $key, target => 'lease', lease => $expected }

Note: Specify exactly one target field (value/version/create_revision/mod_revision/lease)
per compare operation. If multiple are provided, the last one processed takes precedence.

Request operations (for success/failure):

    { request_put => { key => $key, value => $value } }
    { request_delete_range => { key => $key } }
    { request_range => { key => $key } }

Example:

    $client->txn(
        compare => [
            { key => '/counter', target => 'value', value => '0' }
        ],
        success => [
            { request_put => { key => '/counter', value => '1' } }
        ],
        failure => [],
        callback => sub {
            my ($resp, $err) = @_;
            say $resp->{succeeded} ? "Incremented" : "Already changed";
        },
    );

=head1 AUTHOR

Yegor Korablev (egor@cpan.org)

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
