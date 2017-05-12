#---------------------------------------------------------------------
  package FlatFile::DataStore;
#---------------------------------------------------------------------

=head1 NAME

FlatFile::DataStore - Perl module that implements a flatfile
datastore.

=head1 SYNOPSYS

 use FlatFile::DataStore;

 # new datastore object

 my $dir  = "/my/datastore/directory";
 my $name = "dsname";
 my $ds   = FlatFile::DataStore->new( { dir => $dir, name => $name } );

 # create a record

 my $record_data = "This is a test record.";
 my $user_data   = "Test1";
 my $record = $ds->create( {
     data => \$record_data,
     user => $user_data,
     } );
 my $record_number = $record->keynum;

 # retrieve it

 $record = $ds->retrieve( $record_number );

 # update it

 $record->data( "Updating the test record." );
 $record = $ds->update( $record );

 # delete it

 $record = $ds->delete( $record );

 # get its history

 my @records = $ds->history( $record_number );

=head1 DESCRIPTION

FlatFile::DataStore implements a simple flatfile datastore.  When you
create (store) a new record, it is appended to the flatfile.  When you
update an existing record, the existing entry in the flatfile is
flagged as updated, and the updated record is appended to the
flatfile.  When you delete a record, the existing entry is flagged as
deleted, and a "delete record" is I<appended> to the flatfile.

The result is that all versions of a record are retained in the
datastore, and running a history will return all of them.  Another
result is that each record in the datastore represents a transaction:
create, update, or delete.

Methods support the following actions:

 - create
 - retrieve
 - update
 - delete
 - history

Additionally, FlatFile::DataStore::Utils provides the
methods

 - validate
 - migrate

and others.

See FlatFile::DataStore::Tiehash for a tied interface.

=head1 VERSION

FlatFile::DataStore version 1.03

=cut

our $VERSION = '1.03';

use 5.008003;
use strict;
use warnings;

use URI::Escape;
use File::Path;
use Fcntl qw(:DEFAULT :flock);
use Digest::MD5 qw(md5_hex);
use Carp;

use FlatFile::DataStore::Preamble;
use FlatFile::DataStore::Record;
use FlatFile::DataStore::Toc;
use Math::Int2Base qw( base_chars int2base base2int );

use Data::Omap qw( :ALL );
sub untaint;

#---------------------------------------------------------------------
# globals:

my %Preamble = qw(
    indicator   1
    transind    1
    date        1
    transnum    1
    keynum      1
    reclen      1
    thisfnum    1
    thisseek    1
    prevfnum    1
    prevseek    1
    nextfnum    1
    nextseek    1
    user        1
    );

my %Optional = qw(
    dirmax      1
    dirlev      1
    tocmax      1
    keymax      1
    prevfnum    1
    prevseek    1
    nextfnum    1
    nextseek    1
    userdata    1
    );

# attributes that we generate (vs. user-supplied)
my %Generated = qw(
    uri         1
    crud        1
    userlen     1
    dateformat  1
    specs       1
    regx        1
    preamblelen 1
    fnumlen     1
    fnumbase    1
    translen    1
    transbase   1
    keylen      1
    keybase     1
    toclen      1
    datamax     1
    tocs        1
    );

# all attributes, including some more user-supplied ones
my %Attrs = ( %Preamble, %Optional, %Generated, qw(
    name        1
    dir         1
    desc        1
    recsep      1
    ) );

my $Ascii_chars = qr/^[ -~]+$/;  # i.e., printables

#---------------------------------------------------------------------

=head1 CLASS METHODS

=head2 FlatFile::DataStore->new();

Constructs a new FlatFile::DataStore object.

Accepts hash ref giving values for C<dir> and C<name>.

 my $ds = FlatFile::DataStore->new(
     { dir  => $dir,
       name => $name,
     } );

To initialize a new datastore, edit the "$dir/$name.uri" file
and enter a configuration URI (as the only line in the file),
or pass the URI as the value of the C<uri> parameter, e.g.,

 my $ds = FlatFile::DataStore->new(
     { dir  => $dir,
       name => $name,
       uri  => join( ";" =>
           "http://example.com?name=$name",
           "desc=My%20Data%20Store",
           "defaults=medium",
           "user=8-%20-%7E",
           "recsep=%0A",
           ),
     } );

(See URI Configuration below.)

Also accepts a C<userdata> parameter, which sets the default user
data for this instance, e.g.,

 my $ds = FlatFile::DataStore->new(
     { dir  => $dir,
       name => $name,
       userdata => ':',
     } );

Returns a reference to the FlatFile::DataStore object.

=cut

sub new {
    my( $class, $parms ) = @_;

    my $self = bless {}, $class;

    $self = $self->init( $parms ) if $parms;  # $self could change ...
    return $self;
}

#---------------------------------------------------------------------
# 
# =head2 init(), called by new() to initialize a datastore object
# 
# Parms (from hash ref):
# 
#     dir  ... the directory where the datastore lives
#     name ... the name of the datastore
#     uri  ... a uri to be used to configure the datastore
# 
# If dir/name.uri exists, init() will load its values.
# If uri is passed in, it will be used to initialize the datastore
# only if:
#
#     1) there isn't a .uri file, or
#     2) the .uri file is one line long, or
#     3) the .uri file has more lines (4) but no data files exist yet
# 
# Private method.
# 
# =cut
#

sub init {
    my( $self, $parms ) = @_;

    my $dir  = $parms->{'dir'};
    my $name = $parms->{'name'};

    croak qq/Need "dir" and "name"/
        unless defined $dir and defined $name;

    croak qq/Directory doesn't exist: $dir/
        unless -d $dir;

    $self->dir( $dir );
    $self->name( $name );

    # uri file may be
    # - one line: just the uri, or
    # - four lines: uri, object, uri_md5, object_md5
    #
    # if new_uri and uri file has
    # - one line ... new_uri can replace old one
    # - four lines (and new_uri is different) ...
    #   new_uri can replace the old uri (and object)
    #   but only if there aren't any data files yet

    my $new_uri = $parms->{'uri'};

    my $uri_file = "$dir/$name.uri";
    my( $uri, $obj, $uri_md5, $obj_md5 );

    if( -e $uri_file ) {
        my @lines = $self->read_file( $uri_file ); chomp @lines;

        if( @lines == 4 ) {
            ( $uri, $obj, $uri_md5, $obj_md5 ) = @lines;

            croak qq/URI MD5 check failed/    unless $uri_md5 eq md5_hex( $uri );
            croak qq/Object MD5 check failed/ unless $obj_md5 eq md5_hex( $obj );

            # new uri ok only if no data has been added yet
            if( $new_uri         and
                $new_uri ne $uri and
                not -e $self->which_datafile( 1 ) ) {
                    $uri = $new_uri;
            }
            else {
                untaint trusted => $obj;
                $self = eval $obj;  # note: *new* $self

                croak qq/Problem with URI file, $uri_file: $@/ if $@;

                $self->dir( $dir );  # dir not in object
            }
        }
        elsif( @lines == 1 ) {
            $uri = $new_uri || shift @lines;
        }
        else {
            croak qq/Invalid URI file: $uri_file/;
        }
    }
    else {
        $uri = $new_uri;
    }

    # if there isn't an object, the datastore hasn't been
    # initialized yet, so if we have a uri (either passed in
    # or read from the uri file, let's initialize it
    # (we could have an instance that only contains name and dir)

    if( !$obj and $uri ) {

        $self->uri( $uri );

        # Note: 'require', not 'use'.  This isn't
        # a "true" module -- we're just bringing in
        # some more FlatFile::DataStore methods.

        require FlatFile::DataStore::Initialize;

        my $uri_parms = $self->burst_query( \%Preamble );
        for my $attr ( keys %$uri_parms ) {

            croak qq/Unrecognized parameter: $attr/ unless $Attrs{ $attr };

            # (note: using $attr as method name here)
            $self->$attr( $uri_parms->{ $attr } );
        }

        # check that all fnums and seeks are the same ...
        #
        # (note: prevfnum, prevseek, nextfnum, and nextseek are
        # optional, but if you have one of them, you must have
        # all four, so checking for one of them here, i.e.,
        # prevfnum, is enough)

        if( $self->prevfnum ) {

            croak qq/fnum parameters differ/
                unless $self->thisfnum eq $self->prevfnum and
                       $self->thisfnum eq $self->nextfnum;

            croak qq/seek parameters differ/
                unless $self->thisseek eq $self->prevseek and
                       $self->thisseek eq $self->nextseek;

        }

        # now for some generated attributes ...
        my( $len, $base );

        # (we can use thisfnum because all fnums are the same)
        ( $len, $base ) = split /-/, $self->thisfnum;
        $self->fnumlen(    $len                        );
        $self->fnumbase(   $base                       );

        ( $len, $base ) = split /-/, $self->transnum;
        $self->translen(   $len                        );
        $self->transbase(  $base                       );

        ( $len, $base ) = split /-/, $self->keynum;
        $self->keylen(     $len                        );
        $self->keybase(    $base                       );

        $self->dateformat( (split /-/, $self->date)[1] );
        $self->regx(       $self->make_preamble_regx   );
        $self->crud(       $self->make_crud            );
        $self->tocs(       {}                          );
        $self->dir(        $dir                        );  # dir not in uri

        $self->toclen( 10          +  # blanks between parts
            3 *    $self->fnumlen  +  # datafnum, tocfnum, keyfnum
            2 *    $self->keylen   +  # numrecs keynum
            6 *    $self->translen +  # transnum and cruds
            length $self->recsep );

        # (note: we can use thisseek because all seeks are the same)
        ( $len, $base ) = split /-/, $self->thisseek;
        my $maxnum = substr( base_chars( $base ), -1) x $len;
        my $maxint = base2int $maxnum, $base;

        # if we give a datamax, it can't be larger than maxint
        if( my $max = $self->datamax ) {
            $self->datamax( convert_max( $max ) );
            if( $self->datamax > $maxint ) {

                croak join '' =>
                    "datamax too large: (", $self->datamax, ") ",
                    "thisseek is ", $self->thisseek,
                    " so maximum datamax is $maxnum base-$base ",
                    "(decimal: $maxint)";
            }
        }
        else {
            $self->datamax( $maxint );
        }

        if( my $max = $self->dirmax ) {
            $self->dirmax( convert_max( $max ) );
            $self->dirlev( 1 ) unless $self->dirlev;
        }

        if( my $max = $self->keymax ) {
            $self->keymax( convert_max( $max ) );
        }

        if( my $max = $self->tocmax ) {
            $self->tocmax( convert_max( $max ) );
        }

        if( my $user = $self->user ) {
            $self->userlen( (split /-/, $user)[0] );
        }

        for my $attr ( keys %Attrs ) {
            croak qq/Uninitialized attribute: $attr/
                if not $Optional{ $attr } and not defined $self->$attr;
        }

        $self->initialize;
    }

    for( $parms->{'userdata'} ) {
        $self->userdata( $_ ) if defined; 
    }

    return $self;  # this is either the same self or a new self
}

#---------------------------------------------------------------------

=head1 OBJECT METHODS, Record Processing (CRUD)

=head2 create( $record )

 or create( { data => \$record_data, user => $user_data } )
 or create( { record => $record[, data => \$record_data][, user => $user_data] } )

Creates a record. If the parameter is a record object,
the record data and user data will be gotten from it.
Otherwise, if the parameter is a hash reference, the
expected keys are:

 - record => FlatFile::DataStore::Record object
 - data => string or scalar reference
 - user => string

If no record is passed, both 'data' and 'user' are required.
Otherwise, if a record is passed, the record data and user
data will be gotten from it unless one or both are explicitly
provided.

Returns a Flatfile::DataStore::Record object.

Note: the record data (but not the user data) is stored in the
FF::DS::Record object as a scalar reference.  This is done for
efficiency in the cases where the record data may be very large.
Likewise, the data parm passed to create() may be a scalar
reference.

=cut

sub create {
    my $self = shift;
    my( $data_ref, $user_data ) = $self->normalize_parms( @_ );

    # get next keynum
    #   (we don't call nextkeynum(), because we need the
    #   $top_toc object for other things, too)

    my $top_toc = $self->new_toc( { int => 0 } );
    my $keyint  = $top_toc->keynum + 1;
    my $keylen  = $self->keylen;
    my $keybase = $self->keybase;
    my $keynum  = int2base $keyint, $keybase, $keylen;

    croak qq/Database exceeds configured size, keynum too long: $keynum/
        if length $keynum > $keylen;

    # get keyfile
    #   need to lock files before getting seek positions
    #   want to lock keyfile before datafile

    my( $keyfile, $keyfint ) = $self->keyfile( $keyint );
    my $keyfh                = $self->locked_for_write( $keyfile );
    my $keyseek              = -s $keyfile;  # seekpos into keyfile

    # get datafile ($datafnum may increment)
    my $datafnum = $top_toc->datafnum || 1;  # (||1 only in create)
    $datafnum    = int2base $datafnum, $self->fnumbase, $self->fnumlen;
    my $reclen   = length $$data_ref;

    my $datafile;
    ( $datafile, $datafnum ) = $self->datafile( $datafnum, $reclen );
    my $datafh               = $self->locked_for_write( $datafile );
    my $dataseek             = -s $datafile;  # seekpos into datafile

    # get next transaction number
    my $transint = $self->nexttransnum( $top_toc );

    # make new record
    my $record = $self->new_record( {
        data     => $data_ref,
        preamble => {
            indicator => $self->crud->{'create'},
            transind  => $self->crud->{'create'},
            date      => now( $self->dateformat ),
            transnum  => $transint,
            keynum    => $keyint,
            reclen    => $reclen,
            thisfnum  => $datafnum,
            thisseek  => $dataseek,
            user      => $user_data,
            } } );

    # write record to datafile
    my $preamble = $record->preamble_string;
    my $dataline = $preamble . $$data_ref . $self->recsep;
    $self->write_bytes( $datafh, $dataseek, \$dataline );

    # write preamble to keyfile
    $self->write_bytes( $keyfh, $keyseek, \($preamble . $self->recsep) );
    
    # update table of contents (toc) file
    my $toc = $self->new_toc( { num => $datafnum } );

    # (note: datafnum and tocfnum are set in toc->new)
    $toc->keyfnum(   $keyfint          );
    $toc->keynum(    $keyint           );
    $toc->transnum(  $transint         );
    $toc->create(    $toc->create  + 1 );
    $toc->numrecs(   $toc->numrecs + 1 );
    $toc->write_toc( $toc->datafnum    );

    # update top toc
    $top_toc->datafnum( $toc->datafnum        );
    $top_toc->keyfnum(  $toc->keyfnum         );
    $top_toc->tocfnum(  $toc->tocfnum         );
    $top_toc->keynum(   $toc->keynum          );
    $top_toc->transnum( $toc->transnum        );
    $top_toc->create(   $top_toc->create  + 1 );
    $top_toc->numrecs(  $top_toc->numrecs + 1 );

    $top_toc->write_toc( 0 );

    close $datafh or die "Can't close $datafile: $!";
    close $keyfh  or die "Can't close $keyfile: $!";

    return $record;
}

#---------------------------------------------------------------------

=head2 retrieve( $num[, $pos] )

Retrieves a record.  The parm C<$num> may be one of

 - a key number, i.e., record sequence number
 - a file number

The parm C<$pos> is required if C<$num> is a file number.

Here's why: When $num is a record key sequence number (key number), a
preamble is retrieved from the datastore key file.  In that preamble
is the file number and seek position where the record data may be
gotten.  Otherwise, when $num is a file number, the application (you)
must supply the seek position into that file.  Working from an array
of record history is the most likely time you would do this.

Returns a Flatfile::DataStore::Record object.

=cut

sub retrieve {
    my( $self, $num, $pos ) = @_;

    for( $num ) {
        croak qq/Not a number: '$_'/ unless m{^ [0-9]+ $}x;
    }

    my $fnum;
    my $seekpos;
    my $keystring;

    if( defined $pos ) {
        for( $pos ) {
            croak qq/Not a number: '$_'/ unless m{^ [0-9]+ $}x;
        }
        $fnum    = $num;
        $seekpos = $pos;
    }
    else {
        my $keynum  = $num;
        my $recsep  = $self->recsep;
        my $keyseek = $self->keyseek( $keynum );

        my $keyfile = $self->keyfile( $keynum );
        my $keyfh   = $self->locked_for_read( $keyfile );

        my $trynum  = $self->lastkeynum;

        croak qq/Record doesn't exist: $keynum/ if $keynum > $trynum;

        $keystring = $self->read_preamble( $keyfh, $keyseek );
        close $keyfh or die "Can't close $keyfile: $!";

        my $parms  = $self->burst_preamble( $keystring );

        $fnum    = $parms->{'thisfnum'};
        $seekpos = $parms->{'thisseek'};
    }

    my $datafile = $self->which_datafile( $fnum );
    my $datafh   = $self->locked_for_read( $datafile );
    my $record   = $self->read_record( $datafh, $seekpos );
    close $datafh or die "Can't close $datafile: $!";

    # if we got the record via key file, check that preambles match
    if( $keystring ) {
        my $string = $record->preamble_string;

        croak qq/Mismatch: "$string" ne "$keystring"/ if $string ne $keystring;
    }

    return $record;
}

#---------------------------------------------------------------------

=head2 retrieve_preamble( $keynum )

Retrieves a preamble.  The parm C<$keynum> is a key number, i.e.,
record sequence number

Returns a Flatfile::DataStore::Preamble object.

This method allows getting information about the record, e.g., if
it's deleted, what's in the user data, etc., without the overhead of
retrieving the full record data.

=cut

sub retrieve_preamble {
    my( $self, $keynum ) = @_;

    for( $keynum ) {
        croak qq/Not a number: '$_'/ unless m{^ [0-9]+ $}x;
    }

    my $keyseek = $self->keyseek( $keynum );
    my $keyfile = $self->keyfile( $keynum );
    my $keyfh   = $self->locked_for_read( $keyfile );

    my $trynum  = $self->lastkeynum;

    croak qq/Record doesn't exist: $keynum/ if $keynum > $trynum;

    my $keystring = $self->read_preamble( $keyfh, $keyseek );
    close $keyfh or die "Can't close $keyfile: $!";

    my $preamble  = $self->new_preamble( { string => $keystring } );

    return $preamble;
}

#---------------------------------------------------------------------

=head2 locate_record_data( $num[, $pos] )

Rather than retrieving a record, this subroutine positions you at the
record data in the data file.  This might be handy if, for example,
the record data is text, and you just want part of it.  You can scan
the data and get what you want without having to read the entire
record.  Or the data might be XML and you could parse it using SAX
without reading it all into memory.

The parm C<$num> may be one of

 - a key number, i.e., record sequence number
 - a file number

The parm C<$pos> is required if C<$num> is a file number.  See
retrieve() above for why.

Returns a list containing the file handle (which is already locked
for reading in binmode), the seek position, and the record length.

You will be positioned at the seek position, so you could begin
reading data, e.g., via C<< <$fh> >>:

    my( $fh, $pos, $len ) = $ds->locate_record_data( $keynum );
    my $got;
    while( <$fh> ) {
        last if ($got += length) > $len;  # in case we read the recsep
        # [do something with $_ ...]
        last if $got == $len;
    }
    close $fh;

The above loop assumes you know each line of the data ends in a
newline.  Also keep in mind that the file is opened in binmode,
so you will be reading bytes (octets), not necessarily characters.
Decoding these octets is up to you.

XXX ("opened in binmode"?) does that make the example wrong
    wrt non-unix OS's

=cut

sub locate_record_data {
    my( $self, $num, $pos ) = @_;

    for( $num ) {
        croak qq/Not a number: '$_'/ unless m{^ [0-9]+ $}x;
    }

    my $fnum;
    my $seekpos;
    my $keystring;
    my $reclen;

    if( defined $pos ) {
        for( $pos ) {
            croak qq/Not a number: '$_'/ unless m{^ [0-9]+ $}x;
        }
        $fnum    = $num;
        $seekpos = $pos;
    }
    else {
        my $keynum  = $num;
        my $recsep  = $self->recsep;
        my $keyseek = $self->keyseek( $keynum );

        my $keyfile = $self->keyfile( $keynum );
        my $keyfh   = $self->locked_for_read( $keyfile );

        my $trynum  = $self->lastkeynum;

        croak qq/Record doesn't exist: $keynum/ if $keynum > $trynum;

        $keystring = $self->read_preamble( $keyfh, $keyseek );
        close $keyfh or die "Can't close $keyfile: $!";

        my $parms  = $self->burst_preamble( $keystring );

        $fnum    = $parms->{'thisfnum'};
        $seekpos = $parms->{'thisseek'};
        $reclen  = $parms->{'reclen'};
    }

    my $datafile = $self->which_datafile( $fnum );
    my $datafh   = $self->locked_for_read( $datafile );
    my $preamble = $self->read_preamble( $datafh, $seekpos );

    # if we got the record via key file, check that preambles match
    if( $keystring ) {

        croak qq/Mismatch: "$preamble" ne "$keystring"/
            if $preamble ne $keystring;
    }

    # if not via key file, we still need the record length
    else {
        my $parms  = $self->burst_preamble( $preamble );
        $reclen  = $parms->{'reclen'};
    }

    $seekpos += $self->preamblelen;  # skip to record data

    sysseek $datafh, $seekpos, 0 or

        croak qq/Can't seek to $seekpos in $datafile: $!/;

    return $datafh, $seekpos, $reclen;
}

#---------------------------------------------------------------------

=head2 update( $record )

 or update( { string => $preamble_string, data => \$record_data, user => $user_data } )
 or update( { preamble => $preamble_obj, data => \$record_data, user => $user_data } )
 or update( { record => $record_obj
    [, preamble => $preamble_obj]
    [, string   => $preamble_string]
    [, data     => \$record_data]
    [, user     => $user_data] } )

Updates a record. If the parameter is a record object,
the preamble, record data, and user data will be gotten
from it.  Otherwise, if the parameter is a hash reference,
the expected keys are:

 - record   => FlatFile::DataStore::Record object
 - preamble => FlatFile::DataStore::Preamble object
 - string   => a preamble string (the string attribute of a preamble object)
 - data     => string or scalar reference
 - user     => string

If no record is passed, 'preamble' (or 'string'), 'data', and
'user' are required.  Otherwise, if a record is passed, the
preamble, record data and user data will be gotten from it
unless any of them are explicitly provided.

Returns a Flatfile::DataStore::Record object.

=cut

sub update {
    my $self = shift;
    my( $data_ref, $user_data, $pr_obj ) = $self->normalize_parms( @_ );

    croak qq/Must have at least a previous preamble for update/
        unless $pr_obj;

    my $prevnext = $self->prevfnum;  # boolean

    my $prevpreamble = $pr_obj->string;
    my $keyint       = $pr_obj->keynum;
    my $prevind      = $pr_obj->indicator;
    my $prevfnum     = $pr_obj->thisfnum;
    my $prevseek     = $pr_obj->thisseek;

    # update is okay for these:
    my $create = $self->crud->{'create'};
    my $update = $self->crud->{'update'};
    my $delete = $self->crud->{'delete'};

    croak qq/update not allowed: $prevind/
        unless $prevind =~ /[\Q$create$update$delete\E]/;

    # get keyfile
    #   need to lock files before getting seek positions
    #   want to lock keyfile before datafile

    my( $keyfile, $keyfint ) = $self->keyfile( $keyint );
    my $keyfh                = $self->locked_for_write( $keyfile );
    my $keyseek              = $self->keyseek( $keyint );

    my $try = $self->read_preamble( $keyfh, $keyseek );

    croak qq/Mismatch: "$try" ne "$prevpreamble"/ unless $try eq $prevpreamble;

    # get datafile ($datafnum may increment)
    my $top_toc  = $self->new_toc( { int => 0 } );
    my $datafnum = int2base $top_toc->datafnum, $self->fnumbase, $self->fnumlen;
    my $reclen   = length $$data_ref;

    my $datafile;
    ( $datafile, $datafnum ) = $self->datafile( $datafnum, $reclen );
    my $datafh               = $self->locked_for_write( $datafile );
    my $dataseek             = -s $datafile;  # seekpos into datafile

    # get next transaction number
    my $transint = $self->nexttransnum( $top_toc );

    # make new record
    my $preamble_hash = {
        indicator => $update,
        transind  => $update,
        date      => now( $self->dateformat ),
        transnum  => $transint,
        keynum    => $keyint,
        reclen    => $reclen,
        thisfnum  => $datafnum,
        thisseek  => $dataseek,
        user      => $user_data,
        };
    if( $prevnext ) {
        $preamble_hash->{'prevfnum'} = $prevfnum;
        $preamble_hash->{'prevseek'} = $prevseek;
    }
    my $record = $self->new_record( {
        data     => $data_ref,
        preamble => $preamble_hash,
        } );

    # write record to datafile
    my $preamble = $record->preamble_string;
    my $dataline = $preamble . $$data_ref . $self->recsep;
    $self->write_bytes( $datafh, $dataseek, \$dataline );

    # write preamble to keyfile (recsep there already)
    $self->write_bytes( $keyfh, $keyseek, \$preamble );

    # update the old preamble
    if( $prevnext ) {
        $prevpreamble = $self->update_preamble( $prevpreamble, {
            indicator => $self->crud->{ 'oldupd' },
            nextfnum  => $datafnum,
            nextseek  => $dataseek,
            } );
        my $prevdatafile = $self->which_datafile( $prevfnum );
        if( $prevdatafile eq $datafile ) {
            $self->write_bytes( $datafh, $prevseek, \$prevpreamble );
        }
        else {
            my $prevdatafh = $self->locked_for_write( $prevdatafile );
            $self->write_bytes( $prevdatafh, $prevseek, \$prevpreamble );
            close $prevdatafh or die "Can't close $prevdatafile: $!";
        }
    }

    # update table of contents (toc) file
    my $toc = $self->new_toc( { num => $datafnum } );

    # note: datafnum and tocfnum are set in toc->new
    $toc->keyfnum(  $top_toc->keyfnum );  # keep last nums going
    $toc->keynum(   $top_toc->keynum  );
    $toc->transnum( $transint         );
    $toc->update(   $toc->update  + 1 );
    $toc->numrecs(  $toc->numrecs + 1 );

    # was the previous record in another data file?
    if( $prevnext ) {
        if( $prevfnum ne $datafnum ) {
            my $prevtoc = $self->new_toc( { num => $prevfnum } );
            $prevtoc->oldupd(    $prevtoc->oldupd  + 1 );
            $prevtoc->numrecs(   $prevtoc->numrecs - 1 ) if $prevind ne $delete;
            $prevtoc->write_toc( $prevtoc->datafnum    );
        }
        else {
            $toc->oldupd(  $toc->oldupd  + 1 );
            $toc->numrecs( $toc->numrecs - 1 ) if $prevind ne $delete;
        }
    }
    else {
        $toc->numrecs( $toc->numrecs - 1 ) if $prevind ne $delete;
    }

    $toc->write_toc( $toc->datafnum );

    # update top toc
    $top_toc->datafnum( $toc->datafnum        );
    $top_toc->tocfnum(  $toc->tocfnum         );
    $top_toc->transnum( $toc->transnum        );
    $top_toc->update(   $top_toc->update  + 1 );
    $top_toc->oldupd(   $top_toc->oldupd  + 1 ) if $prevnext;
    $top_toc->numrecs(  $top_toc->numrecs + 1 ) if $prevind eq $delete;

    $top_toc->write_toc( 0 );

    close $datafh or die "Can't close $datafile: $!";
    close $keyfh  or die "Can't close $keyfile: $!";

    return $record;
}

#---------------------------------------------------------------------

=head2 delete( $record )

 or delete( { string => $preamble_string, data => \$record_data, user => $user_data } )
 or delete( { preamble => $preamble_obj, data => \$record_data, user => $user_data } )
 or delete( { record => $record_obj
    [, preamble => $preamble_obj]
    [, string   => $preamble_string]
    [, data     => \$record_data]
    [, user     => $user_data] } )

Deletes a record.  The parameters are the same as for update().

Returns a Flatfile::DataStore::Record object.

=cut

sub delete {
    my $self = shift;
    my( $data_ref, $user_data, $pr_obj ) = $self->normalize_parms( @_ );

    croak qq/Must have at least a previous preamble for delete/
        unless $pr_obj;

    my $prevnext = $self->prevfnum;  # boolean

    my $prevpreamble = $pr_obj->string;
    my $keyint       = $pr_obj->keynum;
    my $prevind      = $pr_obj->indicator;
    my $prevfnum     = $pr_obj->thisfnum;
    my $prevseek     = $pr_obj->thisseek;

    # delete is okay for these:
    my $create = $self->crud->{'create'};
    my $update = $self->crud->{'update'};

    croak qq/delete not allowed: $prevind/
        unless $prevind =~ /[\Q$create$update\E]/;

    # get keyfile
    # need to lock files before getting seek positions
    # want to lock keyfile before datafile

    my( $keyfile, $keyfint ) = $self->keyfile( $keyint );
    my $keyfh                = $self->locked_for_write( $keyfile );
    my $keyseek              = $self->keyseek( $keyint );

    my $try = $self->read_preamble( $keyfh, $keyseek );

    croak qq/Mismatch: "$try" ne "$prevpreamble"/ unless $try eq $prevpreamble;

    # get datafile ($datafnum may increment)
    my $top_toc  = $self->new_toc( { int => 0 } );
    my $datafnum = int2base $top_toc->datafnum, $self->fnumbase, $self->fnumlen;
    my $reclen   = length $$data_ref;

    my $datafile;
    ( $datafile, $datafnum ) = $self->datafile( $datafnum, $reclen );
    my $datafh               = $self->locked_for_write( $datafile );
    my $dataseek             = -s $datafile;  # seekpos into datafile

    # get next transaction number
    my $transint = $self->nexttransnum( $top_toc );

    # make new record
    my $delete = $self->crud->{'delete'};
    my $preamble_hash = {
        indicator => $delete,
        transind  => $delete,
        date      => now( $self->dateformat ),
        transnum  => $transint,
        keynum    => $keyint,
        reclen    => $reclen,
        thisfnum  => $datafnum,
        thisseek  => $dataseek,
        user      => $user_data,
        };
    if( $prevnext ) {
        $preamble_hash->{'prevfnum'} = $prevfnum;
        $preamble_hash->{'prevseek'} = $prevseek;
    }
    my $record = $self->new_record( {
        data     => $data_ref,
        preamble => $preamble_hash,
        } );

    # write record to datafile
    my $preamble = $record->preamble_string;
    my $dataline = $preamble . $$data_ref . $self->recsep;
    $self->write_bytes( $datafh, $dataseek, \$dataline );

    # write preamble to keyfile (recsep there already)
    $self->write_bytes( $keyfh, $keyseek, \$preamble );

    # update the old preamble
    if( $prevnext ) {
        $prevpreamble = $self->update_preamble( $prevpreamble, {
            indicator => $self->crud->{ 'olddel' },
            nextfnum  => $datafnum,
            nextseek  => $dataseek,
            } );
        my $prevdatafile = $self->which_datafile( $prevfnum );
        if( $prevdatafile eq $datafile ) {
            $self->write_bytes( $datafh, $prevseek, \$prevpreamble );
        }
        else {
            my $prevdatafh = $self->locked_for_write( $prevdatafile );
            $self->write_bytes( $prevdatafh, $prevseek, \$prevpreamble );
            close $prevdatafh or die "Can't close $prevdatafile: $!";
        }
    }

    # update table of contents (toc) file
    my $toc = $self->new_toc( { num => $datafnum } );

    # note: datafnum and tocfnum are set in toc->new
    $toc->keyfnum(  $top_toc->keyfnum );  # keep last nums going
    $toc->keynum(   $top_toc->keynum  );
    $toc->transnum( $transint         );
    $toc->delete(   $toc->delete + 1  );

    # was the previous record in another data file?
    if( $prevnext ) {
        if( $prevfnum ne $datafnum ) {
            my $prevtoc = $self->new_toc( { num => $prevfnum } );
            $prevtoc->olddel(    $prevtoc->olddel  + 1 );
            $prevtoc->numrecs(   $prevtoc->numrecs - 1 );
            $prevtoc->write_toc( $prevtoc->datafnum    );
        }
        else {
            $toc->olddel(  $toc->olddel  + 1 );
            $toc->numrecs( $toc->numrecs - 1 );
        }
    }
    else {
        $toc->numrecs( $toc->numrecs - 1 );
    }

    $toc->write_toc( $toc->datafnum );

    # update top toc
    $top_toc->datafnum( $toc->datafnum        );
    $top_toc->tocfnum(  $toc->tocfnum         );
    $top_toc->transnum( $toc->transnum        );
    $top_toc->delete(   $top_toc->delete  + 1 );
    $top_toc->olddel(   $top_toc->olddel  + 1 ) if $prevnext;
    $top_toc->numrecs(  $top_toc->numrecs - 1 );

    $top_toc->write_toc( 0 );

    close $datafh or die "Can't close $datafile: $!";
    close $keyfh  or die "Can't close $keyfile: $!";

    return $record;
}

#---------------------------------------------------------------------
# 
# =head2 normalize_parms( $parms )
# 
# Parses parameters for create(), update(), and delete()
# 
# If the parameter is a record object, then the preamble, record data,
# and user data will be gotten from it.
# 
# Otherwise, if the parameter is a hash reference, the expected keys
# are:
# 
#     - record   => FlatFile::DataStore::Record object
#     - preamble => FlatFile::DataStore::Preamble object
#     - string   => a preamble string (the string attribute of a preamble object)
#     - data     => string or scalar reference
#     - user     => string
# 
# Returns record data (scalar ref), user data, preamble object
# 
# Note that create() ignores the returned preamble, but update() and
# delete() do not.
# 
# Private method.
# 
# =cut
# 

sub normalize_parms {
    my( $self, $parms ) = @_;

    croak qq/Bad call/ unless $parms;

    my( $data_ref, $user_data, $preamble );

    my $reftype = ref $parms;
    if( $reftype =~ /Record/ ) {
        $data_ref  = $parms->dataref;
        $user_data = $parms->user;
        $preamble  = $parms->preamble;
    }
    elsif( $reftype eq "HASH" ) {
        for( $parms->{'data'} ) {
            if( ref ) { $data_ref = $_ }
            else      { $data_ref = \$_ if defined }
        }
        for( $parms->{'user'} )  {
            $user_data = $_ if defined;
        }
        for( $parms->{'string'} ) {
            $preamble = $self->new_preamble( { string => $_ } )
                if defined;
        }
        for( $parms->{'preamble'} ) {
            $preamble = $_ if defined;
        }
        for( $parms->{'record'} ) {
            last unless defined;
            $data_ref  = $_->dataref  unless $data_ref;
            $user_data = $_->user     unless defined $user_data;
            $preamble  = $_->preamble unless $preamble;
        }
    }
    else {
        croak qq/Parameter must be a hashref or a record object/;
    }
    croak qq/No record data/ unless $data_ref;

    return $data_ref, $user_data, $preamble;
}

#---------------------------------------------------------------------

=head2 exists()

Tests if a datastore exists.  Currently, a datastore "exists" if there
is a .uri file -- whether the file is valid or not.

May be called on a datastore object, e.g.,

    $ds->exists()

Or may be called as a class method, e.g.,

    FlatFile::DataStore->exists({
        name => 'example',
        dir  => '/dbs/example',
        })

If called as a class method, you must pass a hashref that provides
values for 'name' and 'dir'.

=cut

sub exists {
    my( $self, $parms ) = @_;

    my( $dir, $name );

    if( ref $self ) {  # object method
        $dir  = $self->dir;
        $name = $self->name;

        # empty object, so datastore doesn't exist
        return unless $dir and $name;
    }

    else {  # class method

        if( $parms ) {
            $dir  = $parms->{'dir'};
            $name = $parms->{'name'};
        }

        # required for class method
        croak qq/Need dir and name/ unless $dir and $name;
    }

    -e "$dir/$name.uri";  # returned
}

#---------------------------------------------------------------------

=head2 history( $keynum )

Retrieves a record's history.  The parm C<$keynum> is always a key
number, i.e., a record sequence number.

Returns an array of FlatFile::DataStore::Record objects.

The first element of this array is the current record.  The last
element is the original record.  That is, the array is in reverse
chronological order.

=cut

sub history {
    my( $self, $keynum ) = @_;

    for( $keynum ) {
        croak qq/Not a number: '$_'/ unless m{^ [0-9]+ $}x;
    }

    my @history;

    my $rec = $self->retrieve( $keynum );
    push @history, $rec;

    my $prevfnum = $rec->prevfnum;
    my $prevseek = $rec->prevseek;

    while( $prevfnum ) {

        my $rec = $self->retrieve( $prevfnum, $prevseek );
        push @history, $rec;

        $prevfnum = $rec->prevfnum;
        $prevseek = $rec->prevseek;
    }

    return @history;
}

#---------------------------------------------------------------------

=head1 OBJECT METHODS, Accessors

In the specifications below, square braces ([]) denote optional
parameters, not anonymous arrays, e.g., C<[$omap]> indicates that
C<$omap> is optional, instead of implying that you need to pass it
inside an array.

=head2 $ds->specs( [$omap] )

Sets and returns the C<specs> attribute value if C<$omap> is given,
otherwise just returns the value.

An 'omap' is an ordered hash as defined in

    http://yaml.org/type/omap.html

and implemented here using Data::Omap.  That is, it's an array of
single-key hashes.  This ordered hash contains the specifications for
constructing and parsing a record preamble as defined in the name.uri
file.

In list context, the value returned is a list of hashrefs.  In scalar
context, the value returned is an arrayref containing the list of 
hashrefs.

=cut

sub specs {
    my( $self, $omap ) = @_;
    for( $self->{specs} ) {
        if( $omap ) {

            croak qq/Invalid omap: /.omap_errstr()
                unless omap_is_valid( $omap );

            $_ = $omap;
        }
        return unless defined;
        return @$_ if wantarray;
        return $_;
    }
}

#---------------------------------------------------------------------

=head2 $ds->dir( [$dir] )

Sets and returns the C<dir> attribute value if C<$dir> is given,
otherwise just returns the value.

If C<$dir> is given and is a null string, the C<dir> object attribute
is removed from the object.  If C<$dir> is not null, the directory
must already exist.  In other words, this module will not create the
directory where the database is to be stored.

=cut

sub dir {
    my( $self, $dir ) = @_;
    if( defined $dir and $dir eq "" ) { delete $self->{dir} }
    else {
        for( $self->{dir} ) {
            if( defined $dir ) {

                croak qq/Directory doesn't exist: $dir/ unless -d $dir;

                $_ = $dir
            }
            return $_;
        }
    }
}

#---------------------------------------------------------------------

=head2 Preamble accessors (from the uri)

The following methods set and return their respective attribute values
if C<$value> is given.  Otherwise, they just return the value.

 $ds->indicator( [$value] );  # length-characters
 $ds->transind(  [$value] );  # length-characters
 $ds->date(      [$value] );  # length-format
 $ds->transnum(  [$value] );  # length-base
 $ds->keynum(    [$value] );  # length-base
 $ds->reclen(    [$value] );  # length-base
 $ds->thisfnum(  [$value] );  # length-base
 $ds->thisseek(  [$value] );  # length-base
 $ds->prevfnum(  [$value] );  # length-base
 $ds->prevseek(  [$value] );  # length-base
 $ds->nextfnum(  [$value] );  # length-base
 $ds->nextseek(  [$value] );  # length-base
 $ds->user(      [$value] );  # length-characters

=head2 Other accessors

 $ds->name(        [$value] ); # from uri, name of datastore
 $ds->desc(        [$value] ); # from uri, description of datastore
 $ds->recsep(      [$value] ); # from uri, character(s)
 $ds->uri(         [$value] ); # full uri as is
 $ds->preamblelen( [$value] ); # length of preamble string
 $ds->toclen(      [$value] ); # length of toc entry
 $ds->keylen(      [$value] ); # length of stored keynum
 $ds->keybase(     [$value] ); # base   of stored keynum
 $ds->translen(    [$value] ); # length of stored transaction number
 $ds->transbase(   [$value] ); # base   of stored transaction number
 $ds->fnumlen(     [$value] ); # length of stored file number
 $ds->fnumbase(    [$value] ); # base   of stored file number
 $ds->userlen(     [$value] ); # format from uri
 $ds->dateformat(  [$value] ); # format from uri
 $ds->regx(        [$value] ); # capturing regx for preamble string
 $ds->datamax(     [$value] ); # maximum bytes in a data file
 $ds->crud(        [$value] ); # hash ref, e.g.,

     {
        create => '+',
        oldupd => '#',
        update => '=',
        olddel => '*',
        delete => '-',
        '+' => 'create',
        '#' => 'oldupd',
        '=' => 'update',
        '*' => 'olddel',
        '-' => 'delete',
     }

 (logical actions <=> symbolic indicators)

=head2 Accessors for optional attributes

 $ds->dirmax(   [$value] );  # maximum files in a directory
 $ds->dirlev(   [$value] );  # number of directory levels
 $ds->tocmax(   [$value] );  # maximum toc entries
 $ds->keymax(   [$value] );  # maximum key entries
 $ds->userdata( [$value] );  # default user data

If no C<dirmax>, directories will keep being added to.

If no C<dirlev>, toc, key, and data files will reside in top-level
directory.  If C<dirmax> is given, C<dirlev> defaults to 1.

If no C<tocmax>, there will be only one toc file, which will grow
indefinitely.

If no C<keymax>, there will be only one key file, which will grow
indefinitely.

If no C<userdata>, will default to a null string (padded with spaces)
unless supplied another way.

=cut

sub indicator {for($_[0]->{indicator} ){$_=$_[1]if@_>1;return$_}}
sub transind  {for($_[0]->{transind}  ){$_=$_[1]if@_>1;return$_}}
sub date      {for($_[0]->{date}      ){$_=$_[1]if@_>1;return$_}}
sub transnum  {for($_[0]->{transnum}  ){$_=$_[1]if@_>1;return$_}}
sub keynum    {for($_[0]->{keynum}    ){$_=$_[1]if@_>1;return$_}}
sub reclen    {for($_[0]->{reclen}    ){$_=$_[1]if@_>1;return$_}}
sub thisfnum  {for($_[0]->{thisfnum}  ){$_=$_[1]if@_>1;return$_}}
sub thisseek  {for($_[0]->{thisseek}  ){$_=$_[1]if@_>1;return$_}}

# prevfnum, prevseek, nextfnum, nextseek are optional attributes;
# prevfnum() is set up to avoid autovivification, because it is
# the accessor used to test if these optional attributes are set

sub prevfnum {
    my $self = shift;
    return $self->{prevfnum} = $_[0] if @_;
    return $self->{prevfnum} if exists $self->{prevfnum};
}

sub prevseek  {for($_[0]->{prevseek}  ){$_=$_[1]if@_>1;return$_}}
sub nextfnum  {for($_[0]->{nextfnum}  ){$_=$_[1]if@_>1;return$_}}
sub nextseek  {for($_[0]->{nextseek}  ){$_=$_[1]if@_>1;return$_}}
sub user      {for($_[0]->{user}      ){$_=$_[1]if@_>1;return$_}}

sub name        {for($_[0]->{name}        ){$_=$_[1]if@_>1;return$_}}
sub desc        {for($_[0]->{desc}        ){$_=$_[1]if@_>1;return$_}}
sub recsep      {for($_[0]->{recsep}      ){$_=$_[1]if@_>1;return$_}}
sub uri         {for($_[0]->{uri}         ){$_=$_[1]if@_>1;return$_}}
sub userlen     {for($_[0]->{userlen}     ){$_=$_[1]if@_>1;return$_}}
sub dateformat  {for($_[0]->{dateformat}  ){$_=$_[1]if@_>1;return$_}}
sub regx        {for($_[0]->{regx}        ){$_=$_[1]if@_>1;return$_}}
sub crud        {for($_[0]->{crud}        ){$_=$_[1]if@_>1;return$_}}
sub tocs        {for($_[0]->{tocs}        ){$_=$_[1]if@_>1;return$_}}
sub datamax     {for($_[0]->{datamax}     ){$_=$_[1]if@_>1;return$_}}

sub preamblelen {for($_[0]->{preamblelen} ){$_=0+$_[1]if@_>1;return$_}}
sub toclen      {for($_[0]->{toclen}      ){$_=0+$_[1]if@_>1;return$_}}
sub keylen      {for($_[0]->{keylen}      ){$_=0+$_[1]if@_>1;return$_}}
sub keybase     {for($_[0]->{keybase}     ){$_=0+$_[1]if@_>1;return$_}}
sub translen    {for($_[0]->{translen}    ){$_=0+$_[1]if@_>1;return$_}}
sub transbase   {for($_[0]->{transbase}   ){$_=0+$_[1]if@_>1;return$_}}
sub fnumlen     {for($_[0]->{fnumlen}     ){$_=0+$_[1]if@_>1;return$_}}
sub fnumbase    {for($_[0]->{fnumbase}    ){$_=0+$_[1]if@_>1;return$_}}

# optional (set up to avoid autovivification):

sub dirmax {
    my $self = shift;
    return $self->{dirmax} = $_[0] if @_;
    return $self->{dirmax} if exists $self->{dirmax};
}
sub dirlev {
    my $self = shift;
    return $self->{dirlev} = 0+$_[0] if @_;
    return $self->{dirlev} if exists $self->{dirlev};
}
sub tocmax {
    my $self = shift;
    return $self->{tocmax} = $_[0] if @_;
    return $self->{tocmax} if exists $self->{tocmax};
}
sub keymax {
    my $self = shift;
    return $self->{keymax} = $_[0] if @_;
    return $self->{keymax} if exists $self->{keymax};
}

# default to null string (will be space-padded)
sub userdata {
    my $self = shift;
    return $self->{userdata} = $_[0] if @_;
    return '' unless exists $self->{userdata};
    return $self->{userdata};
}

#---------------------------------------------------------------------
# 
# =head2 new_toc( \%parms )
# 
# This method is a wrapper for FlatFile::DataStore::Toc->new().
# 
# Private method.
# 
# =cut
# 

sub new_toc {
    my( $self, $parms ) = @_;
    $parms->{'datastore'} = $self;
    FlatFile::DataStore::Toc->new( $parms );
}

#---------------------------------------------------------------------
# 
# =head2 new_preamble( \%parms )
# 
# This method is a wrapper for FlatFile::DataStore::Preamble->new().
# 
# Private method.
# 
# =cut
# 

sub new_preamble {
    my( $self, $parms ) = @_;
    $parms->{'datastore'} = $self;
    FlatFile::DataStore::Preamble->new( $parms );
}

#---------------------------------------------------------------------
# 
# =head2 new_record( \%parms )
# 
# This method is a wrapper for FlatFile::DataStore::Record->new().
# 
# Private method.
# 
# =cut
# 

sub new_record {
    my( $self, $parms ) = @_;
    my $preamble = $parms->{'preamble'};
    if( ref $preamble eq 'HASH' ) {  # not an object
        $parms->{'preamble'} = $self->new_preamble( $preamble );
    }
    FlatFile::DataStore::Record->new( $parms );
}

#---------------------------------------------------------------------
# 
# =head2 keyfile( $keyint )
# 
# Takes an integer that is the record sequence number and returns the
# path to the keyfile where that record's preamble is.
# 
# Private method.
# 
# =cut
# 

sub keyfile {
    my( $self, $keyint ) = @_;

    my $name     = $self->name;
    my $fnumlen  = $self->fnumlen;
    my $fnumbase = $self->fnumbase;

    my $keyfint = 1;
    my $keyfile = $name;

    # get key file number (if any) based on keymax and keyint
    if( my $keymax = $self->keymax ) {
        $keyfint = int( $keyint / $keymax ) + 1;
        my $keyfnum = int2base $keyfint, $fnumbase, $fnumlen;

        croak qq/Database exceeds configured size, keyfnum too long: $keyfnum/
            if length $keyfnum > $fnumlen;

        $keyfile .= ".$keyfnum";
    }

    $keyfile .= ".key";

    # get path based on dirlev (if any), dirmax, and key file number
    if( my $dirlev = $self->dirlev ) {
        my $dirmax = $self->dirmax;
        my $path   = "";
        my $this   = $keyfint;
        for( 1 .. $dirlev ) {
            my $dirint = $dirmax? (int( ( $this - 1 ) / $dirmax ) + 1): 1;
            my $dirnum = int2base $dirint, $fnumbase, $fnumlen;
            $path = $path? "$dirnum/$path": $dirnum;
            $this = $dirint;
        }
        $path = $self->dir . "/$name/key$path";
        mkpath( $path ) unless -d $path;
        $keyfile = "$path/$keyfile";
    }
    else {
        $keyfile = $self->dir . "/$keyfile";
    }

    return ( $keyfile, $keyfint ) if wantarray;
    return $keyfile;

}

#---------------------------------------------------------------------
# 
# =head2 datafile(), called by create(), update(), and delete()
# 
# Similar to which_datafile(), this method takes a file number
# and returns the path to that datafile.  Unlike which_datafile(),
# this method also takes a record length to check for overflow.
# 
# That is, if the record about to be written would make a datafile
# become too large (> datamax), the file number is incremented,
# and the path to that new datafile is returned -- along with the
# new file number.  Calls to datafile() should always take this
# new file number into account.
# 
# Will croak if the record is way too big (> datamax) or if the new
# file number is longer than the max length for file numbers.  In
# either case, a new datastore must be configured to handle the
# extra data, and the old datastore must be migrated to it.
# 
# Private method.
# 
# =cut
# 

sub datafile {
    my( $self, $fnum, $reclen ) = @_;

    my $datafile = $self->which_datafile( $fnum );

    # check if we're about to overfill the data file
    # and if so, increment fnum for a new data file

    my $datamax   = $self->datamax;
    my $checksize = $self->preamblelen + $reclen + length $self->recsep;
    my $datasize  = -s $datafile || 0;

    if( $datasize + $checksize > $datamax ) {

        croak qq/Record too long: $checksize > $datamax/
            if $checksize > $datamax;

        my $fnumlen  = $self->fnumlen;
        my $fnumbase = $self->fnumbase;
        $fnum = int2base( 1 + base2int( $fnum, $fnumbase ), $fnumbase, $fnumlen );

        croak qq/Database exceeds configured size, fnum too long: $fnum/
            if length $fnum > $fnumlen;

        $datafile = $self->which_datafile( $fnum );
    }

    return $datafile, $fnum;
}

#---------------------------------------------------------------------
# 
# =head2 which_datafile()
# 
# Takes a file number and returns the path to that datafile.
#
# Takes into account dirlev and dirmax, if set, and will create
# new directories as needed.
# 
# Private method.
# 
# =cut
# 

sub which_datafile {
    my( $self, $datafnum ) = @_;

    my $name     = $self->name;
    my $datafile = "$name.$datafnum.data";

    # get path based on dirlev, dirmax, and data file number
    if( my $dirlev   = $self->dirlev ) {
        my $fnumlen  = $self->fnumlen;
        my $fnumbase = $self->fnumbase;
        my $dirmax   = $self->dirmax;
        my $path     = "";
        my $this     = base2int $datafnum, $fnumbase;
        for( 1 .. $dirlev ) {
            my $dirint = $dirmax? (int( ( $this - 1 ) / $dirmax ) + 1): 1;
            my $dirnum = int2base $dirint, $fnumbase, $fnumlen;
            $path = $path? "$dirnum/$path": $dirnum;
            $this = $dirint;
        }
        $path = $self->dir . "/$name/data$path";
        mkpath( $path ) unless -d $path;
        $datafile = "$path/$datafile";
    }
    else {
        $datafile = $self->dir . "/$datafile";
    }

    return $datafile;
}

#---------------------------------------------------------------------
# 
# =head2 sub all_datafiles(), called by validate utility
# 
# Returns an array of paths for all of the data files in the
# datastore.
# 
# Private method.
# 
# =cut
# 

sub all_datafiles {
    my( $self ) = @_;

    my $fnumlen  = $self->fnumlen;
    my $fnumbase = $self->fnumbase;
    my $top_toc  = $self->new_toc( { int => 0 } );
    my $datafint = $top_toc->datafnum;
    my @files;
    for( 1 .. $datafint ) {
        my $datafnum = int2base $_, $fnumbase, $fnumlen;
        push @files, $self->which_datafile( $datafnum );
    }
    return @files;
}

#---------------------------------------------------------------------

=head1 OBJECT METHODS, Other

=head2 howmany( [$regx] )

Returns count of records whose indicators match regx, e.g.,

    $self->howmany( qr/create|update/ );
    $self->howmany( qr/delete/ );
    $self->howmany( qr/oldupd|olddel/ );

If no regx, howmany() returns numrecs from the toc file, which
should give the same number as qr/create|update/.

=cut

sub howmany {
    my( $self, $regx ) = @_;

    my $top_toc = $self->new_toc( { int => 0 } );

    return $top_toc->numrecs unless $regx;

    my $howmany = 0;
    for( qw( create update delete oldupd olddel ) ) {
        $howmany += $top_toc->$_() if /$regx/ }
    return $howmany;
}

#---------------------------------------------------------------------

=head2 lastkeynum()

Returns the last key number used, i.e., the sequence number of the
last record added to the datastore, as an integer.

=cut

sub lastkeynum {
    my( $self ) = @_;

    my $top_toc = $self->new_toc( { int => 0 } );
    my $keyint  = $top_toc->keynum;

    return $keyint;
}

#---------------------------------------------------------------------

=head2 nextkeynum()

Returns lastkeynum()+1 (a convenience method).  This could be useful
for adding a new record to a hash tied to a datastore, e.g.,

    $h{ $ds->nextkeynum } = "New record data.";

(but also note that there is a "null key" convention for this -- see
FlatFile::DataStore::Tiehash)

=cut

sub nextkeynum {
   for( $_[0]->lastkeynum ) {
       return 0 unless defined;
       return $_ + 1;
   }
}

#---------------------------------------------------------------------
# 
# =head2 keyseek( $keyint )
#
# Gets seekpos of a particular line in the key file.
# 
# Takes the record sequence number as an integer and returns
# the seek position needed to retrieve the record's preamble from
# the pertinent keyfile.
#
# Interestingly, this seek position is only a function of the keyint
# and keymax values, so this routine doesn't need to know (and doesn't
# return) which keyfile we're seeking into.
# 
# Private method.
# 
# =cut
# 
            
sub keyseek {
    my( $self, $keyint ) = @_;

    my $keylen = $self->preamblelen + length( $self->recsep );

    my $keyseek;
    if( my $keymax = $self->keymax ) {
        my $skip = int( $keyint / $keymax );
        $keyseek = $keylen * ( $keyint - ( $skip * $keymax ) ); }
    else {
        $keyseek = $keylen * $keyint; }

    return $keyseek;
}

#---------------------------------------------------------------------
# 
# =head2 nexttransnum(), get next transaction number
# 
# Takes a FF::DS::Toc (table of contents) object, which should be
# the "top" Toc that has many of the key values for the datastore.
# 
# Returns the next transaction number as an integer.
# Note: transaction numbers begin with 1 (not 0).
# 
# Will croak if this number is longer than allowed by the current
# configuration.  In that case, a new datastore that allows for
# more transactions must be configured and the old datastore
# migrated to it.
# 
# Private method.
# 
# =cut
# 

sub nexttransnum {
    my( $self, $top_toc ) = @_;

    $top_toc ||= $self->new_toc( { int => 0 } );

    my $transint  = $top_toc->transnum + 1;
    my $translen  = $self->translen;
    my $transbase = $self->transbase;
    my $transnum  = int2base $transint, $transbase, $translen;

    croak qq/Database exceeds configured size, transnum too long: $transnum/
        if length $transnum > $translen;

    return $transint;
}

#---------------------------------------------------------------------
# 
# =head2 burst_preamble()
# 
# Takes a preamble string (as stored on disk) and parses out all
# of the values, based on regx and specs.
# 
# Returns a hash ref of these values.
# 
# Called by FF::DS::Preamble->new() to create an object from a string,
# and by retrieve() and locate_record_data() to get the file number
# and seek pos for reading a record.
# 
# Private method.
# 
# =cut
# 

sub burst_preamble {
    my( $self, $string ) = @_;

    croak qq/No preamble to burst/ unless $string;

    my @fields = $string =~ $self->regx;

    croak qq/Something is wrong with preamble: $string/ unless @fields;

    my %parms;
    my $i;
    for( $self->specs ) {  # specs() returns an array of hashrefs
        my( $key, $aref )       = %$_;
        my( $pos, $len, $parm ) = @$aref;
        my $field = $fields[ $i++ ];
        for( $key ) {
            if( /indicator|transind|date/ ) {
                $parms{ $key } = $field;
            }
            elsif( /user/ ) {
                my $try = $field;
                $try =~ s/\s+$//;
                $parms{ $key } = $try;
            }
            elsif( /fnum/ ) {
                next if $field =~ /^-+$/;
                $parms{ $key } = $field;
            }
            else {
                next if $field =~ /^-+$/;
                $parms{ $key } = base2int( $field, $parm );
            }
        }
    }
    return \%parms;
}

#---------------------------------------------------------------------
# 
# =head2 update_preamble()
# 
# Called by update() and delete() to flag old recs.
# 
# Takes a preamble string and a hash ref of values to change, and
# returns a new preamble string with those values changed.
# 
# Will croak if the new preamble does not match the regx attribute.
# 
# Private method.
# 
# =cut
# 

sub update_preamble {
    my( $self, $preamble, $parms ) = @_;

    my $omap = $self->specs;

    for( keys %$parms ) {

        my $value = $parms->{ $_ };

        my $specs = omap_get_values( $omap, $_ );
        croak qq/Unrecognized field: $_/ unless $specs;

        my( $pos, $len, $parm ) = @{$specs};

        my $try;
        if( /indicator|transind|date|user/ ) {
            $try = sprintf "%-${len}s", $value;

            croak qq/Invalid value for $_: $try/
                unless $try =~ $Ascii_chars;
        }
        # the fnums should be in their base form already
        elsif( /fnum/ ) {
            $try = sprintf "%0${len}s", $value;
        }
        else {
            $try = int2base $value, $parm, $len;
        }

        croak qq/Value of $_ too long: $try/ if length $try > $len;

        substr $preamble, $pos, $len, $try;  # update the field
    }

    croak qq/Something is wrong with preamble: $preamble/
        unless $preamble =~ $self->regx;

    return $preamble;
}

#---------------------------------------------------------------------
# file read/write:
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# 
# =head2 locked_for_read()
# 
# Takes a file name, opens it for input, locks it, sets binmode, and
# returns the open file handle.
# 
# Private method.
# 
# =cut
# 

sub locked_for_read {
    my( $self, $file ) = @_;
    untaint path => $file;

    my $fh;
    sysopen( $fh, $file, O_RDONLY|O_CREAT )
                         or croak qq/Can't open $file for read: $!/;
    flock $fh, LOCK_SH   or croak qq/Can't lock $file shared: $!/;
    binmode $fh;

    return $fh;
}

#---------------------------------------------------------------------
# 
# =head2 locked_for_write()
# 
# Takes a file name, opens it for read/write, locks it, sets binmode,
# and returns the open file handle.
# 
# Private method.
# 
# =cut
# 

sub locked_for_write {
    my( $self, $file ) = @_;
    untaint path => $file;

    my $fh;
    sysopen( $fh, $file, O_RDWR|O_CREAT ) or croak qq/Can't open $file for read-write: $!/;
    my $ofh = select( $fh ); $| = 1; select ( $ofh );  # flush buffers
    flock $fh, LOCK_EX                    or croak qq/Can't lock $file exclusive: $!/;
    binmode $fh;

    return $fh;
}

#---------------------------------------------------------------------
# 
# =head2 read_record()
# 
# Takes an open file handle and a seek position and
# 
#     - seeks there to read the preamble
#     - seeks to the record data and reads that
#     - returns a record object created from the preamble and data
# 
# Private method.
# 
# =cut
# 

sub read_record {
    my( $self, $fh, $seekpos ) = @_;

    # we don't call read_preamble() because we need len anyway
    my $len  = $self->preamblelen;
    my $sref = $self->read_bytes( $fh, $seekpos, $len ); 
    my $preamble = $self->new_preamble( { string => $$sref } );

    $seekpos    += $len;
    $len         = $preamble->reclen;
    my $recdata  = $self->read_bytes( $fh, $seekpos, $len ); 

    my $record = $self->new_record( {
        preamble => $preamble,
        data     => $recdata,  # scalar ref
        } );

    return $record;
}

#---------------------------------------------------------------------
# 
# =head2 read_preamble()
# 
# Takes an open file handle (probably the key file) and a seek
# position and
# 
#     - seeks there to read the preamble
#     - returns the preamble string (not an object)
# 
# Private method.
# 
# =cut
# 

sub read_preamble {
    my( $self, $fh, $seekpos ) = @_;

    my $len  = $self->preamblelen;
    my $sref = $self->read_bytes( $fh, $seekpos, $len ); 

    return $$sref;  # want the string, not the ref
}

#---------------------------------------------------------------------
# 
# =head2 read_bytes()
# 
# Takes an open file handle, a seek position and a length, reads
# that many bytes from that position, and returns a scalar
# reference to that data.  It is expected that the file is set
# to binmode.
# 
# Private method.
# 
# =cut
# 

sub read_bytes {
    my( $self, $fh, $seekpos, $len ) = @_;

    my $string;
    sysseek $fh, $seekpos, 0 or croak qq/Can't seek: $!/;
    my $rc = sysread $fh, $string, $len;
    croak qq/Can't read: $!/ unless defined $rc;

    return \$string;
}

#---------------------------------------------------------------------
# 
# =head2 write_bytes()
# 
# Takes an open file handle, a seek position, and a scalar
# reference and writes that data to the file at that position.
# It is expected that the file is set to binmode.
# 
# Private method.
# 
# =cut
# 

sub write_bytes {
    my( $self, $fh, $seekpos, $sref ) = @_;

    sysseek  $fh, $seekpos, 0 or croak qq/Can't seek: $!/;
    syswrite $fh, $$sref      or croak qq/Can't write: $!/;

}

#---------------------------------------------------------------------
# 
# =head2 read_file(), used by init() to read the .uri file
# 
# Takes a file name, locks it for reading, and returns the
# contents as an array of lines
# 
# Private method.
# 
# =cut
# 

sub read_file {
    my( $self, $file ) = @_;
    untaint path => $file;

    my $fh;
    open  $fh, '<', $file or croak qq/Can't open $file for read: $!/;
    flock $fh, LOCK_SH    or croak qq/Can't lock $file shared: $!/;
    # binmode $fh;  # NO binmode here, please

    return <$fh>;
}


#---------------------------------------------------------------------
# 
# =head2 now(), expects a string that contains
# 
#     'yyyy', 'mm', 'da', 'tttttt' (hhmmss) in some order, or
#     'yy',   'm',  'd',  'ttt'    (hms)    in some order
# 
# ('yyyy' is a magic string that denotes decimal vs. base62)
# 
# Returns current date formatted as requested.
# 
# Private method.
# 
# =cut
# 

sub now {
    my( $format ) = @_;
    my( $yr, $mo, $da, $hr, $mn, $sc ) =
        sub{($_[5]+1900,$_[4]+1,$_[3],$_[2],$_[1],$_[0])}->(localtime);
    for( $format ) {
        if( /yyyy/ ) {  # decimal
            s/ yyyy   / sprintf "%04d", $yr                   /ex;  # Y10K bug
            s/ mm     / sprintf "%02d", $mo                   /ex;
            s/ dd     / sprintf "%02d", $da                   /ex;
            s/ tttttt / sprintf "%02d%02d%02d", $hr, $mn, $sc /ex;
        }
        else {          # base62
            s/ yy  / int2base( $yr, 62 )  /ex;  # Y3844 bug
            s/ m   / int2base( $mo, 62 )  /ex;
            s/ d   / int2base( $da, 62 )  /ex;
            s/ ttt / int2base( $hr, 62 ).
                     int2base( $mn, 62 ).
                     int2base( $sc, 62 )  /ex;
        }
    }
    return $format;
}

#---------------------------------------------------------------------
# 
# =head2 TIEHASH() supports tied hash access
# 
# Returns datastore object.
# 
# Note: because of how new_toc and new_record are implemented, I
# couldn't make Tiehash a subclass, so I'm requiring it into this
# class.  This may change in the future -- or not.
#
# Somewhat private method.
# 
# =cut
# 

sub TIEHASH {

    # Note: 'require', not 'use'.  This isn't
    # a "true" module -- we're just bringing in
    # some more FlatFile::DataStore methods.

    require FlatFile::DataStore::Tiehash;

    my $class = shift;
    $class->new( @_ );
}

#---------------------------------------------------------------------
BEGIN {
my %allow = (
    trusted  =>  qr{^       (.*) $}x,  # i.e., anything
    path     =>  qr{^ ([-.\w/]*) $}x,  # e.g., /tmp/sess/s.1.data
);

sub untaint {
    my( $key, $var ) = @_;
    for( $var ) {
        return unless defined;
        return if /^$/;
    }
    for( $key ) {
        die "Not defined: $_" unless $allow{ $_ };            # programmer error
        if( $var =~ /$allow{ $_ }/ ) { $_[1] = $1          }  # must set the alias
        else                         { die "Invalid $_.\n" }  # intentionally coy
    }
}}

1;  # returned

__END__

=head1 URI Configuration

It may seem odd to use a URI as a configuration file.  I needed some
configuration approach and wanted to stay as lightweight as possible.
The specs for a URI are fairly well-known, and it allows for everything
we need, so I chose that approach.

The examples all show a URL, because I thought it would be a nice touch
to be able to visit the URL and have the page tell you things about the
datastore.  This is what the C<utils/flatfile-datastore.cgi> program is
intended to do, but it is in a very young/rough state so far.

Following are the URI configuration parameters.  The order of the
preamble parameters I<does> matter: that's the order those fields will
appear in each record preamble.  Otherwise the order of the URI
parameters doesn't matter.

Parameter values should be percent-encoded (uri escaped).  Use %20 for
space (don't be tempted to use '+').  Use URI::Escape::uri_escape , if
desired, e.g.,

    my $name = 'example';
    my $dir  = '/example/dir';

    use URI::Escape;
    my $datastore = FlatFile::DataStore::->new( {
        name => $name,
        dir  => $dir,
        uri  => join( ';' =>
            "http://example.com?name=$name",
            "desc=" . uri_escape( 'My DataStore' ),
            "defaults=medium",
            "user=" . uri_escape( '8- -~' ),
            "recsep=%0A",
        ) }
    );

=head2 Preamble parameters

All of the preamble parameters are required.

(In fact, four of them are optional, but leaving them out means that
you're giving up keeping the linked list of record history, so don't do
that unless you have a good reason.)

=over 8

=item indicator

The indicator parameter specifies the single-character record
indicators that appear in each record preamble.  This parameter has the
following form: C<indicator=length-5CharacterString>,
e.g.,

    indicator=1-+#=*-

The length is always 1.  The five characters represent the five states
of a record in the datastore (in this order):

    create(+): the record has not changed since being added
    oldupd(#): the record was updated, and this entry is an old version
    update(=): this entry is the updated version of a record
    olddel(*): the record was deleted, and this entry is the old version
    delete(-): the record is deleted, and this entry is the "delete record"

(The reason for a "delete record" is for storing information about the
delete process, such has when it was deleted and by whom.)

The five characters shown in the example are the ones used by all
examples in the documentation.  You're free to use your own characters,
but the length must always be 1.

=item transind

The transind parameter describes the single-character transaction
indicators that appear in each record preamble.  This parameter has the
same format and meanings as the indicator parameter, e.g.,

    transind=1-+#=*-

(Note that only three of these are used, but all five must be given and
must match the indicator parameter.)

The three characters that are used are create(+), update(=), and
delete(-).  While the record indicators will change, e.g., from create
to oldupd, or from update to olddel, etc., the transaction indicators
never change from their original values.  So a transaction that created
a record will always have the create value, and the same for update and
delete.

=item date

The date parameter specifies how the transaction date is stored in the
preamble.  It has the form: C<date=length-format>, e.g.,

    date=8-yyyymmdd
    date=14-yyyymmddtttttt
    date=4-yymd
    date=7-yymdttt

The examples show the four choices for length: 4, 7, 8, or 14.  When
the length is 8, the format must contain 'yyyy', 'mm', and 'dd' in some
order.  When the length is 14, add 'tttttt' (hhmmss) in there
somewhere.

When the length is 4, the format must contain 'yy', 'm', and 'd' in
some order.  When the length is 7, add 'ttt' (hms) in there somewhere,
e.g.

    date=8-mmddyyyy,        date=8-ddmmyyyy,        etc.
    date=14-mmddyyyytttttt, date=14-ttttttddmmyyyy, etc.
    date=4-mdyy,            date=4-dmyy,            etc.
    date=7-mdyyttt,         date=7-tttdmyy,         etc.

When the length is 8 (or 14), the year, month, and day (and hours,
minutes, seconds) are stored as decimal numbers, e.g., '20100615' for
June 15, 2010 (or '20101224114208' for Dec 24, 2010 11:42:08).

When the length is 4 (or 7), they are stored as base62 numbers, e.g.
'WQ6F' (yymd) for June 15, 2010, or 'WQCOBg8' (yymdttt) for Dec 24, 2010
11:42:08.

=item transnum

The transnum parameter specifies how the transaction number is stored
in the preamble.  It has the form: C<transnum=length-base>,
e.g.,

    transnum=4-62

The example says the number is stored as a four-digit base62 integer.
The highest transaction number this allows is 'zzzz' base62 which is
14,776,335 decimal.  Therefore, the datastore will accommodate up to
that many transactions (creates, updates, deletes).

=item keynum

The keynum parameter specifies how the record sequence number is stored
in the preamble.  It has the form: C<keynum=length-base>,
e.g.,

    keynum=4-62

As with the transnum example above, the keynum would be stored as a
four-digit base62 integer, and the highest record sequence number
allowed would be 14,776,335 ('zzzz' base62).  Therefore, the datastore
could not store more than this many records.

=item reclen

The reclen parameter specifies how the record length is stored in the
preamble.  It has the form: C<reclen=length-base>, e.g.,

    reclen=4-62

This example allows records to be up to 14,776,335 bytes long.

=item thisfnum

The thisfnum parameter specifies how the file numbers are stored in the
preamble.  There are three file number parameters, thisfnum, prevfnum,
and nextfnum.  They must match each other in length and base.  The
parameter has the form: C<thisfnum=length-base>, e.g.,

    thisfnum=2-36

There is an extra constraint imposed on the file number parameters:
they may not use a number base higher than 36.  The reason is that the
file number appears in file names, and base36 numbers match [0-9A-Z].
By limiting to base36, file names will therefore never differ only by
case, e.g., there may be a file named example.Z.data, but never one
named example.z.data.

The above example states that the file numbers will be stored as
two-digit base36 integers.  The highest file number is 'ZZ' base36,
which is 1,295 decimal.  Therefore, the datastore will allow up to that
many data files before filling up.  (If a datastore "fills up", it must
be migrated to a newly configured datastore that has bigger numbers
where needed.)

In a preamble, thisfnum is the number of the datafile where the record
is stored.  This number combined with the thisseek value and the reclen
value gives the precise location of the record data.

=item thisseek

The thisseek parameter specifies how the seek positions are stored in
the preamble.  There are three seek parameters, thisseek, prevseek, and
nextseek.  They must match each other in length and base.  The
parameter has the form:  C<thisseek=length-base>, e.g.,

    thisseek=5-62

This example states that the seek positions will be stored as
five-digit base62 integers.  So the highest seek position is 'zzzzz'
base62, which is 916,132,831 decimal.  Therefore, each of the
datastore's data files may contain up to that many bytes (record data
plus preambles).

Incidentally, no record (plus its preamble) may be longer than this,
because it just wouldn't fit in a data file.

Also, the size of each data file may be further limited using the
datamax parameter (see below).  For example, a seek value of C<4-62>
would allow datafiles up to 14,776,335 bytes long.  If you want bigger
files, but don't want them bigger than 500 Meg, you can give
C<thisseek=5-62> and C<datamax=500M>.

=item prevfnum (optional)

The prevfnum parameter specifies how the "previous" file numbers are
stored in the preamble.  The value of this parameter must exactly match
thisfnum (see thisfnum above for more details).  It has the form:
C<prevfnum=length-base>, e.g.,

    prevfnum=2-36

In a preamble, the prevfnum is the number of the datafile where the
previous version of the record is stored.  This number combined with
the prevseek value gives the beginning location of the previous
record's data.

This is the first of the four "optional" preamble parameters.  If you
don't provide this one, don't provide the other three either.  If you
leave these off, you will not be able to get a record's history of
changes, and you will not be able to migrate any history to a new
datastore.

So why would to not provide these?  You might have a datastore that has
very transient data, e.g., indexes, and you don't care about change
history.  By not including these four optional parameters, when the
module updates a record, it will not perform the extra bit of IO to
update a previous record's nextfnum and nextseek values.  And the
preambles will be a little bit shorter.

=item prevseek (optional)

The prevseek parameter specifies how the "previous" seek positions are
stored in the preamble.  The value of this parameter must exactly match
thisseek (see thisseek above for more details).  It has the form
C<prevseek=length-base>, e.g.,

    prevseek=5-62

=item nextfnum (optional)

The nextfnum parameter specifies how the "next" file numbers are stored
in the preamble.  The value of this parameter must exactly match
thisfnum (see thisfnum above for more details).  It has the form:
C<nextfnum=length-base>, e.g.,

    nextfnum=2-36

In a preamble, the nextfnum is the number of the datafile where the
next version of the record is stored.  This number combined with the
nextseek value gives the beginning location of the next version of the
record's data.

=item nextseek (optional)

The nextseek parameter specifies how the "next" seek positions are
stored in the preamble.  The value of this parameter must exactly match
thisseek (see thisseek above for more details).  It has the form
C<nextseek=length-base>, e.g.,

    nextseek=5-62

You would have a nextfnum and nextseek in a preamble when it's a
previous version of a record whose current version appears later in the
datastore.  While thisfnum and thisseek are critical for all record
retrievals, prevfnum, prevseek, nextfnum, and nextseek are only needed
for getting a record's history.  They are also used during a migration
to help validate that all the data (and transactions) were migrated
intact.

=item user

The user parameter specifies the length and character class for
extra user data stored in the preamble.  It has the form:
C<user=length-CharacterClass>, e.g.,

    user=8-%20-~  (must match /[ -~]+ */ and not be longer than 8)
    user=10-0-9   (must match /[0-9]+ */ and not be longer than 10)
    user=1-:      (must be literally ':')

When a record is created, the application supplies a value to store
as "user" data.  This might be a userid, an md5 digest, multiple
fixed-length fields -- whatever is needed or wanted.

This field is required but may be preassigned using the userdata
parameter (see below).  If no user data is provided or preassigned,
it will default to a null string (which will be padded with spaces).

When this data is stored in the preamble, it is padded on the right
with spaces.

=back

=head2 Preamble defaults

All of the preamble parameters -- except user -- may be set using one
of the defaults provided, e.g.,

    http://example.com?name=example;defaults=medium;user=8-%20-~
    http://example.com?name=example;defaults=large;user=10-0-9

Note that these are in a default order also.  And the user parameter
is still part of the preamble, so you can make it appear first if you
want, e.g.,

    http://example.com?name=example;user=8-%20-~;defaults=medium
    http://example.com?name=example;user=10-0-9;defaults=large

The C<_nohist> versions leave out the optional preamble parameters --
the above caveat about record history still applies.

Finally, if none of these suits, they may still be good starting points
for defining your own preambles.

=over 8

=item xsmall, xsmall_nohist

When the URI contains C<defaults=xsmall>, the following values are
set:

    indicator=1-+#=*-
    transind=1-+#=*-
    date=7-yymdttt
    transnum=2-62   3,843 transactions
    keynum=2-62     3,843 records
    reclen=2-62     3,843 bytes/record
    thisfnum=1-36   35 data files
    thisseek=4-62   14,776,335 bytes/file
    prevfnum=1-36
    prevseek=4-62
    nextfnum=1-36
    nextseek=4-62

The last four are not set for C<defaults=xsmall_nohist>.

Rough estimates: 3800 records (or transactions), no larger than
3800 bytes each; 517 Megs total (35 * 14.7M).

=item small, small_nohist

For C<defaults=small>:

    indicator=1-+#=*-
    transind=1-+#=*-
    date=7-yymdttt
    transnum=3-62   238,327 transactions
    keynum=3-62     238,327 records
    reclen=3-62     238,327 bytes/record
    thisfnum=1-36   35 data files
    thisseek=5-62   916,132,831 bytes/file
    prevfnum=1-36
    prevseek=5-62
    nextfnum=1-36
    nextseek=5-62

The last four are not set for C<defaults=small_nohist>.

Rough estimates: 238K records (or transactions), no larger than 238K
bytes each; 32 Gigs total (35 * 916M).

=item medium, medium_nohist

For C<defaults=medium>:

    indicator=1-+#=*-
    transind=1-+#=*-
    date=7-yymdttt
    transnum=4-62   14,776,335 transactions
    keynum=4-62     14,776,335 records
    reclen=4-62     14,776,335 bytes/record
    thisfnum=2-36   1,295 data files
    thisseek=5-62   916,132,831 bytes/file
    prevfnum=2-36
    prevseek=5-62
    nextfnum=2-36
    nextseek=5-62

The last four are not set for C<defaults=medium_nohist>.

Rough estimates: 14.7M records (or transactions), no larger than 14.7M
bytes each; 1 Terabyte total (1,295 * 916M).

=item large, large_nohist

For C<defaults=large>:

    datamax=1.9G    1,900,000,000 bytes/file
    dirmax=300
    keymax=100_000
    indicator=1-+#=*-
    transind=1-+#=*-
    date=7-yymdttt
    transnum=5-62   916,132,831 transactions
    keynum=5-62     916,132,831 records
    reclen=5-62     916,132,831 bytes/record
    thisfnum=3-36   46,655 data files
    thisseek=6-62   56G per file (but see datamax)
    prevfnum=3-36
    prevseek=6-62
    nextfnum=3-36
    nextseek=6-62

The last four are not set for C<defaults=large_nohist>.

Rough estimates: 916M records/transactions, no larger than 916M bytes
each; 88 Terabytes total (46,655 * 1.9G).

=item xlarge, xlarge_nohist

For C<defaults=xlarge>:

    datamax=1.9G    1,900,000,000 bytes/file
    dirmax=300
    dirlev=2
    keymax=100_000
    tocmax=100_000
    indicator=1-+#=*-
    transind=1-+#=*-
    date=7-yymdttt
    transnum=6-62   56B transactions
    keynum=6-62     56B records
    reclen=6-62     56G per record (limited to 1.9G by datamax)
    thisfnum=4-36   1,679,615 data files
    thisseek=6-62   56G per file (but see datamax)
    prevfnum=4-36
    prevseek=6-62
    nextfnum=4-36
    nextseek=6-62

The last four are not set for C<defaults=xlarge_nohist>.

Rough estimates: 56B records/transactions, no larger than 1.9G bytes
each; 3 Petabytes total (1,679,615 * 1.9G).

=back

=head2 Other required parameters

=over 8

=item name

The name parameter identifies the datastore by name.  This name should
be short and uncomplicated, because it is used as the root for the
datastore's files.

=item recsep

The recsep parameter gives the ascii character(s) that will make up the
record separator.  The "flatfile" stategy suggests that these
characters ought to match what your OS considers to be a "newline".
But in fact, you could use any string of ascii characters.

    recsep=%0A       (LF)
    recsep=%0D%0A    (CR+LF)
    recsep=%0D       (CR)

    recsep=%0A---%0A (HR -- sort of)

(But keep in mind that the recsep is also used for the key files and
toc files.  So a simpler recsep is probably best.)

Also, if you develop your data on unix with recsep=%0A and then copy it
to a windows machine, the module will continue to use the configured
recsep, i.e., it is not tied the to OS.

=back

=head2 Other optional parameters

=over 8

=item desc

The desc parameter provides a means to give a short description (or perhaps a
longer name) for the datastore.

=item datamax

The datamax parameter gives the maximum number of bytes a data file may contain.
If you don't provide a datamax, it will be computed from the thisseek value (see
thisseek above for more details).

The datamax value is simply a number, e.g.,

    datamax=1000000000   (1 Gig)

To make things easier to read, you can add underscores, e.g.,

    datamax=1_000_000_000   (1 Gig)

You can also shorten the number with an 'M' for megabytes (10**6) or a
'G' for gigabytes (10**9), e.g.,

    datamax=1000M  (1 Gig)
    datamax=1G     (1 Gig)

Finally, with 'M' or 'G', you can use fractions, e.g.

    datamax=.5M  (500_000)
    datamax=1.9G (1_900_000_000)

=item keymax

The keymax parameter gives the number of record keys that may be stored
in a key file.  This simply limits the size of the key files, e.g.,

    keymax=10_000

The maximum bytes would be:

    keymax * (preamble length + recsep length)

The numeric value may use underscores and 'M' or 'G' as described above
for datamax.

=item tocmax

The tocmax parameter gives the number of data file entries that may be stored
in a toc (table of contents) file.  This simply limits the size of the toc
files, e.g.,

    tocmax=10_000

Each (fairly short) line in a toc file describes a single data file, so
you would need a tocmax only in the extreme case of a datastore with
thousands or millions of data files.

The numeric value may use underscores and 'M' or 'G' as described above
for datamax.

=item dirmax

The dirmax parameter gives the number of files (and directories) that
may be stored in a datastore directory, e.g.,

    dirmax=300

This allows a large number of data files (and key/toc files) to be
created without there being too many files in a single directory.

(The numeric value may use underscores and 'M' or 'G' as described above
for datamax.)

If you specify dirmax without dirlev (see below), dirlev will default
to 1.

Without dirmax and dirlev, a datastore's data files (and key/toc files)
will reside in the same directory as the uri file, and the module will
not limit how many you may create (though the size of your filesystem
might).

With dirmax and dirlev, these files will reside in subdirectories.

Giving a value for dirmax will also limit the number of data files (and
key/toc files) a datastore may have, by this formula:

 max files = dirmax ** (dirlev + 1)

So dirmax=300 and dirlev=1 would result in a limit of 90,000 data
files.  If you go to dirlev=2, the limit becomes 27,000,000, which is
why you're unlikely to need a dirlev greater than 2.

=item dirlev

The dirlev parameter gives the number of levels of directories that a
datastore may use, e.g.,

    dirlev=1

You can give a dirlev without a dirmax, which would store the data
files (and key/toc files) in subdirectories, but wouldn't limit how
many files may be in each directory.

=item userdata

The userdata parameter is similar to the userdata parameter in the call
to new().  It specifies the default value to use if the application
does not provide a value when creating, updating, or deleting a
record.

Those provided values will override the value given in the call to new(),
which will override the value given here in the uri.

If you don't specify a default value here or in the call to new(), the
value defaults to a null string (which would be padded with spaces).

    userdata=:

The example is contrived for a hypothetical datastore that doesn't need
this field.  Since the field is required, the above setting will always
store a colon (and the user parameter might be C<user=1-:>).

=back

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

