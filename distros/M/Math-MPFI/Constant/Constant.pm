
package Math::MPFI::Constant;
use strict;
use warnings;

require Exporter;
*import = \&Exporter::import;
require DynaLoader;

our $VERSION = '0.11';
#$VERSION = eval $VERSION;
Math::MPFI::Constant->DynaLoader::bootstrap($VERSION);

@Math::MPFI::Constant::EXPORT = ();
@Math::MPFI::Constant::EXPORT_OK = ();

sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking

1;
