use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'HTML::ReportWriter',
    'VERSION_FROM'	=> 'ReportWriter.pm',
    'PREREQ_PM'		=> {
            'CGI' => 0,
            'List::MoreUtils' => 0,
            'POSIX' => 0,
            'DBI' => 0,
#            'Template' => 0,
#            'Spreadsheet::SimpleExcel' => 0,
    },
    'ABSTRACT_FROM'     => 'ReportWriter.pm',
    'AUTHOR'            => 'Shane Allen <opiate@gmail.com>',
);
