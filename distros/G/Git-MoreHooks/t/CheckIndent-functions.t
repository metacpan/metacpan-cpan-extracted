#!perl
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
use strict;
use warnings;
use Test2::V0;

use Git::MoreHooks::CheckIndent;

{
    my $file = <<'FILE_END';
First line.
    Space indented line (tabsize 4).
	Tab indented line.
Last line.
    Space indented line after last line.
FILE_END

    my %results = Git::MoreHooks::CheckIndent::check_for_indent(
        'file_as_string' => $file,
        'indent_char'    => q{ },
    );
    is( \%results, { 3 => "\tTab indented line." }, 'Found error with tab.' );

}

{
    my $file = <<'FILE_END';
    Space indented line (tabsize 4).
	Tab indented line.
			Tab indented line (indents: 3).
      Space indented line (tabsize 6).
FILE_END

    my %results = Git::MoreHooks::CheckIndent::check_for_indent(
        'file_as_string' => $file,
        'indent_char'    => qq{\t},
        'indent_size'    => 2,
    );
    is( [ sort keys %results ], [ 1, 4 ], 'Found error with spaces.' );

}

done_testing();
