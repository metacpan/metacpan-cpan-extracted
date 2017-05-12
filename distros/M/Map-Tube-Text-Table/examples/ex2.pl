#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Module.
use Encode qw(encode_utf8);
use Map::Tube::Text::Table::Utils qw(table);

# Get table.
my $table = table('Title', [1, 2, 3], ['A', 'BB', 'CCC'], [
        ['E', 'A', 'A'],
        ['A', 'Ga', 'Acv'],
]);

# Print table.
print encode_utf8($table);

# Output:
# ┌──────────────┐
# │ Title        │
# ├───┬────┬─────┤
# │ A │ BB │ CCC │
# ├───┼────┼─────┤
# │ E │ A  │ A   │
# │ A │ Ga │ Acv │
# └───┴────┴─────┘