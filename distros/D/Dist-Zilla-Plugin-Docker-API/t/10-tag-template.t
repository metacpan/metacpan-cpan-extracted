use strict;
use warnings;
use Test::More;
use Test::Deep;
use Dist::Zilla::Plugin::Docker::API::TagTemplate;

subtest 'basic template expansion' => sub {
    my $tmpl = Dist::Zilla::Plugin::Docker::API::TagTemplate->new(
        zilla => undef,
        plugin_name => 'Docker::API',
    );

    is($tmpl->expand('%n', name => 'My-App'), 'My-App');
    is($tmpl->expand('%v', version => '1.234'), '1.234');
    is($tmpl->expand('%t', trial => '-TRIAL'), '-TRIAL');
    is($tmpl->expand('%g', git_short_sha => 'abc1234'), 'abc1234');
    is($tmpl->expand('%G', git_full_sha => 'abc1234def5678'), 'abc1234def5678');
    is($tmpl->expand('%b', branch => 'main'), 'main');
    is($tmpl->expand('%d', build_root => '/path/to/build'), '/path/to/build');
    is($tmpl->expand('%o', source_root => '/path/to/src'), '/path/to/src');
    is($tmpl->expand('%a', archive => '/path/to/archive.tar.gz'), '/path/to/archive.tar.gz');
    is($tmpl->expand('%p', plugin_name => 'Docker::API'), 'Docker::API');
};

subtest 'composite templates' => sub {
    my $tmpl = Dist::Zilla::Plugin::Docker::API::TagTemplate->new(
        zilla => undef,
        plugin_name => 'Docker::API',
    );

    is($tmpl->expand('v%v', version => '1.234'), 'v1.234');
    is($tmpl->expand('build-%v', version => '1.234'), 'build-1.234');
    is($tmpl->expand('sha-%g', git_short_sha => 'abc1234'), 'sha-abc1234');
    is($tmpl->expand('%n:%v', name => 'My-App', version => '1.234'), 'My-App:1.234');
};

subtest 'major version (%V / %vmaj)' => sub {
    my $tmpl = Dist::Zilla::Plugin::Docker::API::TagTemplate->new(
        zilla => undef,
        plugin_name => 'Docker::API',
    );

    is($tmpl->expand('%V',    version => '0.402'),  '0',   '%V extracts leading int');
    is($tmpl->expand('%V',    version => '1.234'),  '1',   '%V with 1.234');
    is($tmpl->expand('%V',    version => '12.34'),  '12',  '%V with multi-digit major');
    is($tmpl->expand('%V',    version => ''),       '',    '%V with empty version');
    is($tmpl->expand('%V-x',  version => '0.402'),  '0-x', '%V composed with literal');
    is($tmpl->expand('%vmaj', version => '0.402'),  '0',   '%vmaj alias still works');
    is($tmpl->expand('%vmin', version => '0.402'),  '402', '%vmin still works');
};

subtest 'unknown variables' => sub {
    my $tmpl = Dist::Zilla::Plugin::Docker::API::TagTemplate->new(
        zilla => undef,
        plugin_name => 'Docker::API',
    );

    is($tmpl->expand('%x', name => 'Test'), '');
    is($tmpl->expand('%x', git_short_sha => 'abc'), '');
    is($tmpl->expand('v%z', version => '1.0'), 'v');
};

subtest 'number padding' => sub {
    my $tmpl = Dist::Zilla::Plugin::Docker::API::TagTemplate->new(
        zilla => undef,
        plugin_name => 'Docker::API',
    );

    is($tmpl->expand('%01', name => 'Test'), '%01');
};

done_testing;