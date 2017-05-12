use strict;
use warnings;
use inc::Module::Install;

# If you updated this file, don't forget to update the Build.PL file as well!

name           'Getopt-Euclid';
all_from       'lib/Getopt/Euclid.pm';

resources
   homepage    'http://search.cpan.org/search?query=Getopt%3A%3AEuclid&mode=dist';
   bugtracker  'https://rt.cpan.org/Public/Dist/Display.html?Name=Getopt-Euclid';
   repository  'git://getopt-euclid.git.sourceforge.net/gitroot/getopt-euclid/getopt-euclid';

# Perl core modules
build_requires 'Test::More'            => 0;
build_requires 'Pod::Checker'          => 0;

requires       'version'               => 0,
requires       'Pod::Select'           => 0;
requires       'Pod::PlainText'        => 0; # uses Pod::Select
requires       'File::Basename'        => 0;
requires       'File::Spec::Functions' => 0;
requires       'List::Util'            => 0;

# CPAN modules
requires       'Text::Balanced'        => 0;

recommends     'IO::Pager::Page'       => 0;

WriteAll;

if ( -e 'MANIFEST.SKIP' ) {
   generate_readme( 'lib/Getopt/Euclid.pm', 'README' ); 
}



sub generate_readme {
   my ($in, $out) = @_;
   `pod2text $in $out`;
   warn "Warning: Could not generate $out.\n$!\n" if $? == -1;
   return $?; # exit status
}
