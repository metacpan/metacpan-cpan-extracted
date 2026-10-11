#!perl
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
use strict;
use warnings;
use Test2::V0;

use Git::MoreHooks::CheckIndent;

{
    my $file =
        sprintf "First line.\n"
        . sprintf "    Space indented line (tabsize 4).\n"
        . sprintf "\tTab indented line.\n"
        . sprintf "Last line.\n"
        . sprintf "    Space indented line after last line.\n";

    my %results = Git::MoreHooks::CheckIndent::check_for_indent(
        'file_as_string' => $file,
        'indent_char'    => q{ },
    );
    is( \%results, { 3 => "\tTab indented line." }, 'Found error with tab.' );

}

{
    my $file =
        sprintf "    Space indented line (tabsize 4).\n"
        . sprintf "\tTab indented line.\n"
        . sprintf "\t\t\tTab indented line (indents: 3).\n"
        . sprintf "      Space indented line (tabsize 6).\n";

    my %results = Git::MoreHooks::CheckIndent::check_for_indent(
        'file_as_string' => $file,
        'indent_char'    => qq{\t},
        'indent_size'    => 2,
    );
    is( [ sort keys %results ], [ 1, 4 ], 'Found error with spaces.' );

}

done_testing();
