package HackaMol::Roles::ReadYAMLRole;
$HackaMol::Roles::ReadYAMLRole::VERSION = '0.046';
# ABSTRACT: Read files with molecular information
use Moose::Role;
use HackaMol::PeriodicTable qw(%KNOWN_NAMES _trim);
use Math::Vector::Real;
use Carp;
use List::MoreUtils qw(singleton);

with qw(
        HackaMol::Roles::NERFRole
);

#  atoms:
#- N 0    0.483824   1.697569  -0.701935
#....
#- C 2   CC 3 CCC 4 CCCC
#vars:
#- CC :       1.54
#- CCC :    106.42
#- CCCC :  [-81.90, 89, 09]

sub read_yaml_atoms {
    # this is going to be the simplest implementation for now using the code from the zmatrix reader
    # generate a zmatrix (or zmatrices if there are scans) and push on to the atoms
    #xyz file and generate list of Atom object
    #issue 16 on github
    my $self = shift;
    my $yaml = shift;
    #use Data::Dumper;
    #print Dumper $yaml;
    my %vars    = %{$yaml->{vars}};
    my @atlines = @{$yaml->{atoms}};
    my @atoms;
    my ( $n, $t ) = ( 0, 0 );

    my @scan_vars = grep {ref($vars{$_}) eq 'ARRAY'} keys (%vars) ;
    if (@scan_vars) {
      my $scan_var = pop @scan_vars;
      carp "scanning more than one coordinate not supported; ignoring scans for $scan_vars[0]" if @scan_vars ;
      my $values_rh = delete $vars{$scan_var};

      foreach my $value (@{$values_rh}){
        $vars{$scan_var} = $value;
        my @atlines = _yaml_substitute_variables(\%vars, \@atlines);
        @atoms = $self->parse_zmat_atoms(\@atlines, \@atoms, $t);       
        $t++;
      }
    }
    else {

        my @atlines = _yaml_substitute_variables(\%vars, \@atlines);
        @atoms = $self->parse_zmat_atoms(\@atlines, \@atoms, $t);       
    }

    $atoms[$_]->iatom($_) foreach ( 0 .. $#atoms );
    #use Data::Dumper;
    #print Dumper \@atoms;

    return (@atoms);

} 

sub parse_zmat_atoms {
    my $self = shift;
    my $zmat  = shift;
    my $atoms = shift;
    my $t  = shift;
    my @zmat  = @{ $zmat  };
    my @atoms = @{ $atoms };

    #use Data::Dumper;
    #print Dumper $zmat;

    # we have 5 types of extensions
    # A. SYM 0 x y z
    # B. SYM
    # C. SYM i R
    # D. SYM i R j Ang
    # E. SYM i R j Ang k Tors
    # we need to filter the indices (can't lose the location)

    #type A
    my @iA = grep { $zmat[$_] =~ m/^\s*\w+\s+0(\s+-*\d*\.*\d*){3}/ } 0 .. $#zmat;
    my @inA = singleton( 0 .. $#zmat, @iA );

    #type B
    my @iB = grep { $zmat[$_] =~ m/^\s*\w+\s*$/ } @inA;

    #type C
    my @iC = grep { $zmat[$_] =~ m/^\s*\w+(\s+\d+\s+\d*\.*\d*)\s*$/ } @inA;

    #type D
    my @iD = grep { $zmat[$_] =~ m/^\s*\w+(\s+\d+\s+\d*\.*\d*){2}\s*$/ } @inA;

    #type E
    my @iE = grep {
        $zmat[$_] =~ m/^\s*\w+(\s+\d+\s+\d*\.*\d*){2}\s+\d+\s+-*\d*\.*\d*\s*$/
    } @inA;

    my $diff = @zmat - (@iA+@iB+@iC+@iD+@iE); #scalar context
    
    if ($diff){
      print "Lines in Z-matrix: ", scalar (@zmat), " Number of lines to be processed: ", scalar (@zmat) - $diff, "\n";
      print "Lines missed: ", $diff, "\n";
      print "\n\nHere is your Z-matrix:\n";
      print $_ . "\n" foreach @zmat;
      print "Indices of lines to be processed: ", join("\n", @iA, @iB, @iC, @iD, @iE);      
      croak "\nThere is something funky with your zmatrix";
    }

    foreach my $ia (@iA) {
        my ( $sym, $iat1, @xyz ) = split( ' ', $zmat[$ia] );
        if ($t) {
          #print "$ia  SHITSHIT  $t\n";
          #print Dumper $atoms[$ia];
          $atoms[$ia]->set_coords($t, V(@xyz));
        } else {
          $atoms[$ia] = HackaMol::Atom->new(
                        name   => $sym.$ia,
                        symbol => $sym,
                        coords => [V(@xyz)]
          );
        }
    }
   
    foreach my $ib (@iB) {
        my $sym = $zmat[$ib];
        my $a   = $self->init;
        $sym =~ s/^\s+|\s+$//;
        if ($t) {
          $atoms[$ib]->set_coords($t, $a);
        } else {
          $atoms[$ib] = HackaMol::Atom->new(
            name   => $sym.$ib,
            symbol => $sym,
            coords => [$a]
          );
        }
    }

   # print Dump 'B', \@atoms;

    foreach my $ic (@iC) {
        my ( $sym, $iat1, $R ) = split( ' ', $zmat[$ic] );
        my $a = $atoms[ $iat1 - 1 ]->xyz;
        my $b = $self->extend_a( $a, $R );
        if ($t) {
          $atoms[$ic]->set_coords($t, $b);
        } else {
          $atoms[$ic] = HackaMol::Atom->new(
            name   => $sym.$ic,
            symbol => $sym,
            coords => [$b]
          );
        }
    }

   # print Dump 'C', \@atoms;

    foreach my $id (@iD) {
        my ( $sym, $iat1, $R, $iat2, $ang ) = split( ' ', $zmat[$id] );
        my $a = $atoms[ $iat1 - 1 ]->get_coords($t);
        my $b = $atoms[ $iat2 - 1 ]->get_coords($t);
        my $c = $self->extend_ab( $b, $a, $R, $ang );
        if ($t) {
          $atoms[$id]->set_coords($t, $c);
        } else {
          $atoms[$id] = HackaMol::Atom->new(
            name   => $sym.$id,
            symbol => _trim($sym),
            coords => [$c]
          );
        }
    }

    # print Dump 'D', \@atoms;

    foreach my $ie (@iE) {
        my ( $sym, $iat1, $R, $iat2, $ang, $iat3, $tor ) =
          split( ' ', $zmat[$ie] );
        my $a = $atoms[ $iat1 - 1 ]->get_coords($t);
        my $b = $atoms[ $iat2 - 1 ]->get_coords($t);
        my $c = $atoms[ $iat3 - 1 ]->get_coords($t);
        my $d = $self->extend_abc( $c, $b, $a, $R, $ang, $tor );
        if ($t) {
          $atoms[$ie]->set_coords($t, $d);
        } else {
          $atoms[$ie] = HackaMol::Atom->new(
            name   => $sym.$ie,
            symbol => _trim($sym),
            coords => [$d]
          );
        }
    }
    return @atoms;
}

sub _yaml_substitute_variables{
    my ($var,$Zmat) = (shift,shift);
    my %var  = %{ $var };
    my @Zmat = @{ $Zmat };

    foreach my $line (@Zmat){
      my @vals = split (/ /, $line);
      next unless @vals > 2;
      $line = join(' ', $vals[0], map{ exists($var{$_}) ? $var{$_} : $_ } @vals[1 .. $#vals] );
    }
    return (@Zmat);
}

no Moose::Role;

1;

__END__

=pod

=head1 NAME

HackaMol::Roles::ReadYAMLRole - Read files with molecular information

=head1 VERSION

version 0.046

=head1 SYNOPSIS

   my @atoms = HackaMol->new
                       ->read_zmat_atoms("some.zmat");

=head1 DESCRIPTION

The HackaMol::Roles::ReadZmatRole provides read_zmat_atoms for the flexible reading of Z-matrix files. 
It supports inline cartesian coordinates and variables as in the following example:

N 0     -12.781   3.620  15.274 

C 0     -11.976   4.652  15.944 

C 0     -12.722   6.019  15.985 

O 0     -13.133   6.378  14.897 

C 2  CBCA 3 CBCAC 4 CBCACO 

C 5  CBCA 2 CBCAC 3 CG1CBCAC

C 5  CBCA 2 CBCAC 3 CG2CBCAC

CBCA    = 1.54

CBCAC   = 113.4

CBCACO  = 71.85

CG1CBCAC = 54. 

CG2CBCAC = 180.

=head1 METHODS

=head2 read_zmat_atoms

One argument: the filename
Returns a list of HackaMol::Atom objects.

=head1 SEE ALSO

=over 4

=item *

L<HackaMol>

=item *

L<HackaMol::Atom>

=item *

L<HackaMol::Roles::MolReadRole>

=item *

L<Protein Data Bank|http://pdb.org>

=back

=head1 CONSUMES

=over 4

=item * L<HackaMol::Roles::NERFRole>

=back

=head1 AUTHOR

Demian Riccardi <demianriccardi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Demian Riccardi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
