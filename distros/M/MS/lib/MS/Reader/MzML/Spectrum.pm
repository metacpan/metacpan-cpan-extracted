package MS::Reader::MzML::Spectrum;

use strict;
use warnings;

use parent qw/MS::Spectrum MS::Reader::MzML::Record/;

use Carp;
use MS::CV qw/:MS :UO/;

sub _pre_load {

    my ($self) = @_;
    $self->{_toplevel} = 'spectrum';
    $self->SUPER::_pre_load();

}

sub id { return $_[0]->{id} };

sub ms_level {

    my ($self) = @_;
    my $given = $self->param(MS_MS_LEVEL);
    return defined $self->param(MS_MS1_SPECTRUM) ? 1
         : defined $given                        ? $given
         : croak "Undefined MS level";

}

sub mz {

    my ($self) = @_;
    return $self->get_array(MS_M_Z_ARRAY);

}

sub int {

    my ($self) = @_;
    return $self->get_array(MS_INTENSITY_ARRAY);

}

sub rt {

    # get retention time in seconds
    #
    my ($self) = @_;

    croak "rt() only valid for single scan spectra, use direct access.\n"
        if ($self->{scanList}->{count} != 1);
    my $scan = $self->{scanList}->{scan}->[0];
    my ($rt, $units)   = $self->param(MS_SCAN_START_TIME, ref => $scan);
    croak "missing RT value" if (! defined $rt);
    $rt *= 60 if ($units eq UO_MINUTE);
    
    return $rt;
 
 }

 sub precursor {

    my ($self) = @_;
    croak "precursor() only valid for MSn spectra"
        if ($self->param(MS_MS_LEVEL) < 2);
    croak "precursor() only valid for single precursor spectra, use direct access.\n"
        if ($self->{precursorList}->{count} != 1);
    my $pre = $self->{precursorList}->{precursor}->[0];
    my $id  = $pre->{spectrumRef};
    my $win = $pre->{isolationWindow};
    my $iso_mz = $self->param(MS_ISOLATION_WINDOW_TARGET_M_Z,   ref => $win);
    my $iso_l  = $self->param(MS_ISOLATION_WINDOW_LOWER_OFFSET, ref => $win);
    my $iso_u  = $self->param(MS_ISOLATION_WINDOW_UPPER_OFFSET, ref => $win);
    croak "missing precursor id"    if (! defined $id);
    croak "missing precursor m/z"   if (! defined $iso_mz);
    croak "missing precursor lower" if (! defined $iso_l);
    croak "missing precursor upper" if (! defined $iso_u);

    croak "precursor() only valid for single precursor spectra, use direct access.\n"
        if ($pre->{selectedIonList}->{count} != 1);
    my $ion = $pre->{selectedIonList}->{selectedIon}->[0];
    my $charge  = $self->param(MS_CHARGE_STATE,     ref => $ion);
    my $mono_mz = $self->param(MS_SELECTED_ION_M_Z, ref => $ion);
    my $int     = $self->param(MS_PEAK_INTENSITY,   ref => $ion);
    croak "missing monoisotopic m/z" if (! defined $mono_mz);
    return {
        scan_id   => $id,
        iso_mz    => $iso_mz,
        iso_lower => $iso_mz - $iso_l,
        iso_upper => $iso_mz + $iso_u,
        mono_mz   => $mono_mz,
        charge    => $charge,
        intensity => $int,
    };

}

sub scan_window {

    my ($self, $i) = @_; 
    $i //= 0;
    
    my $win =
        $self->{scanList}->{scan}->[$i]->{scanWindowList}->{scanWindow}->[0];
    my $l = $self->param(MS_SCAN_WINDOW_LOWER_LIMIT, ref => $win);
    my $r = $self->param(MS_SCAN_WINDOW_UPPER_LIMIT, ref => $win);

    return undef if (! defined $l || ! defined $r);
    return [$l, $r];

}

sub scan_number {

    my ($self) = @_;
    if ($self->{id} =~ /\bscan=(\d+)/) {
        return $1;
    }
    return undef;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MS::Reader::MzML::Spectrum - An MzML spectrum object

=head1 SYNOPSIS

    use MS::Reader::MzML;
    use MS::CV qw/:MS/;

    my $run = MS::Reader::MzML->new('run.mzML');

    while (my $spectrum = $run->next_spectrum) {
        
        # $spectrum inherits from MS::Spectrum, so you can do:
        my $id  = $spectrum->id;
        my $rt  = $spectrum->rt;
        my $mz  = $spectrum->mz;
        my $int = $spectrum->int;
        my $lvl = $spectrum->ms_level;

        # $spectrum inherits from MS::Reader::MzML::Record, so you can do:
        my $tc  = $spectrum->param(MS_TOTAL_ION_CURRENT);
        my $sn  = $spectrum->get_array(MS_CHARGE_ARRAY); # if present

        # in addition,

        my $precursor = $spectrum->precursor;
        my $pre_mz    = $precursor->{mono_mz};
        my $pre_mz    = $precursor->{mono_mz};

        my $scan_num  = $spectrum->scan_number;
        my $scan_win  = $spectrum->scan_window;

        # or access the guts directly (yes, it's okay!)
        my $peak_count = $spectrum->{defaultArrayLength};

        # print the underlying data structure
        $spectrum->dump;

    }

=head1 DESCRIPTION

C<MS::Reader::MzML::Spectrum> objects represent spectra parsed from an mzML
file. The class is an implementation of L<MS::Spectrum> and so implements the
standard data accessors associated with that class, as well as a few extra, as
documented below. The underlying hash is a nested data structure containing
all information present in the original mzML record. This information can be
accessed directly (see below for details of the data structure) when class
methods do not exist for doing so.

=head1 METHODS

=head2 id
    
    my $id = $spectrum->id;

Returns the native ID of the spectrum

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

=head2 param, get_array

See L<MS::Reader::MzML::Record>

=head2 precursor

    my $pre = $spectrum->precursor;
    my $pre_mz = $pre->{mono_mz};

Returns a hash reference containing information about the precursor ion
for MSn spectra. Throws an exception if called on an MS1 spectrum. Note that
this information is pulled directly from the MSn record. The actual
spectrum object for the precursor ion could be fetched e.g. by:

    my $pre_idx = $run->get_index_by_id( 'spectrum' => $pre->{scan_id} );
    my $pre_obj = $run->fetch_spectrum( $pre_idx );

=head2 scan_number

    my $scan = $spectrum->scan_number;

Attempts to parse and return the scan number of the spectrum from the spectrum
id. Returns the scan number as an integer or undef if it cannot be determined.

NOTE: Currently this is only implemented for Thermo native IDs in the form of
"controllerType=0 controllerNumber=1 scan=10001". Hopefully this will be
expanded in the future.

=head2 scan_window

    my $limits = $spectrum->scan_window;
    my ($lower, $upper) = @$limits;

Returns an array reference to the lower and upper limits of the scan window(s)
of the array, in m/z.

=head1 CAVEATS AND BUGS

The API is in alpha stage and is not guaranteed to be stable.

Please reports bugs or feature requests through the issue tracker at
L<https://github.com/jvolkening/p5-MS/issues>.

=head1 SEE ALSO

=over 4

=item * L<MS::Spectrum>

=item * L<MS::Reader::MzML::Record>

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
