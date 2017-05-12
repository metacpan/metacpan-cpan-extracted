# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# Released under the terms of the MIT license.  See the LICENSE file for further
# details.

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Mail::MBX',
    'VERSION_FROM' => 'lib/Mail/MBX.pm',
    'AUTHOR'       => 'Xan Tronix <xan@cpan.org>',
    'LICENSE'      => 'mit',
    'ABSTRACT'     => 'Migrate MBX mailboxes to Maildir',

    'PREREQ_PM' => { 'Time::Local' => 0 },

    'BUILD_REQUIRES' => {},

    'META_MERGE' => {
        'meta-spec' => { 'version' => 2 },
        'resources' => {
            'type' => 'git',
            'url'  => 'git://github.com/xantronix/Mail-Dir-MBX.git',
            'web'  => 'https://github.com/xantronix/Mail-Dir-MBX'
        }
    }
);
