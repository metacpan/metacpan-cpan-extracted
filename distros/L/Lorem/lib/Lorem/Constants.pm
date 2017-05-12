package Lorem::Constants;
{
  $Lorem::Constants::VERSION = '0.22';
}
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(%LoremStyleBorderWidth);

use Readonly;
Readonly::Hash our %LoremStyleBorderWidth => ( qw/thin 1 medium 2 thick 3/ );

1;
