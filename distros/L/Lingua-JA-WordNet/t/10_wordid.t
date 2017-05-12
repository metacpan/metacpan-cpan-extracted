use strict;
use warnings;
use Lingua::JA::WordNet;
use Test::More;
use Test::Warn;

my $wn = Lingua::JA::WordNet->new(
    verbose => 1,
);

subtest 'Japanese data' => sub {
    is($wn->WordID('高度', 'n'), '233447');
    is($wn->WordID('高度', 'a'), '233448');
    is($wn->WordID('高度', 'r'), '233449');
    is($wn->WordID('高度', 'n', 'jpn'), '233447');
    is($wn->WordID('高度', 'a', 'jpn'), '233448');
    is($wn->WordID('高度', 'r', 'jpn'), '233449');
};

subtest 'English data' => sub {
    is($wn->WordID('on the job', 'a', 'eng'), '125076');
    is($wn->WordID('on_the_job', 'a', 'eng'), '125076');

    my $wordID = '1';

    warning_is { $wordID = $wn->WordID('on the job', 'n', 'eng'); }
        "WordID: there is no WordID for 'on_the_job' corresponding to 'n' and 'eng'";

    is($wordID, undef);

    is($wn->WordID('cd', 'a', 'eng'), '126013');
    is($wn->WordID('cd', 'n', 'eng'), '5266');
};

done_testing;
