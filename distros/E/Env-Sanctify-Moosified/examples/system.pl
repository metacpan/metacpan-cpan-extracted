use strict;
use warnings;
use Env::Sanctify::Moosified;

my $sanctify = Env::Sanctify::Moosified->consecrate( sanctify => [ '.*' ], env => { PATH => $ENV{PATH} }, );
system("$^X " . '-MData::Dumper -e \'warn Dumper(\%ENV);\'');
