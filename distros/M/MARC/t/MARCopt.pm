package MARCopt;
# Inheritance test for test3.t only

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = '1.04';
require Exporter;
use MARC;
@ISA = qw( Exporter MARC );
@EXPORT= qw();
@EXPORT_OK= @MARC::EXPORT_OK;
%EXPORT_TAGS = %MARC::EXPORT_TAGS;

print "MARCopt inherits from MARC\n";
1;
