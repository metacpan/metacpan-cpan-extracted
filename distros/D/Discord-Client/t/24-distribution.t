use v5.26;
use warnings;
use Test2::V1;
use CPAN::Meta;
use CPAN::Meta::Validator;

# The source checkout has no generated metadata; disttest exercises these checks.
T2->skip_all('Generated metadata is checked in the make disttest tree')
    unless -f 'META.json';

my $metadata = CPAN::Meta->load_file('META.json');

# Validate the generated metadata in the packaged distribution.
T2->subtest(
    'the distribution metadata follows the CPAN specification',
    sub {
        my $validator = CPAN::Meta::Validator->new( $metadata->as_struct );
        my $valid = $validator->is_valid;
        T2->ok( $valid, 'META.json is valid' );
        T2->diag( join "\n", $validator->errors ) unless $valid;
        T2->is( $metadata->name, 'Discord-Client', 'metadata identifies this distribution' );
        T2->is( [ $metadata->license ], ['apache_2_0'],
            'the distribution declares its Apache License 2.0 license' );
    }
);

T2->subtest(
    'installers require Windows monotonic clock support',
    sub {
        my $requirements = $metadata->effective_prereqs->requirements_for( 'runtime', 'requires' );
        T2->ok(
            !$requirements->accepts_module( 'Time::HiRes', '1.9763' ),
            'versions without Windows clock_gettime support are rejected'
        );
        T2->ok(
            $requirements->accepts_module( 'Time::HiRes', '1.9764' ),
            'the first version with Windows clock_gettime support is accepted'
        );
    }
);

T2->subtest(
    'installers provide Test2::V1 only for testing',
    sub {
        my $test_requirements = $metadata->effective_prereqs->requirements_for( 'test', 'requires' );
        T2->ok(
            !$test_requirements->accepts_module( 'Test2::V1', '1.302216' ),
            'versions missing the required V1 tools are rejected'
        );
        T2->ok( $test_requirements->accepts_module( 'Test2::V1', '1.302217' ),
            'the minimum supported test bundle is accepted' );

        # Consumers should not need the test framework to run an installed client.
        my $runtime_requirements = $metadata->effective_prereqs->requirements_for( 'runtime', 'requires' );
        T2->ok(
            !grep( $_ eq 'Test2::V1', $runtime_requirements->required_modules ),
            'applications do not acquire a test-framework runtime dependency'
        );
    }
);

# Keep test fixtures and implementation helpers out of the public index.
T2->subtest(
    'test fixtures and internal packages are excluded from CPAN indexing',
    sub {
        for my $file (
            qw(t/lib/TestDiscordREST.pm t/lib/TestDiscordGateway.pm t/lib/TestDiscordExamples.pm
            t/lib/TestDiscordTLS.pm examples/ping.pl)
            )
        {
            T2->ok( !$metadata->should_index_file($file), "$file is excluded" );
        }

        # Source files are shipped, but implementation packages are not public CPAN APIs.
        my @internal_packages = qw(
            Discord::Client::Gateway::Session
            Discord::Client::Gateway::IdentifyLimiter
            Discord::Client::Gateway::IdentifyLimiter::Permit
            Discord::Client::Gateway::WebSocket
            Discord::Client::Gateway::WebSocket::Client
            Discord::Client::REST::RateLimiter
        );
        T2->is(
            [ sort @{ $metadata->no_index->{package} } ],
            [ sort @internal_packages ],
            'exactly the six internal packages are excluded'
        );
        for my $package (@internal_packages) {
            T2->ok( !$metadata->should_index_package($package), "$package is internal" );
        }
    }
);

# Check every public package against its shipped file and indexing policy.
T2->subtest(
    'all nineteen public packages are shipped and indexable',
    sub {
        my @public_packages = qw(
            Discord::Client
            Discord::Client::REST
            Discord::Client::REST::Error
            Discord::Client::Gateway
            Discord::Client::Gateway::Shards
            Discord::Client::Commands
            Discord::Client::Interaction
            Discord::Client::Interaction::Verifier
            Discord::Client::Interactions
            Discord::Client::HTTPInteractions
            Discord::Client::UI
            Discord::Client::Intents
            Discord::Client::Error
            Discord::Client::Cache
            Discord::Client::Model
            Discord::Client::Model::Message
            Discord::Client::Model::Channel
            Discord::Client::Model::User
            Discord::Client::Model::Guild
        );
        for my $package (@public_packages) {
            my $file = "lib/$package.pm";
            $file =~ s{::}{/}g;
            T2->ok( -f $file, "$package is shipped" );
            T2->ok( $metadata->should_index_file($file) && $metadata->should_index_package($package),
                "$package is indexable" );
        }
    }
);

T2->done_testing;
