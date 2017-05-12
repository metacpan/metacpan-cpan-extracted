=head1 PURPOSE

Test various syntax combinations for declaring fixed variables.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More tests => 26;

use Fixed;

fix $x1 = 1;

ok not eval { $x1++ };
ok not eval { $x1 = 3 };

fix ($x2) = 1;

ok not eval { $x2++ };
ok not eval { $x2 = 3 };

fix $x3;
$x3 = 1;

ok not eval { $x3++ };
ok not eval { $x3 = 3 };

fix$x4;
$x4 = 1;

ok not eval { $x4++ };
ok not eval { $x4 = 3 };

fix ($x5);
$x5 = 1;

ok not eval { $x5++ };
ok not eval { $x5 = 3 };

fix($x6);
$x6 = 1;

ok not eval { $x6++ };
ok not eval { $x6 = 3 };

fix(
	$x7
)
 = 1;

ok not eval { $x7++ };
ok not eval { $x7 = 3 };

fix
$y1;
fix
# xxx - yes;
      # a comment is here! $nnn
$z1;
$y1 = $z1 = 1;

ok not eval { $y1++ };
ok not eval { $y1 = 3 };
ok not eval { $z1++ };
ok not eval { $z1 = 3 };

fix ($y2, $z2);
$y2 = $z2 = 1;

ok not eval { $y2++ };
ok not eval { $y2 = 3 };
ok not eval { $z2++ };
ok not eval { $z2 = 3 };

fix ($y3, $z3) = (1, 1);

ok not eval { $y3++ };
ok not eval { $y3 = 3 };
ok not eval { $z3++ };
ok not eval { $z3 = 3 };
