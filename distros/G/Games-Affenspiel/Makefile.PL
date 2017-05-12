use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Games::Affenspiel',
	DISTNAME => 'Games-Affenspiel',
	dist => {
		# default CP 'ln' is buggy, it changes source file permissions
		DIST_CP => 'cp',
		TO_UNIX => 'chmod a+x $(DISTVNAME)/bin/*',
		COMPRESS => 'gzip --best --force',
	},
	EXE_FILES => [ glob("bin/*") ],
	PM => {
		map {
			my $t = $_; $t =~ s/^perllib\/Games\///;
			($_, '$(INST_LIBDIR)/' . $t)
		} "perllib/Games/Affenspiel.pm", glob("perllib/Games/Affenspiel/*.pm")
	},
	# this translation should not be needed, but MakeMaker is buggy again
	MAN3PODS => {
		'perllib/Games/Affenspiel.pm' => '$(INST_MAN3DIR)/Games::Affenspiel.3pm',
	},
	VERSION_FROM => 'perllib/Games/Affenspiel.pm',
	ABSTRACT_FROM => 'perllib/Games/Affenspiel.pm',
	AUTHOR => 'Mikhael Goikhman <migo@homemail.com>',
);

open MANIFEST, "<MANIFEST";
my @old_lines = grep !/^META.yml/, <MANIFEST>;
close MANIFEST;
my @new_lines = map { "$_\n" } (
	qw(
		COPYING
		Makefile.PL
		MANIFEST
		README
	),
	"perllib/Games/Affenspiel.pm",
	glob("perllib/Games/Affenspiel/*.pm"),
	glob("bin/*"),
	glob("doc/*"),
	glob("t/*.t"),
);
if (join(',', @old_lines) ne join(',', @new_lines)) {
	print "Creating MANIFEST file\n";
	open MANIFEST, ">MANIFEST" or die "Can't write MANIFEST: $!\n";
	print MANIFEST @new_lines;
	close MANIFEST;
}
