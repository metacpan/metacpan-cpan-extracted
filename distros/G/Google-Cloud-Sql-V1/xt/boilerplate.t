#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 18;

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open( my $fh, '<', $filename )
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    } else {
        pass("$filename contains no boilerplate text");
    }
}

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok($module =>
        'the great new $MODULENAME'   => qr/ - The great new /,
        'boilerplate description'     => qr/Quick summary of what the module/,
        'stub function definition'    => qr/function[12]/,
    );
}

TODO: {
  local $TODO = "Need to replace the boilerplate text";

  not_in_file_ok(README =>
    "The README is used..."       => qr/The README is used/,
    "'version information here'"  => qr/to provide version information/,
  );

  not_in_file_ok(Changes =>
    "placeholder date/time"       => qr(Date/time)
  );

  module_boilerplate_ok('lib/Google/Cloud/Sql/V1/SqlAvailableDatabaseVersionsServiceClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Sql/V1/SqlBackupRunsServiceClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Sql/V1/SqlBackupsServiceClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Sql/V1/SqlConnectServiceClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Sql/V1/SqlDatabasesServiceClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Sql/V1/SqlEventsServiceClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Sql/V1/SqlFeatureEligibilityServiceClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Sql/V1/SqlFlagsServiceClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Sql/V1/SqlIamPoliciesServiceClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Sql/V1/SqlInstanceNamesServiceClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Sql/V1/SqlInstancesServiceClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Sql/V1/SqlOperationsServiceClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Sql/V1/SqlRegionsServiceClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Sql/V1/SqlSslCertsServiceClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Sql/V1/SqlTiersServiceClient.pm');
  module_boilerplate_ok('lib/Google/Cloud/Sql/V1/SqlUsersServiceClient.pm');


}

