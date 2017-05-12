package MassSpec::ViewSpectrum::RealVsHypPeptide;

use 5.006;
use strict;
use warnings;

use MassSpec::ViewSpectrum;

my $haveCUtilities;
if (eval 'require MassSpec::CUtilities') {
	import MassSpec::CUtilities;
	$haveCUtilities = 1;
} else {
	$haveCUtilities = 0;
}


our @ISA = qw(MassSpec::ViewSpectrum);

our $VERSION = '0.02';

my ($add_aa_A,$add_aa_R,$add_aa_N,$add_aa_D,$add_aa_C,$add_aa_E,$add_aa_Q,$add_aa_G,$add_aa_H,$add_aa_IL,$add_aa_K,$add_aa_M,$add_aa_F,$add_aa_P,$add_aa_S,$add_aa_T,$add_aa_W,$add_aa_Y,$add_aa_V);
my @add_aa_vals;



# Preloaded methods go here.

sub new (\$\@\@;\@\%\%) # (peptide, masses, intensities, [optional] annotations, annotations_matching, colormap)
{
	my $type = shift;
	my $peptide = shift;
	
	my $self = $type->SUPER::new(@_);

	
	init_add_aa ();

	$self->{peptide} = $peptide;	
	$self->{tolerance} = 0.1;

	my $i;
	my $maxintensity;

	for ($i = 0; $i <= $#{$self->{masses}}; $i++) {
		my $intensity = $self->{intensities}[$i];

		$maxintensity = $intensity unless defined $maxintensity and $maxintensity > $intensity;
	}



	$self->{HminusEpeakheight} = -0.1 * $maxintensity * $self->{yaxismultiplier};
   	$self->{otherPeakHeights} = -0.2 * $maxintensity * $self->{yaxismultiplier};
   	$self->{yScalingFactor} = (0.1/20.0);
   	$self->{yScalingOffset} = 3;



	return $self;
}


sub set {
        my ($self, $key, $value) = @_;

        $self->{$key} = $value;
}



sub plot
{
	my $self = shift;


	my ($EminusHRef,$HminusERef,$intersectionRef, $massintenRef);

	my $pep = $self->{peptide};

	my ($aRef_theoretical_masses,$aRef_annotations) = generate_theoretical_spectrum ($pep);

	# compare the experimental (E) and hypothetical (H) spectra, and compute 
	# their intersection as well as which peaks appear in one spectrum but
	# not the other
     ($EminusHRef,$HminusERef,$intersectionRef, $massintenRef) = $self->FindDiffs($aRef_theoretical_masses);

	my %inter = %$intersectionRef;
        my @masses;
        my @intensities;
        my @annotations;
        my $mass;
        my $annot;
        my $maxNegativeStrLen = 0;

	my ($HminusEpeakheight,$otherPeakHeights,$yScalingFactor,$yScalingOffset);

	$HminusEpeakheight = $self->{HminusEpeakheight};
   	$otherPeakHeights = $self->{otherPeakHeights};
   	$yScalingFactor = $self->{yScalingFactor};
	$yScalingOffset = $self->{yScalingOffset};

        foreach $mass (@$EminusHRef) {
                push (@masses,$mass);
                push (@intensities,$$massintenRef{$mass});
                push (@annotations,'');
	  }
	
	  
        foreach $mass (@$HminusERef) {
                push (@masses,$mass);
                push (@intensities,$HminusEpeakheight);
                $annot = $$aRef_annotations{$mass};
		    $maxNegativeStrLen = length $annot if length $annot > $maxNegativeStrLen;
                push (@annotations,$annot);

        }

        # plot the intersection twice; once above the axis and once below
        foreach $mass (keys %inter) {
                push (@masses,$mass);
                push (@intensities,$$massintenRef{$mass});
                $annot = $$aRef_annotations{$inter{$mass}};
                push (@annotations,$annot);
                push (@masses,$mass);
                push (@intensities,$otherPeakHeights);
                push (@annotations,'@' . $annot);
        }


	$self->{masses} = \@masses;
	$self->{intensities} = \@intensities;
	$self->{annotations} = \@annotations;
	$self->{extranegativeheight} = $yScalingFactor * ($maxNegativeStrLen - $yScalingOffset);

	$self->SUPER::plot();
}

# TODO(JAE):place local subroutines here, by convention using a leading underscore for
# these local subroutine names


my %add_aa_hsh;

sub init_add_aa {
        my @add_aa_syms = ("A","R","N","D","C","E","Q","G","H","X","K","M","F","P","S","T","W","Y","V");
        my $i = 0;
        my $sym;

($add_aa_A,$add_aa_R,$add_aa_N,$add_aa_D,$add_aa_C,$add_aa_E)=(71.03711,156.10111,114.04293,115.02694,103.00919,129.04259);
($add_aa_Q,$add_aa_G,$add_aa_H,$add_aa_IL,$add_aa_K,$add_aa_M)=(128.05858,57.02146,137.05891,113.08406,128.09496,131.04049);
($add_aa_F,$add_aa_P,$add_aa_S,$add_aa_T,$add_aa_W,$add_aa_Y,$add_aa_V)=(147.06841,97.05276,87.03203,101.04768,186.07931,163.06333,99.06841);
@add_aa_vals = ($add_aa_A,$add_aa_R,$add_aa_N,$add_aa_D,$add_aa_C,$add_aa_E,$add_aa_Q,$add_aa_G,$add_aa_H,$add_aa_IL,$add_aa_K,$add_aa_M,$add_aa_F,$add_aa_P,$add_aa_S,$add_aa_T,$add_aa_W,$add_aa_Y,$add_aa_V);

        foreach $sym (@add_aa_syms) {
                $add_aa_hsh{$sym} = $add_aa_vals[$i++];
        }
}

sub computePeptideMass      {
        my $comp = shift (@_);
	return MassSpec::CUtilities::computePeptideMass($comp) if ($haveCUtilities);
				
        my $sum = 0;
        do {
                $sum = $sum + $add_aa_hsh{chop($comp)};
        }until $comp le 0;
        return $sum;
}




sub generate_theoretical_spectrum	{
	
	my ($sequence) = @_;
	my $parent_comp = aasort ( remove_brackets ($sequence) );	#generate the parent composition which is used for determining compositions of complementary ions
	my (@family,%annotations,@masses,%ion,%conserved_labels);	#essentially the @family is for y ions and the @complement_family is for b ions, although this can be made more sophisticated easily if both ions go in the same direction
	my $length_sequence = length ($sequence);	#for the for loop
	my $chop_incrementer;	#for the for loop
	
	$ion{'y'} = 19.01839;
	$ion{'y-H2O'} = 1.007825;
	$ion{'b'} = 1.007825;
	$ion{'a'} = -26.98709;	
	#plus the proton to make a b ion, then minus CO = 27.9949
	
	$conserved_labels{'y'} = 1;
	$conserved_labels{'b'} = 1;
	$family[0] = ''; #JAE


	for ($chop_incrementer = 0;$chop_incrementer < $length_sequence;$chop_incrementer++)	{
		my $chop = chop ($sequence);	#get a 1 character piece of sequence
		unless ($chop eq "")	{
			if ( $chop eq "\)" )	{	#if this is the beginning of a missed fragmentation
				my $mf = "";
				$chop = chop ($sequence);
				do {
					$mf .= $chop;
					$chop = chop ($sequence);	
				}until $chop eq "\(";
				my $family = aasort($mf.$family[0]);
				my $complement_family = aasort (compdiff ($family,$parent_comp));
				unshift (@family, $family);
				make_ion_mass ($family,'y',\%annotations,\@masses,\%ion,\%conserved_labels);
				make_ion_mass ($family,'y-H2O',\%annotations,\@masses,\%ion,\%conserved_labels);
				if ($complement_family eq "")	{
					make_ion_mass ($parent_comp,'b',\%annotations,\@masses,\%ion,\%conserved_labels);
					make_ion_mass ($parent_comp,'a',\%annotations,\@masses,\%ion,\%conserved_labels);
				}else{
					make_ion_mass ($complement_family,'b',\%annotations,\@masses,\%ion,\%conserved_labels);
					make_ion_mass ($complement_family,'a',\%annotations,\@masses,\%ion,\%conserved_labels);
				}
			}else{
				my $family = aasort ($chop.$family[0]);
				my $complement_family = aasort ( compdiff ($family,$parent_comp) );
				unshift (@family, $family);
				make_ion_mass ($family,'y',\%annotations,\@masses,\%ion,\%conserved_labels);
				make_ion_mass ($family,'y-H2O',\%annotations,\@masses,\%ion,\%conserved_labels);
				if ($complement_family eq "")	{
					make_ion_mass ($parent_comp,'b',\%annotations,\@masses,\%ion,\%conserved_labels);
					make_ion_mass ($parent_comp,'a',\%annotations,\@masses,\%ion,\%conserved_labels);
				}else{
					make_ion_mass ($complement_family,'b',\%annotations,\@masses,\%ion,\%conserved_labels);
					make_ion_mass ($complement_family,'a',\%annotations,\@masses,\%ion,\%conserved_labels);
				}
			}
		}
	}
#	return (\@masses,\%annotations,\%conserved_labels);
	return (\@masses,\%annotations);
}
my $debug;
sub make_ion_mass	{
	my ($composition,$ion,$aRef_annotations,$aRef_masses,$hRef_ion,$aRef_conserved_labels) = @_;
	

	my $mass = computePeptideMass ($composition) + $$hRef_ion{$ion};
	my $annotation = $ion." \(".$composition."\)";


	$annotation = '@' . $annotation unless $$aRef_conserved_labels{$ion};

	#push (@$aRef_annotations,$annotation);
	$$aRef_annotations{$mass} = $annotation;

	push (@$aRef_masses,$mass);
	

}

sub remove_brackets	{
	local $_;
	$_ = shift @_;
	tr/()//d;
	return $_;
}

sub aasort	{
	return join ( "", sort ( split //,$_[0] ) );
}

sub compdiff	{
#returns the compositional difference between 2 amino acid compositions - the second needs to be longer than the first
	my ($aa_one,$aa_two) = @_;
	my ($first,$second);

	if (length ($aa_one) > length ($aa_two))	{
		$first = $aa_two;
		$second = $aa_one;
	}else{
		$first = $aa_one;
		$second = $aa_two;
	}

	my $diff = "";
	do{
		my ($faa,$saa) = (chop $first,chop $second);
		unless ($faa eq $saa)	{
			do	{
				$diff = $saa.$diff;
				$saa = chop $second;
			}until $saa eq $faa;
		}
	}until $first le "";
	$diff = $second.$diff if $second gt "";
	return $diff;
}

sub FindDiffs {
	  my $self = shift;
	  my($hyp_peptide) = @_;

	my @MassData = @{$self->{masses}};
	my @inten = @{$self->{intensities}};
	my $mass_tolerance = $self->{tolerance};

	  my($EminusHRef,$HminusERef,$interRef);
        my $exp_mass;
        my $hyp_mass;
        my $EminusH;
        my $HminusE;
        my(@EminusH,@HminusE,%intersection);

        my %hyp; # hypothetical peaks associated with $peptide
        my %exp; # experimental peaks (filtered masses)
	my %massinten; # experimental intensities

        my $count = 0;
	foreach $exp_mass(@MassData) {
                $exp{$exp_mass} = -1;
		    $massinten{$exp_mass} = $inten[$count++];

        }

	my @s = extend_spectrum(\@MassData,$mass_tolerance,0);
		
        foreach $hyp_mass (@$hyp_peptide) {
		my $mid;
                $hyp{$hyp_mass} = -1;
		if ($haveCUtilities) {
			$mid = MassSpec::CUtilities::binarySearchSpectrum($hyp_mass,\@s);
		} else {
			my $low = 0;
			my $high = @s - 1;

			while ($low <= $high) {
				$mid = int(($low+$high)/2);
				if ($hyp_mass < $s[$mid]) {
					$high = $mid - 1;
				} else {
					$low = $mid + 1;
				}
			}
			$mid++ if ($hyp_mass > $s[$mid]);
		}
		#
		# s[$mid] is now the lowest value in s just greater than $hyp_mass
		#
		#
		# Suppose our spectrum consisted of the peaks 347.42, 639.31, 722.37 and 831.93
		# and our error margin is 0.05 daltons.  Then the spectrum provided by
		# extend_spectrum() would look like:
		# s[0] = artificial negative value
		# s[1] = 347.37
		# s[2] = 347.47
		# s[3] = 639.26
		# s[4] = 639.36
		# s[5] = 722.32
		# s[6] = 722.42
		# s[7] = 831.88
		# s[8] = 831.98
		# s[9] = artificial huge value
		#
		# Suppose the input $mass is 639.27.  Then after the binary search, $mid
		# will be 4.  It turns out that $mid is always even for masses within
		# the error bands and always odd for values which fall outside the error bands.
		#
		unless ($mid & 1) { # unless ($mid is odd)
			my $index = $mid/2-1;
			my $peak = $MassData[$index];
			my $max_intensity = $inten[$index];
			$index--;
			while ($index >= 0 && abs($MassData[$index] - $hyp_mass) < $mass_tolerance) {
				if ($max_intensity < $inten[$index]) {
					$peak = $MassData[$index];
					$max_intensity = $inten[$index];
				}
				$index--;
			}
			$hyp{$hyp_mass} = 1;
			$exp{$peak} = $hyp_mass;
		}
	}



        foreach $hyp_mass (sort {$a <=> $b} (keys %hyp)) {
		if ($hyp{$hyp_mass} < 0) {
			push (@HminusE, $hyp_mass);
			
		}
        }

        # note that the hypothetical mass is logged in the intersection,
        # since that is what we want to plot
        foreach $exp_mass (sort {$a <=> $b} (keys %exp)) {
                if ($exp{$exp_mass} < 0) {
                        push (@EminusH, $exp_mass)
                } else { # note the associated experimental mass
                        $hyp_mass = $exp{$exp_mass};
                        $intersection{$exp_mass} = $hyp_mass;
                }
        }

        $EminusHRef = \@EminusH;
        $HminusERef = \@HminusE;
        $interRef = \%intersection;

        return($EminusHRef, $HminusERef, $interRef, \%massinten);
}


#
# Extend a spectrum to make it suitable for subsequent binary searching
#
sub extend_spectrum {
	my($aRef_rms,$err,$backwards_compatability) = @_;
	my $i;
	my @result = ();
	my $lastlow;
	my $lasthigh = -1;

	# place artificial low & high values to simplify subsequent binary search
	push (@result,-9999);

	for ($i = 0; $i < @{$aRef_rms}; $i++) {
		my $low = $aRef_rms->[$i] - $err;
		my $high = $aRef_rms->[$i] + $err;
		if ($backwards_compatability) {
			$low = sprintf("%.2f",$low);
			if ($high =~ /(\d+\.\d\d)/) {
				$high = $1;
			}
			$high = sprintf("%.2f",$high) + 0.009999;
		}
		if ($low < $lasthigh) { # if (two adjacent bands overlap)
			my $middle = ($lastlow + $high) / 2;
			if ($backwards_compatability) {
				$middle = sprintf("%.2f",$middle);
			}
			pop @result;
			push (@result,$middle-0.000001); # replace high-value of last band
			$low = $middle;
		}
		push (@result,$low);
		push (@result,$high);
		$lastlow = $low;
		$lasthigh = $high;
	}
	push (@result,999999999999);

	return @result;
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

MassSpec::ViewSpectrum::RealVsHypPeptide - View a real mass spectrum on the same graph as a hypothetical spectrum generated by fragmenting a peptide in silico

=head1 SYNOPSIS

  use MassSpec::ViewSpectrum::RealVsHypPeptide;
  open GRAPHIC, ">mygraphic.png" or die "Unable to open output file\n";
  binmode GRAPHIC;

  my @masses = (78.1,81.1,81.7,85.4,86.8,88.8,89.4,97.6,99.0,99.4,108.7,112.1,129.1,
    130.1,132.1,147.7,157.1,158.1,159.1,169.1,171.1,175.1,187.1,229.1,246.2,258.1,
    266.0,327.2,328.2,345.2,415.2,426.2,432.2,531.2,559.3,623.4,639.3,643.3,644.4,
    645.0,647.5,686.4,687.4,689.4);
  my @intensities = (8.7,7.7,7.3,10.5,7.7,7.3,8.4,8.0,9.1,9.1,7.3,29.0,12.6,7.3,8.0,
    7.7,11.9,9.8,10.1,7.3,10.5,131.0,9.4,50.3,22.7,44.7,16.8,30.4,18.2,53.1,25.5,
    15.7,7.7,14.0,46.8,38.4,7.3,11.5,8.7,7.3,8.7,7.3,24.8,194.2);
  my $peptide = "RTSVAR";

  my $vs = MassSpec::ViewSpectrum::RealVsHypPeptide->new($peptide, \@masses,\@intensities);
  $vs->set(yaxismultiplier => 1.8); # a sample tweak to adjust the output
  $vs->set(title => "BSA-689 -- " . $peptide);
 
  my $output = $vs->plot();
  print GRAPHIC $output;
  close GRAPHIC;

=head1 DESCRIPTION

MassSpec::ViewSpectrum::RealVsHypPeptide - View a real mass spectrum on the same graph as a hypothetical spectrum generated by fragmenting a peptide I<in silico>.  The I<in silico> fragmention is performed by generating all of the possible peptides which contain either the amino-terminal or carboxyl-terminal amino acids.

Negative peak intensity values are permitted; this permits the drawing of "pseudospectra" which, for example, illustrate peaks present in one spectrum but missing in another.  Note that these negative peaks have no true intensities, but in some cases we assign different heights to illustrate the differences among different hypothetical peaks.  In addition, pseudocoloring of both positive and negative peaks is performed to illustrate what type of ion that peak represents.  In some cases these ions are labelled explicitly, although in practice it is best to minimize this labelling to avoid excessive clutter.

The real spectrum appears on the positive y axis with known peaks, while the negative y axis reflects:

=over 4

=item Intersection

Peaks appearing in both the experimental and hypothetical spectra.

=item H-E

Peaks appearing the the hypothetical but not experimental spectra, i.e. peaks which failed to be fragmented and/or captured in the mass spec. apparatus.

=item E-H

Peaks appearing the the experimental but not hypothetical spectra; in some cases these peaks can be used to discredit the hypothetical spectrum by pointing out important peaks that the fragmentation of the peptide fails to account for.

=back

=head2 OPTIONS

In addition to the options inherited from MassSpec::ViewSpectrum, the following options are available:

=over 4

=item HminusEpeakheight

The negative heights associated with peaks appearing in the hypothetical spectrum but not in the experimental spectrum.

=item otherPeakHeights

The heights of other negative peaks.

=item yScalingFactor

A fudge factor.

=item yScalingOffset

Another fudge factor, used to make negative labels appear without taking up too much display real estate and without being obscured.

=item tolerance

How close an experimental and hypothetical peak's m/z value (x axis value) must be to be treated as the same peak.

=back

=head1 TO DO

Greater configurability with regard to which types of ion peak labels are displayed, when/whether the associated peptides are displayed as part of the label.

=head1 AUTHORS

=over 4

=item
Jonathan Epstein, E<lt>Jonathan_Epstein@nih.govE<gt>

=item
Matthew Olson, E<lt>olsonmat@mail.nih.gov@mail.nih.govE<gt>

=item
Xiongfong Chen, E<lt>xchen@helix.nih.gov@mail.nih.govE<gt>

=back

=head1 COPYRIGHT AND LICENSE

                          PUBLIC DOMAIN NOTICE

        National Institute of Child Health and Human Development

 This software/database is a "United States Government Work" under the
 terms of the United States Copyright Act.  It was written as part of
 the author's official duties as a United States Government employee and
 thus cannot be copyrighted.  This software/database is freely available
 to the public for use. The National Institutes of Health and the U.S.
 Government have not placed any restriction on its use or reproduction.

 Although all reasonable efforts have been taken to ensure the accuracy
 and reliability of the software and data, the NIH and the U.S.
 Government do not and cannot warrant the performance or results that
 may be obtained by using this software or data. The NIH and the U.S.
 Government disclaim all warranties, express or implied, including
 warranties of performance, merchantability or fitness for any particular
 purpose.
 
Please cite the author in any work or product based on this material.
 
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
