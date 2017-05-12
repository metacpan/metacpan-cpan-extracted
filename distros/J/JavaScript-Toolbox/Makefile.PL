use ExtUtils::MakeMaker;


# 'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" }

WriteMakefile(
    'NAME'          => 'JavaScript::Toolbox',
    'VERSION_FROM'  => 'Toolbox.pm',
    'PREREQ_PM'     => {HTTP::BrowserDetect => 0.97},
);
