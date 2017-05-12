package Games::SGF::Go::Rotator::Test;

use strict;
use warnings;
use vars qw(@EXPORT @EXPORT_OK);

use Exporter qw(import);

@EXPORT = @EXPORT_OK = qw(normalize);

sub normalize {
    my $sgf = shift;
    my @clauses = split(/;/, $sgf);
    foreach (@clauses) {
        my @words = split(/\s+/, $_);
        $_ = join("\n", sort(@words));
    }
    join(';', @clauses);
}

1;
