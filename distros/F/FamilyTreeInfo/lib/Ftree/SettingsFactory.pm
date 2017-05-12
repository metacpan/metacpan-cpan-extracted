use strict;
use warnings;
use lib "../config";

package Ftree::SettingsFactory;
use version; our $VERSION = qv('2.3.41');

sub importSettings{
  my ( $type, $config_name ) = @_;
  if($type eq "perl") {
    require Ftree::PerlSettingsImporter;
    return Ftree::PerlSettingsImporter::importSettings($config_name);
  }
}

1;
