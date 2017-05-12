use inc::Module::Install;

name     'FormValidator-Simple';
all_from 'lib/FormValidator/Simple.pm';
requires 'Class::Accessor'            => 0.22;
requires 'Class::Inspector'           => 1.13;
requires 'Class::Data::Inheritable'   => 0.04;
requires 'Class::Data::Accessor'      => 0.03;
requires 'UNIVERSAL::require'         => 0.10;
requires 'Mail::Address'              => 0;
requires 'Email::Valid'               => 0.15;
requires 'Email::Valid::Loose'        => 0.04;
requires 'Date::Calc'                 => 5.4;
requires 'Tie::IxHash'                => 1.21;
requires 'YAML'                       => 0.39;
requires 'List::MoreUtils'            => 0.16;
requires 'Scalar::Util'               => 0;
requires 'DateTime::Format::Strptime' => 1.0700;
auto_install;
WriteAll;

