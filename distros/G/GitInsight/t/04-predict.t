use strict;
use Test::More;
use GitInsight;

subtest 'GitInsight with no_day_stats = 0', sub {

    my $Insight = GitInsight->new( username => "dummy" );

    $Insight->decode(
        [   [ "2014-08-19", 17 ],
            [ "2014-08-20", 23 ],
            [ "2014-08-21", 9 ],
            [ "2014-08-22", 11 ],
            [ "2014-08-23", 6 ],
            [ "2014-08-24", 1 ],
            [ "2014-08-25", 2 ]
        ]
    );
    $Insight->process;

    is $Insight->{result}->[0]->[2], "2014-08-26",
        "1st day prediction day match";
    is $Insight->{result}->[1]->[2], "2014-08-27",
        "2nd day prediction day match";
    is $Insight->{result}->[2]->[2], "2014-08-28",
        "3rd day prediction day match";
    is $Insight->{result}->[3]->[2], "2014-08-29",
        "4th day prediction day match";
    is $Insight->{result}->[4]->[2], "2014-08-30",
        "5th day prediction day match";
    is $Insight->{result}->[5]->[2], "2014-08-31",
        "6th day prediction day match";
    is $Insight->{result}->[6]->[2], "2014-09-01",
        "7th day prediction day match";

    is $Insight->{result}->[0]->[1], 3, "1st day prediction match";
    is $Insight->{result}->[1]->[1], 3, "2nd day prediction match";
    is $Insight->{result}->[2]->[1], 4, "3rd day prediction match";
    is $Insight->{result}->[3]->[1], 2, "4th day prediction match";
    is $Insight->{result}->[4]->[1], 2, "5th day prediction match";
    is $Insight->{result}->[5]->[1], 1, "6th day prediction match";
    is $Insight->{result}->[6]->[1], 1, "7th day prediction match";
};

subtest 'GitInsight with no_day_stats = 1', sub {

    my $Insight = GitInsight->new( username => "dummy", no_day_stats => 1 );
    $Insight->decode(
        [   [ "2014-08-19", 17 ],
            [ "2014-08-20", 23 ],
            [ "2014-08-21", 9 ],
            [ "2014-08-22", 11 ],
            [ "2014-08-23", 6 ],
            [ "2014-08-24", 1 ],
            [ "2014-08-25", 2 ]
        ]
    );
    $Insight->process;

    is $Insight->{result}->[0]->[2], "2014-08-26",
        "1st day prediction day match";
    is $Insight->{result}->[1]->[2], "2014-08-27",
        "2nd day prediction day match";
    is $Insight->{result}->[2]->[2], "2014-08-28",
        "3rd day prediction day match";
    is $Insight->{result}->[3]->[2], "2014-08-29",
        "4th day prediction day match";
    is $Insight->{result}->[4]->[2], "2014-08-30",
        "5th day prediction day match";
    is $Insight->{result}->[5]->[2], "2014-08-31",
        "6th day prediction day match";
    is $Insight->{result}->[6]->[2], "2014-09-01",
        "7th day prediction day match";

    is $Insight->{result}->[0]->[1], 3, "1st day prediction match";
    is $Insight->{result}->[1]->[1], 3, "2nd day prediction match";
    is $Insight->{result}->[2]->[1], 3, "3rd day prediction match";
    is $Insight->{result}->[3]->[1], 3, "4th day prediction match";
    is $Insight->{result}->[4]->[1], 3, "5th day prediction match";
    is $Insight->{result}->[5]->[1], 3, "6th day prediction match";
    is $Insight->{result}->[6]->[1], 3, "7th day prediction match";
};

done_testing;
