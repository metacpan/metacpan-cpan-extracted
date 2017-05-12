#---------------------------------------------------------------------
  package FlatFile::DataStore::Toc;
#---------------------------------------------------------------------

=head1 NAME

FlatFile::DataStore::Toc - Perl module that implements a flatfile
datastore TOC (table of contents) class.

=head1 SYNOPSYS

 use FlatFile::DataStore::Toc;
 my $toc;

 $toc = FlatFile::DataStore::Toc->new(
     { int       => 10,
       datastore => $datastore_obj
     } );

 # or

 $toc = FlatFile::DataStore::Toc->new(
     { num       => "A",               # same as int=>10
       datastore => $datastore_obj
     } );

=head1 DESCRIPTION

FlatFile::DataStore::Toc is a Perl module that implements a flatfile
datastore TOC (table of contents) class.

This module is used by FlatFile::DataStore.  You will likely never call
any of it's methods yourself.

=head1 VERSION

FlatFile::DataStore::Toc version 1.03

=cut

our $VERSION = '1.03';

use 5.008003;
use strict;
use warnings;

use File::Path;
use Carp;

use Math::Int2Base qw( base_chars int2base base2int );

my %Attrs = qw(
    datastore 1
    datafnum  1
    keyfnum   1
    tocfnum   1
    numrecs   1
    keynum    1
    transnum  1
    create    1
    oldupd    1
    update    1
    olddel    1
    delete    1
    );

#---------------------------------------------------------------------

=head1 CLASS METHODS

=head2 FlatFile::DataStore::Toc->new( $parms )

Constructs a new FlatFile::DataStore::Toc object from a toc record
string in a tocfile.

The parm C<$parms> is a hash reference containing these required keys:

 - datastore ... data store object, and one of:
 - int ... data file number as integer, or
 - num ... data file number as number in number base

An C<int> or C<num> of 0 will load the first (totals) line from the
tocfile.

=cut

sub new {
    my( $class, $parms ) = @_;

    my $self = bless {}, $class;

    $self->init( $parms ) if $parms;
    return $self;
}


#---------------------------------------------------------------------
# init(), called by new() to parse the parms
#
# Private method.

sub init {
    my( $self, $parms ) = @_;

    my $ds = $parms->{'datastore'} || croak qq/Missing: datastore/;
    $self->datastore( $ds );

    my $datafint;
    if(    defined( my $int = $parms->{'int'} ) ) {
        $datafint = $int;
    }
    elsif( defined( my $num = $parms->{'num'} ) ) {
        $datafint = base2int $num, $ds->fnumbase;
    }
    else {
        croak qq/Missing: int or num/;
    }

    my $string = $self->read_toc( $datafint );

    unless( $string ) {
        $self->datafnum( $datafint );
        $self->tocfnum( $self->toc_getfnum( $datafint ) );
        $self->keynum(   $datafint == 0? -1: 0 );
        $self->$_( 0 )
            for qw( keyfnum numrecs transnum create oldupd update olddel delete );
        return $self;
    }

    my $fnumbase  = $ds->fnumbase;
    my $keybase   = $ds->keybase;
    my $transbase = $ds->transbase;

    my $recsep = $ds->recsep;
    $string =~ s/\Q$recsep\E$//;  # chompish
    $self->string( $string );

    my @fields = split " ", $string;
    my $i = 0;
    $self->$_( base2int $fields[ $i++ ], $fnumbase )
        for qw( datafnum keyfnum tocfnum );
    $self->$_( base2int $fields[ $i++ ], $keybase )
        for qw( numrecs keynum );
    $self->$_( base2int $fields[ $i++ ], $transbase )
        for qw( transnum create oldupd update olddel delete );

    return $self;
}

#---------------------------------------------------------------------

=head1 OBJECT METHODS

=head2 to_string()

Returns the toc object as a string, appropriate for writing back to
the tocfile.

=cut

#---------------------------------------------------------------------
sub to_string {
    my( $self ) = @_;

    return unless $self->keynum > -1;  # empty data store

    my $ds = $self->datastore;

    my $fnumbase  = $ds->fnumbase;
    my $fnumlen   = $ds->fnumlen;
    my $keybase   = $ds->keybase;
    my $keylen    = $ds->keylen;
    my $transbase = $ds->transbase;
    my $translen  = $ds->translen;

    my @fields;
    push @fields, int2base $self->$_(), $fnumbase, $fnumlen
        for qw( datafnum keyfnum tocfnum );
    push @fields, int2base $self->$_(), $keybase, $keylen
        for qw( numrecs keynum );
    push @fields, int2base $self->$_(), $transbase, $translen
        for qw( transnum create oldupd update olddel delete );

    return join( " " => @fields ) . $ds->recsep;
}

#---------------------------------------------------------------------
# read_toc()
#     Takes an integer which denotes which datafile we want a toc
#     record for.  It reads the appropriate line from a tocfile and
#     returns the record as a string.
#
# Private method.

# Case study illustrating the logic in the routine.
#
# seekpos if there's a tocmax, e.g., tocmax=3, fint=7, toclen=4
#
# 1: 0   xxxx     skip    = int( fint / tocmax )
#    1   xxxx             = int(    7    /   3    )
#    2   xxxx             = 2 (files to skip)
# 2: 3   xxxx     seekpos = toclen * ( fint - ( skip * tocmax ) )
#    4   xxxx             =   4    * (    7    - (  2   *   3    ) )
#    5   xxxx             =   4    * (    7    -        6          )
# 3: 6   xxxx             =   4    *           1
#    7 =>xxxx             = 4
#    8   xxxx     '=>' marks seekpos 4 in file 3
            
sub read_toc {
    my( $self, $fint ) = @_;

    my $ds = $self->datastore;

    my $tocfile = $self->tocfile( $fint );
    return unless -e $tocfile;

    # look in tocs cache
    # XXX is there a race condition between -M and locked_for_read?
    if( my $tocs = $ds->tocs->{ $tocfile } ) {
        if( -M _ <= $tocs->{'-M'} ) {  # unchanged
            for( $tocs->{ $fint } ) {
                return $_ if defined;
            }
        }
    }

    my $tocfh  = $ds->locked_for_read( $tocfile );
    my $toclen = $ds->toclen;

    my $seekpos;
    if( my $tocmax = $ds->tocmax ) {
        my $skip = int( $fint / $tocmax );
        $seekpos = $toclen * ( $fint - ( $skip * $tocmax ) ); }
    else {
        $seekpos = $toclen * $fint; }

    my $tocline = $ds->read_bytes( $tocfh, $seekpos, $toclen );
    close $tocfh or croak qq/Can't close $tocfile: $!/;

    # write to tocs cache
    $ds->tocs->{ $tocfile }{'-M'}    = -M $tocfile;
    $ds->tocs->{ $tocfile }{ $fint } = $$tocline;

    $$tocline;  # returned
}

#---------------------------------------------------------------------
# write_toc()
#     Takes an integer which denotes which datafile we want a toc
#     record for.  opens the appropriate tocfile, seeks to the
#     appropriate line and writes the Toc object as a string.
#     Uses logic similar to read_toc().
#
# Private method.

sub write_toc {
    my( $self, $fint ) = @_;

    my $ds = $self->datastore;

    my $tocfile = $self->tocfile( $fint );
    my $tocfh   = $ds->locked_for_write( $tocfile );
    my $toclen  = $ds->toclen;

    my $seekpos;
    if( my $tocmax = $ds->tocmax ) {
        my $skip = int( $fint / $tocmax );
        $seekpos = $toclen * ( $fint - ( $skip * $tocmax ) ); }
    else {
        $seekpos = $toclen * $fint; }

    my $tocline = $self->to_string;

    $ds->write_bytes( $tocfh, $seekpos, \$tocline );
    close $tocfh or croak qq/Can't close $tocfile: $!/;

    # write to tocs cache
    $ds->tocs->{ $tocfile }{'-M'}    = -M $tocfile;
    $ds->tocs->{ $tocfile }{ $fint } = $tocline;
}

#---------------------------------------------------------------------
# toc_getfnum(), called by tocfile() and init()
#     Takes an integer which denotes which datafile we want a toc
#     record for.  Calculates the tocfile file number where that
#     record should be found and returns the file number as an
#     integer.  In list context, returns both the integer and the
#     number in the C<fnumbase>.
#    
# Private method.

sub toc_getfnum {
    my( $self, $fint ) = @_;

    my $ds = $self->datastore;

    # get toc file number based on tocmax and fint
    my $tocfint;

    my  $tocmax = $ds->tocmax;
    if( $tocmax ) { $tocfint = int( $fint / $tocmax ) + 1 }
    else          { $tocfint = 1                          }

    my $fnumlen  = $ds->fnumlen;
    my $fnumbase = $ds->fnumbase;
    my $tocfnum  = int2base $tocfint, $fnumbase, $fnumlen;

    croak qq/Database exceeds configured size, tocfnum too long: $tocfnum/
        if length $tocfnum > $fnumlen;

    return( $tocfint, $tocfnum ) if wantarray;
    return  $tocfint;
}

#---------------------------------------------------------------------
# tocfile()
#     Takes an integer which denotes which datafile we want a toc
#     record for.  Returns the path of the tocfile where that record
#     should be found.
#    
# Private method.

sub tocfile {
    my( $self, $fint ) = @_;

    my $ds = $self->datastore;

    my $name = $ds->name;

    my( $tocfint, $tocfnum ) = $self->toc_getfnum( $fint );
    my $tocfile = $name . ( $ds->tocmax? ".$tocfnum": "") . ".toc";

    # get toc path based on dirlev, dirmax, and toc file number
    if( my $dirlev = $ds->dirlev ) {
        my $fnumlen  = $ds->fnumlen;
        my $fnumbase = $ds->fnumbase;
        my $dirmax   = $ds->dirmax;
        my $path     = "";
        my $this     = $tocfint;
        for( 1 .. $dirlev ) {
            my $dirint = $dirmax? (int( ( $this - 1 ) / $dirmax ) + 1): 1;
            my $dirnum = int2base $dirint, $fnumbase, $fnumlen;
            $path = $path? "$dirnum/$path": $dirnum;
            $this = $dirint;
        }
        $path = $ds->dir . "/$name/toc$path";
        mkpath( $path ) unless -d $path;
        $tocfile = "$path/$tocfile";
    }
    else {
        $tocfile = $ds->dir . "/$tocfile";
    }

    return $tocfile;
}

#---------------------------------------------------------------------

=head1 OBJECT METHODS: Accessors

The following read/write methods set and return their respective
attribute values if C<$value> is given.  Otherwise, they just return
the value.

 $record->datastore( [$value] )
 $record->string(    [$value] )

The following methods expect an integer parm and return an integer
value (even though these are stored in the tocfile as numbers in their
respective bases).

 $record->datafnum( [$value] )
 $record->keyfnum(  [$value] )
 $record->tocfnum(  [$value] )
 $record->numrecs(  [$value] )
 $record->keynum(   [$value] )
 $record->transnum( [$value] )
 $record->create(   [$value] )
 $record->oldupd(   [$value] )
 $record->update(   [$value] )
 $record->olddel(   [$value] )
 $record->delete(   [$value] )

=cut

sub datastore {for($_[0]->{datastore} ){$_=$_[1]if@_>1;return$_}}
sub string    {for($_[0]->{string}    ){$_=$_[1]if@_>1;return$_}}

sub datafnum  {for($_[0]->{datafnum}  ){$_=$_[1]if@_>1;return$_}}
sub keyfnum   {for($_[0]->{keyfnum}   ){$_=$_[1]if@_>1;return$_}}
sub tocfnum   {for($_[0]->{tocfnum}   ){$_=$_[1]if@_>1;return$_}}
sub numrecs   {for($_[0]->{numrecs}   ){$_=$_[1]if@_>1;return$_}}
sub keynum    {for($_[0]->{keynum}    ){$_=$_[1]if@_>1;return$_}}
sub transnum  {for($_[0]->{transnum}  ){$_=$_[1]if@_>1;return$_}}
sub create    {for($_[0]->{create}    ){$_=$_[1]if@_>1;return$_}}
sub oldupd    {for($_[0]->{oldupd}    ){$_=$_[1]if@_>1;return$_}}
sub update    {for($_[0]->{update}    ){$_=$_[1]if@_>1;return$_}}
sub olddel    {for($_[0]->{olddel}    ){$_=$_[1]if@_>1;return$_}}
sub delete    {for($_[0]->{delete}    ){$_=$_[1]if@_>1;return$_}}

__END__

=head1 AUTHOR

Brad Baxter, E<lt>bbaxter@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Brad Baxter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

