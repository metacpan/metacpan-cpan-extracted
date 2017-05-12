use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'    => 'File::Fingerprint::Huge',
    'VERSION_FROM' => 'lib/File/Fingerprint/Huge.pm', # finds $VERSION 
    'dist' => { COMPRESS => "gzip", SUFFIX=>"gz" },
    'PREREQ_PM' => {
		'Digest::CRC'		=> '0.16',
		'Digest::MD5'		=> '2.39',
		'Math::Random::MT'	=> '1.10'
    },
    ($] ge '5.005')
        ? (
            'AUTHOR' => 'Colin Faber <cfaber@gmail.com>',
            'ABSTRACT' => 'Very large file high speed finger printing and checksuming',
           )
         : (),
    
);

sub MY::test {
  package MY;
  my $make = shift->SUPER::test();
  $make =~ s/(PERL_DL_NONLAZY)=1/$1=0/g;
  return $make;
}
