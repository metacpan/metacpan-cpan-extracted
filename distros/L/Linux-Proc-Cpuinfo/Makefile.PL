use 5.006000;

use Devel::CheckLib;
use ExtUtils::MakeMaker;

check_lib_or_exit( 'lib' => 'proccpuinfo', 'header' => 'proccpuinfo.h' );

WriteMakefile(
    'NAME'               => 'Linux::Proc::Cpuinfo',
    'VERSION_FROM'       => 'lib/Linux/Proc/Cpuinfo.pm',
    'CONFIGURE_REQUIRES' => { 'Devel::CheckLib' => 0 },
    'PREREQ_PM'          => { 'Test::More' => 0 },
    (
        $] >= 5.005
        ? (
            'ABSTRACT_FROM' => 'lib/Linux/Proc/Cpuinfo.pm',
            'AUTHOR'        => 'Alan Haggai Alavi <alanhaggai@alanhaggai.org>'
          )
        : ()
    ),
    'LIBS'     => ['-lproccpuinfo '],
    'DEFINE'   => '',
    'INC'      => '-I.',
    'LICENSE'  => 'perl',
    'META_ADD' => {
        'resources' => {
            'repository' => 'http://github.com/alanhaggai/Linux-Proc-Cpuinfo',
        },
    },
);
