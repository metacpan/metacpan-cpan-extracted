package  InSilicoSpectro::InSilico::PMFMatch;

# Mass spectrometry Perl module for representing PMF matches

# Copyright (C) 2005 Jacques Colinge

# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.

# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# Contact:
#  Prof. Jacques Colinge
#  Upper Austria University of Applied Science at Hagenberg
#  Hauptstrasse 117
#  A-4232 Hagenberg, Austria
#  http://www.fhs-hagenberg.ac.at

require Exporter;

our (@ISA, @EXPORT, @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT = qw($pmfMatchPeptideIndex $pmfMatchPeakIndex $pmfMatchErrorIndex $pmfMatchRelErrorIndex);
@EXPORT_OK = ();

use strict;
use Carp;
use InSilicoSpectro::InSilico::Peptide;
use InSilicoSpectro::Spectra::ExpSpectrum;

our %visibleAttr = (digestResult=>1, match=>1, expSpectrum=>1);
our $pmfMatchPeptideIndex = 0;
our $pmfMatchPeakIndex = 1;
our $pmfMatchErrorIndex = 2;
our $pmfMatchRelErrorIndex = 3;


return 1;

=head1 NAME

PMFMatch - Perl class to represent PMF matches

=head1 SYNOPSIS

use InSilicoSpectro::InSilico::PMFMatch;

=head1 DESCRIPTION

PMFMatch class is an object that simplifies the access to the data contained in the data structure
returned by function InSilicoSpectro::InSilico::MassCalculator::matchPMF.

=head1 ATTRIBUTES

=over 4

=item match

A reference to a vector such as returned by function InSilicoSpectro::InSilico::MassCalculator::matchPMF.

=item digestResult

A reference to a vector of InSilicoSpectro::InSilico::Peptide objects as returned by the digestion functions of module
InSilicoSpectro::InSilico::MassCalculator.

=item expSpectrum

A InSilicoSpectro::Spectra::ExpSpectrum object that contains the experimental spectrum.

=back

=head1 METHODS

=head2 new([%h|$PMFMatch])

Constructor. %h is a hash of attribute=>value pairs, $PMFMatch is a
InSilicoSpectro::InSilico::PMFMatch object, from which the attributes are copied.

Example:

  my $match = new InSilicoSpectro::InSilico::PMFMatch(match=>[matchPMF(expSpectrum=>$spectrum, digestResult=>\@result, sorted=>1, tol=>$tol)], expSpectrum=>$spectrum, digestResult=>\@result);

=cut
sub new
{
  my $pkg = shift;

  my $match = {};
  my $class = ref($pkg) || $pkg;
  bless($match, $class);

  if (ref($_[0]) && $_[0]->isa('InSilicoSpectro::InSilico::PMFMatch')){
    %$match = %{$_[0]};
    bless($match, $class);
  }
  else{
    bless($match, $class);
    if (!ref($_[0])){
      my %h = @_;
      foreach (keys(%h)){
	$match->$_($h{$_}) if ($visibleAttr{$_});
      }
    }
  }
  return $match;

} # new


=head2 match([$match])

Acessor/modifier of attribute match.

=cut
sub match
{
  my $this = shift;

  if (defined($_[0])){
    if (ref($_[0]) eq 'ARRAY'){
      $this->{match} = $_[0];
    }
    else{
      croak("Illegal data type for match");
    }
  }
  return $this->{match};

} # match


=head2 digestResult([$digestResult])

Acessor/modifier of attibute digestResult.

=cut
sub digestResult
{
  my ($this, $digestResult) = @_;

  if (defined($digestResult)){
    if (ref($digestResult->[0]) && (ref($digestResult->[0]) ne 'ARRAY') && $digestResult->[0]->isa('InSilicoSpectro::InSilico::Peptide')){
      $this->{digestResult} = $digestResult;
    }
    else{
      croak("Illegal digestResult data type");
    }
  }
  return $this->{digestResult};

} # digestResult


=head2 expSpectrum([$sp])

Accessor and modifier for the experimental spectrum.

=cut
sub expSpectrum
{
  my ($this, $sp) = @_;

  if (ref($sp) && $sp->isa('InSilicoSpectro::Spectra::ExpSpectrum')){
    $this->{expSpectrum} = $sp;
  }
  elsif (defined($sp)){
    croak("Illegal data type for expSpectrum");
  }
  return $this->{expSpectrum};

} # expSpectrum


=head2 getMatchedPeaks([$tol, [$minTol]])

Returns a vector of references to 4-tuples (InSilicoSpectro::InSilico::Peptide object, reference to a peak
of the experimental spectrum, absolute mass error, relative (ppm) mass error). All the 4-tuples
correspond to matched peaks, i.e. peaks for which a peptide was found in the digestion product.
The 4-tuples are sorted in ascending order of the peptide masses and the exported variables
$pmfMatchPeptideIndex, $pmfMatchPeakIndex, $pmfMatchErrorIndex, and $pmfMatchRelErrorIndex gives
the positions in the 4-tuple of each field.

If $tol is provided then mass error is checked to determine which are the matched peaks. This is
useful if the match has been obtained by searching for the closest mass initially. $minTol default
value is 0.1 Da.

Example:

  foreach ($match->getMatchedPeaks()){
    print join("\t", $_->[$pmfMatchRelErrorIndex], $_->[$pmfMatchPeptideIndex], $_->[$pmfMatchPeptideIndex]->getMass(), $_->[$pmfMatchPeakIndex][$massIndex], $_->[$pmfMatchPeptideIndex]->nmc()),"\n";
  }

=cut
sub getMatchedPeaks
{
  my ($this, $tol, $minTol) = @_;

  return undef if (!defined($this->match()) || !defined($this->digestResult()) || !defined($this->expSpectrum()));

  $minTol = $minTol || 0.1;
  my $massIndex = $this->expSpectrum()->peakDescriptor()->getFieldIndex('mass');

  my @matched;
  my @match = @{$this->match()};
  for (my $i = 0; $i < @match; $i++){
    if ($match[$i]){
      my $theoMass = $this->{digestResult}[$i]->getMass();
      my $expMass = $match[$i][$massIndex];
      my $error = $expMass-$theoMass;
      my $relError = $error/($theoMass+$expMass)*2e+6;
      if (defined($tol)){
	if ((abs($relError) <= $tol) || (abs($error) <= $minTol)){
	  push(@matched, [$this->{digestResult}[$i], $match[$i], $error, $relError]);
	}
      }
      else{
	push(@matched, [$this->{digestResult}[$i], $match[$i], $error, $relError]);
      }
    }
  }
  @matched = sort {$a->[0]->getMass() <=> $b->[0]->getMass()} @matched;
  return @matched;

} # getMatchedPeaks


=head2 getUnmatchedPeaks([$tol, [$minTol]])

Returns a vector of references to peaks of the experimental spectrum, which are the to unmatched peaks,
i.e. peaks for which no peptide was found in the digestion product. References are sorted in ascending
order of the peak masses.

If $tol is provided then mass error is checked to determine which are the matched peaks. This is
useful if the match has been obtained by searching for the closest mass initially. $minTol default
value is 0.1 Da.

Example:

  foreach ($match->getUnmatchedPeaks()){
    print "$_->[$massIndex], $_->[$intensityIndex]\n";
  }

=cut
sub getUnmatchedPeaks
{
  my ($this, $tol, $minTol) = @_;

  return undef if (!defined($this->match()) || !defined($this->digestResult()) || !defined($this->expSpectrum()));

  $minTol = $minTol || 0.1;
  my $massIndex = $this->expSpectrum()->peakDescriptor()->getFieldIndex('mass');

  my @match = @{$this->match()};
  my %matchedMass;
  my @match = @{$this->match()};
  for (my $i = 0; $i < @match; $i++){
    if ($match[$i]){
      if (defined($tol)){
	my $theoMass = $this->{digestResult}[$i]->getMass();
	my $expMass = $match[$i][$massIndex];
	if ((abs($theoMass-$expMass)/($theoMass+$expMass)*2e+6 <= $tol) || (abs($theoMass-$expMass) <= $minTol)){
	  $matchedMass{$match[$i][$massIndex]} = 1;
	}
      }
      else{
	$matchedMass{$match[$i][$massIndex]} = 1;
      }
    }
  }
  my @spectrum = @{$this->expSpectrum()->spectrum()};
  my @unmatched;
  foreach (@spectrum){
    if (!$matchedMass{$_->[$massIndex]}){
      push(@unmatched, $_);
    }
  }
  @unmatched = sort {$a->[$massIndex] <=> $b->[$massIndex]} @unmatched;
  return @unmatched;

} # getUnmatchedPeaks


=head2 getUnmatchedPeptides([$tol, [$minTol]])

Returns a vector of Peptide objects corresponding to unmatched peptides, i.e. peptides whose masses do
not match experimental peaks. Peptides are returned in ascending order of their mass.

If $tol is provided then mass error is checked to determine which are the matched peaks. This is
useful if the match has been obtained by searching for the closest mass initially. $minTol default
value is 0.1 Da.

Example:

  foreach ($match->getUnmatchedPeptides()){
    print join("\t", $_, $_->getMass(), $_->start(), $_->end(), $_->nmc()),"\n";
  }

=cut
sub getUnmatchedPeptides
{
  my ($this, $tol, $minTol) = @_;

  return undef if (!defined($this->match()) || !defined($this->digestResult()) || !defined($this->expSpectrum()));

  $minTol = $minTol || 0.1;
  my $massIndex = $this->expSpectrum()->peakDescriptor()->getFieldIndex('mass');

  my @unmatched;
  my @match = @{$this->match()};
  for (my $i = 0; $i < @match; $i++){
    if (!$match[$i]){
      push(@unmatched, $this->{digestResult}[$i]);
    }
    elsif (defined($tol)){
      my $theoMass = $this->{digestResult}[$i]->getMass();
      my $expMass = $match[$i][$massIndex];
      if ((abs($theoMass-$expMass)/($theoMass+$expMass)*2e+6 > $tol) && (abs($theoMass-$expMass) > $minTol)){
	push(@unmatched, $this->{digestResult}[$i]);
      }
    }
  }
  @unmatched = sort {$a->getMass() <=> $b->getMass()} @unmatched;
  return @unmatched;

} # getUnmatchedPeptides



=head1 EXAMPLES

See t/InSilico/testCaclcPMFMatchOOP.pl.

=head1 AUTHORS

Jacques Colinge, Upper Austria University of Applied Science at Hagenberg

=cut
