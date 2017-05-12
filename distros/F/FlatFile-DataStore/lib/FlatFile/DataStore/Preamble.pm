#---------------------------------------------------------------------
  package FlatFile::DataStore::Preamble;
#---------------------------------------------------------------------

=head1 NAME

FlatFile::DataStore::Preamble - Perl module that implements a flatfile
datastore preamble class.

=head1 SYNOPSYS

 use FlatFile::DataStore::Preamble;

 my $preamble = FlatFile::DataStore::Preamble->new( {
     datastore => $ds,         # FlatFile::DataStore object
     indicator => $indicator,  # single-character crud flag
     transind  => $transind,   # single-character crud flag
     date      => $date,       # pre-formatted date
     transnum  => $transint,   # transaction number (integer)
     keynum    => $keynum,     # record sequence number (integer)
     reclen    => $reclen,     # record length (integer)
     thisfnum  => $fnum,       # file number (in base format)
     thisseek  => $datapos,    # seek position (integer)
     prevfnum  => $prevfnum,   # ditto these ...
     prevseek  => $prevseek,
     nextfnum  => $nextfnum,
     nextseek  => $nextseek,
     user      => $user_data,  # pre-formatted user-defined data
     } );

 my $string = $preamble->string();

 my $clone = FlatFile::DataStore::Preamble->new( {
     datastore => $ds,
     string    => $string
     } );

=head1 DESCRIPTION

FlatFile::DataStore::Preamble - Perl module that implements a flatfile
datastore preamble class.  This class defines objects used by
FlatFile::DataStore::Record and FlatFile::DataStore.  You will
probably not ever call new() yourself, but you might call some of the
accessors either directly or via a FF::DS::Record object;

A "preamble" is a string of fixed-length fields that precedes every
record in a FlatFile::DataStore data file.  In addition, this string
constitutes the entry in the datastore key file for each current
record.

=head1 VERSION

FlatFile::DataStore::Preamble version 1.03

=cut

our $VERSION = '1.03';

use 5.008003;
use strict;
use warnings;

use Carp;

use Math::Int2Base qw( base_chars int2base base2int );

use Data::Omap qw( :ALL );

my %Generated = qw(
    string      1
    );

my %Attrs = ( %Generated, qw(
    indicator 1
    transind  1
    date      1
    transnum  1
    keynum    1
    reclen    1
    thisfnum  1
    thisseek  1
    prevfnum  1
    prevseek  1
    nextfnum  1
    nextseek  1
    user      1
    ) );

my $Ascii_chars = qr/^[ -~]+$/;

#---------------------------------------------------------------------

=head1 CLASS METHODS

=head2 FlatFile::DataStore::Preamble->new( $parms )

Constructs a new FlatFile::DataStore::Preamble object.

The parm C<$parms> is a hash reference containing key/value pairs to
populate the preamble string.  If there is a C<< $parms->{'string'} >>
value, it will be parsed into fields and the resulting key/value pairs
will replace the C<$parms> hash reference.

=cut

sub new {
    my( $class, $parms ) = @_;

    my $self = bless {}, $class;

    $self->init( $parms ) if $parms;
    return $self;
}

#---------------------------------------------------------------------
# init(), called by new() to parse the parms

sub init {
    my( $self, $parms ) = @_;

    my $datastore = $parms->{'datastore'} || croak qq/Missing: datastore/;

    if( my $string = $parms->{'string'} ) {
        $parms = $datastore->burst_preamble( $string );  # replace parms
    }

    my $crud = $datastore->crud();
    $self->crud( $crud );

    # single chars for character classes:
    my $create = quotemeta $crud->{'create'};
    my $update = quotemeta $crud->{'update'};
    my $delete = quotemeta $crud->{'delete'};
    my $oldupd = quotemeta $crud->{'oldupd'};
    my $olddel = quotemeta $crud->{'olddel'};

    # need these in validations below
    my $indicator = $parms->{'indicator'} || croak qq/Missing: indicator/;
    my $transind  = $parms->{'transind'}  || croak qq/Missing: transind/;
    $self->indicator( $indicator );
    $self->transind(  $transind );

    my $string = '';
    for my $href ( $datastore->specs() ) {  # each field is href of aref
        my( $field, $aref )     = %$href;
        my( $pos, $len, $parm ) = @$aref;
        my $value               = $parms->{ $field };

        for( $field ) {

            if( /indicator|transind/ ) {

                my $regx = qr/^[\Q$parm\E]{1,$len}$/;
                croak qq/Invalid value, $value, for: $_/ unless $value =~ $regx;

                # did these above
                # croak qq/Missing: $_/ unless defined $value;
                # $self->$_( $value );

                $string .= $value;
            }
            elsif( /date/ ) {

                croak qq/Missing: $_/ unless defined $value;
                croak qq/Invalid value, $value, for: $_/ unless length $value == $len;

                $self->$_( then( $value, $parm ) );
                $string .= $value;
            }
            elsif( /user/ ) {

                unless( defined $value ) {
                    $value = $datastore->userdata;
                    croak qq/Missing: $_/ unless defined $value;
                }

                my $try = sprintf "%-${len}s", $value;  # pads with blanks
                croak qq/Value, $try, too long for: $_/ if length $try > $len;

                my $regx = qr/^[$parm]+ *$/;  # $parm chars already escaped as needed
                croak qq/Invalid value, $value, for: $_/ unless $try =~ $regx;

                $self->$_( $value );
                $string .= $try;
            }
            elsif( not defined $value ) {

                if( ( /transnum|keynum|reclen|thisfnum|thisseek/               ) ||
                    ( /prevfnum|prevseek/ and $transind  =~ /[$update$delete]/ ) ||
                    ( /nextfnum|nextseek/ and $indicator =~ /[$oldupd$olddel]/ ) ){
                    croak qq/Missing: $_/;
                }

                $string .= '-' x $len;  # string of '-' for null
            }
            else {

                if( ( /prevfnum|prevseek/ and $indicator =~ /[$create]/        ) ||
                    ( /nextfnum|nextseek/ and $indicator =~ /[$update$delete]/ ) ){
                    croak qq/For indicator, $indicator, you may not set: $_/;
                }

                my $try = sprintf "%0${len}s", /fnum/? $value: int2base( $value, $parm );
                croak qq/Value, $try, too long for: $_/ if length $try > $len;

                $self->$_( /fnum/? $try: 0+$value );
                $string .= $try;
            }
        }
    }

    croak qq/Something is wrong with preamble: $string/
        unless $string =~ $datastore->regx();
    
    $self->string( $string );

    $self;  # returned
}

#---------------------------------------------------------------------

=head1 OBJECT METHODS: ACCESSORS

The following methods set and return their respective attribute values
if C<$value> is given.  Otherwise, they just return the value.

 $preamble->string(    $value ); # full preamble string
 $preamble->indicator( $value ); # single-character crud indicator
 $preamble->transind(  $value ); # single-character crud indicator
 $preamble->date(      $value ); # date as YYYY-MM-DD (hh:mm:ss)
 $preamble->transnum(  $value ); # transaction number (integer)
 $preamble->keynum(    $value ); # record sequence number (integer)
 $preamble->reclen(    $value ); # record length (integer)
 $preamble->thisfnum(  $value ); # file number (in base format)
 $preamble->thisseek(  $value ); # seek position (integer)
 $preamble->prevfnum(  $value ); # ditto these ...
 $preamble->prevseek(  $value ); # 
 $preamble->nextfnum(  $value ); # 
 $preamble->nextseek(  $value ); # 
 $preamble->user(      $value ); # pre-formatted user-defined data
 $preamble->crud(      $value ); # hash ref of all crud indicators

Note: the class code uses these accessors to set values in the object
as it is assembling the preamble string in new().  Unless you have a
really good reason, you should not set these values yourself (outside
of a call to new()).  For example: setting the date with date() will
I<not> change the date in the C<string> attribute.

In other words, even though these are read/write accessors, you should
only use them for reading.

=cut

sub string    {for($_[0]->{string}    ){$_=$_[1]if@_>1;return$_}}
sub indicator {for($_[0]->{indicator} ){$_=$_[1]if@_>1;return$_}}
sub transind  {for($_[0]->{transind}  ){$_=$_[1]if@_>1;return$_}}
sub crud      {for($_[0]->{crud}      ){$_=$_[1]if@_>1;return$_}}
sub date      {for($_[0]->{date}      ){$_=$_[1]if@_>1;return$_}}
sub user      {for($_[0]->{user}      ){$_=$_[1]if@_>1;return$_}}

sub keynum    {for($_[0]->{keynum}    ){$_=0+$_[1]if@_>1;return$_}}
sub reclen    {for($_[0]->{reclen}    ){$_=0+$_[1]if@_>1;return$_}}
sub transnum  {for($_[0]->{transnum}  ){$_=0+$_[1]if@_>1;return$_}}
sub thisfnum  {for($_[0]->{thisfnum}  ){$_=  $_[1]if@_>1;return$_}}
sub thisseek  {for($_[0]->{thisseek}  ){$_=0+$_[1]if@_>1;return$_}}
sub prevfnum  {for($_[0]->{prevfnum}  ){$_=  $_[1]if@_>1;return$_}}
sub prevseek  {for($_[0]->{prevseek}  ){$_=0+$_[1]if@_>1;return$_}}
sub nextfnum  {for($_[0]->{nextfnum}  ){$_=  $_[1]if@_>1;return$_}}
sub nextseek  {for($_[0]->{nextseek}  ){$_=0+$_[1]if@_>1;return$_}}

#---------------------------------------------------------------------

=head2 Convenience methods

=head3 is_created(), is_updated(), is_deleted();

These methods return true if the indicator matches the value implied by
the method name, e.g.,

 print "Deleted!" if $preamble->is_deleted();

=cut

sub is_created {
    my $self = shift;
    $self->indicator eq $self->crud->{'create'};
}
sub is_updated {
    my $self = shift;
    $self->indicator eq $self->crud->{'update'};
}
sub is_deleted {
    my $self = shift;
    $self->indicator eq $self->crud->{'delete'};
}

#---------------------------------------------------------------------
# then(), translates stored date to YYYY-MM-DD hh:mm:ss
#     Takes a date and a format and returns the date as
#     yyyy-mm-dd hh:mm:ss
#     If the format contains 'yyyy' it is assumed to have decimal
#     values for month, day, year, hours, minutes, seconds.
#     Otherwise, it is assumed to have base62 values for them.
#
# Private method.

sub then {
    my( $date, $format ) = @_;
    my( $yr, $mo, $da, $hr, $mn, $sc );
    my $tm = '';
    my $ret;
    for( $format ) {
        if( /yyyy/ ) {  # decimal
            $yr = substr $date, index( $format, 'yyyy'   ), 4;
            $mo = substr $date, index( $format, 'mm'     ), 2;
            $da = substr $date, index( $format, 'dd'     ), 2;
            if( (my $pos = index( $format, 'tttttt' )) > -1 ) {
                $tm = substr $date, $pos, 2;
                ( $hr, $mn, $sc ) = $tm =~ /(..)(..)(..)/;
                $tm = " $hr:$mn:$sc";
            }
        }
        else {          # base62
            $yr = substr $date, index( $format, 'yy'  ), 2;
            $mo = substr $date, index( $format, 'm'   ), 1;
            $da = substr $date, index( $format, 'd'   ), 1;

            $yr = sprintf "%04d", base2int( $yr, 62 );
            $mo = sprintf "%02d", base2int( $mo, 62 );
            $da = sprintf "%02d", base2int( $da, 62 );

            if( (my $pos = index( $format, 'ttt' )) > -1 ) {
                $tm = substr $date, $pos, 3;
                ( $hr, $mn, $sc ) = $tm =~ /(.)(.)(.)/;
                $hr = sprintf "%02d", base2int( $hr, 62 );
                $mn = sprintf "%02d", base2int( $mn, 62 );
                $sc = sprintf "%02d", base2int( $sc, 62 );
                $tm = " $hr:$mn:$sc";
            }
        }
    }
    return "$yr-$mo-$da$tm";
}

__END__

=head1 AUTHOR

Brad Baxter, E<lt>bbaxter@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Brad Baxter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

