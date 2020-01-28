package DiaColloDB::XS;

use Exporter;
use Carp;
use AutoLoader;
use Config qw();
use strict;
use bytes;

our @ISA = qw(Exporter);
our $VERSION = "0.12.012_03";

require XSLoader;
XSLoader::load('DiaColloDB::XS', $VERSION);

# Preloaded methods go here.
#require DiaColloDB::XS::Whatever;
require DiaColloDB::XS::CofUtils;

# Autoload methods go after =cut, and are processed by the autosplit program.

##======================================================================
## Exports
##======================================================================

our (%EXPORT_TAGS, @EXPORT_OK, @EXPORT);
BEGIN {
  %EXPORT_TAGS =
    (
    );
  $EXPORT_TAGS{all}     = [];
  $EXPORT_TAGS{default} = [];
  @EXPORT_OK            = @{$EXPORT_TAGS{all}};
  @EXPORT               = @{$EXPORT_TAGS{default}};
}


##======================================================================
## END

1; ##-- be happy

__END__
