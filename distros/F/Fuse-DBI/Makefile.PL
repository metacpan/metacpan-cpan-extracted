use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Fuse::DBI',
    VERSION_FROM      => 'DBI.pm', # finds $VERSION
    PREREQ_PM         => {
	'POSIX' => 0,
    	'Fuse' => 0,
	'DBI' => 0,
	'Carp' => 0,
	'File::Find' => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'DBI.pm', # retrieve abstract from module
       AUTHOR         => 'Dobrica Pavlinusic <dpavlin@rot13.org>') : ()),
    depend => {
	dist => 'changelog',
    },
);

sub MY::postamble {
	return <<'MAKE_MORE';

html: DBI.pm
	pod2html DBI.pm > DBI.html
	pod2html examples/webgui.pl > WebGUI.html
	rm pod2htm?.tmp

changelog:
	svn update && svn -v log > Changes

webgui: all
	sudo umount /mnt2 || echo -n
	./examples/webgui.pl /data/WebGUI/etc/WebGUI.conf /mnt2

MAKE_MORE
}
