package Flexconf::Yaml;

use YAML::XS;

sub parse {
  return Load shift;
}

sub stringify {
  return Dump shift;
}

sub load {
   my ( $filepath ) = @_;
   local $/;
   open FH, "<", $filepath or return undef;
   my $conf = <FH>;
   $conf = Load $conf;
   close FH;
   $conf;
}

sub save {
   my ( $filepath, $conf ) = @_;
   open FH, ">", $filepath or die("Could not open file. $!");
   print FH Dump $conf;
   close FH;
}

1;
