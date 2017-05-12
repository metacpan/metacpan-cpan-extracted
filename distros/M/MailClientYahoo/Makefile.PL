use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'Mail::Client::Yahoo',
    'VERSION_FROM'  => 'lib/Mail/Client/Yahoo.pm',
    'ABSTRACT_FROM' => 'lib/Mail/Client/Yahoo.pm',
    'AUTHOR'        => 'Cory Johns <johnsca@cpan.org>',
    'PREREQ_PM'     => {
      'WWW::Mechanize'     => 0,
      'HTML::TableExtract' => 0,
      'Mail::Header'       => 0,
      'Mail::Internet'     => 0,
    },
);
