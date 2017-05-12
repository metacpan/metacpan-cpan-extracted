#---------------------------------------------------------------------
package FlatFile::DataStore::Utils;

use 5.008003;
use strict;
use warnings;

use Fcntl qw(:DEFAULT :flock);
use SDBM_File;
use Digest::MD5 qw(md5_hex);
use FlatFile::DataStore;
use Math::Int2Base qw( base_chars int2base base2int );

#---------------------------------------------------------------------

=head1 NAME

FlatFile::DataStore::Utils - a collection of utility routines for
FlatFile::DataStore datastores.

=cut

#---------------------------------------------------------------------

=head1 VERSION

VERSION: 1.03

=cut

our $VERSION = '1.03';

#---------------------------------------------------------------------

=head1 EXPORTS

Nothing is exported by default.  The following may be exported
individually; all of them may be exported using the C<:all> tag:

 - migrate
 - migrate_nohist
 - validate
 - compare

Examples:

 use FlatFile::DataStore::Utils qw( migrate migrate_nohist validate compare );
 use FlatFile::DataStore::Utils qw( :all );

=cut

our ( @ISA, @EXPORT_OK, %EXPORT_TAGS );

BEGIN {
    require Exporter;
    @ISA       = qw( Exporter );
    @EXPORT_OK = qw(
        migrate
        migrate_nohist
        validate
        compare
        );
    %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );
}

#---------------------------------------------------------------------

=head1 SYNOPSIS

    use FlatFile::DataStore::Utils qw( migrate migrate_nohist validate compare );

    my $from_dir  = '/from/dir'; my $from_name = 'ds1';
    my $to_dir    = '/to/dir';   my $to_name   = 'ds2';

    validate( $from_dir, $from_name                    );
    migrate ( $from_dir, $from_name, $to_dir, $to_name );
    validate(                        $to_dir, $to_name );
    compare ( $from_dir, $from_name, $to_dir, $to_name );

    # optionally, migrate_nohist() will not copy any history
    # or deleted records:
    
    validate(        $from_dir, $from_name                    );
    migrate_nohist ( $from_dir, $from_name, $to_dir, $to_name );
    validate(                               $to_dir, $to_name );

    # can't compare anything (yet) after a nohist migrate

=cut

#---------------------------------------------------------------------

=head1 DESCRIPTION

This module provides

- validate(), to validate a datastore, checking that it can be
traversed and that its past record data has not changed, and 
creating history and transaction files for comparison purposes.

- migrate(), to migrate a datastore to a new datastore. Use cases:

  - The data has outgrown the datastore as originally configured
  - You want a better configuration than originally conceived

- migrate_nohist(), to migrate a datastore to a new datastore
without any update history and without any deleted records.  This is
normally discouraged (since the spirit of the module is to retain
all history of activity), but it has its uses.

- compare(), to compare the files that validate() creates for
one datastore to the files that validate() creates for a second
datastore (following a migrate(), most likely).  If these files
(history, transaction, md5) are exactly equal, then the two data
stores are equivalent, i.e., they both contain exactly the same
records, even though their data files, etc., may be very
differently configured.


=cut

#---------------------------------------------------------------------

=head1 SUBROUTINES

Descriptions and parameters for the exportable subroutines are
detailed below.

=head2 validate( $dir, $name )

=head3 Parameters:

=head4 $dir

The directory of the datastore.

=head4 $name

The name of the datastore.

=cut

#---------------------------------------------------------------------
sub validate {
    my( $dir, $name ) = @_;

    my $ds = FlatFile::DataStore->new( { dir => $dir, name => $name } );

    # status is a reverse crud hash for writing to
    # history and transactions files
    my $crud   = $ds->crud;
    my %status = reverse %$crud;

    # build history file for comparing after migrate
    my $histfile = "$dir/$name.hist";
    my $histfh   = locked_for_write( $histfile );

    for my $keynum ( 0 .. $ds->lastkeynum ) {

        for my $rec ( $ds->history( $keynum ) ) {

            my $transnum = $rec->transnum;
            my $keynum   = $rec->keynum;
            my $status   = $status{ $rec->indicator };
            my $user     = $rec->user;
            my $reclen   = $rec->reclen;
            my $md5      = md5_hex( $rec->data );

            print $histfh "$transnum $keynum $status $user $reclen $md5\n";
        }

    }
    close $histfh or die "Can't close $histfile: $!";

    # parse data files and build
    #     transaction file for comparing after migrate, and
    #     md5 file for future validations

    my $recsep      = $ds->recsep;
    my $recseplen   = length( $recsep );
    my $preamblelen = $ds->preamblelen;

    my $transfile = "$dir/$name.tran";
    my $transfh   = locked_for_write( $transfile );

    # our position in md5file will tell us if we have to
    # add this md5 or compare this md5 to an older one

    my $md5file = "$dir/$name.md5";
    my $md5fh   = locked_for_readwrite( $md5file );
    my $md5size = -s $md5file;
    my $md5pos  = 0;

    for my $datafile ( $ds->all_datafiles ) {

        my $datafh   = locked_for_read( $datafile );
        my $filesize = -s $datafile;
        my $seekpos  = 0;

        RECORD: while( $seekpos < $filesize ) {

            my $rec      = $ds->read_record( $datafh, $seekpos );
            my $transnum = $rec->transnum;
            my $keynum   = $rec->keynum;
            my $status   = $status{ $rec->indicator };
            my $user     = $rec->user;
            my $reclen   = $rec->reclen;
            my $md5      = md5_hex( $rec->data );

            print $transfh "$transnum $keynum $status $user $reclen $md5\n";

            # add this md5 or compare this md5 to an older one?

            my $md5out = "$transnum $keynum $user $reclen $md5\n";
            my $outlen = length( $md5out );

            if( $md5pos < $md5size ) {
                my $sref = $ds->read_bytes( $md5fh, $md5pos, $outlen );
                my $md5line = $sref? $$sref: '';
                die qq/Mismatched md5 lines/ unless $md5line eq $md5out;
            }
            else {
                $ds->write_bytes( $md5fh, $md5pos, \$md5out );
            }

            $md5pos += $outlen;

            # move forward in data file
            $seekpos += $preamblelen + $reclen;

            # use recsep as a sentinel for probably okay progress so far
            my $sref = $ds->read_bytes( $datafh, $seekpos, $recseplen );
            my $sentinel = $sref? $$sref: '';
            die qq/Expected a recsep but got: "$sentinel" (at byte "$seekpos" in "$datafile")/
                unless $sentinel eq $recsep;

            $seekpos += $recseplen;
        }

        close $datafh or die "Can't close $datafile: $!";
    }
    close $transfh or die "Can't close $transfile: $!";
    close $md5fh   or die "Can't close $md5file: $!";;
}

#---------------------------------------------------------------------

=head2 migrate( $from_dir, $from_name, $to_dir, $to_name, $to_uri )

=head3 Parameters:

=head4 $from_dir

The directory of the datastore we're migrating from.

=head4 $from_name

The name of the datastore we're migrating from.

=head4 $to_dir

The directory of the datastore we're migrating to.

=head4 $to_name

The name of the datastore we're migrating to.

=head4 $to_uri

The uri of the datastore we're migrating to.  If given, a new data
store will be initialized.  If this parameter is not given, it is
assumed that the new datastore has already been initialized.

=cut

#---------------------------------------------------------------------
sub migrate {
    my( $from_dir, $from_name, $to_dir, $to_name, $to_uri ) = @_;

    my $from_ds = FlatFile::DataStore->new( {
        dir  => $from_dir,
        name => $from_name,
        } );

    my $to_ds   = FlatFile::DataStore->new( {
        dir  => $to_dir,
        name => $to_name,
        uri  => $to_uri,
        } );

    # check some fundamental constraints

    my $from_count = $from_ds->howmany;  # should *not* be zero
    die qq/Can't migrate: "$from_name" datastore empty?/ unless $from_count;

    my $to_count = $to_ds->howmany;  # *should* be zero
    die qq/Can't migrate: "$to_name" datastore not empty?/ if $to_count;

    my $try = $to_ds->which_datafile( 1 );  # first datafile
    die qq/Can't migrate: "$to_name" has a data file, e.g., "$try"/ if -e $try;

    # get ready to loop through datafiles

    my $from_recsep      = $from_ds->recsep;
    my $from_recseplen   = length( $from_recsep );
    my $from_preamblelen = $from_ds->preamblelen;

    my $from_crud = $from_ds->crud;
    my $create    = quotemeta $from_crud->{'create'};  # +
    my $oldupd    = quotemeta $from_crud->{'oldupd'};  # #
    my $update    = quotemeta $from_crud->{'update'};  # =
    my $olddel    = quotemeta $from_crud->{'olddel'};  # *
    my $delete    = quotemeta $from_crud->{'delete'};  # -

    my $last_keynum = -1;  # to be less than 0

    for my $datafile ( $from_ds->all_datafiles ) {

        my $datafh   = locked_for_read( $datafile );
        my $filesize = -s $datafile;
        my $seekpos  = 0;

        my %pending_deletes;

        RECORD: while( $seekpos < $filesize ) {

            my $from_rec       = $from_ds->read_record( $datafh, $seekpos );
            my $keynum         = $from_rec->keynum;
            my $reclen         = $from_rec->reclen;
            my $from_data_ref  = $from_rec->dataref;
            my $from_user_data = $from_rec->user;
            my $indicator      = $from_rec->indicator;
            my $transind       = $from_rec->transind;

            # cases:
            # indicator:  keynum:     pending_delete:  action:             it  because:
            # ----------  ----------  ---------------  ------------------- --  ----------
            # create  +   always new                   create              ++  is current
            # oldupd  #   new                          create              #+  was +
            # oldupd  #   old         if on, turn off  retrieve and delete #-  was -
            # oldupd  #   old                          retrieve and update #=  was =
            # update  =   always old                   retrieve and update ==  is current
            # olddel  *   new         turn on          create              *+  was +
            # olddel  *   old         turn on          retrieve and update *=  was =
            # delete  -   always old  turn off         retrieve and delete --  is current

            my $new_keynum = $keynum > $last_keynum;

            for( $indicator ) {
                /$create/ && do { $to_ds->create({ data => $from_data_ref, user => $from_user_data });
                                  die "Bad transind: $transind"
                                      unless $transind =~ /$create/;  # assertions
                                  last };
                /$oldupd/ && $new_keynum
                          && do { $to_ds->create({ data => $from_data_ref, user => $from_user_data });
                                  die "Bad transind: $transind"
                                      unless $transind =~ /$create/;
                                  last };
                /$oldupd/ && $pending_deletes{ $keynum }
                          && do { my $to_rec =
                                  $to_ds->retrieve( $keynum );
                                  $to_ds->delete({ record => $to_rec, data => $from_data_ref, user => $from_user_data });
                                  delete $pending_deletes{ $keynum };
                                  die "Bad transind: $transind"
                                      unless $transind =~ /$delete/;
                                  last };
                /$oldupd/ && do { my $to_rec =
                                  $to_ds->retrieve( $keynum );
                                  $to_ds->update({ record => $to_rec, data => $from_data_ref, user => $from_user_data });
                                  die "Bad transind: $transind"
                                      unless $transind =~ /$update/;
                                  last };
                /$update/ && do { my $to_rec =
                                  $to_ds->retrieve( $keynum );
                                  $to_ds->update({ record => $to_rec, data => $from_data_ref, user => $from_user_data });
                                  die "Bad transind: $transind"
                                      unless $transind =~ /$update/;
                                  last };
                /$olddel/ && $new_keynum
                          && do { $to_ds->create({ data => $from_data_ref, user => $from_user_data });
                                  ++$pending_deletes{ $keynum };
                                  die "Bad transind: $transind"
                                      unless $transind =~ /$create/;
                                  last };
                /$olddel/ && do { my $to_rec =
                                  $to_ds->retrieve( $keynum );
                                  $to_ds->update({ record => $to_rec, data => $from_data_ref, user => $from_user_data });
                                  ++$pending_deletes{ $keynum };
                                  die "Bad transind: $transind"
                                      unless $transind =~ /$update/;
                                  last };
                /$delete/ && do { my $to_rec =
                                  $to_ds->retrieve( $keynum );
                                  $to_ds->delete({ record => $to_rec, data => $from_data_ref, user => $from_user_data });
                                  delete $pending_deletes{ $keynum };
                                  die "Bad transind: $transind"
                                      unless $transind =~ /$delete/;
                                  last };
            }

            $last_keynum = $keynum if $new_keynum;

            # move forward in data file
            $seekpos += $from_preamblelen + $reclen;

            # use recsep as a sentinel for probably okay progress so far
            my $sref = $from_ds->read_bytes( $datafh, $seekpos, $from_recseplen );
            my $sentinel = $sref? $$sref: '';
            die qq/Expected a recsep but got: "$sentinel" (at byte "$seekpos" in "$datafile")/
                unless $sentinel eq $from_recsep;

            $seekpos += $from_recseplen;
        }

        close $datafh or die "Can't close $datafile: $!";
    }
}

#---------------------------------------------------------------------

=head2 migrate_nohist( $from_dir, $from_name, $to_dir, $to_name, $to_uri )

=head3 Parameters:

=head4 $from_dir

The directory of the datastore we're migrating from.

=head4 $from_name

The name of the datastore we're migrating from.

=head4 $to_dir

The directory of the datastore we're migrating to.

=head4 $to_name

The name of the datastore we're migrating to.

=head4 $to_uri

The uri of the datastore we're migrating to.  If given, a new data
store will be initialized.  If this parameter is not given, it is
assumed that the new datastore has already been initialized.

This routine will not keep any record history and will not migrate
deleted records.

Intended for post-migration comparisons, this routine writes a
"$dir/$name.nohist" data file where each line contains two integers.
The first integer is the record sequence number from the C<from_ds>,
and the second is from the C<to_ds>.  Using these, it should be
possible to compare the user data and record data md5 signature from
both datastores to verify that the data was migrated completely.

=cut

#---------------------------------------------------------------------
sub migrate_nohist {
    my( $from_dir, $from_name, $to_dir, $to_name, $to_uri ) = @_;

    my $from_ds = FlatFile::DataStore->new( {
        dir  => $from_dir,
        name => $from_name,
        } );
    my $to_ds   = FlatFile::DataStore->new( {
        dir  => $to_dir,
        name => $to_name,
        uri  => $to_uri,
        } );

    # check some fundamental constraints

    my $from_count = $from_ds->howmany;  # should *not* be zero
    die qq/Can't migrate: "$from_name" datastore empty?/ unless $from_count;

    my $to_count = $to_ds->howmany;  # *should* be zero
    die qq/Can't migrate: "$to_name" datastore not empty?/ if $to_count;

    my $try = $to_ds->which_datafile( 1 );  # first datafile
    die qq/Can't migrate: "$to_name" has a data file, e.g., "$try"/ if -e $try;

    my $delete = quotemeta $from_ds->crud->{'delete'};

    my $nohistfile = "$to_dir/$to_name.nohist";
    my $nohistfh   = locked_for_write( $nohistfile );
    my $to_keynum = 0;

    for my $keynum ( 0 .. $from_ds->lastkeynum ) {

        my $from_rec       = $from_ds->retrieve( $keynum );
        my $from_data_ref  = $from_rec->dataref;
        my $from_user_data = $from_rec->user;

        # cases: (here we're always retrieving current records)
        # indicator:  action:
        # ----------  -------
        # create  +   create
        # update  =   create
        # delete  -   skip

        unless( $from_rec->indicator =~ /$delete/ ) {
            $to_ds->create({ data => $from_data_ref, user => $from_user_data })
                unless $from_rec->indicator =~ /$delete/;
            print {$nohistfh} "$keynum $to_keynum\n";
            $to_keynum++;
        }
    }
    close $nohistfh or die "Can't close $nohistfile: $!";
}

#---------------------------------------------------------------------

=head2 compare( $from_dir, $from_name, $to_dir, $to_name )

This routine compares the files written by validate() for
each of the datastores to verify that after migration, the
second datastore contains exactly the same information as
the first.

=head3 Parameters:

=head4 $from_dir

The directory of the datastore we migrated from.

=head4 $from_name

The name of the datastore we migrated from.

=head4 $to_dir

The directory of the datastore we migrated to.

=head4 $to_name

The name of the datastore we migrated to.

=cut

#---------------------------------------------------------------------
sub compare {
    my( $from_dir, $from_name, $to_dir, $to_name ) = @_;

    my $from_ds = FlatFile::DataStore->new( {
        dir  => $from_dir,
        name => $from_name,
        } );
    my $to_ds   = FlatFile::DataStore->new( {
        dir  => $to_dir,
        name => $to_name,
        } );

    my @report;
    push @report, "Comparing: TOC files\n";
    my $from_top_toc = $from_ds->new_toc( { int => 0 } );
    my $to_top_toc   = $to_ds->new_toc(   { int => 0 } );
    for( qw(
        numrecs keynum transnum create
        oldupd update olddel delete ) ) {
        my $from_val = $from_top_toc->$_();
        my $to_val   = $to_top_toc->$_();
        push @report, "$_: differs ($from_val $to_val)\n"
            if $from_val ne $to_val;
    }

    my $maxdiff = 10;
    for ( qw( hist tran md5 ) ) {
        my $from_file = "$from_dir/$from_name.$_";
        my $to_file   = "$to_dir/$to_name.$_";
        push @report, "Comparing: $from_file $to_file\n";
        if( -e $from_file and -e $to_file ) {
            if( -s $from_file == -s $to_file ) {
                my @diff = `diff -U 1 $from_file $to_file`;
                if( $diff[0] !~ "No diff" ) {
                    push @report, "Files differ:\n";
                    push @report, @diff[ 0 .. $maxdiff ];
                    push @report, '...' if @diff > $maxdiff
                }
            }
            else {
                push @report, "Files are different sizes.\n";
                push @report, "$from_file: ".(-s $from_file)."\n";
                push @report, "$to_file: ".(-s $to_file)."\n";
            }
        }
        else {
            push @report, "$to_file doesn't exist.\n" if -e $from_file;
            push @report, "$from_file doesn't exist.\n" if -e $to_file;
        }

    }
    return  @report if wantarray;
    return \@report;
}

#---------------------------------------------------------------------
# locked_for_read()
#     Takes a file name, opens it for input, locks it, and returns the
#     open file handle.
#
# Private method.

sub locked_for_read {
    my( $file ) = @_;

    my $fh;
    open $fh, '<', $file or die "Can't open (read) $file: $!";
    flock $fh, LOCK_SH   or die "Can't lock (shared) $file: $!";
    binmode $fh;

    return $fh;
}

#---------------------------------------------------------------------
# locked_for_read()
#     Takes a file name, opens it for output, locks it, and returns the
#     open file handle.
#
# Private method.

sub locked_for_write {
    my( $file ) = @_;

    my $fh;
    open $fh, '>', $file or die "Can't open (write) $file: $!";
    my $ofh = select( $fh ); $| = 1; select ( $ofh );
    flock $fh, LOCK_EX   or die "Can't lock (exclusive) $file: $!";
    binmode $fh;

    return $fh;
}

#---------------------------------------------------------------------
# locked_for_readwrite()
#     Takes a file name, opens it for read/write, locks it, and
#     returns the open file handle.
#
# Private method.

sub locked_for_readwrite {
    my( $file ) = @_;

    my $fh;
    sysopen( $fh, $file, O_RDWR|O_CREAT ) or die "Can't open (read/write) $file: $!";
    my $ofh = select( $fh ); $| = 1; select ( $ofh );
    flock $fh, LOCK_EX                    or die "Can't lock (exclusive) $file: $!";
    binmode $fh;

    return $fh;
}

1;  # return true

__END__
