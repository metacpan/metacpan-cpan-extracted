#!perl -T

use strict;
use warnings;
use Test::More tests => 29;

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open my $fh, "<", $filename
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    } else {
        pass("$filename contains no boilerplate text");
    }
}

not_in_file_ok(README =>
    "The README is used..."       => qr/The README is used/,
    "'version information here'"  => qr/to provide version information/,
);

not_in_file_ok(Changes =>
    "placeholder date/time"       => qr(Date/time)
);

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok($module =>
        'the great new $MODULENAME'   => qr/ - The great new /,
        'boilerplate description'     => qr/Quick summary of what the module/,
        'stub function definition'    => qr/function[12]/,
    );
}

module_boilerplate_ok('lib/Graph/Maker.pm');
module_boilerplate_ok('lib/Graph/Maker/BalancedTree.pm');
module_boilerplate_ok('lib/Graph/Maker/Barbell.pm');
module_boilerplate_ok('lib/Graph/Maker/Bipartite.pm');
module_boilerplate_ok('lib/Graph/Maker/CircularLadder.pm');
module_boilerplate_ok('lib/Graph/Maker/Complete.pm');
module_boilerplate_ok('lib/Graph/Maker/CompleteBipartite.pm');
module_boilerplate_ok('lib/Graph/Maker/Cycle.pm');
module_boilerplate_ok('lib/Graph/Maker/Degree.pm');
module_boilerplate_ok('lib/Graph/Maker/Disconnected.pm');
module_boilerplate_ok('lib/Graph/Maker/Disk.pm');
module_boilerplate_ok('lib/Graph/Maker/Empty.pm');
module_boilerplate_ok('lib/Graph/Maker/Grid.pm');
module_boilerplate_ok('lib/Graph/Maker/Hypercube.pm');
module_boilerplate_ok('lib/Graph/Maker/Ladder.pm');
module_boilerplate_ok('lib/Graph/Maker/Linear.pm');
module_boilerplate_ok('lib/Graph/Maker/Lollipop.pm');
module_boilerplate_ok('lib/Graph/Maker/Random.pm');
module_boilerplate_ok('lib/Graph/Maker/Regular.pm');
module_boilerplate_ok('lib/Graph/Maker/SmallWorldBA.pm');
module_boilerplate_ok('lib/Graph/Maker/SmallWorldHK.pm');
module_boilerplate_ok('lib/Graph/Maker/SmallWorldK.pm');
module_boilerplate_ok('lib/Graph/Maker/SmallWorldWS.pm');
module_boilerplate_ok('lib/Graph/Maker/Star.pm');
module_boilerplate_ok('lib/Graph/Maker/Uniform.pm');
module_boilerplate_ok('lib/Graph/Maker/Utils.pm');
module_boilerplate_ok('lib/Graph/Maker/Wheel.pm');
