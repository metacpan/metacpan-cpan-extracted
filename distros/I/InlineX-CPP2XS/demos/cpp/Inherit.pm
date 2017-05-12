package Math::Geometry::Planar::GPC::Inherit;
use strict;

require Exporter;
*import = \&Exporter::import;
require DynaLoader;

$Math::Geometry::Planar::GPC::Inherit::VERSION = '0.11';

DynaLoader::bootstrap Math::Geometry::Planar::GPC::Inherit $Math::Geometry::Planar::GPC::Inherit::VERSION;

@Math::Geometry::Planar::GPC::Inherit::EXPORT = ();
@Math::Geometry::Planar::GPC::Inherit::EXPORT_OK = ();

sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking

1;
