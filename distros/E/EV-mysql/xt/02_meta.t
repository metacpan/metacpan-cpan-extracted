use strict;
use warnings;
use Test::More;

eval "use Test::CPAN::Changes; 1"
    or plan skip_all => 'Test::CPAN::Changes required';
eval "use Test::MinimumVersion 0.101080; 1"
    or plan skip_all => 'Test::MinimumVersion required';

subtest 'Changes format' => sub {
    changes_ok();
};

subtest 'Minimum Perl version' => sub {
    if (-f 'META.yml' && eval "use Test::CPAN::Meta; 1") {
        meta_yaml_ok();
        all_minimum_version_from_metayml_ok();
    } else {
        all_minimum_version_ok('5.012000');
    }
};

done_testing;
