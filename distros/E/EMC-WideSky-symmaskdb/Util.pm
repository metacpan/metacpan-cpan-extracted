package EMC::WideSky::Util;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(dec2hex hex2dec);    # Symbols to be exported by default
our @EXPORT_OK = qw();  # Symbols to be exported on request
our $VERSION   = 0.1;

sub dec2hex {
  my $dec=shift @_;

  my $out=join("",reverse unpack(H2H2, chr($dec % 256).chr(int($dec/256)) ));  
  $out=~ tr[a-z][A-Z];
  return $out;
}

sub hex2dec {
  my $hex=shift @_;

  my @dec=unpack(C4C4, pack(H2H2,substr($hex,0,2),substr($hex,2,2)));
  return($dec[0]*256+$dec[1]);
}

