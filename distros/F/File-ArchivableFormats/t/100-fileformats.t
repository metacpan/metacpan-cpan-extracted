use warnings;
use strict;

use Test::More;
use Test::Deep;

use File::ArchivableFormats;

my $af = File::ArchivableFormats->new();
isa_ok($af, "File::ArchivableFormats");

my $filename = "foo.bar";

my $ext = $af->parse_extension($filename);
is($ext, ".bar", "Parsed extension");

my @installed_drivers = $af->installed_drivers;
is(@installed_drivers, 1, "We only support DANS for the moment");
is($installed_drivers[0]->name, "DANS", "We think we can DANS");

done_testing;
