#
# This file is part of the Eobj project.
#
# Copyright (C) 2003, Eli Billauer
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# A copy of the license can be found in a file named "licence.txt", at the
# root directory of this project.
#

${__PACKAGE__.'::errorcrawl'}='system';
sub who {
  return "The Global Object";
}

sub new {
  my $this = shift;
  my $self = $this->SUPER::new(@_);

  my $name = $self->get('name');
  puke("The \'global\' class can generate an object only with the name \'globalobject\'".
       " and not \'$name\'\n") unless ($name eq 'globalobject');

  return $self;
}  

