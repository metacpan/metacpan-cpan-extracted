#---------------------------------------------------------------------
  package FlatFile::DataStore::DBM;
#---------------------------------------------------------------------

=head1 NAME

FlatFile::DataStore::DBM - Perl module that implements a flatfile
datastore with a DBM file key access.

=head1 SYNOPSYS

    use Fctnl;
    use FlatFile::DataStore::DBM;

    $FlatFile::DataStore::DBM::dbm_package  = "SDBM_File";  # the defaults
    $FlatFile::DataStore::DBM::dbm_parms    = [ O_CREAT|O_RDWR, 0666 ];
    $FlatFile::DataStore::DBM::dbm_lock_ext = ".dir";

    # new object

    my $obj = tie my %dshash, 'FlatFile::DataStore::DBM', {
        name => "dsname",
        dir  => "/my/datastore/directory",
    };

    # create a record and retrieve it

    my $id     = "testrec1";
    my $record = $dshash{ $id } = { data => "Test record", user => "Test user data" };

    # update it

    $record->data( "Updating the test record." );
    $dshash{ $id } = $record;

    # delete it

    delete $dshash{ $id };

    # get its history

    my @records = $obj->history( $id );

=head1 DESCRIPTION

FlatFile::DataStore::DBM implements a tied hash interface to a
flatfile datastore.  The hash keys are strings that you provide.
These keys do not necessarily have to exist as data in the record.

In the case of delete, you're limited in the tied interface -- you
can't supply a "delete record" (one that has information about the
delete operation).  Instead, it will simply retrieve the existing
record and store that as the delete record.

Record data may be created or updated (i.e., STORE'd) three ways:

As a data string (or scalar reference), e.g.,

    $record = $dshash{ $id } = $record_data;

As a hash reference, e.g.

    $record = $dshash{ $id } = { data => $record_data, user => $user_data };

As a record object (record data and user data gotten from object),
e.g.,

    $record->data( $record_data );
    $record->user( $user_data );
    $record = $dshash{ $id } = $record;

In the last line above, the object fetched is not the same as
the one given to be stored (it has a different preamble).

FWIW, this module is not a subclass of FlatFile::DataStore.  Instead,
it is a wrapper, so it's a "has a" relationship rather than an "is a"
one.  But many of the public flatfile methods are available via the
tied object, as illustrated by the history() call in the synopsis.

These methods include

    name
    dir
    retrieve
    retrieve_preamble
    locate_record_data
    history
    userdata
    howmany
    lastkeynum
    nextkeynum

Note that create(), update(), and delete() are not included in this
list.  If a datastore is set up using this module, all updates to its
data should use this module.  This will keep the keys in sync with
the data.

=head1 VERSION

FlatFile::DataStore::DBM version 1.03

=cut

our $VERSION = '1.03';

use 5.008003;
use strict;
use warnings;

use Fcntl qw(:DEFAULT :flock);
use Carp;

use FlatFile::DataStore;

#---------------------------------------------------------------------

=head1 DESCRIPTION

=head2 Tieing the hash

Accepts hash ref giving values for C<dir> and C<name>.

    tie my %dshash, 'FlatFile::DataStore::DBM', {
        name => $name,
        dir  => $dir,
    };

To initialize a new datastore, pass the URI as the value of the
C<uri> parameter, e.g.,

    tie my %dshash, 'FlatFile::DataStore::DBM', {
        dir  => $dir,
        name => $name,
        uri  => join( ";" =>
            "http://example.com?name=$name",
            "desc=My%20Data%20Store",
            "defaults=medium",
            "user=8-%20-%7E",
            "recsep=%0A",
        ),
    };

(See URI Configuration in FlatFile::DataStore.)
Also accepts a C<userdata> parameter, which sets the default user
data for this instance.

Returns a reference to the FlatFile::DataStore::DBM object.

=head2 Object Methods

#---------------------------------------------------------------------

=head3 get_key( $keynum );

Gets the key associated with a record sequence number (keynum).
This could be handy if you have a record, but don't have its key
in the DBM file, e.g.,

    # have a record to update, but forgot its key
    # (the key isn't necessarily in the record)
    
    my $id = tied(%dshash)->get_key( $record->keynum );
    $dshash{ $id } = $record;

=cut

sub get_key {
    my( $self, $keynum ) = @_;

    croak qq/Not a keynum: $keynum/
        unless defined $keynum and $keynum =~ /^[0-9]+$/;

    my $ds    = $self->datastore;
    my $dir   = $ds->dir;
    my $name  = $ds->name;

    # lock the dbm file and read the key
    $self->readlock;
    tie my %dbm_hash, $self->dbm_package, "$dir/$name", @{$self->dbm_parms}
        or die "Can't tie dbm hash: $!";

    my $key = $dbm_hash{ "_$keynum" };

    untie %dbm_hash;
    $self->unlock;

    $key;  # returned
}

#---------------------------------------------------------------------

=head3 get_keynum( $key );

Gets the record sequence number (keynum) associated with a key.  Don't
have a good use case yet -- included this method as a complement to
get_key().

=cut

sub get_keynum {
    my( $self, $key ) = @_;

    croak qq/Unsupported key format: $key/ if $key =~ /^_[0-9]+$/;

    my $ds    = $self->datastore;
    my $dir   = $ds->dir;
    my $name  = $ds->name;

    # lock the dbm file and read the keynum
    $self->readlock;
    tie my %dbm_hash, $self->dbm_package, "$dir/$name", @{$self->dbm_parms}
        or die "Can't tie dbm hash: $!";

    my $keynum = $dbm_hash{ $key };

    untie %dbm_hash;
    $self->unlock;

    $keynum;  # returned
}

#---------------------------------------------------------------------
# accessors
# the following are required attributes, so simple accessors are okay
#
# Private methods.

sub datastore     {for($_[0]->{datastore    }){$_=$_[1]if@_>1;return$_}}
sub locked        {for($_[0]->{locked       }){$_=$_[1]if@_>1;return$_}}
sub dbm_lock_file {for($_[0]->{dbm_lock_file}){$_=$_[1]if@_>1;return$_}}
sub dbm_package   {for($_[0]->{dbm_package  }){$_=$_[1]if@_>1;return$_}}
sub dbm_parms     {for($_[0]->{dbm_parms    }){$_=$_[1]if@_>1;return$_}}

#---------------------------------------------------------------------
# globals
#
# These are read in TIEHASH().  They may be changed prior to calling
# tie(), e.g.,
#
# my $ds_parms = { name => $ds_name, dir => $ds_dir };
# $FlatFile::DataStore::DBM::dbm_parms = [ O_RDONLY, 0666 ];
#
# tie my %hash, "FlatFile::DataStore::DBM", $ds_parms;
#
# ... or different values may be passed to tie() using a hash
# reference as the second parameter, e.g.,
#
# my $ds_parms = { name => $ds_name, dir => $ds_dir };
# my $dbm_specs = { dbm_parms => [ O_RDONLY, 0666 ] }
#
# tie my %hash, "FlatFile::DataStore::DBM", $ds_parms, $dbm_specs;
#

our $dbm_package  = "SDBM_File";
our $dbm_parms    = [ O_CREAT|O_RDWR, 0666 ];
our $dbm_lock_ext = ".dir";

#---------------------------------------------------------------------
# TIEHASH() supports tied hash access
#
# Coding note: in TIEHASH(), the object attributes are set directly in
# the hash.  In all the other subs the above accessors are used.
#

sub TIEHASH {
    my( $class, $ds_parms, $dbm_specs ) = @_;

    my $ds   = FlatFile::DataStore->new( $ds_parms );
    my $dir  = $ds->dir;
    my $name = $ds->name;

    my $self = {
        datastore     => $ds,
        dbm_package   => $dbm_package,  # may be changed by dbm_specs
        dbm_parms     => $dbm_parms,    # "
        dbm_lock_ext  => $dbm_lock_ext, # "
    };
    if( $dbm_specs ) {
        $self->{ $_ } = $dbm_specs->{ $_ } for keys %$dbm_specs;
    }
    $self->{'dbm_lock_file'} = "$dir/$name$self->{'dbm_lock_ext'}";

    eval qq{require $self->{'dbm_package'}; 1}
        or croak qq/Can't use $self->{'dbm_package'}: $@/;

    bless $self, $class;
}

#---------------------------------------------------------------------
# FETCH() supports tied hash access
#     Returns a FlatFile::DataStore::Record object.

sub FETCH {
    my( $self, $key ) = @_;

    # block efforts to fetch a "_keynum" entry
    croak qq/Unsupported key format: $key/ if $key =~ /^_[0-9]+$/;

    my $ds    = $self->datastore;
    my $dir   = $ds->dir;
    my $name  = $ds->name;

    # lock the dbm file and read the keynum
    $self->readlock;
    tie my %dbm_hash, $self->dbm_package, "$dir/$name", @{$self->dbm_parms}
        or die "Can't tie dbm hash: $!";

    my $keynum = $dbm_hash{ $key };

    untie %dbm_hash;
    $self->unlock;

    return unless defined $keynum;
    $ds->retrieve( $keynum );  # retrieve and return record
}

#---------------------------------------------------------------------
# STORE() supports tied hash access
#     Returns a FlatFile::DataStore::Record object.
#
#     to help with FIRSTKEY/NEXTKEY, we're keeping two entries
#     in the dbm file for every record:
#         1. record id => key sequence number
#         2. key sequence number => record id
#
#     to avoid collisions with numeric keys, the key of the second
#     entry has an underscore pasted on to the front, e.g., a record
#     whose id is "able_baker_charlie" and whose keynum is 257 would
#     have these entries:
#         1. able_baker_charlie => 257
#         2. _257 => able_baker_charlie
#
# Note: the $error variable is intended to avoid having a croak
# between writelock() and unlock().  On linux systems that don't
# allow a process to have multiple locks on the same file, if you
# trap those croaks in an eval{} (like for testing), the program
# will hang waiting for a lock.
#

sub STORE {
    my( $self, $key, $parms ) = @_;

    # block efforts to store to "_keynum" entries
    croak qq/Unsupported key format: $key/ if $key =~ /^_[0-9]+$/;

    my $ds    = $self->datastore;
    my $dir   = $ds->dir;
    my $name  = $ds->name;

    my $error;

    # lock the dbm file and read the keynum
    $self->writelock;
    tie my %dbm_hash, $self->dbm_package, "$dir/$name", @{$self->dbm_parms}
        or die "Can't tie dbm hash: $!";

    my $keynum  = $dbm_hash{ $key };

    # $parms may be record, href, sref, or string
    my $reftype = ref $parms;

    my $record;  # to be returned

    if( defined $keynum ) {  # update

        # record data string
        if( !$reftype or $reftype eq "SCALAR" ) {
            $record = $ds->retrieve( $keynum );  # read it
            $record->data( $parms );             # update it
            $record = $ds->update( $record );    # write it
        }

        # record object
        elsif( $reftype =~ /Record/ ) {

            # trying to update a record using the wrong key?
            if( $keynum != $parms->keynum ) {
                $error = qq/Record key number doesn't match key/;
            }
            else {
                $record = $ds->update( $parms );
            }
        }

        # hash, e.g., {data=>'record data',user=>'user data'}
        elsif( $reftype eq 'HASH' ) {
            $parms->{'record'} = $ds->retrieve( $keynum ) unless $parms->{'record'};
            $record = $ds->update( $parms );
        }

        else {
            $error = qq/Unsupported ref type: $reftype/;
        }

    }

    else {  # create

        # record data string
        if( !$reftype or $reftype eq "SCALAR" ) {
            $record = $ds->create({ data => $parms }); 
        }

        # record object or hash, e.g.,
        #     { data => 'record data', user => 'user data' }
        elsif( $reftype =~ /Record/ or
               $reftype eq 'HASH'      ) {
            $record = $ds->create( $parms );
        }

        else {
            $error = qq/Unsupported ref type: $reftype/;
        }

        # create succeeded, let's store the key
        unless( $error ) {
            for( $record->keynum ) {
                $dbm_hash{ $key  } = $_;
                $dbm_hash{ "_$_" } = $key;
            }
        }
    }

    untie %dbm_hash;
    $self->unlock;

    croak $error if $error;

    $record;  # returned

}

#---------------------------------------------------------------------
# DELETE() supports tied hash access
#     Returns a FlatFile::DataStore::Record object.
#
#     Otherwise, we must have a record to delete one, so we retrieve
#     it first.
#

sub DELETE {
    my( $self, $key ) = @_;

    my $ds    = $self->datastore;
    my $dir   = $ds->dir;
    my $name  = $ds->name;

    $self->writelock;
    tie my %dbm_hash, $self->dbm_package, "$dir/$name", @{$self->dbm_parms}
        or die "Can't tie dbm hash: $!";

    my $exists;
    my $record;

    if( $exists = exists $dbm_hash{ $key } ) {

        my $keynum = $dbm_hash{ $key };

        # must have a record to delete it
        $record = $ds->retrieve( $keynum );
        $record = $ds->delete( $record );

        delete $dbm_hash{ $key };
        delete $dbm_hash{ "_$keynum" };
    }

    untie %dbm_hash;
    $self->unlock;

    return unless $exists;
    $record;  # return the "delete record"
}

#---------------------------------------------------------------------
# CLEAR() supports tied hash access
#     except we don't support CLEAR, because it would be very
#     destructive and it would be a pain to recover from an
#     accidental %h = ();

sub CLEAR {
    croak qq/Clearing the entire datastore is not supported/;
}

#---------------------------------------------------------------------
# FIRSTKEY() supports tied hash access

sub FIRSTKEY {
    my( $self ) = @_;

    my $ds    = $self->datastore;
    my $dir   = $ds->dir;
    my $name  = $ds->name;

    # lock the dbm file and read the first key (stored as '_0')
    $self->readlock;
    tie my %dbm_hash, $self->dbm_package, "$dir/$name", @{$self->dbm_parms}
        or die "Can't tie dbm hash: $!";

    my $firstkey = $dbm_hash{ '_0' };

    untie %dbm_hash;
    $self->unlock;

    $firstkey;  # returned, might be undef
}

#---------------------------------------------------------------------
# NEXTKEY() supports tied hash access

sub NEXTKEY {
    my( $self, $prevkey ) = @_;

    my $ds    = $self->datastore;
    my $dir   = $ds->dir;
    my $name  = $ds->name;

    my $nextkey;

    # lock the dbm file and get the prev key's keynum
    $self->readlock;
    tie my %dbm_hash, $self->dbm_package, "$dir/$name", @{$self->dbm_parms}
        or die "Can't tie dbm hash: $!";

    my $keynum = $dbm_hash{ $prevkey };

    if( $keynum++ < $ds->lastkeynum ) {
        $nextkey = $dbm_hash{ "_$keynum" };
    }

    untie %dbm_hash;
    $self->unlock;

    $nextkey;  # returned, might be undef
}

#---------------------------------------------------------------------
# SCALAR() supports tied hash access
#     Here we're bypassing the dbm file altogether and simply getting
#     the number of non-deleted records in the datastore.  This
#     should be the same as the number of (logical) entries in the
#     dbm hash.

sub SCALAR {
    my $self = shift;
    $self->datastore->howmany;  # create|update (not deletes)
}

#---------------------------------------------------------------------
# EXISTS() supports tied hash access

sub EXISTS {
    my( $self, $key ) = @_;

    # block efforts to look at a "_keynum" entry
    croak qq/Unsupported key format: $key/ if $key =~ /^_[0-9]+$/;

    my $ds    = $self->datastore;
    return unless $ds->exists;

    my $dir   = $ds->dir;
    my $name  = $ds->name;

    # lock the dbm file and call exists on dbm hash
    $self->readlock;
    tie my %dbm_hash, $self->dbm_package, "$dir/$name", @{$self->dbm_parms}
        or die "Can't tie dbm hash: $!";

    my $exists = exists $dbm_hash{ $key };

    untie %dbm_hash;
    $self->unlock;

    return unless $exists;
    $exists;
}

#---------------------------------------------------------------------
# UNTIE() supports tied hash access
#     (see perldoc perltie, The "untie" Gotcha)

sub UNTIE {
    my( $self, $count ) = @_;
    carp "untie attempted while $count inner references still exist" if $count;
}

sub DESTROY {}  # to keep from calling AUTOLOAD

#---------------------------------------------------------------------
# readlock()
#     Takes a file name, opens it for input, locks it, and stores the
#     open file handle in the object.  This file handle isn't really
#     used except for locking, so it's bit of a "lock token"
#
# Private method.

sub readlock {
    my( $self ) = @_;

    my $file = $self->dbm_lock_file;
    my $fh;

    # open $fh, '<', $file or croak qq/Can't open for read $file: $!/;
    sysopen( $fh, $file, O_RDONLY|O_CREAT ) or croak qq/Can't open for read $file: $!/;
    flock $fh, LOCK_SH   or croak qq/Can't lock shared $file: $!/;
    binmode $fh;

    $self->locked( $fh );
}

#---------------------------------------------------------------------
# writelock()
#     Takes a file name, opens it for read/write, locks it, and
#     stores the open file handle in the object.
#
# Private method.

sub writelock {
    my( $self ) = @_;

    my $file = $self->dbm_lock_file;
    my $fh;

    sysopen( $fh, $file, O_RDWR|O_CREAT ) or croak qq/Can't open for read-write $file: $!/;
    my $ofh = select( $fh ); $| = 1; select ( $ofh );  # flush buffers
    flock $fh, LOCK_EX                    or croak qq/Can't lock exclusive $file: $!/;
    binmode $fh;

    $self->locked( $fh );
}

#---------------------------------------------------------------------
# unlock()
#     closes the file handle -- the "lock token" in the object
#
# Private method.

sub unlock {
    my( $self ) = @_;

    my $file = $self->dbm_lock_file;
    my $fh   = $self->locked;

    close $fh or croak qq/Problem closing $file: $!/;
}

#---------------------------------------------------------------------
our $AUTOLOAD;
sub AUTOLOAD {

    my   $method = $AUTOLOAD;
         $method =~ s/.*:://;
    for( $method ) {
        croak qq/Unsupported method: $_/ unless /^
             name
            |dir
            |retrieve
            |retrieve_preamble
            |locate_record_data
            |history
            |userdata
            |howmany
            |lastkeynum
            |nextkeynum
            $/x;
    }

    my $self = shift;
    $self->datastore->$method( @_ );
}

1;  # returned

__END__

