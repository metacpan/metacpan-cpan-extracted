use strict;

use Lingua::JA::Regular;
use Lingua::JA::Regular::Table::Macintosh;
use vars qw(%MAC_ALT_TABLE);

use Test::More tests => scalar(keys %MAC_ALT_TABLE);

    $ENV{HTTP_USER_AGENT} = "Mac";

    while (my ($key, $value) = each %MAC_ALT_TABLE) {
        my $regular = Lingua::JA::Regular->new($key)->regular;
        ok $regular eq $value, $value;
    }


