package MS::Mass;

use strict;
use warnings;

use Carp;
use Storable;
use File::ShareDir qw/dist_file/;
use Exporter qw/import/;

our @EXPORT_OK = qw/
    aa_mass
    atoms
    atoms_mass
    brick_mass
    db_version
    elem_mass
    formula_mass
    list_bricks
    mod_data
    mod_id_to_name
    mod_mass
/;

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

my $unimod;

BEGIN {

    my $fn_unimod = dist_file('MS' => 'unimod.stor');
    $unimod = retrieve $fn_unimod
        or croak "failed to read Unimod database from storage: $@";

} #end BEGIN



sub _check_type {

    my ($type) = @_;

    return 'mono_mass' if (! defined $type);
    return ($type eq 'mono'    || $type eq 'mono_mass') ? 'mono_mass'
         : ($type eq 'average' || $type eq 'avge_mass') ? 'avge_mass'
         : croak "Unexpected mass type (allowed: 'mono','average')\n";

}


sub db_version {
    return $unimod->{db_version}
}

sub _mass {
    my ($group, $name, $type) = @_;
    if (! defined $unimod->{$group}->{$name}) {
        carp "Undefined $group $name";
        return undef;
    }
    $type = _check_type( $type );
    return $unimod->{$group}->{$name}->{$type};
}

sub aa_mass    { return _mass( 'aa',    @_ ) };
sub mod_mass   { return _mass( 'mod',   @_ ) };
sub elem_mass  { return _mass( 'elem',  @_ ) };
sub brick_mass { return _mass( 'brick', @_ ) };

sub mod_data {
    my ($mod) = @_;
    return { %{$unimod->{mod}->{$mod}->{hashref}} };
}

sub formula_mass {

    my ($formula, $type) = @_;
    $type = _check_type( $type );

    croak "unsupported characters in formula $formula"
        if ($formula =~ /[^0-9A-Za-z]/);

    my $mass;
    while ($formula =~ /([A-Z][a-z]?)(\d*)/g) {
        my $single_mass = _mass('elem', $1, $type);
        croak "mass not found for element $1" if (! defined $single_mass);
        my $multiplier  = $2 ? $2 : 1;
        $mass += $single_mass * $multiplier;
    }

    return $mass;

}

sub atoms_mass {

    my ($ref, $type) = @_;
    $type = _check_type( $type );

    my $mass;
    for (keys %$ref) {
        my $single_mass = _mass('elem', $_, $type);
        croak "mass not found for element $_" if (! defined $single_mass);
        $mass += $single_mass * $ref->{$_};
    }

    return $mass;

}

sub atoms {

    my ($type,$name) = @_;
    if (! defined $unimod->{$type}->{$name}) {
        carp "Undefined $type $name";
        return undef;
    }
    return { %{$unimod->{$type}->{$name}->{atoms}} };

}

sub mod_id_to_name {

    my ($id) = @_;
    return $unimod->{mod_index}->{$id};

}

sub list_bricks {

    my $str = "name\tfull_name\tmono_mass\tavg_mass\n";
    my @names = sort {$a cmp $b} keys %{ $unimod->{brick} };
    for (@names) {
        my $ref = $unimod->{brick}->{$_};
        $str .= join( "\t",
            $_,
            $ref->{full_name},
            $ref->{mono_mass},
            $ref->{avge_mass},
        ) . "\n";
    }

    return $str;

}

1;


__END__

=head1 NAME

MS::Mass - core functions for molecular mass calculations

=head1 SYNOPSIS

    use MS::Mass qw/:all/;

    use constant PROTON => elem_mass('H');          # 1.007825035 

    use constant WATER  => formula_mass('H2O');     # 18.0105647

    my $add_NQ = mod_mass('Deamidated', 'average'); # 0.9848

    my $C_proline = atoms('aa' => 'P')->{C};        # 5


=head1 DESCRIPTION

C<MS::Mass> provides a set of core functions for use in calculating and
working with molecular mass values common in mass spectrometry. It is expected
that more specialized libraries for mass calculations can build off of this
module within the C<MS::Mass> namespace.

The module utilizes a functional interface for speed and simplicity. It
utilizes the Unimod database as its data source. For modification records, the
basic delta mass (monoisotopic or average) can be retrieved via the
C<mod_mass> function. The rest of the information stored in Unimod (e.g.
specificities, authors, etc) does not currently have associated retrieval
functions but can, if needed, be directly accessed via the C<mod_data>
function, which returns a hash reference to a nested data structure containing
all information from the Unimod record (use L<Data::Dumper> to view the
underlying structure if you require this functionality). Additional
convenience functions to provide access to these modification attributes may
be added in the future.

=head1 FUNCTIONS

=over 4

=item B<elem_mass> I<symbol> [I<type>]

    use constant PROTON     => elem_mass('H');
    use constant PROTON_AVG => elem_mass('H', 'average');

Takes one required argument (an element symbol) and
one optional argument (the mass value to return, either 'mono' or 'average')
and returns the associated mass value. By default, the monoisotopic mass is
returned. Element symbols are case-sensitive;

=item B<aa_mass> I<code> [I<type>]

    use constant PROLINE     => aa_mass('P');
    use constant PROLINE_AVG => aa_mass('P', 'average');

Takes one required argument (the 1-letter IUPAC code for an amino acid) and
one optional argument (the mass value to return, either 'mono' or 'average')
and returns the associated mass value. By default, the monoisotopic mass is
returned.

=item B<mod_mass> I<name> [I<type>]

    use constant DEAM     => mod_mass('Deamidated');
    use constant DEAM_AVG => brick_mass('Deamidated', average');

Takes one required argument (the modification name) and one optional argument (the
mass value to return, either 'mono' or 'average') and returns the associated
mass value. By default, the monoisotopic mass is returned.

=item B<brick_mass> I<name> [I<type>]

    use constant WATER     => brick_mass('Water');
    use constant WATER_AVG => brick_mass('Water', average');

Takes one required argument (the brick name) and one optional argument (the
mass value to return, either 'mono' or 'average') and returns the associated
mass value. By default, the monoisotopic mass is returned. See C<list_bricks>
for more details.

=item B<formula_mass> I<formula> [I<type>]

Takes one required argument (a string containing a chemical formula) and one
optional argument (the mass value to return, either 'mono' or 'average') and
returns the associated mass value. By default, the monoisotopic mass is
returned.

Formulas are case-sensitive, for obvious reasons. Currently grouping is not
supported. For example, to get the formula for Al2(SO4)3 you must flatten it
out:

    my $al_sulf = formula_mass('Al2S3O12');

and not:

    my $al_sulf = formula_mass('Al2(SO4)3'); # this gives an error

Support for more complicated formulas may be added in the future.

=item B<atoms_mass> I<hashref> [I<type>]

Takes one required argument (a hashref containing element counts) and one
optional argument (the mass value to return, either 'mono' or 'average') and
returns the associated mass value. By default, the monoisotopic mass is
returned.

This function was added to make it easy to recalculate masses based on
modifying the return reference from C<atoms>.

=item B<atoms> I<type> I<name>

    my $atoms = $atoms('aa' => 'G');
    my $n_C = $atoms->{C};

Takes two required arguments (the record type - 'aa', 'mod', or 'brick' - and the
record name/symbol) and returns a hash reference where the keys are the
elements present in the molecule and the values are their counts.

=item B<mod_id_to_name> I<id>

    my $name = mod_id_to_name(7);
    my $deam = mod_mass($name);

Takes one required arguments (a Unimod modification record id) and returns the
associated name compatible with C<mod_mass> or undef if not found.

=item B<mod_data> I<id>

    my $mod = mod_data('Carbamidomethyl');
    my @specificities = @{ $mod->{'umod:specificity'} }
    for (@specificities) {
        print "$_->{site}\n" if (! $_->{hidden});
    }

Takes one required argument (a modification name) and returns a hash
reference containing a nested data structure with all information contained in
the Unimod record. Use Data::Dumper for a view of the internal structure.

In the future an object-oriented interface may be added to make access to
these details more user-friendly.

=item B<list_bricks>

    print {$ref_table} list_bricks();

This is a convenience function that returns a tab-separated table of available
Unimod "bricks" suitable for printing. These are elemental or molecular units
that can be referenced as a group for convenience.

This function is provided mainly because this information does not seem to be
readily available elsewhere without reading the XML.

=item B<db_version>

Returns the version string of the Unimod database in use.

=back

=head1 CAVEATS AND BUGS

Please report bugs to the author.

=head1 AUTHOR

Jeremy Volkening <jdv@base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Jeremy Volkening

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

