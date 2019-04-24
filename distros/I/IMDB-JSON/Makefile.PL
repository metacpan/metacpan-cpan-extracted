use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'    => 'IMDB::JSON',
    'VERSION_FROM' => 'lib/IMDB/JSON.pm', # finds $VERSION 
    'dist' => { COMPRESS => "gzip", SUFFIX=>"gz" },
    ($] ge '5.10')
        ? (
            'AUTHOR' => 'Colin Faber <cfaber@fpsn.net>',
            'ABSTRACT' => 'Grab useful data from IMDB',
           )
         : (),
    'PREREQ_PM' => {
	'HTML::TokeParser'	=> '0',
	'IO::Socket::SSL'	=> '0',
	'JSON::XS'		=> '0'
    }
);

sub MY::test {
  package MY;
  my $make = shift->SUPER::test();
  $make =~ s/(PERL_DL_NONLAZY)=1/$1=0/g;
  return $make;
}
