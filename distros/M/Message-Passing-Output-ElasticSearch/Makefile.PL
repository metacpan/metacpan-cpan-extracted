use strict;
use warnings;
use inc::Module::Install;
use Module::Install::Authority;

all_from 'lib/Message/Passing/Output/ElasticSearch.pm';
authority('GHENRY');
resources(
    repository => "git://github.com/suretec/Message-Passing-Output-ElasticSearch.git",
);

requires 'Moose';
requires 'namespace::autoclean';
requires 'AnyEvent';
requires 'Try::Tiny';
requires 'ElasticSearch';
requires 'ElasticSearch::Transport::AEHTTP';
requires 'MooseX::Types';
requires 'Message::Passing' => '0.001';
requires 'aliased' => '0';
requires 'Scalar::Util' => '0';
requires 'MooseX::Types::Moose' => '0';
requires 'MooseX::Types::ISO8601' => '0';
requires 'MooseX::Types::DateTime' => '0';
requires 'JSON' => '0';
test_requires 'Test::More' => '0.88';

author_requires(
    'Test::Pod' => '1.14',
    'Test::NoTabs' => '0',
    'Test::Pod::Coverage' => '1.04',
    'Pod::Coverage' => '0.19',
    'Pod::Coverage::TrustPod' => '0',
    'Test::Spelling' => '0'
);

author_tests 't/author';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Message/Passing/Output/ElasticSearch.pm > README")
        and die $!;
}

WriteAll;
