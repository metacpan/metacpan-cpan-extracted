use 5.008001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'LIMS::Controller',
    VERSION_FROM      => 'lib/LIMS/Controller.pm', # finds $VERSION
    PREREQ_PM         => {
							DBI => 1.43,
							CGI => 3.05,
							Class::DBI => 0.96,
							Class::DBI::Loader => 0.22,
							Net::Address::IPv4::Local => 0.12,
							CGI::Upload => 1.10,
							Config::IniFiles => 2.38,
							Date::EzDate => 1.08,
							Test::More => 0.64,
							Test::Group => 0.07,
							Test::Differences => 0.47,
							Test::Deep => 0.096,
							Test::Exception => 0.21							
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'Christopher Jones <c.jones@ucl.ac.uk>') : ()),
);
