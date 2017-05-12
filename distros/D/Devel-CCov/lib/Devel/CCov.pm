use strict;
package Devel::CCov;

use vars qw($VERSION @ISA @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw(extract_balanced cc_strstr cc_exprstr $VERSION);
$VERSION = '0.20';

bootstrap Devel::CCov $VERSION;

1;
__END__
