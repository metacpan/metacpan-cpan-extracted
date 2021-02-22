# -*- perl -*-
# Copyright (C) 2015-2021 Sergey Poznyakoff <gray@gnu.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use ExtUtils::MakeMaker;
use Module::Metadata;

WriteMakefile(NAME         =>  'List::Regexp',
              VERSION_FROM =>  'lib/List/Regexp.pm',
              AUTHOR       =>  'Sergey Poznyakoff <gray@gnu.org>',
              LICENSE      =>  'gpl_3',
	      ABSTRACT     =>  'Construct a regexp to match any string from the string list',
	      EXE_FILES    => [ 'regexp-opt' ],
	      MIN_PERL_VERSION => 5.006,
	      META_MERGE => {
		  'meta-spec' => { version => 2 },
		  resources => {
		      repository => {
			  type => 'git',
			  url => 'git://git.gnu.org.ua/regexp-opt.git',
			  web => 'http://git.gnu.org.ua/cgit/regexp-opt.git/',
		      },
		      bugtracker => {
			  web => 'https://puszcza.gnu.org.ua/bugs/?group=regexp-opt',
			  mailto => 'gray+regexp-opt@gnu.org.ua'
		      }
		  },
		  provides => Module::Metadata->provides(version => '1.4',
							 dir => 'lib')
	      }
);
