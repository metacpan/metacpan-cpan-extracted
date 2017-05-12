use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME'	=> 'Mac::Macbinary',
	      'VERSION_FROM' => 'Macbinary.pm', # finds $VERSION
	      dist => {
		  PREOP => build_docs(),
	      },
	      );

sub build_docs {
    return <<EOF;
pod2text Macbinary.pm > README \\
EOF
}
