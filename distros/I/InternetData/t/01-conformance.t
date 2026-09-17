use strict;
use warnings;

use lib 't/lib';

use Test::More;
use InternetData;
use InternetData::Error;
use InternetDataTest;
use InternetDataTest::Origin;

# The shared conformance corpus, asserted by every InternetData SDK in the same
# terms, so a Perl-only drift fails here rather than surfacing as two client
# libraries quietly disagreeing about one refusal.
my $corpus = InternetDataTest::corpus();

my $route = {};
my $origin = InternetDataTest::Origin->new(sub {
    my ($c) = @_;
    $c->res->headers->header($_ => $route->{headers}{$_}) for keys %{ $route->{headers} || {} };
    $c->render(json => $route->{body}, status => $route->{status} || 200);
});

sub client {
    return InternetData->new(base_url => $origin->url, api_key => 'k', @_);
}

sub serve {
    ($route) = @_;
    $origin->reset;
}

subtest 'every refusal in the corpus maps the same way here as everywhere else' => sub {
    ok(@{ $corpus->{errors} }, 'the corpus carries error cases at all');

    for my $case (@{ $corpus->{errors} }) {
        # Both call shapes: a JSON endpoint and the redirect endpoint classify
        # their own responses, so a fix applied to one and not the other is
        # exactly the drift this corpus exists to catch.
        for my $call (
            ['list', sub { $_[0]->database->list }],
            ['download_url', sub { $_[0]->database->download_url('bogon_ip_v1', 'csvgz') }],
        ) {
            my ($name, $run) = @$call;
            serve($case);
            # No retries, so a retryable failure surfaces rather than looping.
            my $answer = eval { $run->(client(retries => 0)) };
            my $error = $@;

            ok(!defined $answer, "$case->{name} via $name: the call failed");
            isa_ok($error, 'InternetData::Error', "$case->{name} via $name: error type");
            is($error->kind, $case->{expect}{kind}, "$case->{name} via $name: kind");
            is($error->retryable, $case->{expect}{retryable} ? 1 : 0,
                "$case->{name} via $name: retryable");
            is($error->status, $case->{status}, "$case->{name} via $name: status");
            # The API says WHICH refusal this is, under `rc`. Falling back to the
            # status means the envelope went unread, and NOT_LICENSED and
            # LICENSE_EXPIRED are both 403.
            is($error->message, $case->{expect}{message}, "$case->{name} via $name: message")
                if defined $case->{expect}{message};
            is($error->retry_after, $case->{expect}{retryAfterSeconds},
                "$case->{name} via $name: retry_after")
                if defined $case->{expect}{retryAfterSeconds};
            is($origin->count, 1, "$case->{name} via $name: asked exactly once");
        }
    }
};

subtest 'a 4xx is never retried and a 5xx is' => sub {
    # The half of the classification a single-attempt test cannot see: `kind` can
    # be right while the retry rule reads something else entirely.
    for my $case (@{ $corpus->{errors} }) {
        serve($case);
        # Retry-After is 2 seconds in the corpus, which would make this test
        # sleep. Retried at all is what is being measured, so the header is
        # overridden to 0 while the classification above keeps the real value.
        $route->{headers} = { 'retry-after' => 0 } if $case->{expect}{retryable}
            && defined $case->{expect}{retryAfterSeconds};

        eval { client(retries => 2)->database->list };
        my $want = $case->{expect}{retryable} ? 3 : 1;
        is($origin->count, $want, "$case->{name}: $want attempt(s)");
    }
};

subtest 'a listing survives every standing, right and format the API publishes' => sub {
    my @families;
    for my $standing (@{ $corpus->{standings} }) {
        for my $right (@{ $corpus->{license_type} }) {
            push @families, InternetDataTest::family(
                base => "${standing}_${right}",
                standing => $standing,
                license_type => $standing eq 'unlicensed' ? undef : $right,
                versions => [{
                    id => "${standing}_${right}_v1", version => 1, summary => 'x',
                    formats => $corpus->{formats},
                }],
            );
        }
    }
    serve({ body => { databases => \@families } });

    my $databases = client()->database->list;

    is_deeply($databases, \@families, 'the catalog arrives exactly as served');
    is(scalar @$databases, scalar @families, 'nothing was dropped');
    for my $db (@$databases) {
        ok(grep({ $_ eq $db->{standing} } @{ $corpus->{standings} }),
            "$db->{base}: standing survived");
        is_deeply($db->{versions}[0]{formats}, $corpus->{formats},
            "$db->{base}: the formats it is built in survived");
    }
    # An unlicensed family has no licence, so it has no license_type right;
    # inventing one would tell a caller they may redistribute something they do
    # not hold.
    my ($unlicensed) = grep { $_->{standing} eq 'unlicensed' } @$databases;
    is($unlicensed->{license_type}, undef, 'an unlicensed family carries no right');
};

# The visibility contract, as the corpus states it: a family built for a single
# customer is ABSENT from a listing for anyone else, rather than present with an
# `unlicensed` standing. The server enforces that, and the only way a client can
# undermine it is by answering `list` from something other than this key's
# response - a bundled catalog, or a listing held from another key.
#
# The corpus names the rules but deliberately NOT the private ids, because it is
# committed into public repositories. So each rule id gets a handler here, and a
# rule with no handler is a failure rather than a silent gap.
my %VISIBILITY = (
    'listing-is-returned-as-served' => sub {
        my @served = (
            InternetDataTest::family(base => 'one'),
            InternetDataTest::family(base => 'two', standing => 'unlicensed', license_type => undef),
        );
        serve({ body => { databases => \@served } });

        my $databases = client()->database->list;

        is_deeply($databases, \@served, 'the listing arrives exactly as served');
        is(scalar @$databases, scalar @served, 'nothing added and nothing dropped');

        # An empty listing is an answer, not a prompt to fill one in.
        serve({ body => { databases => [] } });
        is_deeply(client()->database->list, [], 'and an empty catalog stays empty');
    },

    'no-catalog-is-compiled-into-the-client' => sub {
        # Structural, not behavioural: a client that ships a list of database ids
        # can answer from it under some future edit, and no request-counting test
        # would see that until it did. The modules as SHIPPED must name none.
        my $loaded = $INC{'InternetData.pm'};
        ok($loaded, 'the module under test was located') or return;
        (my $dir = $loaded) =~ s{\.pm\z}{};

        for my $file ($loaded, "$dir/Database.pm", "$dir/Error.pm") {
            open my $fh, '<', $file or do { fail("cannot read $file: $!"); next };
            my $line = 0;
            my @found;
            while (my $text = <$fh>) {
                $line++;
                # Documentation may name public examples; only executable code is
                # the claim being made here.
                last if $text =~ /\A__END__/;
                next if $text =~ /\A\s*#/;
                push @found, "$line: $text" if $text =~ /["'][a-z][a-z0-9_]*_v[0-9]+["']/;
            }
            is_deeply(\@found, [], "$file compiles in no database id");
        }
    },

    'a-listing-is-never-reused-across-clients' => sub {
        serve({ body => { databases => [InternetDataTest::family()] } });

        # Two keys can be on different licences and entitled to see different
        # families, so a listing held from one is not an answer for the other.
        client(api_key => 'key-a')->database->list;
        client(api_key => 'key-b')->database->list;
        is($origin->count, 2, 'each client asked the server for itself');

        # And a second call on ONE client asks again: a catalog held across a
        # licence change is the same disclosure with a slower fuse.
        $origin->reset;
        my $one = client(api_key => 'key-a');
        $one->database->list;
        $one->database->list;
        is($origin->count, 2, 'nothing is cached, so a listing is never stale');
    },
);

subtest 'the catalog is the server answer for THIS key, and nothing else' => sub {
    my @rules = @{ $corpus->{visibility}{clientRules} };
    ok(@rules, 'the corpus states visibility rules at all');

    for my $rule (@rules) {
        # A rule the corpus grew and this suite never noticed would otherwise
        # pass by saying nothing.
        my $handler = $VISIBILITY{$rule};
        ok($handler, "$rule: this suite has a handler for it") or next;
        subtest $rule => $handler;
    }
};

done_testing();
