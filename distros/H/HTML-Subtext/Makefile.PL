use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
@ppdinfo = (
    'AUTHOR'       => 'Kaelin Colclasure (kaelin@acm.org)',
    'ABSTRACT'     => 'Perform text substitutions on an HTML template',
) if $] >= 5.005;

WriteMakefile(
    'NAME'	   => 'HTML::Subtext',
    'VERSION_FROM' => 'Subtext.pm', # finds $VERSION
    'PREREQ_PM'    => {
			'HTML::Parser' => 2,
			'URI::Escape' => 3,
		      },
    @ppdinfo
);
