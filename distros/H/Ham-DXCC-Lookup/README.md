# NAME

Ham::DXCC::Lookup - Look up DXCC entity from amateur radio callsign

# SYNOPSIS

    use Ham::DXCC::Lookup qw(lookup_dxcc);

    my $info = lookup_dxcc('G4ABC');
    print "DXCC: $info->{dxcc_name}\n";

# DESCRIPTION

This module provides a simple lookup mechanism to return the DXCC entity from a given amateur radio callsign.

# FUNCTIONS

## lookup\_dxcc($callsign)

Returns a hashref with `dxcc` for the given callsign.

### API Specification

#### input

    callsign:
      optional: 0
      position: 0
      matches: '^([A-Z0-9]{1,3})([0-9])([A-Z]{1,4})$'
      min: 3
      type: string

#### output

    type: hashref

## run

You can also run this module from the command line:

    perl lib/Ham/DXCC/Lookup.pm G4ABC

# SUPPORT

This module is provided as-is without any warranty.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# SEE ALSO

[https://www.country-files.com/](https://www.country-files.com/)

# LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
