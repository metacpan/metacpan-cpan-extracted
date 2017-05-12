use 5.010;
use strict;
use warnings;
use inc::Module::Install;

name 'I22r-Translate-Microsoft';
all_from 'lib/I22r/Translate/Microsoft.pm';
license 'perl';

requires 'Encode' => 0;
requires 'HTML::Entities' => 0;
requires 'HTTP::Headers' => 0;
requires 'HTTP::Request' => 0;
requires 'I22r::Translate' => 0.96;
requires 'JSON' => 0;
requires 'LWP::UserAgent' => 0;
requires 'XML::XPath' => 0;
requires 'URL::Encode' => 0;
test_requires 'Test::More' => 0;

auto_install;
WriteAll;

print STDERR qq[
*******************************************************************
Using the Microsoft translation backend requires credentials for
Microsoft data services. If you wish to test the Micrsoft backend, 
you will need to edit the file

       t/Constants.pm

and specify your credentials. See the perldoc for 
I22r::Translate::Microsoft for information about obtaining a
set of credentials for yourself, or

       http://search.cpan.org/perldoc?I22r-Translate-Microsoft#CREDENTIALS

*******************************************************************
];
