use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Eixo::Rest',
    VERSION_FROM      => 'lib/Eixo/Rest.pm', # finds $VERSION
    PREREQ_PM         => {
        'JSON' => "2.50",
        'LWP::UserAgent' => '6.06',
        'LWP::Protocol::https' => '6.06',
        'Net::HTTP'   => '6.06',
        'Eixo::Base' => '1.400',
        'HTTP::Server::Simple::CGI' => '0',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
          ABSTRACT_FROM        => 'lib/Eixo/Rest.pod', 
          AUTHOR           => ['Francisco Maseda <frmadem@gmail.com>', 'Javier Gomez <alambike@gmail.com>'],
      ): ()),
);
