![Perl CI](https://github.com/nigelhorne/Genealogy-Obituary-Parser/actions/workflows/test.yml/badge.svg)

# NAME

Genealogy::Obituary::Parser - Extract structured family relationships from obituary text

# VERSION

Version 0.04

# SYNOPSIS

    use Genealogy::Obituary::Parser qw(parse_obituary);

    my $text = 'She is survived by her husband Paul, daughters Anna and Lucy, and grandchildren Jake and Emma.';
    my $data = parse_obituary($text);

    # $data = {
    #   spouse   => ['Paul'],
    #   children => ['Anna', 'Lucy'],
    #   grandchildren => ['Jake', 'Emma'],
    # };

# DESCRIPTION

This module parses freeform obituary text and extracts structured family relationship data
for use in genealogical applications.
It parses obituary text and extract structured family relationship data, including details about children, parents, spouse, siblings, grandchildren, and other relatives.

# FUNCTIONS

## parse\_obituary($text)

The routine processes the obituary content to identify and organize relevant family information into a clear, structured hash.
It returns a hash reference containing structured family information,
with each family member's data organized into distinct categories such as children, spouse, parents, siblings, etc.

Takes a string, or a ref to a string.

### API SPECIFICATION

#### INPUT

    {
      'text' => {
        'type' => 'string',       # or stringref
        'min' => 1,
        'max' => 10000
      }, 'geocoder' => {  # used to geocode locations to verify they exist
        'type' => 'object',
        'can' => 'geocode',
        'optional' => 1,
      }
    }

#### OUTPUT

- No matches: undef

    {
      type => 'hashref',
      'min' => 1,
      'max' => 10
    }

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# SEE ALSO

Test coverage report: [https://nigelhorne.github.io/Genealogy-Obituary-Parser/coverage/](https://nigelhorne.github.io/Genealogy-Obituary-Parser/coverage/)

# SUPPORT

This module is provided as-is without any warranty.

# LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
