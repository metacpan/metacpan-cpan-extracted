package Image::BoxModel::Chart::Data;

use warnings;
use strict;
use Carp;
use POSIX;

=head1 NAME

Image::BoxModel::Chart::Data - Data manipulation and analysis methods for Image::BoxModel::Chart

=head1 SYNOPSIS

  For an example and general information see Image::BoxModel::Chart.pm

=head1 DESCRIPTION

Image::BoxModel::Chart::Data implements methods for data manipulation and analysis.

=head2 Methods

=head3 ArrayHeighestLowest

  ($highest, $lowest) = $image-> ArrayHeighestLowest(@array)  

Feed it an array and get the highest and the lowest value of it.

=cut

sub ArrayHighestLowest{
	my $image 	= shift;
	my @array 	= @_;
	
	@array 		= sort {$a <=> $b} @array;
	my $highest = $array[-1];
	my $lowest 	= $array[0];
	
	return $highest, $lowest;
}

=head3 ScaleSkip

throw highest, lowest value at it and get maximum_lines (10 ist default) on the scale.
You can specify scale_skip_minimum, if you want, but it will be ignored, if you set it = 0.


=cut

sub ScaleSkip{
	my $image 	= shift;
	my %p 		= @_;
	foreach ('highest', 'lowest'){
		croak ("You need to specify $_") unless (exists $p{$_});
	}
	my $maximum_lines;
	$maximum_lines = $p{maximum_lines} or $maximum_lines = 10;
	
	my $range 	= $p{highest}-$p{lowest} -1; #This is a little trick. I want 10, 20, 50, 100, 200, 500 etc. to be in the lower group. This is much easier accomplished that way.
	$range 		= $range * 10 / $maximum_lines; # next trick. If you want 20 lines, then the range is halved. this way scale_skip becomes half as big as it defaultely would.

	my $length = length (ceil($range));
		
	my $first_digit;
	
	# 10-19 -> 2
	# 20-49 -> 5
	# 50-99 -> 10
	if (substr ($range, 0,1) <= 1){	# hmm, 0 should not happen, because the first digit of a number is 1-9, isn't it?
		$first_digit = 2;
	}
	elsif (substr ($range, 0,1) <=4){
		$first_digit = 5;
	}
	else{
		$first_digit = 10;
	}
	
	my $scale_skip = $first_digit * 10 ** ($length-2); #if length is 2 e.g., scale_skip is just = $first_digit. From 100-999 it gets = 10 -> scale_skip becomes 20, 50, 100. And so on.
	# This works for smaller ranges like .1 as well. I believe.
	
	$scale_skip = $p{scale_skip_minimum} if (exists $p{scale_skip_minimum} and $p{scale_skip_minimum} and $scale_skip < $p{scale_skip_minimum});
	
	#~ print "Range: $range\t Länge: $length\t Erstes Zeichen: $first_digit\t ScaleSkip: $scale_skip\n";
	return $scale_skip;
}

=head3 ArrayHighestWidest

 ($highest_text_size, $widest_text_size) = ArrayHighestWidest(values => [@values], textsize => $textsize, rotate => $rotate in degrees)

Feed it an array of numbers or text and get how much space the largest value needs.

=cut

sub ArrayHighestWidest{
	my $image 	= shift;
	my %p 		= @_;
	
	my $widest  = 0;
	my $highest = 0;
	foreach (@{$p{values}}){	
		#~ print "$_\n";
		my ($width, $height) = $image -> GetTextSize(text => $_, textsize => $p{textsize}, rotate => $p{rotate});
		$widest = $width if ($width > $widest);
		$highest = $height if ($height > $highest);
	}
	return $highest, $widest;
}

=head3 ExpandToGrid

 $value_on_grid = $image -> ExpandToGrid (value => $value, skip => $skip, base => $base);

=cut

sub ExpandToGrid{
	my $image 	= shift;
	my %p 		= @_;
	my $step;	#if we step upwards or downwards
	my $counter = 0;
	
	if ($p{value} > $p{base}){
		$step 	= $p{skip};
		$counter++ while ($step * $counter + $p{base} < $p{value});	#0 * step .. 1 * step until bigger than the value (normally the highest of the array..)
	}
	elsif ($p{value} < $p{base}){
		$step 	= -$p{skip};
		$counter++ while ($step * $counter + $p{base} > $p{value});
	}
	else {
		return $p{value};	#if the given value equals to the base line, no expansion is needed.
	}
	
	$p{value} 	= $step * $counter + $p{base}; 
	
	return $p{value};
}

=head3 BuildScaleArray

  my @scale_annotations = BuildScaleArray(lowest => $p{lowest}, highest => $p{highest}, base_line => $p{base_line}, skip => $p{scale_skip});

=cut

sub BuildScaleArray{ 
	my $image 	= shift;
	my %p 		= @_;
	my @scale_array;
	my $counter = 1;
	
	push @scale_array, $p{base};		#First, base goes into @array: Ensure it to be in @array!
	
								#then, all values lower than base_line are prepended
	while ((-$p{skip}) * $counter + $p{base} >= $p{lowest}){
		unshift @scale_array, (-$p{skip}) * $counter + $p{base};
		$counter ++;
	}
	
								#and then, all values bigger than base_line are appended
	$counter = 1;
	while ($p{skip} * $counter + $p{base} <= $p{highest}){
		push @scale_array, $p{skip} * $counter + $p{base};
		
		#~ print "Adding: ",$p{skip} * $counter, " <= ", $p{highest}, "\n";
		$counter ++;
	}
	
	#this seems quite ugly and long. It ensures that the exact value of base is in the array 
	#and it makes it easily possible to do multiplications instead of continued addition, 
	#which might lead to increasing errors if skip holds a value which is not precisely representable. 0.1 e.g.
	#I don't know how precise perl calculates and if this approach improves the results, btw..
	return @scale_array;
}

sub PopulateArrays{
	my $image 	= shift;
	my %p 		= @_;
	
	my (@datasets, @colors, @bordercolors);	#@values is always an 2d-array holding the data-sets.
	my $counter = 0;
	my $max_values = 0;
	foreach (sort keys %p){
		next unless (/^dataset/);
		$datasets[$counter] = $p{$_};
		
		my $c = $_ ;	
		$c=~ s/^dataset/color/;	#dataset_01 becomes color_01
		$colors[$counter] = $p{$c} or $colors[$counter] = $p{color}[$counter] or $colors[$counter] = $p{color}[0];
		
		my ($h, $l) = $image->ArrayHighestLowest(@{$datasets[$counter]});
		$p{highest} = $h unless (exists $p{highest} and $p{highest} > $h);
		$p{lowest}  = $l unless (exists $p{lowest} and $p{lowest} < $l);
		$max_values = scalar (@{$datasets[$counter]}) unless ($max_values and $max_values > @{$datasets[$counter]});
		
		$counter ++;
	}
	return (\@datasets, \@colors, \@bordercolors, $max_values, %p);
}

1;
