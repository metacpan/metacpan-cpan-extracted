#!/usr/bin/env perl
use common::sense;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'FFprobe',
    license => 'perl',
    dist_author => q{Diogo Franco (Kovensky) <diogomfranco@gmail.com>},
    add_to_cleanup => [ 'FFprobe-*' ],
    configure_requires => {
	'common::sense' => 0,
    },
    requires => {
	'perl' => '5.10.0',
	'Carp' => 0,
	'common::sense' => 0,
	'Encode' => 0,
	'version' => '0.77',
    }
);

unless(qx{ffprobe -version 2>&1} =~ /libavcodec/) {
    say "'ffprobe' (part of ffmpeg/libav) is not present in this system's PATH. Aborting...";
    exit 0;
}

$builder->create_build_script;
