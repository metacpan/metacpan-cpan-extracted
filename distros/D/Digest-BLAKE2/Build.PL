# vim: set expandtab ts=4 sw=4 nowrap ft=perl ff=unix :
use strict;
use warnings;
use File::Spec;
use File::Path qw/make_path/;

use Module::Build::Pluggable(
    'XSUtil' => {
        cc_warnings => 0,
        ppport      => 'src/ppport.h',
        'c99'       => 1,
    }
);

my %xs_files;
my @dependent_files;
my @clean_files;

# Generate C codes.
# We want to use ACTION_code for code generation.
# But I don't know how to make subclass of Module::Build with Module::Build::Pluggable.
{
    # NOTE: remove BLAKE2bp and BLAKE2sp for avoiding segmentation fault
    # my @algorithms = ('b', 's', 'bp', 'sp');
    my @algorithms = ('b', 's');

    for my $algorithm (@algorithms) {
        my ($xs_path, $xs_filtered_path) =
          filter_module_name([ 'src', 'BLAKE2x.xs' ], $algorithm);
        my ($pm_path, $pm_filtered_path) =
          filter_module_name([ 'lib', 'Digest', 'BLAKE2x.pm' ], $algorithm);
        $xs_files{$xs_filtered_path} = "lib/Digest/BLAKE2$algorithm.xs";
        push @dependent_files, $xs_path,          $pm_path;
        push @clean_files,     $xs_filtered_path, $pm_filtered_path;
    }
}

# Check byteorder
{
    my $content = '';
    use Config;
    if ($Config{byteorder} eq '4321' || $Config{byteorder} eq '87654321') {
        $content = '#define WORDS_BIGENDIAN 1';
    }
    open my $out_fh, '>', File::Spec->catdir('stringencoders', 'config.h');
    print $out_fh $content;
    close $out_fh;
}

my $build = Module::Build::Pluggable->new(
    module_name => 'Digest::BLAKE2',
    dist_author =>
      'Tasuku SUENAGA a.k.a. gunyarakun <tasuku-s-cpanATATtitech.ac>',
    license => 'perl',

    requires => {
        perl => '5.008005',
    },
    configure_requires => {
        'Module::Build'                    => '0.4003',
        'Module::Build::Pluggable::XSUtil' => '0.01',
    },
    build_requires => {
        'Test::More'      => '0.98',
        'Test::Requires'  => '0',
        'Test::Exception' => '0',
    },
    include_dirs         => [ 'src', 'stringencoders' ],
    c_source             => ['stringencoders'],
    xs_files             => \%xs_files,
    extra_compiler_flags => [qw/-std=c99/],

    no_index => { 'directory' => [ 'inc', 'author' ] },

    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? 't/ xt/' : 't/',
    recursive_test_files => 1,

    resources => {
        repository => {
            url  => 'git://github.com/gunyarakun/p5-Digest-BLAKE2.git',
            web  => 'http://github.com/gunyarakun/p5-Digest-BLAKE2',
            type => 'git',
        }
    },

    create_readme  => 1,
    create_license => 1,
);

$build->create_build_script();

sub filter_module_name {
    my ($paths, $algorithm) = @_;

    my $in_path = File::Spec->catdir('in', @$paths);
    open my $fh, '<', $in_path;
    my $content = do { local $/; <$fh> };
    close $fh;
    $content =~ s/(BLAKE2)x/$1$algorithm/ig;
    $content =~ s/(${algorithm})(_OUTBYTES)/uc(substr($1, 0, 1)).$2/ge;

    my $out_path = File::Spec->catdir(@$paths);
    $out_path =~ s/(BLAKE2)x/$1$algorithm/;
    open my $out_fh, '>', $out_path;
    print $out_fh $content;
    close $out_fh;

    $in_path, $out_path;
}
