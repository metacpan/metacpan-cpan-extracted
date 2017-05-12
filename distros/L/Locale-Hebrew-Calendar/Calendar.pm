# $File: //member/autrijus/Locale-Hebrew-Calendar/Calendar.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 3587 $ $DateTime: 2003/01/17 05:30:22 $

package Locale::Hebrew::Calendar;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

=head1 NAME

Locale::Hebrew::Calendar - Jewish Calendar

=head1 VERSION

This document describes version 0.03 of Locale::Hebrew::Calendar,
released January 17, 2003.

=head1 SYNOPSIS

    # 'g2j' and 'j2g' may be exported explicitly
    use Locale::Hebrew::Calendar;

    # Gregorian to Jewish
    ($d, $m, $y) = Locale::Hebrew::Calendar::g2j($dd, $mm, $yy);

    # Jewish to Gregorian
    ($d, $m, $y) = Locale::Hebrew::Calendar::j2g($dd, $mm, $yy);

=head1 DESCRIPTION

This is an XSUB interface to a code which can be found on several main
FTP servers.  Neither Ariel nor Autrijus have contacted the author, but
"He who says things in the name of their originators brings redemption
to the world" -- The actual code was written by Amos Shapir.

=cut

use Exporter;
use DynaLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = ();
@EXPORT_OK = qw( g2j j2g );
$VERSION = '0.03';

__PACKAGE__->bootstrap($VERSION);

sub g2j {
    @{_g2j(shift, shift, shift)};
}

sub j2g {
    @{_j2g(shift, shift, shift)};
}

1;

__END__

=head1 AUTHORS

Amos Shapir E<lt>amos@nsc.comE<gt> is the original author.

Ariel Brosh E<lt>schop@cpan.orgE<gt> did the XSUB functions.

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt> is the current maintainer.

=head1 COPYRIGHT

Copyright 2001, 2002 by Ariel Brosh.

Copyright 2003 by Autrijus Tang.

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
