package HackaMol::Roles::NERFRole;
 # ABSTRACT: Role providing Natural extension reference frame implementation for molecular building 
$HackaMol::Roles::NERFRole::VERSION = '0.043';
use 5.008;
use Moose::Role;
use Math::Vector::Real;
use Math::Trig; 

my $orig = V(0,0,0);

sub init {
  # adding the first vector
  my $self = shift;
  if (@_ == 3){
    return V(@_);
  }
  else {
    return $orig;
  }
}

sub extend_a {
  #allow the use of optvec to give control over the addition
  my ($self, $a, $R, $optvec) = @_;
  $optvec = V(1,0,0) unless defined($optvec);
  return ($a + $R*$optvec->versor); 
}

sub extend_ab {
  my ($self,$a,$b,$R,$ang) = @_;
  $ang  = deg2rad(180-$ang);
  my ($ba, $j, $k) = ($b-$a)->rotation_base_3d;
  my $c = $b+$ba*$R;
  $c = $j->rotate_3d($ang, $c-$b) + $b;
  return ($c);
}

sub extend_abc {
  my ($self,$a,$b,$c,$R,$ang,$tors) = @_;
  $ang  = deg2rad(180-$ang);
  $tors = deg2rad($tors);
  my $cang = cos($ang);
  my $sang = sin($ang);
  my $ctor = cos($tors);
  my $stor = sin($tors);

  my $bc = ($c-$b)->versor;
  my $n = (($b-$a) x $bc)->versor;

  my $D = $R*($bc*$cang + ($n x $bc)*$sang*$ctor + $n*$sang*$stor) + $c;
  return $D;
}

no Moose::Role;

1;

__END__

=pod

=head1 NAME

HackaMol::Roles::NERFRole - Role providing Natural extension reference frame implementation for molecular building 

=head1 VERSION

version 0.043

=head1 SYNOPSIS

       # Adds the NERF capabilities to consuming classes        
       # Let's say that the $bld object below consumes this Role 
       #Let's build a six member ring 

       push @vecs, $bld->init() ; 
       push @vecs, $bld->extend_a(  $vecs[0]  ,   1.47              );
       push @vecs, $bld->extend_ab( @vecs[0,1],   1.47, 109.5       );
       push @vecs, $bld->extend_abc(@vecs[0,1,2], 1.47, 109.5,  60 );
       push @vecs, $bld->extend_abc(@vecs[1,2,3], 1.47, 109.5, -60 );
       push @vecs, $bld->extend_abc(@vecs[2,3,4], 1.47, 109.5,  60 );

       printf ("C %10.6f %10.6f %10.6f\n", @$_ ) foreach @vecs;

=head1 DESCRIPTION

The HackaMol::X::NERF library is a quick implementation of the Natural 
Extension Reference Frame method for building cartesian coordinates from 
internal coordinates.  It is experimental. In fact, there are
no substantial tests yet! They will be added soon. 
The API will change and expand.  Currently, the class provides four methods four initializing and extending a vector space. Lend me a hand if you are interested!

Study Z-matrices and the synopsis should be easy to understand. All angles are in degrees.

=head1 METHODS

=head2 init

optional argument is list of three numbers: x, y, and z. 

Returns an MVR object constructed from V(0,0,0) or V(x,y,z). 

=head2 extend_a(MVR1, R)

two arguments MVR1 and R, along with optional argument MVR2. 

Returns an MVR object that is a distance R from MVR1. This new vector will be 
displaced along the x axis unless the optional MVR2 is passed. If MVR2 the 
MVR returned is displace by R times the unit vector parallel to MVR1. 

=head2 extend_ab(MVR1, MVR2, R, ANGLE)

four arguments MVR1, MVR2, R, and ANGLE. 

Returns an MVR object that is a distance R from MVR2 and at ANGLE from MVR1.

=head2 extend_abc(MVR1, MVR2, MVR3, R, ANGLE, TORSION)

six arguments MVR1, MVR2, MVR3, R, ANGLE, and TORSION. 

Returns an MVR object that is a distance R from MVR3, at ANGLE from MVR2, 
and at TORSION from MVR1 via the vector between MVR2 and MVR3.

=head1 AUTHOR

Demian Riccardi <demianriccardi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Demian Riccardi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
