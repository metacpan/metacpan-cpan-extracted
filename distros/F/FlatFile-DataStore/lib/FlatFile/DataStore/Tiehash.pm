#---------------------------------------------------------------------
  package FlatFile::DataStore;  # not FlatFile::DataStore::Tiehash
#---------------------------------------------------------------------

=head1 NAME

FlatFile::DataStore::Tiehash - Provides routines that are used
only when tie'ing a hash to a datastore.

=head1 SYNOPSYS

 require FlatFile::DataStore::Tiehash;

(But this is done only in FlatFile/DataStore.pm)

=head1 DESCRIPTION

FlatFile::DataStore::Tiehash provides the routines that are used only
when tie'ing a hash to a datastore.  It isn't a "true" module; it's
intended for loading more methods into the FlatFile::DataStore class.

=head1 SYNOPSYS

    use FlatFile::DataStore;  # not FlatFile::DataStore::Tiehash

    tie my %dshash, 'FlatFile::DataStore', {
        name => "dsname",
        dir  => "/my/datastore/directory",
    };

    # create a record (null string key says, "new record")

    my $record = $dshash{''} = { data => "Test record", user => "Test user data" };
    my $record_number = $record->keynum;

    # update it (have to "have" a record to update it)

    $record->data( "Updating the test record." );
    $dshash{ $record_number } = $record;

    # retrieve it

    $record = $dshash{ $record_number };

    # delete it

    delete $dshash{ $record_number };

    # -or-

    tied(%dshash)->delete( $record );

    # test it ... exists is true after a delete

    if( $preamble = exists $dshash{ $record_number } ) {
        print "Deleted." if $preamble->is_deleted;
    }

=head1 DESCRIPTION

This module provides the methods that allow you to tie a hash to a data
store.  The hash keys are integers that range from 0 to
$datastore_object->lastkeynum.

In the case of delete, you're limited in the tied interface -- you
can't supply a "delete record" (one that has information about the
delete operation).  Instead, it will simply retrieve the existing
record and store that as the "delete record".  If you want the "delete
record" to contain different information (such as who is deleting it),
you must call the non-tied delete() method with the datastore object.

Note that record data may be created or updated (i.e., STORE'd) three
ways:

As data string (or scalar reference), e.g.,

    $record = $dshash{''} = $record_data;

As a hash reference (so you can supply some user data), e.g.

    $record = $dshash{''} = { data => $record_data, user => $user_data };

As a record object (record data and user data gotten from object),
e.g.,

    $record->data( $record_data );
    $record->user( $user_data );
    $record = $dshash{''} = $record;

Note that in the last example, the object fetched is not the same as
the one given to be stored (it has a different preamble).

The above examples use a "null key" convention.  When you assign to the
null key entry, it creates a new record in the datastore, which adds a
new record key sequence number.  When you read the null key entry, it
retrieves the last record.  Thus when you do this:

    $record = $dshash{''} = $record_data;

You are creating a new record (C<$dshash{''} = $record_data>), and you
are then retrieving the last record (C<$record = $dshash{''}>), which
happens to be the record you just created.  This null key convention
saves you from having to do something like this equivalent code:

    my $ds = tied %dshash;
    $dshash{ $ds->nextkeynum } = $record_data;
    $record = $dshash{ $ds->lastkeynum };
 
=head1 VERSION

FlatFile::DataStore::Tiehash version 1.03

=cut

our $VERSION = '1.03';

use 5.008003;
use strict;
use warnings;
use Carp;

#---------------------------------------------------------------------
# NOTE: TIEHASH() is defined in FlatFile/DataStore.pm

#---------------------------------------------------------------------
# FETCH() supports tied hash access
#     Returns a record object.

sub FETCH {
    my( $self, $key ) = @_;

    my $lastkeynum = $self->lastkeynum;
    $key = $lastkeynum if $key eq '';

    return if $key !~ /^[0-9]+$/;
    return if $key  > $lastkeynum;
    $self->retrieve( $key );
}

#---------------------------------------------------------------------
# STORE() supports tied hash access
#     Keys are limited to 0 .. lastkeynum (integers)
#     If $key is new, it has to be nextkeynum, i.e., you can't leave
#     gaps in the sequence of keys
#     e.g., $h{ keys %h                } = { data => "New", user => "record" };
#     or    $h{ tied( %h )->nextkeynum } = { data => "New", user => "record" };
#     or    $h{ ''                     } = { data => "New", user => "record" };
#     or    $h{ undef                  } = { data => "New", user => "record" };
#     ('keys %h' is fairly light-weight, but nextkeynum is more so
#     and $h{''} (or $h{undef}) is shorthand for nextkeynum)

sub STORE {
    my( $self, $key, $parms ) = @_;

    my $nextkeynum = $self->nextkeynum;
    $key = $nextkeynum if $key eq '';
    croak qq/Unsupported key format: $key/
        unless $key =~ /^[0-9]+$/ and $key <= $nextkeynum;

    my $reftype = ref $parms;  # record, hash, sref, string

    # for updates, $parms must be a record object
    if( $key < $nextkeynum ) {
        croak qq/Not a record object: $parms/
            unless $reftype and $reftype =~ /Record/;
        my $keynum = $parms->keynum;
        croak qq/Record key number, $keynum, doesn't match key: $key/
            unless $key == $keynum;
        return $self->update( $parms );
    }

    # for creates, $parms may be record, href, sref, or string
    else {
        if( !$reftype or $reftype eq "SCALAR" ) {  # string
            return $self->create({ data => $parms }); 
        }
        if( $reftype =~ /Record/ ) {
            return $self->create( $parms );
        }
        if( $reftype eq 'HASH' ) {  # e.g., {data=>'recdata',user=>'userdata'}
            return $self->create( $parms );
        }
        else {
            croak qq/Unsupported ref type: $reftype/;
        }
    }
}

#---------------------------------------------------------------------
# DELETE() supports tied hash access
#     If you want the "delete record" to contain anything more than
#     the record being deleted, you have to call tied( %h )->delete()
#     instead.
#
#     Otherwise, we have to have a record to delete one, so we fetch
#     it first.

sub DELETE {
    my( $self, $key ) = @_;
    return if $key !~ /^[0-9]+$/;
    return if $key > $self->lastkeynum;
    my $record = $self->retrieve( $key );
    $self->delete( $record );
}

#---------------------------------------------------------------------
# CLEAR() supports tied hash access
#     except we don't support CLEAR, because it would be very
#     destructive and it would be a pain to recover from an
#     accidental %h = ();

sub CLEAR {
    my $self = shift;
    croak qq/Clearing the entire datastore is not supported/;
}

#---------------------------------------------------------------------
# FIRSTKEY() supports tied hash access
#     The keys in a datastore are always 0 .. lastkeynum (integers).
#     Before the first record is added, nextkeynum() returns 0.
#     In that case, the sub below would return undef.

sub FIRSTKEY {
    my $self = shift;
    return 0 if $self->nextkeynum > 0;
}

#---------------------------------------------------------------------
# NEXTKEY() supports tied hash access
#     Because FIRSTKEY/NEXTKEY are functions of integers and require
#     reading only a single line from a file (lastkeynum() reads the
#     first line of the first toc file), the 'keys %h' operation is
#     comparatively light-weight ('values %h' is a different story.)

sub NEXTKEY {
    my( $self, $prevkey ) = @_; 
    return if $prevkey >= $self->lastkeynum;
    $prevkey + 1;
}

#---------------------------------------------------------------------
# SCALAR() supports tied hash access
#     nextkeynum() returns 0 before any records are added.  A non-zero
#     value indicates there are records -- created, updated, and/or
#     deleted.  Note that exists() returns true for a deleted record.

sub SCALAR {
    my $self = shift;
    $self->nextkeynum;
}

#---------------------------------------------------------------------
# EXISTS() supports tied hash access
#     This routine will return a true value for created, updated,
#     *and* deleted records.  This true value is in fact a preamble
#     object, so if needed, you can check the status of the record
#     (deleted or not), e.g.,
#
#     if( my $preamble = exists( $key ) ) {
#        print "Deleted." if $preamble->is_deleted();
#        print "Created." if $preamble->is_created();
#        print "Updated." if $preamble->is_updated();
#     }

sub EXISTS {
    my( $self, $key ) = @_;
    return if $key !~ /^[0-9]+$/;
    return if $key > $self->lastkeynum;
    $self->retrieve_preamble( $key );
}

#---------------------------------------------------------------------
# UNTIE() supports tied hash access
#     (see perldoc perltie, The "untie" Gotcha)

sub UNTIE {
    my( $self, $count ) = @_;
    carp "untie attempted while $count inner references still exist" if $count;
}


1;  # returned

__END__

=head1 CAVEATS

This module is still in an experimental state.  The tests are sparse.
When I start using it in production, I'll bump the version to 1.00.

Until then (afterwards, too) please use with care.

=head1 AUTHOR

Brad Baxter, E<lt>bbaxter@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Brad Baxter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

