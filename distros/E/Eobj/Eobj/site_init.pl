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

# This class contains only one method -- init.
# It includes the initialization associated with this current
# site (application and user independent).

${__PACKAGE__.'::errorcrawl'}='system';

sub init {
  my $user_init_flag = 0;

  if (-e 'init.pl') { # Per-project init?
    &Eobj::inherit('user_init','init.pl','PL_hardroot');
    $user_init_flag = 1;
  }

  blow("init() called more than once")
    if (defined $Eobj::globalobject);
  $Eobj::globalobject = global -> new(name => 'globalobject');
  
  user_init->init() if $user_init_flag;
}
