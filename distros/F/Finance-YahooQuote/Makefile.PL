# Makefile for Yahoo.pm
#
#    Copyright (C) 1998, 1999, 2000 Dj Padzensky <djpadz@padz.net>
#    Copyright (C) 2002 - 2015      Dirk Eddelbuettel <edd@debian.org>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

require 5.005;
use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'		=> 'Finance::YahooQuote',
	      'VERSION_FROM'    => 'YahooQuote.pm',
	      'PREREQ_PM'	=> { "LWP::UserAgent"	=> 1.62,
				     "HTTP::Request"	=> 1.23,
				     "HTML::Parser"	=> 2.20,
				     "Text::ParseWords" => 3.1 },
	      'ABSTRACT'   	=> 'Gets stock quotes from Yahoo! Finance',
	      'AUTHOR'        	=> 'Dirk Eddelbuettel (edd@debian.org)',
	      'EXE_FILES'       => ['yahooquote'],
	      'dist'		=> { COMPRESS => 'gzip', 
				     SUFFIX => '.gz', },
	     );
