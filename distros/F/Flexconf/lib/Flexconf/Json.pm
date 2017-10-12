package Flexconf::Json;

use JSON::MaybeXS;

sub parse {
  return decode_json shift;
}

sub stringify {
  return encode_json shift;
}

sub load {
   my ( $filepath ) = @_;
   local $/;
   open FH, "<", $filepath or return undef;
   my $conf = <FH>;
   $conf = decode_json $conf;
   close FH;
   $conf;
}

sub save {
   my ( $filepath, $conf ) = @_;
   open FH, ">", $filepath or die("Could not open file. $!");
   print FH encode_json $conf;
   close FH;
}

1;

