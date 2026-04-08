#!perl
use strict;
use warnings;
use Test::More;
use LLM::SimpleClient;

# Test basic client creation
subtest 'Client creation' => sub {
    my $client = LLM::SimpleClient->new(
        provider   => 'mistral',
        api_key    => 'test-key',
        model      => 'test-model',
    );
    
    ok($client, 'Client created');
    is($client->{provider}, 'mistral', 'Provider set correctly');
    is($client->{api_key}, 'test-key', 'API key set correctly');
    is($client->{model}, 'test-model', 'Model set correctly');
};

# Test default values
subtest 'Default values' => sub {
    my $client = LLM::SimpleClient->new(
        provider => 'mistral',
        api_key  => 'test-key',
        model    => 'test-model',
    );
    
    is($client->{temperature}, 0.7, 'Default temperature is 0.7');
    is($client->{max_tokens}, 4096, 'Default max_tokens is 4096');
    is($client->{top_p}, 1.0, 'Default top_p is 1.0');
    is($client->{timeout}, 60, 'Default timeout is 60');
};

# Test custom parameters
subtest 'Custom parameters' => sub {
    my $client = LLM::SimpleClient->new(
        provider   => 'mistral',
        api_key    => 'test-key',
        model      => 'test-model',
        temperature => 0.5,
        max_tokens  => 1000,
        top_p       => 0.9,
        timeout     => 30,
    );
    
    is($client->{temperature}, 0.5, 'Custom temperature set');
    is($client->{max_tokens}, 1000, 'Custom max_tokens set');
    is($client->{top_p}, 0.9, 'Custom top_p set');
    is($client->{timeout}, 30, 'Custom timeout set');
};

done_testing();