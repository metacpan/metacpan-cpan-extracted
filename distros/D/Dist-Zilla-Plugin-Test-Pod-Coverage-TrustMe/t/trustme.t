use v5.20;
use warnings;
use experimental qw(signatures postderef);

use Test::More;
use Dist::Zilla::Dist::Builder;
use File::ShareDir ();
use Path::Tiny;
use Test::DZil;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ 'GatherDir' ],
                [ 'Test::Pod::Coverage::TrustMe', 'base' ],
                [ 'Test::Pod::Coverage::TrustMe', 'with_modules' => {
                    filename => 'xt/author/with-modules.t',
                    module => [
                        'My::Module',
                    ],
                } ],
                [ 'Test::Pod::Coverage::TrustMe', 'with_options' => {
                    filename => 'xt/author/with-options.t',
                    private => [
                        'welp',
                        '/guff/',
                    ],
                    also_private => [
                        'chorg',
                    ],
                    trust_methods => 1,
                    require_content => 1,
                    trust_parents => 1,
                    trust_roles => 1,
                    trust_packages => 1,
                    trust_pod => 1,
                    require_link => 1,
                    export_only => 1,
                    ignore_imported => 1,
                    options => [
                        'extra_option = rulp',
                        'another_option => bluh',
                    ],
                } ],
            ),
            path(qw(source lib My Module.pm)) => <<'END_CODE',
                package My::Module;

                1;
END_CODE
            path(qw(source lib My Module2.pm)) => <<'END_CODE',
                package My::Module2;

                1;
END_CODE
        },
    },
);

$tzil->build;

my %files = map +($_->name => $_), $tzil->files->@*;

subtest "default generated test" => sub {
    my $test = $files{'xt/author/pod-coverage.t'};
    ok $test, 'found test'
        or return;
    my $content = $test->content;
    like $content, qr/\bMy::Module\b/, 'includes first module';
    like $content, qr/\bMy::Module2\b/, 'includes second module';
};

subtest "test with modules" => sub {
    my $test = $files{'xt/author/with-modules.t'};
    ok $test, 'found test'
        or return;
    my $content = $test->content;
    like $content, qr/\bMy::Module\b/, 'includes first module';
    unlike $content, qr/\bMy::Module2\b/, "doesn't include second module";
};

subtest "test with options" => sub {
    my $test = $files{'xt/author/with-options.t'};
    ok $test, 'found test'
        or return;
    my $content = $test->content;
    my ($config_text) = $content =~ /\bmy \$config = (\{.*?\});/s;
    ok $config_text, 'found config'
        or return;
    my $config = eval $config_text
        or die $@;
    is_deeply $config, {
        also_private => [
            qr/\Achorg\z/u,
        ],
        another_option => 'bluh',
        export_only => 1,
        extra_option => 'rulp',
        ignore_imported => 1,
        private => [
            qr/\Awelp\z/u,
            qr/guff/u,
        ],
        require_content => 1,
        require_link => 1,
        trust_methods => [
            1,
        ],
        trust_packages => 1,
        trust_parents => 1,
        trust_pod => 1,
        trust_roles => 1,
    };
};

done_testing;
