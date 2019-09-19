package MS::Reader::ImzML::Spectrum;

use strict;
use warnings;

use parent qw/MS::Reader::MzML::Spectrum/;

use Carp;
use MS::CV qw/:MS :IMS/;

sub _get_raw {

    my ($self, $array) = @_;

    # if external data flag not set, use inherited method
    return $self->SUPER::_raw_data($array)
        if (! defined $self->param(IMS_EXTERNAL_DATA, ref => $array) );

    my $offset  = $self->param(IMS_EXTERNAL_OFFSET,         ref => $array);
    my $length  = $self->param(IMS_EXTERNAL_ENCODED_LENGTH, ref => $array);
    my $alength = $self->param(IMS_EXTERNAL_ARRAY_LENGTH,   ref => $array);

    my $fh = $self->{__fh_ibd};
    seek($fh, $offset, 0) or croak "Error seeking in IBD: $@";
    my $r = read($fh, my $data, $length);
    croak "Read length mismatch" if ($r != $length);

    return $data;

}

sub _get_code {

    my ($self, $array) = @_;

    return defined $self->param(IMS_8_BIT_INTEGER,  ref => $array) ? 'c'
         : defined $self->param(IMS_16_BIT_INTEGER, ref => $array) ? 's<'
         : defined $self->param(IMS_32_BIT_INTEGER, ref => $array) ? 'l<'
         : defined $self->param(IMS_64_BIT_INTEGER, ref => $array) ? 'q<'
         : $self->SUPER::_get_code($array);

}

sub x {

    my ($self) = @_;
    croak "Multiple scans in single spectrum not supported"
        if ($self->{scanList}->{count} != 1);
    my $ref = $self->{scanList}->{scan}->[0];
    my $v = $self->param(IMS_POSITION_X, ref => $ref);
    return $v;

}

sub y {

    my ($self) = @_;
    croak "Multiple scans in single spectrum not supported"
        if ($self->{scanList}->{count} != 1);
    my $ref = $self->{scanList}->{scan}->[0];
    my $v = $self->param(IMS_POSITION_Y, ref => $ref);
    return $v

}

sub z {

    my ($self) = @_;
    croak "Multiple scans in single spectrum not supported"
        if ($self->{scanList}->{count} != 1);
    my $ref = $self->{scanList}->{scan}->[0];
    my $v = $self->param(IMS_POSITION_Z, ref => $ref);
    return $v

}

sub coords {

    my ($self) = @_;
    return (
        $self->x,
        $self->y,
        $self->z,
    );

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MS::Reader::ImzML::Spectrum - An ImzML spectrum object

=head1 SYNOPSIS

    use MS::Reader::ImzML;

    my $run = MS::Reader::ImzML->new('run.imzML');

    while (my $spectrum = $run->next_spectrum) {
        
        # $spectrum inherits from MS::Reader::MzML::Spectrum, so you can do:
        my $id  = $spectrum->id;
        my $mz  = $spectrum->mz;
        my $int = $spectrum->int;
        my $lvl = $spectrum->ms_level;

        my $tc  = $spectrum->param(MS_TOTAL_ION_CURRENT);
        my $sn  = $spectrum->get_array(MS_CHARGE_ARRAY); # if present

        my $precursor = $spectrum->precursor;
        my $pre_mz    = $precursor->{mono_mz};
        my $pre_mz    = $precursor->{mono_mz};

        my $scan_num  = $spectrum->scan_number;
        my $scan_win  = $spectrum->scan_window;

        # but also fetch imaging coordinates
        my $x = $spectrum->x;
        my $y = $spectrum->y;
        my $z = $spectrum->z; # if present

    }

=head1 DESCRIPTION

C<MS::Reader::ImzML::Spectrum> objects represent spectra parsed from an imzML
file. The class is an implementation of L<MS::Reader::MzML::Spectrum> and so implements the
standard data accessors associated with that class, as well as accessors for
the imaging x, y, and z coordinates. It also overrides the methods associated
with binary data extraction to fit with the imzMl model.

=head1 METHODS

=head2 x
    
=head2 y

=head2 z

    my $x = $spectrum->x;
    my $y = $spectrum->y;
    my $z = $spectrum->z;

Return the imaging coordinates associated with the spectrum. 'x' and 'y' must
always be defined, 'z' is optional.

=head2 coords
    
    my ($x, $y, $z) = $spectrum->coords

Returns the coordinates associated with the spectrum ('z' may be undefined)

=head1 CAVEATS AND BUGS

The API is in alpha stage and is not guaranteed to be stable.

Please reports bugs or feature requests through the issue tracker at
L<https://github.com/jvolkening/p5-MS/issues>.

=head1 SEE ALSO

=over 4

=item * L<MS::Spectrum>

=item * L<MS::Reader::MzML::Spectrum>

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
