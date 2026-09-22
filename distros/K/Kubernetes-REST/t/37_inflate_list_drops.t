#!/usr/bin/env perl
# karr #16: _inflate_list used to discard any list item the object model
# rejects - eval around struct_to_object, push only on success - with no
# warning, no counter, no difference in the return value. A cluster whose
# Pods carry a field the installed IO::K8s does not know read as a smaller
# cluster, or an empty one. Dropping stays (a library must not turn one
# drifted object into a fatal list()), but it must be loud: one warning per
# list naming every dropped item and why.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";

use Test::Kubernetes::Mock qw(mock_api);

sub pod_list_response {
    my ($api, @items) = @_;
    $api->io->add_response('GET', '/api/v1/namespaces/default/pods', {
        kind => 'PodList', apiVersion => 'v1', items => \@items,
    });
}

my $GOOD = { metadata => { name => 'good' },
             spec => { containers => [ { name => 'c', image => 'i' } ] } };
my $GOOD2 = { metadata => { name => 'good2' } };
my $BAD = { metadata => { name => 'bad' },
            spec => { containers => 'NOT-AN-ARRAY' } };

subtest 'a rejected item is dropped loudly, not silently' => sub {
    my $api = mock_api();
    pod_list_response($api, $GOOD, $BAD, $GOOD2);

    my @warnings;
    my $list = do {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        $api->list('Pod', namespace => 'default');
    };

    is scalar @{$list->items}, 2, 'the two inflatable items come back';
    is_deeply [map { $_->metadata->name } @{$list->items}], ['good', 'good2'],
        'and they are the right ones';

    is scalar @warnings, 1, 'exactly one warning for the whole list';
    like $warnings[0], qr/dropped 1 of 3 .*Pod items/,
        'the warning counts dropped against total';
    like $warnings[0], qr/INCOMPLETE/,
        'and says the list is incomplete';
    like $warnings[0], qr/item 1 \(name 'bad'\)/,
        'and names the dropped item by index and metadata.name';
};

subtest 'a fully inflatable list stays warning-free' => sub {
    my $api = mock_api();
    pod_list_response($api, $GOOD, $GOOD2);

    my @warnings;
    my $list = do {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        $api->list('Pod', namespace => 'default');
    };

    is scalar @{$list->items}, 2, 'all items come back';
    is_deeply \@warnings, [], 'and nothing is warned';
};

subtest 'every item rejected: an empty list, but a loud one' => sub {
    my $api = mock_api();
    pod_list_response($api, $BAD,
        { metadata => { name => 'bad2' }, spec => { containers => 42 } });

    my @warnings;
    my $list = do {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        $api->list('Pod', namespace => 'default');
    };

    is scalar @{$list->items}, 0, 'nothing inflatable, nothing returned';
    is scalar @warnings, 1, 'but one warning says so';
    like $warnings[0], qr/dropped 2 of 2/,
        '"no Pods" is now distinguishable from "no readable Pods"';
    like $warnings[0], qr/item 0 \(name 'bad'\)/, 'first item named';
    like $warnings[0], qr/item 1 \(name 'bad2'\)/, 'second item named';
};

subtest 'the caller can promote the warning to a fatal error' => sub {
    my $api = mock_api();
    pod_list_response($api, $GOOD, $BAD);

    local $SIG{__WARN__} = sub { die @_ };
    my $list = eval { $api->list('Pod', namespace => 'default') };
    ok !defined $list, 'strict callers get their fatal error';
    like $@, qr/dropped 1 of 2/, 'carrying the same diagnosis';
};

done_testing;
