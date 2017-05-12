use ExtUtils::MakeMaker;

my %opts = (
    'NAME'	   => 'Math::Bezier',
    'VERSION_FROM' => 'Bezier.pm',
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ AUTHOR }   = 'Andy Wardley <abw@kfs.org>';
    $opts{ ABSTRACT } = 'solution of Bezier curves',
}

WriteMakefile( %opts );
