#!/usr/bin/perl
use 5.014;
use strict;
use warnings;
use ExtUtils::MakeMaker;

use File::Which;
use IPC::Run3;

my ($dot_bin, $issue_stretch, $issue_prism);

sub is_dot_available {
    $dot_bin = which('dot');
    if (!$dot_bin) {
        warn "External dot binary (https://graphviz.org) not found.\n" .
             "Please, make sure it is installed and can be found on the path.\n";
        return;
    }
    my ($dot_out, $dot_err);
    run3( [ $dot_bin, '-h' ], \undef, \$dot_out, \$dot_err );
    if ( $dot_err !~ /.*Usage:/s ) {
        warn "Your external dot binary seems not to run properly. Expect tests to fail.\n";
        return;
    }
    return 1;
}

sub dot_no_overlap_mode_ok {
    my ($dot_out, $dot_err);
    my $dot_in = make_test_gv(', overlap=0');
    run3( [ $dot_bin, '-Tdot' ], \$dot_in, \$dot_out, \$dot_err );
    if ( $dot_out !~ /^digraph/ || $dot_out !~ /bb="(.*?)"/s ) {
        warn "Your external dot binary does not seem to produce proper output. Expect tests to fail.\n";
        return;
    }
    my @bb = split( /,/, $1 );
    if ( scalar(@bb) != 4 || ($bb[3]+0) > 10*($bb[2]+0) ) {
        warn "Your external dot binary produces improbably stretched graphs (non-overlap mode).\n" .
             "Not all output formats may support this.\n" .
             "Please, check whether an updated version is available.\n";
        # not ok: bmp, gd, gd2, jpe, jpeg, jpg, png, ps2, tif, tiff, vt, vt-24bit, vt-4up, vt-6up, vt-8up, vt-8up2, wbmp, webp
        $issue_stretch = 1;
    }
    if ( $dot_err =~ /triangulation/s ) {
        warn "Your external dot binary may have trouble producing non-overlapping station markers.\n";
        $issue_prism = 1;
    }
}

sub dot_overlap_mode_ok {
    my ($dot_out, $dot_err);
    my $dot_in = make_test_gv('');
    run3( [ $dot_bin, '-Tdot' ], \$dot_in, \$dot_out, \$dot_err );
    if ( $dot_out !~ /^digraph/ || $dot_out !~ /bb="(.*?)"/s ) {
        warn "Your external dot binary does not seem to produce proper output. Expect tests to fail.\n";
        return;
    }
    my @bb = split( /,/, $1 );
    if ( scalar(@bb) != 4 || ($bb[3]+0) > 10*($bb[2]+0) ) {
        warn "Your external dot binary produces improbably stretched graphs (overlap mode).\n" .
             "Not all output formats may support this.\n" .
             "Please, check whether an updated version is available.\n";
        # not ok: bmp, gd, gd2, jpe, jpeg, jpg, png, ps2, tif, tiff, vt, vt-24bit, vt-4up, vt-6up, vt-8up, vt-8up2, wbmp, webp
        $issue_stretch = 1;
    }
}


sub make_test_gv {
  my $overlap = shift;
  return <<"EOF";
digraph test {
    graph [ label="Test for Map::Tube::Plugin::Graph", labelloc=top $overlap ];
    node [color=black, fontcolor=black, label="\\N", shape=oval];
    edge [arrowsize=1];
    id_A [label="Station A"];
    id_B [label="Station B"];
    id_A -> id_B
    id_B -> id_A
}
EOF
}

if ( is_dot_available( ) ) {
    dot_overlap_mode_ok( );
    dot_no_overlap_mode_ok( );
    # if $issue_stretch: consider writing config and not testing bitmap output formats
    # if $issue_prism: consider writing config and disabling by default no-overlap; or ask for different algorithm?
}

WriteMakefile(
    NAME               => 'Map::Tube::Plugin::Graph',
    AUTHOR             => q{Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Map/Tube/Plugin/Graph.pm',
    ABSTRACT_FROM      => 'lib/Map/Tube/Plugin/Graph.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.014,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
        'Test::Lib'  => 0,
    },
    PREREQ_PM                  => {
        'Moo::Role'            => '2.000000',
        'namespace::autoclean' => '0.28',
        'File::Which'          => '1.21',
        'GraphViz2'            => '2.63',
        'IPC::Run3'            => '0.048',
        'MIME::Base64'         => '3.14',
        'Map::Tube'            => '5.1.0',
        'Map::Tube::Exception' => '3.18',
        'Graph'                => '0.9732',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    test  => { TESTS => 't/*.t xt/*.t' },
    clean => { FILES => 'Map-Tube-Plugin-Graph-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Map::Tube::Plugin::Graph' => {
                file    => 'lib/Map/Tube/Plugin/Graph.pm',
                version => MM->parse_version('lib/Map/Tube/Plugin/Graph.pm')
            },
            'Map::Tube::Plugin::Graph::Utils' => {
                file    => 'lib/Map/Tube/Plugin/Graph/Utils.pm',
                version => MM->parse_version('lib/Map/Tube/Plugin/Graph/Utils.pm')
            },
        },
        prereqs => {
            test => {
                recommends => {
                    'Test::CPAN::Changes'    => 0,
                    'Test::CPAN::Meta::JSON' => 0,
                    'Test::CPAN::Meta'       => 0,
                    'Test::Pod'              => 1.22,
                    'Test::Version'          => 0,
                },
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Map-Tube-Plugin-Graph.git',
                web  => 'https://github.com/manwar/Map-Tube-Plugin-Graph',
            },
            bugtracker => {
                web    => 'https://github.com/manwar/Map-Tube-Plugin-Graph/issues'
            },
        },
    },
);
