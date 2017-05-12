use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'ETL::Pequel3::PlaceHolder',
    VERSION_FROM      => 'lib/ETL/Pequel3/PlaceHolder.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (#ABSTRACT_FROM  => 'lib/ETL/Pequel3/PlaceHolder.pm', # retrieve abstract from module
	ABSTRACT => 'Comprehensive & high performance data processing/ETL engine',
       AUTHOR         => 'U-LS005114\administrator <mgaffier@familiehaase.de>') : ()),
);
print "\n", '*' x 50 , "\n";
print "This is just a placeholeder dummy module...\n";
print "The Pequel 3 module and extensions are available for download from\n";
print "http://sourceforge.net/projects/pequel/\n";
print "\n", '*' x 50 , "\n";

__END__
Copyright Notice
----------------
Copyright 1999-2007 Mario Gaffiero.

This file is part of Pequel(TM).

Pequel is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 of the License.

Pequel is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Pequel; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
