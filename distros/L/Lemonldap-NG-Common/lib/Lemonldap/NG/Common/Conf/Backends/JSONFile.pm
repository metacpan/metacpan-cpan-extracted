# Now, File.pm is a mix of the old File.pm and JSONFile.pm. So this file is
# just set for compatibility
package Lemonldap::NG::Common::Conf::Backends::JSONFile;

use Lemonldap::NG::Common::Conf::Backends::File;

our @ISA     = qw(Lemonldap::NG::Common::Conf::Backends::File);
our $VERSION = '2.0.0';

1;

