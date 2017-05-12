use 5.008000;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Helios-Panoptes',
    AUTHOR            => 'Andrew Johnson <ajohnson at ittoolbox dotcom>',
    ABSTRACT          => 'Web administration interface to the Helios distributed job processing system',
    LICENSE           => 'perl',
    VERSION_FROM      => 'lib/Helios/Panoptes.pm', # finds $VERSION
    PREREQ_PM         => { 'CGI::Application'     => 4.06,
                           'DBD::Mock'            => 0.11,		# needed by CGI::Application::Plugin::DBH
                           'CGI::Application::Plugin::DBH'
                                                  => 4.00,
                           'HTML::Template'       => 2.90,
                           'Parse::RecDescent'    => '',		# needed by HTML::Template::Expr
                           'HTML::Template::Expr' => 0.04,
                           'Helios'               => 2.00,

                         }
);
