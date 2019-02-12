use ExtUtils::MakeMaker;

WriteMakefile
  (
   NAME => 'GermaNet::Flat',
   AUTHOR => "Bryan Jurish <jurish@bbaw.de>",
   ABSTRACT => "Flat relational access to GermaNet data",
   VERSION_FROM	=> 'Flat.pm',
   PREREQ_PM => {
		 ##-- Flat.pm
		 'Carp' => 0,
		 'Fcntl' => 0,
		 'File::Basename' => 0,
		 'IO::File' => 0,
		 'XML::Parser' => 0,

		 ##-- test
		 'Test::More' => 0,

		 ##-- gn-flat-compile.perl
		 'Getopt::Long' => 0,
		 'Pod::Usage' => 0,

		 ##-- gn-view.perl
		 'CGI' => 0,
		 'Encode' => 0,
		 'File::Temp' => 0,
		 'GraphViz' => 0,
		 'HTTP::Status' => 0,
		 'JSON' => 0,
		},
   EXE_FILES => [
		 glob('gn-flat-*.perl'),
		],
  );

##-----------------------------------------------------------------------
## Extensions
##-----------------------------------------------------------------------

##---------------------------------------------------------------
sub MY::depend {
  package MY;
  my $inherited = shift->SUPER::depend(@_);
  $inherited .= (
		 ###-- depends -> README.txt, CAB/Version.pm
		 "\n\n"
		 ."dist: README.txt\n"
		 ."\n"
		 ."create_distdir: README.txt\n"
		 #."distdir_am: README.txt CAB/Version.pm\n"
		 ."\n"
		 ."distcheck: README.txt\n"
		 ."\n"
		 ."manicheck: README.txt\n"
		 ."\n"
		 #."blibdirs: CAB/Version.pm\n"
		 #."\n"
		);
  return $inherited;
}

##---------------------------------------------------------------
sub MY::special_targets {
  package MY;
  my $inherited = shift->SUPER::special_targets(@_);
  $inherited .=
"
.SUFFIXES: .pm .pod .rpod .man .txt .html

readme: README.txt

.pm.html:
\tpod2html --infile=\$< --outfile=\$@

.pm.txt:
\tpod2text \$< \$@

.pod.html:
\tpod2html --infile=\$< --outfile=\$@

.pod.txt:
\tpod2text \$< \$@

.rpod.html:
\tpod2html --infile=\$< --outfile=\$@

.rpod.txt:
\tpod2text \$< \$@

";

  return $inherited;
}
