package Versions;
use strict;
use warnings;

use Module::CoreList;
use List::Util 'first';

my @all_perl_releases = reverse sort keys %Module::CoreList::released;
my $latest_stable_perl = first { /^5\.(\d{3})/; defined $1 and $1 % 2 == 0 } @all_perl_releases;
my $latest_dev_perl = first { /^5\.(\d{3})/; defined $1 and $1 % 2 == 1 } @all_perl_releases;

my @gmtime = gmtime;
sub year { $gmtime[5] + 1900 }
sub month { $gmtime[4] + 1 }
sub day { $gmtime[3] }

sub latest_stable_perl { $latest_stable_perl }
sub latest_dev_perl { $latest_dev_perl }

# year, month, day
sub date_of_mcl_release
{
    return Module::CoreList->VERSION =~ /^5\.(\d{4})(\d{2})(\d{2})/;
}

1;
