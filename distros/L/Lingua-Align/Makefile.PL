use ExtUtils::MakeMaker;

use File::Copy;
if ($^O eq 'darwin'){
  unlink('bin/megam');
  copy('bin/megam.osx','bin/megam');
  chmod 0755,'bin/megam';
}
else{
  unlink('bin/megam');
  copy('bin/megam_i686.opt','bin/megam');
  chmod 0755,'bin/megam';
}

if ($ARGV[0] eq 'clean'){
  unlink('bin/megam');
  system('rm -f examples/wpt03/testsuffix.*');
  system('rm -f examples/wpt03/testword.*');
  system('rm -f examples/wpt03/test.align');
  system('rm -f examples/wpt03/wordalign.megam*');
  system('rm -f examples/europarl/nl-en-weak_125.10.0.align');
  system('rm -f examples/europarl/nl-en-weak_125.90.10.align');
  system('rm -f examples/europarl/treealign.megam');
  system('rm -f examples/europarl/treealign.megam.feat');
  exit 1;
}


WriteMakefile(
    NAME              => 'Lingua::Align',
    VERSION_FROM      => 'lib/Lingua/Align.pm',
    ABSTRACT_FROM     => 'lib/Lingua/Align.pm',
    EXE_FILES         => [ 
	'bin/treealign',
	'bin/treealigneval',
	'bin/megam', 
	'bin/sta2moses',
	'bin/sta2penn',
	'bin/sta2phrases',
	'bin/tiger2penn',
	'bin/tiger2text',
	'bin/tiger2alpino',
	'bin/stanford2tiger',
	'bin/penn2tiger',
	'bin/alpino2tiger',
	'bin/convert_treebank'
    ],
    AUTHOR            => 'Joerg Tiedemann',
    PREREQ_PM         => {
        'XML::Parser' => 0,
	'IPC::Open3' => 0,
	'Algorithm::Munkres' => 0,
    },
);
