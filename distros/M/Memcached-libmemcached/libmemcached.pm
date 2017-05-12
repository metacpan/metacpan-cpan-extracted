package Memcached::libmemcached;

use warnings;
use strict;

=head1 NAME

Memcached::libmemcached - Thin fast full interface to the libmemcached client API

=head1 VERSION

Version 1.001801 (with libmemcached-1.0.18 embedded)

=cut

our $VERSION = '1.001801'; # also alter in pod above

use Carp;
use base qw(Exporter);

use Memcached::libmemcached::API;
our @EXPORT_OK = (
    libmemcached_functions(),
    libmemcached_constants(),
);
our %EXPORT_TAGS = libmemcached_tags();

require XSLoader;
XSLoader::load('Memcached::libmemcached', $VERSION);

=head1 SYNOPSIS

  use Memcached::libmemcached;

  $memc = memcached_create();

  memcached_server_add($memc, "localhost");

  memcached_set($memc, $key, $value);

  $value = memcached_get($memc, $key);

=head1 DESCRIPTION

Memcached::libmemcached is a very thin, highly efficient, wrapper around the
libmemcached library. It's implemented almost entirely in C.

It gives full access to the rich functionality offered by libmemcached.
libmemcached is fast, light on memory usage, thread safe, and provide full
access to server side methods.

 - Synchronous and Asynchronous support.
 - TCP and Unix Socket protocols.
 - A half dozen or so different hash algorithms.
 - Implementations of the new cas, replace, and append operators.
 - Man pages written up on entire API.
 - Implements both modulo and consistent hashing solutions. 

(Memcached::libmemcached is fairly new and not all the functions in
libmemcached have perl interfaces yet.  It's usually trivial to add functions -
just a few lines in libmemcached.xs, a few lines of documentation, and a few
lines of testing.  Volunteers welcome!)

The libmemcached library documentation (which is bundled with this module)
serves as the primary reference for the functionality.

This documentation provides summary of the functions, along with any issues
specific to this perl interface, and references to the documentation for the
corresponding functions in the underlying library.

For more information on libmemcached, see L<http://docs.libmemcached.org>

=head1 CONVENTIONS

=head2 Terminology

The term "memcache" is used to refer to the C<memcached_st> structure at the
heart of the libmemcached library. We'll use $memc to represent this
structure in perl code. (The libmemcached library documentation uses C<ptr>.)

=head2 Traditional and Object-Oriented

There are two ways to use the functionality offered by this module:

B<*> You can import the functions you want to use and call them explicitly.

B<*> Or, you can use $memc as an object and call most of the functions as methods.
You can do that for any function that takes a $memc (ptr) as its first
argument, which is almost all of them.

Since the primary focus of this module is to be a thin wrapper around
libmemcached, the bulk of this documentation describes the traditional
functional interface.

The object-oriented interface is mainly targeted at modules wishing to subclass
Memcached::libmemcached, such as Cache::Memcached::libmemcached.  For more information
see L</OBJECT-ORIENTED INTERFACE>.

=head2 Function Names and Arguments

The function names in the libmemcached library have exactly the same names in
Memcached::libmemcached.

The function arguments are also the same as the libmemcached library and
documentation, with two exceptions:

B<*> There are no I<length> arguments. Wherever the libmemcached documentation
shows a length argument (input or output) the corresponding argument doesn't
exist in the Perl API because it's not needed.

B<*> Some arguments are optional.

Many libmemcached function arguments are I<output values>: the argument is the
address of the value that the function will modify. For these the perl function
will modify the argument directly if it can. For example, in this call:

    $value = memcached_get($memc, $key, $flags, $rc);

The $flags and $rc arguments are output values that are modified by the
memcached_get() function.

See the L</Type Mapping> section for the fine detail of how each argument type
is handled.

=head2 Return Status

Most of the functions return an integer status value. This is shown as
C<memcached_return> in the libmemcached documentation.

In the perl interface this value is I<not> returned directly. Instead a simple
boolean is returned: true for 'success', defined but false for some
'unsuccessful' conditions like 'not found', and undef for all other cases (i.e., errors).

All the functions documented below return this simple boolean value unless
otherwise indicated.

The actual C<memcached_return> integer value, and corresponding error message,
for the last libmemcached function call can be accessed via the
L</errstr> method.

=head2 Unimplemented Functions

Functions relating to managing lists of servers (memcached_server_push, and
memcached_server_list) have not been implemented because they're not needed and
likely to be deprecated by libmemcached.

Functions relating to iterating through results (memcached_result_*) have not
been implemented yet. They're not a priority because similar functionality is
available via the callbacks. See L</set_callback_coderefs>.

=cut

=head1 EXPORTS

All the public functions in libmemcached are available for import.

All the public constants and enums in libmemcached are also available for import.

Exporter tags are defined for each enum. This allows you to import groups of
constants easily. For example, to enable consistent hashing you could use:

  use Memcached::libmemcached qw(:memcached_behavior :memcached_server_distribution);

  memcached_behavior_set($memc, MEMCACHED_BEHAVIOR_DISTRIBUTION(), MEMCACHED_DISTRIBUTION_CONSISTENT());

The L<Exporter> module allows patterns in the import list, so to import all the
functions, for example, you can use:

  use Memcached::libmemcached qw(/^memcached/);

Refer to L<Memcached::libmemcached::constants> for a full list of the available
constants and the tags they are grouped by. To see a list of all available
functions and constants you can execute:

  perl -MMemcached::libmemcached -le 'print $_ for @Memcached::libmemcached::EXPORT_OK'

=head1 FUNCTIONS

=head2 Functions For Managing Memcaches

=head3 memcached_create

  my $memc = memcached_create();

Creates and returns a 'memcache' that represents the state of
communication with a set of memcached servers.
See L<Memcached::libmemcached::memcached_create>.

=head3 memcached_clone

  my $memc = memcached_clone(undef, undef);

XXX Not currently recommended for use.
See L<Memcached::libmemcached::memcached_create>.

=head3 memcached_free

  memcached_free($memc);

Frees the memory associated with $memc.
After calling it $memc can't be used.
See L<Memcached::libmemcached::memcached_create>.

=head3 memcached_server_count

  $server_count= memcached_server_count($memc);

Returns a count of the number of servers
associated with $memc.
See L<Memcached::libmemcached::memcached_servers>.

=head3 memcached_server_add

=head3 memcached_server_add_with_weight

  memcached_server_add($memc, $hostname, $port);
  memcached_server_add_with_weight($memc, $hostname, $port, $weight);

Adds details of a single memcached server (accessed via TCP/IP) to $memc.
See L<Memcached::libmemcached::memcached_servers>. The default weight is 0.

=head3 memcached_server_add_unix_socket

=head3 memcached_server_add_unix_socket_with_weight

  memcached_server_add_unix_socket($memc, $socket_path);
  memcached_server_add_unix_socket_with_weight($memc, $socket_path);

Adds details of a single memcached server (accessed via a UNIX domain socket) to $memc.
See L<Memcached::libmemcached::memcached_servers>. The default weight is 0.

=head3 memcached_behavior_set

  memcached_behavior_set($memc, $option_key, $option_value);

Changes the value of a particular option.
See L<Memcached::libmemcached::memcached_behavior>.

=head3 memcached_behavior_get

  memcached_behavior_get($memc, $option_key);

Get the value of a particular option.
See L<Memcached::libmemcached::memcached_behavior>.

=head3 memcached_callback_set

  memcached_callback_set($memc, $flag, $value);

Set callback flag value.

The only flag currently supported is C<MEMCACHED_CALLBACK_PREFIX_KEY>.
The $value must be less than MEMCACHED_PREFIX_KEY_MAX_SIZE  (eg 128) bytes.
It also can't be empty L<https://bugs.launchpad.net/libmemcached/+bug/667878>

=head3 memcached_callback_get

  $value = memcached_callback_set($memc, $flag, $return_status);

Get callback flag value. Sets return status in $return_status.
The only flag currently supported is C<MEMCACHED_CALLBACK_PREFIX_KEY>.
Returns undef on error.

=cut


=head2 Functions for Setting Values

See L<Memcached::libmemcached::memcached_set>.

=head3 memcached_set

  memcached_set($memc, $key, $value);
  memcached_set($memc, $key, $value, $expiration, $flags);

Set $value as the value of $key.
$expiration and $flags are both optional and default to 0.

=head3 memcached_add

  memcached_add($memc, $key, $value);
  memcached_add($memc, $key, $value, $expiration, $flags);

Like L</memcached_set> except that an error is returned if $key I<is> already
stored in the server.

=head3 memcached_replace

  memcached_replace($memc, $key, $value);
  memcached_replace($memc, $key, $value, $expiration, $flags);

Like L</memcached_set> except that an error is returned if $key I<is not> already
error is returned.

=head3 memcached_prepend

  memcached_prepend($memc, $key, $value);
  memcached_prepend($memc, $key, $value, $expiration, $flags);

Prepend $value to the value of $key. $key must already exist.
$expiration and $flags are both optional and default to 0.

=head3 memcached_append

  memcached_append($memc, $key, $value);
  memcached_append($memc, $key, $value, $expiration, $flags);

Append $value to the value of $key. $key must already exist.
$expiration and $flags are both optional and default to 0.

=head3 memcached_cas

  memcached_cas($memc, $key, $value, $expiration, $flags, $cas)

Overwrites data in the server stored as $key as long as $cas
still has the same value in the server.

Cas is still buggy in memached.  Turning on support for it in libmemcached is
optional.  Please see memcached_behavior_set() for information on how to do this.

XXX and the memcached_result_cas() function isn't implemented yet
so you can't get the $cas to use.

=cut

=head2 Functions for Fetching Values

See L<Memcached::libmemcached::memcached_get>.

The memcached_fetch_result() and 

=head3 memcached_get

  $value = memcached_get($memc, $key);
  $value = memcached_get($memc, $key, $flags, $rc);

Get and return the value of $key.  Returns undef on error.

Also updates $flags to the value of the flags stored with $value,
and updates $rc with the return code.


=head3 memcached_mget

  memcached_mget($memc, \@keys);
  memcached_mget($memc, \%keys);

Triggers the asynchronous fetching of multiple keys at once. For multiple key
operations it is always faster to use this function. You I<must> then use
memcached_fetch() or memcached_fetch_result() to retrieve any keys found.
No error is given on keys that are not found.

Instead of this function, you'd normally use the L</mget_into_hashref> method.

=head3 memcached_fetch

  $value = memcached_fetch($memc, $key);
  $value = memcached_fetch($memc, $key, $flag, $rc);

Fetch the next $key and $value pair returned in response to a memcached_mget() call.
Returns undef if there are no more values.

If $flag is given then it will be updated to whatever flags were stored with the value.
If $rc is given then it will be updated to the return code.

This is similar to L</memcached_get> except its fetching the results from the previous
call to L</memcached_mget> and $key is an output parameter instead of an input.
Usually you'd just use the L</mget_into_hashref> method instead.

=cut


=head2 Functions for Incrementing and Decrementing Values

memcached servers have the ability to increment and decrement unsigned integer keys
(overflow and underflow are not detected). This gives you the ability to use
memcached to generate shared sequences of values.  

See L<Memcached::libmemcached::memcached_auto>.

=head3 memcached_increment

  memcached_increment( $key, $offset, $new_value_out );

Increments the integer value associated with $key by $offset and returns the
new value in $new_value_out.

=head3 memcached_decrement 

  memcached_decrement( $key, $offset, $new_value_out );

Decrements the integer value associated with $key by $offset and returns the
new value in $new_value_out.

=head3 memcached_increment_with_initial

  memcached_increment_with_initial( $key, $offset, $initial, $expiration, $new_value_out );

Increments the integer value associated with $key by $offset and returns the
new value in $new_value_out.

If the object specified by key does not exist, one of two things may happen:
If the expiration value is MEMCACHED_EXPIRATION_NOT_ADD, the operation will fail.
For all other expiration values, the operation will succeed by seeding the
value for that key with a initial value to expire with the provided expiration time.
The flags will be set to zero.

=head3 memcached_decrement_with_initial

  memcached_decrement_with_initial( $key, $offset, $initial, $expiration, $new_value_out );

Decrements the integer value associated with $key by $offset and returns the
new value in $new_value_out.

If the object specified by key does not exist, one of two things may happen:
If the expiration value is MEMCACHED_EXPIRATION_NOT_ADD, the operation will fail.
For all other expiration values, the operation will succeed by seeding the
value for that key with a initial value to expire with the provided expiration time.
The flags will be set to zero.

=head3 memcached_increment_by_key

=head3 memcached_decrement_by_key

=head3 memcached_increment_with_initial_by_key

=head3 memcached_decrement_with_initial_by_key

These are the master key equivalents of the above. They all take an extra
initial $master_key parameter.


=head2 Functions for Deleting Values from memcached

See L<Memcached::libmemcached::memcached_delete>.

=head3 memcached_delete

  memcached_delete($memc, $key);
  memcached_delete($memc, $key, $expiration);

Delete $key. If $expiration is greater than zero then the key is deleted by
memcached after that many seconds.

=cut


=head2 Functions for Accessing Statistics from memcached

Not yet implemented. See L<Memcached::libmemcached::memcached_stats>.

See L<walk_stats>.

=cut


=head2 Miscellaneous Functions

=head2 memcached_lib_version

  $version = memcached_lib_version()

Returns a simple version string, like "1.0.17", representing the libmemcached
version (version of the client library, not server).

=head2 memcached_version

  $version = memcached_version($memc)
  ($version1, $version2, $version3) = memcached_version($memc)

Returns the I<lowest> version of all the memcached servers.

In scalar context returns a simple version string, like "1.2.3".
In list context returns the individual version component numbers.
Returns an empty list if there was an error.

Note that the return value differs from that of the underlying libmemcached
library memcached_version() function.

=cut

sub memcached_version {
    my $self = shift;

    my @versions;
    # XXX should be rewritten to use underlying memcached_version then
    # return the lowest cached version from the server structures
    $self->walk_stats('', sub {
        my ($key, $value, $hostport) = @_;
        push @versions, [ split /\./, $value ] if $key eq 'version';
        return;
    });

    my $lowest = (sort {
        $a->[0] <=> $b->[0] or $a->[1] <=> $b->[1] or $a->[2] <=> $b->[2]
    } @versions)[0];

    return join '.', @$lowest unless wantarray;
    return @$lowest;
}


=head2 memcached_verbosity

  memcached_verbosity($memc, $verbosity)

Modifies the "verbosity" of the memcached servers associated with $memc.
See L<Memcached::libmemcached::memcached_verbosity>.

=head3 memcached_flush

  memcached_flush($memc, $expiration);

Wipe clean the contents of associated memcached servers.
See L<Memcached::libmemcached::memcached_flush>.

=head2 memcached_quit

  memcached_quit($memc)

Disconnect from all currently connected servers and reset libmemcached state associated with $memc.
Not normally called explicitly.
See L<Memcached::libmemcached::memcached_quit>.

=head3 memcached_strerror

  $string = memcached_strerror($memc, $return_code)

memcached_strerror() takes a C<memcached_return> value and returns a string describing the error.
The string should be treated as read-only (it may be so in future versions).
See also L<Memcached::libmemcached::memcached_strerror>.

This function is rarely needed in the Perl interface because the return code is
a I<dualvar> that already contains the error string.

=cut

=head2 Grouping Keys On Servers

Normally libmemcached hashes the $key value to select which memcached server to
communicate with. If you have several keys relating to a single object then
it's very likely that the corresponding values will be stored in different
memcached servers.

It would be more efficient, in general, when setting and getting multiple
related values, if it was possible to specify a different value to be hashed to
select which memcached server to communicate with. With libmemcached, you can.

Most of the functions for setting and getting values have C<*_by_key> variants
for exactly this reason.  These all have an extra $master_key parameter
immediately after the $memc parameter. For example:

    memcached_mget($memc, \%keys, \%dest);

    memcached_mget_by_key($memc, $maskey_key, \%keys, \%dest);

The C<*_by_key> variants all work in exactly the same way as the corresponding
plain function, except that libmemcached hashes $master_key instead of $key to
which memcached server to communicate with.

If $master_key is undef then the functions behave the same as their non-by-key
variants, i.e., $key is used for hashing.

By-key variants of L</Functions for Fetching Values>:

=head3 memcached_get_by_key

=head3 memcached_mget_by_key

By-key variants of L</Functions for Setting Values>:

=head3 memcached_set_by_key

=head3 memcached_replace_by_key

=head3 memcached_add_by_key

=head3 memcached_append_by_key

=head3 memcached_cas_by_key

=head3 memcached_prepend_by_key

=head3 memcached_delete_by_key

=head1 OBJECT-ORIENTED INTERFACE

=head2 Methods

=head3 new

  $memc = $class->new; # same as memcached_create()

=head3 errstr

  $errstr = $memc->errstr;

Returns the error message and code from the most recent call to any
libmemcached function that returns a C<memcached_return>, which most do.

The return value is a I<dualvar>, like $!, which means it has separate numeric
and string values. The numeric value is the memcached_return integer value,
and the string value is the corresponding error message what memcached_strerror()
would return.

As a special case, if the memcached_return is MEMCACHED_ERRNO, indicating a
system call error, then the string returned by strerror() is appended.

This method is also currently callable as memcached_errstr() for compatibility
with an earlier version, but that deprecated alias will start warning and then
cease to exist in future versions.

=head3 mget_into_hashref

  $memc->mget_into_hashref( \@keys, \%dest_hash); # keys from array
  $memc->mget_into_hashref( \%keys, \%dest_hash); # keys from hash

Combines memcached_mget() and a memcached_fetch() loop into a single highly
efficient call.

Fetched values are stored in \%dest_hash, updating existing values or adding
new ones as appropriate.

This method is also currently callable as memcached_mget_into_hashref() for
compatibility with an earlier version, but that deprecated alias will start
warning and then cease to exist in future versions.

=head3 get_multi

  $hash_ref = $memc->get_multi( @keys );

Effectively the same as:

  $memc->mget_into_hashref( \@keys, $hash_ref = { } )

So it's very similar to L</mget_into_hashref> but less efficient for large
numbers of keys (because the keys have to be pushed onto the argument stack)
and less flexible (because you can't add/update elements into an existing hash).

This method is provided to optimize subclasses that want to provide a
Cache::Memcached compatible API with maximum efficiency.
Note, however, that C<get_multi> does I<not> support the L<Cache::Memcached>
feature where a key can be a reference to an array [ $master_key, $key ].
Use L</memcached_mget_by_key> directly if you need that feature.

=head3 get

  $value = $memc->get( $key );

Effectively the same as:

  $value = memcached_get( $memc, $key );

The C<get> method also supports the L<Cache::Memcached> feature where $key can
be a reference to an array [ $master_key, $key ]. In which case the call is
effectively the same as:

  $value = memcached_get_by_key( $memc, $key->[0], $key->[1] )


=head3 set_callback_coderefs

  $memc->set_callback_coderefs(\&set_callback, \&get_callback);

This interface is I<experimental> and I<likely to change>. (It's also currently
used by Cache::Memcached::libmemcached, so don't use it if you're using that module.)

Specify functions which will be executed when values are set and/or get using $memc. 

When the callbacks are executed $_ is the value and the arguments are the key
and flags value. Both $_ and the flags may be modified.

Currently the functions must return an empty list.

This method is also currently callable as memcached_set_callback_coderefs() for
compatibility with an earlier version, but that deprecated alias will start
warning and then cease to exist in future versions.

=head3 walk_stats

  $memc->walk_stats( $stats_args, \&my_stats_callback );

This interface is I<experimental> and I<likely to change>.

Calls the memcached_stat_execute() function to issue a "STAT $stats_args" command to
the connected memcached servers. The $stats_args argument is usually an empty string.

The callback function is called for each return value from each server.
The callback will be passed at least these parameters:

  sub my_stats_callback {
    my ($key, $value, $hostport) = @_;
    # Do what you like with the above!
    return;
  }

Currently the callback I<must> return an empty list.

Prior to version 0.4402 the callback was passed a fourth argument which was a
copy of the $stats_args value. That is no longer the case. As a I<temporary> aid
to migration, the C<walk_stats> method does C<local $_ = $stats_args> and
passes C<$_> as the forth argument. That will work so long as the code in the
callback doesn't alter C<$_>. If your callback code requires $stats_args you
should change it to be a closure instead.

=head2 trace_level

    $memc->trace_level($trace_level);
    $trace_level = $memc->trace_level;

Sets the trace level (see L</Tracing Execution>). Returns the previous trace level.

=head3 get_server_for_key

  $memc->get_server_for_key( $key )

This method uses I<memcached_server_by_key> to get information about which server should contain
the specified $key.

It returns a string containing the hostname:port of the appropriate server, or undef on failure.

=head1 EXTRA INFORMATION

=head2 Tracing Execution

    $memc->trace_level($trace_level);

If set >= 1 then any non-success memcached_return value will be logged via warn().

If set >= 2 or more then some data types will list conversions of input and output values for function calls.

The C<PERL_LIBMEMCACHED_TRACE> environment variable provides a default.
The value is read when L<memcached_create> is called.

=head2 Type Mapping

For pointer arguments, undef is mapped to null on input and null is mapped to
undef on output.

XXX expand with details from typemap file

=head2 Deprecated Functions

The following functions are available but deprecated in this release.
In the next release they'll generate warnings.
In a future release they'll be removed.

=head3 memcached_errstr

Use L</errstr> instead.

=head3 memcached_mget_into_hashref

Use L</mget_into_hashref> instead.

=head3 memcached_set_callback_coderefs

Use L</set_callback_coderefs> instead.

=head1 AUTHOR EMERITUS

Tim Bunce, C<< <Tim.Bunce@pobox.com> >> with help from Patrick Galbraith and Daisuke Maki.

L<http://www.tim.bunce.name>

=head1 CURRENT MAINTAINER

Matthew Horsfall (alh) C<< <wolfsage@gmail.com> >>

Daisuke Maki C<< <daisuke@endeworks.jp> >> with occasional bursts of input from Tim Bunce.

=head1 ACKNOWLEDGEMENTS

Larry Wall for Perl, Brad Fitzpatrick for memcached, Brian Aker for libmemcached,
and Patrick Galbraith and Daisuke Maki for helping with the implementation.

=head1 PORTABILITY

See Slaven Rezic's excellent CPAN Testers Matrix at L<http://matrix.cpantesters.org/?dist=Memcached-libmemcached>

Along with Dave Cantrell's excellent CPAN Dependency tracker at
L<http://deps.cpantesters.org/?module=Memcached%3A%3Alibmemcached&perl=any+version&os=any+OS>

=head1 BUGS

Please report any bugs or feature requests to the GitHub issue tracker at
L<https://github.com/timbunce/Memcached-libmemcached/issues>.
We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=head1 CONTRIBUTING

The source is hosted at github: L<https://github.com/timbunce/Memcached-libmemcached>
Patches and volunteers always welcome.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Tim Bunce, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Memcached::libmemcached
