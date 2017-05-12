#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';
use Module::Build;

# TODO: Add version specifications for requirements

my $module_file = "lib/Log/Reproducible.pm";
my @scripts = grep { -f and !-d } glob 'script/*';

# eval "use Pod::Markdown";
# if ( ! $@ ) {
#     require Pod::Markdown;
#     my $readme_file = "future-README.md";
#     pod2markdown( $module_file, $readme_file );
# }

my $builder = Module::Build->new(
    module_name        => 'Log::Reproducible',
    dist_version_from  => $module_file,
    license            => 'perl',
    create_makefile_pl => 0,
    requires           => {
        'perl'            => 5.006,
        "Config"          => 0,
        "Cwd"             => 0,
        "File::Basename"  => 0,
        "File::Path"      => 0,
        "File::Temp"      => 0,
        "IPC::Open3"      => 0,
        "List::MoreUtils" => 0,
        "POSIX"           => 0,
        "YAML::Old"       => 0,
    },
    build_requires => {
        'Capture::Tiny' => 0,
        'Test::More'    => 0,
    },
    configure_requires => {
        'Module::Build' => 0,
    },
    recommends => {
        'Devel::Cover'   => 0,    # To generate testing coverage report
        'Module::Loaded' => 0,    # To test for loading of known conflicting modules
        # 'Pod::Markdown'  => 0,    # To auto-generate README from POD markup
        'Text::Diff'     => 0,    # To summarize Archived vs Current differences
    },
    script_files   => [ @scripts ],
    meta_merge => {
        resources => {
            repository =>
                'https://github.com/mfcovington/Log-Reproducible'
        }
    },
);

$builder->create_build_script;

exit;

# sub pod2markdown {
#     my ( $pod_file, $markdown_file ) = @_;
#     open my $markdown_fh, ">", $markdown_file
#         or die "Cannot open $markdown_file for writing: $!";
#     my $parser = Pod::Markdown->new();
#     $parser->output_fh($markdown_fh);
#     $parser->parse_file($pod_file);
#     close $markdown_fh;
# }
