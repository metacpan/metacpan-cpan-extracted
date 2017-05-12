use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'IPC::DirQueue',
    'VERSION_FROM' => 'lib/IPC/DirQueue.pm', # finds $VERSION

    'EXE_FILES' => [
        'dq-deque',
        'dq-list',
        'dq-server',
        'dq-indexd',
        'dq-submit'
    ],

    'MAN1PODS' => {
        'dq-submit'   => '$(INST_MAN1DIR)/dq-submit.$(MAN1EXT)',
        'dq-server'   => '$(INST_MAN1DIR)/dq-server.$(MAN1EXT)',
        'dq-list'     => '$(INST_MAN1DIR)/dq-list.$(MAN1EXT)',
        'dq-indexd'   => '$(INST_MAN1DIR)/dq-indexd.$(MAN1EXT)',
        'dq-deque'    => '$(INST_MAN1DIR)/dq-deque.$(MAN1EXT)',
    },

    'clean' => {
        FILES => ' '
    },

    'PREREQ_PM' => {
        'Time::HiRes'  => 0,
        'File::Spec'   => 0,
    },

    'dist' => {
        COMPRESS => 'gzip -9f',
        SUFFIX => 'gz',
        DIST_DEFAULT => 'tardist'
    },

    'AUTHOR'   => 'Justin Mason <jmason@cpan.org>',
    'ABSTRACT' => 'disk-based many-to-many queueing system',
    'NO_META' => 1,

);
