# NAME

Hash::Tabular::Markdown - Tabulate hashref to markdown table format.

# SYNOPSIS

    use Hash::Tabular::Markdown;

# DESCRIPTION

Hash::Tabular::Markdown is dump hashref as markdown table format string.

# VALIABLES

- $Hash::Tabular::Markdown::Delimit

        delimit for markdown table

# METHODS

- tabulate

        my $hashref = { 1 => 2 };
        my $md = Hash::Tabular::Markdown->tabulate($hashref);

    convert hashref to markdown table.

# LICENSE

Copyright (C) Tomoo Amano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Tomoo Amano <sheercat@gmail.com>
