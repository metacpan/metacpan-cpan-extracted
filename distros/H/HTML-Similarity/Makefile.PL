use lib 'lib';
use inc::Module::Install;

name 'HTML-Similarity';
author 'Yung-chung Lin <henearkrxern@gmail.com>';
version '0.2.0';
license 'Perl';

requires 'HTML::DOM' => 0;
requires 'XML::DOM' => 0;
requires 'Algorithm::LCS' => 0;

auto_install;

WriteAll;
