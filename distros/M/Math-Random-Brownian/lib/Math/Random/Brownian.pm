package Math::Random::Brownian;

use 5.008005;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Math::Random::Brownian ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';
sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Math::Random::Brownian::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';
        # Fixed between 5.005_53 and 5.005_61
#XXX    if ($] >= 5.00561) {
#XXX        *$AUTOLOAD = sub () { $val };
#XXX    }
#XXX    else {
            *$AUTOLOAD = sub { $val };
#XXX    }
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Math::Random::Brownian', $VERSION);
use Params::Validate qw( validate SCALAR );

my $Validate = 
    {
     LENGTH   => {type => SCALAR,
                  callbacks =>
                  {
                   'is positive' =>
                   sub{ $_[0] > 0},
                   'is an integer' =>
                   sub{ $_[0] == int $_[0]},
                  },
                 },
     HURST    => {type => SCALAR,
                  callbacks =>
                  {
                   'is between 0 and 1' =>
                   sub{ $_[0] > 0 && $_[0] < 1},
                  },
                 },
     VARIANCE => {type => SCALAR,
                  callbacks =>
                  {
                   'is positive' =>
                   sub{ $_[0] > 0 },
                  },
                 },
     NOISE    => {type => SCALAR,
                  callbacks =>
                  {
                   'must be Gaussian or Brownian' =>
                   sub{ $_[0] =~ 'Gaussian' || $_[0] =~ 'Brownian' },
                  },
                 },
   };
  
 my $Wavelet_Validate = 
   {
    %$Validate,
    APPROX_PARAM => {type => SCALAR,
                      callbacks =>
                      {
                       'is an integer' =>
                       sub{ $_[0] == int $_[0] },
                      },
                     },

    };
    
# Preloaded methods go here.
sub new
{
 my $class = shift;
 
 my $self = {};

 $self->{SEED1} = time ^ ($$ + ($$ << 15));
 $self->{SEED2} = time ^ $$ ^ unpack "%L*", `ps axww | gzip`;

 bless $self, $class;

 return $self;
}

sub Hosking
{
 my $self = shift;
 my %p = ();
 %p = validate(@_,$Validate);

 my $n = int (log($p{LENGTH})/log(2.0)) + 1;
 my $H = $p{HURST};
 my $L = $p{VARIANCE};
 my $cum;
 if( $p{NOISE} =~ 'Gaussian' ) { $cum = 0; } 
 if( $p{NOISE} =~ 'Brownian' ) { $cum = 1; } 
 my $seed1 = $self->{SEED1};
 my $seed2 = $self->{SEED2}; 

 my $output = __hosking($n,$H,$L,$cum,$seed1,$seed2);
  
 # Save new seeds
 $self->{SEED1} = $$output[-2];
 $self->{SEED2} = $$output[-1];
 
 # Truncate the array
 my @new_output = (); 
 for(my $i=0;$i<$p{LENGTH};$i++)
 {
  $new_output[$i] = $$output[$i];
 }
 
 return @new_output;
}

sub Circulant
{
 my $self = shift;
 my %p = ();
 %p = validate(@_,$Validate);

 my $n = int (log($p{LENGTH})/log(2.0)) + 1;
 my $H = $p{HURST};
 my $L = $p{VARIANCE};
 my $cum;
 if( $p{NOISE} =~ 'Gaussian' ) { $cum = 0; } 
 if( $p{NOISE} =~ 'Brownian' ) { $cum = 1; } 
 my $seed1 = $self->{SEED1};
 my $seed2 = $self->{SEED2}; 

 my $output = __circulant($n,$H,$L,$cum,$seed1,$seed2);
  
 # Save new seeds
 $self->{SEED1} = $$output[-2];
 $self->{SEED2} = $$output[-1];
 
 # Truncate the array
 my @new_output = (); 
 for(my $i=0;$i<$p{LENGTH};$i++)
 {
  $new_output[$i] = $$output[$i];
 }
 
 return @new_output;
}

sub ApprCirc
{
 my $self = shift;
 my %p = ();
 %p = validate(@_,$Validate);

 my $n = int (log($p{LENGTH})/log(2.0)) + 1;
 my $H = $p{HURST};
 my $L = $p{VARIANCE};
 my $cum;
 if( $p{NOISE} =~ 'Gaussian' ) { $cum = 0; } 
 if( $p{NOISE} =~ 'Brownian' ) { $cum = 1; } 
 my $seed1 = $self->{SEED1};
 my $seed2 = $self->{SEED2}; 

 my $output = __apprcirc($n,$H,$L,$cum,$seed1,$seed2);
  
 # Save new seeds
 $self->{SEED1} = $$output[-2];
 $self->{SEED2} = $$output[-1];
 
 # Truncate the array
 my @new_output = (); 
 for(my $i=0;$i<$p{LENGTH};$i++)
 {
  $new_output[$i] = $$output[$i];
 }
 
 return @new_output;
}

sub Paxson
{
 my $self = shift;
 my %p = ();
 %p = validate(@_,$Validate);

 my $n = int (log($p{LENGTH})/log(2.0)) + 1;
 my $H = $p{HURST};
 my $L = $p{VARIANCE};
 my $cum;
 if( $p{NOISE} =~ 'Gaussian' ) { $cum = 0; } 
 if( $p{NOISE} =~ 'Brownian' ) { $cum = 1; } 
 my $seed1 = $self->{SEED1};
 my $seed2 = $self->{SEED2}; 

 my $output = __paxson($n,$H,$L,$cum,$seed1,$seed2);
  
 # Save new seeds
 $self->{SEED1} = $$output[-2];
 $self->{SEED2} = $$output[-1];
 
 # Truncate the array
 my @new_output = (); 
 for(my $i=0;$i<$p{LENGTH};$i++)
 {
  $new_output[$i] = $$output[$i];
 }
 
 return @new_output;
}

sub DESTROY
{
 my $self = shift;
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Math::Random::Brownian - Perl module for generating Fractional Brownian and Gaussian Noise

=head1 SYNOPSIS

 use Math::Random::Brownian;
 my $noise = Math::Random::Brownian->new(); 

 my @Hosking_noise = $noise->Hosking(LENGTH => 30,
                                     HURST => 0.5,
                                     VARIANCE => 1.0,
                                     NOISE => 'Gaussian' );
  
 my @Circ_noise = $noise->Circulant(LENGTH => 30,
                                    HURST => 0.5,
                                    VARIANCE => 1.0,
                                    NOISE => 'Brownian' );

 my @Appr_noise = $noise->ApprCirc(LENGTH => 30,
                                   HURST => 0.5,
                                   VARIANCE => 1.0,
                                   NOISE => 'Brownian');

 my @Paxson = $noise->Paxson(LENGTH => 30,
                             HURST => 0.5,
                             VARIANCE => 1.0,
                             NOISE => 'Gaussian');

=head1 DESCRIPTION

Math::Random::Brownian is a perl module for calculating a realization of
either fractional Brownian Motion, or a fractional Gaussian sequence.
This is accomplished using the various methods.  Currently, the C code
for this module is due to Ton Dieker with slight modifications by Walter
Szeliga to help the code stand alone.  For more information, refer to

Dieker, T. Simulation of fractional Brownian motion, Master's Thesis,
University of Twente, Dept. of Mathematical Sciences.  

This may be found at http://homepages.cwi.nl/~ton/fbm/.

Hash values and their meanings are as follows:

=over

=item LENGTH

=back

The length of the realization desired.  This must be an integer.

=over

=item HURST

=back

The Hurst parameter of the output sequence.  If A is the slope of a 1/f
process, then A = 2H-1 where H is the Hurst parameter.

=over

=item VARIANCE

=back

The variance of the output sequence.

=over

=item NOISE

=back

Is equal to either 'Gaussian' or 'Brownian' depending on whether
one would like fractional Gaussian noise, or it's cumulative sum --
fractional Brownian motion.


=head1 SEE ALSO

Dieker, T. Simulation of fractional Brownian motion, Master's Thesis,
University of Twente, Dept. of Mathematical Sciences.  

This may be found at http://homepages.cwi.nl/~ton/fbm/.

For other software, see http://www.geology.cwu.edu/grad/walter

=head1 AUTHOR

Walter Szeliga, E<lt>walter@geology.cwu.eduE<gt>
Original C code by Ton Dieker
FFT code by J. Claerbout

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Walter Szeliga

Original C code Copyright (C) 2002 Ton Dieker

FFT code by J. Claerbout Copyright (C) 1985

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
