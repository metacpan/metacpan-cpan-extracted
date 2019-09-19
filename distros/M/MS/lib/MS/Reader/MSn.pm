package MS::Reader::MSn;

use strict;
use warnings;

use parent qw/MS::Reader/;

use Carp;
use Data::Dumper;

use MS::Reader::MSn::Spectrum;

our $VERSION = 0.001;

# Perform parsing of the MS1/MS2 (this is called by the parent class - do not
# change the method name )

sub _load_new {

    my ($self) = @_;

    $self->_parse;
    $self->{pos} = 0;
        
    return;

}

sub _post_load {

    my ($self) = @_;
    $self->{pos} = 0;

}

sub _parse {

    my ($self) = @_;

    my $fh = $self->{__fh};
    my $last_offset = tell $fh;
    my $offset;
    my $title;
    my $seen_spectra = 0;

    LINE:
    while (my $line = <$fh>) {
        
        chomp $line;

        my ($f1, $f2) = split ' ', $line;
        next LINE if (! defined $f1);
        if ($f1 eq 'H') {
            my ($str) = ($line =~ /^H\s+$f2\s+(.+)$/);
            die "Error parsing header line: $line\n" if (! defined $str);
            $self->{headers}->{$f2} = $str;
        }

        elsif ($f1 eq 'S') {
            push @{ $self->{offsets} }, $last_offset;
            $self->{index}->{$f2} = $#{ $self->{offsets} };
            if ($seen_spectra) { # if not at first record
                push @{ $self->{lengths} }, $last_offset - $self->{offsets}->[-2];
            }
            $seen_spectra = 1;
        }
        $last_offset = tell $fh;

    }
    if ($seen_spectra) { # if not at first record
        push @{ $self->{lengths} }, $last_offset - $self->{offsets}->[-1];
    }

    $self->{count} = scalar @{ $self->{offsets} };

}

sub fetch_spectrum {

    my ($self, $idx) = @_;
    
    my $offset = $self->{offsets}->[$idx];
    croak "Record not found for $idx" if (! defined $offset);
    
    my $to_read = $self->{lengths}->[ $idx ];
    my $el = $self->_read_element($offset,$to_read);

    return MS::Reader::MSn::Spectrum->new($el);

}

sub next_spectrum {

    my ($self) = @_;

    return undef if ($self->{pos} == $self->{count}); #EOF
    return $self->fetch_spectrum($self->{pos}++);

}

sub goto_spectrum {

    my ($self, $idx) = @_;
    die "Index out of bounds in goto()\n"
        if ($idx < 0 || $idx >= $self->{count});
    $self->{pos} = $idx;
    return;

}

sub get_index_by_id {

    my ($self, $id) = @_;
    return $self->{index}->{$id};

}

sub curr_index {

    my ($self) = @_;
    return $self->{pos};

}

sub n_spectra {

    my ($self) = @_;
    return $self->{count};

}

1;


__END__

=pod

=encoding UTF-8

=head1 NAME

MS::Reader::MSn - A simple but complete MS1/MS2 parser

=head1 SYNOPSIS

    use MS::Reader::MSn;

    my $run = MS::Reader::MSn->new('run.ms2');

    while (my $spectrum = $run->next_spectrum) {
       
        # only want MS1
        next if ($spectrum->ms_level > 1);

        my $rt = $spectrum->rt;
        # see MS::Reader::MSn::Spectrum and MS::Spectrum for all available
        # methods

    }

    $spectrum = $run->fetch_spectrum(0);  # first spectrum


=head1 DESCRIPTION

C<MS::Reader::MSn> is a parser for the MS1/MS2 formats for raw
mass spectrometry data. It aims to provide complete access to the data
contents while not being overburdened by detailed class infrastructure.
Convenience methods are provided for accessing commonly used data.

=head1 INHERITANCE

C<MS::Reader::MSn> is a subclass of L<MS::Reader> and inherits the methods of
this parental class. Please see the documentation for that class for details of
available methods not detailed below.

=head1 METHODS

=head2 new

    my $run = MS::Reader::MSn->new( $fn,
        use_cache => 0,
        paranoid  => 0,
    );

Takes an input filename (required) and optional argument hash and returns an
C<MS::Reader::MSn> object. This constructor is inherited directly from
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

Returns an C<MS::Reader::MSn::Spectrum> object representing the next spectrum
in the file, or C<undef> if the end of records has been reached. Typically
used to iterate over each spectrum in the run.

=head2 fetch_spectrum

    my $s = $run->fetch_spectrum($idx);

Takes a single argument (zero-based spectrum index) and returns an
C<MS::Reader::MSn::Spectrum> object representing the spectrum at that index.
Throws an exception if the index is out of range.

=head2 goto_spectrum

    $run->goto_spectrum($idx);

Takes a single argument (zero-based spectrum index) and sets the spectrum
record iterator to that index (for subsequent calls to C<next_spectrum>).

=head2 n_spectra

    my $n = $run->n_spectra;

Returns the number of spectra present in the file.

=head2 curr_index

    my $idx = $run->curr_index;

Returns the index of the current iterator

=head2 get_index_by_id

    my $idx = $run->get_index_by_id($id);

Returns the index of the spectrum with ID $id

=head1 CAVEATS AND BUGS

The API is in alpha stage and is not guaranteed to be stable.

Please reports bugs or feature requests through the issue tracker at
L<https://github.com/jvolkening/p5-MS/issues>.

=head1 SEE ALSO

=over 4

=item * L<InSilicoSpectro>

=item * L<MS2::Parser>

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
