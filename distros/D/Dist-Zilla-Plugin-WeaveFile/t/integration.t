#!perl
### no critic (ControlStructures::ProhibitPostfixControls)

use strict;
use warnings;

our $VERSION = 0.001;

use English qw( -no_match_vars );

use Path::Tiny qw( path );

use Test2::V1             qw( -utf8 -x );
use Test2::Tools::Subtest qw( subtest_streamed );
use Test2::Tools::GenTemp qw( gen_temp );
use Test::DZil;

use Dist::Zilla::Plugin::WeaveFile::Engine;

my $module_content = <<'END_MODULE';
package My::Sample;
use strict;
use warnings;

our $VERSION = '0.001';

=head1 NAME

My::Sample - A sample module

=head1 SYNOPSIS

    use My::Sample;
    my $s = My::Sample->new;
    $s->run;

=head1 DESCRIPTION

My::Sample does important things. It is the best module.

=cut

1;
END_MODULE

my $config_content = <<'END_CONFIG';
---
snippets:
    badge: |
        [![Build](https://example.com/badge.svg)](https://example.com)
    footer: |
        Copyright [% dist.author %]

files:
    "README.md": |
        [% snippets.badge %]

        # [% dist.name %]

        [% dist.abstract %]

        [% pod("My::Sample", "SYNOPSIS") %]

        [% pod("My::Sample", "DESCRIPTION") %]

        [% snippets.footer %]
END_CONFIG

my %root_config = (
    name             => 'My-Sample',
    abstract         => 'A sample distribution',
    author           => 'Test Author <test@example.com>',
    license          => 'Perl_5',
    copyright_holder => 'Test Author',
    version          => '0.001',
);

my $ini = dist_ini( \%root_config, ['GatherDir'], [ 'WeaveFile', 'README.md' ], ['Test::WeaveFile'], );

my $source = gen_temp(
    'dist.ini'     => $ini,
    '.weavefilerc' => $config_content,
    lib            => {
        My => {
            'Sample.pm' => $module_content,
        },
    },
);

# Generate README.md using Engine (simulates `dzil weave`).
my $engine = Dist::Zilla::Plugin::WeaveFile::Engine->new(
    config_path => '.weavefilerc',
    root_dir    => $source,
    dist        => {
        name     => $root_config{name},
        abstract => $root_config{abstract},
        author   => $root_config{author},
        authors  => [ $root_config{author} ],
        version  => $root_config{version},
    },
);
my $expected_readme = $engine->render_file('README.md');
path( $source, 'README.md' )->spew_utf8($expected_readme);

subtest_streamed 'Build succeeds and generates author test' => sub {
    my $tzil = Builder->from_config( { dist_root => $source } );
    $tzil->chrome->logger->set_debug(1);
    T2->ok( lives { $tzil->build }, 'build succeeds' ) or T2->diag($EVAL_ERROR);

    my @weave_tests = grep { $_->name =~ /weave/msx } @{ $tzil->files };
    T2->is( scalar @weave_tests, 1, 'exactly one weave test generated' );

    my $test_file = $weave_tests[0];
    T2->is( $test_file->name, 'xt/author/weave_readme_md.t', 'test file path correct' );

    my $content = $test_file->content;
    T2->like( $content, qr/use \s Test2::V1/msx,                        'generated test uses Test2::V1' );
    T2->like( $content, qr/File \s README[.]md \s exists/msx,           'test checks file existence' );
    T2->like( $content, qr/matches \s expected \s content/msx,          'test checks content match' );
    T2->like( $content, qr/__DATA__\n.*My-Sample/msx,                   'DATA section contains dist name' );
    T2->like( $content, qr/__DATA__\n.*My::Sample->new/msx,             'DATA section contains pod content' );
    T2->like( $content, qr/__DATA__\n.*Copyright \s Test \s Author/msx, 'DATA section contains rendered snippet' );
};

subtest_streamed 'Generated test DATA matches README.md' => sub {
    my $tzil = Builder->from_config( { dist_root => $source } );
    $tzil->build;

    my ($test_file) = grep { $_->name =~ /weave/msx } @{ $tzil->files };
    my $content = $test_file->content;

    my ($data_section) = $content =~ /^__DATA__\n(.*)\z/msx;
    T2->ok( defined $data_section, '__DATA__ section found' );

    $data_section =~ s/[[:space:]]+\z//msx;
    my $readme_norm = $expected_readme;
    $readme_norm =~ s/[[:space:]]+\z//msx;

    T2->is( $data_section, $readme_norm, 'DATA section matches rendered README.md' );
};

T2->done_testing;
