use Test::More tests => 1;
use strict;
use warnings;

use Markdown::ODF;

# The following tests don't actually check the output of an ODF, but check that
# it can be produced.

my $convert = Markdown::ODF->new;
my $odf     = $convert->odf;

# Add content
$convert->add_markdown("My markdown with some **bold text**");

# Write to file and check that it exists with some content
my $fh = File::Temp->new(UNLINK => 0);
$odf->save(target => "$fh");
$fh->close;

ok(-s "$fh", "ODF file produced");
