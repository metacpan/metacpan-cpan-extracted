#!perl -w
use warnings;
use strict;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::RealBin/lib";

use File::Find;
use Test::More tests => 2;

=head1 PURPOSE

This test ensures that the Changes file mentions the current version and that
a release date is mentioned as well.

=cut

#require './Makefile.PL';
## Loaded from Makefile.PL
#our %module = get_module_info();
my $module = 'Google::RestApi';

(my $file = $module) =~ s!::!/!g;
require "$file.pm";

my $version = $module->VERSION;
my $changes = do { local $/; open my $fh, 'Changes' or die $!; <$fh> };

ok $changes      =~ /^(.*$version.*)$/m, "We found version $version for $module";
my $changes_line = $1;
ok $changes_line =~ /$version \s \d{4} - \d{2} - \d{2}/x, "We found a release date on the same line"
    or diag $changes_line;
