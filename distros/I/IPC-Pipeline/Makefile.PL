# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use ExtUtils::MakeMaker;
use 5.008001;
use strict;
use warnings;

if ( $^O =~ /^MSWin/ ) {
    die('OS unsupported');
}

WriteMakefile(
    'NAME'             => 'IPC::Pipeline',
    'AUTHOR'           => 'Xan Tronix <xan@cpan.org>',
    'ABSTRACT'         => 'IPC::Open3-like interface providing shell-style pipelines in Perl',
    'LICENSE'          => 'perl',
    'VERSION_FROM'     => 'lib/IPC/Pipeline.pm',
    'MIN_PERL_VERSION' => '5.8.0',
    'BUILD_REQUIRES'   => { 'Test::More' => 0 },
    'META_MERGE'       => {
        'meta-spec' => { 'version' => 2 },
        'resources' => {
            'type' => 'git',
            'url'  => 'git://github.com/xantronix/IPC-Pipeline.git',
            'web'  => 'https://github.com/xantronix/IPC-Pipeline'
        },
    }
);
