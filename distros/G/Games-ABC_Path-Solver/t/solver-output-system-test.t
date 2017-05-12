#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Differences qw( eq_or_diff );

sub _slurp
{
    my $filename = shift;

    open my $in, "<", $filename
        or die "Cannot open '$filename' for slurping - $!";

    local $/;
    my $contents = <$in>;

    close($in);

    return $contents;
}

{
    my $got_results =
        `$^X -Mblib scripts/abc-path-solve t/layouts/brain-bashers.2010-12-21.abc-path`
        ;

    # TEST
    ok ((!$?), "Process ended successfully.");

    my $exp_results =
        _slurp('./t/results/brain-bashers.2010-12-21.abc-path-sol');

    # TEST
    eq_or_diff(
        $got_results,
        $exp_results,
        "Output is OK.",
    );
}

{
    my $got_results =
        `$^X -Mblib scripts/abc-path-solve t/layouts/brain-bashers.2010-12-22.abc-path`
        ;

    # TEST
    ok ((!$?), "Process ended successfully.");

    my $exp_results =
        _slurp('./t/results/brain-bashers.2010-12-22.abc-path-sol');

    # TEST
    eq_or_diff(
        $got_results,
        $exp_results,
        "Output is OK.",
    );
}

{
    my $got_results =
        `$^X -Mblib scripts/abc-path-solve --gen-v1-template`
        ;

    # TEST
    ok ((!$?), "Process ended successfully.");

    my $v1_template__exp_results = <<'EOF';
ABC Path Solver Layout Version 1:
???????
?     ?
?     ?
?     ?
?   A ?
?     ?
???????
EOF

    # TEST
    eq_or_diff(
        $got_results,
        $v1_template__exp_results,
        "Output of --gen-v1-template is OK.",
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

