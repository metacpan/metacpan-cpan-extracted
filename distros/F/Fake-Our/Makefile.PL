use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Fake::Our',
    'VERSION_FROM'  => 'lib/Fake/Our.pm',
    'ABSTRACT_FROM' => 'lib/Fake/Our.pm',
    'PREREQ_PM'     => { },
    'AUTHOR'        => 'ina <ina@cpan.org> in a CPAN',
);

__END__
