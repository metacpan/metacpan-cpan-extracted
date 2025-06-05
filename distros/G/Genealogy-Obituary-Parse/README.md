![Perl CI](https://github.com/nigelhorne/Genealogy-Obituary-Parse/actions/workflows/test.yml/badge.svg)

# NAME

Genealogy::Obituary::Parse - Extract structured family relationships from obituary text

# SYNOPSIS

    use Genealogy::Obituary::Parse qw(parse_obituary);

    my $text = "She is survived by her husband Paul, daughters Anna and Lucy, and grandchildren Jake and Emma.";
    my $data = parse_obituary($text);

    # $data = {
    #   spouse       => ['Paul'],
    #   children     => ['Anna', 'Lucy'],
    #   grandchildren => ['Jake', 'Emma'],
    # };

# DESCRIPTION

This module parses freeform obituary text and extracts structured family relationship data
for use in genealogical applications.

# FUNCTIONS

## parse\_obituary($text)

Returns a hashref of extracted relatives.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# SUPPORT

This module is provided as-is without any warranty.

# LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
