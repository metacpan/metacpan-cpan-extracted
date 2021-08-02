package Helper;

use strict;
use warnings;
use Cwd;
use File::Basename;

our @ISA = 'Exporter';
our @EXPORT_OK = qw(test_dir);

sub test_dir {
    my $base = Cwd::realpath(dirname(__FILE__) . '/..');
    return $base unless @_ > 0;
    return $base . '/' . $_[0];
}

1;
