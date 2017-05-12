use inc::Module::Install;
all_from    'lib/HTML/Quoted.pm';
readme_from 'lib/HTML/Quoted.pm';
requires    'HTML::Parser' => '3.0';
WriteAll();
