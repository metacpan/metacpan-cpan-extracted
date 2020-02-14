package MS::Reader::MzML::Chromatogram;

use strict;
use warnings;

use parent qw/MS::Reader::MzML::Record/;
use MS::CV qw/:MS/;
use MS::Mass qw/elem_mass/;
use List::Util qw/sum/;
use List::MoreUtils qw/any/;

sub _pre_load {

    my ($self) = @_;
    $self->{_toplevel} = 'chromatogram';
    $self->SUPER::_pre_load();

}

sub new {

    my ($class, %args) = @_;
    my $self = bless {}, $class;

    # if xml is provided, we read chromatogram from that
    if (defined $args{xml}) {
        return $class->SUPER::new(%args);
    }

    # else we generate it based on other parameters
    die "must specify either 'xml' or 'type' for new chromatogram"
        if (! defined $args{type});
    die "must provide mzML object to generate chromatogram on-the-fly"
        if (! defined $args{raw} || ! $args{raw}->isa("MS::Reader::MzML"));

    # save current spectrum position
    my $mzml = $args{raw};
    my $ref = $mzml->{run}->{spectrumList};
    my $last_pos = $ref->{__pos};

    if ($args{type} eq 'xic') {
        $self->_calc_xic(%args);
    }
    else {
        $self->_calc_ic(%args);
    }

    # restore current spectrum position
    $ref->{__pos} = $last_pos;

    return $self;

}

sub _calc_xic {

    my ($self, %args) = @_;

    die "XIC generation requires parameters 'mz', 'err_ppm'"
        if (any {! defined $args{$_} } qw/mz err_ppm/);

    my $mzml = $args{raw};
    my @rt;
    my @int;

    my $mz_lower = $args{mz} - $args{err_ppm} * $args{mz} / 1000000;
    my $mz_upper = $args{mz} + $args{err_ppm} * $args{mz} / 1000000;
    my $rt_lower = defined $args{rt} ? $args{rt} - $args{rt_win} : undef;
    my $rt_upper = defined $args{rt} ? $args{rt} + $args{rt_win} : undef;

    my $iso_shift = elem_mass('13C') - elem_mass('C');

    my @pairs = ( [$mz_lower, $mz_upper] );

    # include isotopic envelope if asked
    if (defined $args{charge}) {
        my $steps = $args{iso_steps} // 0;
        for (-$steps..$steps) {
            my $off = $_ * $iso_shift / $args{charge};
            push @pairs, [$mz_lower+$off, $mz_upper+$off];
        }
    }

    my $ref = $mzml->{run}->{spectrumList};
    $mzml->goto($ref, defined $rt_lower
        ? $mzml->find_by_time($rt_lower)
        : 0 );
    while (my $spectrum = $mzml->next_spectrum( filter => [&MS_MS_LEVEL => 1] )) {
        last if (defined $rt_upper && $spectrum->rt > $rt_upper);

        my ($mz, $int) = $spectrum->mz_int_by_range(@pairs);
        my $ion_sum = (defined $int && scalar(@$int)) ? sum(@$int) : 0;

        push @rt, $spectrum->rt;
        push @int, $ion_sum;
    }
    $self->{rt}  = \@rt;
    $self->{int} = \@int;

    return;

}

sub _calc_ic {

    my ($self, %args) = @_;
       
    my $mzml = $args{raw};
    my $acc = $args{type} eq 'tic' ? MS_TOTAL_ION_CURRENT
            : $args{type} eq 'bpc' ? MS_BASE_PEAK_INTENSITY
            : die "unexpected chromatogram type requested";
    my @rt;
    my @int;
    my $ref = $mzml->{run}->{spectrumList};
    $mzml->goto($ref => 0);
    while (my $spectrum = $mzml->next_spectrum( filter => [&MS_MS_LEVEL => 1] )) {
        my $current = $spectrum->param($acc);
        push @rt, $spectrum->rt;
        push @int, $current;
    }
    $self->{rt}  = [@rt];
    $self->{int} = [@int];

    return;

}

sub int {
    my ($self) = @_;
    return $self->{int} if (defined $self->{int});
    return $self->get_array(MS_INTENSITY_ARRAY);
}

sub rt {
    my ($self) = @_;
    return $self->{rt} if (defined $self->{rt});
    return $self->get_array(MS_TIME_ARRAY);
}

sub id { return $_[0]->{id} };

sub window { return undef}; # TODO: implement

1;


__END__

=pod

=encoding UTF-8

=head1 NAME

MS::Reader::MzML::Chromatogram - An MzML chromatogram object

=head1 SYNOPSIS

    use MS::Reader::MzML;

    my $run = MS::Reader::MzML->new('run.mzML');

    my $tic = $run->get_tic; # an MS::Reader::MzML::Chromatogram object
        
    my $id  = $tic->id;
    my $rt  = $tic->rt;
    my $int = $tic->int;

    # print the underlying data structure
    $tic->dump;

    }

=head1 DESCRIPTION

C<MS::Reader::MzML::Chromatogram> objects represent chromatograms parsed or
calculated from an mzML file. The constructor is not intended to be used directly
but rather by via methods of L<MS::Reader::MzML>. 

=head1 METHODS

=head2 id
    
    my $id = $chrom->id;

Returns the native ID of the chromatogram, or undefined if not available

=head2 rt

    my $rt = $chrom->rt;
    for (@$rt) { # do something }

Returns an array reference to the retention time data array (in SECONDS)

=head2 int

    my $int = $chrom->int;
    for (@$int) { # do something }

Returns an array reference to the peak intensity data array

=head2 param, get_array

See L<MS::Reader::MzML::Record>

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
