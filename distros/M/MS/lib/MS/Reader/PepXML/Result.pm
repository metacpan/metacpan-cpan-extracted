package MS::Reader::PepXML::Result;

use strict;
use warnings;

use Data::Dumper;
use MS::Mass qw/aa_mass elem_mass/;

use parent qw/MS::Reader::XML::Record/;

# Lookup tables to quickly check elements

sub _pre_load {

    my ($self) = @_;

    $self->{_toplevel} = 'spectrum_query';

    $self->{_make_named_hash} = { map {$_ => 'name'} qw/
        parameter
        search_score
    / };

    $self->{_make_anon_array} = { map {$_ => 1} qw/
        search_result
        search_hit
        search_id
        alternative_protein
        mod_aminoacid_mass
        analysis_result
    / };

}

sub get_hit {

    my ($self, $idx) = @_;
    $idx //= 0;
    return $self->{search_result}->[0]->{search_hit}->[$idx];

}

sub mod_delta_array {

    my ($self, $hit) = @_;
    $hit = $hit // 0;
    $hit = $self->{search_result}->[0]->{search_hit}->[$hit];
    my $pep = $hit->{peptide};
    my @deltas = (0) x (length($pep)+2);
    $deltas[0] += $hit->{modification_info}->{mod_nterm_mass} - elem_mass('H')
        if (defined $hit->{modification_info}->{mod_nterm_mass});
    $deltas[-1] += $hit->{modification_info}->{mod_cterm_mass} - elem_mass('OH')
        if (defined $hit->{modification_info}->{mod_cterm_mass});
    for my $mod (@{ $hit->{modification_info}->{mod_aminoacid_mass} }) {
        my $pos = $mod->{position};
        my $mass = $mod->{mass} - aa_mass( substr $pep, $pos-1, 1 );
        $deltas[$pos] += $mass;
    }
    return \@deltas;

}

sub dump {

    my ($self) = @_;

    my $copy = {};
    %$copy = %$self;

    delete $copy->{$_} 
        for qw/use_cache/;

    my $dump = '';

    {
        local $Data::Dumper::Indent   = 1;
        local $Data::Dumper::Terse    = 1;
        local $Data::Dumper::Sortkeys = 1;
        $dump = Dumper $copy;
    }

    return $dump;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MS::Reader::PepXML::Result - pepXML search result object

=head1 SYNOPSIS

    while (my $result = $search->next_result) {
    
        my $top_hit = $result->get_hit(0);
        my $peptide = $top_hit->{peptide};
        my $deltas  = $result->mod_delta_array(0);

    }

=head1 DESCRIPTION

The C<MS::Reader::PepXML::Result> class represent search query results
(<<spectrum_query>> elements in the pepXML schema).  mass spectrometry data.
It aims to provide complete access to the data contents while not being
overburdened by detailed class infrastructure.  Convenience methods are
provided for accessing commonly used data. Users who want to extract data not
accessible through the available methods should examine the data structure of
the parsed object. The C<dump()> method provides an easy method of doing so.

=head1 METHODS

=head2 get_hit

    my $first_hit = $result->get_hit(0);

Takes one optional argument (zero-based index of the hit) and returns a hash
reference containing the result data for the hit. Currently most useful data
is extracted directly from this hash reference. In the future additional
accessors may be added for commonly accessed data. If no arguments are
provided, returns the first hit.

=head2 mod_delta_array

    my $deltas = $result->mod_delta_array(0);

Takes one optional argument (zero-based index of the hit) and returns an array
reference containing floating point delta masses for each location on the
peptide.  The length of the array wil be equal to peptide length + 2 - the
first and last values represent N-terminal and C-terminal modifications
respectively.  If no arguments are provided, returns the first hit.

=head2 dump

    my $string = $result->dump;

Returns a textual serialization of the C<MS::Reader::PepXML::Result> object as
a text string. This is useful for understanding how to access information not
provided directly by class methods.

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
