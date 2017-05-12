use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME                => 'Email::Postman',
              AUTHOR              => q{Jerome Eteve <jerome.eteve@gmail.com>},
              VERSION_FROM        => 'lib/Email/Postman.pm',
              ABSTRACT_FROM       => 'lib/Email/Postman.pm',
              ($ExtUtils::MakeMaker::VERSION >= 6.3002
               ? ('LICENSE'=> 'perl')
               : ()),
              PL_FILES            => {},
              PREREQ_PM => {
                            'DateTime' => 0.70,
                            'Email::Abstract' => 3.004,
                            'Email::Address' => 1.892,
                            'Net::DNS' => 0.66,
                            'Net::SMTP' => 2.31,
                            'Moose' => 2.0401,
                            'Log::Log4perl' => 1.29,
                           },
              BUILD_REQUIRES => {
                                 'MIME::Parser' => 5.502,
                                 'Test::More' => 0,
				 'Test::MockObject' => 1.20,
                                 'Test::MockModule' => 0.05,
                                },
              dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
              clean               => { FILES => 'Email-Postman-*' },
             );
