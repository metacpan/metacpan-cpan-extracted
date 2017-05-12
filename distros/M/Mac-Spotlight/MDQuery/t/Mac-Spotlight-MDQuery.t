use strict;
use warnings;
use Test::More 'no_plan';

use Mac::Spotlight::MDQuery ':constants';
use Mac::Spotlight::MDItem ':constants';

for (1..3) {
    my $query = Mac::Spotlight::MDQuery->new(q/((_kMDItemGroupId = 8) && (true)) && ((kMDItemDisplayName = "text*"cdw))/);
    ok defined $query;
    $query->setScope(kMDQueryScopeComputer);
    $query->execute;
    $query->stop;
    my @results = $query->getResults;
    ok @results > 0;
    like $results[0]->get(kMDItemPath), qr/text/i;
}
