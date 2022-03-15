
package Math::MPC::Constant;
use strict;
use warnings;

require Exporter;
*import = \&Exporter::import;
require DynaLoader;

our $VERSION = '1.15';
#$VERSION = eval $VERSION;
Math::MPC::Constant->DynaLoader::bootstrap($VERSION);

@Math::MPC::Constant::EXPORT = ();
@Math::MPC::Constant::EXPORT_OK = ();

sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking

1;
