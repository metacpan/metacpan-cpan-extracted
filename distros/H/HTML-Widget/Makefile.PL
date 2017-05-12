use inc::Module::Install;

name 'HTML-Widget';
all_from 'lib/HTML/Widget.pm';

requires 'perl' => '5.8.1';
requires 'HTML::Element' => '3.22';
requires 'Class::Accessor::Fast';
requires 'Class::Accessor::Chained::Fast';
requires 'Class::Data::Accessor';
requires 'HTML::Scrubber';
requires 'Storable';
requires 'Module::Pluggable::Fast';
requires 'Email::Valid';
requires 'Date::Calc';
requires 'Scalar::Util';

build_requires 'Test::NoWarnings';

no_index directory => 't/lib';

auto_install;
&WriteAll;
