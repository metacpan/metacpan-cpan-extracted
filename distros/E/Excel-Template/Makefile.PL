use inc::Module::Install;

name 'Excel-Template';
perl_version '5.006';
all_from 'lib/Excel/Template.pm';
author q{Rob Kinyon <rob.kinyon@gmail.com>};
license 'perl';
resources(
    repository => {
        url  => 'git://git.shadowcat.co.uk/p5sagit/Excel-Template.git',
        web  => 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=p5sagit/Excel-Template.git;a=summary',
        type => 'git',
    },
);

test_requires 'File::Path'      => 0;
test_requires 'File::Temp'      => 0;
test_requires 'Test::Deep'      => '0.095';
test_requires 'Test::More'      => '0.47';
test_requires 'Test::Exception' => '0.21';

requires 'Test::More'                       => 0;
requires 'XML::Parser'                      => 0;
requires 'IO::Scalar'                       => 0;
requires 'File::Basename'                   => 0;
requires 'Spreadsheet::WriteExcel'          => '0.42';
requires 'Spreadsheet::WriteExcel::Utility' => 0;

if ($] < 5.008) {
    print "#\n";
    print "# Note: If you want to work with Unicode, you will need to install\n";
    print "# the optional module Unicode::String and set USE_UNICODE to true.\n";
    print "#\n";
    recommends 'Unicode::String';
}

auto_install;

WriteAll;

