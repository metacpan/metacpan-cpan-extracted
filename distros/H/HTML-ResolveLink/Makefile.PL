use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'HTML::ResolveLink',
    'VERSION_FROM' => 'lib/HTML/ResolveLink.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
        HTML::Parser => 3.26,
        URI => 0,
    },
);
