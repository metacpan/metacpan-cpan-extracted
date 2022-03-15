
package Math::Float128::Constant;
use strict;
use warnings;

require Exporter;
*import = \&Exporter::import;
require DynaLoader;

our $VERSION = '0.15';
#$VERSION = eval $VERSION;
Math::Float128::Constant->DynaLoader::bootstrap($VERSION);

@Math::Float128::Constant::EXPORT = ();
@Math::Float128::Constant::EXPORT_OK = ();

sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking

1;
