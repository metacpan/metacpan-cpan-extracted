#!/usr/bin/env perl
use Modern::Perl;
use HackaMol;
use Math::Vector::Real;

my $hack = HackaMol->new( name => "hackitup" );

my @atoms = $hack->read_file_atoms("t/lib/1L2Y_mod123.pdb");
my $mol   = HackaMol::Molecule->new( name => 'trp-cage', atoms => [@atoms] );

$mol->print_xyz;

$mol->translate( -$mol->COM );
$mol->translate( V( 10, 10, 10 ) );

$mol->print_xyz;

$mol->rotate( V( 1, 0, 0 ), 180, V( 10, 10, 10 ) );

$mol->print_xyz;

my @groups = $hack->group_by_atom_attr( 'resid', $mol->all_atoms );
$mol->push_groups(@groups);

$_->rotate( V( 1, 1, 1 ), 60, $_->COM, 1 ) foreach $mol->all_groups;

$mol->t(1);
$mol->print_xyz;

