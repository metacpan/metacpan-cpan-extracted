use strict;
use inc::Module::Install;
name 'Lingua-JA-Expand';
all_from 'lib/Lingua/JA/Expand.pm';

requires 'UNIVERSAL::require';
requires 'Carp';
requires 'Class::Accessor::Fast';
requires 'Class::Data::Inheritable';
requires 'LWP::UserAgent';
requires 'XML::LibXML::Simple';
requires 'Lingua::JA::TFIDF';
build_requires 'Test::More';
tests 't/*.t t/*/*.t';
auto_install;
WriteAll;
