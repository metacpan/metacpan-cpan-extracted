package Devel::Mortality;

use 5.005;
use strict;

require Exporter;
require DynaLoader;

use File::Basename qw(dirname);
use File::Spec;

use vars qw($VERSION @ISA);
@ISA = qw(DynaLoader);

$VERSION = '0.01';

bootstrap Devel::Mortality $VERSION;

sub inc_dir {
    my @pm_dir = File::Spec->splitdir(dirname($INC{"Devel/Mortality.pm"}));
    pop @pm_dir;
    my $inc_dir = File::Spec->catdir(@pm_dir, "auto", "Devel", "Mortality");
    return $inc_dir;
}

1;
__END__
=head1 NAME

Devel::Mortality - Helper functions for XS developers debugging mortality issues

=head1 SYNOPSIS

  #include "Devel_Mortality.h"
  
  ... then somewhere later in XS land ...
  
  if (DM_SvNEXTMORTAL(sv)) {
    /* SV was mortal which it wasn't supposed to be */
  }
  
=head1 DESCRIPTION

This module provides a a few handy macros and functions for checking if SVs are mortal or not. It is not intended to use 
from Perl except from you Makefile.PL (or Build.PL)

Also make sure this module is loaded when you run your XS or there will be failures.

=head1 INTERFACE

=head2 MACROS

=over 4

=item DM_SvNEXTMORTAL(sv)

Checks if the given SV is flagged temporary and exists in the current stackframe of the mortality list.

=item DM_SvMAYBEMORTAL(sv)

Checks if the given SV is flagged temporary and exists somewhere in the mortality list.

=back

=head2 FUNCTIONS

=over 4

=item bool DM_scan_for_mortal(SV *sv, bool from_root, bool to_top)

Scan the PL_tmps_stack for the given I<SV>. If I<from_root> is true scan will be performed from 0 
otherwise the value of C<PL_tmps_floor + 1> is used. If I<to_top> is true scan will be performed to 
the value of C<PL_tmps_ix + 1> otherwise to C<PL_tmps_floor>

=back

=head2 BUILD UTILITIES

=over 4

=item inc_dir

Returns the path to the directory where our header is installed. This should be passed to your 
C compiler.

=back
 
=head1 EXPORT

Nothing exported.

=head1 THANKS

With help and suggestions from Nicholas Clark and Rafaël Garcia-Suarez.

=head1 SEE ALSO

L<perlapi>, L<perlxs>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-devel-mortality@rt.cpan.org>, 
or through the web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Claes Jakobsson, Versed Solutions C<< <claesjac@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Versed Solutions C<< <info@versed.se> >>. All rights reserved.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut
