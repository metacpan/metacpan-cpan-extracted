package MS::Reader::MzXML;

use strict;
use warnings;

use parent qw/MS::Reader::XML/;

use Carp;
use Data::Dumper;
use Digest::SHA;
use List::Util qw/first/;

use MS::Reader::MzXML::Spectrum;

sub _pre_load {

    my ($self) = @_;

    # ---------------------------------------------------------------------------#
    # These tables are the main configuration point between the parser and the
    # specific document schema. For more information, see the documentation
    # for the parent class MS::Reader::XML
    # ---------------------------------------------------------------------------#

    #$self->{_toplevel} = 'msRun';
    $self->{__rt_index} = undef;

    $self->{__record_classes} = {
        scan => 'MS::Reader::MzXML::Spectrum',
    };

    $self->{_skip_inside} = { map {$_ => 1} qw/
        scan
        index
    / };

    $self->{_make_index} = {
        scan => 'num',
    };

    $self->{_make_named_array} = {
        userParam => 'name',
    };

    $self->{_make_named_hash} = {
        msInstrument        => 'msInstrumentID',
        nameValue           => 'name',
        processingOperation => 'name',
        spot                => 'spotID',
    };

    $self->{_make_anon_array} = { map {$_ => 1} qw/
        comment
        event
        dataProcessing
        parentFile
    / };

}


sub _load_new {

    my ($self) = @_;

    $self->SUPER::_load_new();

    if (defined $self->{mzXML}->{sha1}) {

        # compare supplied and calculated SHA1 sums to validate
        my $sha1_given = $self->{mzXML}->{sha1}->{pcdata};
        croak "ERROR: SHA1 digest mismatch\n"
            if ($sha1_given ne $self->_calc_sha1);

    }

    # Outer <msRun> may optionally be wrapped in <mzXML> tags. For
    # consistent downstream handling, everything outside <msRun> should be
    # discarded before returning.
    if (defined $self->{mzXML}) {
        $self->{msRun} = $self->{mzXML}->{msRun};
        delete $self->{mzXML};
    }

    return;

}

sub fetch_spectrum {

    my ($self, $idx, %args) = @_;
    return $self->fetch_record($self->{msRun}, $idx, %args);

}

sub next_spectrum {

    my ($self, %args) = @_;
    return $self->next_record( $self->{msRun}, %args );

}

sub find_by_time {

    my ($self, $rt, $ms_level) = @_;

    # lazy load
    if (! defined $self->{__rt_index}) {
        $self->_index_rt();
    }

    my @sorted = @{ $self->{__rt_index} };

    croak "Retention time out of bounds"
        if ($rt < 0 || $rt > $self->{__rt_index}->[-1]->[1]);

    # binary search
    my ($lower, $upper) = (0, $#sorted);
    while ($lower != $upper) {
        my $mid = int( ($lower+$upper)/2 );
        ($lower,$upper) = $rt < $sorted[$mid]->[1]
            ? ( $lower , $mid   )
            : ( $mid+1 , $upper );
    }

    my $i = $sorted[$lower]->[0]; #return closest scan index >= $ret
    while (defined $ms_level
      && $self->fetch_record($self->{msRun} => $i)->ms_level() != $ms_level) {
        ++$i;
    }
    return $i;

}

sub goto_spectrum {

    my ($self, $idx) = @_;
    $self->goto($self->{msRun} => $idx);

}

sub _index_rt {

    my ($self) = @_;

    my @spectra;
    my $saved_pos = $self->{msRun}->{__pos};
    $self->goto($self->{msRun} => 0);
    my $curr_pos  = $self->{msRun}->{__pos};
    while (my $spectrum = $self->next_spectrum) {

        my $ret = $spectrum->rt;
        push @spectra, [$curr_pos, $ret];
        $curr_pos = $self->{msRun}->{__pos};

    }
    @spectra = sort {$a->[1] <=> $b->[1]} @spectra;
    $self->goto($self->{msRun} => $saved_pos);
    $self->{__rt_index} = [@spectra];

    # Since we took the time to index RTs, go ahead and store the updated
    # structure to file
    $self->_write_index;

    return;

}

sub _calc_sha1 {

    my ($self) = @_;

    my $fh = $self->{__fh};
    seek $fh, 0, 0;

    my $sha1 = Digest::SHA->new(1);
    local $/ = '>';
    while (my $chunk = <$fh>) {
        $sha1->add($chunk);
        last if (substr($chunk, -6) eq '<sha1>');
    }

    return $sha1->hexdigest;

}

sub n_spectra {

    my ($self) = @_;
    return $self->record_count($self->{msRun});

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MS::Reader::MzXML - A simple but complete mzXML parser

=head1 SYNOPSIS

    use MS::Reader::MzXML;

    my $run = MS::Reader::MzXML->new('run.mzXML');

    while (my $spectrum = $run->next_spectrum) {
       
        # only want MS1
        next if ($spectrum->ms_level > 1);

        my $rt = $spectrum->rt;
        # see MS::Reader::MzXML::Spectrum and MS::Spectrum for all available
        # methods

    }

    $spectrum = $run->fetch_spectrum(0);  # first spectrum
    $spectrum = $run->find_by_time(1500); # in seconds


=head1 DESCRIPTION

C<MS::Reader::MzXML> is a parser for the mzXML format for raw
mass spectrometry data. It aims to provide complete access to the data
contents while not being overburdened by detailed class infrastructure.
Convenience methods are provided for accessing commonly used data. Users who
want to extract data not accessible through the available methods should
examine the data structure of the parsed object. The C<dump()> method of
L<MS::Reader::XML>, from which this class inherits, provides an easy method of
doing so.

=head1 INHERITANCE

C<MS::Reader::MzXML> is a subclass of L<MS::Reader::XML>, which in turn
inherits from L<MS::Reader>, and inherits the methods of these parental
classes. Please see the documentation for those classes for details of
available methods not detailed below.

=head1 METHODS

=head2 new

    my $run = MS::Reader::MzXML->new( $fn,
        use_cache => 0,
        paranoid  => 0,
    );

Takes an input filename (required) and optional argument hash and returns an
C<MS::Reader::MzXML> object. This constructor is inherited directly from
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

Returns an C<MS::Reader::MzXML::Spectrum> object representing the next spectrum
in the file, or C<undef> if the end of records has been reached. Typically
used to iterate over each spectrum in the run.

=head2 fetch_spectrum

    my $s = $run->fetch_spectrum($idx);

Takes a single argument (zero-based spectrum index) and returns an
C<MS::Reader::MzXML::Spectrum> object representing the spectrum at that index.
Throws an exception if the index is out of range.

=head2 goto_spectrum

    $run->goto_spectrum($idx);

Takes a single argument (zero-based spectrum index) and sets the spectrum
record iterator to that index (for subsequent calls to C<next_spectrum>).

=head2 find_by_time

    my $idx = $run->find_by_time($rt);

Takes a single argument (retention time in SECONDS) and returns the index of
the nearest spectrum with retention time equal to or greater than that given.
Throws an exception if the given retention time is out of range.

NOTE: The first time this method is called, the spectral indices are sorted by
retention time for subsequent access. This can be a bit slow. The retention
time index is saved and subsequent calls should be relatively quick. This is
done because the mzXML specification doesn't guarantee that the spectra are
ordered by RT (even though they invariably are).

=head2 n_spectra

    my $n = $run->n_spectra;

Returns the number of spectra present in the file.


=head1 CAVEATS AND BUGS

The mzXML format allows for nested <scan> elements (e.g. nesting MS2 scans
within the parent MS1). However, this is not currently supported by the parser
and will throw an exception if detected. It is possible (and arguably
preferable) to represent such files using a flat scan list - this is how
C<msconvert> currently formats its mzXML output. Lack of support is due to
lack of demand - if this feature is desired it could be implemented with
minimal trouble.

The API is in alpha stage and is not guaranteed to be stable.

Please reports bugs or feature requests through the issue tracker at
L<https://github.com/jvolkening/p5-MS/issues>.

=head1 SEE ALSO

=over 4

=item * L<InSilicoSpectro>

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
