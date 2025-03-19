use strict;
use warnings;

package TestHelper;

use File::Temp 'tempdir';
use File::Path 'mkpath';
use File::Spec::Functions 'catdir', 'catfile';

use base 'Exporter';

our @EXPORT = qw(temp_inc catfile catdir);

sub temp_inc {
    my $tmpinc = tempdir(CLEANUP => 1);
    mkpath(catdir($tmpinc, qw(DepTest Install)), 0, 0711);
    unshift @INC, $tmpinc;
    return $tmpinc;
}

1;
