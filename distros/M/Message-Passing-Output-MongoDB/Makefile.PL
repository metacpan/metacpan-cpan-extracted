use inc::Module::Install;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

license 'perl';
name 'Message-Passing-Output-MongoDB';
all_from 'lib/Message/Passing/Output/MongoDB.pm';

resources(
    repository => "git://github.com/bins/Message-Passing-Output-MongoDB.git",
);
requires 'indirect';
requires 'multidimensional';
requires 'bareword::filehandles';
requires 'Message::Passing' => '0.009';
requires 'MongoDB';
requires 'Moose';
requires 'MooseX::Types';
requires 'AnyEvent';
requires 'MooseX::Types::ISO8601';
requires 'Tie::IxHash';
requires 'aliased';
requires 'namespace::autoclean';
test_requires 'Try::Tiny';

author_requires(
    'Test::Pod' => '1.14',
    'Test::NoTabs' => '0',
    'Test::Pod::Coverage' => '1.04',
    'Pod::Coverage' => '0.19',
    'Pod::Coverage::TrustPod' => '0',
    'Test::Spelling' => '0',
);

author_tests 't/author';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Message/Passing/Output/MongoDB.pm > README")
        and die $!;
}

WriteAll;


