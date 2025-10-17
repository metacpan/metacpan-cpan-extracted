use strict;
use warnings;
use Test::More;
use JSON::PP qw(encode_json);
use JQ::Lite;

my $jq = JQ::Lite->new;

sub apply_query {
    my ($data, $query) = @_;
    my $json = encode_json($data);
    my @results = $jq->run_query($json, $query);
    return @results;
}

subtest 'update existing value' => sub {
    my $data = { spec => { replicas => 1 } };
    my ($result) = apply_query($data, '.spec.replicas = 3');

    is($result->{spec}{replicas}, 3, 'replicas updated to 3');
};

subtest 'create new nested key' => sub {
    my $data = { spec => {} };
    my ($result) = apply_query($data, '.spec.version = "1.2.3"');

    is($result->{spec}{version}, '1.2.3', 'version key created');
};

subtest 'assign from another path' => sub {
    my $data = { spec => { replicas => 2 } };
    my ($result) = apply_query($data, '.spec.copy = .spec.replicas');

    is($result->{spec}{copy}, 2, 'value copied from other path');
};

subtest 'update array element' => sub {
    my $data = { items => [ { value => 1 }, { value => 2 } ] };
    my ($result) = apply_query($data, '.items[1].value = 5');

    is($result->{items}[1]{value}, 5, 'second item updated');
    is($result->{items}[0]{value}, 1, 'first item untouched');
};

subtest 'assign within root array' => sub {
    my $data = [ { value => 1 }, { value => 2 } ];
    my ($result) = apply_query($data, '.[0].value = 9');

    is($result->[0]{value}, 9, 'first element updated');
};

subtest 'assign null literal' => sub {
    my $data = { spec => { replicas => 4 } };
    my ($result) = apply_query($data, '.spec.replicas = null');

    ok(!defined $result->{spec}{replicas}, 'value set to null');
};

subtest 'compound assignments on numbers' => sub {
    subtest 'addition assignment' => sub {
        my $data = { spec => { count => 2 } };
        my ($result) = apply_query($data, '.spec.count += 3');

        is($result->{spec}{count}, 5, 'count increased by 3');
    };

    subtest 'subtraction assignment' => sub {
        my $data = { spec => { count => 10 } };
        my ($result) = apply_query($data, '.spec.count -= 4');

        is($result->{spec}{count}, 6, 'count decreased by 4');
    };

    subtest 'multiplication assignment' => sub {
        my $data = { spec => { factor => 3 } };
        my ($result) = apply_query($data, '.spec.factor *= 5');

        is($result->{spec}{factor}, 15, 'factor multiplied by 5');
    };

    subtest 'division assignment' => sub {
        my $data = { spec => { ratio => 20 } };
        my ($result) = apply_query($data, '.spec.ratio /= 4');

        is($result->{spec}{ratio}, 5, 'ratio divided by 4');
    };

    subtest 'addition assignment on missing key initializes value' => sub {
        my $data = { spec => {} };
        my ($result) = apply_query($data, '.spec.count += 4');

        is($result->{spec}{count}, 4, 'missing count treated as zero');
    };

    subtest 'division assignment by zero leaves value unchanged' => sub {
        my $data = { spec => { ratio => 10 } };
        my ($result) = apply_query($data, '.spec.ratio /= 0');

        is($result->{spec}{ratio}, 10, 'division by zero ignored');
    };
};

done_testing();
