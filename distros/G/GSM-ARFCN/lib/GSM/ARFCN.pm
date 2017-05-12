package GSM::ARFCN;
use strict;
our $VERSION ='0.04';

=head1 NAME

GSM::ARFCN - Absolute Radio Frequency Channel Number (ARFCN) Converter

=head1 SYNOPSIS

  use GSM::ARFCN;
  my $ga=GSM::ARFCN->new(24);
  my $frequency=$ga->fdl;

=head1 DESCRIPTION

The Absolute Radio Frequency Channel Number (ARFCN) is a unique number given to each radio channel in GSM Radio Communication Band plan. The ARFCN can be used to calculate the frequency of the radio channel.

The ARFCNs used in GSM-1900 band (US PCS-1900) overlap with the ARFCNs used in GSM-1800 band (DCS-1800). In the GSM-1900 band plan, the ARFCNs 512 to 810 are different frequencies than the same channel numbers in the GMS-1800 band plan.  A multiband mobile phone will interpret ARFCN numbers 512 to 810 as either GSM-1800 or GSM-1900 frequencies based on a band plan indicator.

For this package to interpret ARFCN numbers 512 to 810 as either GSM-1800 or GSM-1900 frequencies, set the additional parameter band plan indicator (i.e. "bpi") to either "GSM-1800" or "GSM-1900" (DEFAULT) to make the correct interpretation. 

=head1 USAGE

  use GSM::ARFCN;
  my $frequency=GSM::ARFCN->new(24)->fdl; #MHz

Looping without blessing a new object each time

  use GSM::ARFCN;
  my $ga=GSM::ARFCN->new;
  foreach my $channel (0 .. 1023) {
    $ga->channel($channel);  #sets channel and recalculates the object properties
    printf "Channel: %s;\tBand: %s\tUplink: %s MHz,\tDownlink: %s MHz\n", $ga->channel, $ga->band, $ga->ful, $ga->fdl
      if $ga->band;
  }

=head1 CONSTRUCTOR

=head2 new

  my $obj=GSM::ARFCN->new;                                  #blesses empty object; no channel set
  my $obj=GSM::ARFCN->new(24);                              #default bpi=>"GSM-1900"
  my $obj=GSM::ARFCN->new(channel=>24);                     #default bpi=>"GSM-1900"
  my $obj=GSM::ARFCN->new(channel=>24, bpi=>"GSM-1800");    #specify band plan indicator

=cut

sub new {
  my $this = shift();
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

sub initialize {
  my $self=shift;
  if (scalar(@_) == 1) {
    %$self=(channel=>shift);
  } else {
    %$self=@_;
  }
  $self->bpi("GSM-1900") unless $self->bpi;
  $self->calculate if defined $self->channel;
}

sub calculate {
  my $self=shift;
  my $n=$self->channel;
  my $cs=$self->{'cs'}=0.2;
  if ($n ==0) {
    $self->{"band"}="EGSM-900";
    $self->{"fs"}=45;
    $self->{"ful"}=890 + $cs * $n;

  } elsif ($n >= 1   and $n <= 124) {
    $self->{"band"}="GSM-900";
    $self->{"fs"}=45;
    $self->{"ful"}=890 + $cs * $n;

  } elsif ($n >= 128 and $n <= 251) {
    $self->{"band"}="GSM-850";
    $self->{"fs"}=45;
    $self->{"ful"}=824.2 + $cs * ($n - 128);

  } elsif ($n >= 259 and $n <= 293) {
    $self->{"band"}="GSM-450";
    $self->{"fs"}=10;
    $self->{"ful"}=450.6 + $cs * ($n - 259);

  } elsif ($n >= 306 and $n <= 340) {
    $self->{"band"}="GSM-480";
    $self->{"fs"}=10;
    $self->{"ful"}=479 + $cs * ($n - 306);

  } elsif ($n >= 350 and $n <= 425) {
    $self->{"band"}="TGSM-810";
    $self->{"fs"}=10;
    $self->{"ful"}=806 + $cs * ($n - 350);

  } elsif ($n >= 438 and $n <= 511) {
    $self->{"band"}="GSM-750";
    $self->{"fs"}=30;
    $self->{"ful"}=747.2 + $cs * ($n - 438);

  } elsif ($n >= 512 and $n <= 810) {
    if ($self->bpi eq "GSM-1800") {
      $self->{"band"}="GSM-1800";
      $self->{"fs"}=95;
      $self->{"ful"}=1710.2 + $cs * ($n - 512);
    } else {
      $self->{"band"}="GSM-1900";
      $self->{"fs"}=80;
      $self->{"ful"}=1850.2 + $cs * ($n - 512);
    }

  } elsif ($n >= 811 and $n <= 885) {
    $self->{"band"}="GSM-1800";
    $self->{"fs"}=95;
    $self->{"ful"}=1710.2 + $cs * ($n - 512);

  } elsif ($n >= 955 and $n <= 974) {
    $self->{"band"}="RGSM-900";
    $self->{"fs"}=45;
    $self->{"ful"}=890 + $cs * ($n - 1024);

  } elsif ($n >= 975 and $n <= 1023) {
    $self->{"band"}="EGSM-900";
    $self->{"fs"}=45;
    $self->{"ful"}=890 + $cs * ($n - 1024);

  } else {
    $self->{"band"}="";
    delete $self->{'cs'};
  }
  $self->{"fdl"}=$self->ful + $self->fs if $self->band;
}

=head1 METHODS

=head2 channel

Sets or returns the channel.  Recalculates properties when updated.

=cut

sub channel {
  my $self=shift;
  if (@_) {
    $self->{"channel"}=shift;
    $self->calculate if defined $self->{"channel"};
  }
  return $self->{"channel"};
}

=head2 bpi

Set and returns the band plan indicator.  Recalculates properties when set.

  my $bpi=$ga->bpi("GSM-1900"); #default
  my $bpi=$ga->bpi("GSM-1800");

=cut

sub bpi {
  my $self=shift;
  if (@_) {
    $self->{"bpi"}=shift;
    $self->calculate if defined $self->channel;
  }
  return $self->{"bpi"};
}

=head1 PROPERTIES

=head2 band

Returns the GSM band for the current channel.  If the current channel is unknown by this package, this property will be false but defined.

  print $ga->band;
  if ($ga->band) {
    #Channel is valid
  } else {
    #Channel is not valid
  }

=cut

sub band {
  my $self=shift;
  return $self->{"band"};
}

=head2 ful (Frequency Uplink)

Returns the channel uplink frequency in MHz.

  my $frequency=$ga->ful;

=cut

sub ful {
  my $self=shift;
  return $self->{"ful"};
}

=head2 fdl (Frequency Downlink)

Returns the channel downlink frequency in MHz.

=cut

sub fdl {
  my $self=shift;
  return $self->{"fdl"};
}

=head2 fs (Frequency Separation)

Returns the frequency separation between the uplink and downlink frequencies in MHz.

=cut

sub fs {
  my $self=shift;
  return $self->{"fs"};
}

=head2 cs (Channel Spacing)

Returns the channel spacing in MHz.  Currently, this is always 0.2 MHz.  The actual bandwidth of the signal is 270.833 KHz.

=cut

sub cs {
  my $self=shift;
  return $self->{"cs"};
}

=head1 BUGS

Submit to RT and email author.

=head1 SUPPORT

Try the author.

=head1 AUTHOR

    Michael R. Davis
    CPAN ID: MRDVT
    STOP, LLC
    domain=>michaelrdavis,tld=>com,account=>perl
    http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<http://www.telecomabc.com/a/arfcn.html>, L<http://wireless.agilent.com/rfcomms/refdocs/gsmgprs/gen_bse_cell_band.php>

=cut

1;
