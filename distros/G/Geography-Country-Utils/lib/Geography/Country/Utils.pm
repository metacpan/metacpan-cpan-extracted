package Geography::Country::Utils;
$Geography::Country::Utils::VERSION = '1.07';

use strict;

=head1 NAME

Geography::Country::Utils - Utilities for country-specific information

=head1 VERSION

This document describes version 1.07 of Geography::Country::Utils,
released August 12, 2005.

=head1 SYNOPSIS

    use Geography::Country::Utils qw(...); # autoloads submodules

=head1 DESCRIPTION

This module is just a thin wrapper around other B<Geography::Country::*>
modules.  No functions are exported by default; any functions requested
are imported from the module that defines them.

=head1 FUNCTIONS

=head2 Geography::Country::Dial

=over 4

=item dialcode([$name | $code])

Returns the international dial code for a country, specified either as
name or as FIPS country code.

=back

=head2 Geography::Country::FIPS

=over 4

=item country2fips($name)

Returns the FIPS code for a country.

=item fips2country($code)

Returns the FIPS code for a country name.

=item iso2fips($code)

Convert an ISO country code to the corresponding FIPS code.

=item fips2iso($code)

Convert a FIPS country code to the corresponding ISO code.

=item Code($name)

Same as L</country2fips>.  Deprecated.

=item Name($code)

Same as L</fips2country>.  Deprecated.

=back

=head2 Geography::Country::FIPS::Capitals

=over 4

=item fips2capital($code)

Returns the capital for the country specified as FIPS code.

=back

=head2 Geography::Country::TZ

XXX: currently undocumented.

=over 4

=item from_iso

=item areas

=item areas_dmy

=back

=head2 Geography::Country::TZ::Zone

XXX: currently undocumented.

=over 4

=item getblock

=item conv

=item getoffset

=item getpastoffset

=item getsave

=item find

=item maketime

=back

=cut

use Geography::Country::Dial ();
use Geography::Country::FIPS ();
use Geography::Country::FIPS::Capitals ();
use Geography::Country::TZ ();
use Geography::Country::TZ::Zone ();

sub import {
    my $class  = shift;
    my $caller = caller;
    my $param  = join(',', map { '"' . quotemeta($_) . '"' } @_);
    eval "package $caller; $_->import($param)" for qw(
        Geography::Country::Dial
        Geography::Country::FIPS
        Geography::Country::FIPS::Capitals
        Geography::Country::TZ
        Geography::Country::TZ::Zone
    );
}

1;

=head1 AUTHORS

Ariel Brosh E<lt>schop@cpan.orgE<gt> is the original author, now passed
away.

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt> is the current maintainer.

=head1 COPYRIGHT

Copyright 2001, 2002 by Ariel Brosh.

Copyright 2003, 2005 by Autrijus Tang.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

__END__
# Local variables:
# c-indentation-style: bsd
# c-basic-offset: 4
# indent-tabs-mode: nil
# End:
# vim: expandtab shiftwidth=4:
