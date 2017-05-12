# -*- perl -*-

use ExtUtils::MakeMaker;

my %opts = 
    ( 'NAME'         => 'ExtUtils::PerlPP',
      'VERSION_FROM' => 'PerlPP.pm',
      'dist'         => { 'SUFFIX'       => ".gz",
			  'DIST_DEFAULT' => 'all tardist',
			  'COMPRESS'     => "gzip -9vf" },
     );

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{'AUTHOR'} = 'Jochen Wiedmann (joe@ispsoft.de)';
    $opts{'ABSTRACT_FROM'} = 'PerlPP.pm';
}

WriteMakefile(%opts);


package MY;

sub postamble {
    '
all :: README

README: PerlPP.pm
	perldoc -t PerlPP.pm >README
';
}
