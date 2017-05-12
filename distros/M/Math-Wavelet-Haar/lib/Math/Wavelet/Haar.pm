package Math::Wavelet::Haar;

use 5.005005;
use strict;
use warnings;

use Storable qw(dclone);

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Wavelet::Haar ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
        transform1D
        transform2D
        detransform1D
        detransform2D
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.06';

# Preloaded methods go here.

sub transform1D
{
    my @input=@_;
    return if (!is_power2(scalar(@input)));
    my @output=(0)x@_;

   my $length=@input>>1;
 
    for (; ; $length >>= 1) {
        #length=2^n, WITH DECREASING n
        
        for my $i (0..$length-1) 
        {
            my $sum = $input[$i*2]+$input[$i*2+1];
            my $difference = $input[$i*2]-$input[$i*2+1];
            $output[$i] = $sum;
            $output[$length+$i] = $difference;
        }
        return @output if ($length == 1) ;
        
        #//Swap arrays to do next iteration
        @input[0..$length*2]=@output[0..$length*2];
    }
}

sub is_power2
{
  $_[0] && ($_[0]-1&$_[0] ) == 0 
}

sub transform2D
{
  my @input = @{dclone(\@_)};

  my $length = @_;
  
  my $width = @{$input[0]};
  return if (!is_power2($width));
  for (1..$length-1)
  {
    return if (@{$input[$_]} != $width);
  }
  
  #do the X direction
  for (0..$length-1)
  {
    @{$input[$_]} = transform1D(@{$input[$_]});
  }
  
  for my $i (0..$width-1)
  { 
    my @col = map { $_->[$i] } @input;
    
    @col = transform1D(@col);
    
    for my $l (0..$#col)
    {
      $input[$l]->[$i] = $col[$l];
    }
  }  
  
  return @input;
}

sub detransform1D
{
    my @input=@_;
    return if (!is_power2(scalar(@input)));
    my @output=@input;

   my $length=1;
 
    for (; $length<=@input>>1; $length <<= 1) 
    {
      for my $i (0..$length-1)
      {
        my $x = ($input[$i] + $input[$i+$length])/2;
        my $y = ($input[$i] - $input[$i+$length])/2;
        $output[$i*2] = $x;
        $output[$i*2+1] = $y;
      }
      #//Swap arrays to do next iteration
      @input = @output;
    }
    
    return @input;
}

sub detransform2D
{
  my @input = @{dclone(\@_)};
  my $length = @_;
  
  my $width = @{$input[0]};
  return if (!is_power2($width));
  for (1..$length-1)
  {
    return if (@{$input[$_]} != $width);
  }
  
  #do the X direction
  for (0..$length-1)
  {
    @{$input[$_]} = detransform1D(@{$input[$_]});
  }
  
  for my $i (0..$width-1)
  { 
    my @col = map { $_->[$i] } @input;
    
    @col = detransform1D(@col);
    
    for my $l (0..$#col)
    {
      $input[$l]->[$i] = $col[$l];
    }
  }  
  
  return @input;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Math::Wavelet::Haar - Perl extension for transforming data with the Haar Wavelet

=head1 SYNOPSIS

  use Math::Wavelet::Haar qw(:all);

  my @test = qw(1 2 3 4 5 6 7 8);
  my @result = transform1D(@test);
  
  my @test = ([0,1,2,3],[1,2,3,4],[2,3,4,5],[3,4,5,6]);
  my @result = transform2D(@test);

  my @test = qw(36 -16 -4 -4 -1 -1 -1 -1);
  my @result = detransform1D(@test);
  
  my @test = ([48,-16,-4,-4],[-16,0,0,0],[-4,0,0,0],[-4,0,0,0]);
  my @result = detransform2D(@test);

  my @test = ([48,-16,-4,-4],[-16,0,0,0],[-4,0,0,0],[-4,0,0,0]);
  @result = detransform2D(transform2D(@test));
  
  @result == @test;

=head1 DESCRIPTION

Math::Wavelet::Haar is a module for performing a discrete wavelet transform using the Haar wavelet.

=head2 EXPORT

=item B<transform1D>
    @result = transform1D(@input);
takes a single array as input, and returns the transformed result, @input MUST be a power of two in length, if it is not, then it will return undef

=item B<transform2D>
    @result = transform2D(@input);
takes a single two dimensional array as input, and returns the transformed result, @input MUST be a power of two in length and width, if it is not, then it will return undef

=item B<detransform1D>
    @result = detransform1D(@input);
takes a single array as input, and returns the inverse transform as the result, @input MUST be a power of two in length, if it is not, then it will return undef

=item B<detransform2D>
    @result = detransform2D(@input);
takes a single two dimensional array as input, and returns the inverse transform as the result, @input MUST be a power of two in length and width, if it is not, then it will return undef

=head1 SEE ALSO

Wikipedia articles on the Haar Wavlet, Discrete Wavelet Transforms, and lots and lots of math

=head1 CHANGES

=item v0.01
	First release, supports only transforming

=item v0.02
	Second release, supports transforming and its inverse
	Changed API significatly

=item v0.05
	Third public release, fixes catastrophic bug that causes the input to the 2d transforms to be mangled

=item v0.06
	Added some corrected dependencies and marked the module as usable by earlier perl versions
	Also removed an incorrect print statement, that outputted debugging information that shouldn't have been outputted

=head1 AUTHOR

Ryan Voots <lt>simcop2387@yahoo.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Ryan Voots

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
