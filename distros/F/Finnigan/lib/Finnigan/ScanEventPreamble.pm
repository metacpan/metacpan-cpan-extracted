package Finnigan::ScanEventPreamble;

use strict;
use warnings FATAL => qw( all );
our $VERSION = 0.0206;

use Finnigan;
use base 'Finnigan::Decoder';

use overload ('""' => 'stringify');

my %SYMBOL = (
              bool => {
                       0 => "False",
                       1 => "True"
                      },

              "on/off" => {
                           0 => "Off",
                           1 => "On",
                           2 => "undefined",
                          },

              detector => {
                           0 => "valid",
                           1 => "undefined",
                          },

              analyzer => {
                           0 => "ITMS",
                           1 => "TQMS",
                           2 => "SQMS",
                           3 => "TOFMS",
                           4 => "FTMS",
                           5 => "Sector",
                           6 => "undefined"
                          },

              polarity => {
                           0 => "negative",
                           1 => "positive",
                           2 => "undefined",
                          },

              "scan mode" => {
                              0 => "centroid",
                              1 => "profile",
                              2 => "undefined",
                             },

              "scan type" => {
                              0 => "Full",
                              1 => "Zoom",
                              2 => "SIM",
                              3 => "SRM",
                              4 => "CRM",
                              5 => "undefined",
                              6 => "Q1",
                              7 => "Q3",
                             },

              "ms power" => {
                             0 => "undefined",
                             1 => "MS1",
                             2 => "MS2",
                             3 => "MS3",
                             4 => "MS4",
                             5 => "MS5",
                             6 => "MS6",
                             7 => "MS7",
                             8 => "MS8",
                            },

              ionization => {
                             0 => "EI",
                             1 => "CI",
                             2 => "FABI",
                             3 => "ESI",
                             4 => "APCI",
                             5 => "NSI",
                             6 => "TSI",
                             7 => "FDI",
                             8 => "MALDI",
                             9 => "GDI",
                             10 => "undefined"
                            },
             );

my %TYPE = (
            "corona"            => "on/off",
            "detector"          => "detector",
            "polarity"          => "polarity",
            "scan mode"         => "scan mode",
            "ms power"          => "ms power",
            "scan type"         => "scan type",
            "dependent"         => "bool",
            "ionization"        => "ionization",
            "wideband"          => "on/off",
            "analyzer"          => "analyzer",
           );

my @common_fields = (
                     "unknown byte[0]"   => ['C',    'UInt8'],
                     "unknown byte[1]"   => ['C',    'UInt8'],
                     "corona"            => ['C',    'UInt8'],
                     "detector"          => ['C',    'UInt8'],
                     "polarity"          => ['C',    'UInt8'],
                     "scan mode"         => ['C',    'UInt8'],
                     "ms power"          => ['C',    'UInt8'],
                     "scan type"         => ['C',    'UInt8'],
                     "unknown byte[8]"   => ['C',    'UInt8'],
                     "unknown byte[9]"   => ['C',    'UInt8'],
                     "dependent"         => ['C',    'UInt8'],
                     "ionization"        => ['C',    'UInt8'],
                     "unknown byte[12]"  => ['C',    'UInt8'],
                     "unknown byte[13]"  => ['C',    'UInt8'],
                     "unknown byte[14]"  => ['C',    'UInt8'],
                     "unknown byte[15]"  => ['C',    'UInt8'],
                     "unknown byte[16]"  => ['C',    'UInt8'],
                     "unknown byte[17]"  => ['C',    'UInt8'],
                     "unknown byte[18]"  => ['C',    'UInt8'],
                     "unknown byte[19]"  => ['C',    'UInt8'],
                     "unknown byte[20]"  => ['C',    'UInt8'],
                     "unknown byte[21]"  => ['C',    'UInt8'],
                     "unknown byte[22]"  => ['C',    'UInt8'],
                     "unknown byte[23]"  => ['C',    'UInt8'],
                     "unknown byte[24]"  => ['C',    'UInt8'],
                     "unknown byte[25]"  => ['C',    'UInt8'],
                     "unknown byte[26]"  => ['C',    'UInt8'],
                     "unknown byte[27]"  => ['C',    'UInt8'],
                     "unknown byte[28]"  => ['C',    'UInt8'],
                     "unknown byte[29]"  => ['C',    'UInt8'],
                     "unknown byte[30]"  => ['C',    'UInt8'],
                     "unknown byte[31]"  => ['C',    'UInt8'],
                     "wideband"          => ['C',    'UInt8'],
                     "unknown byte[33]"  => ['C',    'UInt8'],
                     "unknown byte[34]"  => ['C',    'UInt8'],
                     "unknown byte[35]"  => ['C',    'UInt8'],
                     "unknown byte[36]"  => ['C',    'UInt8'],
                     "unknown byte[37]"  => ['C',    'UInt8'],
                     "unknown byte[38]"  => ['C',    'UInt8'],
                     "unknown byte[39]"  => ['C',    'UInt8'],
                     "analyzer"          => ['C',    'UInt8'],
                    );

my %specific_fields;
$specific_fields{8} = [];
$specific_fields{57} = [
                        "unknown byte[41]"  => ['C',    'UInt8'],
                        "unknown byte[42]"  => ['C',    'UInt8'],
                        "unknown byte[43]"  => ['C',    'UInt8'],
                        "unknown byte[44]"  => ['C',    'UInt8'],
                        "unknown byte[45]"  => ['C',    'UInt8'],
                        "unknown byte[46]"  => ['C',    'UInt8'],
                        "unknown byte[47]"  => ['C',    'UInt8'],
                        "unknown byte[48]"  => ['C',    'UInt8'],
                        "unknown byte[49]"  => ['C',    'UInt8'],
                        "unknown byte[50]"  => ['C',    'UInt8'],
                        "unknown byte[51]"  => ['C',    'UInt8'],
                        "unknown byte[52]"  => ['C',    'UInt8'],
                        "unknown byte[53]"  => ['C',    'UInt8'],
                        "unknown byte[54]"  => ['C',    'UInt8'],
                        "unknown byte[55]"  => ['C',    'UInt8'],
                        "unknown byte[56]"  => ['C',    'UInt8'],
                        "unknown byte[57]"  => ['C',    'UInt8'],
                        "unknown byte[58]"  => ['C',    'UInt8'],
                        "unknown byte[59]"  => ['C',    'UInt8'],
                        "unknown byte[60]"  => ['C',    'UInt8'],
                        "unknown byte[61]"  => ['C',    'UInt8'],
                        "unknown byte[62]"  => ['C',    'UInt8'],
                        "unknown byte[63]"  => ['C',    'UInt8'],
                        "unknown byte[64]"  => ['C',    'UInt8'],
                        "unknown byte[65]"  => ['C',    'UInt8'],
                        "unknown byte[66]"  => ['C',    'UInt8'],
                        "unknown byte[67]"  => ['C',    'UInt8'],
                        "unknown byte[68]"  => ['C',    'UInt8'],
                        "unknown byte[69]"  => ['C',    'UInt8'],
                        "unknown byte[70]"  => ['C',    'UInt8'],
                        "unknown byte[71]"  => ['C',    'UInt8'],
                        "unknown byte[72]"  => ['C',    'UInt8'],
                        "unknown byte[73]"  => ['C',    'UInt8'],
                        "unknown byte[74]"  => ['C',    'UInt8'],
                        "unknown byte[75]"  => ['C',    'UInt8'],
                        "unknown byte[76]"  => ['C',    'UInt8'],
                        "unknown byte[77]"  => ['C',    'UInt8'],
                        "unknown byte[78]"  => ['C',    'UInt8'],
                        "unknown byte[79]"  => ['C',    'UInt8'],
                       ];

$specific_fields{60} = $specific_fields{57};

$specific_fields{62} = [
                        "unknown byte[41]"  => ['C',    'UInt8'],
                        "unknown byte[42]"  => ['C',    'UInt8'],
                        "unknown byte[43]"  => ['C',    'UInt8'],
                        "unknown byte[44]"  => ['C',    'UInt8'],
                        "unknown byte[45]"  => ['C',    'UInt8'],
                        "unknown byte[46]"  => ['C',    'UInt8'],
                        "unknown byte[47]"  => ['C',    'UInt8'],
                        "unknown byte[48]"  => ['C',    'UInt8'],
                        "unknown byte[49]"  => ['C',    'UInt8'],
                        "unknown byte[50]"  => ['C',    'UInt8'],
                        "unknown byte[51]"  => ['C',    'UInt8'],
                        "unknown byte[52]"  => ['C',    'UInt8'],
                        "unknown byte[53]"  => ['C',    'UInt8'],
                        "unknown byte[54]"  => ['C',    'UInt8'],
                        "unknown byte[55]"  => ['C',    'UInt8'],
                        "unknown byte[56]"  => ['C',    'UInt8'],
                        "unknown byte[57]"  => ['C',    'UInt8'],
                        "unknown byte[58]"  => ['C',    'UInt8'],
                        "unknown byte[59]"  => ['C',    'UInt8'],
                        "unknown byte[60]"  => ['C',    'UInt8'],
                        "unknown byte[61]"  => ['C',    'UInt8'],
                        "unknown byte[62]"  => ['C',    'UInt8'],
                        "unknown byte[63]"  => ['C',    'UInt8'],
                        "unknown byte[64]"  => ['C',    'UInt8'],
                        "unknown byte[65]"  => ['C',    'UInt8'],
                        "unknown byte[66]"  => ['C',    'UInt8'],
                        "unknown byte[67]"  => ['C',    'UInt8'],
                        "unknown byte[68]"  => ['C',    'UInt8'],
                        "unknown byte[69]"  => ['C',    'UInt8'],
                        "unknown byte[70]"  => ['C',    'UInt8'],
                        "unknown byte[71]"  => ['C',    'UInt8'],
                        "unknown byte[72]"  => ['C',    'UInt8'],
                        "unknown byte[73]"  => ['C',    'UInt8'],
                        "unknown byte[74]"  => ['C',    'UInt8'],
                        "unknown byte[75]"  => ['C',    'UInt8'],
                        "unknown byte[76]"  => ['C',    'UInt8'],
                        "unknown byte[77]"  => ['C',    'UInt8'],
                        "unknown byte[78]"  => ['C',    'UInt8'],
                        "unknown byte[79]"  => ['C',    'UInt8'],

                        "unknown byte[80]"  => ['C',    'UInt8'],
                        "unknown byte[81]"  => ['C',    'UInt8'],
                        "unknown byte[82]"  => ['C',    'UInt8'],
                        "unknown byte[83]"  => ['C',    'UInt8'],
                        "unknown byte[84]"  => ['C',    'UInt8'],
                        "unknown byte[85]"  => ['C',    'UInt8'],
                        "unknown byte[86]"  => ['C',    'UInt8'],
                        "unknown byte[87]"  => ['C',    'UInt8'],
                        "unknown byte[88]"  => ['C',    'UInt8'],
                        "unknown byte[89]"  => ['C',    'UInt8'],
                        "unknown byte[90]"  => ['C',    'UInt8'],
                        "unknown byte[91]"  => ['C',    'UInt8'],
                        "unknown byte[92]"  => ['C',    'UInt8'],
                        "unknown byte[93]"  => ['C',    'UInt8'],
                        "unknown byte[94]"  => ['C',    'UInt8'],
                        "unknown byte[95]"  => ['C',    'UInt8'],
                        "unknown byte[96]"  => ['C',    'UInt8'],
                        "unknown byte[97]"  => ['C',    'UInt8'],
                        "unknown byte[98]"  => ['C',    'UInt8'],
                        "unknown byte[99]"  => ['C',    'UInt8'],
                        "unknown byte[100]" => ['C',    'UInt8'],
                        "unknown byte[101]" => ['C',    'UInt8'],
                        "unknown byte[102]" => ['C',    'UInt8'],
                        "unknown byte[103]" => ['C',    'UInt8'],
                        "unknown byte[104]" => ['C',    'UInt8'],
                        "unknown byte[105]" => ['C',    'UInt8'],
                        "unknown byte[106]" => ['C',    'UInt8'],
                        "unknown byte[107]" => ['C',    'UInt8'],
                        "unknown byte[108]" => ['C',    'UInt8'],
                        "unknown byte[109]" => ['C',    'UInt8'],
                        "unknown byte[110]" => ['C',    'UInt8'],
                        "unknown byte[111]" => ['C',    'UInt8'],
                        "unknown byte[112]" => ['C',    'UInt8'],
                        "unknown byte[113]" => ['C',    'UInt8'],
                        "unknown byte[114]" => ['C',    'UInt8'],
                        "unknown byte[115]" => ['C',    'UInt8'],
                        "unknown byte[116]" => ['C',    'UInt8'],
                        "unknown byte[117]" => ['C',    'UInt8'],
                        "unknown byte[118]" => ['C',    'UInt8'],
                        "unknown byte[119]" => ['C',    'UInt8'],
                       ];

$specific_fields{63} = [
                        "unknown byte[41]"  => ['C',    'UInt8'],
                        "unknown byte[42]"  => ['C',    'UInt8'],
                        "unknown byte[43]"  => ['C',    'UInt8'],
                        "unknown byte[44]"  => ['C',    'UInt8'],
                        "unknown byte[45]"  => ['C',    'UInt8'],
                        "unknown byte[46]"  => ['C',    'UInt8'],
                        "unknown byte[47]"  => ['C',    'UInt8'],
                        "unknown byte[48]"  => ['C',    'UInt8'],
                        "unknown byte[49]"  => ['C',    'UInt8'],
                        "unknown byte[50]"  => ['C',    'UInt8'],
                        "unknown byte[51]"  => ['C',    'UInt8'],
                        "unknown byte[52]"  => ['C',    'UInt8'],
                        "unknown byte[53]"  => ['C',    'UInt8'],
                        "unknown byte[54]"  => ['C',    'UInt8'],
                        "unknown byte[55]"  => ['C',    'UInt8'],
                        "unknown byte[56]"  => ['C',    'UInt8'],
                        "unknown byte[57]"  => ['C',    'UInt8'],
                        "unknown byte[58]"  => ['C',    'UInt8'],
                        "unknown byte[59]"  => ['C',    'UInt8'],
                        "unknown byte[60]"  => ['C',    'UInt8'],
                        "unknown byte[61]"  => ['C',    'UInt8'],
                        "unknown byte[62]"  => ['C',    'UInt8'],
                        "unknown byte[63]"  => ['C',    'UInt8'],
                        "unknown byte[64]"  => ['C',    'UInt8'],
                        "unknown byte[65]"  => ['C',    'UInt8'],
                        "unknown byte[66]"  => ['C',    'UInt8'],
                        "unknown byte[67]"  => ['C',    'UInt8'],
                        "unknown byte[68]"  => ['C',    'UInt8'],
                        "unknown byte[69]"  => ['C',    'UInt8'],
                        "unknown byte[70]"  => ['C',    'UInt8'],
                        "unknown byte[71]"  => ['C',    'UInt8'],
                        "unknown byte[72]"  => ['C',    'UInt8'],
                        "unknown byte[73]"  => ['C',    'UInt8'],
                        "unknown byte[74]"  => ['C',    'UInt8'],
                        "unknown byte[75]"  => ['C',    'UInt8'],
                        "unknown byte[76]"  => ['C',    'UInt8'],
                        "unknown byte[77]"  => ['C',    'UInt8'],
                        "unknown byte[78]"  => ['C',    'UInt8'],
                        "unknown byte[79]"  => ['C',    'UInt8'],

                        "unknown byte[80]"  => ['C',    'UInt8'],
                        "unknown byte[81]"  => ['C',    'UInt8'],
                        "unknown byte[82]"  => ['C',    'UInt8'],
                        "unknown byte[83]"  => ['C',    'UInt8'],
                        "unknown byte[84]"  => ['C',    'UInt8'],
                        "unknown byte[85]"  => ['C',    'UInt8'],
                        "unknown byte[86]"  => ['C',    'UInt8'],
                        "unknown byte[87]"  => ['C',    'UInt8'],
                        "unknown byte[88]"  => ['C',    'UInt8'],
                        "unknown byte[89]"  => ['C',    'UInt8'],
                        "unknown byte[90]"  => ['C',    'UInt8'],
                        "unknown byte[91]"  => ['C',    'UInt8'],
                        "unknown byte[92]"  => ['C',    'UInt8'],
                        "unknown byte[93]"  => ['C',    'UInt8'],
                        "unknown byte[94]"  => ['C',    'UInt8'],
                        "unknown byte[95]"  => ['C',    'UInt8'],
                        "unknown byte[96]"  => ['C',    'UInt8'],
                        "unknown byte[97]"  => ['C',    'UInt8'],
                        "unknown byte[98]"  => ['C',    'UInt8'],
                        "unknown byte[99]"  => ['C',    'UInt8'],
                        "unknown byte[100]" => ['C',    'UInt8'],
                        "unknown byte[101]" => ['C',    'UInt8'],
                        "unknown byte[102]" => ['C',    'UInt8'],
                        "unknown byte[103]" => ['C',    'UInt8'],
                        "unknown byte[104]" => ['C',    'UInt8'],
                        "unknown byte[105]" => ['C',    'UInt8'],
                        "unknown byte[106]" => ['C',    'UInt8'],
                        "unknown byte[107]" => ['C',    'UInt8'],
                        "unknown byte[108]" => ['C',    'UInt8'],
                        "unknown byte[109]" => ['C',    'UInt8'],
                        "unknown byte[110]" => ['C',    'UInt8'],
                        "unknown byte[111]" => ['C',    'UInt8'],
                        "unknown byte[112]" => ['C',    'UInt8'],
                        "unknown byte[113]" => ['C',    'UInt8'],
                        "unknown byte[114]" => ['C',    'UInt8'],
                        "unknown byte[115]" => ['C',    'UInt8'],
                        "unknown byte[116]" => ['C',    'UInt8'],
                        "unknown byte[117]" => ['C',    'UInt8'],
                        "unknown byte[118]" => ['C',    'UInt8'],
                        "unknown byte[119]" => ['C',    'UInt8'],

                        "unknown byte[120]" => ['C',    'UInt8'],
                        "unknown byte[121]" => ['C',    'UInt8'],
                        "unknown byte[122]" => ['C',    'UInt8'],
                        "unknown byte[123]" => ['C',    'UInt8'],
                        "unknown byte[124]" => ['C',    'UInt8'],
                        "unknown byte[125]" => ['C',    'UInt8'],
                        "unknown byte[126]" => ['C',    'UInt8'],
                        "unknown byte[127]" => ['C',    'UInt8'],
                       ];

$specific_fields{64} = $specific_fields{63};

# stringify symbols
my %polarity_symbol = (
                       0 => "-",
                       1 => "+",
                       2 => "any",
                      );

my %scan_mode_symbol = (
                        0 => "c",
                        1 => "p",
                        2 => "?",
                       );

my %dependent_symbol = (
                        0 => "",
                        1 => " d",
                       );

my %wideband_symbol = (
                       0 => "",
                       1 => " w",
                       2 => "",
                      );

my %ms_power_symbol = (
                       0 => "?",
                       1 => "ms",
                       2 => "ms2",
                       3 => "ms3",
                       4 => "ms4",
                       5 => "ms5",
                       6 => "ms6",
                       7 => "ms7",
                       8 => "ms8",
                      );

# used in list()
my %name = (
            2 => "corona",
            3 => "detector",
            4 => "polarity",
            5 => "scan mode",
            6 => "ms power",
            7 => "scan type",

            10 => "dependent",
            11 => "ionization",

            32 => "wideband",
            40 => "analyzer",
           );

sub decode {
  # my ($class, $stream, $version) = @_;
  die "don\'t know how to parse version $_[2]" unless $specific_fields{$_[2]};
  return bless Finnigan::Decoder->read($_[1], [@common_fields, @{$specific_fields{$_[2]}}]), $_[0];
}


sub list {
  my @list;
  foreach my $i (0 .. keys(%{$_[0]->{data}}) - 1) {
    my $key = $name{$i} ? $name{$i} : "unknown byte[$i]";
    my $value;
    if ( $_[1] ) { # decode
      $value = $TYPE{$key}
        ? $SYMBOL{$TYPE{$key}}->{$_[0]->{data}->{$key}->{value}}
          : $_[0]->{data}->{$key}->{value};
    }
    else {
      $value = $_[0]->{data}->{$key}->{value};
    }
    $list[$i] = $value;
  }
  return @list;
}

sub corona {
  my $key = "corona";
  if ( $_[1] ) { # decode
    return $TYPE{$key}
      ? $SYMBOL{$TYPE{$key}}->{$_[0]->{data}->{$key}->{value}}
        : $_[0]->{data}->{$key}->{value};
  }
  else {
    shift->{data}->{corona}->{value};
  }
}

sub detector {
  my $key = "detector";
  if ( $_[1] ) {
    return $TYPE{$key}
      ? $SYMBOL{$TYPE{$key}}->{$_[0]->{data}->{$key}->{value}}
        : $_[0]->{data}->{$key}->{value};
  }
  else {
    $_[0]->{data}->{$key}->{value};
  }
}

sub polarity {
  my $key = "polarity";
  if ( $_[1] ) { # decode
    return $TYPE{$key}
      ? $SYMBOL{$TYPE{$key}}->{$_[0]->{data}->{$key}->{value}}
        : $_[0]->{data}->{$key}->{value};
  }
  else {
    return $_[0]->{data}->{$key}->{value};
  }
}

sub scan_mode {
  my $key = "scan mode";
  if ( $_[1] ) {
    return $TYPE{$key}
      ? $SYMBOL{$TYPE{$key}}->{$_[0]->{data}->{$key}->{value}}
        : $_[0]->{data}->{$key}->{value};
  }
  else {
    $_[0]->{data}->{$key}->{value};
  }
}

sub ms_power {
  my $key = "ms power";
  if ( $_[1] ) {
    return $TYPE{$key}
      ? $SYMBOL{$TYPE{$key}}->{$_[0]->{data}->{$key}->{value}}
        : $_[0]->{data}->{$key}->{value};
  }
  else {
    $_[0]->{data}->{$key}->{value};
  }
}

sub scan_type {
  my $key = "scan type";
  if ( $_[1] ) {
    return $TYPE{$key}
      ? $SYMBOL{$TYPE{$key}}->{$_[0]->{data}->{$key}->{value}}
        : $_[0]->{data}->{$key}->{value};
  }
  else {
    $_[0]->{data}->{$key}->{value};
  }
}

sub dependent {
  $_[0]->{data}->{dependent}->{value};
}

sub ionization {
  my $key = "ionization";
  if ( $_[1] ) {
    return $TYPE{$key}
      ? $SYMBOL{$TYPE{$key}}->{$_[0]->{data}->{$key}->{value}}
        : $_[0]->{data}->{$key}->{value};
  }
  else {
    $_[0]->{data}->{$key}->{value};
  }
}

sub wideband {
  my $key = "wideband";
  if ( $_[1] ) {
    return $TYPE{$key}
      ? $SYMBOL{$TYPE{$key}}->{$_[0]->{data}->{$key}->{value}}
        : $_[0]->{data}->{$key}->{value};
  }
  else {
    $_[0]->{data}->{$key}->{value};
  }
}

sub analyzer {
  my $key = "analyzer";
  if ( $_[1] ) {
    return $TYPE{$key}
      ? $SYMBOL{$TYPE{$key}}->{$_[0]->{data}->{$key}->{value}}
        : $_[0]->{data}->{$key}->{value};
  }
  else {
    $_[0]->{data}->{$key}->{value};
  }
}

sub stringify {
  my $self = shift;

  # consider adding {s;e} and "lock" to output, e.g.:
  #   FTMS {1;1}  + p ESI Full lock ms [60.00-1200.00]" 
  $self->analyzer(decode => 1)
    . " " . $polarity_symbol{$self->polarity}
      . " " . $scan_mode_symbol{$self->scan_mode}
        . " " . $self->ionization('decode')
          . $dependent_symbol{$self->dependent}
            . $wideband_symbol{$self->wideband}
              . " " . $self->scan_type('decode')
                . " " . $ms_power_symbol{$self->ms_power}
}

1;
__END__

=head1 NAME

Finnigan::ScanEventPreamble -- a decoder for ScanEventPreamble, the byte array component of ScanEvent

=head1 SYNOPSIS

  use Finnigan;
  my $p = Finnigan::ScanEventPreamble->decode(\*INPUT, $version);
  say join(" ", $p->list);
  say join(" ", $p->list('decode');
  say p->analyzer;
  say p->analyzer('decode');

=head1 DESCRIPTION

ScanEventPreamble is a fixed-size (but version-dependent) structure. It
is a byte array located at the head of each ScanEvent. It contains
various boolean flags an enumerated types. For example, it's 41st byte
contains the analyzer type in all versions:

  %ANALYZER = (
    0 => "ITMS",
    1 => "TQMS",
    2 => "SQMS",
    3 => "TOFMS",
    4 => "FTMS",
    5 => "Sector",
    6 => "undefined"
  );

The ScanEventPreamble decoder provides a number of accessors that
interpret the enumerated and boolean values.

The meaning of some values in ScanEventPreamble remains unknown.

The structure seems to have grown historically: to the 41 bytes in
B<v.57>, 39 more were added in B<v.62>, and 8 further bytes were added in
B<v.63>. That does not affect the decoder interface; those values it
knows about have not changed, but the version number still has to be
passed into it so it knows how many bytes to read.


=head2 METHODS

=over 4

=item decode($stream, $version)

The constructor method

=back

All of the following accessor methods will replace the byte value of
the flag they access with a symbolic value representing that flag's
meaning if given a truthy argument. The word 'decode' is a good one to
use because it makes the code more readable, but any truthy value will
work.

=over 4

=item list(bool)

Returns an array containing all byte values of ScanEventPreamble

=item corona(bool)

Get the corona status (0:off or 1:on).

=item detector(bool)

Get the detector flag (0:valid or 1:undefined).

=item polarity(bool)

Get the polarity value (0:negative, 1:positive, 2:undefined)

=item scan_mode(bool)

Get the scan mode (0:centroid, 1:profile, 2:undefined)

=item ms_power(bool)

Get the MS power number (0:undefined, 1:MS1, 2:MS2, 3:MS3, 4:MS4,
5:MS5, 6:MS6, 7:MS7, 8:MS8)

=item scan_type(bool)

Get the scan type (0:Full, 1:Zoom, 2:SIM, 3:SRM, 4:CRM, 5:undefined, 6:Q1, 7:Q3)

=item dependent(bool)

Get the dependent flag (0 for primary MS1 scans, 1 for dependent scan
types)

=item ionization(bool)

Get the scan type (0:EI, 1:CI, 2:FABI, 3:ESI, 4:APCI, 5:NSI, 6:TSI,
7:FDI, 8:MALDI, 9:GDI, 10:undefined)

=item wideband(bool)

Get the wideband flag (0:off, 1:on, 2:undefined).

=item analyzer(bool)

Get the scan type (0:ITMS, 1:TQMS, 2:SQMS, 3:TOFMS, 4:FTMS, 5:Sector, 6:undefined)

=item stringify

Makes a short text representation of the set of flags (known as
"filter line" to the users of Thermo software)

=back


=head1 SEE ALSO

Finnigan::ScanEvent

L<uf-trailer>


=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
