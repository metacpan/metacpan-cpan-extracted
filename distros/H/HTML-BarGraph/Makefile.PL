use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'HTML::BarGraph',
    'VERSION_FROM' => 'BarGraph.pm', # finds $VERSION
    'AUTHOR'   => 'Vlad Podgurschi <cpan@podgurschi.org>'
);
