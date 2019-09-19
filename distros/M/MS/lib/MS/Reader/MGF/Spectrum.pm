package MS::Reader::MGF::Spectrum;

use strict;
use warnings;

use Carp;

use parent qw/MS::Spectrum/;

sub new {

    my ($class, $data) = @_;

    my $self = bless {}, $class;
    $self->{mz}  = [];
    $self->{int} = [];
    $self->_parse($data);

    return $self;

}

sub _parse {

    my ($self, $data) = @_;

    my @mz;
    my @int;
    LINE:
    for my $line (split /\r?\n/, $data) {
        
        chomp $line;
        if ($line =~ /^(\w+)\=(.+)$/) {
            my ($key, $val) = ($1, $2);
            croak "$key already defined\n"
                if (exists $self->{$key});
            $self->{$key} = $val;
            next LINE;
        }
        my ($mz,$int) = split ' ', $line;
        push @mz, $mz;
        push @int, $int;

    }

    $self->{mz} = [@mz];
    $self->{int} = [@int];

}

sub id  { return $_[0]->{TITLE}    }

sub mz  { return $_[0]->{mz}  }

sub int { return $_[0]->{int} }

sub ms_level { return -1 } # unknown - usually MS2 but not guaranteed

sub rt {

    my ($self) = @_;
    die "Spectrum does not contain retention time annotation\n"
        if (! defined $self->{RTINSECONDS} );
    return $self->{RTINSECONDS};

}


sub dump {

    my ($self) = @_;

    use Data::Dumper;

    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Sortkeys = 1;

    return Dumper $self;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MS::Reader::MGF::Spectrum - An MGF spectrum object

=head1 SYNOPSIS

    use MS::Reader::MGF;
    use MS::CV qw/:MS/;

    my $run = MS::Reader::MGF->new('run.mgf');

    while (my $spectrum = $run->next_spectrum) {
        
        # $spectrum inherits from MS::Spectrum, so you can do:
        my $id  = $spectrum->id;
        my $rt  = $spectrum->rt;
        my $mz  = $spectrum->mz;
        my $int = $spectrum->int;
        my $lvl = $spectrum->ms_level;

        # in addition,

        # print the underlying data structure
        print $spectrum->dump;

    }

=head1 DESCRIPTION

C<MS::Reader::MGF::Spectrum> objects represent spectra parsed from an MGF
file. The class is an implementation of L<MS::Spectrum> and so implements the
standard data accessors associated with that class, as well as a few extra, as
documented below. The underlying hash is a nested data structure containing
all information present in the original MGF record. This information can be
accessed directly (see below for details of the data structure) when class
methods do not exist for doing so.

=head1 METHODS

=head2 id
    
    my $id = $spectrum->id;

Returns the ID of the spectrum

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

For C<MS::Reader::MGF::Spectrum> objects, always returns -1, as the MS level
is not known from the file.

=head2 dump

    my $dump = $spectrum->dump;

Returns a textual representation (via C<Data::Dumper>) of the data structure.
This can facilitate access to data parsed from the MGF record but not
accessible via an accessor method.

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

Copyright 2015-2019 Jeremy Volkening

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

