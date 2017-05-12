use ExtUtils::MakeMaker;
use Config;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $eu_version = $ExtUtils::MakeMaker::VERSION;
my %opts = (
	    'NAME'		=> 'Math::FFT',
	    'VERSION_FROM'	=> 'FFT.pm', # finds $VERSION
            'OBJECT' => 'FFT.o fft4g.o arrays.o',
	    'dist'   => {
			 SUFFIX   => 'gz',
			 COMPRESS => 'gzip -9f',
			},
            ($eu_version >= 6.11 ?
             (NO_META     => 1,)
             : ()),
	   );
if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
  $opts{ABSTRACT} = 'Perl extension for Fast Fourier Transforms';
  $opts{AUTHOR} = 'Randy Kobes <r.kobes@uwinnipeg.ca>';
  $opts{CAPI} = 'TRUE' if $Config::Config{archname} =~ /-object\b/i;
}

WriteMakefile(%opts);
