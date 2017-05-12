use ExtUtils::MakeMaker;

($ABTRACT = <<"EOT") =~ s/\n/\\n/g;
I18N::AcceptLanguage matches language preference to available
languages.
EOT

if ($] < 5.006001) {
  die "Perl version 5.6.1 or higher required.\n";
}

WriteMakefile(
    'NAME'		=> 'I18N::AcceptLanguage',
    'VERSION_FROM'	=> 'lib/I18N/AcceptLanguage.pm',
    'PREREQ_PM'		=> { 'Test::More'       => 0.45 },
    'dist'              => { 'COMPRESS'         => 'gzip -9f',
			     'SUFFIX'           => 'gz', },
     ABSTRACT           => $ABSTRACT,
     AUTHOR             => 'Christian Gilmore <cag@us.ibm.com>',
);
