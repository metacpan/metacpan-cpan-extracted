use strict;
use warnings;

package JustOneFact;
our @ISA = ('Metabase::Report');
sub report_spec { return { 'Metabase::Fact' => 1 } }

package OneOrMoreFacts;
our @ISA = ('Metabase::Report');
sub report_spec { return { 'Metabase::Fact' => '1+' } }

package OneOfEach;
our @ISA = ('Metabase::Report');

sub report_spec {
    return {
        'FactOne' => '1',
        'FactTwo' => '1',
    };
}

package OneSpecificAtLeastThreeTotal;
our @ISA = ('Metabase::Report');

sub report_spec {
    return {
        'FactOne'        => '1',
        'Metabase::Fact' => '3',
    };
}

1;
