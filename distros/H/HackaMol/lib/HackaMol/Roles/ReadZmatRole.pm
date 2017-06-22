package HackaMol::Roles::ReadZmatRole;
$HackaMol::Roles::ReadZmatRole::VERSION = '0.040';
# ABSTRACT: Read files with molecular information
use Moose::Role;
use HackaMol::PeriodicTable qw(%KNOWN_NAMES _trim);
use Math::Vector::Real;
use Carp;
use List::MoreUtils qw(singleton);

with qw(
        HackaMol::Roles::NERFRole
);

sub read_zmat_atoms {

    #xyz file and generate list of Atom object
    my $self = shift;
    my $fh   = shift;
#    my $file = shift;
#    my $fh   = FileHandle->new("<$file") or croak "unable to open $file";

    my @atoms;
    my ( $n, $t ) = ( 0, 0 );
  
    my @zmat = <$fh>;
    @zmat = _substitute_variables(@zmat);

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
      print $_ foreach @zmat;
      print "Indices of lines to be processed: ", join("\n", @iA, @iB, @iC, @iD, @iE);      
      croak "\nThere is something funky with your zmatrix";
    }

    foreach my $ia (@iA) {
        my ( $sym, $iat1, @xyz ) = split( ' ', $zmat[$ia] );
        $atoms[$ia] = HackaMol::Atom->new(
                        name   => $sym.$ia,
                        symbol => $sym,
                        coords => [ V(@xyz) ]
        );
    }
   
    foreach my $ib (@iB) {
        my $sym = $zmat[$ib];
        my $a   = $self->init;
        $sym =~ s/^\s+|\s+$//;
        $atoms[$ib] = HackaMol::Atom->new(
            name   => $sym.$ib,
            symbol => $sym,
            coords => [$a]
        );
    }

   # print Dump 'B', \@atoms;

    foreach my $ic (@iC) {
        my ( $sym, $iat1, $R ) = split( ' ', $zmat[$ic] );
        my $a = $atoms[ $iat1 - 1 ]->xyz;
        my $b = $self->extend_a( $a, $R );
        $atoms[$ic] = HackaMol::Atom->new(
            name   => $sym.$ic,
            symbol => $sym,
            coords => [$b]
        );
    }

   # print Dump 'C', \@atoms;

    foreach my $id (@iD) {
        my ( $sym, $iat1, $R, $iat2, $ang ) = split( ' ', $zmat[$id] );
        my $a = $atoms[ $iat1 - 1 ]->xyz;
        my $b = $atoms[ $iat2 - 1 ]->xyz;
        my $c = $self->extend_ab( $b, $a, $R, $ang );
        $atoms[$id] = HackaMol::Atom->new(
            name   => $sym.$id,
            symbol => _trim($sym),
            coords => [$c]
        );
    }

    # print Dump 'D', \@atoms;

    foreach my $ie (@iE) {
        my ( $sym, $iat1, $R, $iat2, $ang, $iat3, $tor ) =
          split( ' ', $zmat[$ie] );
        my $a = $atoms[ $iat1 - 1 ]->xyz;
        my $b = $atoms[ $iat2 - 1 ]->xyz;
        my $c = $atoms[ $iat3 - 1 ]->xyz;
        my $d = $self->extend_abc( $c, $b, $a, $R, $ang, $tor );
        $atoms[$ie] = HackaMol::Atom->new(
            name   => $sym.$ie,
            symbol => _trim($sym),
            coords => [$d]
        );
    }
    $atoms[$_]->iatom($_) foreach ( 0 .. $#atoms );
    return (@atoms);

}

sub _substitute_variables{
    my @Zmat = @_;

    chomp @Zmat;

    my %bin;
    my %var  =  map {
                      my ($key,$val) = map{ s/^\s+|\s+$//; $_ } split(/\s*=\s*/,$_);
                      $bin{$key}++;
                      $key => $val,
                    } grep {/=/} @Zmat;

    # check for double entry of variables
    my @too_many = grep {$bin{$_}>1} keys(%bin);     
    if (@too_many) {
      carp "ReadZMatRole> you have more than one entry for these variables: ". join("\n", @too_many);
    }

    @Zmat    = grep {!/(^\#)|=|(^\s*$)/} @Zmat;

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

HackaMol::Roles::ReadZmatRole - Read files with molecular information

=head1 VERSION

version 0.040

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
