

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'HTML::Robot::Scrapper',
    VERSION_FROM => 'lib/HTML/Robot/Scrapper.pm', # finds \$VERSION
    AUTHOR       => 'Hernan Lopes (hernan@cpan.org)',
    ABSTRACT     => 'Your robot to parse webpages',
    PREREQ_PM    => {
                      'Test::Simple'             => 0.44,
#                     'CHI'                      => 0,
#                     'CHI::Driver::BerkeleyDB'  => 0,
                      'Moose'                    => 0,
                      'Class::Load'              => 0,
                      'Data::Dumper'             => 0,
                      'Data::Printer'            => 0,
                      'Try::Tiny'                => 0,
#                     'v5.10'                    => 0,
                      'Carp'                     => 0,
                      'Encode::Guess'            => 0,
                      'Encode'                   => 0,
                      'utf8'                     => 0,
                      'Digest::SHA'              => 0,
                      'HTML::Entities'           => 0,
                      'Time::HiRes'              => 0,
                      'HTML::TreeBuilder::XPath' => 0,
                      'XML::XPath'               => 0,
                      'HTTP::Tiny'               => 0,
                      'HTTP::Headers::Util'      => 0,
                      'Digest::SHA1'             => 0,
                      'URI'                      => 0,
                      'Path::Class'              => 0,
#                     'BerkeleyDB'               => 0,
                      'DateTime'                 => 0,
                    },
);
