=license

	Dot - The beginning of a Perl universe
	Copyright © 2018 Yang Bo

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <https://www.gnu.org/licenses/>.

=cut
require v5.14;
use ExtUtils::MakeMaker;
my $me = '://github.com/057a3dd61f99517a3afea0051a49cb27994f94d/Dot';
WriteMakefile(NAME => 'Dot',
	      ABSTRACT => 'The beginning of a Perl universe',
	      AUTHOR => ['Yang Bo <rslovers@yandex.com>'],
	      VERSION_FROM => 'Dot.pm',
	      META_MERGE => {resources => {repository => {type => 'git',
							  url => "git$me.git",
							  web => "https$me"},
					   homepage => "https$me",
					   bugtracker => {web => "https$me/issues"}},
			     prereqs => {test => {requires => {'Test::More' => 0}}},
			     'meta-spec' => {version => 2}},
	      LICENSE => 'gpl_3');
