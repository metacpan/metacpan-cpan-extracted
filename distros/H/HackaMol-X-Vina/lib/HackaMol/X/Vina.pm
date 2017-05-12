package HackaMol::X::Vina;
$HackaMol::X::Vina::VERSION = '0.012';
#ABSTRACT: HackaMol extension for running Autodock Vina
use Moose;
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints;
use Math::Vector::Real;
use MooseX::Types::Path::Tiny qw(AbsPath) ;
use HackaMol; # for building molecules
use File::chdir;
use namespace::autoclean;
use Carp;

with qw(HackaMol::X::Roles::ExtensionRole);

has $_ => ( 
            is        => 'rw', 
            isa       => AbsPath, 
            predicate => "has_$_",
            required  => 1,
            coerce    => 1,
          ) foreach ( qw( receptor ligand ) );

has 'save_mol' => (
            is      => 'rw',
            isa     => 'Bool',
            default => 0,
);        
   

has $_ => (
    is        => 'rw',
    isa       => 'Num',
    predicate => "has_$_",
) foreach qw(center_x center_y center_z size_x size_y size_z);

has 'num_modes' => (
    is        => 'rw',
    isa       => 'Int',
    predicate => "has_num_modes",
    default   => 1,
    lazy      => 1,
);

has $_ => (
    is        => 'rw',
    isa       => 'Int',
    predicate => "has_$_",
) foreach qw(energy_range exhaustiveness seed cpu);


has 'center' => (
    is        => 'rw',
    isa       => 'Math::Vector::Real',
    predicate => "has_center",
    trigger   => \&_set_center,
);

has 'size' => (
    is        => 'rw',
    isa       => 'Math::Vector::Real',
    predicate => "has_size",
    trigger   => \&_set_size,
);

sub BUILD {
    my $self = shift;

    if ( $self->has_scratch ) {
        $self->scratch->mkpath unless ( $self->scratch->exists );
    }

    # build in some defaults
    $self->in_fn("conf.txt") unless ($self->has_in_fn);
    $self->exe($ENV{"HOME"}."/bin/vina") unless $self->has_exe;

    unless ( $self->has_out_fn ) {
      my $outlig = $self->ligand->basename;
      $outlig =~ s/\.pdbqt/\_out\.pdbqt/;
      $self->out_fn($outlig); 
    }

    unless ( $self->has_command ) {
        my $cmd = $self->build_command;
        $self->command($cmd);
    }

    return;
}

sub _set_center {
    my ( $self, $center, $old_center ) = @_;
    $self->center_x( $center->[0] );
    $self->center_y( $center->[1] );
    $self->center_z( $center->[2] );
}

sub _set_size {
    my ( $self, $size, $old_size ) = @_;
    $self->size_x( $size->[0] );
    $self->size_y( $size->[1] );
    $self->size_z( $size->[2] );
}

#required methods
sub build_command {
    my $self = shift;
    my $cmd;
    $cmd = $self->exe;
    $cmd .= " --config " . $self->in_fn->stringify;

    # we always capture output
    return $cmd;
}

sub _build_map_in {
    # this builds the default behavior, can be set anew via new
    return sub { return ( shift->write_input ) };
}

sub _build_map_out {
    # this builds the default behavior, can be set anew via new
    my $sub_cr = sub {
        my $self = shift;
        my $qr   = qr/^\s+\d+\s+(-*\d+\.\d)/;
        my ( $stdout, $sterr ) = $self->capture_sys_command;
        my @be = map { m/$qr/; $1 }
          grep { m/$qr/ }
          split( "\n", $stdout );
        return (@be);
    };
    return $sub_cr;
}

sub dock {
  my $self      = shift;
  my $num_modes = shift;
  $self->num_modes($num_modes) if defined($num_modes);
  $self->map_input;
  return $self->map_output;
}

sub dock_mol {
  # want this to return configurations of the molecule
  my $self      = shift;
  my $num_modes = shift;
  $self->num_modes($num_modes) if defined($num_modes);
  $self->map_input; 
  local $CWD = $self->scratch if ( $self->has_scratch );
  my @bes = $self->map_output; # this is fragile... broken if map_out changed...
  my $mol = HackaMol -> new(hush_read => 1)
                     -> read_file_mol($self->out_fn->stringify);
  $mol->push_score(@bes);
  return ($mol);
}

sub write_input {
    my $self = shift;
    my $input;
    $input .= sprintf( "%-15s = %-55s\n", 'out', $self->out_fn->stringify );
    $input .= sprintf( "%-15s = %-55s\n", 'log', $self->log_fn->stringify )
      if $self->has_log_fn;
    foreach my $cond (
        qw(receptor ligand cpu num_modes energy_range exhaustiveness seed))
    {
        my $condition = "has_$cond";
        $input .= sprintf( "%-15s = %-55s\n", $cond, $self->$cond )
          if $self->$condition;
    }
    foreach my $metric (qw(center_x center_y center_z size_x size_y size_z)) {
        $input .= sprintf( "%-15s = %-55s\n", $metric, $self->$metric );
    }
    $self->in_fn->spew($input);
    return ($input);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

HackaMol::X::Vina - HackaMol extension for running Autodock Vina

=head1 VERSION

version 0.012

=head1 SYNOPSIS

  use Modern::Perl;
  use HackaMol;
  use HackaMol::X::Vina;
  use Math::Vector::Real;

  my $receptor = "receptor.pdbqt";
  my $ligand   = "lig.pdbqt",
  my $rmol     = HackaMol -> new( hush_read=>1 ) -> read_file_mol( $receptor );
  my $lmol     = HackaMol -> new( hush_read=>1 ) -> read_file_mol( $ligand );
  my $fh = $lmol->print_pdb("lig_out.pdb");

  my @centers = map  {$_ -> xyz}
                grep {$_ -> name    eq "OH" }
                grep {$_ -> resname eq "TYR"} $rmol -> all_atoms;

  foreach my $center ( @centers ){

      my $vina = HackaMol::X::Vina -> new(
          receptor       => $receptor,
          ligand         => $ligand,
          center         => $center,
          size           => V( 20, 20, 20 ),
          cpu            => 4,
          exhaustiveness => 12,
          exe            => '~/bin/vina',
          scratch        => 'tmp',
      );

      my $mol = $vina->dock_mol(3); # fill mol with 3 binding configurations

      printf ("Score: %6.1f\n", $mol->get_score($_) ) foreach (0 .. $mol->tmax); 

      $mol->print_pdb_ts([0 .. $mol->tmax], $fh); 

    }

    $_->segid("hgca") foreach $rmol->all_atoms; #for vmd rendering cartoons.. etc
    $rmol->print_pdb("receptor.pdb");

=head1 DESCRIPTION

HackaMol::X::Vina provides an interface to AutoDock Vina, which is a widely used program for docking small molecules
(ligands) into biological molecules (receptors). This class provides methods for writing configuration files and for 
processing output. The input/output associated with running Vina is pretty simple, but there is still a fair amount of
scripting required to apply the program to virtual drug-screens that often involve sets of around 100,000 ligands, several
sites (centers) within a given receptor, which may also have multiple configurations.  The goal of this interface is to reduce 
the amount of scripting needed to set up massive drug screens, provide flexibility in analysis/application, and improve
control of what is written into files that can quickly accumulate. For example, the synopsis docks a ligand into a 
receptor for a collection of centers located at the hydroxy group of tyrosine residues; there are a multitude of binding
site prediction software that can be used to provide a collection of centers. Loops over ligands, receptors, centers are 
straightforward to implement, but large screens on a computer cluster will require splitting the loops into chunks that
can be spread across the queueing system.  See the examples.

This class does not include the AutoDock Vina program, which is 
L<released under a very permissive Apache license|http://vina.scripps.edu/manual.html#license>, with few 
restrictions on commercial or non-commercial use, or on the derivative works, such is this. Follow these 
L<instructions | http://vina.scripps.edu/manual.html#installation> to acquire the program. Most importantly, if 
you use this interface effectively, please be sure to cite AutoDock Vina in your work:

O. Trott, A. J. Olson, AutoDock Vina: improving the speed and accuracy of docking with a new scoring function, efficient optimization and multithreading, Journal of Computational Chemistry 31 (2010) 455-461 

Since HackaMol has no pdbqt writing capabilities (yet, HackaMol can read pdbqt files; hush_read=>1 recommended, see
synopsis), the user is required to provide those  files. L<OpenBabel| http://openbabel.org/wiki/Main_Page> and L<MGLTools| http://mgltools.scripps.edu> are popular
and effective. This is still a work in progress and the API may change. Documentation will improve as API
gets more stable... comments/contributions welcome! The automated testing reported on metacpan will likely give a bunch 
of fails until I have time to figure out how to skip tests calling on the vina program to run.  

=head1 METHODS

=head2 write_input

This method takes no arguments; it returns, as a scalar, the input constructed from attributes.  This method is called by map_input method via the map_in attribute to write the configuration file for running Vina. 

=head2 map_input

provided by L<HackaMol::X::Roles::ExtensionRole>. Writes the configuration file for Vina. See dock and dock_mol methods.

=head2 map_output

provided by L<HackaMol::X::Roles::ExtensionRole>. By default, this method returns the docking scores as an array.

=head2 dock_mol

this method takes the number of binding modes (Integer) as an argument (Int). The argument is optional, and the num_modes attribute is rewritten if passed. This method calls the map_input and map_output methods for preparing and running Vina. It loads the resulting pdbqt and scores into a L<HackaMol::Molecule> object.  The scores are stored into the score attribute provided by the L<HackaMol::QmMolRole>. See the synopsis for an example.

=head2 dock

this method is similar to dock_mol, but returns only the scores.

=head1 ATTRIBUTES

=head2 mol 

isa L<HackaMol::Molecule> object that is 'ro' and provided by L<HackaMol::X::Roles::ExtensionRole>.  

=head2 map_in map_out 

these attributes are 'ro' CodeRefs that can be adjusted in a given instance of a class. These are provided by L<HackaMol::X::Roles::ExtensionRole>.  Setting the map_in and map_out attributes are for advanced use.  Defaults are provided that are used in the map_input and map_output methods.

=head2 receptor ligand 

these attributes are 'rw' and coerced into L<Path::Tiny> objects using the AbsPath type provided by L<MooseX::Types::Path::Tiny>.  Thus, setting the receptor or ligand attributes with a string will store the entire path to the file, which 
is provided to Vina via the input configuration file. The receptor and ligand attributes typically point to pdbqt 
files used for running the docking calculations.    

=head2 save_mol 

this attribute isa 'Bool' that is 'rw'.  

=head2 center

this attribute isa Math::Vector::Real object that is 'rw'.  This attribute comes with a trigger that writes the 
center_x, center_y, and center_z attributes that are used in Vina configuration files.

=head2 center_x center_y center_z 

this attribute isa Num that is 'rw'. These attributes provide the center for the box that (with size_x, size_y, size_z) define the docking space searched by Vina. Using the center attribute may be more convenient since it has the same
type as the coordinates in atoms.  See the synopsis.

=head2 size_x size_y size_z

this attribute isa Num that is 'rw'. These attributes provide the edgelengths of the the box that (with center_x, 
center_y, center_z) define the docking space searched by Vina.

=head2 num_modes 

this attribute isa Int that is 'rw'. It provides the requested number of binding modes (ligand configurations) for 
Vina via the configuration file.  Vina may return a smaller number of configurations depending on energy_range
or other factors (that need documentation). 

=head2 energy_range 

this attribute isa Int that is 'rw'. In kcal/mol, provides a window for the number of configurations to return. 

=head2 exhaustiveness 

this attribute isa Int that is 'rw'. The higher the number the more time Vina will take looking for optimal
docking configurations.

=head2 cpu

this attribute isa Int that is 'rw'. By default Vina will try to use all the cores available.  Setting this 
attribute will limit the number of cores used by Vina.  

=head2 scratch

this attribute isa L<Path::Tiny> that is 'ro' and provided by  L<HackaMol::PathRole>.  Setting this attribute return a 
Path::Tiny object with absolute path that will be created if needed and then used for  
all Vina calculations to be run.

=head2 in_fn

this attribute isa L<Path::Tiny> that is 'rw' and provided by L<HackaMol::PathRole>.  The default is set to conf.txt 
when the object is built using the new method.  If many instances of Vina will be running at the same time in the
same directory, this conf.txt will need to be unique for each one!!!  The same applies to out_fn which is 
described next.

=head2 out_fn

this attribute isa L<Path::Tiny> that is 'rw' and provided by L<HackaMol::PathRole>. The default is set to a value 
derived from the the basename of the ligand attribute. i.e. out_fn is set to lig_out.pdbqt from 
/some/big/path/lig.pdbqt.  The Vina default behavior is to write to /some/big/path/lig_out.pdbqt, is usually not
wanted (by me anyway); thus, the default is always set and written to the configuration file.  If many instances 
of Vina will be running at the same time in the same directory, the output will need to be unique for each one as
described above.

=head1 SEE ALSO

=over 4

=item *

L<HackaMol>

=item *

L<HackaMol::X::Roles::ExtensionRole>

=item *

L<HackaMol::X::Calculator>

=item *

L<PBS::Client>

=item *

L<Vina | http://vina.scripps.edu>

=item *

L<MGLTools   | http://mgltools.scripps.edu>

=item *

L<Open Babel | http://openbabel.org>

=back

=head1 EXTENDS

=over 4

=item * L<Moose::Object>

=back

=head1 CONSUMES

=over 4

=item * L<HackaMol::Roles::ExeRole>

=item * L<HackaMol::Roles::ExeRole|HackaMol::Roles::PathRole>

=item * L<HackaMol::Roles::PathRole>

=item * L<HackaMol::X::Roles::ExtensionRole>

=back

=head1 AUTHOR

Demian Riccardi <demianriccardi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Demian Riccardi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
