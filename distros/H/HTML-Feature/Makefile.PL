use inc::Module::Install;
name 'HTML-Feature';
all_from 'lib/HTML/Feature.pm';

requires 'Class::Accessor::Fast';
requires 'Class::Data::ConfigHash';
requires 'UNIVERSAL::require';
requires 'Encode';
requires 'Carp';
requires 'URI';
requires 'Scalar::Util';
requires 'LWP::UserAgent';
requires 'LWP::Simple';
requires 'HTTP::Request';
requires 'Statistics::Lite';
requires 'Storable';
requires 'JSON';
requires 'HTML::TreeBuilder::LibXML'; 
requires 'HTML::TreeBuilder::XPath'; 
requires 'Data::Decode', '0.00006';

build_requires 'Test::More';
build_requires 'Test::Memory::Cycle';
use_test_base;
tests 't/*.t t/*/*.t t/*/*/*.t'; 
auto_include;
WriteAll;
