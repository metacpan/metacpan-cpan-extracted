package MS::Reader::MzML;

use strict;
use warnings;

use parent qw/MS::Reader::XML::CV/;

use Carp;
use Data::Dumper;
use Digest::SHA;
use List::Util qw/first/;

use MS::Reader::MzML::Spectrum;
use MS::Reader::MzML::Chromatogram;
use MS::CV qw/:MS/;

our $VERSION = 0.006;

use constant FLOAT_TOL => 0.000001;

sub _pre_load {

    my ($self) = @_;

    # ---------------------------------------------------------------------------#
    # These tables are the main configuration point between the parser and the
    # specific document schema. For more information, see the documentation
    # for the parent class MS::Reader::XML
    # ---------------------------------------------------------------------------#

    $self->{_toplevel} = 'mzML';
    $self->{__rt_index} = undef;

    $self->{__record_classes} = {
        spectrum     => 'MS::Reader::MzML::Spectrum',
        chromatogram => 'MS::Reader::MzML::Chromatogram',
    };

    $self->{_skip_inside} = { map {$_ => 1} qw/
        spectrum
        chromatogram
        indexList
    / };

    $self->{_make_index} = { map {$_ => 'id'} qw/
        spectrum
        chromatogram
    / };

    $self->{_make_named_array} = {
        cvParam   => 'accession',
        userParam => 'name',
    };

    $self->{_make_named_hash} = { map {$_ => 'id'} qw/
        cv
        dataProcessing
        instrumentConfiguration
        referenceableParamGroup
        sample
        scanSettings
        software
        sourceFile
    / };

    $self->{_make_anon_array} = { map {$_ => 1} qw/
        analyzer
        contact
        detector
        processingMethod
        referenceableParamGroupRef
        source
        sourceFileRef
        target
    / };

}


sub _load_new {

    my ($self) = @_;

    $self->SUPER::_load_new();

    if (defined $self->{indexedmzML}->{fileChecksum}) {

        # compare supplied and calculated SHA1 sums to validate
        my $sha1_given = $self->{indexedmzML}->{fileChecksum}->{pcdata};
        croak "ERROR: SHA1 digest mismatch\n"
            if ($sha1_given ne $self->_calc_sha1);

    }

    # Outer <mzML> may optionally be wrapped in <indexedmxML> tags. For
    # consistent downstream handling, everything outside <mzML> should be
    # discarded before returning.
    if (defined $self->{indexedmzML}) {
        $self->{mzML}->{$_} = $self->{indexedmzML}->{mzML}->{$_}
            for (keys %{ $self->{indexedmzML}->{mzML} });
        delete $self->{indexedmzML};
    }

    return;

}

sub fetch_spectrum {

    my ($self, $idx, %args) = @_;
    my $ref = $self->{run}->{spectrumList};
    return $self->fetch_record($ref, $idx, %args);

}

sub next_spectrum {

    my ($self, %args) = @_;
    my $ref = $self->{run}->{spectrumList};
    return $self->next_record( $ref, %args );

}

sub find_by_time {

    my ($self, $rt, $ms_level) = @_;

    # lazy load
    if (! defined $self->{__rt_index}) {
        $self->_index_rt();
    }

    my @sorted = @{ $self->{__rt_index} };

    croak "Retention time out of bounds"
        if ($rt < 0 || $rt > $self->{__rt_index}->[-1]->[1] + FLOAT_TOL);

    # binary search
    my ($lower, $upper) = (0, $#sorted);
    while ($lower != $upper) {
        my $mid = int( ($lower+$upper)/2 );
        ($lower,$upper) = $rt > $sorted[$mid]->[1] + FLOAT_TOL
            ? ( $mid+1 , $upper )
            : ( $lower , $mid   );
    }

    my $i = $sorted[$lower]->[0]; #return closest scan index >= $ret
    my $ref = $self->{run}->{spectrumList};
    while (defined $ms_level
      && $self->fetch_record($ref => $i)->ms_level() != $ms_level) {
        ++$i;
    }
    return $i;

}

sub spectrum_index_by_id {

    my ($self, $id) = @_;
    my $ref = $self->{run}->{spectrumList};
    return $self->get_index_by_id( $ref => $id );

}

sub goto_spectrum {

    my ($self, $idx) = @_;
    my $ref = $self->{run}->{spectrumList};
    $self->goto($ref => $idx);

}

sub curr_spectrum_index {

    my ($self) = @_;
    my $ref = $self->{run}->{spectrumList};
    return $self->curr_index($ref);

}

sub _index_rt {

    my ($self) = @_;

    my @spectra;
    my $ref = $self->{run}->{spectrumList};
    my $saved_pos = $ref->{__pos};
    $self->goto($ref => 0);
    my $curr_pos  = $ref->{__pos};
    while (my $spectrum = $self->next_spectrum) {

        my $ret = $spectrum->rt;
        push @spectra, [$curr_pos, $ret];
        $curr_pos = $ref->{__pos};

    }
    @spectra = sort {$a->[1] <=> $b->[1]} @spectra;
    $self->goto($ref => $saved_pos);
    $self->{__rt_index} = [@spectra];

    # Since we took the time to index RTs, go ahead and store the updated
    # structure to file
    $self->_write_index;

    return;

}

sub _write_index {

    my ($self) = @_;
    $self->{__memoized_refs} = [$self->{run}->{spectrumList}];
    return $self->SUPER::_write_index();

}

sub _calc_sha1 {

    my ($self) = @_;

    my $fh = $self->{__fh};
    seek $fh, 0, 0;

    my $sha1 = Digest::SHA->new(1);
    local $/ = '>';
    while (my $chunk = <$fh>) {
        $sha1->add($chunk);
        last if (substr($chunk, -14) eq '<fileChecksum>');
    }

    return $sha1->hexdigest;

}

sub get_tic {

    my ($self, $force) = @_;

    if (! $force) {
        my $ref = $self->{run}->{chromatogramList};
        $self->goto($ref => 0);
        while (my $c = $self->next_record($ref)) {
            next if (! exists $c->{cvParam}->{&MS_TOTAL_ION_CURRENT_CHROMATOGRAM});
            return $c;
        }
    }

    return MS::Reader::MzML::Chromatogram->new(type => 'tic', raw => $self);

}

sub get_xic {

    my ($self, %args) = @_;
    return MS::Reader::MzML::Chromatogram->new(type => 'xic',raw => $self, %args);

}

sub get_bpc {

    my ($self, $force) = @_;

    if (! $force) {
        my $ref = $self->{run}->{chromatogramList};
        $self->goto($ref => 0);
        while (my $c = $self->next_record($ref)) {
            next if (! exists $c->{cvParam}->{&MS_BASEPEAK_CHROMATOGRAM});
            return $c;
        }
    }

    return MS::Reader::MzML::Chromatogram->new(type => 'bpc',raw => $self);

}

sub n_spectra {

    my ($self) = @_;
    my $ref = $self->{run}->{spectrumList};
    return $self->record_count($ref);

}

sub id { return $_[0]->{run}->{id} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MS::Reader::MzML - A simple but complete mzML parser

=head1 SYNOPSIS

    use MS::Reader::MzML;

    my $run = MS::Reader::MzML->new('run.mzML');

    while (my $spectrum = $run->next_spectrum) {
       
        # only want MS1
        next if ($spectrum->ms_level > 1);

        my $rt = $spectrum->rt;
        # see MS::Reader::MzML::Spectrum and MS::Spectrum for all available
        # methods

    }

    $spectrum = $run->fetch_spectrum(0);  # first spectrum
    $spectrum = $run->find_by_time(1500); # in seconds


=head1 DESCRIPTION

C<MS::Reader::MzML> is a parser for the HUPO PSI standard mzML format for raw
mass spectrometry data. It aims to provide complete access to the data
contents while not being overburdened by detailed class infrastructure.
Convenience methods are provided for accessing commonly used data. Users who
want to extract data not accessible through the available methods should
examine the data structure of the parsed object. The C<dump()> method of
L<MS::Reader::XML>, from which this class inherits, provides an easy method of
doing so.

=head1 INHERITANCE

C<MS::Reader::MzML> is a subclass of L<MS::Reader::XML>, which in turn
inherits from L<MS::Reader>, and inherits the methods of these parental
classes. Please see the documentation for those classes for details of
available methods not detailed below.

=head1 METHODS

=head2 new

    my $run = MS::Reader::MzML->new( $fn,
        use_cache => 0,
        paranoid  => 0,
    );

Takes an input filename (required) and optional argument hash and returns an
C<MS::Reader::MzML> object. This constructor is inherited directly from
L<MS::Reader>. Available options include:

=over

=item * use_cache — cache fetched records in memory for repeat access
(default: FALSE)

=item * paranoid — when loading index from disk, recalculates MD5 checksum
each time to make sure raw file hasn't changed. This adds (typically) a few
seconds to load times. By default, only file size and mtime are checked.

=back

=head2 next_spectrum

    while (my $s = $run->next_spectrum) {
        # do something
    }

Returns an C<MS::Reader::MzML::Spectrum> object representing the next spectrum
in the file, or C<undef> if the end of records has been reached. Typically
used to iterate over each spectrum in the run.

=head2 fetch_spectrum

    my $s = $run->fetch_spectrum($idx);

Takes a single argument (zero-based spectrum index) and returns an
C<MS::Reader::MzML::Spectrum> object representing the spectrum at that index.
Throws an exception if the index is out of range.

=head2 goto_spectrum

    $run->goto_spectrum($idx);

Takes a single argument (zero-based spectrum index) and sets the spectrum
record iterator to that index (for subsequent calls to C<next_spectrum>).

=head2 curr_spectrum_index

    $run->curr_spectrum_index

Returns the 0-based index of the current spectrum pointer.

=head2 spectrum_index_by_id

    my $idx = $run->spectrum_index_by_id($id);

Takes a single argument (spectrum ID) and returns the index of the matching
spectrum (generally for input into other methods).

=head2 find_by_time

    my $idx = $run->find_by_time($rt);

Takes a single argument (retention time in SECONDS) and returns the index of
the nearest spectrum with retention time equal to or greater than that given.
Throws an exception if the given retention time is out of range.

NOTE: The first time this method is called, the spectral indices are sorted by
retention time for subsequent access. This can be a bit slow. The retention
time index is saved and subsequent calls should be relatively quick. This is
done because the mzML specification doesn't guarantee that the spectra are
ordered by RT (even though they invariably are).

=head2 n_spectra

    my $n = $run->n_spectra;

Returns the number of spectra present in the file.

=head2 get_tic

    my $tic = $run->get_tic;
    my $tic = $run->get_tic($force);

Returns an C<MS::Reader::MzML::Chromatogram> object containing the total ion
current chromatogram for the run. By default, first searches the chromatogram
list to see if a TIC is already defined, and returns it if so. Otherwise,
walks the MS1 spectra and calculates the TIC. Takes a single optional boolean
argument which, if true, forces recalculation of the TIC even if one exists in
the file.

=head2 get_bpc

    my $tic = $run->get_bpc;
    my $tic = $run->get_bpc($force);

Returns an C<MS::Reader::MzML::Chromatogram> object containing the base peak
chromatogram for the run. By default, first searches the chromatogram
list to see if a BPC is already defined, and returns it if so. Otherwise,
walks the MS1 spectra and calculates the BPC. Takes a single optional boolean
argument which, if true, forces recalculation of the BPC even if one exists in
the file.

=head2 get_xic

    my $xic = $run->get_xic(%args);

Returns an C<MS::Reader::MzML::Chromatogram> object containing an extracted
ion chromatogram for the run. Required arguments include:

=over 4

=item * C<mz> — The m/z value to extract (REQUIRED)

=item * C<err_ppm> — The allowable m/z error tolerance (in PPM)

=back

Optional arguments include:

=over

=item * C<rt> — The center of the retention time window, in seconds 

=item * C<rt_win> — The window scanned on either size of C<rt>, in seconds

=item * C<charge> — Expected charge of the target species at C<mz>

=item * C<iso_steps> — The number of isotopic shifts to consider

=back

If C<rt> and C<rt_win> are not given, the full range of the run will be used.
If C<charge> and C<iso_steps> are given, will include peaks falling within the
expected isotopic envelope (up to C<iso_steps> shifts in either direction) -
otherwise the isotopic envelope will not be considered.


=head2 id

Returns the ID of the run as specified in the C<<mzML>> element.

=head1 CAVEATS AND BUGS

The API is in alpha stage and is not guaranteed to be stable.

Please reports bugs or feature requests through the issue tracker at
L<https://github.com/jvolkening/p5-MS/issues>.

=head1 SEE ALSO

=over 4

=item * L<InSilicoSpectro>

=item * L<MzML::Parser>

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
