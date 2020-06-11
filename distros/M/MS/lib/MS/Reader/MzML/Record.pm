package MS::Reader::MzML::Record;

use strict;
use warnings;

use parent qw/MS::Reader::XML::Record::CV/;

use Compress::Zlib;
use MIME::Base64;
use List::Util qw/first/;
use MS::CV qw/:MS :UO/;

# Abbreviate some constants
use constant NUMPRESS_LIN  => MS_MS_NUMPRESS_LINEAR_PREDICTION_COMPRESSION;
use constant NUMPRESS_PIC  => MS_MS_NUMPRESS_POSITIVE_INTEGER_COMPRESSION;
use constant NUMPRESS_SLOF => MS_MS_NUMPRESS_SHORT_LOGGED_FLOAT_COMPRESSION;

sub _pre_load {

    my ($self) = @_;

    # Lookup tables to quickly check elements
    $self->{_make_named_array} = {
        cvParam   => 'accession',
        userParam => 'name',
    };
    $self->{_make_anon_array} = { map {$_ => 1} qw/
        referenceableParamGroupRef
        product
        binaryDataArray
        precursor
        selectedIon
        scanWindow
        scan
    / };

}

sub _get_raw {

    my ($self, $array) = @_;
    return decode_base64( $array->{binary}->{pcdata} );

}

sub _get_code {

    my ($self, $array) = @_;

    return defined $self->param(MS_32_BIT_FLOAT,   ref => $array) ? 'f<'
         : defined $self->param(MS_64_BIT_FLOAT,   ref => $array) ? 'd<'
         : defined $self->param(MS_32_BIT_INTEGER, ref => $array) ? 'l<'
         : defined $self->param(MS_64_BIT_INTEGER, ref => $array) ? 'q<'
         : undef;

}

# binary arrays are only decoded upon request, to increase parse speed
sub get_array {

    my ($self, $acc) = @_;


    # fetch from cache if exists
    if ($self->{__use_cache} && exists $self->{__memoized}->{arrays}->{$acc}) {
        my $ret = $self->{__memoized}->{arrays}->{$acc};
        # return hash in array context, or first data array else
        return wantarray ? @$ret : $ret->[1];
    }

    # Find data array reference by CV accession
    my @arrays = grep {defined $self->param($acc, ref => $_)}
        @{ $self->{binaryDataArrayList}->{binaryDataArray} };

    my @ret;

    for my $array (@arrays) {

        # Extract metadata necessary to unpack array
        my $raw = $self->_get_raw($array);
        my $is_zlib  = 0;
        my $numpress = 'none';
        if (! defined $self->param(MS_NO_COMPRESSION, ref => $array) ) {
            $is_zlib  = defined $self->param(MS_ZLIB_COMPRESSION, ref => $array);
            $numpress
                = defined $self->param(NUMPRESS_LIN,  ref => $array) ? 'np-lin'
                : defined $self->param(NUMPRESS_PIC,  ref => $array) ? 'np-pic'
                : defined $self->param(NUMPRESS_SLOF, ref => $array) ? 'np-slof'
                : 'none';
            # Compression type (or lack thereof) MUST be specified!
            die "Uknown compression scheme (no known schemes specified) ??"
                if (! $is_zlib && $numpress eq 'none');
        }
        my $code = $self->_get_code($array);
    
        die "floating point precision required if numpress not used"
            if (! defined $code && $numpress eq 'none');

        my $data = _decode_raw(
            $raw,
            $code,
            $is_zlib,
            $numpress,
        );
        # Convert minutes to seconds
        if ($acc eq MS_TIME_ARRAY) {
        
            my ($t, $units) = $self->param(MS_TIME_ARRAY, ref => $array);
            if (defined $units && $units eq UO_MINUTE) {
                $data = [ map {$_*60} @{$data} ];
            }
        }

        # Sanity checks (no noticeable effect on speed during benchmarking)
        #die "ERROR: array data compressed length mismatch"
            #if ($is_compressed && $len != $array->{encodedLength});
        #my $c = scalar @{$data};
        #my $e = $self->{defaultArrayLength};
        #die "ERROR: array list count mismatch ($e v $c) for record"
            #if (scalar(@{$data}) != $self->{defaultArrayLength});


        my $name = $self->param($acc, ref => $array);
        push @ret, $name, $data;

    }

    $self->{__memoized}->{arrays}->{$acc} = [@ret] if ($self->{__use_cache});

    # return hash in array context, or first data array else
    return wantarray ? @ret : $ret[1];

}

sub _decode_raw {

    my ($data, $code, $is_zlib, $numpress) = @_;

    return [] if (length($data) < 1);

    $data = uncompress($data) if ($is_zlib);
    my $array;
    if ($numpress eq 'none') {
        $array = [ unpack "$code*", $data ];
    }
    elsif ($numpress eq 'np-pic') {
        $array = _decode_trunc_ints( $data );
    }
    elsif ($numpress eq 'np-slof') {
        $array = _decode_np_slof( $data );
    }
    elsif ($numpress eq 'np-lin') {
        $array = _decode_np_linear( $data );
    }

    return $array;

}

sub _decode_np_linear {

    my ($data) = @_;

    my $fp = unpack 'd>', substr($data,0,8,'');
    my @v  = unpack 'VV', substr($data,0,8,'');
    if (length $data) {
        push @v, 2*$v[-1] - $v[-2] + $_
            for ( @{ _decode_trunc_ints($data) } );
    }
    @v = map {$_/$fp} @v;

    return \@v;

}

sub _decode_np_slof {

    my ($data) = @_;

    my $fp = unpack 'd>', substr($data,0,8,'');
    my @v  = map {exp($_/$fp)-1} unpack 'v*', $data;

    return \@v;

}

sub _decode_trunc_ints {

    # Unpack string of truncated integer nybbles into longs

    my ($data) = (@_);

    my @nybbles;
    for (unpack 'C*', $data) {
        # push most-significant first!
        push @nybbles, ($_ >> 4);
        push @nybbles, ($_ & 0xf);
    }
    my $array;
    while (scalar(@nybbles)) {

        my $long = 0;
        my $head = shift @nybbles;
        # ignore trailing non-zero nybble
        last if (!scalar(@nybbles) && $head != 0x8);
        my $n = 0;
        if ($head <= 8) {
            $n = $head;
        }
        else {
            $n = $head - 8;
            my $shift = (8-$n)*4;
            $long = $long | ((0xffffffff >> $shift) << $shift);
        }

        my $i = $n;
        while ($i < 8) {
            my $nyb = shift @nybbles;
            $long = $long | ($nyb << (($i-$n)*4));
            ++$i;
        }
        $long = unpack 'l<', pack 'l<',$long; # cast to signed long - slow?
        push @{$array}, $long;
    }

    return $array;

}

#sub param {
#
    #my ($self, $cv, $idx) = @_;
    #$idx //= 0;
    #my $val   = $self->{cvParam}->{$cv}->[$idx]->{value};
    #my $units = $self->{cvParam}->{$cv}->[$idx]->{unitAccession};
    #return wantarray ? ($val, $units) : $val;
#
#}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MS::Reader::MzML::Record - The base class for MzML spectrum and chromatogram
records

=head1 SYNOPSIS

    use MS::Reader::MzML;

    while (my $spectrum = $run->next_spectrum) {
       
        # $spectrum inherits methods from MS::Reader::MzML::Record

    }

=head1 DESCRIPTION

C<MS::Reader::MzML::Record> is the base class for spectrum and chromatogram
records and is not intended to be used directly. However, the following
methods are inherited by those modules for public consumption.

=head1 METHODS


=head2 get_array

    my $z = $record->get_array($cv);
    my %z = $record->get_array($cv);

Takes a single argument (PSI:MS CV id for the data array type) and returns a
context-dependent value. In list context, returns a hash where keys are the
free-form array names and values are the data array references. In scalar
context, returns an data array reference for the first array found. Subclasses
wrap this in methods to return specific array types (e.g. m/z, intensity,
retention time) but it can also be used directly to return other data arrays,
if available.  Applicable constants exported by the L<MS::CV> module include:

=over

=item * MS_M_Z_ARRAY

=item * MS_INTENSITY_ARRAY

=item * MS_TIME_ARRAY

=item * MS_CHARGE_ARRAY

=item * MS_SIGNAL_TO_NOISE_ARRAY

=item * MS_WAVELENGTH_ARRAY

=item * MS_RESOLUTION_ARRAY

=item * MS_BASELINE_ARRAY

=item * MS_FLOWRATE_ARRAY

=item * MS_PRESSURE_ARRAY

=item * MS_TEMPERATURE_ARRAY

=item * MS_MEAN_DRIFT_TIME_ARRAY

=item * MS_MEAN_CHARGE_ARRAY

=item * MS_NON_STANDARD_DATA_ARRAY

=back

=head2 param

    my $val = $record->param($cv_id);
    my $val = $record->param($cv_id => 2);
    my ($val,$units) = $record->param($cv_id);

Takes as an argument a PSI:MS CV ID and optionally an index of the annotation
to return. In scalar context, returns the value associated with the CV term or
undef if the term is not present. In list context, returns the value of the
term and the CV ID of the units assigned to it. By default, the first term
with the given CV ID is used, although it is legal (but not common) for a CV
term to be applied multiple times to a record.

=head1 CAVEATS AND BUGS

The API is in alpha stage and is not guaranteed to be stable.

Please reports bugs or feature requests through the issue tracker at
L<https://github.com/jvolkening/p5-MS/issues>.

=head1 AUTHOR

Jeremy Volkening <jdv@base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2016 Jeremy Volkening

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
