use inc::Module::Install;

name        'Kwiki-DoubleClickToEdit';
all_from    'lib/Kwiki/DoubleClickToEdit.pm';

requires    perl => '5.6.1';
requires    Kwiki => 0.38;

WriteAll;
