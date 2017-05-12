#!/usr/bin/env perl
# $File: //member/autrijus/MasonX-Profiler/Makefile.PL $ $Author: autrijus $
# $Revision: #2 $ $Change: 10396 $ $DateTime: 2004/03/16 10:55:14 $

use inc::Module::Install;

name		('MasonX-Profiler');
author		('Autrijus Tang <autrijus@autrijus.org>');
abstract_from	('lib/MasonX/Profiler.pm');
version_from	('lib/MasonX/Profiler.pm');
requires	('HTML::Mason', 0);
requires	('Time::HiRes', 0);
license		('perl');

WriteAll( sign => 1 );
