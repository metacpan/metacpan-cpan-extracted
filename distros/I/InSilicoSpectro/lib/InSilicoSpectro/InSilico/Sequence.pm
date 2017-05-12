package InSilicoSpectro::InSilico::Sequence;

# Perl object class for biological sequences

#Copyright (C) 2005 Alexandre Masselot and Jacques Colinge

#This library is free software; you can redistribute it and/or
#modify it under the terms of the GNU Lesser General Public
#License as published by the Free Software Foundation; either
#version 2.1 of the License, or (at your option) any later version.

#This library is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#Lesser General Public License for more details.

#You should have received a copy of the GNU Lesser General Public
#License along with this library; if not, write to the Free Software
#Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use strict;
require Exporter;
use Carp;
use InSilicoSpectro::Utils::io;


our (@ISA, @EXPORT, @EXPORT_OK, $isBioPerl);
@ISA = qw(Exporter);

@EXPORT = qw();
@EXPORT_OK = ();

# Checks for Bio::Perl availability.
eval{
  require Bio::Perl;
  $isBioPerl = 1;
};
if ($@){
  warn("[WARNING] Bio::Perl is not installed") if ($InSilicoSpectro::Utils::io::VERBOSE);
}

# Visible attributes controled vocabulary
our %visibleAttr = (sequence=>1, AC=>1, ID=>1, description=>1);

return 1;

=head1 NAME

InSilicoSpectro::InSilico::Sequence - Elementary sequence object

=head1 SYNOPSIS

use InSilicoSpectro::InSilico::Sequence;

=head1 DESCRIPTION

Elementary biological sequence object with AC, ID, description, sequence etc.
Aimed to be derived into AASequence or DNASequence, and not used as-is

=head1 ATTRIBUTES

=over 4

=item sequence

=item AC

=item ID

=item description

=back

=head1 METHODS

=head2 new([%h|$bpSeq|$Sequence])

Constructor. %h is a hash of attribute=>value pairs, $bpSeq is a
BioPerl Bio::seq object, from which the attributes are copied, and
$Sequence is InSilicoSpectro::InSilico::Sequence object.

=cut
sub new
{
  my $pkg = shift;

  my $class = ref($pkg) || $pkg;
  my $seq = {};

  if (ref($_[0]) && $_[0]->isa('Bio::Seq')){
    if (!$isBioPerl){
      croak("Bio::Perl is not installed");
    }
    bless($seq, $class);
    my $bps = $_[0];
    $seq->sequence($bps->seq);
    $seq->AC($bps->accession_number);
    $seq->ID($bps->display_id);
    $seq->description($bps->description);
  }
  elsif (ref($_[0]) && $_[0]->isa('InSilicoSpectro::InSilico::Sequence')){
    %$seq = %{$_[0]};
    bless($seq, $class);
  }
  else{
    bless($seq, $class);
    my %h = @_;
    foreach (keys(%h)){
      $seq->$_($h{$_}) if ($visibleAttr{$_});
    }
  }
  return $seq;

} # new


=head2 AC([$val])

AC accessor/modifier: sets AC attribute if $val is given, returns the AC attribute.

=cut
sub AC
{
  my ($this, $val) =@_;
  if ($val){
    $this->{AC} = $val;
  }
  return $this->{AC};

} # AC


=head2 ID([$val])

ID accessor/modifier: sets ID attribute if $val is given, returns the ID attribute.

=cut
sub ID
{
  my ($this, $val) = @_;
  if ($val){
    $this->{ID} = $val;
  }
  return $this->{ID};

} # ID


=head2 description([$val])

description accessor/modifier: sets description attribute if $val is given, returns
the description attribute.

=cut
sub description
{
  my ($this, $val) = @_;
  if (defined($val)){
    $this->{description} = $val;
  }
  return $this->{description};
} # description


=head2 sequence([$val])

sequence accessor/modifier: sets sequence attribute if $val is given, returns the sequence attribute.

=cut
sub sequence
{
  my ($this, $val) = @_;
  if (defined($val)){
    $val =~ s/\s//g;
    $this->{sequence} = $val;
  }
  return $this->{sequence};

} # sequence


=head2 getLength

Returns the sequence length.

=cut
sub getLength
{
  my $this = shift;
  return length($this->{sequence});

} # getLength


=head2 toFasta

Returns a string of the protein sequence in fasta format.

=head2 printFasta

Prints the sequence in fasta format.

=head2 "" operator

Overloded by calling printFasta to make the object printable.

=cut
use SelectSaver;
use overload '""' => \&toFasta;
sub toFasta
{
  my ($this, $out) = @_;

  my $string = ">".$this->AC;
  $string .= " \\ID=".$this->ID if ($this->ID);
  $string .= " \\DE=".$this->description if ($this->description);
  return $string."\n".$this->sequence."\n";

} # toFasta


sub printFasta
{
  my ($this, $out) = @_;

  my $fdOut = defined($out) ? (new SelectSaver(InSilicoSpectro::Utils::io->getFD($out) || croak("cannot open [$out]: $!"))) : \*STDOUT;
  print $fdOut $this->toFasta();

} # printFasta

=head1 EXAMPLES

See t/InSilico/testSequence.pl.

=head1 AUTHORS

Alexandre Masselot, www.genebio.com

Jacques Colinge, Upper Austria University of Applied Science at Hagenberg

=cut

return 1;
