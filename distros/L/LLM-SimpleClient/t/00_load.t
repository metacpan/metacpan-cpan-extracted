#!perl
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('LLM::SimpleClient');
    use_ok('LLM::SimpleClient::Provider');
    use_ok('LLM::SimpleClient::Mistral');
    use_ok('LLM::SimpleClient::HuggingFace');
    use_ok('LLM::SimpleClient::OpenRouter');
}

diag("Testing LLM::SimpleClient $LLM::SimpleClient::VERSION");

done_testing();