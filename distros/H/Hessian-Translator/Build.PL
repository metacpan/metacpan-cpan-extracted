use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'Hessian::Translator',
    license     => 'perl',
    dist_author => 'William Travis Holton <heytrav@cpan.org>',
    dist_version_from    => 'lib/Hessian/Translator.pm',
    recursive_test_files => 1,
    meta_merge           => {
        resources => {
            repository => 'https://github.com/heytrav/hessian-client.git',
        }
    },
    requires             => {
        'Test::More'                    => 0,
        'Test::Class'                   => 0,
        'Test::Deep'                    => 0,
        'Perl::Critic'                  => 0,
        'Test::Perl::Critic'            => 0,
        'Contextual::Return'            => 0,
        'Moose'                         => 0,
        'Class::Std'                    => 0,
        'Exception::Class'              => 0,
        'Math::Int64'                   => 0,
        'Math::BigInt'                  => 0,
        'Smart::Comments'               => 0,
        'YAML'                          => 0,
        'Module::Load'                  => 0,
        'List::MoreUtils'               => 0,
        'LWP::UserAgent'                => 0,
        'HTTP::Request'                 => 0,
        'DateTime'                      => 0,
        'DateTime::Format::Strptime'    => 0,
        'DateTime::Format::Epoch'       => 0,
        'DateTime::Format::Epoch::Unix' => 0,

    },
    add_to_cleanup => ['Hessian-*'],
);

my $network_available = $builder->y_n("Network connection available?",'n');
$builder->notes(network_available => $network_available);
$builder->create_build_script();
