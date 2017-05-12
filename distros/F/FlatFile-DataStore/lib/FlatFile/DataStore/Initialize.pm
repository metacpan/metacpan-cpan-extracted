#---------------------------------------------------------------------
  package FlatFile::DataStore;  # not FlatFile::DataStore::Initialize
#---------------------------------------------------------------------

=head1 NAME

FlatFile::DataStore::Initialize - Provides routines that are used
only when initializing a datastore

=head1 SYNOPSYS

 require FlatFile::DataStore::Initialize;

(But this is done only in FlatFile/DataStore.pm)

=head1 DESCRIPTION

FlatFile::DataStore::Initialize provides the routines that
are used only when a datastore is initialized.  It isn't a
"true" module; it's intended for loading more methods in the
FlatFile::DataStore class.

=head1 VERSION

FlatFile::DataStore::Initialize version 1.03

=cut

our $VERSION = '1.03';

use 5.008003;
use strict;
use warnings;

use URI;
use URI::Escape;
use Digest::MD5 qw(md5_hex);
use Data::Dumper;
use Carp;

use Math::Int2Base qw( base_chars int2base base2int );
use Data::Omap qw( :ALL );

#---------------------------------------------------------------------
# burst_query(), called by init() to parse the datastore's uri
#     Takes a hash ref to the %Preamble attribute hash, so it can
#     know which parts of the uri belong in the preamble.
#     Then it gets the uri from the datastore object and parses it.
#     It loads all of the values it gets (and generates) in to a
#     hash ref which it returns.
#
# Private method.

sub burst_query {
    my( $self, $Preamble ) = @_;

    my $uri   = $self->uri;
    my $query = URI->new( $uri )->query();

    my @pairs = split /[;&]/, $query;
    my $omap  = [];  # psuedo-new(), ordered hash
    my $pos   = 0;
    my %parms;
    my $load_parms = sub {
        my( $name, $val ) = split /=/, $_[0], 2;

        $name = uri_unescape( $name );
        $val  = uri_unescape( $val );

        croak qq/Parm duplicated in uri: $name/ if $parms{ $name };

        $parms{ $name } = $val;
        if( $Preamble->{ $name } ) {
            my( $len, $parm ) = split /-/, $val, 2;
            croak qq/Value must be format 'length-parm': $name=$val/
                unless defined $len and defined $parm;
            omap_add( $omap, $name => [ $pos, 0+$len, $parm ] );
            $pos += $len;
        }
    };
    for( @pairs ) {
        if( /^defaults=(.*)/ ) {
            $load_parms->( $_ ) for defaults( $1 );
            next;
        }
        $load_parms->( $_ );
    }

    # some attributes are generated here:
    $parms{'specs'}       = $omap;
    $parms{'preamblelen'} = $pos;

    return \%parms;
}

#---------------------------------------------------------------------
# defaults()
#     This routine provides some default values for the datastore
#     configuration uri.  It takes the default you want, one of
#     xsmall  xsmall_nohist
#      small   small_nohist
#     medium  medium_nohist
#      large   large_nohist
#     xlarge  xlarge_nohist
#     and it returns the default values as an array of key/value
#     strings, ready to include in a uri.
#
# Private method.

sub defaults {
    my( $want ) = @_;

    my $ind = uri_escape( "1-+#=*-" );

    my @xsmall_nohist = (
        "indicator=$ind",
        "transind=$ind",
        "date=7-yymdttt",
        "transnum=2-62",   # 3,843 transactions
        "keynum=2-62",     # 3,843 records
        "reclen=2-62",     # 3,843 bytes/record
        "thisfnum=1-36",   # 35 data files
        "thisseek=4-62",   # 14,776,335 bytes/file
    );
    my @xsmall = (
        @xsmall_nohist,
        "prevfnum=1-36",
        "prevseek=4-62",
        "nextfnum=1-36",
        "nextseek=4-62",
    );

    my @small_nohist = (
        "indicator=$ind",
        "transind=$ind",
        "date=7-yymdttt",
        "transnum=3-62",   # 238,327 transactions
        "keynum=3-62",     # 238,327 records
        "reclen=3-62",     # 238,327 bytes/record
        "thisfnum=1-36",   # 35 data files
        "thisseek=5-62",   # 916,132,831 bytes/file
    );
    my @small = (
        @small_nohist,
        "prevfnum=1-36",
        "prevseek=5-62",
        "nextfnum=1-36",
        "nextseek=5-62",
    );

    my @medium_nohist = (
        "indicator=$ind",
        "transind=$ind",
        "date=7-yymdttt",
        "transnum=4-62",   # 14,776,335 transactions
        "keynum=4-62",     # 14,776,335 records
        "reclen=4-62",     # 14,776,335 bytes/record
        "thisfnum=2-36",   # 1,295 data files
        "thisseek=5-62",   # 916,132,831 bytes/file
    );
    my @medium = (
        @medium_nohist,
        "prevfnum=2-36",
        "prevseek=5-62",
        "nextfnum=2-36",
        "nextseek=5-62",
    );

    my @large_nohist = (
        "datamax=1.9G",
        "dirmax=300",
        "keymax=100_000",
        "indicator=$ind",
        "transind=$ind",
        "date=7-yymdttt",
        "transnum=5-62",   # 916,132,831 transactions
        "keynum=5-62",     # 916,132,831 records
        "reclen=5-62",     # 916,132,831 bytes/record
        "thisfnum=3-36",   # 46,655 data files
        "thisseek=6-62",   # 56G per file (but see datamax)
    );
    my @large = (
        @large_nohist,
        "prevfnum=3-36",
        "prevseek=6-62",
        "nextfnum=3-36",
        "nextseek=6-62",
    );

    my @xlarge_nohist = (
        "datamax=1.9G",
        "dirmax=300",
        "dirlev=2",
        "keymax=100_000",
        "tocmax=100_000",
        "indicator=$ind",
        "transind=$ind",
        "date=7-yymdttt",
        "transnum=6-62",   # 56B transactions
        "keynum=6-62",     # 56B records
        "reclen=6-62",     # 56G per record
        "thisfnum=4-36",   # 1,679,615 data files
        "thisseek=6-62",   # 56G per file (but see datamax)
    );
    my @xlarge = (
        @xlarge_nohist,
        "prevfnum=4-36",
        "prevseek=6-62",
        "nextfnum=4-36",
        "nextseek=6-62",
    );

    my $ret = {
        xsmall        => \@xsmall,
        xsmall_nohist => \@xsmall_nohist,
        small         => \@small,
        small_nohist  => \@small_nohist,
        medium        => \@medium,
        medium_nohist => \@medium_nohist,
        large         => \@large,
        large_nohist  => \@large_nohist,
        xlarge        => \@xlarge,
        xlarge_nohist => \@xlarge_nohist,
    }->{ $want };

    croak qq/Unrecognized defaults: $want/ unless $ret;
    @$ret;  # returned
}

#---------------------------------------------------------------------
# make_preamble_regx(), called by init() to construct a regular
#     expression that should match any record's preamble.
#     This regx should capture each field's value.
#
# Private method.

sub make_preamble_regx {
    my( $self ) = @_;

    my $regx = "";
    for( $self->specs ) {  # specs() returns an array of hashrefs
        my( $key, $aref )       = %$_;
        my( $pos, $len, $parm ) = @$aref;

        for( $key ) {
            if( /indicator/ or /transind/ ) {
                $regx .= ($len == 1 ? "([\Q$parm\E])" : "([\Q$parm\E]{$len})");
            }
            elsif( /user/ ) {
                # XXX should only allow $Ascii_chars, not checked here
                # (metachars in $parm should already be escaped as needed)
                $regx .= ($len == 1 ? "([$parm])" : "([$parm]{$len})");
            }
            elsif( /date/ ) {
                # XXX regx makes no attempt to insure an actual valid date
                # XXX this code needs to barf on, e.g., yyyyyyyy ...
                # e.g., yyyymmdd(8) yyyymmddtttttt(14) yymd(4) yymdttt(7)
                croak qq/Invalid date length: $len/
                    unless $len =~ /^(?:4|7|8|14)$/;
                croak qq/Date length doesn't match format: $len-$parm/
                    unless $len == length $parm;
                $regx .= ($len < 8 ? "([0-9A-Za-z]{$len})" : "([0-9]{$len})");
            }
            else {
                my $chars = base_chars( $parm );
                $chars =~ s/([0-9])[0-9]+([0-9])/$1-$2/;  # compress
                $chars =~ s/([A-Z])[A-Z]+([A-Z])/$1-$2/;
                $chars =~ s/([a-z])[a-z]+([a-z])/$1-$2/;
                # '-' is 'null' character:
                $regx .= ($len == 1 ? "([-$chars])" : "([-$chars]{$len})");
            }
        }
    }
    return qr/$regx/;
}

#---------------------------------------------------------------------
# make_crud(), called by init() to construct a hash of CRUD indicators
#     (CRUD: Create, Retrieve, Update, Delete)
#     the following are suggested, but configurable in the uri
#         + Create
#         # Old Update (old record flagged as updated)
#         = Update
#         * Old Delete (old record flagged as deleted)
#         - Delete
#     (no indicator for Retrieve, n/a--but didn't want to say CUD)
#     Note that a reverse set is included, e.g., '+' => 'create' as
#     well as create => '+'.
#
# Private method.

sub make_crud {
    my( $self ) = @_;

    my( $len, $chars ) = split /-/, $self->indicator, 2;
    croak qq/Only single-character indicators supported/ if $len != 1;

    my @c = split //, $chars;
    my %c = map { $_ => 1 } @c;
    my @n = keys %c;
    croak qq/Need five unique indicator characters/ if @n != 5 or @c != 5;

    my %crud;
    @crud{ qw( create oldupd update olddel delete ) } = @c;
    @crud{ @c } = qw( create oldupd update olddel delete );
    return \%crud;
}

#---------------------------------------------------------------------
# convert_max(), called by init() to convert user-supplied max values
#     (datamax, keymax, etc.) into an integer.
#     One can say, "500_000_000", "500M", or ".5G" to mean
#     500,000,000 bytes
#
# Private method.

sub convert_max {
    my( $max ) = @_;

    # ignoring M/G ambiguities and using round numbers:
    my %sizes = ( M => 10**6, G => 10**9 );

    $max =~ s/_//g;
    if( $max =~ /^([.0-9]+)([MG])/ ) {
        my( $n, $s ) = ( $1, $2 );
        $max = $n * $sizes{ $s };
    }

    return 0+$max;
}

#---------------------------------------------------------------------
# initialize(), called by init() when datastore is first used
#     adds a serialized object to the uri file to bypass uri
#     parsing from then on
#
# Private method.

sub initialize {
    my( $self ) = @_;

    # can't initialize after data has been added

    my $fnum     = int2base 1, $self->fnumbase, $self->fnumlen;
    my $datafile = $self->which_datafile( $fnum );
    croak qq/Can't initialize database (data files exist): $datafile/
        if -e $datafile;

    # make object a one-liner
    local $Data::Dumper::Quotekeys = 0;
    local $Data::Dumper::Pair      = '=>';
    local $Data::Dumper::Useqq     = 1;
    local $Data::Dumper::Terse     = 1;
    local $Data::Dumper::Indent    = 0;

    # delete dir, don't want it in obj file
    my $savedir = $self->dir;
    $self->dir("");

    my $uri_file = "$savedir/" . $self->name . ".uri";
    my $uri = $self->uri;
    my $obj = Dumper $self;
    my $uri_md5 = md5_hex( $uri );
    my $obj_md5 = md5_hex( $obj );
    my $contents = <<_end_;
$uri
$obj
$uri_md5
$obj_md5
_end_
    $self->write_file( $uri_file, \$contents );

    # restore dir
    $self->dir( $savedir );

}

#---------------------------------------------------------------------
# write_file(), dump contents to file
#     Takes a file name and some "contents", locks it for writing,
#     and writes the contents to the file.  The $contents parameter
#     is expected to be a string, a scalar reference, or an array 
#     reference.  The lines in this array should already end with
#     newline, if they're expected to be that way in the file.
#
# Private method.

sub write_file {
    my( $self, $file, $contents ) = @_;

    my $fh = $self->locked_for_write( $file );
    my $type = ref $contents;
    if( $type ) {
        if   ( $type eq 'SCALAR' ) { print $fh $$contents               }
        elsif( $type eq 'ARRAY'  ) { print $fh join "", @$contents      }
        else                       { croak qq/Unrecognized type: $type/ }
    }
    else { print $fh $contents }
    close $fh or die "Can't close $file: $!";
}

1;  # returned

__END__

=head1 AUTHOR

Brad Baxter, E<lt>bbaxter@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Brad Baxter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

