package Fdb;
use base qw(Exporter);
use base qw(DynaLoader);
package Fdbc;
bootstrap Fdb;
package Fdb;

@EXPORT = qw();
use 5.8.0;
use strict;
use warnings FATAL => 'all';
use threads;

=head1 NAME

Fdb - FoundationDB Perl Interface

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

Use Fdb to interface with FoundationDB. It is based on the C API, so please
read the documentation on the FoundationDB website.

The Perl interface differs from the C one in 2 cases:

=li

* where C methods expect tuples of C<(string, string_length)>, in Perl disregard
the need for string_length

=li

* where C methods expect an output parameter (e.g. C<FDBCluster **out_cluster>),
in Perl you instead do not pass it in but get it as a 2nd item in the output of
the method.

=back

        use Fdb;
        Fdb::select_api_version(Fdb::FDB_API_VERSION);
        Fdb::setup_network();
        Fdb::run_network();
        my $cluster_f = Fdb::create_cluster(undef);
        Fdb::future_block_until_ready($cluster_f);
        my $err;
        if (Fdb::future_is_error($cluster_f)) {
          Fdb::future_get_error($cluster_f, $err);
          warn $err;
        }
        my $res;
        my $cluster_handle = undef;
        ($res, $cluster_handle) = Fdb::future_get_cluster($cluster_f);
        Fdb::future_destroy($cluster_f);
        my $db_f = Fdb::cluster_create_database($cluster_handle, "TEST_DB");
        Fdb::future_block_until_ready($db_f);
        my $db_handle;
        ($res, $db_handle) = Fdb::future_get_database($db_f);
        Fdb::future_destroy($db_f);

        ...

        Fdb::database_destroy($db_handle);
        Fdb::cluster_destroy($cluster_handle);
        Fdb::stop_network();

Please see B<t/01_connect.t> for a complete example with transactions and getting/setting keys

=head1 EXPORT

Nothing

=head1 SUBROUTINES/METHODS

With the exceptions described in the SYNOPSIS, all the subroutines have the same
names and parameters as the C API.


=head1 AUTHOR

Henri Asseily, C<< <henri at asseily.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-fdb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Fdb>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

The main documentation for the API is:

=over 4

L<http://foundationdb.com/documentation/>

=back

You can find documentation for this module with the perldoc command.

    perldoc Fdb


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Fdb>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Fdb>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Fdb>

=item * Search CPAN

L<http://search.cpan.org/dist/Fdb/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Henri Asseily.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut


our $network_thread;

sub run_network {
  if (!$network_thread) {
    $network_thread = threads->create(sub { Fdbc::run_network(); });
    $network_thread->detach();
  }
  return 0;
}

sub select_api_version {
  return select_api_version_impl(@_, FDB_API_VERSION());
}

# ---------- BASE METHODS -------------


sub TIEHASH {
    my ($classname,$obj) = @_;
    return bless $obj, $classname;
}

sub CLEAR { }

sub FIRSTKEY { }

sub NEXTKEY { }

sub FETCH {
    my ($self,$field) = @_;
    my $member_func = "swig_${field}_get";
    $self->$member_func();
}

sub STORE {
    my ($self,$field,$newval) = @_;
    my $member_func = "swig_${field}_set";
    $self->$member_func($newval);
}

sub this {
    my $ptr = shift;
    return tied(%$ptr);
}


# ------- FUNCTION WRAPPERS --------

package Fdb;

*get_error = *Fdbc::get_error;
*network_set_option = *Fdbc::network_set_option;
*setup_network = *Fdbc::setup_network;
*stop_network = *Fdbc::stop_network;
*future_destroy = *Fdbc::future_destroy;
*future_block_until_ready = *Fdbc::future_block_until_ready;
*future_is_ready = *Fdbc::future_is_ready;
*future_is_error = *Fdbc::future_is_error;
*future_set_callback = *Fdbc::future_set_callback;
*future_get_error = *Fdbc::future_get_error;
*future_get_version = *Fdbc::future_get_version;
*future_get_key = *Fdbc::future_get_key;
*future_get_cluster = *Fdbc::future_get_cluster;
*future_get_database = *Fdbc::future_get_database;
*future_get_value = *Fdbc::future_get_value;
*future_get_keyvalue_array = *Fdbc::future_get_keyvalue_array;
*create_cluster = *Fdbc::create_cluster;
*cluster_destroy = *Fdbc::cluster_destroy;
*cluster_set_option = *Fdbc::cluster_set_option;
*cluster_create_database = *Fdbc::cluster_create_database;
*database_destroy = *Fdbc::database_destroy;
*database_set_option = *Fdbc::database_set_option;
*database_create_transaction = *Fdbc::database_create_transaction;
*transaction_destroy = *Fdbc::transaction_destroy;
*transaction_set_option = *Fdbc::transaction_set_option;
*transaction_set_read_version = *Fdbc::transaction_set_read_version;
*transaction_get_read_version = *Fdbc::transaction_get_read_version;
*transaction_get = *Fdbc::transaction_get;
*transaction_get_key = *Fdbc::transaction_get_key;
*transaction_get_range = *Fdbc::transaction_get_range;
*transaction_set = *Fdbc::transaction_set;
*transaction_clear = *Fdbc::transaction_clear;
*transaction_clear_range = *Fdbc::transaction_clear_range;
*transaction_commit = *Fdbc::transaction_commit;
*transaction_get_committed_version = *Fdbc::transaction_get_committed_version;
*transaction_on_error = *Fdbc::transaction_on_error;
*transaction_reset = *Fdbc::transaction_reset;
*select_api_version_impl = *Fdbc::select_api_version_impl;
*get_max_api_version = *Fdbc::get_max_api_version;

############# Class : Fdb::FDBKeyValue ##############

package Fdb::FDBKeyValue;
use vars qw(@ISA %OWNER %ITERATORS %BLESSEDMEMBERS);
@ISA = qw( Fdb );
%OWNER = ();
%ITERATORS = ();
*swig_key_get = *Fdbc::FDBKeyValue_key_get;
*swig_key_set = *Fdbc::FDBKeyValue_key_set;
*swig_key_length_get = *Fdbc::FDBKeyValue_key_length_get;
*swig_key_length_set = *Fdbc::FDBKeyValue_key_length_set;
*swig_value_get = *Fdbc::FDBKeyValue_value_get;
*swig_value_set = *Fdbc::FDBKeyValue_value_set;
*swig_value_length_get = *Fdbc::FDBKeyValue_value_length_get;
*swig_value_length_set = *Fdbc::FDBKeyValue_value_length_set;
sub new {
    my $pkg = shift;
    my $self = Fdbc::new_FDBKeyValue(@_);
    bless $self, $pkg if defined($self);
}

sub DESTROY {
    return unless $_[0]->isa('HASH');
    my $self = tied(%{$_[0]});
    return unless defined $self;
    delete $ITERATORS{$self};
    if (exists $OWNER{$self}) {
        Fdbc::delete_FDBKeyValue($self);
        delete $OWNER{$self};
    }
}

sub DISOWN {
    my $self = shift;
    my $ptr = tied(%$self);
    delete $OWNER{$ptr};
}

sub ACQUIRE {
    my $self = shift;
    my $ptr = tied(%$self);
    $OWNER{$ptr} = 1;
}


# ------- CONSTANT STUBS -------

package Fdb;

sub FDB_API_VERSION () { $Fdbc::FDB_API_VERSION }
sub FDB_NET_OPTION_LOCAL_ADDRESS () { $Fdbc::FDB_NET_OPTION_LOCAL_ADDRESS }
sub FDB_NET_OPTION_CLUSTER_FILE () { $Fdbc::FDB_NET_OPTION_CLUSTER_FILE }
sub FDB_NET_OPTION_TRACE_ENABLE () { $Fdbc::FDB_NET_OPTION_TRACE_ENABLE }
sub FDB_CLUSTER_OPTION_DUMMY_DO_NOT_USE () { $Fdbc::FDB_CLUSTER_OPTION_DUMMY_DO_NOT_USE }
sub FDB_DB_OPTION_DUMMY_DO_NOT_USE () { $Fdbc::FDB_DB_OPTION_DUMMY_DO_NOT_USE }
sub FDB_TR_OPTION_CAUSAL_WRITE_RISKY () { $Fdbc::FDB_TR_OPTION_CAUSAL_WRITE_RISKY }
sub FDB_TR_OPTION_CAUSAL_READ_RISKY () { $Fdbc::FDB_TR_OPTION_CAUSAL_READ_RISKY }
sub FDB_TR_OPTION_CAUSAL_READ_DISABLE () { $Fdbc::FDB_TR_OPTION_CAUSAL_READ_DISABLE }
sub FDB_TR_OPTION_CHECK_WRITES_ENABLE () { $Fdbc::FDB_TR_OPTION_CHECK_WRITES_ENABLE }
sub FDB_TR_OPTION_READ_YOUR_WRITES_DISABLE () { $Fdbc::FDB_TR_OPTION_READ_YOUR_WRITES_DISABLE }
sub FDB_TR_OPTION_READ_AHEAD_DISABLE () { $Fdbc::FDB_TR_OPTION_READ_AHEAD_DISABLE }
sub FDB_TR_OPTION_DURABILITY_DATACENTER () { $Fdbc::FDB_TR_OPTION_DURABILITY_DATACENTER }
sub FDB_TR_OPTION_DURABILITY_RISKY () { $Fdbc::FDB_TR_OPTION_DURABILITY_RISKY }
sub FDB_TR_OPTION_DURABILITY_DEV_NULL_IS_WEB_SCALE () { $Fdbc::FDB_TR_OPTION_DURABILITY_DEV_NULL_IS_WEB_SCALE }
sub FDB_TR_OPTION_PRIORITY_SYSTEM_IMMEDIATE () { $Fdbc::FDB_TR_OPTION_PRIORITY_SYSTEM_IMMEDIATE }
sub FDB_TR_OPTION_PRIORITY_BATCH () { $Fdbc::FDB_TR_OPTION_PRIORITY_BATCH }
sub FDB_TR_OPTION_INITIALIZE_NEW_DATABASE () { $Fdbc::FDB_TR_OPTION_INITIALIZE_NEW_DATABASE }
sub FDB_TR_OPTION_ACCESS_SYSTEM_KEYS () { $Fdbc::FDB_TR_OPTION_ACCESS_SYSTEM_KEYS }
sub FDB_TR_OPTION_DEBUG_DUMP () { $Fdbc::FDB_TR_OPTION_DEBUG_DUMP }
sub FDB_STREAMING_MODE_WANT_ALL () { $Fdbc::FDB_STREAMING_MODE_WANT_ALL }
sub FDB_STREAMING_MODE_ITERATOR () { $Fdbc::FDB_STREAMING_MODE_ITERATOR }
sub FDB_STREAMING_MODE_EXACT () { $Fdbc::FDB_STREAMING_MODE_EXACT }
sub FDB_STREAMING_MODE_SMALL () { $Fdbc::FDB_STREAMING_MODE_SMALL }
sub FDB_STREAMING_MODE_MEDIUM () { $Fdbc::FDB_STREAMING_MODE_MEDIUM }
sub FDB_STREAMING_MODE_LARGE () { $Fdbc::FDB_STREAMING_MODE_LARGE }
sub FDB_STREAMING_MODE_SERIAL () { $Fdbc::FDB_STREAMING_MODE_SERIAL }


1;
