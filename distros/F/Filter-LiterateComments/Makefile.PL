#!/usr/bin/perl

use inc::Module::Install;

name		('Filter-LiterateComments');
author		('Autrijus Tang <autrijus@autrijus.org>');
abstract	('Haskell-style literate comments');
license		('perl');
version_from	('lib/Filter/LiterateComments.pm');
requires        ('Filter::Simple' => 0 );

WriteAll( sign => 1 );
