use strict;

use Lingua::JA::Regular;
use Lingua::JA::Regular::Table::Windows;
use vars qw(%WIN_ALT_TABLE);

use Test::More tests => scalar(keys %WIN_ALT_TABLE);

    $ENV{HTTP_USER_AGENT} = "Windows";

    while (my ($key, $value) = each %WIN_ALT_TABLE) {
        my $regular = Lingua::JA::Regular->new($key)->regular;
        ok $regular eq $value, $value;
    }


