#!/usr/bin/perl

use strict;
use warnings;

use Test::Fatal;
use Test::More;
use MS::Mass qw/:all/;

require_ok ("MS::Mass");

ok( db_version() eq '2.0', "db version" );

# test elem_mass()
ok( are_equal( elem_mass('Fe'             ), 55.935, 3), "elem_mass(none)" );
ok( are_equal( elem_mass('Fe', 'mono'     ), 55.935, 3), "elem_mass(mono)" );
ok( are_equal( elem_mass('Fe', 'mono_mass'), 55.935, 3), "elem_mass(mono_mass)" );
ok( are_equal( elem_mass('Fe', 'average'  ), 55.845, 3), "elem_mass(average)"  );
ok( are_equal( elem_mass('Fe', 'avge_mass'), 55.845, 3), "elem_mass(avge_mass)"  );
like( exception {elem_mass('Fe', 'foobar')}, qr/Unexpected mass type/,
    "elem_mass() bad mass type" );

# test aa_mass()
ok( are_equal( aa_mass('G'           ), 57.021, 3), "elem_mass(mono)" );
ok( are_equal( aa_mass('G', 'average'), 57.051, 3), "elem_mass(avg)"  );

# test mod_mass()
my $name = mod_id_to_name(21);
ok ($name eq 'Phospho', "mod_id_to_name");
ok( are_equal( mod_mass($name),             79.9663 , 3), "mod_mass(mono)" );
ok( are_equal( mod_mass($name, 'average'),  79.9799 , 3), "mod_mass(avg)"  );

# test brick_mass() 
ok( are_equal( brick_mass('Water'), 18.010565, 3), "brick_mass()" );

# test formula_mass()
ok( are_equal( formula_mass('H2O'), 18.010565, 3), "formula_mass()" );
like( exception {formula_mass('foo!')}, qr/unsupported characters/,
    "atoms_mass() bad atoms" );
like( exception {formula_mass('Qq')}, qr/mass not found/,
    "atoms_mass() bad atoms" );

# test atoms()
ok( my $atoms = atoms('brick' => 'Water'), "atoms()" );
ok( ! defined atoms('brick' => 'FooBar'), "atoms() bad name" );
ok( are_equal( atoms_mass($atoms), 18.010565, 3), "atoms_mass()" );
like( exception {atoms_mass({'Foo'=>2})}, qr/mass not found/,
    "atoms_mass() bad atoms" );

# test list_bricks()
ok( my $list = list_bricks(), "list_bricks()" );
ok( $list =~ /^name\t/, "list_bricks header" );
ok( $list =~ /^Zn\tZinc\t/m, "list_bricks item" );

# test mod_data()
ok( my $phospho = mod_data('Phospho'), "mod_data()" );
ok( $phospho->{title} eq 'Phospho', "mod_data() check" );


done_testing();

sub are_equal {

    my ($v1, $v2, $dp) = @_;
    return sprintf("%.${dp}f", $v1) eq sprintf("%.${dp}f", $v2);

}
