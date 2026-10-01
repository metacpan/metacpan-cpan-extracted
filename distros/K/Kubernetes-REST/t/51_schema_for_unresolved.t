#!/usr/bin/env perl
# karr k47: schema_for with a name nothing resolves answers undef, silently.
#
# schema_for is a lookup, and a name it cannot find answers undef. For a
# qualified name that resolves to no class, expand_class answers undef, and
# schema_for went on to turn that undef into an OpenAPI definition name -
# several "Use of uninitialized value" warnings before the undef came back.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock qw(mock_api);

my %SPEC = (
    definitions => {
        'io.k8s.api.core.v1.Pod' => { type => 'object', description => 'a Pod' },
    },
    paths => {},
);

# 'other.org/v1/Widget': expand_class answers undef. 'Ghost': it answers the
# fabricated IO::K8s::Ghost, which names no definition either.
for my $name ('other.org/v1/Widget', 'Ghost') {
    my $api = mock_api();
    $api->io->add_response('GET', '/openapi/v2', \%SPEC);

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my $schema = $api->schema_for($name);

    ok(!defined $schema, "$name: schema_for answers undef");
    is_deeply(\@warnings, [], "$name: without a warning")
        or diag explain \@warnings;
}

# A name that resolves still finds its definition.
{
    my $api = mock_api();
    $api->io->add_response('GET', '/openapi/v2', \%SPEC);
    is($api->schema_for('Pod')->{description}, 'a Pod',
        'Pod: schema_for still finds the definition');
}

done_testing;
