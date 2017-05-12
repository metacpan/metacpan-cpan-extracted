package DateTimeX::ymdhms;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.2');

sub DateTime::ymdhms {
    my $self = shift;
    my($ymd_sep, $hms_sep) = @_;
    $ymd_sep //= "-";
    $hms_sep //= ":";

    return $self->format_cldr( "yyyy${ymd_sep}MM${ymd_sep}dd HH${hms_sep}mm${hms_sep}ss" );

}

sub DateTime::ymdhm {
    my $self = shift;
    my($ymd_sep, $hms_sep) = @_;
    $ymd_sep //= "-";
    $hms_sep //= ":";

    return $self->format_cldr( "yyyy${ymd_sep}MM${ymd_sep}dd HH${hms_sep}mm" );

}

1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

DateTimeX::ymdhms - more easily output date and time of your DateTime.

=head1 VERSION

This document describes DateTimeX::ymdhms version 0.0.1

=head1 SYNOPSIS

    use DateTime;
    use DateTimeX::ymdhms;

    my $dt = DateTime->now;
    print $dt->ymdhms; # prints "YYYY-MM-DD HH:MM:SS"
    print $dt->ymdhm; # same as above without seconds

=head1 DESCRIPTION

Adds easy to use methods for outputting date and time.

=head1 INTERFACE

=head2 ymdhms

Does both ymd("-") and hms(":") with a space between.

=head2 ymdhm

Same as L</ymdhms> only without seconds.

=head1 CONFIGURATION AND ENVIRONMENT

Currently doesn't load DateTime, you must do that. As such it would be
pointless to use this module without also using DateTime.

=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-datetimex-ymdhms@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Torbjørn Lindahl  C<< <torbjorn.lindahl@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Torbjørn Lindahl C<< <torbjorn.lindahl@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
