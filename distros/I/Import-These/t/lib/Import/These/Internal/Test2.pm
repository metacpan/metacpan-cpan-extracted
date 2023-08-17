package Import::These::Internal::Test2;
use strict;
use warnings;
use feature ":all";

use Exporter "import";

our @EXPORT=qw<default_sub>;

our @EXPORT_OK=qw<default_sub optional_sub>;


sub default_sub{
1;

}
sub optional_sub {
2;
}

1;
