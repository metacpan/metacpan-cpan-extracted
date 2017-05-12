use inc::Module::Install 0.91;
 
use warnings;
use strict;
 
all_from 'lib/HTML/FormHandlerX/Field/reCAPTCHA.pm';
repository 'git://github.com/jjn1056/HTML-FormHandlerX-Field-reCAPTCHA.git'; 

requires 'HTML::FormHandler' => '0.30002';
requires 'Crypt::CBC' => '2.30';
requires 'Crypt::Blowfish' => '2.10'; 
requires 'Captcha::reCAPTCHA' => '0.92';

test_requires 'Test::More' => '0.94';

auto_install;
tests_recursive;
WriteAll;
