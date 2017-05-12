#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Differences;

use Games::ABC_Path::Solver::Board;

{
    my $input_string = <<'EOF';
OWXIBQN
J    AK
E     L
U     F
Y     P
R     S
TVMGCDH
EOF

    my $solver = Games::ABC_Path::Solver::Board->input_from_v1_string(
        $input_string
    );

    # TEST
    ok ($solver, "Solver was initialized.");

    $solver->solve();

    # TEST
    is (scalar(@{$solver->get_successful_layouts()}), 1,
        "One successful layout"
    );

    # TEST
    eq_or_diff($solver->get_successes_text_tables(),
        [ <<'EOF' ],
| X = 1 | X = 2 | X = 3 | X = 4 | X = 5 |
|   K   |   J   |   I   |   B   |   A   |
|   L   |   H   |   G   |   C   |   E   |
|   U   |   M   |   N   |   F   |   D   |
|   V   |   T   |   Y   |   O   |   P   |
|   W   |   X   |   S   |   R   |   Q   |
EOF
        "Success table is right.",
    );
}

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 Shlomi Fish

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

