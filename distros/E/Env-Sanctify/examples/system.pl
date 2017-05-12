use strict;
use warnings;
use Env::Sanctify;

my $sanctified = { PATH => $ENV{PATH} };

{ 
  my $sanctify = Env::Sanctify->sanctify( env => $sanctified, sanctify => [ '.*' ] );

  system("$^X " . '-MData::Dumper -e \'warn Dumper(\%ENV);\'');
}
