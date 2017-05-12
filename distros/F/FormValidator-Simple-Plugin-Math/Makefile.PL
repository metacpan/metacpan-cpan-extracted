use inc::Module::Install;
name    'FormValidator-Simple-Plugin-Math';
all_from       'lib/FormValidator/Simple/Plugin/Math.pm';
requires 'Test::More' => 0;
requires 'FormValidator::Simple::Constants' => 0;
requires 'Math::Expression' => 0;
WriteAll;