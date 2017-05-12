

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $cgi = prompt("Where would you like kilngraph.pl & kilnserve.pl installed ", 
						"/var/www/cgi-bin");

WriteMakefile(
    NAME         => 'Device::Kiln',
    VERSION_FROM => 'lib/Device/Kiln.pm', # finds \$VERSION
    AUTHOR       => 'David Peters (davidp@electronf.com)',
    ABSTRACT     => 'Plot Graph of values from Q1573 over time.',
    EXE_FILES	 => ['lib/Device/kilngraph.pl',
    				'lib/Device/kilnserver.pl'],
    INSTALLSITESCRIPT => $cgi,
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'SVG' => 0.01,
                     'SVG::TT::Graph::TimeSeries' => 0,
                     'HTTP::Date' => 0,
                     'Device::DSE::Q1573' => 0.01,
                     'Device::Kiln::Orton' => 0.01,
                    },
);
