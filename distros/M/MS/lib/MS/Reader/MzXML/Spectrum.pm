package MS::Reader::MzXML::Spectrum;

use strict;
use warnings;

use parent qw/MS::Reader::XML::Record/;

use Compress::Zlib;
use MIME::Base64;
use List::Util qw/first/;
use Carp;

BEGIN {

    *id = \&scan_number

}

sub _pre_load {

    my ($self) = @_;

    $self->{_toplevel} = 'scan';

    # Lookup tables to quickly check elements
    $self->{_make_named_hash} = {
        nameValue           => 'name',
        peaks               => 'contentType',
    };
    $self->{_make_anon_array} = { map {$_ => 1} qw/
        scanOrigin
        precursorMz
        comment
    / };

}

sub _post_load {

    my ($self) = @_;

    # Nested scans don't work with the current infrastructure (plus we never
    # use this format). Could be supported in future if there was demand.
    croak "Nested scans in mzXML not currently supported!"
        if (exists $self->{scan}->{scan});

}
sub ms_level {

    my ($self) = @_;

    croak "Invalid mzXML (missing msLevel property)"
        if (! defined $self->{msLevel});

    return $self->{msLevel};

}

sub rt {

    my ($self) = @_;

    return undef if (! defined $self->{retentionTime});

    if ($self->{retentionTime} =~ /^PT(?:([\d\.]+)M)?(?:([\d\.]+)S)?/) {
        my $s = 0;
        $s += $1*60 if (defined $1);
        $s += $2    if (defined $2);
        return $s;
    }

    croak "Unexpected retention time format: $self->{retentionTime}";

}

sub scan_number {

    my ($self) = @_;

    croak "Invalid mzXML (missing scan number property)"
        if (! defined $self->{num});

    return $self->{num};

}

sub precursor {

    my ($self) = @_;
    croak "precursor() only valid for MS2 spectra"
        if ($self->{msLevel} < 2);
    croak "precursor() only valid for single precursor spectra, use direct access.\n"
        if (scalar @{$self->{precursorMz}} != 1);

    my $pre       = $self->{precursorMz}->[0];
    my $id        = $pre->{precursorScanNum};
    my $mono_mz   = $pre->{pcdata};
    my $iso_mz    = $mono_mz;
    my $iso_lower = $iso_mz - $pre->{windowWideness}/2;
    my $iso_upper = $iso_mz + $pre->{windowWideness}/2;
    my $charge    = $pre->{precursorCharge};
    my $int       = $pre->{precursorIntensity};

    croak "missing monoisotopic m/z" if (! defined $mono_mz);
    return {
        scan_id   => $id,
        iso_mz    => $iso_mz,
        iso_lower => $iso_lower,
        iso_upper => $iso_upper,
        mono_mz   => $mono_mz,
        charge    => $charge,
        intensity => $int,
    };

}

sub mz {

    my ($self) = @_;

    return $self->{__mz} if (exists $self->{__mz});

    if (defined $self->{peaks}->{'m/z'}) {
        $self->{__mz} = $self->get_array('m/z');
    }
    elsif (defined $self->{peaks}->{'m/z-int'}) {
        my $v = $self->get_array('m/z-int');
        my $l = scalar(@$v)/2;
        croak "Odd-numbered m/z-int array" if ( ($l%2) != 0);
        $self->{__mz}  = [ map {$v->[$_]} map {$_*2}   (0..$l-1) ];
        $self->{__int} = [ map {$v->[$_]} map {$_*2+1} (0..$l-1) ];
    }
    else {
        croak "m/z array undefined";
    }

    return $self->{__mz};

}

sub int {

    my ($self) = @_;

    return $self->{__int} if (exists $self->{__int});

    if (defined $self->{peaks}->{'intensity'}) {
        $self->{__int} = $self->get_array('intensity');
    }
    elsif (defined $self->{peaks}->{'m/z-int'}) {
        my $v = $self->get_array('m/z-int');
        my $l = scalar(@$v)/2;
        croak "Odd-numbered m/z-int array" if ( ($l%2) != 0);
        $self->{__mz}  = [ map {$v->[$_]} map {$_*2}   (0..$l-1) ];
        $self->{__int} = [ map {$v->[$_]} map {$_*2+1} (0..$l-1) ];
    }
    else {
        croak "intensity array undefined";
    }

    return $self->{__int};

}

sub get_array {

    my ($self, $type) = @_;

    my $ref = $self->{peaks}->{$type};
    croak "Undefined array type $type" if (! defined $ref);

    my $data = decode_base64( $ref->{pcdata} );
    $data    = uncompress($data) if ($ref->{compressionType} eq 'zlib');
    my $code = $ref->{precision} eq '64' ? 'd>' : 'f>';
    return [ unpack "$code*", $data ];

}

sub scan_window {

    my ($self) = @_; 
    
    my $l = $self->{startMz} // $self->{lowMz};
    my $r = $self->{endMZ}   // $self->{highMz};

    return undef if (! defined $l || ! defined $r);
    return [$l, $r];

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MS::Reader::MzXML::Spectrum - An MzXML spectrum object

=head1 SYNOPSIS

    use MS::Reader::MzXML;

    my $run = MS::Reader::MzXML->new('run.mzXML');

    while (my $spectrum = $run->next_spectrum) {
       
        # Note that these two methods are functionally identical
        my $id        = $spectrum->id;
        my $scan_num  = $spectrum->scan_number;

        my $rt  = $spectrum->rt;
        my $mz  = $spectrum->mz;
        my $int = $spectrum->int;
        my $lvl = $spectrum->ms_level;

        # $spectrum inherits from MS::Reader::MzML::Record, so you can do:
        my $tc  = $spectrum->param(MS_TOTAL_ION_CURRENT);
        my $sn  = $spectrum->get_array(MS_CHARGE_ARRAY); # if present

        # in addition,

        my $z  = $spectrum->get_array('charge'); # if present
        my $precursor = $spectrum->precursor;
        my $pre_mz    = $precursor->{mono_mz};
        my $pre_mz    = $precursor->{mono_mz};

        # or access the guts directly (yes, it's okay!)
        my $current = $spectrum->{totIonCurrent};

        # print the underlying data structure
        $spectrum->dump;

    }

=head1 DESCRIPTION

C<MS::Reader::MzXML::Spectrum> objects represent spectra parsed from an mzXML
file. The class is an implementation of L<MS::Spectrum> and so implements the
standard data accessors associated with that class, as well as a few extra, as
documented below. The underlying hash is a nested data structure containing
all information present in the original mzXML record. This information can be
accessed directly (see below for details of the data structure) when class
methods do not exist for doing so.

=head1 METHODS

=head2 mz

    my $mz = $spectrum->mz;
    for (@$mz) { # do something }

Returns an array reference to the m/z data array

=head2 int

    my $int = $spectrum->int;
    for (@$int) { # do something }

Returns an array reference to the peak intensity data array

=head2 rt

    my $rt = $spectrum->rt;

Returns the retention time of the spectra, in SECONDS

=head2 ms_level

    my $l = $spectrum->ms_level;

Returns the MS level of the spectrum as a positive integer

=head2 get_array

    my $a = $spectrum->get_array('type');

    Returns an array reference to the data array specified. Type can be one of
    I<m/z-int|m/z|intensity|m/z ruler|TOF|S/N|charge>. Not all arrays will be
    present in all files. Note that mz/intensity pairs can be represented by
    individual 'm/z' and 'intensity' arrays or by a single interleaved
    'm/z-int' array. The C<mz()> and C<int()> methods take care of figuring
    this out for you.

=head2 precursor

    my $pre = $spectrum->precursor;
    my $pre_mz = $pre->{mono_mz};

Returns a hash reference containing information about the precursor ion
for MSn spectra. Throws an exception if called on an MS1 spectrum. Note that
this information is pulled directly from the MSn record. The actual
spectrum object for the precursor ion could be fetched e.g. by:

    my $pre_idx = $run->get_index_by_id( 'spectrum' => $pre->{scan_num} );
    my $pre_obj = $run->fetch_spectrum( $pre_idx );

=head2 id

=head2 scan_number

    my $scan = $spectrum->scan_number;
    my $id   = $spectrum->id;

Returns the scan number of the spectrum. Since mzXML spectrum records have no
'id' attribute per se, the C<id()> method is simply a link to the
C<scan_number> method as the unique identifier.

=head2 scan_window

    my $limits = $spectrum->scan_window;
    my ($lower, $upper) = @$limits;

Returns an array reference to the lower and upper limits of the scan window(s)
of the array, in m/z. If not available, returns the lowest and highest
observed m/z (from annotations). Otherwise returns undef.

=head1 CAVEATS AND BUGS

The API is in alpha stage and is not guaranteed to be stable.

Please reports bugs or feature requests through the issue tracker at
L<https://github.com/jvolkening/p5-MS/issues>.

=head1 SEE ALSO

=over 4

=item * L<MS::Spectrum>

=back

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
