#!perl
### no critic (ControlStructures::ProhibitPostfixControls)

use strict;
use warnings;

our $VERSION = 0.001;

use Test2::V1             qw( -utf8 -x );
use Test2::Tools::Subtest qw( subtest_streamed );
use Test2::Tools::GenTemp qw( gen_temp );

use Dist::Zilla::Plugin::WeaveFile::Engine;

my $module_content = <<'END_MODULE';
package My::Module;
use strict;
use warnings;

our $VERSION = '1.23';

=head1 NAME

My::Module - A test module for weaving

=head1 SYNOPSIS

    use My::Module;
    my $obj = My::Module->new;

=head1 DESCRIPTION

This is a test module used to verify that the WeaveFile engine
can extract POD sections and convert them to Markdown.

=head2 Details

Some extra detail under a subheading.

=head1 AUTHOR

Test Author

=cut

1;
END_MODULE

my $config_content = <<'END_CONFIG';
---
snippets:
    header: |
        # [% dist.name %]

        [% dist.abstract %]
    footer: |
        ---
        Version [% dist.version %] by [% dist.author %]

files:
    "README.md": |
        [% snippets.header %]

        [% pod("My::Module", "SYNOPSIS") %]

        [% pod("My::Module", "DESCRIPTION") %]

        [% snippets.footer %]
    "SIMPLE.txt": |
        Name: [% dist.name %]
        Version: [% dist.version %]
END_CONFIG

my $root = gen_temp(
    '.weavefilerc' => $config_content,
    lib            => {
        My => {
            'Module.pm' => $module_content,
        },
    },
);

my $dist = {
    name     => 'My-Dist',
    abstract => 'A test distribution',
    author   => 'Test Author <test@example.com>',
    authors  => ['Test Author <test@example.com>'],
    version  => '1.23',
};

subtest_streamed 'Engine construction' => sub {
    T2->ok( dies { Dist::Zilla::Plugin::WeaveFile::Engine->new() }, 'dies without config_path', );

    my $engine = Dist::Zilla::Plugin::WeaveFile::Engine->new(
        config_path => '.weavefilerc',
        root_dir    => $root,
        dist        => $dist,
    );
    T2->ok( $engine, 'engine created' );
};

subtest_streamed 'Config loading' => sub {
    my $engine = Dist::Zilla::Plugin::WeaveFile::Engine->new(
        config_path => '.weavefilerc',
        root_dir    => $root,
        dist        => $dist,
    );

    my $config = $engine->config;
    T2->ok( $config->{snippets}, 'config has snippets' );
    T2->ok( $config->{files},    'config has files' );

    my @files = sort $engine->available_files;
    T2->is( \@files, [qw( README.md SIMPLE.txt )], 'available_files lists both' );
};

subtest_streamed 'Config file not found' => sub {
    my $engine = Dist::Zilla::Plugin::WeaveFile::Engine->new(
        config_path => 'nonexistent.yaml',
        root_dir    => $root,
        dist        => $dist,
    );
    T2->ok( dies { $engine->config }, 'dies when config file missing' );
};

subtest_streamed 'POD extraction' => sub {
    my $engine = Dist::Zilla::Plugin::WeaveFile::Engine->new(
        config_path => '.weavefilerc',
        root_dir    => $root,
        dist        => $dist,
    );

    my $synopsis = $engine->extract_pod_section( 'My::Module', 'SYNOPSIS' );
    T2->like( $synopsis, qr/SYNOPSIS/msx,        'section heading present' );
    T2->like( $synopsis, qr/My::Module->new/msx, 'section content present' );
    T2->unlike( $synopsis, qr/DESCRIPTION/msx, 'next section not included' );

    my $desc = $engine->extract_pod_section( 'My::Module', 'DESCRIPTION' );
    T2->like( $desc, qr/DESCRIPTION/msx, 'description heading present' );
    T2->like( $desc, qr/Details/msx,     'subheading included' );
    T2->unlike( $desc, qr/AUTHOR/msx, 'next head1 not included' );

    my $empty = $engine->extract_pod_section( 'My::Module', 'NONEXISTENT' );
    T2->is( $empty, q{}, 'nonexistent section returns empty string' );
};

subtest_streamed 'POD extraction by file path' => sub {
    my $engine = Dist::Zilla::Plugin::WeaveFile::Engine->new(
        config_path => '.weavefilerc',
        root_dir    => $root,
        dist        => $dist,
    );

    my $synopsis = $engine->extract_pod_section( 'lib/My/Module.pm', 'SYNOPSIS' );
    T2->like( $synopsis, qr/My::Module->new/msx, 'file path resolution works' );
};

subtest_streamed 'Source resolution errors' => sub {
    my $engine = Dist::Zilla::Plugin::WeaveFile::Engine->new(
        config_path => '.weavefilerc',
        root_dir    => $root,
        dist        => $dist,
    );

    T2->ok( dies { $engine->extract_pod_section( 'No::Such::Module', 'SYNOPSIS' ) }, 'dies for nonexistent module', );
    T2->ok( dies { $engine->extract_pod_section( 'no/such/file.pm',  'SYNOPSIS' ) }, 'dies for nonexistent file', );
};

subtest_streamed 'Simple file rendering (no POD, no snippets)' => sub {
    my $engine = Dist::Zilla::Plugin::WeaveFile::Engine->new(
        config_path => '.weavefilerc',
        root_dir    => $root,
        dist        => $dist,
    );

    my $output = $engine->render_file('SIMPLE.txt');
    T2->like( $output, qr/Name: \s My-Dist/msx,   'dist.name rendered' );
    T2->like( $output, qr/Version: \s 1[.]23/msx, 'dist.version rendered' );
};

subtest_streamed 'Full README rendering' => sub {
    my $engine = Dist::Zilla::Plugin::WeaveFile::Engine->new(
        config_path => '.weavefilerc',
        root_dir    => $root,
        dist        => $dist,
    );

    my $output = $engine->render_file('README.md');

    T2->like( $output, qr/\A[#] \s My-Dist\n/msx,                        'rendered header snippet with dist.name' );
    T2->like( $output, qr/A \s test \s distribution/msx,                 'rendered dist.abstract' );
    T2->like( $output, qr/My::Module->new/msx,                           'rendered pod() SYNOPSIS' );
    T2->like( $output, qr/verify \s that \s the/msx,                     'rendered pod() DESCRIPTION' );
    T2->like( $output, qr/Details/msx,                                   'pod() included subheading' );
    T2->like( $output, qr/Version \s 1[.]23 \s by \s Test \s Author/msx, 'rendered footer snippet with TT tags' );
};

subtest_streamed 'Full file comparison with two modules' => sub {
    my $greeter_content = <<'END_MODULE';
package My::Greeter;
use strict;
use warnings;

our $VERSION = '1.00';

=head1 NAME

My::Greeter - A greeting module

=head1 SYNOPSIS

    use My::Greeter;
    My::Greeter->hello;

=head1 DESCRIPTION

My::Greeter provides friendly greetings.

=cut

1;
END_MODULE

    my $farewell_content = <<'END_MODULE';
package My::Farewell;
use strict;
use warnings;

our $VERSION = '1.00';

=head1 NAME

My::Farewell - A farewell module

=head1 SYNOPSIS

    use My::Farewell;
    My::Farewell->goodbye;

=head1 DESCRIPTION

My::Farewell handles partings gracefully.

=head2 Formal

Use C<< My::Farewell->formal >> for business contexts.

=cut

1;
END_MODULE

    my $two_mod_config = <<'END_CONFIG';
---
snippets:
    footer: |
        ---
        Copyright [% dist.author %]

files:
    "README.md": |
        # [% dist.name %]

        [% dist.abstract %]

        [% pod("My::Greeter", "SYNOPSIS") %]

        [% pod("My::Farewell", "DESCRIPTION") %]

        [% snippets.footer %]
END_CONFIG

    my $two_mod_root = gen_temp(
        '.weavefilerc' => $two_mod_config,
        lib            => {
            My => {
                'Greeter.pm'  => $greeter_content,
                'Farewell.pm' => $farewell_content,
            },
        },
    );

    my $two_mod_dist = {
        name     => 'Two-Modules',
        abstract => 'A multi-module test',
        author   => 'Test Author <test@example.com>',
        authors  => ['Test Author <test@example.com>'],
        version  => '1.00',
    };

    my $engine = Dist::Zilla::Plugin::WeaveFile::Engine->new(
        config_path => '.weavefilerc',
        root_dir    => $two_mod_root,
        dist        => $two_mod_dist,
    );

    my $got = $engine->render_file('README.md');

    my $expected = <<'END_EXPECTED';
# Two-Modules

A multi-module test

# SYNOPSIS

    use My::Greeter;
    My::Greeter->hello;

# DESCRIPTION

My::Farewell handles partings gracefully.

## Formal

Use `My::Farewell->formal` for business contexts.

---
Copyright Test Author <test@example.com>
END_EXPECTED

    T2->is( $got, $expected, 'full rendered README matches expected output exactly' );
};

subtest_streamed 'Nonexistent file definition' => sub {
    my $engine = Dist::Zilla::Plugin::WeaveFile::Engine->new(
        config_path => '.weavefilerc',
        root_dir    => $root,
        dist        => $dist,
    );

    T2->ok( dies { $engine->render_file('NO_SUCH_FILE.md') }, 'dies for undefined file' );
};

T2->done_testing;
