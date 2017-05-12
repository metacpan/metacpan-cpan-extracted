#!/usr/bin/env perl

use inc::Module::Install;

name		('Lingua-ZH-Numbers');
author		('Autrijus Tang <autrijus@autrijus.org>');
abstract	('Converts numeric values into their Chinese string equivalents');
license		('perl');
version_from	('lib/Lingua/ZH/Numbers.pm');

WriteAll( sign => 1 );
