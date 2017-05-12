package TestMod;
use warnings;
use strict;
use Exporter::Attributes qw(import);

use MyExport qw/@bar askme/;

sub test1 : Exported { return @bar; }

sub test2 : Exported { return askme(); }

1;
