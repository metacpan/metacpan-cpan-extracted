require 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
              'NAME'         => 'HTML::FormsDj',
              'VERSION_FROM' => 'lib/HTML/FormsDj.pm',
              'PREREQ_PM'    => {
                                  'Digest::SHA'         => 1.00,
                                  'Data::FormValidator' => 4.66,
                                },
              'AUTHOR'       => 'T. Linden <tlinden@cpan.org>',
              'clean'        => {
                                 FILES                   => 't/*.out *~ */*~ */*/*~ */*/*/*~'
                                },

);
