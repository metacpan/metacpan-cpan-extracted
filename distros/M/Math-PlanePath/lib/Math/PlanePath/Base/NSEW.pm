# Copyright 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.


package Math::PlanePath::Base::NSEW;
use 5.004;
use strict;

use vars '$VERSION';
$VERSION = 129;

use constant dx_minimum => -1; # NSEW straight only
use constant dx_maximum => 1;
use constant dy_minimum => -1;
use constant dy_maximum => 1;

use constant dsumxy_minimum => -1; # NSEW straight only
use constant dsumxy_maximum => 1;
use constant ddiffxy_minimum => -1;
use constant ddiffxy_maximum => 1;
use constant dir_maximum_dxdy => (0,-1); # South

use constant 1.02;
use constant _UNDOCUMENTED__dxdy_list => (1,0,   # E
                                          0,1,   # N
                                          -1,0,  # W
                                          0,-1); # S

1;
__END__

=for stopwords Ryde Math-PlanePath multi-inheritance mixin

=head1 NAME

Math::PlanePath::Base::NSEW -- multi-inheritance mixin for North, South, East, West unit steps

=head1 SYNOPSIS

=for test_synopsis my @ISA; # normally a package variable of course, but this satisfies Test::Synopsis

 package Math::PlanePath::Foo;
 use Math::PlanePath;
 use Math::PlanePath::Base::NSEW;
 @ISA = ('Math::PlanePath::Base::NSEW', 'Math::PlanePath');

=head1 DESCRIPTION

This is a multi-inheritance mixin for paths which take only steps North,
South, East and West by distance 1 each time.  This includes for example the
C<SquareSpiral> and also things like the C<DragonCurve> or C<CCurve>.

The following path descriptive methods are provided

                        value
    dx_minimum()         -1
    dx_maximum()          1
    dy_minimum()         -1
    dy_maximum()          1

    dsumxy_minimum()     -1
    dsumxy_maximum()      1
    ddiffxy_minimum()    -1
    ddiffxy_maximum()     1
    dir_maximum_dxdy()   0,-1    # maximum South

=cut

#    _UNDOCUMENTED__dxdy_list()          1,0, 0,1, -1,0, 0,-1

=pod

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::Base::Generic>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

This file is part of Math-PlanePath.

Math-PlanePath is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-PlanePath is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.

=cut
